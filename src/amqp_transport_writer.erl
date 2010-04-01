%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description :  Frame and send protocol units down the TCP socket
%%%
%%% States:
%%%		wait.socket : waiting for socket parameters
%%%     wait.write  : waiting for packet/message to frame and transmit
%%%
%%%
%%% Created : Mar 23, 2010
%%% -------------------------------------------------------------------
-module(amqp_transport_writer).

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

-record(state, {cstate=wait.socket, socket=none, server=none, tserver=none, fmax=none}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, TransportServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, TransportServer], []).

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
init([Server, TransportServer]) ->
    {ok, #state{cstate=wait.socket,
				server=Server, tserver=TransportServer}}.

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

%% When the Transport server detects that the connection is down,
%%  quicker convergence on this server.
%%
handle_cast(close, State) ->
	{noreply, State#state{cstate=wait.socket}};


%% Message from Transport.Server
%%  
%% Upon Success/Failure, signal back to Transport.Server
%%
handle_cast({_From, socket, Socket, FrameMax}, State) ->
	Tserver=State#state.tserver,
	case gen_tcp:send(Socket, ?PROTOCOL_HEADER) of
		ok ->
			State2=State#state{cstate=wait.write, socket=Socket, fmax=FrameMax},
			gen_server:cast(Tserver, {ok, 'transport.writer.send.protocol.start.header'});
		{error, Reason} ->
			%io:format("!! Writer/socket: error, reason: ~p~n", [Reason]),
			State2=State#state{cstate=wait.socket, socket=none},
			gen_tcp:close(Socket),
			gen_server:cast(Tserver, {error, {'transport.writer.send.header', Reason}})
	end,
	{noreply, State2};

handle_cast({_From, packet, Type, Channel, Payload}, State=#state{cstate=wait.write}) ->
	Socket=State#state.socket,
	Len=erlang:size(Payload),
	Frame= <<Type:8, Channel:16, Len:32, Payload/binary, 16#ce:8>>,
	case gen_tcp:send(Socket, Frame) of
		ok ->
			State2=State;
		{error, Reason} ->
			gen_tcp:close(Socket),
			State2=State#state{socket=none, cstate=wait.socket},
			Tserver=State#state.tserver,
			gen_server:cast(Tserver, {error, {transport.writer.send, Reason}})
	end,
	{noreply, State2};

handle_cast({_From, msg, Channel, Method, MethodFrame, Message}, State=#state{cstate=wait.write}) ->
	NewState=handle_msg({Channel, Method, MethodFrame, Message}, State),
	{noreply, NewState};


handle_cast({_From, packet, _Type, _Channel, _Payload}, State=#state{cstate=wait.socket}) ->
	Tserver=State#state.tserver,
	gen_server:cast(Tserver, {error, {transport.writer.send, unexpected.pkt}}),
	{noreply, State};

handle_cast(Msg, State=#state{cstate=wait.socket}) ->
	error_logger:warning_msg("writer.server: (in wait.socket) unexpected msg: ~p", [Msg]),
	{noreply, State};

handle_cast(Msg, State) ->
	error_logger:warning_msg("writer.server: unexpected msg: ~p", [Msg]),
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


%% --------------------------------------------------------------------------------------- %%
%% --------------------------------------------------------------------------------------- %%
%% --------------------------------------------------------------------------------------- %%


%% Message sending
%%
%%  3step process:
%%  a) write Method frame
%%	b) write Header frame
%%  c) write Body frame
%%
handle_msg({Channel, Method, MethodFrameData, Message}, State) ->

	%% (a)
	Len=erlang:size(MethodFrameData),
	MethodFrame= <<?TYPE_METHOD:8, Channel:16, Len:32, MethodFrameData/binary, 16#ce:8>>,

	

	ok.

