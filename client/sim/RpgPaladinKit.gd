class_name RpgPaladinKit
extends RefCounted
## The paladin's own effect arms and their lifecycles: Oath Chain and the threat pulse
## (combat/paladin_control.ts), Sunward Disc's bounces (paladin_sunward_disc.ts), Sun
## God's Verdict (paladin_sun_verdict.ts), Valkyr's Calling (paladin_valkyrs_calling
## .ts), Veilbound March (paladin_veilbound_march.ts) and Aegis of the First Dawn
## (paladin_aegis.ts).
## ADAPTED for the street: positions are on its axis (x), a "pull" moves a monster
## along it, and threat has no second player to divide, so a threat pulse is the
## combat entry it makes (each monster in reach engages the paladin).

const SUN_VERDICT_ID := "sun_gods_verdict"
const SUN_VERDICT_FLASH := 0.2
const VALKYR_ASCENT := 0.5
const VALKYR_APPROACH := 1.0
const VALKYR_DESCENT := 0.5
const VALKYR_FLIGHT_AURA_ID := "valkyrs_calling_flight"
const VEILBOUND_ID := "veilbound_march"
const VEILBOUND_MARK_ID := "veilbound_mark"
const AEGIS_ID := "aegis_first_dawn"
const AEGIS_REFRESH := 0.15


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _aura(
	id: String, kind: String, duration: float, value: float, p: Dictionary, school := "holy"
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


## The arms runEffects routes here. False when `eff` is not a paladin arm.
static func run_arm(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> bool:
	var def: Dictionary = res["def"]
	match str(eff["type"]):
		"threatPulse":
			for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
				w, p, float(p["x"]), float(eff["radius"])
			):
				w.enter_combat(p, m)
		"pullTarget":
			if not target.is_empty() and not target["dead"]:
				_pull_targets(w, p, target, def, eff)
		"chainDamage":
			if def["id"] != "sunward_disc":
				return false
			_sunward_chain(w, p, target, res, eff, ctx)
		"sunGodVerdict":
			if not target.is_empty() and not target["dead"]:
				_strip_verdicts(w, p)
				var mark := _aura(SUN_VERDICT_ID, "sun_verdict", float(eff["duration"]), 0.0, p)
				RpgCombat.apply_aura(w, target, mark)
				w.enter_combat(p, target)
		"valkyrsCalling":
			if not target.is_empty() and not target["dead"] and target["kind"] == "mob":
				_arm_valkyr(w, p, target, def, eff)
		"veilboundMarch":
			_activate_veilbound(w, p, def, eff)
		_:
			return false
	return true


# -- Oath Chain --------------------------------------------------------------------


## isPullEligible: never a boss (the street's monsters carry no boss flag).
static func _pull_eligible(m: Dictionary) -> bool:
	return not bool(m.get("boss", false))


## pullPaladinTargets: the primary plus the nearest others up to maxTargets.
static func _pull_targets(
	w: RpgEncounter, p: Dictionary, primary: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	var targets: Array = [primary]
	var most := int(eff.get("maxTargets", 1))
	if most > 1:
		var others: Array = []
		for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
			w, p, float(p["x"]), float(def["range"])
		):
			if m["id"] != primary["id"] and not m["dead"] and _pull_eligible(m):
				others.append(m)
		var px := float(p["x"])
		others.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				var da := absf(float(a["x"]) - px)
				var db := absf(float(b["x"]) - px)
				return da < db if da != db else int(a["id"]) < int(b["id"])
		)
		targets.append_array(others.slice(0, most - 1))
	for t: Dictionary in targets:
		_pull_one(w, p, t, def, eff)


## pullPaladinTarget: a target beyond the stop distance is reeled in (forced_move),
## one already there is slowed.
static func _pull_one(
	w: RpgEncounter, p: Dictionary, t: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	if _pull_eligible(t):
		var stop := float(eff["stopDistance"])
		var speed := float(eff["travelSpeed"])
		var dist := absf(float(t["x"]) - float(p["x"]))
		var traveling := dist > stop and dist > 1e-6 and not marching(t)
		var dur := (
			maxf(0.05, (dist - stop) / maxf(0.01, speed) + 1.0)
			if traveling
			else float(eff["slowDuration"])
		)
		var id := "%s_%s" % [def["id"], "pull" if traveling else "slow"]
		var aura := _aura(
			id,
			"forced_move" if traveling else "slow",
			dur,
			1.0 if traveling else float(eff["slowMult"]),
			p
		)
		if traveling:
			aura["pull_stop"] = stop
			aura["pull_speed"] = speed
			aura["pull_slow_mult"] = float(eff["slowMult"])
			aura["pull_slow_duration"] = float(eff["slowDuration"])
		RpgCombat.apply_aura(w, t, aura)
	w.enter_combat(p, t)


## tickPaladinOathChainPull: the reeled target closes on the paladin at travelSpeed
## and, on arrival, takes the slow.
static func tick_pull(w: RpgEncounter, t: Dictionary, a: Dictionary) -> void:
	if not str(a["id"]).ends_with("_pull") or a.get("pull_stop") == null:
		return
	var src := w.unit(int(a["source_id"]))
	if src.is_empty() or src["dead"]:
		_finish_pull(w, t, a)
		return
	if marching(t):
		return
	var dx := float(t["x"]) - float(src["x"])
	var dist := absf(dx)
	var stop := float(a["pull_stop"])
	if dist <= stop + 1e-6 or dist <= 1e-6:
		_finish_pull(w, t, a)
		return
	var next := maxf(stop, dist - float(a["pull_speed"]) * w.dt)
	t["x"] = float(src["x"]) + signf(dx) * next
	if absf(float(t["x"]) - float(src["x"])) <= stop + 1e-3:
		_finish_pull(w, t, a)


static func _finish_pull(w: RpgEncounter, t: Dictionary, a: Dictionary) -> void:
	a["remaining"] = 0.0
	var dur := float(a.get("pull_slow_duration", 0.0))
	if dur <= 0.0:
		return
	var src := w.unit(int(a["source_id"]))
	var slow := _aura(
		str(a["id"]).trim_suffix("_pull") + "_slow",
		"slow",
		dur,
		float(a.get("pull_slow_mult", 1.0)),
		src if not src.is_empty() else {"id": a["source_id"]},
		str(a["school"])
	)
	RpgCombat.apply_aura(w, t, slow)


# -- Sunward Disc ------------------------------------------------------------------


## The chainDamage arm for Sunward Disc (scheduleSunwardBounceChain): one shared roll,
## then each bounce flies from the last target to the nearest new hostile within the
## radius; each landed bounce grants a Devotion.
static func _sunward_chain(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	if target.is_empty():
		return
	var def: Dictionary = res["def"]
	var sp := RpgEffects.direct_hit_bonus(
		w, RpgEffects.scaling_power(p, def), def, float(res["castTime"]), true, ctx["dmg_mult"]
	)
	var base := _jr(
		(
			(w.rng.range_f(float(eff["min"]), float(eff["max"])) + sp)
			* float(eff.get("damageMult", 1.0))
		)
	)
	var chain := {
		"hit": {p["id"]: true, target["id"]: true},
		"jumps": int(eff["jumps"]),
		"radius": float(eff["radius"]),
		"falloff": float(eff["falloff"]),
		"base": base,
		"def": def,
		"threat": {"flat": ctx["threat_flat"], "mult": ctx["threat_mult"], "ability_id": def["id"]},
	}
	_launch_bounce(w, p, target, 1, chain)


static func _launch_bounce(
	w: RpgEncounter, p: Dictionary, origin: Dictionary, hop: int, chain: Dictionary
) -> void:
	if hop > int(chain["jumps"]):
		return
	var best := {}
	var best_d := INF
	for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
		w, p, float(origin["x"]), float(chain["radius"])
	):
		if chain["hit"].has(m["id"]):
			continue
		var d := absf(float(m["x"]) - float(origin["x"]))
		if best.is_empty() or d < best_d or (d == best_d and int(m["id"]) < int(best["id"])):
			best = m
			best_d = d
	if best.is_empty():
		return
	chain["hit"][best["id"]] = true
	w.schedule_projectile(
		func(src: Dictionary, landed: Dictionary) -> void:
			var def: Dictionary = chain["def"]
			var dmg := float(chain["base"]) * pow(float(chain["falloff"]), hop - 1)
			if def["school"] != "physical":
				dmg *= RpgEffects.spell_damage_mult(src)
			else:
				dmg *= (
					1.0
					- RpgHitTable.armor_reduction(
						RpgCombat.effective_armor(w, landed), int(src["level"])
					)
				)
			var before := int(landed["hp"])
			RpgCombat.deal_damage(
				w,
				src,
				landed,
				maxi(1, _jr(dmg)),
				false,
				str(def["school"]),
				str(def["name"]),
				"hit",
				false,
				chain["threat"]
			)
			if int(landed["hp"]) < before:
				RpgPaladin.grant_ability_devotion(src, 1)
			_launch_bounce(w, src, landed, hop + 1, chain),
		best,
		float(origin["x"])
	)


# -- Sun God's Verdict -------------------------------------------------------------


static func _strip_verdicts(w: RpgEncounter, p: Dictionary) -> void:
	for m: Dictionary in w.mobs:
		for a: Dictionary in (m["auras"] as Array).duplicate():
			if (
				a["id"] == SUN_VERDICT_ID
				and a["kind"] == "sun_verdict"
				and a["source_id"] == p["id"]
			):
				m["auras"].erase(a)
				w.log_event({"type": "aura", "target": m["id"], "name": a["id"], "gained": false})


## sunVerdictMarkForHit: the caster's mark on a target struck by Final Edict or
## Dawnfall ({} when none).
static func verdict_mark(p: Dictionary, t: Dictionary, ability_id: String) -> Dictionary:
	if ability_id != "final_edict" and ability_id != "dawnfall":
		return {}
	for a: Dictionary in t["auras"]:
		if a["id"] == SUN_VERDICT_ID and a["kind"] == "sun_verdict" and a["source_id"] == p["id"]:
			return a
	return {}


## advanceSunGodVerdict: each marked Final Edict or Dawnfall charges the mark; the
## last charge detonates it (Final Edict: the single-target blow; Dawnfall: the
## area blow that stuns).
static func advance_verdict(
	w: RpgEncounter, p: Dictionary, t: Dictionary, ability_id: String, mark: Dictionary
) -> void:
	if mark.is_empty() or p["dead"]:
		return
	var known := w.pack["abilities"].get(SUN_VERDICT_ID, {}).get("def", {}) as Dictionary
	var eff := {}
	for e: Dictionary in known.get("effects", []):
		if e["type"] == "sunGodVerdict":
			eff = e
	if eff.is_empty():
		return
	var worn: bool = (t["auras"] as Array).has(mark)
	if not t["dead"] and not worn:
		return
	var charges := int(eff["charges"])
	if float(mark["value"]) >= charges:
		return
	var next := mini(charges, maxi(0, int(floorf(float(mark["value"])))) + 1)
	if next < charges:
		if worn:
			mark["value"] = float(next)
			mark["stacks"] = next
		return
	if worn:
		mark["value"] = float(charges)
		mark["stacks"] = charges
		mark["remaining"] = minf(float(mark["remaining"]), SUN_VERDICT_FLASH)
	var mult := RpgPaladin.dawnreaver_damage_mult(p, SUN_VERDICT_ID)
	var name := str(known["name"])
	if ability_id == "final_edict":
		if not t["dead"]:
			var amount := _jr(
				w.rng.range_f(float(eff["singleTargetMin"]), float(eff["singleTargetMax"])) * mult
			)
			RpgCombat.deal_damage(w, p, t, amount, false, "holy", name)
		return
	var victims := RpgAbilityRules.hostiles_in_radius(w, p, float(t["x"]), float(eff["areaRadius"]))
	var cap := int(eff["areaSoftCap"])
	var scale := float(cap) / victims.size() if victims.size() > cap else 1.0
	for v: Dictionary in victims:
		var amount := _jr(
			w.rng.range_f(float(eff["areaMin"]), float(eff["areaMax"])) * scale * mult
		)
		RpgCombat.deal_damage(w, p, v, amount, false, "holy", name)
		if v["dead"]:
			continue
		var dur := float(eff["stunDuration"])
		RpgCombat.apply_aura(w, v, _aura(SUN_VERDICT_ID + "_stun", "stun", dur, 0.0, p))


# -- Valkyr's Calling --------------------------------------------------------------


## isValkyrsCallingAirborne.
static func valkyr_airborne(p: Dictionary) -> bool:
	return p.get("valkyr_flight") is Dictionary


## armValkyrsCalling: a two-second flight that lands on the target's spot.
static func _arm_valkyr(
	w: RpgEncounter, p: Dictionary, t: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	p["charge_target"] = -1
	p["valkyr_flight"] = {
		"from": float(p["x"]),
		"to": clampf(float(t["x"]), w.bounds.x, w.bounds.y),
		"elapsed": 0.0,
		"min": float(eff["min"]),
		"max": float(eff["max"]),
		"radius": float(eff["radius"]),
		"soft_cap": int(eff["softCap"]),
		"name": str(def["name"]),
		"school": str(def["school"]),
	}
	var total := VALKYR_ASCENT + VALKYR_APPROACH + VALKYR_DESCENT + w.dt
	RpgCombat.apply_aura(
		w, p, _aura(VALKYR_FLIGHT_AURA_ID, "internal_cd", total, 0.0, p, str(def["school"]))
	)


static func _smoothstep(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


## advanceValkyrsCalling: the flight owns the paladin's movement; on landing the
## area under them takes the blow (soft-capped) and an effective hit grants Devotion.
static func advance_valkyr(w: RpgEncounter, p: Dictionary) -> bool:
	if not valkyr_airborne(p):
		return false
	var f: Dictionary = p["valkyr_flight"]
	if p["dead"]:
		_end_flight(w, p)
		return false
	var total := VALKYR_ASCENT + VALKYR_APPROACH + VALKYR_DESCENT
	f["elapsed"] = minf(total, float(f["elapsed"]) + w.dt)
	var approach := clampf((float(f["elapsed"]) - VALKYR_ASCENT) / VALKYR_APPROACH, 0.0, 1.0)
	var from := float(f["from"])
	p["x"] = from + (float(f["to"]) - from) * _smoothstep(approach)
	if absf(float(f["to"]) - float(p["x"])) > 1e-6:
		p["facing"] = signf(float(f["to"]) - float(p["x"]))
	if float(f["elapsed"]) < total:
		return true
	p["x"] = float(f["to"])
	_end_flight(w, p)
	var victims := RpgAbilityRules.hostiles_in_radius(w, p, float(p["x"]), float(f["radius"]))
	var cap := int(f["soft_cap"])
	var scale := float(cap) / victims.size() if victims.size() > cap else 1.0
	var effective := false
	for v: Dictionary in victims:
		var before := int(v["hp"])
		var dmg := _jr(w.rng.range_f(float(f["min"]), float(f["max"])) * scale)
		RpgCombat.deal_damage(w, p, v, dmg, false, str(f["school"]), str(f["name"]))
		effective = effective or int(v["hp"]) < before
	if effective:
		RpgPaladin.grant_ability_devotion(p, 1)
	return true


static func _end_flight(w: RpgEncounter, p: Dictionary) -> void:
	p.erase("valkyr_flight")
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["id"] == VALKYR_FLIGHT_AURA_ID and a["source_id"] == p["id"]:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})


# -- Veilbound March ---------------------------------------------------------------


## isVeilboundMarchActive.
static func marching(e: Dictionary) -> bool:
	if e["dead"]:
		return false
	for a: Dictionary in e["auras"]:
		if a["id"] == VEILBOUND_ID:
			return true
	return false


## veilboundMarchBlocksAura: while marching, others' roots and slows do not land.
static func blocks_aura(target: Dictionary, aura: Dictionary) -> bool:
	return (
		aura.get("source_id") != target["id"]
		and (aura["kind"] == "root" or aura["kind"] == "slow")
		and marching(target)
	)


## veilboundMarkDamageMultiplier: a marked monster deals 20% less to its marker.
static func mark_damage_mult(source: Dictionary, target: Dictionary) -> float:
	if source.is_empty() or source["id"] == target["id"]:
		return 1.0
	for a: Dictionary in source["auras"]:
		if a["id"] == VEILBOUND_MARK_ID and a["source_id"] == target["id"]:
			return 0.8
	return 1.0


## activateVeilboundMarch: the paladin sheds roots and slows, gains the march's speed
## and armor.
static func _activate_veilbound(
	w: RpgEncounter, p: Dictionary, _def: Dictionary, eff: Dictionary
) -> void:
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if (a["kind"] == "root" or a["kind"] == "slow") and not a.get("unbreakable_control", false):
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
	var dur := float(eff["duration"])
	var march := _aura(VEILBOUND_ID, "buff_speed", dur, float(eff["speedMult"]), p)
	march["value2"] = 1.0 if eff.get("ascended", false) else 0.0
	march["value3"] = 0.0
	march["stacks"] = 0
	RpgCombat.apply_aura(w, p, march)
	var armor := _aura(VEILBOUND_ID + "_armor", "buff_armor_pct", dur, float(eff["armorPct"]), p)
	RpgCombat.apply_aura(w, p, armor)


## updateVeilboundMarchMovement then completeVeilboundMarch, after the paladin moved
## from `from_x`: every monster the march passes through is marked (a holy dot; the
## first mark grants Devotion); on the march's last tick each marked monster within
## 10 takes the burst (ascended: more, and drawn 2 closer).
static func after_move(w: RpgEncounter, p: Dictionary, from_x: float) -> void:
	var march := {}
	for a: Dictionary in p["auras"]:
		if a["id"] == VEILBOUND_ID:
			march = a
	if march.is_empty() or p["dead"]:
		return
	var lo := minf(from_x, float(p["x"])) - 1.1
	var hi := maxf(from_x, float(p["x"])) + 1.1
	var passed: Array = []
	for m: Dictionary in w.mobs:
		if not m["dead"] and float(m["x"]) >= lo and float(m["x"]) <= hi:
			passed.append(m)
	passed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	for m: Dictionary in passed:
		if _marked(m, p):
			continue
		var mark := _aura(VEILBOUND_MARK_ID, "dot", 6.0, 12.0, p)
		mark["tick_interval"] = 1.0
		mark["tick_timer"] = 1.0
		RpgCombat.apply_aura(w, m, mark)
		if float(march.get("value3", 0.0)) == 0.0:
			march["value3"] = 1.0
			RpgPaladin.grant_ability_devotion(p, 1)
	if float(march["remaining"]) > w.dt + RpgCast.CAST_COMPLETE_EPS or int(march["stacks"]) > 0:
		return
	march["stacks"] = 1
	var ascended := float(march.get("value2", 0.0)) > 0.0
	var marked: Array = []
	for m: Dictionary in w.mobs:
		if not m["dead"] and _marked(m, p) and absf(float(m["x"]) - float(p["x"])) <= 10.0:
			marked.append(m)
	marked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	for m: Dictionary in marked:
		RpgCombat.deal_damage(w, p, m, 54 if ascended else 36, false, "holy", "Veilbound March")
		if ascended and not m["dead"] and _pull_eligible(m) and not marching(m):
			var dx := float(m["x"]) - float(p["x"])
			if absf(dx) > 1e-6:
				m["x"] = float(p["x"]) + signf(dx) * maxf(1.0, absf(dx) - 2.0)


static func _marked(m: Dictionary, p: Dictionary) -> bool:
	for a: Dictionary in m["auras"]:
		if a["id"] == VEILBOUND_MARK_ID and a["source_id"] == p["id"]:
			return true
	return false


# -- Aegis of the First Dawn -------------------------------------------------------


static func _aegis_eff(res: Dictionary) -> Dictionary:
	for e: Dictionary in res.get("effects", []):
		if e["type"] == "paladinAegis":
			return e
	return {}


## syncPaladinAegisProtection (the channel's start and every tick of it): the caster,
## the street's only ally, inside the radius by definition, wears the cut.
static func aegis_sync(w: RpgEncounter, p: Dictionary, res: Dictionary) -> void:
	var eff := _aegis_eff(res)
	if eff.is_empty():
		return
	var id := "%s_dr:%d" % [AEGIS_ID, int(p["id"])]
	for a: Dictionary in p["auras"]:
		if a["id"] == id and a["source_id"] == p["id"]:
			a["remaining"] = AEGIS_REFRESH
			a["duration"] = AEGIS_REFRESH
			a["value"] = float(eff["damageReduction"])
			return
	var dr := _aura(id, "shield_wall", AEGIS_REFRESH, float(eff["damageReduction"]), p)
	RpgCombat.apply_aura(w, p, dr)


## tickPaladinAegis: each channel tick heals (tick roll + the channel share of heal
## power, primary-healing scaled). True when this channel is the Aegis.
static func aegis_tick(w: RpgEncounter, p: Dictionary, res: Dictionary) -> bool:
	var eff := _aegis_eff(res)
	if eff.is_empty():
		return false
	var def: Dictionary = res["def"]
	var hm := RpgTalents.hit_mult(w.pack, def, p["mods"])
	var sp := RpgChannel._bonus(w, float(p["heal_power"]), def, float(hm["heal"]))
	var amount := RpgEffects.scale_primary(
		w.rng.range_f(float(eff["tickMin"]), float(eff["tickMax"])) + sp,
		RpgEffects.primary_heal_mult(p)
	)
	RpgCombat.apply_heal(w, p, p, amount)
	return true


## completePaladinAegis: the final heal and the speed, then the cut ends.
static func aegis_complete(w: RpgEncounter, p: Dictionary, res: Dictionary) -> void:
	var eff := _aegis_eff(res)
	if eff.is_empty():
		return
	var def: Dictionary = res["def"]
	var hm := RpgTalents.hit_mult(w.pack, def, p["mods"])
	var bonus := RpgEffects.direct_heal_bonus(
		w, float(p["heal_power"]), 0.0, float(hm["heal"]), true
	)
	var amount := RpgEffects.scale_primary(
		w.rng.range_f(float(eff["finalMin"]), float(eff["finalMax"])) + bonus,
		RpgEffects.primary_heal_mult(p)
	)
	RpgCombat.apply_heal(w, p, p, amount)
	var speed := _aura(
		AEGIS_ID + "_speed", "buff_speed", float(eff["speedDuration"]), float(eff["speedMult"]), p
	)
	RpgCombat.apply_aura(w, p, speed)
	aegis_cleanup(w, p)


## cleanupPaladinAegis (also on a cancelled channel).
static func aegis_cleanup(w: RpgEncounter, p: Dictionary) -> void:
	var id := "%s_dr:%d" % [AEGIS_ID, int(p["id"])]
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["id"] == id and a["source_id"] == p["id"]:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
