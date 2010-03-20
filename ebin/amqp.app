%%
%% @author: Jean-Lou Dupont
%%
{application,amqp,
 [{description,"erlang-amqp-simple-client"},
  {vsn,"1.0"},
  {modules,[
            amqp,
            amqp_sup,
            amqp_app,

        ]},
  {env, [
  
  		]},
  {registered,[amqp_sup, httpc_manager]},
  {applications,[kernel,stdlib]},
  {mod,{amqp_app,[]}}]}.
