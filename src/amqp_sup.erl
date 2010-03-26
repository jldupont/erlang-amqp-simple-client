%% Author: jldupont
%% Created: Mar 19, 2010
%% Description: amqp_sup
-module(amqp_sup).

-behaviour(supervisor).

-export([init/1]).

%%%=========================================================================
%%%  Supervisor callback
%%%=========================================================================
init([]) ->
    SupFlags = {one_for_one, 10, 3600},
    Children = children(), 
	%io:format("Children: ~p~n", [Children]),
    {ok, {SupFlags, Children}}.

%%%=========================================================================
%%%  Internal functions
%%%=========================================================================

children() ->
	[
	 transport_spec()
	 ,reader_spec()
	 ,writer_spec()
	 ,conn_spec()
	 ,ccmsg_spec()
	 ,api_spec()
	 ].

api_spec() ->
	ApiServer=getpar(api.server),
	TransportServer=getpar(transport.server),
	ConnServer=getpar(conn.server),
	
    Name = amqp_api,
    StartFunc = {amqp_api, start_link, [[ApiServer, TransportServer, ConnServer]]},
    Restart = permanent, 
    Shutdown = brutal_kill,
    Modules = [amqp_api],
    Type = worker,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.


transport_spec() ->
	TransportServer=getpar(transport.server),
	ConnServer=getpar(conn.server),
	ReaderServer=getpar(transport.reader.server),
	WriterServer=getpar(transport.writer.server),
	
    Name = amqp_transport,
    StartFunc = {amqp_transport, start_link, [[TransportServer, ConnServer, ReaderServer, WriterServer]]},
    Restart = permanent, 
    Shutdown = brutal_kill,
    Modules = [amqp_transport],
    Type = worker,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.


reader_spec() ->
	TransportServer=getpar(transport.server),
	ConnServer=getpar(conn.server),
	ReaderServer=getpar(transport.reader.server),
	WriterServer=getpar(transport.writer.server),
	
    Name = amqp_transport_reader,
    StartFunc = {amqp_transport_reader, start_link, [[ReaderServer, TransportServer, ConnServer, WriterServer]]},
    Restart = permanent, 
    Shutdown = brutal_kill,
    Modules = [amqp_transport_reader],
    Type = worker,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.


writer_spec() ->
	TransportServer=getpar(transport.server),
	WriterServer=getpar(transport.writer.server),
	
    Name = amqp_transport_writer,
    StartFunc = {amqp_transport_writer, start_link, [[WriterServer, TransportServer]]},
    Restart = permanent, 
    Shutdown = brutal_kill,
    Modules = [amqp_transport_writer],
    Type = worker,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.

conn_spec() ->
	TransportServer=getpar(transport.server),
	WriterServer=getpar(transport.writer.server),
	ConnServer=getpar(conn.server),
	CCMsgServer=getpar(ccmsg.server),
	
    Name = amqp_conn,
    StartFunc = {amqp_conn, start_link, [[ConnServer, TransportServer, WriterServer, CCMsgServer]]},
    Restart = permanent, 
    Shutdown = brutal_kill,
    Modules = [amqp_conn],
    Type = worker,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.

ccmsg_spec() ->
	CCMsgServer=getpar(ccmsg.server),
	ConnServer=getpar(conn.server),
	
    Name = amqp_ccmsg,
    StartFunc = {amqp_ccmsg, start_link, [[CCMsgServer, ConnServer]]},
    Restart = permanent, 
    Shutdown = brutal_kill,
    Modules = [amqp_ccmsg],
    Type = worker,
    {Name, StartFunc, Restart, Shutdown, Type, Modules}.

getpar(Param) ->
	case application:get_env(Param) of
		{ok, Value} -> 
			Value;
		_ -> 
			erlang:error({error, {missing.app.parameter, Param}})
	end.
			
