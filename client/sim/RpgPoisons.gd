class_name RpgPoisons
extends RefCounted
## Poison coatings (src/sim/combat/poison_coating.ts): an imbue whose effect carries
## a `coat` rides every landed melee hit: a stacking damage-over-time (stackDot) or a
## refreshed debuff (melting acid, mortal wound).


## poisonCoatFor: the coat of an imbue ability, or {}.
static func coat_for(w: RpgEncounter, ability_id: String) -> Dictionary:
	var known := w.known_entry(ability_id)
	var effects: Array = (
		known["effects"]
		if not known.is_empty()
		else w.pack["abilities"].get(ability_id, {}).get("def", {}).get("effects", [])
	)
	for e: Dictionary in effects:
		if e["type"] == "imbue" and e.get("coat") != null:
			return e["coat"]
	return {}


## applyPoisonCoats.
static func apply_coats(w: RpgEncounter, attacker: Dictionary, target: Dictionary) -> void:
	if target["dead"]:
		return
	for coating: Dictionary in (attacker["auras"] as Array).duplicate():
		if coating["kind"] != "imbue":
			continue
		var coat := coat_for(w, str(coating["id"]))
		if coat.is_empty():
			continue
		if coat["rider"] == "stackDot":
			_stack_dot(w, attacker, target, coating, coat)
		else:
			_debuff(w, attacker, target, coating, coat)


static func _stack_dot(
	w: RpgEncounter, attacker: Dictionary, target: Dictionary, coating: Dictionary, coat: Dictionary
) -> void:
	for a: Dictionary in target["auras"]:
		if a["id"] == coating["id"] and a["kind"] == "dot" and a["source_id"] == attacker["id"]:
			a["stacks"] = mini(maxi(1, int(coat["maxStacks"])), int(a.get("stacks", 0)) + 1)
			a["value"] = float(
				maxi(1, int(RpgTalents.js_round(float(coat["perTick"]) * int(a["stacks"]))))
			)
			a["remaining"] = a["duration"]
			return
	(
		RpgCombat
		. apply_aura(
			w,
			target,
			{
				"id": coating["id"],
				"kind": "dot",
				"remaining": float(coat["duration"]),
				"duration": float(coat["duration"]),
				"value": float(maxi(1, int(RpgTalents.js_round(float(coat["perTick"]))))),
				"tick_interval": float(coat["interval"]),
				"tick_timer": float(coat["interval"]),
				"stacks": 1,
				"source_id": attacker["id"],
				"school": str(coat.get("school", "nature")),
			}
		)
	)


static func _debuff(
	w: RpgEncounter, attacker: Dictionary, target: Dictionary, coating: Dictionary, coat: Dictionary
) -> void:
	for a: Dictionary in target["auras"]:
		if (
			a["id"] == coating["id"]
			and a["kind"] == coat["kind"]
			and a["source_id"] == attacker["id"]
		):
			a["value"] = float(coat["value"])
			a["remaining"] = a["duration"]
			return
	(
		RpgCombat
		. apply_aura(
			w,
			target,
			{
				"id": coating["id"],
				"kind": str(coat["kind"]),
				"remaining": float(coat["duration"]),
				"duration": float(coat["duration"]),
				"value": float(coat["value"]),
				"source_id": attacker["id"],
				"school": str(coat.get("school", "nature")),
			}
		)
	)
