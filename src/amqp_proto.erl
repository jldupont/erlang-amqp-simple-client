%% Author: jldupont
%% Created: Mar 24, 2010
%% Description: amqp_proto
-module(amqp_proto).

-compile(export_all).

-include("amqp.hrl").

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
imap(?CONNECTION, 10) -> 'connection.start';
imap(?CONNECTION, 11) -> 'connection.start.ok';
imap(?CONNECTION, 20) -> 'connection.secure';
imap(?CONNECTION, 21) -> 'connection.secure.ok';
imap(?CONNECTION, 30) -> 'connection.tune';
imap(?CONNECTION, 31) -> 'connection.tune.ok';
imap(?CONNECTION, 40) -> 'connection.open';
imap(?CONNECTION, 41) -> 'connection.open.ok';
imap(?CONNECTION, 60) -> 'connection.close';
imap(?CONNECTION, 61) -> 'connection.close.ok';

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

imap(ClassId, MethodId) -> {invalid, ClassId, MethodId}.


emap('connection.start')    -> <<10:16, 10:16>>;
emap('connection.start.ok') -> <<10:16, 11:16>>;
emap('connection.secure')   -> <<10:16, 20:16>>;
emap('connection.secure.ok')-> <<10:16, 21:16>>;
emap('connection.tune')     -> <<10:16, 30:16>>;
emap('connection.tune.ok')  -> <<10:16, 31:16>>;
emap('connection.open')     -> <<10:16, 40:16>>;
emap('connection.open.ok')  -> <<10:16, 41:16>>;
emap('connection.close')    -> <<10:16, 50:16>>;
emap('connection.close.ok') -> <<10:16, 51:16>>;

emap('channel.open')     -> <<20:16, 10:16>>;
emap('channel.open.ok')  -> <<20:16, 11:16>>;
emap('channel.flow')     -> <<20:16, 20:16>>;
emap('channel.flow.ok')  -> <<20:16, 21:16>>;
emap('channel.close')    -> <<20:16, 40:16>>;
emap('channel.close.ok') -> <<20:16, 41:16>>;

emap('exchange.declare')    -> <<40:16, 10:16>>;
emap('exchange.declare.ok') -> <<40:16, 11:16>>;
emap('exchange.delete')     -> <<40:16, 20:16>>;
emap('exchange.delete.ok')  -> <<40:16, 21:16>>;

emap('queue.declare')    -> <<50:16, 10:16>>;
emap('queue.declare.ok') -> <<50:16, 11:16>>;
emap('queue.bind')       -> <<50:16, 20:16>>;
emap('queue.bind.ok')    -> <<50:16, 21:16>>;
emap('queue.unbind')     -> <<50:16, 50:16>>;
emap('queue.unbind.ok')  -> <<50:16, 51:16>>;
emap('queue.purge')      -> <<50:16, 30:16>>;
emap('queue.purge.ok')   -> <<50:16, 31:16>>;
emap('queue.delete')     -> <<50:16, 40:16>>;
emap('queue.delete.ok')  -> <<50:16, 41:16>>;

emap('basic.qos')        -> <<60:16, 10:16>>;
emap('basic.qos.ok')     -> <<60:16, 11:16>>;
emap('basic.consume')    -> <<60:16, 20:16>>;
emap('basic.consume.ok') -> <<60:16, 21:16>>;
emap('basic.cancel')     -> <<60:16, 30:16>>;
emap('basic.cancel.ok')  -> <<60:16, 31:16>>;
emap('basic.publish')    -> <<60:16, 40:16>>;
emap('basic.return')     -> <<60:16, 50:16>>;
emap('basic.deliver')    -> <<60:16, 60:16>>;
emap('basic.get')        -> <<60:16, 70:16>>;
emap('basic.get.ok')     -> <<60:16, 71:16>>;
emap('basic.get.empty')  -> <<60:16, 72:16>>;
emap('basic.ack')        -> <<60:16, 80:16>>;

emap('basic.reject')        -> <<60:16, 90:16>>;
emap('basic.recover.async') -> <<60:16, 100:16>>;
emap('basic.recover')       -> <<60:16, 110:16>>;
emap('basic.recover.ok')    -> <<60:16, 111:16>>;

emap(Method) -> {invalid, Method}.


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
	[{long,  _, FrameMax},   Rest2] = decode_prim(long, Rest),
	[{short, _, Heartbeat},  _Rest3] = decode_prim(short, Rest2),
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



decode_header(<<ClassId:16, Weight:16, BodySize:64, Properties/binary>>) ->
	{ClassId, Weight, BodySize, Properties};

decode_header(_) ->
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
	<<LongLong:64>>;

encode_prim(long, Long) ->
	<<Long:32>>;

encode_prim(short, Short) ->
	<<Short:16>>;

encode_prim(octet, true) ->
	<<1:8>>;

encode_prim(octet, false) ->
	<<0:8>>;

encode_prim(octet, <<Octet:8>>) ->
	<<Octet:8>>;

encode_prim(octet, Octet) ->
	<<Octet:8>>;

encode_prim(Type, Data) ->
	throw({encode_prim, invalid.type, Type, Data}).


encode_bit(Byte, Pos, true) when Byte =< 255, Pos =< 7 ->
	SetBit=16#01 bsl Pos,
	Byte bor SetBit;

encode_bit(Byte, Pos, _) when Byte =< 255, Pos =< 7 ->
	ClearBit= bnot (16#01 bsl Pos),
	Byte band ClearBit.


encode_bits(Bits) ->
	encode_bits(Bits, 0, 0).

encode_bits([], _Pos, Bits) ->
	Bits;

encode_bits([Bit|Rest], Pos, Bits) ->
	Result= encode_bit(Bits, Pos, Bit),
	encode_bits(Rest, Pos+1, Result).



%% Encodes a "table" compound data-type
%%
%%  Each element of the table must have the form:
%%	{Name, Prim, Data}
%%
encode_table(Table) ->
	encode_table(Table, <<>>).

encode_table([], Acc) ->
	Size=erlang:size(Acc),
	<<Size:32, Acc/binary>>;

encode_table([{Name, Prim, Data}|Rest], Acc) ->
	Result=case Prim of
		table ->
			Table=encode_table(Data, Acc),
			<<$F, Table/binary>>;
		longstr ->
			Str=encode_prim(longstr, Data),
			<<$S, Str/binary>>;
		long ->
			Int=encode_prim(long, Data),
			<<$I, Int/binary>>
	end,
	NameStr=encode_prim(shortstr, Name),
	%%io:format("!! encode_table, NameStr:~p Prim:~p Data:~p ----- Acc: ~p~n",[NameStr, Prim, Data, Acc]),	
	encode_table(Rest, <<Acc/binary, NameStr/binary, Result/binary>>);

encode_table(Item, Acc) ->
	throw({encode_table, invalid.item, Item, {acc, Acc}}).

	

%% Encodes a list of method parameters
%%
%%	Each element of the list must have the following form:
%%		{Type, Data}
%%
encode_method_params(Liste) ->
	encode_method_params(Liste, <<>>).

encode_method_params([], Acc) ->
	Acc;

encode_method_params([{Type, Data}|Rest], Acc) ->
	%io:format("** encode_method_params: Type:~p  -- Data: ~p~n", [Type, Data]),
	Result=case Type of
		table ->
			encode_table(Data);
		_ ->
			encode_prim(Type, Data)
	end,
	%io:format("** encode_method_params: Type:~p  -- Data: ~p  Result:~p ~n", [Type, Data, Result]),
	encode_method_params(Rest, <<Acc/binary, Result/binary>>).




%% ---------------------------------------------------------------------------------- %%
%% ---------------------------------------------------------------------------------- %%
%% ---------------------------------------------------------------------------------- %%




encode_method('channel.open', _) ->
	Param=encode_prim(shortstr, ""),
	Method=amqp_proto:emap('channel.open'),
	<<Method/binary, Param/binary>>;

%% Channel.close
%% {"type": "short", "name": "reply-code"},
%% {"type": "shortstr", "name": "reply-text", "default-value": ""}
%% {"type": "short", "name": "class-id"}
%% {"type": "short", "name": "method-id"}
%%
encode_method('channel.close', [ReplyCode, ReplyText, ClassId, MethodId]) ->
	Method=amqp_proto:emap('channel.close'),
	RC=encode_prim(short, ReplyCode),
	RT=encode_prim(shortstr, ReplyText),
	CID=encode_prim(short, ClassId),
	MID=encode_prim(short, MethodId),
	<<Method/binary, RC, RT/binary, CID, MID>>;

%% exchange.declare
%%
%% arguments: void (0:32)
%%
encode_method(Method='exchange.declare', [Name, Type, Durable, AutoDelete, Internal, NoWait]) ->
	MethodCode=amqp_proto:emap(Method),
	Ticket=0,
	Bits=amqp_proto:encode_bits([false, Durable, AutoDelete, Internal, NoWait]),
	Params=amqp_proto:encode_method_params([{short, Ticket}, {shortstr, Name}, {shortstr, Type}, {octet, Bits}]),
	<<MethodCode/binary, Params/binary, 0:32>>;


%% queue.declare
%%
encode_method(Method='queue.declare', [QueueName, Passive, Durable, Exclusive, AutoDelete, NoWait]) ->
	MethodCode=amqp_proto:emap(Method),
	Ticket=0,
	Bits=amqp_proto:encode_bits([Passive, Durable, Exclusive, AutoDelete, NoWait]),
	Params=amqp_proto:encode_method_params([{short, Ticket}, {shortstr, QueueName}, {octet, Bits}]),
	<<MethodCode/binary, Params/binary, 0:32>>;

%% queue.delete
%%
encode_method(Method='queue.delete', [QueueName, IfUnused, IfEmpty, NoWait]) ->
	MethodCode=amqp_proto:emap(Method),
	Ticket=0,
	Bits=amqp_proto:encode_bits([IfUnused, IfEmpty, NoWait]),
	Params=amqp_proto:encode_method_params([{short, Ticket}, {shortstr, QueueName}, {octet, Bits}]),
	<<MethodCode/binary, Params/binary>>;


%% queue.bind
%%
%% arguments: void (0:32)
%%
encode_method(Method='queue.bind', [Name, ExchangeName, RoutingKey, NoWait]) ->
	io:format("encode_method:queue.bind: Name: ~p  Exch:~p Rk: ~p  NoWait:~p~n", [Name, ExchangeName, RoutingKey, NoWait]),
	MethodCode=amqp_proto:emap(Method),
	Ticket=0,
	Octet=amqp_proto:encode_prim(octet, NoWait),
	Params=amqp_proto:encode_method_params([{short, Ticket}, {shortstr, Name}, {shortstr, ExchangeName}, 
											{shortstr, RoutingKey}, {octet, Octet}]),
	<<MethodCode/binary, Params/binary, 0:32>>;
	

%% basic.consume
%%
encode_method(Method='basic.consume', [Queue, ConsumerTag, NoLocal, NoAck, Exclusive, NoWait]) ->
	MethodCode=amqp_proto:emap(Method),
	Ticket=0,
	Bits=amqp_proto:encode_bits([NoLocal, NoAck, Exclusive, NoWait]),
	Params=amqp_proto:encode_method_params([{short, Ticket}, {shortstr, Queue}, 
											{shortstr, ConsumerTag}, {octet, Bits}]),
	<<MethodCode/binary, Params/binary>>;
	

%% connection.start.ok
%%
encode_method(Method='connection.start.ok', [Username, Password]) ->
	MethodCode=amqp_proto:emap(Method),
	{ok, Cprops}=application:get_env(client.properties),
	{ok, Mechanism}=application:get_env(default.login.method),
	
	<<_Size:32, LoginTable/binary>> =amqp_proto:encode_table([{"LOGIN", longstr, Username}, 
															  {"PASSWORD", longstr, Password}]),
	
	{ok, Locale}=application:get_env(default.locale),
	
	Params=amqp_proto:encode_method_params([{table, Cprops}
										   ,{shortstr, Mechanism}
										   ,{longstr, erlang:binary_to_list(LoginTable)}
										   ,{shortstr, Locale}
										   ]),
	<<MethodCode/binary, Params/binary>>;

%% connection.tune.ok
%%
encode_method(Method='connection.tune.ok', _) ->
	MethodCode=amqp_proto:emap(Method),
	{ok, ChannelMax}=application:get_env(default.channel.max),
	{ok, FrameMax}=application:get_env(default.frame.max),
	{ok, Heartbeat}=application:get_env(default.heartbeat),
	Params=amqp_proto:encode_method_params([{short, ChannelMax}
										   ,{long, FrameMax}
										   ,{short, Heartbeat}
										   ]),
	<<MethodCode/binary, Params/binary>>;

%% connection.open
%%
encode_method(Method='connection.open', [Vhost]) ->
	MethodCode=amqp_proto:emap(Method),
	%% need to account for the "deprecated" parameters (at least in version 0.9.1)
	%% "capabilities", "insist"
	Params=amqp_proto:encode_method_params([{shortstr, Vhost}, {shortstr, ""}, {octet, 1}]),
	<<MethodCode/binary, Params/binary>>.




	