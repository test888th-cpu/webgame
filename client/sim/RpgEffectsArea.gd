class_name RpgEffectsArea
extends RefCounted
## runEffects' area, control and utility arms (src/sim/combat/effect_dispatch.ts),
## each the reference arm named on it. Areas use the street's axis
## (RpgAbilityRules.hostiles_in_radius); the street has no party, so a party or
## ally-radius effect lands on the caster alone (friendliesInRadius finds only the
## caster).


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


## The arm for `eff`; false when no arm here handles its type.
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
		"aoeDamage":
			_aoe_damage(w, p, target, res, eff, ctx)
		"aoeAttackSpeed":
			for m: Dictionary in _near(w, p, float(eff["radius"])):
				_aura(
					w,
					m,
					def["id"] + "_as",
					"attackspeed",
					float(eff["duration"]),
					float(eff["mult"]),
					p,
					def
				)
		"aoeAttackPower":
			_aoe_attack_power(w, p, def, eff)
		"aoeSlow":
			for m: Dictionary in _near(w, p, float(eff["radius"])):
				_aura(
					w,
					m,
					def["id"] + "_slow",
					"slow",
					float(eff["duration"]),
					float(eff["mult"]),
					p,
					def
				)
				w.enter_combat(p, m)
		"aoeFear":
			_aoe_fear(w, p, def, eff)
		"taunt":
			if not target.is_empty() and target["kind"] == "mob" and not target["dead"]:
				RpgWorld.apply_taunt(w, p, target)
		"aoeTaunt":
			for m: Dictionary in _near(w, p, float(eff["radius"])):
				RpgWorld.apply_taunt(w, p, m)
		"interrupt":
			_interrupt(w, p, target, def, eff)
		"charge":
			_charge(w, p, target)
		"sunder":
			_sunder(w, p, target, res, eff, ctx)
		"enrageChance":
			_enrage_chance(w, p, def, eff)
		"selfHealPctMax":
			var pct := float(eff["pct"])
			for a: Dictionary in p["auras"]:
				if a["id"] == "furious_mending":
					pct = maxf(pct, 0.2)
			RpgCombat.apply_heal(w, p, p, float(_jr(float(p["max_hp"]) * pct)))
			RpgHunter.on_self_heal_pct(w, p, str(def["id"]))
		"selfDamagePctMax":
			var dmg := _jr(float(p["max_hp"]) * float(eff["pct"]))
			p["hp"] = maxi(1, int(p["hp"]) - dmg)
			_log_self_damage(w, p, dmg, "physical", def)
		"selfDamagePctCurrent":
			var cur := maxi(1, _jr(float(p["hp"]) * float(eff["pct"])))
			p["hp"] = maxi(1, int(p["hp"]) - cur)
			_log_self_damage(w, p, cur, "shadow", def)
		"selfAbsorbPctMax":
			_aura(
				w,
				p,
				str(def["id"]),
				"absorb",
				float(eff["duration"]),
				float(_jr(float(p["max_hp"]) * float(eff["pct"]))),
				p,
				def
			)
		"aoeAllyMaxHp":
			_aura(
				w,
				p,
				def["id"] + "_hp",
				"buff_maxhp_pct",
				float(eff["duration"]),
				float(eff["pct"]),
				p,
				def
			)
			if p["spec_id"] == "prot":
				_aura(w, p, def["id"] + "_dr", "buff_dr", float(eff["duration"]), 0.05, p, def)
			w.recalc_player()
		"partyMeleeBuff":
			if str(p["class_id"]) in w.pack["constants"]["melee_classes"]:
				var aura := _make(
					str(def["id"]),
					"sanguine",
					float(eff["duration"]),
					float(eff["attackSpeedMult"]),
					p,
					def
				)
				aura["value2"] = float(eff["dmgPct"])
				RpgCombat.apply_aura(w, p, aura)
		"aoeAllySureCrit":
			var crit := _make(def["id"] + "_crit", "sure_crit", float(eff["duration"]), 0.0, p, def)
			crit["charges"] = int(eff["charges"])
			RpgCombat.apply_aura(w, p, crit)
		"breakControl":
			_break_control(w, p)
		"debuffTargetSource":
			if not target.is_empty() and not target["dead"]:
				_aura(
					w,
					target,
					str(eff["auraId"]),
					str(eff["kind"]),
					float(eff["duration"]),
					float(eff["value"]),
					p,
					def
				)
		"repositionToAim":
			if eff.get("landingAoe") != null:
				RpgMotion.arm_leap(
					w,
					p,
					float(p["cast_aim"]) if p.get("cast_aim") != null else float(p["x"]),
					eff["landingAoe"],
					def
				)
		"absorbSpentResource":
			var amount := _jr(float(res["cost"]) * float(eff["mult"]))
			if amount > 0:
				_aura(w, p, str(def["id"]), "absorb", float(eff["duration"]), float(amount), p, def)
		"consumeDot":
			_consume_dot(w, p, target, def, eff)
		"extendDot":
			if not target.is_empty():
				RpgEffects.extend_owned_dot(target, p["id"], eff)
		"polymorph":
			_polymorph(w, p, target, def, eff)
		"cleanseSelf":
			var debuffs: Array = w.pack["constants"]["debuff_aura_kinds"]
			for a: Dictionary in (p["auras"] as Array).duplicate():
				var k := str(a["kind"])
				var harmful := k in debuffs or (k.begins_with("buff_") and float(a["value"]) < 0.0)
				if (
					harmful
					and not a.get("unbreakable_control", false)
					and not a.get("undispellable", false)
				):
					RpgAbilityRules.remove_aura(w, p, a)
		"aoeAllyAbsorb":
			_aoe_ally_absorb(w, p, res, eff, ctx)
		"silence":
			if not target.is_empty() and not target["dead"]:
				_aura(
					w,
					target,
					def["id"] + "_silence",
					"silence",
					float(eff["duration"]),
					0.0,
					p,
					def
				)
				w.enter_combat(p, target)
		"aoeHeal":
			_aoe_heal(w, p, target, res, eff, ctx)
		"groundAoE":
			RpgGround.cast(w, p, res, eff, ctx)
		"aoeRoot":
			_aoe_root(w, p, res, eff, ctx)
		"clearCooldowns":
			for id: String in eff["abilities"]:
				p["cooldowns"].erase(id)
				var bank: Dictionary = p.get("ability_charges", {}).get(id, {})
				if not bank.is_empty():
					bank["charges"] = bank["max"]
					bank["recharges"] = []
		"finisherDamage":
			_finisher_damage(w, p, target, res, eff, ctx)
		"finisherHaste":
			if int(ctx["spent_combo"]) > 0:
				var dur := float(eff["basedur"]) + float(eff["perCombo"]) * int(ctx["spent_combo"])
				_aura(
					w,
					p,
					str(def["id"]),
					"buff_haste",
					dur,
					float(eff["mult"]),
					p,
					{"school": "physical"}
				)
		"finisherStun":
			if not target.is_empty() and not target["dead"] and int(ctx["spent_combo"]) > 0:
				var dur := float(eff["base"]) + float(eff["perCombo"]) * int(ctx["spent_combo"])
				_aura(w, target, def["id"] + "_stun", "stun", dur, 0.0, p, def)
				w.enter_combat(p, target)
		"imbue":
			_imbue(w, p, def, eff)
		"applyDebuff":
			if not target.is_empty() and not target["dead"]:
				_aura(
					w,
					target,
					"%s_%s" % [def["id"], eff["kind"]],
					str(eff["kind"]),
					float(eff["duration"]),
					float(eff["value"]),
					p,
					def
				)
				w.enter_combat(p, target)
		"blinkForward":
			_blink_forward(w, p, target, def, eff)
		"aoeAllyHaste":
			# applyGroupHaste: the caster (friendliesInRadius, or the group-only
			# list, finds only the caster on the street).
			if not (eff.get("exhaust", false) and RpgAbilityRules.has_kind(p, "sated")):
				_aura(
					w,
					p,
					str(def["id"]),
					"buff_haste",
					float(eff["duration"]),
					float(eff["mult"]),
					p,
					def
				)
				if eff.get("spell", false):
					_aura(
						w,
						p,
						def["id"] + "_spell",
						"buff_spellhaste",
						float(eff["duration"]),
						float(eff["mult"]) - 1.0,
						p,
						def
					)
				if eff.get("exhaust", false):
					RpgClassHooks.apply_sated(w, p, str(def["school"]))
		"chainDamage":
			if not RpgEffectsClass.run_arm(w, p, target, res, eff, ctx):
				_chain_damage(w, p, target, res, eff, ctx)
		_:
			return RpgEffectsClass.run_arm(w, p, target, res, eff, ctx)
	return true


## chainDamage: one shared roll (+ the AoE share of power, x damageMult); hop i takes
## falloff^i of it; each hop is the nearest unstruck hostile within the radius of the
## last (the primary itself first when hitsPrimary).
static func _chain_damage(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
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
	var primary: bool = eff.get("hitsPrimary", false) and not target.is_empty()
	var hits: Array = [target] if primary else []
	var excluded := {p["id"]: true}
	if not target.is_empty():
		excluded[target["id"]] = true
	var from: Dictionary = target if not target.is_empty() else p
	var total := int(eff["jumps"]) + (1 if primary else 0)
	while hits.size() < total:
		var best := {}
		var best_d := INF
		for m: Dictionary in RpgAbilityRules.hostiles_in_radius(
			w, p, float(from["x"]), float(eff["radius"])
		):
			if excluded.has(m["id"]):
				continue
			var d := absf(float(m["x"]) - float(from["x"]))
			if best.is_empty() or d < best_d or (d == best_d and int(m["id"]) < int(best["id"])):
				best = m
				best_d = d
		if best.is_empty():
			break
		excluded[best["id"]] = true
		hits.append(best)
		from = best
	var first := [0, 0]
	for i in hits.size():
		var m: Dictionary = hits[i]
		var dmg := base * pow(float(eff["falloff"]), i)
		if ctx["is_spell"]:
			dmg *= RpgEffects.spell_damage_mult(p)
		else:
			dmg *= (
				1.0 - RpgHitTable.armor_reduction(RpgCombat.effective_armor(w, m), int(p["level"]))
			)
		var landed := RpgCombat.deal_damage(
			w,
			p,
			m,
			maxi(1, _jr(dmg)),
			false,
			str(def["school"]),
			str(def["name"]),
			"hit",
			false,
			{"flat": ctx["threat_flat"], "mult": ctx["threat_mult"], "ability_id": def["id"]}
		)
		if i == 0:
			first = [maxi(1, _jr(dmg)), landed]
	if not hits.is_empty():
		RpgShaman.after_chain(
			w, p, str(def["id"]), hits[0], first[0], first[1], float(ctx["threat_mult"])
		)


## finisherDamage: base + per point + a variance roll + AP / 14 x the talent
## multiplier, Knockout's Redline, one crit draw, armor; a five-point finisher with
## Second Shadow repeats part of it as shadow.
static func _finisher_damage(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var spent := int(ctx["spent_combo"])
	if target.is_empty() or (spent <= 0 and not def.get("comboOptional", false)):
		return
	var dmg := (
		float(eff["base"])
		+ float(eff["perCombo"]) * spent
		+ w.rng.range_f(0.0, float(eff["variance"]))
		+ RpgCombat.effective_attack_power(p) / 14.0 * float(ctx["dmg_mult"])
	)
	dmg *= RpgRogue.knockout_redline_mult(w, p, str(def["id"]))
	dmg *= RpgDruid.apex_payoff_mult(w, p, str(def["id"]))
	var forced := RpgAbilityRules.consume_next_attack_crit(w, p)
	var crit: bool = (
		w.rng.chance(1.0 if forced else float(p["crit"]))
		or bool(ctx["sure_crit"])
		or RpgClassHooks.guaranteed_crit(w, p, def, target)
	)
	if ctx["sure_crit"]:
		ctx["sure_crit_rolled"] = true
	if crit:
		dmg *= 2.0 + float(p["crit_dmg_phys"])
	dmg *= 1.0 - RpgHitTable.armor_reduction(RpgCombat.effective_armor(w, target), int(p["level"]))
	var threat := {"flat": ctx["threat_flat"], "mult": ctx["threat_mult"], "ability_id": def["id"]}
	RpgCombat.deal_damage(
		w, p, target, _jr(dmg), crit, "physical", str(def["name"]), "hit", false, threat
	)
	RpgDruid.on_landed_strike(w, p, str(def["id"]))
	var echo := float(p["mods"]["global"]["secondShadowPct"])
	if spent >= 5 and not target["dead"] and echo > 0.0:
		RpgCombat.deal_damage(
			w, p, target, _jr(dmg * echo), false, "shadow", "Second Shadow", "hit", true, threat
		)


## imbue: one weapon imbue at a time (the shaman's Galeheart and Rockbiter set a
## posture instead).
static func _imbue(w: RpgEncounter, p: Dictionary, def: Dictionary, eff: Dictionary) -> void:
	if RpgShaman.imbue_posture(w, p, def, eff):
		return
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["kind"] == "imbue" and a["id"] != def["id"]:
			RpgAbilityRules.remove_aura(w, p, a)
	_aura(w, p, str(def["id"]), "imbue", float(eff["duration"]), float(eff["bonus"]), p, def)


## blinkForward: a step along the facing (Shadowstep: to 1.5 yd short of its target);
## breakRoots clears roots first.
static func _blink_forward(
	w: RpgEncounter, p: Dictionary, target: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	if eff.get("breakRoots", false):
		for a: Dictionary in (p["auras"] as Array).duplicate():
			if a["kind"] == "root":
				RpgAbilityRules.remove_aura(w, p, a)
	var distance := float(eff["distance"])
	var facing := float(p.get("facing", 1.0))
	if def["id"] == "shadowstep" and not target.is_empty() and not target["dead"]:
		var dx := float(target["x"]) - float(p["x"])
		if absf(dx) <= 1.5:
			return
		facing = signf(dx)
		p["facing"] = facing
		distance = minf(absf(dx) - 1.5, distance)
	p["x"] = clampf(float(p["x"]) + facing * distance, w.bounds.x, w.bounds.y)
	p["charge_target"] = -1


static func _near(w: RpgEncounter, p: Dictionary, radius: float) -> Array:
	return RpgAbilityRules.hostiles_in_radius(w, p, float(p["x"]), radius)


static func _make(
	id: String, kind: String, duration: float, value: float, p: Dictionary, def: Dictionary
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": duration,
		"duration": duration,
		"value": value,
		"source_id": p["id"],
		"school": def["school"],
	}


static func _aura(
	w: RpgEncounter,
	t: Dictionary,
	id: String,
	kind: String,
	duration: float,
	value: float,
	p: Dictionary,
	def: Dictionary
) -> void:
	RpgCombat.apply_aura(w, t, _make(id, kind, duration, value, p, def))


static func _log_self_damage(
	w: RpgEncounter, p: Dictionary, amount: int, school: String, def: Dictionary
) -> void:
	w.log_event(
		{
			"type": "damage",
			"source": p["id"],
			"target": p["id"],
			"amount": amount,
			"crit": false,
			"school": school,
			"ability": def["name"],
			"kind": "hit"
		}
	)


## aoeDamage: every hostile in the radius (in front when frontal); a soft cap scales
## each hit down past its target count; one crit draw for the cast when it can crit.
static func _aoe_damage(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var center := float(p["x"])
	if eff.get("centerOnTarget", false) and not target.is_empty():
		center = float(target["x"])
	elif p.get("cast_aim") != null:
		center = float(p["cast_aim"])
	var sp := RpgEffects.direct_hit_bonus(
		w, RpgEffects.scaling_power(p, def), def, float(res["castTime"]), true, ctx["dmg_mult"]
	)
	var targets: Array = []
	for m: Dictionary in RpgAbilityRules.hostiles_in_radius(w, p, center, float(eff["radius"])):
		if eff.get("frontal", false) and not RpgAbilityRules.in_front(p, m):
			continue
		targets.append(m)
	var cap := 1.0
	if eff.get("softCap") != null and targets.size() > int(eff["softCap"]):
		cap = float(eff["softCap"]) / targets.size()
	var is_spell: bool = ctx["is_spell"]
	var crit: bool = (
		bool(eff.get("canCrit", false))
		and not targets.is_empty()
		and (w.rng.chance(RpgCombat.spell_crit(p)) or RpgClassHooks.guaranteed_crit(w, p, def, {}))
	)
	var verdict := {}
	for m: Dictionary in targets:
		var mark := RpgPaladinKit.verdict_mark(p, m, str(def["id"]))
		var dmg := w.rng.range_f(float(eff["min"]), float(eff["max"])) + sp
		if is_spell:
			dmg *= RpgEffects.spell_damage_mult(p)
		if crit:
			dmg *= (
				(1.5 + float(p["crit_dmg_spell"]))
				if is_spell
				else (2.0 + float(p["crit_dmg_phys"]))
			)
		if not is_spell:
			dmg *= (
				1.0 - RpgHitTable.armor_reduction(RpgCombat.effective_armor(w, m), int(p["level"]))
			)
		dmg *= cap * float(ctx["primary_dmg_mult"])
		RpgCombat.deal_damage(
			w,
			p,
			m,
			_jr(dmg),
			crit,
			str(def["school"]),
			str(def["name"]),
			"hit",
			false,
			{"flat": ctx["threat_flat"], "mult": ctx["threat_mult"], "ability_id": def["id"]}
		)
		if not mark.is_empty():
			verdict = {"target": m, "mark": mark}
		if eff.get("stunSec") != null and not m["dead"]:
			_aura(w, m, def["id"] + "_stun", "stun", float(eff["stunSec"]), 0.0, p, def)
	if not verdict.is_empty():
		RpgPaladinKit.advance_verdict(w, p, verdict["target"], str(def["id"]), verdict["mark"])
	if def["id"] == "dawnfall" and not targets.is_empty() and not ctx.get("dawn_rhythm", false):
		RpgPaladinProcs.dawn_rhythm(p, "dawnfall")
		ctx["dawn_rhythm"] = true
	if eff.get("rageOnHit") != null and p["class_id"] == "warrior" and p["resource_type"] == "rage":
		var roh: Dictionary = eff["rageOnHit"]
		var hits := mini(targets.size(), int(roh["capTargets"]))
		var gain := (
			(float(roh["base"]) + float(roh["perTarget"]) * hits)
			* RpgWarrior.ability_rage_mult(w, p)
		)
		p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + gain)
	if bool(eff.get("canCrit", false)) and not targets.is_empty() and is_spell:
		RpgMage.note_spell_hit(w, p, crit, str(def["id"]))
	if def.get("awardsCombo") != null and not ctx["combo_awarded"] and not targets.is_empty():
		RpgRogue.award_combo(w, p, targets[0], int(def["awardsCombo"]))
		ctx["combo_awarded"] = true
	if not targets.is_empty():
		RpgDruid.on_landed_strike(w, p, str(def["id"]))


## resolveWeaponSweep: a weapon strike on every hostile in front within the radius.
## Returns how many connected.
static func weapon_sweep(
	w: RpgEncounter,
	p: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary,
	crit_bonus: float
) -> int:
	var def: Dictionary = res["def"]
	var landed := 0
	for m: Dictionary in _near(w, p, float(eff["sweepRadius"])):
		if not RpgAbilityRules.in_front(p, m):
			continue
		var opts := {
			"weapon_mult": float(eff.get("weaponMult", 1.0)),
			"bonus": float(eff["bonus"]),
			"crit_bonus": crit_bonus,
			"force_crit": bool(ctx["sure_crit"]),
			"primary_dmg_mult": float(ctx["primary_dmg_mult"]),
			"ability_id": def["id"],
			"threat_flat": ctx["threat_flat"],
			"threat_mult": ctx["threat_mult"],
		}
		if w.player_melee(m, opts, str(def["name"])):
			landed += 1
			if def.get("awardsCombo") != null:
				RpgRogue.award_combo(w, p, m, int(def["awardsCombo"]))
	return landed


## aoeAttackPower: a percent cut is a negative damage-done aura; a flat one debuff_ap.
static func _aoe_attack_power(
	w: RpgEncounter, p: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	for m: Dictionary in _near(w, p, float(eff["radius"])):
		if eff.get("pct") != null:
			_aura(
				w,
				m,
				def["id"] + "_ap",
				"buff_dmg_done",
				float(eff["duration"]),
				-float(eff["pct"]),
				p,
				def
			)
		else:
			_aura(
				w,
				m,
				def["id"] + "_ap",
				"debuff_ap",
				float(eff["duration"]),
				float(eff.get("amount", 0.0)),
				p,
				def
			)
		w.enter_combat(p, m)


## aoeFear: up to maxTargets hostiles flee (an incapacitate with a random heading
## that breaks on damage by chance, or past fearBreakPct of max health).
static func _aoe_fear(w: RpgEncounter, p: Dictionary, def: Dictionary, eff: Dictionary) -> void:
	var break_pct := float(p["mods"]["global"]["fearBreakPct"])
	var feared := 0
	for m: Dictionary in _near(w, p, float(eff["radius"])):
		if eff.get("maxTargets") != null and feared >= int(eff["maxTargets"]):
			break
		var lock := RpgWarlock.fear_break_threshold(str(def["id"]), int(m["max_hp"]))
		feared += 1
		var aura := _make(
			"fear_incap", "incapacitate", float(eff["duration"]), w.rng.range_f(-PI, PI), p, def
		)
		aura["name"] = str(def["name"])
		aura["breaks_on_damage"] = true
		if lock < 0:
			aura["break_chance_scale"] = float(w.pack["constants"]["fear_break_chance_scale"])
		if lock >= 0:
			aura["break_threshold"] = lock
		elif break_pct > 0.0:
			aura["break_threshold"] = maxi(1, _jr(float(m["max_hp"]) * break_pct))
		RpgCombat.apply_aura(w, m, aura)
		w.enter_combat(p, m)


## The single-target incapacitate arm (fearDr: a heading and the fear break rule).
static func incapacitate(
	w: RpgEncounter, p: Dictionary, target: Dictionary, res: Dictionary, eff: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var fear: bool = def.get("fearDr", false)
	var lock := RpgWarlock.fear_break_threshold(str(def["id"]), int(target["max_hp"]))
	var aura := _make(
		def["id"] + "_incap",
		"incapacitate",
		float(eff["duration"]),
		w.rng.range_f(-PI, PI) if fear else 0.0,
		p,
		def
	)
	aura["breaks_on_damage"] = true
	if fear and lock < 0:
		aura["break_chance_scale"] = float(w.pack["constants"]["fear_break_chance_scale"])
	if lock >= 0:
		aura["break_threshold"] = lock
	RpgCombat.apply_aura(w, target, aura)
	if def["id"] == "gouge":
		RpgAutoAttack.reset_swing_timer(w)
	if def.get("awardsCombo") != null:
		RpgRogue.award_combo(w, p, target, int(def["awardsCombo"]))


## polymorph: the target heals to full, its other damage-over-time ends.
static func _polymorph(
	w: RpgEncounter, p: Dictionary, target: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	if target.is_empty() or target["dead"]:
		return
	target["hp"] = target["max_hp"]
	var aura := _make(str(def["id"]), "polymorph", float(eff["duration"]), 0.0, p, def)
	aura["tick_interval"] = 1.0
	aura["tick_timer"] = 1.0
	aura["breaks_on_damage"] = true
	RpgCombat.apply_aura(w, target, aura)
	target["auras"] = (target["auras"] as Array).filter(
		func(a: Dictionary) -> bool: return a["kind"] != "dot" or a["id"] == def["id"]
	)
	w.enter_combat(p, target)


## interrupt: only a target casting a non-physical, interruptible spell (the
## street's monsters cast nothing, so this lands on players' foes only when one is
## casting); its school locks out; a warrior gains rage on the interrupt.
static func _interrupt(
	w: RpgEncounter, p: Dictionary, target: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	if target.is_empty() or target.get("casting", {}).is_empty():
		return
	var cast_def: Dictionary = w.pack["abilities"].get(str(target["casting"]["ability"]), {}).get(
		"def", {}
	)
	if (
		cast_def.is_empty()
		or cast_def["school"] == "physical"
		or cast_def.get("uninterruptible", false)
	):
		return
	target["casting"] = {}
	if (
		eff.get("rageOnInterrupt") != null
		and p["class_id"] == "warrior"
		and p["resource_type"] == "rage"
	):
		p["resource"] = minf(
			float(p["max_resource"]),
			(
				float(p["resource"])
				+ float(eff["rageOnInterrupt"]) * RpgWarrior.ability_rage_mult(w, p)
			)
		)
	_aura(
		w,
		target,
		def["id"] + "_lockout",
		"lockout",
		float(eff["lockout"]),
		0.0,
		p,
		{"school": cast_def["school"]}
	)


## charge: a run at the target (RpgEncounter moves it); a rage user gains 9 (x the
## warrior's ability rage multiplier).
static func _charge(w: RpgEncounter, p: Dictionary, target: Dictionary) -> void:
	if target.is_empty():
		return
	p["charge_target"] = int(target["id"])
	p["charge_time"] = float(w.pack["constants"]["charge_max_duration"])
	if target["kind"] != "mob":
		return
	if p["resource_type"] == "rage":
		var gain := 9.0 * RpgWarrior.ability_rage_mult(w, p)
		p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + gain)
	w.enter_combat(p, target)


## sunder: one miss draw; a stack of armor reduction (to maxStacks), refreshed.
static func _sunder(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	if target.is_empty() or target["dead"]:
		return
	var def: Dictionary = res["def"]
	var miss := RpgHitTable.swing_miss_chance(
		int(p["level"]), int(target["level"]), false, float(p.get("hit_bonus", 0.0))
	)
	if w.rng.chance(miss):
		RpgEffects._log_miss(w, p, target, str(def["name"]))
		return
	var spent := int(ctx["spent_combo"])
	var combo_stacks := (
		mini(int(eff["maxStacks"]), maxi(1, spent)) if eff.get("perCombo", false) else -1
	)
	var existing := RpgAbilityRules.find_kind(target, "sunder")
	if not existing.is_empty():
		if eff.get("full", false):
			existing["stacks"] = int(eff["maxStacks"])
		elif combo_stacks >= 0:
			existing["stacks"] = combo_stacks
		else:
			existing["stacks"] = mini(int(eff["maxStacks"]), int(existing.get("stacks", 1)) + 1)
		existing["value"] = float(eff["armor"])
		existing["remaining"] = existing["duration"]
	else:
		var aura := _make(str(def["id"]), "sunder", 30.0, float(eff["armor"]), p, def)
		aura["school"] = "physical"
		aura["stacks"] = (
			int(eff["maxStacks"])
			if eff.get("full", false)
			else (combo_stacks if combo_stacks >= 0 else 1)
		)
		RpgCombat.apply_aura(w, target, aura)
	w.enter_combat(p, target)


## enrageChance: Enraged (ENRAGE_DMG_DONE damage done) on the roll.
static func _enrage_chance(
	w: RpgEncounter, p: Dictionary, _def: Dictionary, eff: Dictionary
) -> void:
	if float(eff["chance"]) < 1.0 and not w.rng.chance(float(eff["chance"])):
		return
	var dur := float(eff["duration"])
	var enrage_dmg := float(w.pack["constants"]["enrage_dmg_done"])
	(
		RpgCombat
		. apply_aura(
			w,
			p,
			{
				"id": "fury_enrage",
				"kind": "enrage",
				"remaining": dur,
				"duration": dur,
				"value": enrage_dmg,
				"source_id": p["id"],
				"school": "physical",
			}
		)
	)


## breakControl: control, silence, blind, disarm and slow from others end.
static func _break_control(w: RpgEncounter, p: Dictionary) -> void:
	var auras: Array = p["auras"]
	for i in range(auras.size() - 1, -1, -1):
		var a: Dictionary = auras[i]
		var k := str(a["kind"])
		if not (k in RpgAbilityRules.CONTROL_KINDS or k in ["silence", "blind", "disarm", "slow"]):
			continue
		if a.get("unbreakable_control", false) or a["source_id"] == p["id"]:
			continue
		RpgAbilityRules.remove_aura(w, p, a)


## consumeDot: the caster's named dot ends and its remaining ticks land at once.
static func _consume_dot(
	w: RpgEncounter, p: Dictionary, target: Dictionary, def: Dictionary, eff: Dictionary
) -> void:
	if target.is_empty():
		return
	for a: Dictionary in target["auras"]:
		if a["kind"] != "dot" or a["id"] != eff["dot"] or a["source_id"] != p["id"]:
			continue
		var interval := float(a.get("tick_interval", 1.0))
		var until_next := float(a.get("tick_timer", interval))
		var left := 0
		if until_next <= float(a["remaining"]):
			left = 1 + maxi(0, int(floorf((float(a["remaining"]) - until_next) / interval)))
		var remaining := _jr(
			float(a["value"]) * left * RpgDruid.apex_payoff_mult(w, p, str(def["id"]))
		)
		RpgAbilityRules.remove_aura(w, target, a)
		if remaining > 0:
			RpgCombat.deal_damage(
				w, p, target, remaining, false, str(def["school"]), str(def["name"])
			)
		return


## aoeRoot: every hostile in the radius takes the damage (when any) and a root that
## breaks past its damage budget (or a stun); Ring of Frost and hunter traps spawn
## their own areas.
static func _aoe_root(
	w: RpgEncounter, p: Dictionary, res: Dictionary, eff: Dictionary, ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var center := float(p["cast_aim"]) if p.get("cast_aim") != null else float(p["x"])
	if eff.get("ring") != null:
		RpgMage.spawn_ring_of_frost(w, p, center, eff, def)
		return
	if eff.get("trap") != null:
		RpgHunter.spawn_trap(w, p, eff, def)
		return
	var deals := float(eff["min"]) != 0.0 or float(eff["max"]) != 0.0
	var sp := 0
	if deals:
		sp = RpgEffects.direct_hit_bonus(
			w, RpgEffects.scaling_power(p, def), def, float(res["castTime"]), true, ctx["dmg_mult"]
		)
	for m: Dictionary in RpgAbilityRules.hostiles_in_radius(w, p, center, float(eff["radius"])):
		if deals:
			var dmg := w.rng.range_f(float(eff["min"]), float(eff["max"])) + sp
			RpgCombat.deal_damage(w, p, m, _jr(dmg), false, str(def["school"]), str(def["name"]))
		if m["dead"]:
			continue
		if eff.get("stun", false):
			_aura(w, m, def["id"] + "_freeze", "stun", float(eff["duration"]), 0.0, p, def)
			continue
		var root := _make(def["id"] + "_root", "root", float(eff["duration"]), 0.0, p, def)
		if eff.get("breakOnDamage") != null:
			var b: Dictionary = eff["breakOnDamage"]
			root["breaks_on_damage"] = true
			root["break_threshold"] = mini(
				int(b["max"]), maxi(int(b["min"]), _jr(int(m["max_hp"]) * float(b["maxHpPct"])))
			)
		RpgCombat.apply_aura(w, m, root)
		if def["id"] == "earthbind":
			_aura(w, m, "earthbind_slow", "slow", 8.0, 0.6, p, def)


## aoeAllyAbsorb: the group's shield (the caster alone on the street); Mass Barrier
## also starts the spec's own personal barrier's cooldown.
static func _aoe_ally_absorb(
	w: RpgEncounter, p: Dictionary, res: Dictionary, eff: Dictionary, ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var spec := str(p["spec_id"])
	var school := str(def["school"])
	if def["id"] == "mass_barrier":
		var barrier := {
			"arcane": "temporal_barrier", "fire": "blazing_barrier", "frost": "ice_barrier"
		}
		if barrier.has(spec):
			var k := w.known_entry(str(barrier[spec]))
			if not k.is_empty() and float(k["cooldown"]) > 0.0:
				var id := str(barrier[spec])
				p["cooldowns"][id] = maxf(float(p["cooldowns"].get(id, 0.0)), float(k["cooldown"]))
		if spec == "arcane" or spec == "fire":
			school = spec
	var value := (
		float(eff["amount"])
		+ maxi(
			0,
			_jr(
				(
					float(p["heal_power"])
					* float(eff.get("spellPowerCoeff", 0.0))
					* float(ctx["heal_mult"])
					* (1.0 + float(p["mods"]["global"]["absorbPct"]))
				)
			)
		)
	)
	var aura := _make(str(def["id"]), "absorb", float(eff["duration"]), value, p, def)
	aura["school"] = school
	RpgCombat.apply_aura(w, p, aura)


## aoeHeal: every friendly in the radius (the caster on the street) takes a rolled
## heal; the priest's group-heal talents read each.
static func _aoe_heal(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var center: Dictionary = (
		target if eff.get("centerOnTarget", false) and not target.is_empty() else p
	)
	if eff.get("friendlyTargetOnly", false) and center["kind"] == "mob":
		return
	if absf(float(p["x"]) - float(center["x"])) > float(eff["radius"]):
		return
	var bonus := RpgEffects.direct_heal_bonus(
		w, float(p["heal_power"]), float(res["castTime"]), float(ctx["heal_mult"]), true
	)
	var amount := RpgEffects.scale_primary(
		w.rng.range_f(float(eff["min"]), float(eff["max"])) + bonus, RpgEffects.primary_heal_mult(p)
	)
	var missing := int(p["max_hp"]) - int(p["hp"])
	var out := {}
	var healed := RpgCombat.apply_heal(w, p, p, amount, true, out)
	RpgPriest.on_group_heal(w, p, p, def, int(out.get("resolved", 0)), missing, healed)
	if def["id"] == "radiant_chorus":
		RpgPaladinProcs.grant_resonance(w, p, 1 if healed > 0 else 0)
