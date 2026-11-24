class_name RpgEffects
extends RefCounted
## The effect handlers (src/sim/combat/effect_dispatch.ts runEffects), each the
## general path of its arm. The runtime pack names which abilities may reach them
## (an ability special-cased anywhere in the reference's combat code is BLOCKED and
## never gets here). `res` is a known-ability entry (RpgTalents.known) and `p` the
## caster unit; `target` may be {}.

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


static func _power_scale(w: RpgEncounter, def: Dictionary) -> float:
	if def.get("scalesWith") == "ranged":
		return float(w.pack["constants"]["ranged_spell_ap_scale"])
	if def.get("school") == "physical":
		return float(w.pack["constants"]["melee_spell_ap_scale"])
	return 1.0


static func _clamp_cast(w: RpgEncounter, seconds: float) -> float:
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
		else _clamp_cast(w, cast_time) / float(c["spell_coeff_divisor"])
	)
	if aoe:
		coeff *= float(c["spell_aoe_coeff_mult"])
	return _jr(power * coeff * _power_scale(w, def) * mult)


## directHealBonus.
static func direct_heal_bonus(
	w: RpgEncounter, heal_power: float, cast_time: float, mult: float
) -> int:
	var c: Dictionary = w.pack["constants"]
	var coeff := _clamp_cast(w, cast_time) / float(c["spell_coeff_divisor"])
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


## primaryHealingMultiplier and scalePrimaryHealing (spec_output_tuning.ts).
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


static func _scale_primary(amount: float, mult: float) -> float:
	return amount if mult == 1.0 else float(_jr(amount * mult))


## runEffects for one cast.
static func run(w: RpgEncounter, p: Dictionary, target: Dictionary, res: Dictionary) -> void:
	var def: Dictionary = res["def"]
	var is_spell: bool = def["school"] != "physical"
	var hm := RpgTalents.hit_mult(w.pack, def, p["mods"])
	var ctx := {
		"last_direct": 0,
		"buff_index": 0,
		"dmg_mult": float(hm["dmg"]),
		"heal_mult": float(hm["heal"]),
		"is_spell": is_spell,
	}
	for eff: Dictionary in res["effects"]:
		var stop := false
		match str(eff["type"]):
			"weaponStrike":
				_weapon_strike(w, p, target, res, eff)
			"directDamage":
				stop = _direct_damage(w, p, target, res, eff, ctx)
			"aoeDamage":
				_aoe_damage(w, p, target, res, eff, ctx)
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
			_:
				push_error("RpgEffects: no handler for " + str(eff["type"]))
		if stop:
			break


## weaponStrike (general path): one meleeSwing with the effect's bonus and weapon
## multiplier, normalized when asked, Unblockable when asked.
static func _weapon_strike(
	w: RpgEncounter, p: Dictionary, target: Dictionary, res: Dictionary, eff: Dictionary
) -> void:
	if target.is_empty():
		return
	var ability_id := str(res["id"])
	var crit_bonus := float(p["mods"]["abilities"].get(ability_id, {}).get("critPct", 0.0))
	(
		w
		. player_melee(
			target,
			{
				"weapon_mult": float(eff.get("weaponMult", 1.0)),
				"bonus": float(eff["bonus"]),
				"normalized": bool(eff.get("normalized", false)),
				"cannot_be_dodged": bool(eff.get("cannotBeDodged", false)),
				"crit_bonus": crit_bonus,
			},
			str(res["def"]["name"])
		)
	)


## directDamage (general path). Returns true when a physical miss ends the cast's
## remaining effects (`break effects`).
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
	var is_spell: bool = ctx["is_spell"]
	if not is_spell:
		var miss := RpgHitTable.swing_miss_chance(
			int(p["level"]), int(target["level"]), false, float(p.get("hit_bonus", 0.0))
		)
		if miss > 0.0 and w.rng.chance(miss):
			w.log_event(
				{
					"type": "damage",
					"source": p["id"],
					"target": target["id"],
					"amount": 0,
					"kind": "miss",
					"ability": def["name"]
				}
			)
			w.enter_combat(p, target)
			return true
	var crit_pct := float(p["mods"]["abilities"].get(res["id"], {}).get("critPct", 0.0))
	var rooted := RpgCombat.is_rooted(target) or RpgCombat._has_kind(target, "slow")
	var crit_chance := float(p["crit"])
	if is_spell:
		crit_chance = RpgCombat.spell_crit(p)
		if rooted:
			crit_chance += float(p["mods"]["global"]["critVsRooted"])
	crit_chance += crit_pct
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
	var crit := w.rng.chance(crit_chance)
	if crit:
		dmg *= (
			(1.5 + float(p["crit_dmg_spell"])) if is_spell else (2.0 + float(p["crit_dmg_phys"]))
		)
	if is_spell:
		dmg *= spell_damage_mult(p)
	else:
		dmg *= 1.0 - RpgHitTable.armor_reduction(float(target["armor"]), int(p["level"]))
	var final := _jr(dmg)
	ctx["last_direct"] = final
	RpgCombat.deal_damage(w, p, target, final, crit, str(def["school"]), str(def["name"]))
	return false


## aoeDamage: every hostile within the radius (the trial holds one), one crit draw
## for the cast when it can crit, per-target roll.
static func _aoe_damage(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var def: Dictionary = res["def"]
	var center: float = (
		float(target["x"])
		if eff.get("centerOnTarget", false) and not target.is_empty()
		else float(p["x"])
	)
	var targets: Array = []
	var m := w.mob
	if not m["dead"] and absf(float(m["x"]) - center) <= float(eff["radius"]):
		targets.append(m)  # frontal: the trial's mob is always in front of the player
	var sp_bonus := direct_hit_bonus(
		w, scaling_power(p, def), def, float(res["castTime"]), true, ctx["dmg_mult"]
	)
	var is_spell: bool = ctx["is_spell"]
	var crit: bool = (
		bool(eff.get("canCrit", false))
		and not targets.is_empty()
		and w.rng.chance(RpgCombat.spell_crit(p))
	)
	for t: Dictionary in targets:
		var dmg := w.rng.range_f(float(eff["min"]), float(eff["max"])) + sp_bonus
		if is_spell:
			dmg *= spell_damage_mult(p)
		if crit:
			dmg *= (
				(1.5 + float(p["crit_dmg_spell"]))
				if is_spell
				else (2.0 + float(p["crit_dmg_phys"]))
			)
		if not is_spell:
			dmg *= 1.0 - RpgHitTable.armor_reduction(float(t["armor"]), int(p["level"]))
		RpgCombat.deal_damage(w, p, t, _jr(dmg), crit, str(def["school"]), str(def["name"]))
		if eff.get("stunSec") != null and not t["dead"]:
			_apply(w, t, res["id"] + "_stun", "stun", float(eff["stunSec"]), 0.0, p, def)


## heal (general path).
static func _heal(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	res: Dictionary,
	eff: Dictionary,
	ctx: Dictionary
) -> void:
	var t: Dictionary = target if not target.is_empty() else p
	if t["kind"] != "player":
		return
	var rolled := w.rng.range_f(float(eff["min"]), float(eff["max"]))
	var base := (
		(
			rolled
			+ direct_heal_bonus(w, float(p["heal_power"]), float(res["castTime"]), ctx["heal_mult"])
		)
		if eff.get("casterMaxHpPct") == null
		else float(_jr(float(p["max_hp"]) * float(eff["casterMaxHpPct"])))
	)
	var amount := base
	if eff.get("casterMaxHpPct") == null:
		amount = _scale_primary(base, primary_heal_mult(p))
	if eff.get("canCrit") == false:
		w.rng.chance(0.0)
	RpgCombat.apply_heal(w, p, t, amount, eff.get("canCrit", true) != false)


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
	if eff.get("pctOfMax") == null:
		tick = _scale_primary(tick, primary_heal_mult(p))
	(
		RpgCombat
		. apply_aura(
			w,
			t,
			{
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
		)
	)


## dot (general path: no combo, no direct-percent, no leech).
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
	var total := (
		float(eff["total"])
		if eff.get("directPct") == null
		else float(_jr(float(ctx["last_direct"]) * float(eff["directPct"])))
	)
	var interval := float(eff["interval"])
	var duration := float(eff["duration"])
	var base := maxi(1, _jr(total / (duration / interval)))
	var sp := (
		0
		if hybrid
		else periodic_bonus(
			w,
			scaling_power(p, def),
			_power_scale(w, def),
			duration,
			interval,
			ctx["dmg_mult"] * (1.0 + float(p["mods"]["global"]["dotDmgPct"]))
		)
	)
	var dot_id := str(eff.get("auraId", res["id"]))
	(
		RpgCombat
		. apply_aura(
			w,
			target,
			{
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
		)
	)
	w.enter_combat(p, target)


## absorb.
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
	var aura_id := str(eff.get("auraId", res["id"]))
	_apply_aura_full(w, t, aura_id, "absorb", float(eff["duration"]), value, p, res["def"])


## selfBuff (general path): a form toggles off and replaces other forms; the
## exclusive group's other members go; then the aura.
static func _self_buff(w: RpgEncounter, p: Dictionary, res: Dictionary, eff: Dictionary) -> void:
	var def: Dictionary = res["def"]
	var kind := str(eff["kind"])
	var is_form: bool = kind in w.pack["constants"]["form_aura_kinds"]
	var auras: Array = p["auras"]
	if is_form or kind in ["defensive_stance", "stealth"]:
		for i in auras.size():
			if auras[i]["id"] == res["id"]:
				auras.remove_at(i)
				w.log_event({"type": "aura", "target": p["id"], "name": res["id"], "gained": false})
				w.recalc_player()
				return
	if is_form:
		for i in range(auras.size() - 1, -1, -1):
			if (
				str(auras[i]["kind"]) in w.pack["constants"]["form_aura_kinds"]
				and auras[i]["kind"] != kind
			):
				auras.remove_at(i)
	var group: Variant = def.get("exclusiveGroup")
	if group != null:
		for i in range(auras.size() - 1, -1, -1):
			var other_id := str(auras[i]["id"])
			if other_id == res["id"]:
				continue
			var other: Dictionary = w.pack["abilities"].get(other_id, {}).get("def", {})
			if other.get("exclusiveGroup") == group:
				auras.remove_at(i)
	var aura_id := str(eff["auraId"]) if eff.get("auraId") != null else _self_buff_id(res, eff)
	var lifetime := INF if eff.get("permanent", false) else float(eff["duration"])
	(
		RpgCombat
		. apply_aura(
			w,
			p,
			{
				"id": aura_id,
				"kind": kind,
				"remaining": lifetime,
				"duration": lifetime,
				"permanent": eff.get("permanent", false),
				"value": float(eff["value"]),
				"source_id": p["id"],
				"school": def["school"],
			}
		)
	)
	w.recalc_player()


## selfBuffAuraId.
static func _self_buff_id(res: Dictionary, eff: Dictionary) -> String:
	var first := ""
	for e: Dictionary in res["def"]["effects"]:
		if e["type"] == "selfBuff":
			first = str(e["kind"])
			break
	return str(res["id"]) if eff["kind"] == first else "%s_%s" % [res["id"], eff["kind"]]


## buffTarget (no party: the trial has none). buffTargetAuraId.
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
	_apply_aura_full(w, t, aura_id, str(eff["kind"]), lifetime, float(eff["value"]), p, res["def"])


## gainResource: a warrior's rage gain is scaled by warriorAbilityRageMult.
static func _gain_resource(w: RpgEncounter, p: Dictionary, eff: Dictionary) -> void:
	var amount := float(eff["amount"])
	if p["class_id"] == "warrior" and p["resource_type"] == "rage":
		amount *= (1.0 + float(p["mods"]["global"]["abilityRagePct"])) * w.rage_aura_mult(p)
	p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + amount)


## stun, incapacitate (breaks on damage), root, slow. A player's control on a mob
## takes no diminishing returns (stun_dr.ts applies them player against player).
static func _control(
	w: RpgEncounter, p: Dictionary, target: Dictionary, res: Dictionary, eff: Dictionary
) -> void:
	if target.is_empty() or target["dead"]:
		return
	var def: Dictionary = res["def"]
	match str(eff["type"]):
		"stun":
			_apply(w, target, res["id"] + "_stun", "stun", float(eff["duration"]), 0.0, p, def)
		"incapacitate":
			_apply(
				w,
				target,
				res["id"] + "_incap",
				"incapacitate",
				float(eff["duration"]),
				0.0,
				p,
				def,
				true
			)
		"root":
			_apply(w, target, res["id"] + "_root", "root", float(eff["duration"]), 0.0, p, def)
		"slow":
			_apply(
				w,
				target,
				res["id"] + "_slow",
				"slow",
				float(eff["duration"]),
				float(eff["mult"]),
				p,
				def
			)
	if not def.get("noCombatEntry", false):
		w.enter_combat(p, target)


static func _apply(
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


static func _apply_aura_full(
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
