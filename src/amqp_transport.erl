%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description : Module responsible of the "Transport" layer
%%%					to the AMQP broker.  The transport protocol is 
%%%					TCP over IP. 
%%%				The protocol framing is also handled here. 
%%%
%%% Transport states:  
%%%		wait.open  -> no transport established yet - waiting for socket parameters
%%%		opened     -> connection opened, sending start "protocol header"
%%%
%%%
%%% Events:
%%%		OOS (Out Of Sync)
%%%		Remote Close
%%%
%%%
%%%	API:
%%%		'open'  : opens the TCP/IP transport connection & sends the initial protocol-header (4.2.2)
%%%		'close' : close the
%%%
%%%
%%% Messages:
%%% ---------
%%%
%%%  server  <-- open   ---  api.server
%%%  server  --- {error, transport.open} --> api.server
%%%  server  --- socket -->  reader.server
%%%  server  --- socket -->  writer.server
%%%  server  --- transport.open  --> conn.server
%%%  server  --- transport.ready --> conn.server
%%%
%%%
%%% Created : Mar 19, 2010
%%% -------------------------------------------------------------------
-module(amqp_transport).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {cstate=wait.open, 
				client=none,
				socket=none, address=none, port=none, vhost=none,
				options=[],
				server=none, cserver=none, rserver=none, wserver=none
				}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, ConnServer, ReaderServer, WriterServer]) ->
	io:format("* Transport starting~n"),
	gen_server:start_link({local, Server}, ?MODULE, [Server, ConnServer, ReaderServer, WriterServer], []).


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
init([Server, ConnServer, ReaderServer, WriterServer]) ->
    {ok, #state{cstate=wait.open, 
				server=Server, cserver=ConnServer, 
				rserver=ReaderServer, wserver=WriterServer}}.

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

%% Open the TCP transport socket
%%
%%	Upon success, signal to Connection.Server
%%	Upon failure, signal back to Client
%%
handle_cast({_From=Client, open, [Address, Port, FrameMax], Opts}, State=#state{cstate=wait.open}) ->
	{ok, TcpOptions}=application:get_env(amqp.tcp.options),
	case gen_tcp:connect(Address, Port, TcpOptions) of
		{ok, Socket} ->
			State2=State#state{cstate=opened, socket=Socket, options=Opts, client=Client
							  ,address=Address, port=Port},
			Rserver=State#state.rserver,
			Wserver=State#state.wserver,
			Cserver=State#state.cserver,
			gen_server:cast(Rserver, {self(), socket, Socket}),
			gen_server:cast(Wserver, {self(), socket, Socket, FrameMax}),
			gen_server:cast(Cserver, {ok, {transport, open}});
		{error, Reason} ->
			State2=State,
			Cserver=State#state.cserver,
			gen_server:cast(Cserver, {error, {transport.open, Reason}})
	end,
    {noreply, State2};

handle_cast({_From, open, _Host, _Port}, State) ->
	Cserver=State#state.cserver,
	gen_server:cast(Cserver, {ok, {transport, already.active}}),
    {noreply, State};

handle_cast({ok, 'transport.writer.send.protocol.start.header'}, State) ->
	Cserver=State#state.cserver,
	gen_server:cast(Cserver, {ok, {transport, ready}}),
	{noreply, State};

handle_cast(Msg={error, {transport.writer.send, unexpected.pkt}}, State) ->
	Cserver=State#state.cserver,
	gen_server:cast(Cserver, Msg),
	{noreply, State};


%% Discard message that might have been generated by a race condition
%%
handle_cast({error, {_Error, _Reason}}, State=#state{socket=none}) ->
	{noreply, State#state{cstate=wait.open}};

%% Transport connection / Network error
%%
%% No need to inform Reader & Writer : they'll be ok when re-init comes
%%
handle_cast({error, {Error, Reason}}, State) ->
	error_logger:warning_msg("transport.server: received error notification(~p): Reason: ~p", [Error, Reason]),
	do_close(State, Reason),
	{noreply, State#state{socket=none, cstate=wait.open}};


handle_cast(Msg, State) ->
	error_logger:warning_msg("transport.server: unexpected msg: ~p", [Msg]),
	{noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({From, open, Params, Options}, State) ->
	gen_server:cast(self(), {From, open, Params, Options}),
    {noreply, State};

handle_info(Info, State) ->
	error_logger:warning_msg("Transport.server: unexpected info: ~p", [Info]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	io:format("!! Transport: terminate~n"),
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
do_close(State, Reason) ->
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, close),
	
	ConnServer=State#state.cserver,
	gen_server:cast(ConnServer, {error, {transport.closed, Reason}}),
	
	Socket=State#state.socket,
	gen_tcp:close(Socket).

