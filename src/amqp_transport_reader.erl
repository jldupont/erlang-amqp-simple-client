%% Author: jldupont
%% Created: Mar 23, 2010
%% Description: amqp_transport_reader
%%
%% States:
%%	wait.init   : waiting for initialization
%%	wait.header : waiting for header
%%	wait.payload : waiting for payload
%%
%%
-module(amqp_transport_reader).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("amqp.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {cstate=wait.init, socket=none, host=none, port=none,
				server=none, tserver=none, cserver=none, wserver=none}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, TransportServer, ConnServer, WriterServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, TransportServer, ConnServer, WriterServer], []).

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
init([Server, TransportServer, ConnServer, WriterServer]) ->
    {ok, #state{cstate=wait.init,
				server=Server, tserver=TransportServer, cserver=ConnServer, wserver=WriterServer}}.

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

%% Grab socket parameter regardless of current state
%%
%%
handle_cast({From, socket, Socket}, State) ->
	gen_server:cast(self(), {From, do.wait.header}),
    {noreply, State#state{cstate=wait.header, socket=Socket}};

%% Wait for the Header part of a protocol unit
%%
%%  Upon success, proceed to wait.payload
%%  Upon timeout, retry
%%  Upon network error, send event to Transport.Server
%%
handle_cast({From, do.wait.header}, State=#state{cstate=wait.header}) ->
	Socket=State#state.socket,
	case gen_tcp:recv(Socket, ?FRAME_HEADER_LENGTH, ?TIMEOUT_WAIT_HEADER) of
		{ok, FrameHeader} ->
			%io:format("> reader, header: ~p~n", [FrameHeader]),
			State2=State#state{cstate=wait.payload},
			gen_server:cast(self(), {From, do.wait.payload, FrameHeader});
		{error, timeout} ->
			%io:format("> reader, timeout~n"),
			State2=State,
			gen_server:cast(self(), {From, do.wait.header});
		{error, Reason} ->
			%io:format("> reader, error, reason: ~p~n", [Reason]),
			State2=State#state{cstate=wait.init},
			Tserver=State#state.tserver,
			gen_server:cast(Tserver, {error, {'transport.reader.wait.header', Reason}})
	end,
    {noreply, State2};

%% Wait for Payload part of protocol unit
%%
%%  Upon success, transfer whole frame to Connection.Server & return to wait.header
%%	Upon timeout, signal error to Transport.Server
%%	Upon network error, signal error to Transport.Server
%%
handle_cast({From, do.wait.payload, <<Type:8, Channel:16, Size:32>>}, State=#state{cstate=wait.payload}) ->
	io:format("> reader, wait.payload, type:~p  size:~p~n", [Type, Size]),
	Socket=State#state.socket,
	
	case gen_tcp:recv(Socket, Size+1, ?TIMEOUT_WAIT_PAYLOAD) of
		{ok, FramePayload} ->
			State2=State#state{cstate=wait.header},
			ConnServer=State#state.cserver,
			
			%% Send-off complete AMQP protocol packet to Connection Agent
			%% ==========================================================
			gen_server:cast(ConnServer, {amqp.packet, Type, Channel, Size, FramePayload}),
			gen_server:cast(self(), {From, do.wait.header});
		
			%% Errors should be few in between... setup Tserver just then 
		{error, Reason} ->
			State2=State#state{cstate=wait.init},
			Tserver=State#state.tserver,
			gen_server:cast(Tserver, {error, {'transport.reader.wait.payload', Reason}})
	end,
	{noreply, State2};

%% Discard message from queue...
handle_cast(_Msg, State) ->
	{noreply, State}.


%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	io:format(">reader: Info: ~p *** State: ~p~n", [Info, State]),
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

