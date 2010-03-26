%%% -------------------------------------------------------------------
%%% Author  : jldupont
%%% Description :
%%%
%%% States:
%%%		none   : no connection established
%%%		start  : starting connection procedure
%%%		auth   : authentication phase
%%%		nego   : negotiation phase
%%%		open   : connection open
%%%		closed : 
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

-record(state, {cstate=none, server, tserver, wserver}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link([Server, TransportServer, WriterServer]) ->
	gen_server:start_link({local, Server}, ?MODULE, [Server, TransportServer, WriterServer], []).

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
init([Server, TransportServer, WriterServer]) ->
    {ok, #state{server=Server, tserver=TransportServer, wserver=WriterServer}}.

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

%% Success in opening Transport socket
%%
handle_cast({ok, transport.open}, State) ->
	ok;

%% Success in sending initial Protocol Header to AMQP server
%%
handle_cast({ok, transport.ready}, State) ->
	ok;

%% Error in opening Transport socket
%%
handle_cast({error, transport.closed}, State) ->
	ok;

handle_cast({amqp.packet, ?TYPE_METHOD, Channel, Size, <<ClassId:16, MethodId:16, Rest/binary>>}, State) ->
	Method=amqp_proto:imap(ClassId, MethodId),
	NewState=handle_method(State, Channel, Size, Method, Rest),
	{noreply, NewState};

handle_cast({amqp.packet, Type, Channel, Size, FramePayload}, State) ->
	io:format("> conn, frame, type:~p  payload:~p ~n", [Type, FramePayload]),
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
%%% Internal functions
%% --------------------------------------------------------------------
handle_method(State, Channel, Size, 'connection.start'=Method, Payload) ->
	Result=amqp_proto:decode_method(Method, Payload),
  	io:format("> Conn, method: ~p  result: ~p~n", [Method, Result]),
	State;

handle_method(State, Channel, Size, Method, Payload) ->
	io:format("> conn, method: ~p~n", [Method]),
	State.

	
