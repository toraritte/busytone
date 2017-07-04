-module(call_manager).
-behaviour(gen_server).

% accept and manage incoming agent callls

-export([start_link/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	{ok, #state{}}.

handle_info({freeswitch_sendmsg, UUID}, #state{}=S) ->
	lager:notice("incoming message, uuid:~s", [UUID]),
	{ok, _Pid} = call:start_link(UUID),
	{noreply, S};

handle_info({get_pid, UUID, Ref, From}, #state{}=S) ->
	lager:notice("call control request, uuid:~s", [UUID]),
	CallPid =
		case call:pid(UUID) of
			undefined -> {ok, Pid} = call:start_link(UUID), Pid;
			Pid -> Pid
		end,
	From ! {Ref, CallPid},
	{noreply, S};

handle_info(_Info, S=#state{}) ->
	lager:error("unhandled info:~p", [_Info]),
	{noreply, S}.

handle_cast(_Msg, S=#state{}) ->
	lager:error("unhandled cast:~p", [_Msg]),
	{noreply, S}.

handle_call(_Request, _From, S=#state{}) ->
	lager:error("unhandled call:~p", [_Request]),
	{reply, ok, S}.

terminate(_Reason, _S) ->
	lager:notice("terminate, reason:~p", [_Reason]),
	ok.

code_change(_OldVsn, S=#state{}, _Extra) -> {ok, S}.
