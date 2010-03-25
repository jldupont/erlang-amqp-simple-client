%% Author: jldupont
%% Created: Mar 19, 2010
%% Description: AMQP application
-module(amqp_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _State) ->
    supervisor:start_link(amqp_sup, []).

stop(_State) ->
    ok.
