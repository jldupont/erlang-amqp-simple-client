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
%%%	api --- open        ---> transport.server
%%% api --- conn.params ---> conn.server
%%%
%%%
%%%
%%%
%%%
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
%% External exports
-export([ 'conn.open'/0, 'conn.open'/5 
		, 'chan.open'/1
		, 'exchange.declare'/7
		, 'queue.bind'/5
		, 'basic.consume'/7
		]).

%% management functions
-export([ start_link/1 ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {cstate, server, tserver, cserver, wserver,
				user, password, address, port, vhost
				}).

%% ====================================================================
%% API - External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 'open.conn'/0
%% Description: Opens a connection using the default parameters
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
'conn.open'() ->
	gen_server:cast(?SERVER, {self(), 'conn.open'}).
													  
'conn.open'(Username, Password, Address, Port, Vhost) ->
	gen_server:cast(?SERVER, {self(), 'conn.open', Username, Password, Address, Port, Vhost}).

%% --------------------------------------------------------------------
%% Function: 'open.chan'/1
%% Description: Opens a channel over the existing connection
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
'chan.open'(Ref) when is_integer(Ref) ->
	gen_server:cast(?SERVER, {self(), 'chan.open', Ref});

'chan.open'(Ref) ->
	{error, {invalid.parameter, Ref}}.


%'exchange.declare
'exchange.declare'(Channel, Name, Type, Durable, AutoDelete, Internal, NoWait) ->
	case is_list(Name) of
		true -> ok;
		_    -> erlang:error({error, {invalid.parameter, name, Name}})
	end,
	case Type of
		direct -> ok;
		fanout -> ok;
		topic  -> ok;
		_      -> erlang:error({error, {invalid.parameter, type, Type}})
	end,
	case Durable of
		true  -> ok;
		false -> ok;
		_      -> erlang:error({error, {invalid.parameter, durable, Durable}})
	end,
	case AutoDelete of
		true  -> ok;
		false -> ok;
		_      -> erlang:error({error, {invalid.parameter, auto.delete, AutoDelete}})
	end,
	case Internal of
		true  -> ok;
		false -> ok;
		_      -> erlang:error({error, {invalid.parameter, internal, Internal}})
	end,
	case NoWait of
		true  -> ok;
		false -> ok;
		_      -> erlang:error({error, {invalid.parameter, nowait, NoWait}})
	end,	
	EType=erlang:atom_to_list(Type),
	gen_server:cast(?SERVER, {self(), 'exchange.declare', Channel, [Name, EType, Durable, AutoDelete, Internal, NoWait]}).


%% Queue.bind
%%
'queue.bind'(Channel, Name, ExchangeName, RoutingKey, NoWait) ->
	case is_integer(Channel) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, channel, Channel}})
	end,
	case is_list(Name) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, name, Name}})
	end,
	case is_list(ExchangeName) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, exchange.name, ExchangeName}})
	end,
	case is_list(RoutingKey) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, routing.key, RoutingKey}})
	end,
	case NoWait of
		true  -> ok;
		false -> ok;
		_     -> erlang:error({error, {invalid.parameter, nowait, NoWait}})
	end,
	gen_server:cast(?SERVER, {self(), 'queue.bind', Channel, [Name, ExchangeName, RoutingKey, NoWait]}).
		
%% Basic.consume
%%
%%
'basic.consume'(Channel, Queue, ConsumerTag, NoLocal, NoAck, Exclusive, NoWait) ->
	case is_integer(Channel) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, channel, Channel}})
	end,
	case is_list(Queue) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, queue, Queue}})
	end,
	case is_list(ConsumerTag) of
		true  -> ok;
		false -> erlang:error({error, {invalid.parameter, consumer.tag, ConsumerTag}})
	end,
	case NoLocal of
		true  -> ok;
		false -> ok;
		_     -> erlang:error({error, {invalid.parameter, no.local, NoLocal}})
	end,
	case NoAck of
		true  -> ok;
		false -> ok;
		_     -> erlang:error({error, {invalid.parameter, no.ack, NoAck}})
	end,
	case Exclusive of
		true  -> ok;
		false -> ok;
		_     -> erlang:error({error, {invalid.parameter, exclusive, Exclusive}})
	end,
	case NoWait of
		true  -> ok;
		false -> ok;
		_     -> erlang:error({error, {invalid.parameter, nowait, NoWait}})
	end,	
	gen_server:cast(?SERVER, {self(), 'basic.consume', Channel, [Queue, ConsumerTag, NoLocal, NoAck, Exclusive, NoWait]}).

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
    {ok, #state{server=Server, tserver=TransportServer, cserver=ConnServer, wserver=WriterServer}}.

handle_call(_,__,_) -> ok.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({From, 'conn.open'}, State) ->
	Username=getpar(default.user),
	Password=getpar(default.password),
	Address=getpar(default.address),
	Port=getpar(default.port),
	Vhost=getpar(default.vhost),
	gen_server:cast(self(), {From, 'conn.open', Username, Password, Address, Port, Vhost}),
	{noreply, State};

handle_cast({From, 'conn.open', Username, Password, Address, Port, Vhost}, State) ->
	io:format("> conn, opening, username: ~p password: ~p ~n",[Username, Password]),
	
	%% Connection related settings first, manage possible race-condition
	ConnServer=State#state.cserver,
	gen_server:cast(ConnServer, {conn.params, Username, Password, Vhost}),
	
	TransportServer=State#state.tserver,
	gen_server:cast(TransportServer, {From, open, [Address, Port], []}),
	{noreply, State#state{user=Username, password=Password, address=Address, port=Port, vhost=Vhost}};


%% channel.open
%%
handle_cast({_From, 'chan.open', Ref}, State) ->
	MethodFrame=amqp_proto:encode_method('channel.open', void),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, Ref, MethodFrame}),
	{noreply, State};

%% Exchange.Declare
%%
%%  Access ticket: 0 (default)
%%  Passive: false
%%
handle_cast({_From, 'exchange.declare', Channel, Params}, State) ->
	Payload=amqp_proto:encode_method('exchange.declare', Params),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, Channel, Payload}),	
	{noreply, State};

%% Queue.bind
%%
handle_cast({_From, 'queue.bind', Channel, Params}, State) ->
	Payload=amqp_proto:encode_method('queue.bind', Params),
	Wserver=State#state.wserver,
	gen_server:cast(Wserver, {self(), packet, ?TYPE_METHOD, Channel, Payload}),	
	{noreply, State};

%% Basic.consume
%%
handle_cast({_From, Method='basic.consume', Channel, Params}, State) ->
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

