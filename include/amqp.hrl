%%% Author: Jean-Lou Dupont
%%%
%%%
%%%
%%%
%%%
%%%
%%%
-define(PROTOCOL_VERSION_MAJOR, 9).
-define(PROTOCOL_VERSION_MINOR, 1).
-define(AMQP_TCP_OPTS, [binary, {packet, 0}, {active,false}, {nodelay, true}]).
-define(PROTOCOL_HEADER,
        <<"AMQP", 1, 1, ?PROTOCOL_VERSION_MAJOR, ?PROTOCOL_VERSION_MINOR>>).

-define(DEFAULT_ADDRESS, "127.0.0.1").
-define(DEFAULT_PORT,    5672).
-define(TIMEOUT_WAIT_HEADER,  2000).
-define(TIMEOUT_WAIT_PAYLOAD, 1000).
-define(FRAME_HEADER_LENGTH,  7).


