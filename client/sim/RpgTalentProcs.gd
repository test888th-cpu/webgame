class_name RpgTalentProcs
extends RefCounted
## Talent procs (src/sim/combat/talent_procs.ts): a talent's `proc` names a trigger
## (castNth, spellCrit, shieldConsumed, hotExpired, bigHitTaken, meleeSwingWhile,
## thornsReflect) and the responses it fires (empowerNext, cooldownRefund, resource,
## heal, absorb, aura, echo). Counters and internal cooldowns live on the player as
## `proc_state` {counters, icds}.


static func _state(p: Dictionary) -> Dictionary:
	if not p.get("proc_state") is Dictionary:
		p["proc_state"] = {"counters": {}, "icds": {}}
	return p["proc_state"]


## tickProcState.
static func tick(p: Dictionary, dt: float) -> void:
	var s: Variant = p.get("proc_state")
	if not (s is Dictionary):
		return
	for key: String in s["icds"].keys():
		s["icds"][key] = float(s["icds"][key]) - dt
		if float(s["icds"][key]) <= 0.0:
			s["icds"].erase(key)


static func _procs(p: Dictionary) -> Array:
	if p.get("kind") != "player":
		return []
	return p["mods"].get("procs", [])


static func _fire(w: RpgEncounter, p: Dictionary, def: Dictionary, subject: Dictionary) -> void:
	for r: Dictionary in def["responses"]:
		_fire_one(w, p, def, subject, r)


static func _fire_one(
	w: RpgEncounter, p: Dictionary, def: Dictionary, subject: Dictionary, r: Dictionary
) -> void:
	var school := str(def.get("school", "holy"))
	match str(r["kind"]):
		"empowerNext":
			var value := 1.0 - float(r["costPct"]) if r.get("costPct") != null else 0.0
			var existing := {}
			for a: Dictionary in p["auras"]:
				if a["id"] == def["id"] and a["source_id"] == p["id"]:
					existing = a
			if not existing.is_empty():
				existing["kind"] = r["aura"]
				existing["remaining"] = float(r["duration"])
				existing["duration"] = float(r["duration"])
				existing["value"] = value
				existing["empower_abilities"] = r.get("abilities")
			else:
				var aura := _aura(
					str(def["id"]), str(r["aura"]), float(r["duration"]), value, p, school
				)
				aura["empower_abilities"] = r.get("abilities")
				RpgCombat.apply_aura(w, p, aura)
		"cooldownRefund":
			var id := str(r["ability"])
			if not p["cooldowns"].has(id):
				return
			var left := float(p["cooldowns"][id])
			if str(r["seconds"]) == "reset" or left - float(r["seconds"]) <= 0.0:
				p["cooldowns"].erase(id)
			else:
				p["cooldowns"][id] = left - float(r["seconds"])
		"resource":
			if r.get("resourceType") != null and p["resource_type"] != r["resourceType"]:
				return
			p["resource"] = minf(
				float(p["max_resource"]), float(p["resource"]) + float(r["amount"])
			)
		"heal":
			var to: Dictionary = p if r.get("target") == "self" else subject
			var amount := float(r.get("amount", 0.0))
			if r.get("amountPctSourceMaxHp") != null:
				amount = RpgTalents.js_round(float(p["max_hp"]) * float(r["amountPctSourceMaxHp"]))
			elif r.get("amountPctMaxHp") != null:
				amount = RpgTalents.js_round(float(to["max_hp"]) * float(r["amountPctMaxHp"]))
			RpgCombat.apply_heal(w, p, to, amount)
		"absorb":
			var to: Dictionary = p if r.get("target") == "self" else subject
			var amount := float(r.get("amount", 0.0))
			if r.get("amountPctMaxHp") != null:
				amount = RpgTalents.js_round(float(to["max_hp"]) * float(r["amountPctMaxHp"]))
			RpgCombat.apply_aura(
				w, to, _aura(str(def["id"]), "absorb", float(r["duration"]), amount, p, school)
			)
		"aura":
			var to: Dictionary = subject if r.get("target") == "subject" else p
			var id := str(r.get("auraId", def["id"]))
			RpgCombat.apply_aura(
				w,
				to,
				_aura(id, str(r["auraKind"]), float(r["duration"]), float(r["value"]), p, school)
			)
			if to["kind"] == "player":
				w.recalc_player()
		"echo":
			var heal := float(r.get("heal", 0.0))
			if r.get("healPctMaxHp") != null:
				heal = RpgTalents.js_round(float(subject["max_hp"]) * float(r["healPctMaxHp"]))
			var echo := _aura(str(def["id"]), "heal_echo", float(r["window"]), heal, p, "holy")
			echo["value2"] = float(r["belowFrac"])
			RpgCombat.apply_aura(w, subject, echo)


static func _aura(
	id: String, kind: String, duration: float, value: float, p: Dictionary, school: String
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": duration,
		"duration": duration,
		"value": value,
		"source_id": p["id"],
		"school": school,
	}


## onCastCompleted: the class engines' cast hooks, then (unless the cast spent an
## empowered-next aura) every castNth proc of this ability.
static func on_cast_completed(
	w: RpgEncounter, p: Dictionary, ability_id: String, target: Dictionary
) -> void:
	var was_empowered: bool = p.get("cast_consumed_empower", false)
	p.erase("cast_consumed_empower")
	RpgClassHooks.on_cast_completed(w, p, ability_id, target)
	if was_empowered:
		return
	var spec := str(p.get("spec_id", ""))
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] != "castNth" or not ability_id in t["abilities"]:
			continue
		if spec != "" and def.get("excludeSpecs") != null and spec in def["excludeSpecs"]:
			continue
		var s := _state(p)
		if t.get("icd") != null and s["icds"].has(def["id"]):
			continue
		var count := int(s["counters"].get(def["id"], 0)) + 1
		if count >= int(t["n"]):
			s["counters"][def["id"]] = 0
			if t.get("chance") != null and not w.rng.chance(float(t["chance"])):
				continue
			if t.get("icd") != null:
				s["icds"][def["id"]] = float(t["icd"])
			_fire(w, p, def, target if not target.is_empty() and not target["dead"] else p)
		else:
			s["counters"][def["id"]] = count


static func on_spell_crit(
	w: RpgEncounter, p: Dictionary, ability_id: String, target: Dictionary
) -> void:
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] != "spellCrit":
			continue
		if t.get("abilities") != null and (ability_id == "" or not ability_id in t["abilities"]):
			continue
		var s := _state(p)
		if t.get("icd") != null and s["icds"].has(def["id"]):
			continue
		if t.get("chance") != null and not w.rng.chance(float(t["chance"])):
			continue
		if t.get("icd") != null:
			s["icds"][def["id"]] = float(t["icd"])
		_fire(w, p, def, target)


static func on_shield_consumed(
	w: RpgEncounter, p: Dictionary, shield_id: String, owner: Dictionary
) -> void:
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] != "shieldConsumed":
			continue
		var matches: bool = (
			shield_id in RpgMage.PERSONAL_BARRIER_IDS
			if t["ability"] == "personal_barrier"
			else t["ability"] == shield_id
		)
		if not matches:
			continue
		var s := _state(p)
		if t.get("icd") != null and s["icds"].has(def["id"]):
			continue
		if t.get("icd") != null:
			s["icds"][def["id"]] = float(t["icd"])
		_fire(w, p, def, owner)


static func on_hot_expired(
	w: RpgEncounter, p: Dictionary, hot_id: String, owner: Dictionary
) -> void:
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] == "hotExpired" and t["ability"] == hot_id:
			_fire(w, p, def, owner)


static func on_thorns_reflect(w: RpgEncounter, p: Dictionary, ability_id: String) -> void:
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] == "thornsReflect" and t["ability"] == ability_id:
			_fire(w, p, def, p)


## onDamageTaken: a hit of at least hpFrac of max health fires a bigHitTaken proc.
static func on_damage_taken(w: RpgEncounter, p: Dictionary, amount: int) -> void:
	if int(p["max_hp"]) <= 0:
		return
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] != "bigHitTaken" or amount < float(p["max_hp"]) * float(t["hpFrac"]):
			continue
		var s := _state(p)
		if s["icds"].has(def["id"]):
			continue
		s["icds"][def["id"]] = float(t["icd"])
		_fire(w, p, def, p)


## onMeleeSwing: a meleeSwingWhile proc fires while its aura kind is worn.
static func on_melee_swing(w: RpgEncounter, p: Dictionary) -> void:
	for def: Dictionary in _procs(p):
		var t: Dictionary = def["trigger"]
		if t["on"] != "meleeSwingWhile" or not RpgAbilityRules.has_kind(p, str(t["auraKind"])):
			continue
		var s := _state(p)
		if t.get("icd") != null and s["icds"].has(def["id"]):
			continue
		if t.get("chance") != null and not w.rng.chance(float(t["chance"])):
			continue
		if t.get("icd") != null:
			s["icds"][def["id"]] = float(t["icd"])
		_fire(w, p, def, p)
