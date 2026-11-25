class_name RpgPaladinProcs
extends RefCounted
## The paladin's procs and riders: Solar Reprisal (combat/paladin_solar_reprisal.ts),
## Dawn's Wrath (paladin_dawns_wrath.ts), Dawn Rhythm (paladin_dawn_rhythm.ts),
## Radiant Resonance (paladin_radiant_resonance.ts, empower_next.ts), Debt of Light
## (paladin_debt_of_light.ts, damage.ts), the Protection Consecration cut
## (paladin_consecration.ts), Requital and the talent riders (paladin_talents.ts).
## The set-bonus variants (Oathpyre, Zealfire, Dawnforged, Lightbrand) are gear the
## street's items never grant, so their base values apply.

const SOLAR_REPRISAL_KIND := "paladin_solar_reprisal"
const SOLAR_REPRISAL_DURATION := 8.0
const SOLAR_REPRISAL_BLOCK_CHANCE := 0.25
const SOLAR_REPRISAL_VOWKEEPER_CHANCE := 0.2
const SOLAR_REPRISAL_SUNWARD_DAMAGE_MULT := 1.2
const SOLAR_REPRISAL_CONSUMERS: Array[String] = ["sunward_disc", "hammer_of_grace", "holy_light"]
const DAWNS_WRATH_KIND := "paladin_dawns_wrath"
const DAWNS_WRATH_DURATION := 8.0
const DAWNS_WRATH_PROC_CHANCE := 0.15
const DAWNS_WRATH_DAMAGE_MULT := 1.2
const DAWN_RHYTHM_CUT := 2.0
const RADIANT_RESONANCE_KIND := "paladin_radiant_resonance"
const RADIANT_RESONANCE_DURATION := 10.0
const RADIANT_RESONANCE_DAWN_CAST_TIME := 1.5
const RADIANT_RESONANCE_DAWN_COST_MULT := 0.5
const DEBT_OF_LIGHT_KIND := "paladin_debt_of_light"
const PROTECTION_CONSECRATION_DR := 0.1


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _aura(
	id: String, kind: String, duration: float, value: float, p: Dictionary
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": duration,
		"duration": duration,
		"value": value,
		"source_id": p["id"],
		"school": "holy",
	}


static func _spec(p: Dictionary, spec: String) -> bool:
	return p.get("kind") == "player" and p.get("class_id") == "paladin" and p.get("spec_id") == spec


# -- Solar Reprisal ---------------------------------------------------------------


## tryGrantSolarReprisal: a protection paladin's block (25%) or Vowkeeper Strike (20%).
static func try_solar_reprisal(w: RpgEncounter, p: Dictionary, source: String) -> bool:
	if not _spec(p, "protection"):
		return false
	var chance := (
		SOLAR_REPRISAL_BLOCK_CHANCE if source == "block" else SOLAR_REPRISAL_VOWKEEPER_CHANCE
	)
	if not w.rng.chance(chance):
		return false
	RpgCombat.apply_aura(
		w,
		p,
		_aura(
			"solar_reprisal",
			SOLAR_REPRISAL_KIND,
			SOLAR_REPRISAL_DURATION,
			SOLAR_REPRISAL_SUNWARD_DAMAGE_MULT - 1.0,
			p
		)
	)
	return true


## solarReprisalBypassesCooldown / dawnsWrathHammerActive: the cast gate lets these
## through their running cooldowns.
static func bypasses_cooldown(p: Dictionary, ability_id: String) -> bool:
	if ability_id in ["sunward_disc", "hammer_of_grace"]:
		return RpgAbilityRules.has_kind(p, SOLAR_REPRISAL_KIND)
	if ability_id == "hammer_of_wrath":
		return RpgAbilityRules.has_kind(p, DAWNS_WRATH_KIND)
	return false


## solarReprisalMakesAbilityFree.
static func makes_free(p: Dictionary, ability_id: String) -> bool:
	return ability_id == "sunward_disc" and RpgAbilityRules.has_kind(p, SOLAR_REPRISAL_KIND)


## applySolarReprisalOverride then applyDawnsWrathOverride, after every cast gate.
static func cast_overrides(w: RpgEncounter, p: Dictionary, res: Dictionary) -> Dictionary:
	var id := str(res["def"]["id"])
	if id in SOLAR_REPRISAL_CONSUMERS:
		var proc := RpgAbilityRules.find_kind(p, SOLAR_REPRISAL_KIND)
		if not proc.is_empty():
			RpgAbilityRules.remove_aura(w, p, proc)
			res = res.duplicate()
			var effects: Array = []
			for src: Dictionary in res["effects"]:
				var e := src.duplicate(true)
				if id == "sunward_disc" and e["type"] in ["directDamage", "chainDamage"]:
					e["damageMult"] = (
						float(e.get("damageMult", 1.0)) * SOLAR_REPRISAL_SUNWARD_DAMAGE_MULT
					)
				if id == "hammer_of_grace" and e["type"] == "directDamage":
					e["selfHealDamageFrac"] = 1.0
				effects.append(e)
			res["effects"] = effects
			if id == "sunward_disc":
				res["cost"] = 0.0
			if id != "holy_light":
				res["cooldown"] = 0.0
			else:
				res["castTime"] = 0.0
	if id == "hammer_of_wrath":
		var wrath := RpgAbilityRules.find_kind(p, DAWNS_WRATH_KIND)
		if not wrath.is_empty():
			RpgAbilityRules.remove_aura(w, p, wrath)
			res = res.duplicate()
			res["cooldown"] = 0.0
			var effects: Array = []
			for src: Dictionary in res["effects"]:
				var e := src.duplicate(true)
				if e["type"] == "directDamage":
					e["damageMult"] = (
						float(e.get("damageMult", 1.0)) * (1.0 + float(wrath["value"]))
					)
				effects.append(e)
			res["effects"] = effects
	return res


## tryGrantDawnsWrath: a retribution paladin's auto attack or Final Edict, 15%.
static func try_dawns_wrath(w: RpgEncounter, p: Dictionary) -> bool:
	if not _spec(p, "retribution") or not w.rng.chance(DAWNS_WRATH_PROC_CHANCE):
		return false
	RpgCombat.apply_aura(
		w,
		p,
		_aura(
			"dawns_wrath", DAWNS_WRATH_KIND, DAWNS_WRATH_DURATION, DAWNS_WRATH_DAMAGE_MULT - 1.0, p
		)
	)
	return true


## triggerPaladinDawnRhythm: Final Edict and Dawnfall cut each other's cooldown 2 s.
static func dawn_rhythm(p: Dictionary, ability_id: String) -> void:
	var paired := {"final_edict": "dawnfall", "dawnfall": "final_edict"}
	if not paired.has(ability_id) or not p["cooldowns"].has(paired[ability_id]):
		return
	var left := float(p["cooldowns"][paired[ability_id]])
	if left <= 0.0:
		return
	var next := left - minf(left, DAWN_RHYTHM_CUT)
	if next <= 0.0:
		p["cooldowns"].erase(paired[ability_id])
	else:
		p["cooldowns"][paired[ability_id]] = next


## weaponStrike's paladin tails after a landed strike.
static func after_weapon_strike(w: RpgEncounter, p: Dictionary, ability_id: String) -> void:
	if ability_id == "final_edict":
		dawn_rhythm(p, ability_id)
		try_dawns_wrath(w, p)
	elif ability_id == "vowkeeper_strike":
		try_solar_reprisal(w, p, "vowkeeper")


# -- Radiant Resonance ------------------------------------------------------------


## grantRadiantResonance: a Radiant Chorus that healed two or more.
static func grant_resonance(w: RpgEncounter, p: Dictionary, effective_targets: int) -> void:
	if effective_targets < 2:
		return
	RpgCombat.apply_aura(
		w,
		p,
		_aura(
			"radiant_resonance",
			RADIANT_RESONANCE_KIND,
			RADIANT_RESONANCE_DURATION,
			RADIANT_RESONANCE_DAWN_COST_MULT,
			p
		)
	)


## nextCastCheapMultiplier / consumeNextCastCheap's Radiant Resonance arm: Dawn's
## Embrace costs half while it is worn or was reserved at cast start. -1 = no part.
static func resonance_cheap(
	w: RpgEncounter, p: Dictionary, ability_id: String, consume: bool
) -> float:
	if ability_id != "dawns_embrace":
		return -1.0
	var reserved: bool = p.get("cast_radiant_resonance", false)
	if not reserved and not RpgAbilityRules.has_kind(p, RADIANT_RESONANCE_KIND):
		return -1.0
	if consume:
		p.erase("cast_radiant_resonance")
		RpgAbilityRules.consume_aura_kind(w, p, RADIANT_RESONANCE_KIND, ability_id)
	return RADIANT_RESONANCE_DAWN_COST_MULT


## consumeNextCastInstantFor's arm: Radiant Resonance makes Holy Light instant.
static func consume_resonance_instant(
	w: RpgEncounter, p: Dictionary, ability_id: String
) -> Dictionary:
	if ability_id != "holy_light":
		return {}
	return RpgAbilityRules.consume_aura_kind(w, p, RADIANT_RESONANCE_KIND, ability_id)


## radiantResonanceCastTime: an empowered Dawn's Embrace casts in 1.5 s at most.
static func resonance_cast_time(p: Dictionary, ability_id: String, cast_time: float) -> float:
	if ability_id != "dawns_embrace":
		return cast_time
	if (
		not RpgAbilityRules.has_kind(p, RADIANT_RESONANCE_KIND)
		and not p.get("cast_radiant_resonance", false)
	):
		return cast_time
	return minf(cast_time, RADIANT_RESONANCE_DAWN_CAST_TIME)


## reserveRadiantResonance at a cast bar's start; cleared when the bar stops.
static func reserve_resonance(p: Dictionary, ability_id: String, reserve: bool) -> void:
	if not reserve:
		p.erase("cast_radiant_resonance")
	elif ability_id == "dawns_embrace" and RpgAbilityRules.has_kind(p, RADIANT_RESONANCE_KIND):
		p["cast_radiant_resonance"] = true


# -- defence ----------------------------------------------------------------------


## Debt of Light (damage.ts): the armed answer soaks up to its value of a hit from
## another attacker before the shields, grants Devotion and owes the attacker the
## soaked amount back as Holy damage. Returns the soak (0 = untouched).
static func debt_of_light(
	w: RpgEncounter, target: Dictionary, source: Dictionary, amount: int
) -> int:
	if amount <= 0 or source.is_empty() or source["id"] == target["id"]:
		return 0
	var armed := RpgAbilityRules.find_kind(target, DEBT_OF_LIGHT_KIND)
	if armed.is_empty() or float(armed["value"]) <= 0.0:
		return 0
	var soaked := mini(int(armed["value"]), amount)
	target["auras"].erase(armed)
	w.log_event({"type": "aura", "target": target["id"], "name": armed["id"], "gained": false})
	if target["kind"] == "player":
		RpgPaladin.grant_ability_devotion(target, RpgPaladin.DEBT_OF_LIGHT_DEVOTION)
	if soaked > 0 and not source["dead"]:
		target["debt_return"] = {"attacker": source, "amount": soaked}
	return soaked


## The Debt of Light return, after the incoming hit resolved.
static func pay_debt(w: RpgEncounter, target: Dictionary) -> void:
	var debt: Variant = target.get("debt_return")
	if not debt is Dictionary:
		return
	target.erase("debt_return")
	var attacker: Dictionary = debt["attacker"]
	if not attacker["dead"] and int(debt["amount"]) > 0:
		RpgCombat.deal_damage(
			w, target, attacker, int(debt["amount"]), false, "holy", "Debt of Light", "hit", true
		)


## protectionConsecrationDamageReduction: the paladin's own protection zone around them.
static func consecration_dr(w: RpgEncounter, target: Dictionary) -> float:
	if target.get("kind") != "player" or target.get("class_id") != "paladin":
		return 0.0
	var reduction := 0.0
	for area: Dictionary in w.ground:
		var value := float(area.get("protection_dr", 0.0))
		if value <= reduction or area["source_id"] != target["id"]:
			continue
		if float(area["remaining"]) <= 0.0:
			continue
		if absf(float(target["x"]) - float(area["x"])) <= float(area["radius"]):
			reduction = value
	return reduction


## masteredPaladinAuraValue: Aura Mastery triples Devotion Ward and Requital.
static func mastered_value(u: Dictionary, aura_id: String, value: float) -> float:
	if aura_id != "devotion_ward" and aura_id != "retribution_aura":
		return value
	for a: Dictionary in u["auras"]:
		if a["id"] == "aura_mastery":
			return value * 3.0
	return value


## applyRequitalAutoAttack: the paladin's own swing carries Requital's holy damage.
static func requital(w: RpgEncounter, attacker: Dictionary, target: Dictionary) -> void:
	if attacker["dead"] or target["dead"]:
		return
	var dmg := 0.0
	for a: Dictionary in attacker["auras"]:
		if a["id"] == "retribution_aura" and a["kind"] == "thorns":
			dmg += mastered_value(attacker, str(a["id"]), float(a["value"]))
	if dmg <= 0.0:
		return
	# catFlatSwingAdderMult is 1 outside Cat Form, which a paladin never wears.
	dmg = float(maxi(1, _jr(dmg)))
	RpgCombat.deal_damage(
		w, attacker, target, int(dmg), false, "holy", "Requital Aura", "hit", true
	)


# -- talent riders ----------------------------------------------------------------


## applyRecurringGraceShield: Hammer of Grace's overheal banks a shield (10% max hp).
static func recurring_grace(
	w: RpgEncounter, p: Dictionary, ability_id: String, overheal: int
) -> void:
	if ability_id != "hammer_of_grace" or overheal <= 0:
		return
	if float(p["mods"]["global"].get("paladinRecurringGrace", 0.0)) <= 0.0:
		return
	var cap := maxi(1, _jr(int(p["max_hp"]) * 0.1))
	var existing := 0.0
	for a: Dictionary in p["auras"]:
		if a["id"] == "recurring_grace_absorb" and a["kind"] == "absorb":
			existing = float(a["value"])
	var aura := _aura("recurring_grace_absorb", "absorb", 10.0, minf(cap, existing + overheal), p)
	RpgCombat.apply_aura(w, p, aura)


## The hit and heal riders: Radiant Stride (Hammer of Grace that landed) and Steady
## Hands (Lay on Hands that healed leaves a hot of its share over 6 s).
static func after_effective(
	w: RpgEncounter, p: Dictionary, ability_id: String, target: Dictionary, heal_amount: float
) -> void:
	var g: Dictionary = p["mods"]["global"]
	if ability_id == "hammer_of_grace" and float(g.get("paladinRadiantStride", 0.0)) > 0.0:
		RpgCombat.apply_aura(w, p, _aura("radiant_stride_speed", "buff_speed", 4.0, 1.3, p))
	var steady := float(g.get("paladinSteadyHandsHotPct", 0.0))
	if ability_id == "lay_on_hands" and steady > 0.0 and heal_amount > 0.0:
		var total := maxi(1, _jr(heal_amount * steady))
		var hot := _aura("steady_hands_hot", "hot", 6.0, float(maxi(1, _jr(total / 3.0))), p)
		hot["tick_interval"] = 2.0
		hot["tick_timer"] = 2.0
		RpgCombat.apply_aura(w, target, hot)


## unleashPerpetualSun: 150 holy to every hostile within 10, a 150 heal (primary
## healing scaled) to the caster, and doubled devotion for 5 s.
static func unleash_perpetual_sun(w: RpgEncounter, p: Dictionary) -> void:
	var enemies := RpgAbilityRules.hostiles_in_radius(w, p, float(p["x"]), 10.0)
	enemies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	for m: Dictionary in enemies:
		RpgCombat.deal_damage(w, p, m, 150, false, "holy", "Perpetual Sun", "hit", true)
	var heal := RpgEffects.scale_primary(150.0, RpgEffects.primary_heal_mult(p))
	if not p["dead"]:
		RpgCombat.apply_heal(w, p, p, heal, false)
	RpgCombat.apply_aura(w, p, _aura("perpetual_sun_generation", "internal_cd", 5.0, 2.0, p))
