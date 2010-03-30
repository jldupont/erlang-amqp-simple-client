%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description : AMQP Connection handling
%%%
%%% The protocol units that come in through the Transport server process
%%% eventually come through here.  
%%%
%%% The protocol units destined to the Client are forwarded to the CC server
%%% whilst the other protocol packets are decoded and analyzed here: most
%%% and then forwarded to the API server.
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

-record(state, {cstate, server, tserver, wserver, ccserver, aserver,
				user, password, vhost}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, TransportServer, WriterServer, CCMsgServer, ApiServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, TransportServer, WriterServer, CCMsgServer, ApiServer], []).

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
init([Server, TransportServer, WriterServer, CCMsgServer, ApiServer]) ->
    {ok, #state{cstate=wait.start, server=Server, 
				tserver=TransportServer, wserver=WriterServer, 
				ccserver=CCMsgServer, aserver=ApiServer}}.

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
handle_cast({error, {transport.open, Reason}}, State) ->
	error_logger:error_msg("conn.server: error opening transport, reason: ~p", [Reason]),
	{noreply, State#state{cstate=wait.start}};


%% Error in opening Transport socket
%%
handle_cast({error, transport.closed}, State) ->
	{noreply, State};

%%  AMQP Management Protocol  (channel==0)
%%
%%
handle_cast({amqp.packet, ?TYPE_METHOD, 0, Size, <<ClassId:16, MethodId:16, Rest/binary>>}, State) ->
	Method=amqp_proto:imap(ClassId, MethodId),
	error_logger:info_msg("conn.server: handling Method(~p)", [Method]),
	NewState=handle_method(State, 0, Size, Method, Rest),
	{noreply, NewState};



%%  Server-to-Client Management  &
%%  Client-to-Client messaging
%%
%%  Send to CCMsg server
%%
handle_cast({amqp.packet, ?TYPE_METHOD, Channel, Size, <<ClassId:16, MethodId:16, Rest/binary>>}, State) ->
	Method=amqp_proto:imap(ClassId, MethodId),
	error_logger:info_msg("conn.server: handling Client Method(~p) on Channel(~p)", [Method, Channel]),
	NewState=handle_cmethod(State, {Channel, Size, Method, Rest}),
	%CCMsgServer=State#state.ccserver,
	%gen_server:cast(CCMsgServer, {pkt, method, Channel, Size, Method, Rest}),
	{noreply, NewState};

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



%% Channel.open.ok
%%
handle_cmethod(State, {Channel, _Size, 'channel.open.ok', _Payload}) ->
	ApiServer=State#state.aserver,
	gen_server:cast(ApiServer, {channel.open.ok, Channel}),
	State;

%% Exchange.declare.ok
%%
handle_cmethod(State, {Channel, _Size, 'exchange.declare.ok', _Payload}) ->
	ApiServer=State#state.aserver,
	gen_server:cast(ApiServer, {exchange.declare.ok, Channel}),
	State;

%% Queue.bind.ok
%%
handle_cmethod(State, {Channel, _Size, 'queue.bind.ok', _Payload}) ->
	ApiServer=State#state.aserver,
	gen_server:cast(ApiServer, {queue.bind.ok, Channel}),
	State;

%% Basic.consume.ok
%%
handle_cmethod(State, {Channel, _Size, 'basic.consume.ok', _Payload}) ->
	ApiServer=State#state.aserver,
	gen_server:cast(ApiServer, {basic.consume.ok, Channel}),
	State;

%% Basic.deliver
%%
handle_cmethod(State, {Channel, _Size, 'basic.deliver', Payload}) ->
	ApiServer=State#state.aserver,
	gen_server:cast(ApiServer, {basic.deliver, Channel, Payload}),
	State;

handle_cmethod(State, Msg) ->
	error_logger:error_msg("conn.server:cmethod: unexpected msg: ~p", [Msg]),
	State.


%%% ------------------------------------------------------------------------- %%%
%%% ------------------------------------------------------------------------- %%%
%%% ------------------------------------------------------------------------- %%%




%% Connection.start
%%
%% Received "start" method ==> generate "start.ok" method
%%
handle_method(State, _Channel, _Size, 'connection.start'=Method, Payload) when State#state.cstate==wait.start ->
	Result=amqp_proto:decode_method(Method, Payload),
	error_logger:info_msg("Connection.start: ~p", [Result]),
	Username=State#state.user,
	Password=State#state.password,
	Frame=amqp_proto:encode_method('connection.start.ok', [Username, Password]),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, 0, Frame}),
	State#state{cstate=wait.tune};

%% Connection.start
%%
handle_method(State, _Channel, _Size, 'connection.start'=_Method, _Payload) ->
	Tserver=State#state.tserver,
	gen_server:cast(Tserver, {error, {amqp.proto.error, unexpected.start.method}}),
	State#state{cstate=wait.start};

%% Connection.tune
%%
handle_method(State, _Channel, _Size, 'connection.tune'=Method, Payload) when State#state.cstate==wait.tune ->
	Result=amqp_proto:decode_method(Method, Payload),
	error_logger:info_msg("Connection.tune: ~p", [Result]),
	Frame=amqp_proto:encode_method('connection.tune.ok', []),
	
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, 0, Frame}),
	
	Vhost=State#state.vhost,
	FrameOpen=amqp_proto:encode_method('connection.open', [Vhost]),
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, 0, FrameOpen}),

	State#state{cstate=wait.open.ok};

%% Connection.close
%%
handle_method(State, _Channel, _Size, 'connection.close'=Method, Payload) ->
	Result=amqp_proto:decode_method(Method, Payload),
	error_logger:info_msg("Connection.close: ~p", [Result]),
	State#state{cstate=wait.start};
	

%% Connection.open.ok
%%
handle_method(State, _Channel, _Size, 'connection.open.ok', _Payload) ->
	ApiServer=State#state.aserver,
	gen_server:cast(ApiServer, connection.open.ok),
	State;


handle_method(State, Channel, _Size, Method, _Payload) ->
	error_logger:warning_msg("Connection.server: unexpected Method: ~p, Channel: ~p", [Method, Channel]),
	State.

	
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

	


	