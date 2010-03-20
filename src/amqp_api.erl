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
-export([ 'open.conn'/0, 'open.conn'/2, 'open.conn'/4 
		, 'open.chan'/1 
		]).

%% management functions
-export([ start/0 ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

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
	gen_server:cast(?SERVER, {self(), 'open.conn', default, default, default, default}).
													  
'open.conn'(Username, Password) ->
	gen_server:cast(?SERVER, {self(), 'open.conn', Username, Password, default, default}).

'open.conn'(Username, Password, Address, Port) ->
	gen_server:cast(?SERVER, {self(), 'open.conn', Username, Password, Address, Port}).

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

start() ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).



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
init([]) ->
    {ok, #state{}}.

handle_call(_,__,_) -> ok.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
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

