%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description : Client-to-Client Messaging handler
%%%
%%% Created : Mar 26, 2010
%%% -------------------------------------------------------------------
-module(amqp_ccmsg).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {cstate, server, cserver}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, ConnServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, ConnServer], []).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([Server, ConnServer]) ->
    {ok, #state{cstate=wait, server=Server, cserver=ConnServer}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

%%  Reset per-channel state
%%
%%
handle_cast(reset, State) ->
	erlang:erase(),
	{noreply, State};

handle_cast({pkt, method, Channel, Size, 'basic.deliver', Rest}, State) ->
	put({Channel, state}, {start, basic.deliver}),
	%% reset any previsouly received Header
	put({Channel, header}, undefined),
	%% reset any previsouly received Body
	put({Channel, body}, undefined),
	{noreply, State};

%handle_cast({pkt, method, Channel, Size, 'basic.return', Rest}, State) ->
%	put({Channel, state}, {start, basic.return}),
%	{noreply, State};

%handle_cast({pkt, method, Channel, Size, 'basic.get.ok', Rest}, State) ->
%	put({Channel, state}, {start, basic.get.ok}),
%	{noreply, State};


%% Drop other Method messages
%%
%%  Deliver pending messages to the channel: the receipt of Method frames
%%  effectively signals the end of a Content delivery event.
%%
handle_cast({pkt, method, _Channel, _Size, _, _Rest}, State) ->
	{noreply, State};


%% Store the Header part of the message for delivery when
%%	the complete message gets here
%%
handle_cast({pkt, header, Channel, _Size, Header}, State) ->
	put({Channel, header}, Header),
	%io:format("cc.server: header: ~p~n", [Header]),
	{noreply, State};

handle_cast({pkt, body, Channel, Size, Payload}, State) ->
	%io:format("cc.server: body: ~p~n", [Payload]),
	Header=get({Channel, header}),
	case Header of
		undefined -> 
			error_logger:warning_msg("cc.server: received Body frame but can't find Header context for Channel(~p)", [Channel]);
		{_, _, BodySize, _} ->
			handle_body(State, Channel, Size, BodySize, Payload)
	end,
	{noreply, State};

handle_cast(Msg, State) ->
	error_logger:info_msg("cc.server: unexpected msg: ~p", [Msg]),
    {noreply, State}.

 
%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
handle_body(State, Channel, Size, BodySize, Payload) ->
	BodyData=get({Channel, body}),
	{CurrentSize, Data}=case BodyData of
		undefined -> {0, <<>>};
		_         -> BodyData
	end,
	NewSize=CurrentSize+Size,
	NewData= <<Data/binary, Payload:Size/binary>>,
	NewBodyData={NewSize, NewData},
	%io:format("handle_body: Size: ~p CurrentSize: ~p  NewSize:~p~n", [Size, CurrentSize, NewSize]),
	case NewSize==BodySize of
		false -> 
				put({Channel, body}, NewBodyData);
		true  -> 
			put({Channel, header}, undefined),
			put({Channel, body},   undefined),
			io:format("cc.server: packet: ~p~n", [NewBodyData])
	end.
