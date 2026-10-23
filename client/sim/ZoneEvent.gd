class_name ZoneEvent
extends RefCounted
## Something that happened during one zone tick, for presentation, saving and
## (later) for the server to send to clients. `type` is one of:
## hit, spawn, despawn, defeat, pickup, level_up, quest_complete,
## encounter_start, wave, encounter_clear, boss_phase, hero_down, exit.

var type := ""
var data := {}
## Set for "hit" events.
var hit: CombatEvent = null


static func make(p_type: String, p_data := {}) -> ZoneEvent:
	var event := ZoneEvent.new()
	event.type = p_type
	event.data = p_data
	return event
