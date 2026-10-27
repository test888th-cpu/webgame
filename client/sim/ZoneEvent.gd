class_name ZoneEvent
extends RefCounted
## Something that happened during one zone tick, for presentation, saving and
## (later) for the server to send to clients. `type` is one of:
## hit, spawn, despawn, defeat, pickup, level_up, quest_complete,
## encounter_start, wave, encounter_clear, boss_phase, boss_summon, hero_down, exit,
## swing (an attack or skill began), dodge, hazard_warn and hazard_hit (a
## crane drop's shadow appears, and it lands).

var type := ""
var data := {}
## Set for "hit" events.
var hit: CombatEvent = null


static func make(p_type: String, p_data := {}) -> ZoneEvent:
	var event := ZoneEvent.new()
	event.type = p_type
	event.data = p_data
	return event
