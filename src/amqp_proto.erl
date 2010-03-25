%% Author: jldupont
%% Created: Mar 24, 2010
%% Description: amqp_proto
-module(amqp_proto).

%%
%% Definitions
%%
-define(CONNECTION, 10).
-define(CHANNEL,    20).
-define(EXCHANGE,   40).
-define(QUEUE,      50).
-define(BASIC,      60).
-define(TX,         90).

-define(START,      10).
-define(START_OK,   11).
-define(SECURE,     20).
-define(SECURE_OK,  21).
-define(TUNE,       30).
-define(TUNE_OK,    31).
-define(OPEN,       40).
-define(OPEN_OK,    41).
-define(CLOSE,      50).
-define(CLOSE_OK,   51).

%%
%% Exported Functions
%%
-export([imap/2, emap/1]).

%%
%% API Functions
%%
imap(?CONNECTION, ?START) ->	 'connection.start';
imap(?CONNECTION, ?START_OK) ->	 'connection.start.ok';
imap(?CONNECTION, ?SECURE) ->	 'connection.secure';
imap(?CONNECTION, ?SECURE_OK) -> 'connection.secure.ok';
imap(?CONNECTION, ?TUNE) ->	     'connection.tune';
imap(?CONNECTION, ?TUNE_OK) ->   'connection.tune.ok';
imap(?CONNECTION, ?OPEN) ->      'connection.open';
imap(?CONNECTION, ?OPEN_OK) ->   'connection.open.ok';
imap(?CONNECTION, ?CLOSE) ->     'connection.close';
imap(?CONNECTION, ?CLOSE_OK) ->  'connection.close.ok';

imap(?CHANNEL, 10) ->    'channel.open';
imap(?CHANNEL, 11) ->	 'channel.open.ok';
imap(?CHANNEL, 20) ->    'channel.flow';
imap(?CHANNEL, 21) ->	 'channel.flow.ok';
imap(?CHANNEL, 40) ->    'channel.close';
imap(?CHANNEL, 41) ->	 'channel.close.ok';

imap(?EXCHANGE, 10) ->   'exchange.declare';
imap(?EXCHANGE, 11) ->	 'exchange.declare.ok';
imap(?EXCHANGE, 20) ->   'exchange.delete';
imap(?EXCHANGE, 21) ->	 'exchange.delete.ok';

imap(?QUEUE, 10) ->  'queue.declare';
imap(?QUEUE, 11) ->	 'queue.declare.ok';
imap(?QUEUE, 20) ->  'queue.bind';
imap(?QUEUE, 21) ->	 'queue.bind.ok';
imap(?QUEUE, 50) ->  'queue.unbind';
imap(?QUEUE, 51) ->	 'queue.unbind.ok';
imap(?QUEUE, 30) ->  'queue.purge';
imap(?QUEUE, 31) ->	 'queue.purge.ok';
imap(?QUEUE, 40) ->  'queue.delete';
imap(?QUEUE, 41) ->	 'queue.delete.ok';

imap(?BASIC, 10) ->  'basic.qos';
imap(?BASIC, 11) ->	 'basic.qos.ok';
imap(?BASIC, 20) ->  'basic.consume';
imap(?BASIC, 21) ->	 'basic.consume.ok';
imap(?BASIC, 30) ->  'basic.cancel';
imap(?BASIC, 31) ->	 'basic.cancel.ok';
imap(?BASIC, 40) ->  'basic.publish';
imap(?BASIC, 50) ->	 'basic.return';
imap(?BASIC, 60) ->	 'basic.deliver';
imap(?BASIC, 70) ->  'basic.get';
imap(?BASIC, 71) ->	 'basic.get.ok';
imap(?BASIC, 72) ->	 'basic.get.empty';
imap(?BASIC, 80) ->	 'basic.ack';
imap(?BASIC, 90) ->	 'basic.reject';
imap(?BASIC, 100) -> 'basic.recover.async';
imap(?BASIC, 110) -> 'basic.recover';
imap(?BASIC, 111) -> 'basic.recover.ok'.


emap('connection.start')    -> {10, 10};
emap('connection.start.ok') -> {10, 11};
emap('connection.secure')   -> {10, 20};
emap('connection.secure.ok')-> {10, 21};
emap('connection.tune')     -> {10, 30};
emap('connection.tune.ok')  -> {10, 31};
emap('connection.open')     -> {10, 40};
emap('connection.open.ok')  -> {10, 41};
emap('connection.close')    -> {10, 50};
emap('connection.close.ok') -> {10, 51};

emap('channel.open')     -> {20, 10};
emap('channel.open.ok')  -> {20, 11};
emap('channel.flow')     -> {20, 20};
emap('channel.flow.ok')  -> {20, 21};
emap('channel.close')    -> {20, 40};
emap('channel.close.ok') -> {20, 41};

emap('exchange.declare')    -> {40, 10};
emap('exchange.declare.ok') -> {40, 11};
emap('exchange.delete')     -> {40, 20};
emap('exchange.delete.ok')  -> {40, 21};

emap('queue.declare')    -> {50, 10};
emap('queue.declare.ok') -> {50, 11};
emap('queue.bind')       -> {50, 20};
emap('queue.bind.ok')    -> {50, 21};
emap('queue.unbind')     -> {50, 50};
emap('queue.unbind.ok')  -> {50, 51};
emap('queue.purge')      -> {50, 30};
emap('queue.purge.ok')   -> {50, 31};
emap('queue.delete')     -> {50, 40};
emap('queue.delete.ok')  -> {50, 41};

emap('basic.qos')        -> {60, 10};
emap('basic.qos.ok')     -> {60, 11};
emap('basic.consume')    -> {60, 20};
emap('basic.consume.ok') -> {60, 21};
emap('basic.cancel')     -> {60, 30};
emap('basic.cancel.ok')  -> {60, 31};
emap('basic.publish')    -> {60, 40};
emap('basic.return')     -> {60, 50};
emap('basic.deliver')    -> {60, 60};
emap('basic.get')        -> {60, 70};
emap('basic.get.ok')     -> {60, 71};
emap('basic.get.empty')  -> {60, 72};
emap('basic.ack')        -> {60, 80};
emap('basic.reject')        -> {60, 90};
emap('basic.recover.async') -> {60, 100};
emap('basic.recover')       -> {60, 110};
emap('basic.recover.ok')    -> {60, 111}.


