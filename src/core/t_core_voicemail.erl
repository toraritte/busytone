-module(t_core_voicemail).
-export([main/0]).
-import(ts_core, [wait/1]).

main() ->
	lager:notice("check inqueue call conversion to voicemail"),
	A = admin:new_agent(),
	{ok, In} = call_sup:originate("default_queue"),
	admin:call(subscribe, [uuid, In]),
	wait(fun() -> [#{ <<"uuid">> := In, <<"state">> := <<"inqueue">>, <<"record">> := <<"inqueue_call">> }]  = admin:call(inqueues, []) end),
	call:send_dtmf(In, "*"),
	admin:wait_ws(#{ <<"Application">> => <<"sleep">>, <<"Unique-ID">> => In }),
	timer:sleep(500), % voicemail body
	call:hangup(In),
	wait(fun() -> [#{ <<"uuid">> := In, <<"state">> := <<"inqueue">>, <<"record">> := <<"inqueue_vm">> }]  = admin:call(inqueues, []) end),

	agent:available(A),
	[LegA] = agent:wait_for_call(A),
	ok = call:answer(LegA),
	call:wait_event(LegA, <<"CHANNEL_ANSWER">>),
	call:wait_hangup(LegA),
	wait(fun() -> []  = admin:call(inqueues, []) end),
	[#{ <<"login">> := A, <<"state">> := <<"available">> }]  = admin:call(agents, []).
