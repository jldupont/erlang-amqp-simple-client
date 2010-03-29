%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description :
%%%
%%% States:
%%%		wait.start   : no connection established
%%%		wait.secure  : waiting for Secure method
%%%		wait.tune    : waiting for Tune method
%%%		wait.open.ok : waiting for Open.ok method
%%%		active       : connection active - processing
%%%
%%% Created : Mar 19, 2010
%%% -------------------------------------------------------------------
-module(amqp_conn).

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

-record(state, {cstate, server, tserver, wserver, ccserver,
				user, password, vhost}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, TransportServer, WriterServer, CCMsgServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, TransportServer, WriterServer, CCMsgServer], []).

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
init([Server, TransportServer, WriterServer, CCMsgServer]) ->
    {ok, #state{cstate=wait.start, server=Server, tserver=TransportServer, wserver=WriterServer, ccserver=CCMsgServer}}.

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

handle_cast({conn.params, Username, Password, Vhost}, State) ->
	{noreply, State#state{user=Username, password=Password, vhost=Vhost}};

%% Success in opening Transport socket
%%
%%  Signal the C-to-C messaging agent to reset
%%
handle_cast({ok, transport.open}, State) ->
	CCServer=State#state.ccserver,
	gen_server:cast(CCServer, reset),
	{noreply, State};

%% Success in sending initial Protocol Header to AMQP server
%%
handle_cast({ok, transport.ready}, State) ->
	{noreply, State};

%% Error in opening Transport socket
%%
handle_cast({error, transport.closed}, State) ->
	{noreply, State};

%%  AMQP Management Protocol  (channel==0)
%%
%%
handle_cast({amqp.packet, ?TYPE_METHOD, 0, Size, <<ClassId:16, MethodId:16, Rest/binary>>}, State) ->
	Method=amqp_proto:imap(ClassId, MethodId),
	NewState=handle_method(State, 0, Size, Method, Rest),
	{noreply, NewState};


%%  Client-to-Client messaging
%%
%%  Send to CCMsg server
%%
handle_cast({amqp.packet, ?TYPE_METHOD, Channel, Size, <<ClassId:16, MethodId:16, Rest/binary>>}, State) ->
	Method=amqp_proto:imap(ClassId, MethodId),
	CCMsgServer=State#state.ccserver,
	gen_server:cast(CCMsgServer, {pkt, method, Channel, Size, Method, Rest}),
	{noreply, State};

handle_cast({amqp.packet, ?TYPE_HEADER, Channel, Size, Payload}, State) ->
	Header=amqp_proto:decode_header(Payload),
	CCMsgServer=State#state.ccserver,
	gen_server:cast(CCMsgServer, {pkt, header, Channel, Size, Header}),
	{noreply, State};

handle_cast({amqp.packet, ?TYPE_BODY, Channel, Size, Payload}, State) ->
	CCMsgServer=State#state.ccserver,
	gen_server:cast(CCMsgServer, {pkt, body, Channel, Size, Payload}),
	{noreply, State};


%%%%%%%%%%%%%%%%%% CATCH-ALL %%%%%%%%%%%%%%%%%%%%%

handle_cast(Msg, State) ->
	io:format("> conn: msg: ~p~n", [Msg]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	io:format(">conn: Info: ~p *** State: ~p~n", [Info, State]),
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
%%% MAIN state-machine
%% --------------------------------------------------------------------


%% Received "start" method ==> generate "start.ok" method
%%
handle_method(State, Channel, Size, 'connection.start'=Method, Payload) when State#state.cstate==wait.start ->
	Result=amqp_proto:decode_method(Method, Payload),
	error_logger:info_msg("Connection.start: ~p", [Result]),
	Frame=frame_method(State, 'connection.start.ok'),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, 0, Frame}),
	State#state{cstate=wait.tune};

handle_method(State, _Channel, _Size, 'connection.start'=_Method, _Payload) ->
	Tserver=State#state.tserver,
	gen_server:cast(Tserver, {error, {amqp.proto.error, unexpected.start.method}}),
	State#state{cstate=wait.start};

handle_method(State, _Channel, _Size, 'connection.tune'=Method, Payload) when State#state.cstate==wait.tune ->
	Result=amqp_proto:decode_method(Method, Payload),
	error_logger:info_msg("Connection.tune: ~p", [Result]),
	Frame=frame_method(State, 'connection.tune.ok'),
	
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, 0, Frame}),
	
	FrameOpen=frame_method(State, 'connection.open'),
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, 0, FrameOpen}),

	State#state{cstate=wait.open.ok};


handle_method(State, Channel, Size, Method, Payload) ->
	io:format("> conn, method: ~p~n", [Method]),
	State.

	
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

frame_method(State, 'connection.start.ok') ->
	{ok, Cprops}=application:get_env(client.properties),
	{ok, Mechanism}=application:get_env(default.login.method),
	
	<<_Size:32, LoginTable/binary>> =amqp_proto:encode_table([{"LOGIN", longstr, State#state.user}, 
															  {"PASSWORD", longstr, State#state.password}]),
	
	{ok, Locale}=application:get_env(default.locale),
	
	Params=amqp_proto:encode_method_params([{table, Cprops}
										   ,{shortstr, Mechanism}
										   ,{longstr, erlang:binary_to_list(LoginTable)}
										   ,{shortstr, Locale}
										   ]),
	Method=amqp_proto:emap('connection.start.ok'),
	<<Method/binary, Params/binary>>;

frame_method(_State, 'connection.tune.ok') ->
	{ok, ChannelMax}=application:get_env(default.channel.max),
	{ok, FrameMax}=application:get_env(default.frame.max),
	{ok, Heartbeat}=application:get_env(default.heartbeat),
	Params=amqp_proto:encode_method_params([{short, ChannelMax}
										   ,{long, FrameMax}
										   ,{short, Heartbeat}
										   ]),
	Method=amqp_proto:emap('connection.tune.ok'),
	<<Method/binary, Params/binary>>;


frame_method(State, 'connection.open') ->
	Vhost=State#state.vhost,
	VhostParam = amqp_proto:encode_prim(shortstr, Vhost),
	Method=amqp_proto:emap('connection.open'),
	<<Method/binary, VhostParam/binary>>.

	


	