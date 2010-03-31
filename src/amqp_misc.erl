%% Author: jldupont
%% Created: Mar 31, 2010
%% Description: misc helper functions
-module(amqp_misc).

-compile(export_all).

%%
%% Exported Functions
%%
-export([check_params/2]).

%%
%% API Functions
%%
check_params([], _) ->
	ok;

check_params([Param|RestParams], [{string, Name}|RestRefs]) ->
	case is_list(Param) of
		true  -> ok;
		false -> erlang:error({error, {invalid.param, Name, Param}, {expecting, string}})
	end,
	check_params(RestParams, RestRefs);

check_params([Param|RestParams], [{int, Name}|RestRefs]) ->
	case is_integer(Param) of
		true  -> ok;
		false -> erlang:error({error, {invalid.param, Name, Param}, {expecting, integer}})
	end,
	check_params(RestParams, RestRefs);

check_params([Param|RestParams], [{bool, Name}|RestRefs]) ->
	case Param of
		true  -> ok;
		false -> ok;
		_     -> erlang:error({error, {invalid.param, Name, Param}, {expecting, boolean}})
	end,
	check_params(RestParams, RestRefs);

check_params([Param|RestParams], [{choice, Choices, Name}|RestRefs]) ->
	case lists:member(Param, Choices) of
		true  -> ok;
		false -> 
			erlang:error({error, {invalid.param, Name, Param}, {expecting, Choices}})
	end,
	check_params(RestParams, RestRefs).

