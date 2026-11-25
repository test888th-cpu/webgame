class_name RpgEffects
extends RefCounted
## The effect runner (src/sim/combat/effect_dispatch.ts runEffects): its preamble,
## the single-target arms here, the area and utility arms in RpgEffectsArea, and its
## epilogue. Class-specific branches call the class modules (RpgWarrior, RpgRogue,
## ...). `res` is a known-ability entry (RpgTalents.known) and `p` the caster;
## `target` may be {}.

const DOT_COEFF_HYBRID_KINDS: Array[String] = [
	"directDamage", "chainDamage", "aoeDamage", "aoeRoot"
]


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


## The power an ability scales with (spell_scaling.ts abilityScalingPower).
static func scaling_power(p: Dictionary, def: Dictionary) -> float:
	if def.get("scalesWith") == "ranged":
		return float(p.get("ranged_power", 0))
	if def.get("school") == "physical":
		return float(p.get("attack_power", 0))
	return float(p.get("spell_power", 0))


## powerScale.
static func power_scale(w: RpgEncounter, def: Dictionary) -> float:
	if def.get("scalesWith") == "ranged":
		return float(w.pack["constants"]["ranged_spell_ap_scale"])
	if def.get("school") == "physical":
		return float(w.pack["constants"]["melee_spell_ap_scale"])
	return 1.0


## clampCast.
static func clamp_cast(w: RpgEncounter, seconds: float) -> float:
	var c: Dictionary = w.pack["constants"]
	var t := float(c["spell_coeff_min_cast"]) if seconds <= 0.0 else seconds
	return minf(float(c["spell_coeff_max_cast"]), maxf(float(c["spell_coeff_min_cast"]), t))


## directHitBonus.
static func direct_hit_bonus(
	w: RpgEncounter,
	power: float,
	def: Dictionary,
	cast_time: float,
	aoe: bool,
	mult: float,
	coefficient_override: Variant = null
) -> int:
	var c: Dictionary = w.pack["constants"]
	var coeff := (
		float(coefficient_override)
		if coefficient_override != null
		else clamp_cast(w, cast_time) / float(c["spell_coeff_divisor"])
	)
	if aoe:
		coeff *= float(c["spell_aoe_coeff_mult"])
	return _jr(power * coeff * power_scale(w, def) * mult)


## directHealBonus.
static func direct_heal_bonus(
	w: RpgEncounter, heal_power: float, cast_time: float, mult: float, aoe := false
) -> int:
	var c: Dictionary = w.pack["constants"]
	var coeff := clamp_cast(w, cast_time) / float(c["spell_coeff_divisor"])
	if aoe:
		coeff *= float(c["spell_aoe_coeff_mult"])
	return _jr(heal_power * float(c["healing_sp_scale"]) * coeff * mult)


## dotTickBonus / hotTickBonus.
static func periodic_bonus(
	w: RpgEncounter, power: float, scale: float, duration: float, interval: float, mult: float
) -> int:
	var ticks := maxf(1.0, duration / interval) if interval > 0.0 else 1.0
	var coeff := duration / float(w.pack["constants"]["spell_dot_coeff_duration"]) / ticks
	return _jr(power * coeff * scale * mult)


## spellDamageMultFromAuras.
static func spell_damage_mult(p: Dictionary) -> float:
	var bonus := 0.0
	for a: Dictionary in p["auras"]:
		if a["kind"] == "buff_spelldmg":
			bonus += float(a["value"])
		elif a["kind"] == "form_moonkin":
			bonus += 0.2
	return 1.0 + bonus


## primaryHealingMultiplier (spec_output_tuning.ts).
static func primary_heal_mult(p: Dictionary) -> float:
	var cls := str(p["class_id"])
	var spec := str(p["spec_id"])
	if cls == "shaman" and spec == "restoration":
		return 1.1
	if cls == "paladin" and spec == "holy":
		return 1.1
	if cls == "druid" and spec == "restoration":
		return 1.05
	return 1.0


## scalePrimaryHealing.
static func scale_primary(amount: float, mult: float) -> float:
	return amount if mult == 1.0 else float(_jr(amount * mult))


## isStealthToggle / preservesStealth.
static func _preserves_stealth(def: Dictionary) -> bool:
	for e: Dictionary in def.get("effects", []):
		if e["type"] == "selfBuff" and e["kind"] == "stealth":
			return true
	return def["id"] in ["sprint", "dash", "sap", "shadowstep"]


## runEffects for one cast.
static func run(
	w: RpgEncounter, p: Dictionary, target: Dictionary, res: Dictionary, attack_anim := false
) -> void:
	var def: Dictionary = res["def"]
	var hm := RpgTalents.hit_mult(w.pack, def, p["mods"])
	var echo_ok := RpgAbilityRules.qualifies_for_area_echo(res["effects"])
	var ctx := {
		"last_direct": 0,
		"last_resolved_direct": 0,
		"buff_index": 0,
		"dmg_mult": float(hm["dmg"]),
		"heal_mult": float(hm["heal"]),
		"is_spell": def["school"] != "physical",
		"spent_combo": int(p.get("combo_points", 0)) if def.get("spendsCombo", false) else 0,
		"combo_awarded": false,
		"sure_crit": RpgAbilityRules.has_kind(p, "sure_crit"),
		"sure_crit_rolled": false,
		"area_echo": echo_ok and RpgAbilityRules.has_kind(p, "aoe_echo"),
		"sweeping": echo_ok and RpgAbilityRules.has_kind(p, "sweeping_strikes"),
		"echo_dealt": false,
		"primary_dmg_mult": RpgPaladin.dawnreaver_damage_mult(p, str(def["id"])),
		"attack_anim": attack_anim,
		"threat_flat": float(res.get("threatFlat", 0.0)),
		"threat_mult": float(res.get("threatMult", 1.0)),
		"cast_heal_mult": float(res.get("natures_boon_power", 1.0)),
	}
	ctx["true_stealth"] = RpgRogue.true_stealth_ambush(p, str(def["id"]))
	RpgRogue.gloam_detonation(w, p, str(def["id"]))
	if not _preserves_stealth(def):
		RpgStealth.break_stealth(w, p)
	for e: Dictionary in res["effects"]:
		if e["type"] in ["heal", "hot", "aoeHeal"]:
			var sf := RpgAbilityRules.find_kind(p, "form_shadow")
			if not sf.is_empty():
				RpgAbilityRules.remove_aura(w, p, sf)
				w.recalc_player()
			break
	RpgWarrior.before_effects(w, p, def)
	RpgPaladin.before_effects(w, p, def, ctx)
	RpgShaman.before_effects(w, p, def, target)
	for eff: Dictionary in res["effects"]:
		var stop := false
		match str(eff["type"]):
			"weaponStrike":
				_weapon_strike(w, p, target, res, eff, ctx)
			"directDamage":
				stop = _direct_damage(w, p, target, res, eff, ctx)
			"heal":
				_heal(w, p, target, res, eff, ctx)
			"hot":
				_hot(w, p, target, res, eff, ctx)
			"dot":
				_dot(w, p, target, res, eff, ctx)
			"absorb":
				_absorb(w, p, target, res, eff, ctx)
			"selfBuff":
				_self_buff(w, p, res, eff)
			"buffTarget":
				_buff_target(w, p, target, res, eff, ctx)
			"gainResource":
				_gain_resource(w, p, eff)
			"stun", "incapacitate", "root", "slow":
				_control(w, p, target, res, eff)
			"weaponDamage":
				pass  # the queued next swing deals it (empower_next.ts)
			_:
				if not RpgEffectsArea.run_arm(w, p, target, res, eff, ctx):
					push_error("RpgEffects: no handler for " + str(eff["type"]))
		if stop:
			break
		if not target.is_empty() and target["dead"]:
			target = {}
	RpgClassHooks.after_effects(w, p, def, target, ctx)
	if def.get("spendsCombo", false) and int(ctx["spent_combo"]) > 0:
		RpgRogue.on_finisher(w, p, str(def["id"]), int(ctx["spent_combo"]))
		if not res.get("free_cast", false):
			p["combo_points"] = 0
	if ctx["sure_crit_rolled"]:
		RpgAbilityRules.consume_charge_of_kind(w, p, "sure_crit")
	if ctx["area_echo"] and ctx["echo_dealt"]:
		RpgAbilityRules.consume_charge_of_kind(w, p, "aoe_echo")


## After a single-target hit lands: area echo and sweeping strikes replay it.
static func _echo(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	amount: int,
	def: Dictionary,
	ctx: Dictionary
) -> void:
	var c: Dictionary = w.pack["constants"]
	if ctx["area_echo"]:
		ctx["echo_dealt"] = true
		RpgAbilityRules.replay_damage(
			w,
			p,
			target,
			amount,
			float(c["aoe_echo_mult"]),
			int(c["aoe_echo_max_targets"]),
			def["school"],
			def["name"]
		)
	if ctx["sweeping"]:
		RpgAbilityRules.replay_damage(
			w, p, target, amount, float(c["sweep_mult"]), 1, def["school"], def["name"]
		)


## weaponStrike: one meleeSwing with the effect's bonus and weapon multiplier (a
## sweep radius strikes every hostile in front instead).
static func _weapon_strike(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var ability_id := str(def["id"])
	var crit_bonus := float(p["mods"]["abilities"].get(ability_id, {}).get("critPct", 0.0))
	if eff.get("sweepRadius") != null:
		var landed := RpgEffectsArea.weapon_sweep(w, p, res, eff, ctx, crit_bonus)
		if landed > 0 and def.get("awardsCombo") != null:
			ctx["combo_awarded"] = true
		if landed > 0 and ctx["sure_crit"]:
			ctx["sure_crit_rolled"] = true
		return
	if target.is_empty():
		return
	var mult := float(eff.get("weaponMult", 1.0))
	var bonus := float(eff["bonus"])
	var shaped := RpgWarrior.shape_weapon_strike(w, p, ability_id, mult, bonus)
	mult = shaped[0]
	bonus = shaped[1]
	var true_stealth: bool = ctx.get("true_stealth", false)
	var edge := 1.0 if true_stealth else RpgRogue.consume_veiled_edge(w, p, ability_id)
	mult *= RpgRogue.TRUE_STEALTH_OPENER_MULT if true_stealth else edge
	if true_stealth:
		bonus = RpgTalents.js_round(bonus * RpgRogue.TRUE_STEALTH_OPENER_MULT)
	var dealt := [0]
	var verdict := RpgPaladinKit.verdict_mark(p, target, ability_id)
	var hit := w.player_melee(
		target,
		{
			"weapon_mult": mult,
			"bonus": bonus,
			"normalized": bool(eff.get("normalized", false)),
			"cannot_be_dodged": bool(eff.get("cannotBeDodged", false)),
			"crit_bonus": crit_bonus,
			"force_crit": bool(ctx["sure_crit"]),
			"primary_dmg_mult": float(ctx["primary_dmg_mult"]),
			"ability_id": ability_id,
			"threat_flat": ctx["threat_flat"],
			"threat_mult": ctx["threat_mult"],
			"on_dealt": func(amount: int, effective: int) -> void: dealt[0] = effective,
		},
		str(def["name"])
	)
	if hit:
		var amount := int(w.last_melee_dealt)
		if eff.get("restoreMana") != null and p["resource_type"] == "mana":
			p["resource"] = minf(
				float(p["max_resource"]), float(p["resource"]) + float(eff["restoreMana"])
			)
		_echo(w, p, target, amount, def, ctx)
		if eff.get("selfHealDamageFrac") != null and int(dealt[0]) > 0:
			RpgCombat.apply_heal(
				w, p, p, float(_jr(int(dealt[0]) * float(eff["selfHealDamageFrac"]))), false
			)
		if int(dealt[0]) > 0:
			RpgPaladin.note_outcome(ctx, "damage", target, amount, str(def["school"]))
		RpgClassHooks.after_weapon_strike(w, p, target, res, amount)
		RpgPaladinKit.advance_verdict(w, p, target, ability_id, verdict)
		if ctx["sure_crit"]:
			ctx["sure_crit_rolled"] = true
		if def.get("awardsCombo") != null:
			RpgRogue.award_combo(w, p, target, int(def["awardsCombo"]))
			ctx["combo_awarded"] = true
	if def.get("requiresDodgeProc", false):
		p["overpower_until"] = -1.0


## directDamage. Returns true when a physical miss ends the cast (`break effects`).
static func _direct_damage(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> bool:
	if target.is_empty() or target["kind"] == "player":
		return false
	var def: Dictionary = res["def"]
	var ability_id := str(def["id"])
	if RpgClassHooks.skip_direct_damage(w, p, res):
		return false
	var is_spell: bool = ctx["is_spell"]
	if not is_spell:
		var miss := RpgHitTable.swing_miss_chance(
			int(p["level"]), int(target["level"]), false, float(p.get("hit_bonus", 0.0))
		)
		if miss > 0.0 and w.rng.chance(miss):
			_log_miss(w, p, target, def["name"])
			return true
	var amod: Dictionary = p["mods"]["abilities"].get(ability_id, {})
	var rooted := RpgCombat.is_rooted_or_chilled(target)
	var frozen := RpgMage.frozen_cast(w, p, def, target)
	var crit_chance := float(p["crit"])
	if is_spell:
		crit_chance = RpgCombat.spell_crit(p)
		if rooted:
			crit_chance += float(p["mods"]["global"]["critVsRooted"])
	crit_chance += float(amod.get("critPct", 0.0))
	crit_chance += RpgShaman.magma_crit_bonus(p, ability_id)
	if is_spell and frozen.get("treat_as_frozen", false):
		crit_chance += float(frozen["crit_bonus"])
	var dmg := w.rng.range_f(float(eff["min"]), float(eff["max"]))
	dmg += direct_hit_bonus(
		w,
		scaling_power(p, def),
		def,
		float(res["castTime"]),
		false,
		ctx["dmg_mult"],
		eff.get("spellPowerCoeff")
	)
	dmg *= float(eff.get("damageMult", 1.0))
	if eff.get("vsRootedMult") != null and rooted:
		dmg *= float(eff["vsRootedMult"])
	if is_spell and frozen.get("treat_as_frozen", false):
		dmg *= float(frozen["damage_mult"])
	var vs_dotted := float(amod.get("dmgPctVsDotted", 0.0))
	if vs_dotted > 0.0:
		var need: Variant = amod.get("dmgPctVsDottedAbility")
		for a: Dictionary in target["auras"]:
			if (
				a["kind"] == "dot"
				and a["source_id"] == p["id"]
				and (need == null or a["id"] == need)
			):
				dmg *= 1.0 + vs_dotted
				break
	var forced := RpgAbilityRules.consume_next_attack_crit(w, p)
	var crit: bool = (
		w.rng.chance(1.0 if forced else crit_chance)
		or eff.get("guaranteedCrit", false) == true
		or bool(ctx["sure_crit"])
		or RpgClassHooks.guaranteed_crit(w, p, def, target)
	)
	if ctx["sure_crit"]:
		ctx["sure_crit_rolled"] = true
	if crit:
		dmg *= (
			(1.5 + float(p["crit_dmg_spell"])) if is_spell else (2.0 + float(p["crit_dmg_phys"]))
		)
	if is_spell:
		dmg *= spell_damage_mult(p)
	else:
		dmg *= (
			1.0 - RpgHitTable.armor_reduction(RpgCombat.effective_armor(w, target), int(p["level"]))
		)
	dmg *= RpgClassHooks.direct_damage_mult(w, p, def)
	var final := _jr(dmg * float(ctx["primary_dmg_mult"]))
	ctx["last_direct"] = final
	var hp_before := int(target["hp"])
	var resolved := RpgCombat.deal_damage(
		w,
		p,
		target,
		final,
		crit,
		str(def["school"]),
		str(def["name"]),
		"hit",
		false,
		{"flat": ctx["threat_flat"], "mult": ctx["threat_mult"], "ability_id": ability_id}
	)
	var effective := maxi(0, hp_before - int(target["hp"]))
	RpgClassHooks.after_direct_damage(w, p, target, res, final, resolved, crit)
	RpgShaman.after_direct_damage(
		w, p, target, ability_id, final, resolved, float(ctx["threat_mult"])
	)
	if eff.get("restoreMana") != null and p["resource_type"] == "mana":
		p["resource"] = minf(
			float(p["max_resource"]), float(p["resource"]) + float(eff["restoreMana"])
		)
	if effective > 0:
		RpgPaladin.note_outcome(ctx, "damage", target, final, str(def["school"]))
		RpgPaladinProcs.after_effective(w, p, ability_id, target, 0.0)
	if eff.get("selfHealDamageFrac") != null and effective > 0:
		var planned := _jr(effective * float(eff["selfHealDamageFrac"]))
		var self_healed := RpgCombat.apply_heal(w, p, p, float(planned), false)
		RpgPaladinProcs.recurring_grace(w, p, ability_id, maxi(0, planned - self_healed))
	ctx["last_resolved_direct"] = resolved
	_echo(w, p, target, resolved, def, ctx)
	if is_spell:
		_power_echo_damage(w, p, target, final, crit, def)
		RpgMage.note_spell_hit(w, p, crit, ability_id)
	if not target["dead"] and def.get("awardsCombo") != null and not ctx["combo_awarded"]:
		RpgRogue.award_combo(w, p, target, int(def["awardsCombo"]))
		ctx["combo_awarded"] = true
	return false


## The power_echo aura repeats a spell hit once, as a second bolt.
static func _power_echo_damage(
	w: RpgEncounter, p: Dictionary, target: Dictionary, final: int, crit: bool, def: Dictionary
) -> void:
	var echo := RpgAbilityRules.find_kind(p, "power_echo")
	if echo.is_empty():
		return
	RpgAbilityRules.remove_aura(w, p, echo)
	if target["dead"]:
		return
	var amount := maxi(1, _jr(final * float(echo["value"])))
	w.schedule_projectile(
		func(src: Dictionary, tgt: Dictionary) -> void:
			RpgCombat.deal_damage(w, src, tgt, amount, crit, str(def["school"]), str(def["name"]))
	)


static func _log_miss(w: RpgEncounter, p: Dictionary, target: Dictionary, label: String) -> void:
	w.log_event(
		{
			"type": "damage",
			"source": p["id"],
			"target": target["id"],
			"amount": 0,
			"kind": "miss",
			"ability": label
		}
	)
	w.enter_combat(p, target)


## heal.
static func _heal(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var t: Dictionary = target if not target.is_empty() else p
	if t != p and t["kind"] == "mob":
		return
	var rolled := w.rng.range_f(float(eff["min"]), float(eff["max"]))
	var base := (
		(
			rolled
			+ direct_heal_bonus(
				w,
				float(p["heal_power"]),
				float(res.get("scalingCastTime", res["castTime"])),
				ctx["heal_mult"]
			)
		)
		if eff.get("casterMaxHpPct") == null
		else float(_jr(float(p["max_hp"]) * float(eff["casterMaxHpPct"])))
	)
	var cast_mult := float(ctx.get("cast_heal_mult", 1.0))
	if cast_mult != 1.0:
		base = float(maxi(1, _jr(base * cast_mult)))
	var amount := base
	if eff.get("casterMaxHpPct") == null:
		amount = scale_primary(base, primary_heal_mult(p))
	ctx["direct_heal"] = amount
	if eff.get("canCrit") == false:
		w.rng.chance(0.0)
	var healed := RpgCombat.apply_heal(w, p, t, amount, eff.get("canCrit", true) != false)
	RpgClassHooks.after_heal(w, p, t, res, amount, healed)
	RpgShamanKit.deposit(w, p, t, amount, str(res["def"]["id"]))
	if res["def"]["id"] == "healing_wave":
		RpgShamanWar.trigger_ward_cycle(w, p)
	if healed > 0:
		RpgPaladin.note_outcome(ctx, "healing", t, healed)
		RpgPaladinProcs.after_effective(w, p, str(res["def"]["id"]), t, amount)
	if ctx["is_spell"]:
		var echo := RpgAbilityRules.find_kind(p, "power_echo")
		if not echo.is_empty():
			RpgAbilityRules.remove_aura(w, p, echo)
			if not t["dead"] and healed > 0:
				RpgCombat.apply_heal(
					w, p, t, float(maxi(1, _jr(healed * float(echo["value"])))), false
				)


## hot.
static func _hot(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var t: Dictionary = target if not target.is_empty() else p
	var hybrid := false
	for e: Dictionary in res["effects"]:
		hybrid = hybrid or e["type"] == "heal"
	var total := (
		float(_jr(float(t["max_hp"]) * float(eff["pctOfMax"])))
		if eff.get("pctOfMax") != null
		else float(eff["total"])
	)
	var interval := float(eff["interval"])
	var base := maxi(1, _jr(total / (float(eff["duration"]) / interval)))
	var sp := (
		0
		if hybrid
		else periodic_bonus(
			w,
			float(p["heal_power"]),
			float(w.pack["constants"]["healing_sp_scale"]),
			float(eff["duration"]),
			interval,
			ctx["heal_mult"] * (1.0 + float(p["mods"]["global"]["hotHealPct"]))
		)
	)
	var tick := float(base + sp)
	if float(ctx.get("cast_heal_mult", 1.0)) != 1.0:
		tick = float(maxi(1, _jr(tick * float(ctx["cast_heal_mult"]))))
	if eff.get("pctOfMax") == null:
		tick = scale_primary(tick, primary_heal_mult(p))
	var aura := {
		"id": res["id"],
		"kind": "hot",
		"remaining": float(eff["duration"]),
		"duration": float(eff["duration"]),
		"value": tick,
		"tick_interval": interval,
		"tick_timer": interval,
		"source_id": p["id"],
		"school": res["def"]["school"],
	}
	if eff.get("closingHealFromDirect", false) and ctx.has("direct_heal"):
		aura["closing_heal"] = ctx["direct_heal"]
	RpgCombat.apply_aura(w, t, aura)
	RpgDruid.on_hot_planted(w, p, str(res["id"]))


## dot.
static func _dot(
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
	var hybrid := false
	for e: Dictionary in res["effects"]:
		hybrid = hybrid or str(e["type"]) in DOT_COEFF_HYBRID_KINDS
	if eff.get("directPct") != null and int(ctx["last_direct"]) <= 0:
		return
	var combo := int(ctx["spent_combo"])
	var total := (
		float(eff["total"]) + float(eff.get("perCombo", 0.0)) * combo
		if eff.get("directPct") == null
		else float(_jr(float(ctx["last_direct"]) * float(eff["directPct"])))
	)
	if eff.get("perComboTotal") != null:
		total = float(eff.get("baseTotal", 0.0)) + float(eff["perComboTotal"]) * combo
	var interval := float(eff["interval"])
	var apex := RpgDruid.apex_payoff_mult(w, p, str(def["id"]))
	var base := maxi(1, _jr(total / (float(eff["duration"]) / interval) * apex))
	var duration := float(eff["duration"])
	if eff.get("perComboDuration") != null and float(eff["perComboDuration"]) != 0.0:
		duration = float(eff.get("baseDuration", 0.0)) + float(eff["perComboDuration"]) * combo
	var sp := (
		0
		if hybrid
		else periodic_bonus(
			w,
			scaling_power(p, def),
			power_scale(w, def),
			duration,
			interval,
			(
				ctx["dmg_mult"]
				* (1.0 + float(p["mods"]["global"]["dotDmgPct"]))
				* RpgPriest.dirge_sp_mult(p, str(def["id"]))
			)
		)
	)
	var dot_id := str(eff.get("auraId", res["id"]))
	var dot := {
		"id": dot_id,
		"kind": "dot",
		"remaining": duration,
		"duration": duration,
		"value": float(base + sp),
		"tick_interval": interval,
		"tick_timer": interval,
		"source_id": p["id"],
		"school": str(eff.get("school", def["school"])),
	}
	if eff.get("leechPct") != null:
		dot["leech_pct"] = float(eff["leechPct"])
	RpgClassHooks.apply_dot(w, p, target, dot, def)
	if def["id"] == "rip":
		RpgDruid.on_landed_strike(w, p, "rip")
	w.enter_combat(p, target)


## extendOwnedDot.
static func extend_owned_dot(target: Dictionary, source_id: int, eff: Dictionary) -> void:
	for a: Dictionary in target["auras"]:
		if a["kind"] != "dot" or a["id"] != eff["dot"] or a["source_id"] != source_id:
			continue
		var base := float(a.get("base_duration", a["duration"]))
		a["base_duration"] = base
		var cap := base + float(eff["maxBonus"])
		var extended := minf(cap, float(a["remaining"]) + float(eff["seconds"]))
		a["duration"] = maxf(float(a["duration"]), extended)
		a["remaining"] = extended
		return


## absorb (absorbAuraId: a stasis self-buff beside it takes `_absorb`).
static func _absorb(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var t: Dictionary = target if not target.is_empty() else p
	var value := (
		float(eff["amount"])
		+ _jr(float(p["max_hp"]) * float(eff.get("casterMaxHpPct", 0.0)))
		+ maxi(
			0,
			_jr(
				(
					float(p["heal_power"])
					* float(eff.get("spellPowerCoeff", 0.0))
					* ctx["heal_mult"]
					* (1.0 + float(p["mods"]["global"]["absorbPct"]))
				)
			)
		)
	)
	var aura_id := str(res["id"])
	if eff.get("auraId") != null:
		aura_id = str(eff["auraId"])
	else:
		for e: Dictionary in res["def"]["effects"]:
			if e["type"] == "selfBuff" and e["kind"] == "stasis":
				aura_id = str(res["id"]) + "_absorb"
	apply_full(w, t, aura_id, "absorb", float(eff["duration"]), value, p, res["def"])


## selfBuff: a toggle goes off when worn; stasis and travel forms stop casting and
## the auto attack; a form replaces other forms; the exclusive group's other members
## go; Overpower's charge stacks to 2; then the aura, and the sheet recalculates.
static func _self_buff(w: RpgEncounter, p: Dictionary, res: Dictionary, eff: Dictionary) -> void:
	var def: Dictionary = res["def"]
	var kind := str(eff["kind"])
	var is_form := RpgForms.is_form_kind(w, kind)
	var auras: Array = p["auras"]
	if (
		is_form
		or kind in ["defensive_stance", "stealth"]
		or def["id"] == "ghost_wolf"
		or eff.get("healthDrainPctMax") != null
	):
		for a: Dictionary in auras:
			if a["id"] == def["id"]:
				RpgAbilityRules.remove_aura(w, p, a)
				RpgShaman.on_ghost_wolf_exited(w, p, str(def["id"]))
				w.recalc_player()
				return
	if kind == "stasis" or RpgForms.is_travel_kind(kind):
		RpgCast.cancel_cast(w)
		p["auto_attack"] = false
	if is_form:
		for i in range(auras.size() - 1, -1, -1):
			if RpgForms.is_form_kind(w, str(auras[i]["kind"])) and auras[i]["kind"] != kind:
				var gone: Dictionary = auras[i]
				auras.remove_at(i)
				w.log_event(
					{"type": "aura", "target": p["id"], "name": gone["id"], "gained": false}
				)
	var group: Variant = def.get("exclusiveGroup")
	if group != null and not RpgPaladin.is_devotion_ability(str(def["id"])):
		for i in range(auras.size() - 1, -1, -1):
			var other_id := str(auras[i]["id"])
			if other_id == def["id"]:
				continue
			var other: Dictionary = w.pack["abilities"].get(other_id, {}).get("def", {})
			if other.get("exclusiveGroup") == group:
				var gone: Dictionary = auras[i]
				auras.remove_at(i)
				w.log_event(
					{"type": "aura", "target": p["id"], "name": gone["id"], "gained": false}
				)
	if kind == "overpower_charge":
		var existing := RpgAbilityRules.find_kind(p, "overpower_charge")
		if not existing.is_empty():
			existing["stacks"] = mini(2, int(existing.get("stacks", 1)) + 1)
			existing["remaining"] = float(eff["duration"])
			existing["duration"] = float(eff["duration"])
			return
	var aura_id := str(eff["auraId"]) if eff.get("auraId") != null else _self_buff_id(res, eff)
	var lifetime := INF if eff.get("permanent", false) else float(eff["duration"])
	var aura := {
		"id": aura_id,
		"kind": kind,
		"remaining": lifetime,
		"duration": lifetime,
		"permanent": eff.get("permanent", false),
		"value": float(eff["value"]),
		"source_id": p["id"],
		"school": def["school"],
	}
	if eff.get("value2") != null:
		aura["value2"] = float(eff["value2"])
	elif eff.get("healthDrainPctMax") != null:
		aura["value2"] = float(eff["healthDrainPctMax"])
	elif def["id"] == "demon_skin" and float(p["mods"]["global"]["warlockFiendhideMagicDrPct"]) > 0:
		aura["value2"] = float(p["mods"]["global"]["warlockFiendhideMagicDrPct"])
	if eff.get("value3") != null or eff.get("disableBelowHpPct") != null:
		aura["value3"] = float(eff.get("value3", eff.get("disableBelowHpPct")))
	if eff.get("healthDrainPctMax") != null:
		aura["tick_interval"] = 1.0
		aura["tick_timer"] = 1.0
	if kind == "overpower_charge":
		aura["stacks"] = 1
	if eff.get("charges") != null:
		aura["charges"] = int(eff["charges"])
	if eff.get("internalCooldown") != null:
		aura["icd_max"] = float(eff["internalCooldown"])
	if eff.get("empowerAbilities") != null:
		aura["empower_abilities"] = eff["empowerAbilities"]
	RpgCombat.apply_aura(w, p, aura)
	if kind == "stealth":
		RpgRogue.on_stealth_entered(w, p, def)
	w.recalc_player()
	RpgHunter.on_self_buff(w, p, def, eff)


## selfBuffAuraId.
static func _self_buff_id(res: Dictionary, eff: Dictionary) -> String:
	var first := ""
	for e: Dictionary in res["def"]["effects"]:
		if e["type"] == "selfBuff":
			first = str(e["kind"])
			break
	return str(res["id"]) if eff["kind"] == first else "%s_%s" % [res["id"], eff["kind"]]


## buffTarget (buffTargetAuraId). A party buff lands on the target and the caster;
## the street has no party.
static func _buff_target(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var index: int = ctx["buff_index"]
	ctx["buff_index"] = index + 1
	var aura_id := str(res["id"]) if index == 0 else "%s_%s_%d" % [res["id"], eff["kind"], index]
	var t: Dictionary = target if not target.is_empty() else p
	var lifetime := INF if eff.get("permanent", false) else float(eff["duration"])
	var aura := {
		"id": aura_id,
		"kind": str(eff["kind"]),
		"remaining": lifetime,
		"duration": lifetime,
		"permanent": lifetime == INF,
		"value": float(eff["value"]),
		"source_id": p["id"],
		"school": res["def"]["school"],
	}
	if eff.get("value2") != null:
		aura["value2"] = float(eff["value2"])
	if eff["kind"] == "buff_mana_grace":
		aura["tick_interval"] = 5.0
		aura["tick_timer"] = 5.0
	RpgCombat.apply_aura(w, t, aura)
	if eff.get("party", false) and t != p:
		RpgCombat.apply_aura(w, p, aura.duplicate())


## gainResource: a warrior's rage gain is scaled by warriorAbilityRageMult.
static func _gain_resource(w: RpgEncounter, p: Dictionary, eff: Dictionary) -> void:
	var amount := float(eff["amount"]) * RpgWarrior.ability_rage_mult(w, p)
	p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + amount)


## stun, incapacitate (breaks on damage), root, slow.
static func _control(
	w: RpgEncounter, p: Dictionary, target: Dictionary, res: Dictionary, eff: Dictionary
) -> void:
	if target.is_empty() or target["dead"]:
		return
	var def: Dictionary = res["def"]
	match str(eff["type"]):
		"stun":
			apply_simple(
				w, target, def["id"] + "_stun", "stun", float(eff["duration"]), 0.0, p, def
			)
		"incapacitate":
			RpgEffectsArea.incapacitate(w, p, target, res, eff)
		"root":
			apply_simple(
				w, target, def["id"] + "_root", "root", float(eff["duration"]), 0.0, p, def
			)
		"slow":
			apply_simple(
				w,
				target,
				def["id"] + "_slow",
				"slow",
				float(eff["duration"]),
				float(eff["mult"]),
				p,
				def
			)
	if not def.get("noCombatEntry", false):
		w.enter_combat(p, target)


static func apply_simple(
	w: RpgEncounter,
	t: Dictionary,
	id: String,
	kind: String,
	duration: float,
	value: float,
	p: Dictionary,
	def: Dictionary,
	breaks := false
) -> void:
	var aura := {
		"id": id,
		"kind": kind,
		"remaining": duration,
		"duration": duration,
		"value": value,
		"source_id": p["id"],
		"school": def["school"],
	}
	if breaks:
		aura["breaks_on_damage"] = true
	RpgCombat.apply_aura(w, t, aura)


static func apply_full(
	w: RpgEncounter,
	t: Dictionary,
	id: String,
	kind: String,
	lifetime: float,
	value: float,
	p: Dictionary,
	def: Dictionary
) -> void:
	(
		RpgCombat
		. apply_aura(
			w,
			t,
			{
				"id": id,
				"kind": kind,
				"remaining": lifetime,
				"duration": lifetime,
				"permanent": lifetime == INF,
				"value": value,
				"source_id": p["id"],
				"school": def["school"],
			}
		)
	)
