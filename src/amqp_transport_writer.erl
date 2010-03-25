%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description :
%%%
%%% States:
%%%		wait.socket : waiting for socket parameters
%%%
%%%
%%%
%%%
%%%
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

-record(state, {cstate=wait.socket, socket=none, server=none, tserver=none}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, TransportServer]) ->
	io:format("* Transport Writer starting~n"),
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
handle_cast({From, socket, Socket}, State) ->
	case gen_tcp:send(Socket, ?PROTOCOL_HEADER) of
		ok ->
			From ! {ok, 'transport.writer.send.protocol.start.header'},
			State2=State#state{cstate=wait.frame};
		{error, Reason} ->
			State2=State#state{cstate=wait.socket},
			gen_tcp:close(Socket),
			From ! {error, {'transport.writer.send.header', Reason}}
	end,
	{noreply, State2};

handle_cast(Msg, State) ->
	io:format("! Writer state: ~p  msg: ~p", [State#state.cstate, Msg]),
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

