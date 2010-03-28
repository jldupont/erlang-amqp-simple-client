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

handle_cast(_, State) ->
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

	
