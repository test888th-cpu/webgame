class_name RpgCombat
extends RefCounted
## Damage, healing and auras for the trial world (RpgEncounter), each a port of the
## World of ClaudeCraft function named on it (d2b91e08). `w` is the RpgEncounter.
##
## dealDamage keeps, in the source's order, every step a trial unit can reach: the
## two-hand mastery, stances, Shield Wall, expose, spell and general vulnerability,
## damage-done buffs, damage reduction, physical reduction, Shadowform, absorbs,
## health loss, breaking breakable control, combat entry and death. Steps that need
## something the trial cannot hold (parties, duels, arenas, PvP, set and trinket
## procs, boss wards, pets, crafted collections) are absent because nothing reaches
## them.

const CAST_COMPLETE_EPS := 1e-9


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


# -- auras (sim.ts applyAura, combat/auras.ts updateAuras) ------------------------


## applyAura: same id and same source replace (a refresh); a mob never takes control
## while ccImmune or a slow while slowImmune (the trial's mobs are neither).
static func apply_aura(w: RpgEncounter, target: Dictionary, aura: Dictionary) -> void:
	var auras: Array = target["auras"]
	for i in range(auras.size() - 1, -1, -1):
		var e: Dictionary = auras[i]
		if e["id"] == aura["id"] and e["source_id"] == aura["source_id"]:
			auras.remove_at(i)
	auras.append(aura)
	w.log_event({"type": "aura", "target": target["id"], "name": aura["id"], "gained": true})
	if target["kind"] == "player":
		w.recalc_player()


## updateAuras for one unit: time runs down, periodic damage and healing tick, and an
## expired aura goes (a stat aura's removal recalculates the player).
static func update_auras(w: RpgEncounter, e: Dictionary) -> void:
	if e["dead"]:
		return
	var stats_dirty := false
	var snapshot: Array = (e["auras"] as Array).duplicate()
	for i in range(snapshot.size() - 1, -1, -1):
		var a: Dictionary = snapshot[i]
		if not (e["auras"] as Array).has(a):
			continue
		if not a.get("permanent", false):
			a["remaining"] = float(a["remaining"]) - w.dt
		if a.get("tick_interval") != null:
			a["tick_timer"] = float(a.get("tick_timer", a["tick_interval"])) - w.dt
			if float(a["tick_timer"]) <= CAST_COMPLETE_EPS:
				a["tick_timer"] = float(a["tick_timer"]) + float(a["tick_interval"])
				_tick_periodic(w, e, a)
				if e["dead"]:
					return
		if not a.get("permanent", false) and float(a["remaining"]) <= CAST_COMPLETE_EPS:
			var idx := (e["auras"] as Array).find(a)
			if idx < 0:
				continue
			e["auras"].remove_at(idx)
			w.log_event({"type": "aura", "target": e["id"], "name": a["id"], "gained": false})
			var kind := str(a["kind"])
			if (
				kind.begins_with("buff")
				or kind.begins_with("form")
				or kind in ["debuff_ap", "die_by_sword", "enrage", "bloodbath", "berserker_stance"]
			):
				stats_dirty = true
	if stats_dirty and e["kind"] == "player":
		w.recalc_player()


static func _tick_periodic(w: RpgEncounter, e: Dictionary, a: Dictionary) -> void:
	match str(a["kind"]):
		"dot":
			var src := w.unit(int(a["source_id"]))
			var amount := float(a["value"])
			if str(a["school"]) == "physical":
				var amp := 0.0
				for t: Dictionary in e["auras"]:
					if t["kind"] == "bleed_vuln":
						amp += float(t["value"])
				if amp > 0.0:
					amount = _jr(amount * (1.0 + amp))
			deal_damage(w, src, e, int(amount), false, str(a["school"]), str(a["id"]), "hit", true)
		"hot":
			var intended := _jr(float(a["value"]) * healing_taken_mult(e))
			var healed := mini(intended, maxi(0, int(e["max_hp"]) - int(e["hp"])))
			if healed > 0:
				e["hp"] = int(e["hp"]) + healed
			w.log_event({"type": "heal", "target": e["id"], "amount": healed, "hot": true})


# -- healing (combat/heal.ts) ------------------------------------------------------


static func healing_taken_mult(target: Dictionary) -> float:
	var mult := 1.0
	for a: Dictionary in target["auras"]:
		if a["kind"] == "mortal_wound":
			mult *= 1.0 - float(a["value"])
	return maxf(0.0, mult)


## applyHeal: one crit draw (when it can crit), heal-done buffs, x1.5 on a crit plus
## the heal-crit bonus, healing taken, clamped to missing health.
static func apply_heal(
	w: RpgEncounter, source: Dictionary, target: Dictionary, amount: float, can_crit := true
) -> int:
	if target["dead"]:
		return 0
	var crit := w.rng.chance(spell_crit(source)) if can_crit else false
	var heal_done := 0.0
	for a: Dictionary in source["auras"]:
		if a["kind"] == "buff_heal_done":
			heal_done += float(a["value"])
	var healed := _jr(
		(
			amount
			* (1.0 + heal_done)
			* (1.5 + float(source.get("crit_dmg_heal", 0.0)) if crit else 1.0)
			* healing_taken_mult(target)
		)
	)
	healed = mini(healed, int(target["max_hp"]) - int(target["hp"]))
	target["hp"] = int(target["hp"]) + healed
	w.log_event({"type": "heal", "target": target["id"], "amount": healed, "crit": crit})
	return healed


## spellCritChance: base + Int x 0.08% + the shared crit bonus (+ aura bonuses).
static func spell_crit(u: Dictionary) -> float:
	var bonus := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "buff_spellcrit":
			bonus += float(a["value"])
	if u["kind"] != "player":
		return RpgStats.SPELL_CRIT_BASE
	return (
		RpgStats.SPELL_CRIT_BASE
		+ float(u["stats"]["int"]) * RpgStats.SPELL_CRIT_PER_INT
		+ float(u.get("shared_crit_bonus", 0.0))
		+ bonus
	)


## spell_resist.ts isSpellResisted: one chance(effectiveSpellHit) draw; resisted when
## it fails.
static func spell_resisted(w: RpgEncounter, src: Dictionary, tgt: Dictionary) -> bool:
	var hit := minf(
		1.0,
		(
			RpgHitTable.spell_hit_chance(int(src["level"]), int(tgt["level"]))
			+ float(src.get("hit_bonus", 0.0))
		)
	)
	return not w.rng.chance(hit)


# -- damage (combat/damage.ts dealDamage) -----------------------------------------


static func _has_kind(u: Dictionary, kind: String) -> bool:
	for a: Dictionary in u["auras"]:
		if a["kind"] == kind:
			return true
	return false


static func _sum_kind(u: Dictionary, kinds: Array) -> float:
	var total := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] in kinds:
			total += float(a["value"])
	return total


## dealDamage. Returns the health actually lost. `kind`: hit, block, ...
static func deal_damage(
	w: RpgEncounter,
	source: Dictionary,
	target: Dictionary,
	amount: int,
	crit: bool,
	school: String,
	ability: String,
	kind := "hit",
	periodic := false
) -> int:
	if target["dead"]:
		return 0
	var other: bool = not source.is_empty() and source["id"] != target["id"]
	var amt := float(amount)
	if other and source["kind"] == "player" and amt > 0:
		var two_hand := float(source["mods"]["global"]["masteryTwoHandDmgPct"])
		if two_hand > 0.0 and w.player_mainhand_is_two_hand():
			amt = _jr(amt * (1.0 + two_hand))
	if other and _has_kind(source, "defensive_stance"):
		amt = _jr(amt * 0.9)
	if other and _has_kind(target, "defensive_stance"):
		amt = _jr(amt * 0.9)
	if amt > 0:
		var ward := 0.0
		for a: Dictionary in target["auras"]:
			if a["kind"] == "shield_wall":
				ward = maxf(ward, float(a["value"]))
		if ward > 0.0:
			amt = _jr(amt * (1.0 - ward))
	if school == "physical" and amt > 0:
		var expose := 1.0 + _sum_kind(target, ["expose"])
		if expose != 1.0:
			amt = _jr(amt * expose)
	if amt > 0 and school != "physical" and school != "holy":
		var amp := _sum_kind(target, ["spellvuln"])
		if amp > 0.0:
			amt = _jr(amt * (1.0 + amp))
	if amt > 0:
		var vuln := _sum_kind(target, ["vulnerability"])
		if vuln > 0.0:
			amt = _jr(amt * (1.0 + vuln))
	if other and amt > 0:
		var done := _sum_kind(source, ["buff_dmg_done", "bloodbath", "buff_avatar", "enrage"])
		if done != 0.0:
			amt = _jr(amt * maxf(0.0, 1.0 + done))
	if other and amt > 0:
		var red := _sum_kind(target, ["buff_dr", "die_by_sword"])
		if red > 0.0:
			amt = _jr(amt * maxf(0.0, 1.0 - red))
	if other and amt > 0 and school == "physical":
		var red_phys := _sum_kind(target, ["buff_dr_phys"])
		if red_phys > 0.0:
			amt = _jr(amt * maxf(0.0, 1.0 - red_phys))
	if not source.is_empty() and school == "shadow" and amt > 0:
		for a: Dictionary in source["auras"]:
			if a["kind"] == "form_shadow":
				amt = _jr(amt * (1.0 + float(a["value"]) / 100.0))
				break
	var absorbed := 0
	if amt > 0:
		var auras: Array = target["auras"]
		for i in range(auras.size() - 1, -1, -1):
			if amt <= 0:
				break
			var a: Dictionary = auras[i]
			if a["kind"] != "absorb":
				continue
			var soaked := minf(float(a["value"]), amt)
			a["value"] = float(a["value"]) - soaked
			amt -= soaked
			absorbed += int(soaked)
			if float(a["value"]) <= 0.0:
				auras.remove_at(i)
				w.log_event(
					{"type": "aura", "target": target["id"], "name": a["id"], "gained": false}
				)
	var pre := int(target["hp"])
	target["hp"] = maxi(0, pre - int(amt))
	var lost := pre - int(target["hp"])
	(
		w
		. log_event(
			{
				"type": "damage",
				"source": -1 if source.is_empty() else source["id"],
				"target": target["id"],
				"amount": int(amt),
				"crit": crit,
				"school": school,
				"ability": ability,
				"kind": kind,
				"absorbed": absorbed,
				"periodic": periodic,
			}
		)
	)
	if amt > 0:
		_break_on_damage(w, target)
	if other:
		w.enter_combat(source, target)
	if not source.is_empty() and source["kind"] == "player" and amt > 0 and not periodic:
		w.rage_from_dealing(source, int(amt), school, ability, crit)
	if target["kind"] == "player" and other and amt > 0:
		w.rage_from_taking(source, target, int(amt))
	if int(target["hp"]) <= 0 and not target["dead"]:
		w.kill(source, target)
	return lost


## Breakable control ends on damage (breaksOnDamage, with an optional threshold).
static func _break_on_damage(w: RpgEncounter, target: Dictionary) -> void:
	var auras: Array = target["auras"]
	for i in range(auras.size() - 1, -1, -1):
		var b: Dictionary = auras[i]
		if not b.get("breaks_on_damage", false):
			continue
		auras.remove_at(i)
		w.log_event({"type": "aura", "target": target["id"], "name": b["id"], "gained": false})


## isStunned (combat/cc.ts).
static func is_stunned(u: Dictionary) -> bool:
	for a: Dictionary in u["auras"]:
		if a["kind"] in ["stun", "stasis", "incapacitate", "polymorph"]:
			return true
	return false


static func is_rooted(u: Dictionary) -> bool:
	return _has_kind(u, "root")


## player_motion.ts moveSpeedMult for what a trial unit can carry (slows take the
## smallest multiplier).
static func move_speed_mult(u: Dictionary) -> float:
	var slow := 1.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "slow":
			slow = minf(slow, float(a["value"]))
	return slow
