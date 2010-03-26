%%
%% @author: Jean-Lou Dupont
%%
{application, amqp,
 [{description,"erlang-amqp-simple-client"},
  {vsn,"1.0"},
  {modules,[
            amqp_app,
            amqp_sup,
            amqp_transport,
            amqp_transport_reader,
            amqp_transport_writer,
            amqp_conn,
            amqp_ccmsg
        ]},
  {env, [
  			{default.address,          "127.0.0.1" }
  			,{default.port,            5672}
  			,{default.user,            "guest"}
  			,{default.password,        "guest"}
  			,{amqp.tcp.options,        [binary, {packet, 0}, {active,false}, {nodelay, true}]}
  			,{transport.server,        amqp.transport.server}
  			,{transport.reader.server, amqp.transport.reader.server}
  			,{transport.writer.server, amqp.transport.writer.server}
  			,{conn.server,             amqp.conn.server}
  			,{ccmsg.server,            amqp.ccmsg.server}
  
  		]},
  {registered,[amqp_sup]},
  {applications,[kernel,stdlib]},
  {mod,{amqp_app,[]}}
 ]}.
