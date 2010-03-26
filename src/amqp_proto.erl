%% Author: jldupont
%% Created: Mar 24, 2010
%% Description: amqp_proto
-module(amqp_proto).

-compile(export_all).

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
-export([imap/2, emap/1
		,decode_method/2
		]).

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
imap(?BASIC, 111) -> 'basic.recover.ok';

imap(_, _) -> invalid.


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
emap('basic.recover.ok')    -> {60, 111};

emap(_) -> invalid.


decode_method('connection.start', <<VersionMajor:8, VersionMinor:8, Rest/binary>>) ->
	[{table, ServerPropertiesTable}, {rest, RestData}]=extract_table(Rest),
	ServerProperties=table_decode(ServerPropertiesTable),
	[Mechanisms, RestData2] = decode_prim(longstr, RestData),
	[Locales, _RestData3] = decode_prim(longstr, RestData2),
	[{version.major, VersionMajor},
	 {version.minor, VersionMinor},
	 {server.properties, ServerProperties},
	 {mechanisms, Mechanisms},
	 {locales, Locales} 
	 ];

decode_method('connection.secure', Payload) ->
	Challenge=decode_prim(longstr, Payload),
	[{longstr, _Len, Str}, _Rest] = Challenge,
	[{challenge, Str}];

decode_method('connection.tune', Payload) ->
	[{short, _, ChannelMax}, Rest]=decode_prim(short, Payload),
	[{long,  _, FrameMax},   Rest2] = Rest,
	[{short, _, Heartbeat},  _Rest3] = Rest2,
	[{channel.max, ChannelMax}, {frame.max, FrameMax}, {heartbeat, Heartbeat}];

decode_method('connection.open', Payload) ->
	[{shortstr, _, Path}, _Rest]=decode_prim(shortstr, Payload),
	[{path, Path}];

decode_method('connection.close', Payload) ->
	[{short,    _, Code}, Rest]=decode_prim(short, Payload),
	[{shortstr, _, Text}, Rest2]=decode_prim(shortstr, Rest),
	[{short,    _, Clid}, Rest3]=decode_prim(short, Rest2),
	[{short,    _, Mlid}, _Rest4]=decode_prim(short, Rest3),
	[{reply.code, Code}, {reply.text, Text}, {class.id, Clid}, {method.id, Mlid}];

decode_method('connection.close.ok', _Payload) ->
	[];

decode_method('channel.flow', Payload) ->
	[{octet, _, Active}, _Rest]=decode_prim(octet, Payload),
	[{active, Active}];

decode_method('channel.flow.ok', Payload) ->
	[{octet, _, Active}, _Rest]=decode_prim(octet, Payload),
	[{active, Active}];

decode_method('channel.close', Payload) ->
	[{short,    _, Code}, Rest]=decode_prim(short, Payload),
	[{shortstr, _, Text}, Rest2]=decode_prim(shortstr, Rest),
	[{short,    _, Clid}, Rest3]=decode_prim(short, Rest2),
	[{short,    _, Mlid}, _Rest4]=decode_prim(short, Rest3),
	[{reply.code, Code}, {reply.text, Text}, {class.id, Clid}, {method.id, Mlid}];

decode_method('channel.close.ok', _Payload) ->
	[];

decode_method('exchange.declare.ok', _Payload) ->
	[];

decode_method('exchange.delete.ok', _Payload) ->
	[];

decode_method('queue.declare.ok', Payload) ->
	[{shortstr, _, Name},   Rest]=decode_prim(shortstr, Payload),
	[{long,     _, MCount}, Rest2]=decode_prim(long, Rest),
	[{long,     _, CCount}, _Rest3]=decode_prim(long, Rest2),
	[{name, Name}, {message.count, MCount}, {consumer.count, CCount}];

decode_method('queue.bind.ok', _Payload) ->
	[];

decode_method('queue.unbind.ok', _Payload) ->
	[];

decode_method('queue.purge.ok', Payload) ->
	[{long,     _, MCount}, _Rest]=decode_prim(long, Payload),
	[{message.count, MCount}];

decode_method('queue.delete.ok', Payload) ->
	[{long,     _, MCount}, _Rest]=decode_prim(long, Payload),
	[{message.count, MCount}];

decode_method('basic.qos.ok', _Payload) ->
	[];

decode_method('basic.consume.ok', Payload) ->
	[{shortstr, _, Tag},   _Rest]=decode_prim(shortstr, Payload),
	[{consumer.tag, Tag}];

decode_method('basic.cancel.ok', Payload) ->
	[{shortstr, _, Tag},   _Rest]=decode_prim(shortstr, Payload),
	[{consumer.tag, Tag}];

decode_method('basic.return', Payload) ->
	[{short,    _, Code}, Rest]=decode_prim(short, Payload),
	[{shortstr, _, Text}, Rest2]=decode_prim(shortstr, Rest),
	[{shortstr, _, Exch}, Rest3]=decode_prim(shortstr, Rest2),
	[{shortstr, _, Key}, _Rest4]=decode_prim(shortstr, Rest3),
	[{reply.code, Code}, {reply.text, Text}, {exchange.name, Exch}, {routing.key, Key}];

decode_method('basic.deliver', Payload) ->
	[{shortstr, _, CTag},   Rest] =decode_prim(shortstr, Payload),
	[{longlong, _, DTag},   Rest2]=decode_prim(longlong, Rest),
	[{octet,    _, Redel},  Rest3]=decode_prim(octet, Rest2),
	[{shortstr, _, Exch},   Rest4]=decode_prim(shortstr, Rest3),
	[{shortstr, _, Key},   _Rest5]=decode_prim(shortstr, Rest4),
	[{consumer.tag, CTag}, {delivery.tag, DTag}, {redelivered, Redel},
	  {exchange.name, Exch}, {routing.key, Key}];
	
decode_method('basic.get.ok', Payload) ->
	[{longlong, _, DTag},   Rest]=decode_prim(longlong, Payload),
	[{octet,    _, Redel},  Rest2]=decode_prim(octet, Rest),
	[{shortstr, _, Exch},   Rest3]=decode_prim(shortstr, Rest2),
	[{shortstr, _, Key},    Rest4]=decode_prim(shortstr, Rest3),
	[{long,     _, MCount}, _Rest5]=decode_prim(long, Rest4),
	[{delivery.tag, DTag}, {redelivered, Redel}, {exchange.name, Exch}
	,{routing.key, Key}, {message.count, MCount}
	 ];

decode_method('basic.get.empty', _Payload) ->
	[];

decode_method('basic.recover.ok', _Payload) ->
	[];

decode_method(_, _) ->
	undefined.




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Table Encoding:
%%
%%   <<Table Length, [{name, type, value}, ...]
%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Extracts a "table" from a binary blob
%% 
extract_table(<<Tlen:32, Data/binary>>) ->
	<<Table:Tlen/binary, Rest/binary>> = Data,
	[{table, Table}, {rest, Rest}].


%% Decodes a "table" compound data-type
%%
table_decode(TableData) ->
	table_decode(TableData, []).

table_decode(<<>>, Acc) ->
	{table, Acc};

table_decode(Data, Acc) ->
	[{_, _, Name}, TypeAndRestData]=decode_prim(shortstr, Data),
	[{_, _, Type}, ValueAndRestData]=decode_prim(octet, TypeAndRestData),
	
	[{Ptype, _Size, Value}, RestData]=table_decode_entry(Type, ValueAndRestData),
	Result=case Ptype of
		table ->
			table_decode(Value);
		_ ->
			{Ptype, Name, Value}
	end,
	table_decode(RestData, Acc++[Result]).
		




table_decode_entry($F, ValueAndRestData) ->
	<<Tlen:32, Rest/binary>> = ValueAndRestData,
	<<TableData:Tlen/binary, RestData/binary>> = Rest,
	[{table, Tlen, TableData}, RestData];

table_decode_entry($T, ValueAndRestData) ->
	decode_prim(timestamp, ValueAndRestData);

table_decode_entry($D, ValueAndRestData) ->
	decode_prim(decimal, ValueAndRestData);

table_decode_entry($I, ValueAndRestData) ->
	decode_prim(long, ValueAndRestData);

table_decode_entry($S, ValueAndRestData) ->
	decode_prim(longstr, ValueAndRestData);

table_decode_entry(_, Data) ->
	[undefined, Data].


%%
%% Decode Primitives
%%
decode_prim(decimal, <<Places:8, Long:32, Rest/binary>>) ->
	[{decimal, 5, {Places, Long}}, Rest];

decode_prim(shortstr, <<Len:8, StrAndRest/binary>>) ->
	<<Str:Len/binary, Rest/binary>> = StrAndRest,
	[{shortstr, Len, Str}, Rest];

decode_prim(longstr, <<Len:32, StrAndRest/binary>>) ->
	<<Str:Len/binary, Rest/binary>> = StrAndRest,
	[{longstr, Len, Str}, Rest];

decode_prim(timestamp, <<Ts:64, Rest/binary>>) ->
	[{timestamp, 8, Ts}, Rest];

decode_prim(octet, <<Octet:8, Rest/binary>>) ->
	[{octet, 1, Octet}, Rest];

decode_prim(short, <<Short:16, Rest/binary>>) ->
	[{short, 2, Short}, Rest];

decode_prim(long, <<Long:32, Rest/binary>>) ->
	[{long, 4, Long}, Rest];

decode_prim(longlong, <<LongLong:64, Rest/binary>>) ->
	[{longlong, 8, LongLong}, Rest];

decode_prim(_, Data) ->
	[{undefined, undefined, undefined}, Data].


decode_bit(Byte) when Byte =< 255 ->
	[{bit, Byte band 16#01}, Byte bsr 1].


%%
%% Encode Primitives
%%
encode_prim(shortstr, String) ->
	Size=erlang:length(String),
	ByteString=erlang:list_to_binary(String),
	<<Size:8, ByteString/binary>>;

encode_prim(longstr, String) ->
	Size=erlang:length(String),
	ByteString=erlang:list_to_binary(String),
	<<Size:32, ByteString/binary>>;

encode_prim(longlong, LongLong) ->
	<<LongLong:64/binary>>;

encode_prim(long, Long) ->
	<<Long:32/binary>>;

encode_prim(short, Short) ->
	<<Short:16/binary>>;

encode_prim(octet, Octet) ->
	<<Octet:8/binary>>.


encode_bit(Byte, Pos, true) when Byte =< 255, Pos =< 7 ->
	SetBit=16#01 bsl Pos,
	Byte bor SetBit;

encode_bit(Byte, Pos, _) when Byte =< 255, Pos =< 7 ->
	ClearBit= bnot (16#01 bsl Pos),
	Byte band ClearBit.


