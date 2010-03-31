%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description :
%%%
%%% States:
%%%  
%%%
%%%
%%%
%%%
%%%
%%%
%%% Messages:
%%% ---------
%%%
%%% {ok, {transport, open}}
%%% {ok, {transport, ready}}
%%% {error, {transport.open, Reason}}
%%% {error, {transport.closed, Reason}}
%%%
%%%
%%%
%%%
%%% Created : Mar 19, 2010
%%% -------------------------------------------------------------------
-module(amqp_api).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("amqp.hrl").

%% --------------------------------------------------------------------
%% Defines
%% --------------------------------------------------------------------
-define(SERVER, amqp.api.server).

%% --------------------------------------------------------------------
%% API -- External exports
%% --------------------------------------------------------------------
-export([ 'conn.open'/0, 'conn.open'/5 
		, 'chan.open'/1
		, 'exchange.declare'/7
		, 'queue.declare'/7
		, 'queue.delete'/5
		, 'queue.bind'/5
		, 'basic.consume'/7
		]).

%% management functions
-export([ start_link/1 ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {cstate, client,
				user, password, address, port, vhost, 
				server, tserver, cserver, wserver
				}).

%% ====================================================================
%% API - External functions
%% ====================================================================

%% Connection.open
%%
'conn.open'() ->
	gen_server:cast(?SERVER, {self(), 'conn.open'}).

%% Connection.open
%%
'conn.open'(Username, Password, Address, Port, Vhost) ->
	amqp_misc:check_params([Username, Password, Address, Port, Vhost], 
						   [{string, username}, {string, password}, 
							{string, address}, {int, port}, {string, vhost}]),
	gen_server:cast(?SERVER, {self(), 'conn.open', Username, Password, Address, Port, Vhost}).

%% Channel.open
%%
'chan.open'(Ref) ->
	amqp_misc:check_params([Ref], [{int, channel.ref}]),
	gen_server:cast(?SERVER, {self(), 'chan.open', Ref, []}).


%% 'Exchange.declare
%%
'exchange.declare'(Channel, Name, Type, Durable, AutoDelete, Internal, NoWait) ->
	amqp_misc:check_params([Channel, Name, Type, Durable, AutoDelete, Internal, NoWait], 
						   [{int, channel}, {string, exchange.name}, {choice, [direct, fanout, topic]},
							{bool, auto.delete}, {bool, internal}, {bool, no.wait}]),
	EType=erlang:atom_to_list(Type),
	gen_server:cast(?SERVER, {self(), 'exchange.declare', Channel, [Name, EType, Durable, AutoDelete, Internal, NoWait]}).


%% Queue.declare
%%
'queue.declare'(Channel, QueueName, Passive, Durable, Exclusive, AutoDelete, NoWait) ->
	amqp_misc:check_params([Channel, QueueName, Passive, Durable, Exclusive, AutoDelete, NoWait], 
						   [{int, channel}, {string, queue.name}, 
							{bool, passive}, {bool, durable}, {bool, exclusive}, {bool, auto.delete},
							{bool, no.wait}]),
	gen_server:cast(?SERVER, {self(), 'queue.declare', Channel, [QueueName, Passive, Durable, Exclusive, AutoDelete, NoWait]}).

%% Queue.delete
%%
'queue.delete'(Channel, QueueName, IfUnused, IfEmpty, NoWait) ->
	amqp_misc:check_params([Channel, QueueName, IfUnused, IfEmpty, NoWait], 
						   [{int, channel}, {string, queue.name}, 
							{bool, 'if.unused'}, {bool, 'if.empty'}, {bool, no.wait}]),
	gen_server:cast(?SERVER, {self(), 'queue.delete', Channel, [QueueName, IfUnused, IfEmpty, NoWait]}).
	

%% Queue.bind
%%
'queue.bind'(Channel, QueueName, ExchangeName, RoutingKey, NoWait) ->
	amqp_misc:check_params([Channel, QueueName, ExchangeName, RoutingKey, NoWait], 
						   [{int, channel}, {string, queue.name}, {string, exchange.name},
							{string, routing.key}, {bool, no.wait}]),
	gen_server:cast(?SERVER, {self(), 'queue.bind', Channel, [QueueName, ExchangeName, RoutingKey, NoWait]}).
		
%% Basic.consume
%%
%%
'basic.consume'(Channel, QueueName, ConsumerTag, NoLocal, NoAck, Exclusive, NoWait) ->
	amqp_misc:check_params([Channel, QueueName, ConsumerTag, NoLocal, NoAck, Exclusive, NoWait], 
						   [{int, Channel}, {string, QueueName}, {string, ConsumerTag},
							{bool, no.local}, {bool, no.ack}, {bool, exclusive}, {bool, no.wait}]),
	gen_server:cast(?SERVER, {self(), 'basic.consume', Channel, [QueueName, ConsumerTag, NoLocal, NoAck, Exclusive, NoWait]}).

%% ====================================================================
%% Management functions
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
    {ok, #state{server=Server, tserver=TransportServer, cserver=ConnServer, wserver=WriterServer,
				cstate=init, client=none
				}}.

handle_call(_,__,_) -> ok.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

%% Connection.open
%%
handle_cast({From, 'conn.open'}, State) ->
	Username=getpar(default.user),
	Password=getpar(default.password),
	Address=getpar(default.address),
	Port=getpar(default.port),
	Vhost=getpar(default.vhost),
	gen_server:cast(self(), {From, 'conn.open', Username, Password, Address, Port, Vhost}),
	{noreply, State};

handle_cast({From, 'conn.open', Username, Password, Address, Port, Vhost}, State) ->
	
	%% Connection related settings first, manage possible race-condition
	ConnServer=State#state.cserver,
	gen_server:cast(ConnServer, {conn.params, Username, Password, Vhost}),
	
	TransportServer=State#state.tserver,
	gen_server:cast(TransportServer, {From, open, [Address, Port], []}),
	
	%% Keep client process id
	{noreply, State#state{client=self(),
						  user=Username, password=Password, 
						  address=Address, port=Port, vhost=Vhost}};


%% channel.open
%%
handle_cast({_From, 'chan.open', Ref, []}, State) ->
	MethodFrame=amqp_proto:encode_method('channel.open', void),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, Ref, MethodFrame}),
	{noreply, State};

%% All methods
%%
handle_cast({_From, Method, Channel, Params}, State) ->
	Payload=amqp_proto:encode_method(Method, Params),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, Channel, Payload}),	
	{noreply, State};


handle_cast(Msg, State) ->
	error_logger:info_msg("api.server: unexpected msg: ~p", [Msg]),
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
getpar(Param) ->
	case application:get_env(Param) of
		{ok, Value} -> 
			Value;
		_ -> 
			erlang:error({error, {missing.app.parameter, Param}})
	end.

