%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description :
%%%
%%% Created : Mar 19, 2010
%%% -------------------------------------------------------------------
-module(amqp_api).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Defines
%% --------------------------------------------------------------------
-define(SERVER, amqp_api).

%% --------------------------------------------------------------------
%% External exports
-export([ 'open.conn'/0, 'open.conn'/5 
		, 'open.chan'/1 
		]).

%% management functions
-export([ start_link/1 ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {cstate, server, tserver, cserver,
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
'open.conn'() ->
	gen_server:cast(?SERVER, {self(), 'open.conn'}).
													  
'open.conn'(Username, Password, Address, Port, Vhost) ->
	gen_server:cast(?SERVER, {self(), 'open.conn', Username, Password, Address, Port, Vhost}).

%% --------------------------------------------------------------------
%% Function: 'open.chan'/1
%% Description: Opens a channel over the existing connection
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
'open.chan'(Ref) ->
	gen_server:cast(?SERVER, {self(), 'open.chan', Ref}).


%% ====================================================================
%% Management functions
%% ====================================================================

start_link([Server, TransportServer, ConnServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, TransportServer, ConnServer], []).



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
init([Server, TransportServer, ConnServer]) ->
    {ok, #state{server=Server, tserver=TransportServer, cserver=ConnServer}}.

handle_call(_,__,_) -> ok.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({From, 'open.conn'}, State) ->
	Username=getpar(default.user),
	Password=getpar(default.password),
	Address=getpar(default.address),
	Port=getpar(default.port),
	Vhost=getpar(default.vhost),
	gen_server:cast(self(), {From, 'open.conn', Username, Password, Address, Port, Vhost}),
	{noreply, State};

handle_cast({From, 'open.conn', Username, Password, Address, Port, Vhost}, State) ->
	{noreply, State#state{user=Username, password=Password, address=Address, port=Port, vhost=Vhost}};


handle_cast(Msg, State) ->
	io:format("Msg: ~p", [Msg]),
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

