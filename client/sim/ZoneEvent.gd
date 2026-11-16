class_name ZoneEvent
extends RefCounted
## Something that happened during one zone tick, for presentation, saving and
## (later) for the server to send to clients. `type` is one of:
## hit, spawn, despawn, defeat, pickup, level_up, quest_complete,
## encounter_start, wave, encounter_clear, boss_phase, boss_summon ("elite"
## when a world boss called in an elite, for the HUD),
## boss_shield, boss_enrage_warn and boss_enrage (BossEnrage), hero_down,
## exit, fights_back (a farming ground refilled, StreetMemory.refill),
## lair_status (a lair's mini-boss came out in another block, LairRules.watch),
## swing (an attack or skill began), dodge, slam (a thrown body hits the
## street, GrabRules), hazard_warn, hazard_hit and hazard_cancel (a hazard's
## warning appears, it lands, or it is called off with its boss; all three
## carry the hazard's "id").

var type := ""
var data := {}
## Set for "hit" events.
var hit: CombatEvent = null


static func make(p_type: String, p_data := {}) -> ZoneEvent:
	var event := ZoneEvent.new()
	event.type = p_type
	event.data = p_data
	return event
