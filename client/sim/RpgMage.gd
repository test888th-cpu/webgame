class_name RpgMage
extends RefCounted
## The mage's engines (src/sim/combat/fire_mage.ts, frost_mage.ts, frozen_orb.ts,
## chronomancy.ts, glacial_front.ts, ring_of_frost.ts, greater_invisibility.ts).

## fire_mage.ts PERSONAL_BARRIER_IDS.
const PERSONAL_BARRIER_IDS: Array[String] = ["ice_barrier", "blazing_barrier", "temporal_barrier"]
## fire_mage.ts.
const IGNITE_DURATION := 6.0
const IGNITE_INTERVAL := 2.0
const SCORCH_EXECUTE_HP := 0.3
const HOT_STREAK_BUILDERS: Array[String] = [
	"fireball", "fire_blast", "scorch", "pyroblast", "flamestrike", "dragons_breath"
]
const HOT_STREAK_SPENDERS: Array[String] = ["pyroblast", "flamestrike"]
const HEATING_UP_WINDOW := 10.0
const HOT_STREAK_DURATION := 12.0
const COMBUSTION_CDR_PER_CRIT := 1.0
const CAUTERIZE_ICD := 300.0
const CAUTERIZE_HEAL_FRAC := 0.25
const CAUTERIZE_BURN_PER_SEC := 0.05
const CAUTERIZE_BURN_DURATION := 6.0
const CAUTERIZE_FIRE_DMG_BONUS := 0.12
## frost_mage.ts.
const FINGERS_OF_FROST_CHANCE := 0.15
const FINGERS_OF_FROST_MAX_STACKS := 2
const FINGERS_OF_FROST_DURATION := 15.0
const BRAIN_FREEZE_CHANCE := 0.2
const BRAIN_FREEZE_DURATION := 15.0
const WINTERS_CHILL_CHARGES := 2
const WINTERS_CHILL_DURATION := 5.0
const SHATTER_CRIT_BONUS := 0.5
const ICE_LANCE_FROZEN_MULT := 3.0
const WINTERS_CHILL_SPENDERS: Array[String] = ["ice_lance"]
const BLIZZARD_ORB_CDR_PER_ENEMY := 0.5
const BLIZZARD_ORB_CDR_CAP := 3.0
const ICICLE_MAX := 5
const ICICLE_DURATION := 30.0
## casting_lifecycle.ts Overflowing Power.
const MAGE_DEFENSIVE_COOLDOWNS: Array[String] = [
	"blink", "ice_barrier", "blazing_barrier", "temporal_barrier", "greater_invisibility"
]
const OVERFLOW_CAP_SECONDS := 10.0
const OVERFLOW_CAP_WINDOW := 30.0


## frostMageChannelPulse: each enemy a Blizzard pulse strikes takes 0.5 s off Frozen
## Orb's cooldown, up to 3 s per Blizzard.
static func frost_channel_pulse(w: RpgEncounter, p: Dictionary, id: String, struck: int) -> void:
	if id != "blizzard" or struck <= 0:
		return
	var spent := float(p.get("blizzard_orb_cdr", 0.0))
	var refund := minf(struck * BLIZZARD_ORB_CDR_PER_ENEMY, BLIZZARD_ORB_CDR_CAP - spent)
	if refund <= 0.0:
		return
	p["blizzard_orb_cdr"] = spent + refund
	if not p["cooldowns"].has("frozen_orb"):
		return
	var cur := float(p["cooldowns"]["frozen_orb"])
	if cur <= refund:
		p["cooldowns"].erase("frozen_orb")
	else:
		p["cooldowns"]["frozen_orb"] = cur - refund
	w.log_event({"type": "cdr", "ability": "frozen_orb", "amount": refund})


## aetherDartsBoltBonus (arcane_missiles only).
static func aether_darts_bonus(_w: RpgEncounter, _p: Dictionary, _def: Dictionary) -> float:
	return 0.0


## PERFECT_MOMENT_DARTS_DAMAGE_MULT while Perfect Moment holds (arcane_missiles only).
static func darts_damage_mult(_p: Dictionary, _def: Dictionary) -> float:
	return 1.0


## noteSpellHit (spell_combat.ts): the fire mage's Hot Streak reads every resolved
## spell hit (the frost item-set feed needs set items, which this game has none of).
static func note_spell_hit(w: RpgEncounter, p: Dictionary, crit: bool, id: String) -> void:
	if not id in HOT_STREAK_BUILDERS or not _fire(p):
		return
	var heating := {}
	for a: Dictionary in p["auras"]:
		if a["id"] == "heating_up":
			heating = a
	if not crit:
		if not heating.is_empty():
			RpgAbilityRules.remove_aura(w, p, heating)
		return
	if not RpgAbilityRules.has_kind(p, "combustion") and p["cooldowns"].has("combustion"):
		var cd := float(p["cooldowns"]["combustion"])
		if cd > 0.0:
			p["cooldowns"]["combustion"] = maxf(0.0, cd - COMBUSTION_CDR_PER_CRIT)
	if heating.is_empty():
		RpgCombat.apply_aura(w, p, _aura("heating_up", "internal_cd", HEATING_UP_WINDOW, p, "fire"))
		return
	RpgAbilityRules.remove_aura(w, p, heating)
	var free := _aura("hot_streak", "next_cast_free", HOT_STREAK_DURATION, p, "fire")
	free["empower_abilities"] = HOT_STREAK_SPENDERS.duplicate()
	RpgCombat.apply_aura(w, p, free)
	var instant := _aura("hot_streak_instant", "next_cast_instant", HOT_STREAK_DURATION, p, "fire")
	instant["empower_abilities"] = HOT_STREAK_SPENDERS.duplicate()
	RpgCombat.apply_aura(w, p, instant)


## resolveFrozenCast: a committed frost mage's spell on a target its own control
## holds (or Ice Lance spending Fingers of Frost, or Winter's Chill) counts as frozen:
## +SHATTER_CRIT_BONUS crit, Ice Lance x3. {} when not frozen.
static func frozen_cast(
	w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary
) -> Dictionary:
	if target.is_empty() or def["school"] == "physical" or not _frost(p):
		return {}
	var lance := ICE_LANCE_FROZEN_MULT if def["id"] == "ice_lance" else 1.0
	var frozen := {"treat_as_frozen": true, "damage_mult": lance, "crit_bonus": SHATTER_CRIT_BONUS}
	for a: Dictionary in target["auras"]:
		if a["kind"] in ["stun", "stasis", "root", "incapacitate", "polymorph"]:
			var src := w.unit(int(a["source_id"]))
			if not src.is_empty() and src["kind"] == "player" and src["class_id"] == "mage":
				return frozen
	if def["id"] == "ice_lance" and _consume_stack(w, p, "fingers_of_frost"):
		return frozen
	if def["id"] in WINTERS_CHILL_SPENDERS:
		var chill := RpgAbilityRules.find_kind(target, "winters_chill")
		if not chill.is_empty():
			RpgAbilityRules.consume_charge_of_kind(w, target, "winters_chill")
			return frozen
	return {}


## aetherSurgeCostMult.
static func surge_cost_mult(_p: Dictionary) -> float:
	return 1.0


## convergenceOnCast.
static func convergence_on_cast(_w: RpgEncounter, _p: Dictionary, _id: String) -> void:
	pass


## combustionRestokesCinderfall: Combustion hands a Fire Blast charge back.
static func combustion_restokes(_w: RpgEncounter, p: Dictionary, id: String) -> void:
	if id != "combustion" or not _fire(p):
		return
	var bank: Dictionary = p.get("ability_charges", {}).get("fire_blast", {})
	if bank.is_empty() or int(bank["charges"]) >= int(bank["max"]):
		return
	bank["charges"] = int(bank["charges"]) + 1
	if not (bank["recharges"] as Array).is_empty():
		bank["recharges"].pop_front()
	if int(bank["charges"]) > 0:
		p["cooldowns"].erase("fire_blast")


## applyGreaterInvisibilityAftereffect.
static func greater_invisibility_aftereffect(
	_w: RpgEncounter, _u: Dictionary, _aura: Dictionary
) -> void:
	pass


static func _fire(p: Dictionary) -> bool:
	return p.get("kind") == "player" and p.get("class_id") == "mage" and p.get("spec_id") == "fire"


static func _frost(p: Dictionary) -> bool:
	return p.get("kind") == "player" and p.get("class_id") == "mage" and p.get("spec_id") == "frost"


static func _aura(
	id: String, kind: String, duration: float, p: Dictionary, school: String
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"value": 0.0,
		"remaining": duration,
		"duration": duration,
		"source_id": p["id"],
		"school": school,
	}


## A stacked aura of `kind` loses a stack (going at 0). False when none.
static func _consume_stack(w: RpgEncounter, p: Dictionary, kind: String) -> bool:
	var a := RpgAbilityRules.find_kind(p, kind)
	if a.is_empty():
		return false
	var left := int(a.get("stacks", 1)) - 1
	if left <= 0:
		RpgAbilityRules.remove_aura(w, p, a)
	else:
		a["stacks"] = left
	return true


## fireGuaranteedCrit: a fire mage's fire spell always crits under Combustion; Fire
## Blast always; Scorch at or below 30% target health.
static func fire_guaranteed_crit(p: Dictionary, def: Dictionary, target: Dictionary) -> bool:
	if def["school"] != "fire" or not _fire(p):
		return false
	if RpgAbilityRules.has_kind(p, "combustion") or def["id"] == "fire_blast":
		return true
	return (
		def["id"] == "scorch"
		and not target.is_empty()
		and float(target["hp"]) <= float(target["max_hp"]) * SCORCH_EXECUTE_HP
	)


## cauterizeFireDamageMult: +12% fire damage while Cauterized burns.
static func cauterize_fire_mult(source: Dictionary, target: Dictionary, school: String) -> float:
	if source.is_empty() or source == target or school != "fire":
		return 1.0
	for a: Dictionary in source["auras"]:
		if a["id"] == "cauterizing":
			return 1.0 + CAUTERIZE_FIRE_DMG_BONUS
	return 1.0


## fireMageCauterize: a killing blow on a fire mage leaves 25% health and a burn,
## once per five minutes. Returns the damage to take instead, or -1.
static func cauterize(w: RpgEncounter, target: Dictionary, incoming: float) -> float:
	if target["kind"] != "player" or target["dead"] or incoming < float(target["hp"]):
		return -1.0
	if not _fire(target) or RpgAbilityRules.has_kind(target, "cauterize_fatigue"):
		return -1.0
	target["hp"] = maxi(1, int(RpgTalents.js_round(float(target["max_hp"]) * CAUTERIZE_HEAL_FRAC)))
	RpgCombat.apply_aura(
		w, target, _aura("cauterize_fatigue", "cauterize_fatigue", CAUTERIZE_ICD, target, "fire")
	)
	var burn := _aura("cauterizing", "dot", CAUTERIZE_BURN_DURATION, target, "fire")
	burn["value"] = float(
		maxi(1, int(RpgTalents.js_round(float(target["max_hp"]) * CAUTERIZE_BURN_PER_SEC)))
	)
	burn["tick_interval"] = 1.0
	burn["tick_timer"] = 1.0
	RpgCombat.apply_aura(w, target, burn)
	return 0.0


## applyIgnite: the burn spreads over IGNITE_DURATION; an existing Ignite folds its
## outstanding ticks in.
static func apply_ignite(
	w: RpgEncounter, source: Dictionary, target: Dictionary, burn: int
) -> void:
	if burn <= 0 or target["dead"]:
		return
	var spread := IGNITE_DURATION / IGNITE_INTERVAL
	for a: Dictionary in target["auras"]:
		if a["id"] == "ignite" and a["source_id"] == source["id"]:
			var timer := float(a.get("tick_timer", a.get("tick_interval", IGNITE_INTERVAL)))
			var left := (
				int(floorf((float(a["remaining"]) - timer) / IGNITE_INTERVAL)) + 1
				if float(a["remaining"]) >= timer
				else 0
			)
			var outstanding := float(a["value"]) * left
			a["value"] = float(maxi(1, int(RpgTalents.js_round((outstanding + burn) / spread))))
			a["remaining"] = IGNITE_DURATION
			a["duration"] = IGNITE_DURATION
			return
	var ignite := _aura("ignite", "dot", IGNITE_DURATION, source, "fire")
	ignite["final_damage"] = true
	ignite["value"] = float(maxi(1, int(RpgTalents.js_round(burn / spread))))
	ignite["tick_interval"] = IGNITE_INTERVAL
	ignite["tick_timer"] = IGNITE_INTERVAL
	RpgCombat.apply_aura(w, target, ignite)


## igniteOnCrit: a fire mage's fire crit ignites ignitionPct of it.
static func ignite_on_crit(
	w: RpgEncounter,
	source: Dictionary,
	target: Dictionary,
	amount: int,
	crit: bool,
	school: String,
	ability: String
) -> void:
	if not crit or amount <= 0 or ability == "" or school != "fire":
		return
	if source.is_empty() or source["id"] == target["id"] or not _fire(source):
		return
	var pct := float(source["mods"]["global"]["ignitionPct"])
	if pct > 0.0:
		apply_ignite(w, source, target, int(RpgTalents.js_round(amount * pct)))


## frostMageAfterCast: Frostbolt rolls Fingers of Frost and Brain Freeze and makes an
## Icicle; Flurry leaves Winter's Chill.
static func after_cast(w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary) -> void:
	if def.get("class") != "mage" or p["kind"] != "player":
		return
	if def["id"] == "frostbolt":
		if _frost(p):
			var fingers := w.rng.chance(FINGERS_OF_FROST_CHANCE)
			var brain := w.rng.chance(BRAIN_FREEZE_CHANCE)
			if fingers:
				_gain_fingers(w, p)
			if brain and not RpgAbilityRules.has_kind(p, "brain_freeze"):
				RpgCombat.apply_aura(
					w, p, _aura("brain_freeze", "brain_freeze", BRAIN_FREEZE_DURATION, p, "frost")
				)
			_gain_icicle(w, p)
	elif def["id"] == "flurry" and _frost(p) and not target.is_empty() and not target["dead"]:
		var chill := RpgAbilityRules.find_kind(target, "winters_chill")
		if not chill.is_empty():
			chill["charges"] = WINTERS_CHILL_CHARGES
			chill["remaining"] = WINTERS_CHILL_DURATION
			chill["duration"] = WINTERS_CHILL_DURATION
			chill["source_id"] = p["id"]
		else:
			var a := _aura("winters_chill", "winters_chill", WINTERS_CHILL_DURATION, p, "frost")
			a["charges"] = WINTERS_CHILL_CHARGES
			RpgCombat.apply_aura(w, target, a)


static func _gain_fingers(w: RpgEncounter, p: Dictionary) -> void:
	var a := RpgAbilityRules.find_kind(p, "fingers_of_frost")
	if not a.is_empty():
		if int(a.get("stacks", 1)) >= FINGERS_OF_FROST_MAX_STACKS:
			return
		a["stacks"] = int(a.get("stacks", 1)) + 1
		a["remaining"] = FINGERS_OF_FROST_DURATION
		a["duration"] = FINGERS_OF_FROST_DURATION
		return
	var f := _aura("fingers_of_frost", "fingers_of_frost", FINGERS_OF_FROST_DURATION, p, "frost")
	f["stacks"] = 1
	RpgCombat.apply_aura(w, p, f)


static func _gain_icicle(w: RpgEncounter, p: Dictionary) -> void:
	var a := RpgAbilityRules.find_kind(p, "icicles")
	if not a.is_empty():
		a["remaining"] = ICICLE_DURATION
		a["duration"] = ICICLE_DURATION
		if int(a.get("stacks", 1)) < ICICLE_MAX:
			a["stacks"] = int(a.get("stacks", 1)) + 1
		return
	var i := _aura("icicles", "icicles", ICICLE_DURATION, p, "frost")
	i["stacks"] = 1
	RpgCombat.apply_aura(w, p, i)


## brainFreezeBypassesCooldown.
static func brain_freeze_bypasses(p: Dictionary, id: String) -> bool:
	return id == "flurry" and RpgAbilityRules.has_kind(p, "brain_freeze")


## applyBrainFreezeOverride: Flurry spends Brain Freeze to be instant and cooldown-free.
static func brain_freeze_override(w: RpgEncounter, p: Dictionary, res: Dictionary) -> Dictionary:
	if res["def"]["id"] != "flurry":
		return res
	var a := RpgAbilityRules.find_kind(p, "brain_freeze")
	if a.is_empty():
		return res
	RpgAbilityRules.remove_aura(w, p, a)
	var out := res.duplicate()
	out["castTime"] = 0.0
	out["cooldown"] = 0.0
	return out


## spawnRingOfFrost (ring_of_frost.ts).
static func spawn_ring_of_frost(
	_w: RpgEncounter, _p: Dictionary, _center: float, _eff: Dictionary, _def: Dictionary
) -> void:
	pass


## iceFloesAuraForAbility.
static func ice_floes_for(p: Dictionary, ability_id: String) -> Dictionary:
	for a: Dictionary in p["auras"]:
		if a["kind"] != "ice_floes":
			continue
		if a.get("empower_abilities") == null or ability_id in a["empower_abilities"]:
			return a
	return {}


## consumeOverload: a non-physical, costed cast spends Overload: its effects' numbers
## x (1 + value), its cost x OVERLOAD_COST_MULT.
static func consume_overload(w: RpgEncounter, p: Dictionary, res: Dictionary) -> Dictionary:
	if res["def"]["school"] == "physical" or float(res["cost"]) <= 0.0:
		return res
	var o := RpgAbilityRules.find_kind(p, "overload")
	if o.is_empty():
		return res
	var amp := 1.0 + float(o["value"])
	RpgAbilityRules.remove_aura(w, p, o)
	var fx: Array = []
	for e: Dictionary in res["effects"]:
		var c := e.duplicate(true)
		if c["type"] == "empoweredCone":
			for st: Dictionary in c["stages"]:
				st["min"] = RpgTalents.js_round(float(st["min"]) * amp)
				st["max"] = RpgTalents.js_round(float(st["max"]) * amp)
		else:
			for key: String in ["min", "max", "amount", "bonus", "total", "value"]:
				if c.get(key) is float or c.get(key) is int:
					if float(c[key]) > 0.0:
						c[key] = RpgTalents.js_round(float(c[key]) * amp)
		fx.append(c)
	res["effects"] = fx
	res["cost"] = RpgTalents.js_round(
		float(res["cost"]) * float(w.pack["constants"]["overload_cost_mult"])
	)
	return res


## isIceBlocked: Ice Block's stasis refuses others' control.
static func ice_blocked(u: Dictionary) -> bool:
	for a: Dictionary in u["auras"]:
		if a["id"] == "ice_block" and a["kind"] == "stasis":
			return true
	return false


## overflowingPowerCdr: mana spent takes (cost / max mana) x 10 x manaDefCdrPer10 s off
## the mage's defensive cooldowns, up to 10 s per 30 s window.
static func overflowing_power_cdr(w: RpgEncounter, p: Dictionary, cost: float) -> void:
	if cost <= 0.0 or p["resource_type"] != "mana" or float(p["max_resource"]) <= 0.0:
		return
	var per10 := float(p["mods"]["global"]["manaDefCdrPer10"])
	if per10 <= 0.0:
		return
	var cap := {}
	for a: Dictionary in p["auras"]:
		if a["id"] == "overflowing_power_cap":
			cap = a
	var used := 0.0 if cap.is_empty() else float(cap["value"])
	var shave := minf(cost / float(p["max_resource"]) * 10.0 * per10, OVERFLOW_CAP_SECONDS - used)
	if shave <= 0.0:
		return
	if not cap.is_empty():
		cap["value"] = float(cap["value"]) + shave
	else:
		var a := _aura("overflowing_power_cap", "internal_cd", OVERFLOW_CAP_WINDOW, p, "arcane")
		a["value"] = shave
		RpgCombat.apply_aura(w, p, a)
	for id: String in MAGE_DEFENSIVE_COOLDOWNS:
		if not p["cooldowns"].has(id):
			continue
		var cur := float(p["cooldowns"][id])
		if cur <= shave:
			p["cooldowns"].erase(id)
		else:
			p["cooldowns"][id] = cur - shave
