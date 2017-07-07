-module(test_lib).
-export([
	login_available/3,
	ensureTalking/2, ensureTalking/3
]).

login_available(Login, Password, Number) ->
	Agent = agent_sup:agent(Login, Password, Number),
	agent:wait_ws(Agent, #{ <<"username">> => Agent }),
	agent:available(Agent),
	agent:wait_ws(Agent, #{ <<"command">> => <<"arelease">>, <<"releaseData">> => false }),
	Agent.

ensureTalking(UUID1, UUID2) -> ensureTalking(UUID1, UUID2, 5000).
ensureTalking(UUID1, UUID2, Timeout) ->
	call:execute(UUID1, "playback", "tone_stream://%(3000, 0, 2600)"),
	call:detect_tone(UUID2, "2600"),
	call:wait_event(UUID2, #{ "Event-Name" => "DETECTED_TONE" }, Timeout),
	call:stop_detect_tone(UUID2).
