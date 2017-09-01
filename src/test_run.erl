-module(test_run).
-behaviour(gen_server).

-export([start/0, start_link/0, stop/1, run/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

start() -> gen_server:start(?MODULE, [], []).
start_link() -> gen_server:start_link(?MODULE, [], []).

run(Pid, Test) -> gen_server:call(Pid, {run, Test}, infinity).
stop(Pid) -> gen_server:stop(Pid).

init([]) ->
	lager:debug("start", []),
	{ok, #state{}}.

handle_cast(stop, S) -> {stop, normal, S};
handle_cast(_Msg, S=#state{}) -> lager:error("unhandled cast:~p", [_Msg]), {noreply, S}.

handle_info(_Info, S=#state{}) -> lager:info("unhandled info:~p", [_Info]), {noreply, S}.

handle_call({run, Test}, _From, S=#state{}) ->
	try
		Test:main(),
		admin:reset(),
		{reply, ok, S}
	catch C:E ->
		lager:error("~s error:~s", [Test, lager:pr_stacktrace(erlang:get_stacktrace(), {C,E})]),
		admin:reset(),
		{reply, not_ok, S}
	end;

handle_call({run, Test, Repeat}, _From, S=#state{}) ->
	try
		[ Test:main() || _I <- lists:seq(1, Repeat) ],
		admin:reset(),
		{reply, ok, S}
	catch C:E ->
		lager:error("~s error:~s", [Test, lager:pr_stacktrace(erlang:get_stacktrace(), {C,E})]),
		admin:reset(),
		{reply, not_ok, S}
	end;

handle_call(_Request, _From, S=#state{}) -> lager:error("unhandled call:~p", [_Request]), {reply, ok, S}.

terminate(_Reason, _S) -> lager:debug("terminate"), ok.

code_change(_OldVsn, S=#state{}, _Extra) -> {ok, S}.
