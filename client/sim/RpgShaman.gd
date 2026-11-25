class_name RpgShaman
extends RefCounted
## The shaman's Elemental engine (src/sim/combat/shaman_thundercall.ts,
## shaman_thundercall_kit.ts): Arc Bolt, Chain Lightning, Arc Overload and Magma Burst
## bank Thunder Charges (cap 5); Earthen Jolt and Faultwake vent them for +25% / +20%
## per charge; Primal Mastery doubles the bank and readies an instant bolt; Cinder
## Jolt's ticks may surge Magma Burst. Ghost Wolf's talent tails and the shared hooks
## route here; Warspirit and the talents live in RpgShamanWar, Spiritmend, Unleash
## Weapon and Chain Heal in RpgShamanKit. Set bonuses (Stormkindled, Pyrebrand sets)
## are gear the street never grants.

const THUNDER_CHARGES_ID := "shaman_thunder_charges"
const PRIMAL_MASTERY_ID := "elemental_mastery"
const PRIMAL_MASTERY_INSTANT_ID := "elemental_mastery_instant"
const PRIMAL_MASTERY_VENT_ID := "elemental_mastery_vent"
const MAGMA_SURGE_ID := "shaman_magma_surge"
const THUNDER_CHARGE_CAP := 5
const THUNDER_BANK_DURATION := 86400.0
const EARTHEN_JOLT_BONUS_PER_CHARGE := 0.25
const FAULTWAKE_BONUS_PER_CHARGE := 0.2
const PRIMAL_MASTERY_DURATION := 12.0
const PRIMAL_MASTERY_VENT_BONUS := 0.25
const THUNDER_VENTS: Array[String] = ["earth_shock", "earthquake"]
const ARC_OVERLOAD_CHANCE := 0.2
const ARC_OVERLOAD_DAMAGE_FRACTION := 0.5
const MAGMA_BURST_CRIT_BONUS := 0.24
const MAGMA_SURGE_CHANCE := 0.2
const MAGMA_SURGE_DURATION := 10.0
const STORMBREAK_MANA_FRACTION := 0.08
const CINDER_JOLT_DURATION := 27.0


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _elemental(p: Dictionary) -> bool:
	return (
		p.get("kind") == "player"
		and p.get("class_id") == "shaman"
		and p.get("spec_id") == "elemental"
	)


static func knows(w: RpgEncounter, id: String) -> bool:
	for k: Dictionary in w.known():
		if k["id"] == id:
			return true
	return false


static func _state(
	p: Dictionary, id: String, kind: String, dur: float, value: float, school := "nature"
) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": dur,
		"duration": dur,
		"value": value,
		"source_id": p["id"],
		"school": school,
	}


static func _remove_id(w: RpgEncounter, p: Dictionary, id: String) -> bool:
	for a: Dictionary in p["auras"]:
		if a["id"] == id:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
			return true
	return false


# -- Thunder Charges ---------------------------------------------------------------


static func thunder_charges(p: Dictionary) -> int:
	for a: Dictionary in p["auras"]:
		if a["id"] == THUNDER_CHARGES_ID:
			return clampi(int(a.get("stacks", 0)), 0, THUNDER_CHARGE_CAP)
	return 0


## addThunderCharges.
static func add_thunder_charges(w: RpgEncounter, p: Dictionary, n: int) -> int:
	if not _elemental(p) or n <= 0:
		return thunder_charges(p)
	var next := mini(THUNDER_CHARGE_CAP, thunder_charges(p) + n)
	for a: Dictionary in p["auras"]:
		if a["id"] == THUNDER_CHARGES_ID:
			a["stacks"] = next
			a["remaining"] = THUNDER_BANK_DURATION
			a["duration"] = THUNDER_BANK_DURATION
			return next
	var bank := _state(p, THUNDER_CHARGES_ID, "internal_cd", THUNDER_BANK_DURATION, 0.0)
	bank["stacks"] = next
	RpgCombat.apply_aura(w, p, bank)
	return next


## thundercallDamageMultiplier: a vent's bonus per banked charge (and the Primal
## Mastery vent bonus on a full bank).
static func thundercall_damage_mult(_w: RpgEncounter, p: Dictionary, id: String) -> float:
	if not _elemental(p):
		return 1.0
	var charges := thunder_charges(p)
	if charges <= 0:
		return 1.0
	var primal := 0.0
	if charges == THUNDER_CHARGE_CAP and RpgAbilityRules.has_id(p, PRIMAL_MASTERY_VENT_ID):
		primal = PRIMAL_MASTERY_VENT_BONUS
	if id == "earth_shock":
		return (1.0 + charges * EARTHEN_JOLT_BONUS_PER_CHARGE) * (1.0 + primal)
	if id == "earthquake":
		return (1.0 + charges * FAULTWAKE_BONUS_PER_CHARGE) * (1.0 + primal)
	return 1.0


## consumeThunderVent: the bank empties into the vent; a full one feeds Deep
## Reservoir, Living Weapon and Echoing Elements.
static func consume_vent(
	w: RpgEncounter, p: Dictionary, id: String, target := {}, resolved := 0
) -> int:
	if not _elemental(p) or not id in THUNDER_VENTS:
		return 0
	var charges := thunder_charges(p)
	if charges <= 0:
		return 0
	_remove_id(w, p, THUNDER_CHARGES_ID)
	if charges == THUNDER_CHARGE_CAP:
		_remove_id(w, p, PRIMAL_MASTERY_VENT_ID)
		if RpgShamanWar.selected(p, RpgShamanWar.T_DEEP_RESERVOIR):
			add_thunder_charges(w, p, 2)
		if (
			RpgShamanWar.selected(p, RpgShamanWar.T_LIVING_WEAPON)
			and RpgAbilityRules.has_id(p, "flametongue_weapon")
		):
			var bolt := _state(
				p, "shaman_living_weapon_bolt", "next_cast_instant", 12.0, 1.0, "fire"
			)
			bolt["empower_abilities"] = ["lightning_bolt"]
			RpgCombat.apply_aura(w, p, bolt)
		if (
			not target.is_empty()
			and not target["dead"]
			and resolved > 0
			and RpgShamanWar.selected(p, RpgShamanWar.T_ECHOING)
		):
			var echo := _state(
				p, "shaman_echoing_elements_damage", "dot", 1.0, float(maxi(1, _jr(resolved * 0.4)))
			)
			echo["tick_interval"] = 1.0
			echo["tick_timer"] = 1.0
			RpgCombat.apply_aura(w, target, echo)
	return charges


## The groundAoE arm's shaman tail: a full-bank Faultwake with Echoing Elements lays a
## 40% echo zone; then the vent spends the bank.
static func after_ground_aoe(
	w: RpgEncounter, p: Dictionary, def: Dictionary, eff: Dictionary, area: Dictionary
) -> void:
	if def["id"] != "earthquake" or not _elemental(p):
		return
	if (
		thunder_charges(p) == THUNDER_CHARGE_CAP
		and RpgShamanWar.selected(p, RpgShamanWar.T_ECHOING)
	):
		var echo := area.duplicate()
		echo["min"] = float(maxi(1, _jr(float(area["min"]) * 0.4)))
		echo["max"] = float(maxi(1, _jr(float(area["max"]) * 0.4)))
		echo["remaining"] = float(eff["duration"]) + 1.0
		echo["tick_timer"] = 1.0
		echo["ability"] = "Echoing Elements"
		echo["sp_bonus"] = float(area["sp_bonus"]) * 0.4
		w.ground.append(echo)
	consume_vent(w, p, "earthquake")


## runEffects' shaman prelude (effect_dispatch.ts:585-590).
static func before_effects(
	w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary
) -> void:
	if p.get("class_id") != "shaman":
		return
	match str(def["id"]):
		"elemental_mastery":
			if _elemental(p):
				RpgCombat.apply_aura(
					w, p, _state(p, PRIMAL_MASTERY_ID, "internal_cd", PRIMAL_MASTERY_DURATION, 0.0)
				)
				var instant := _state(
					p, PRIMAL_MASTERY_INSTANT_ID, "next_cast_instant", PRIMAL_MASTERY_DURATION, 1.0
				)
				instant["empower_abilities"] = ["lightning_bolt", "chain_lightning"]
				RpgCombat.apply_aura(w, p, instant)
				var vent := _state(
					p,
					PRIMAL_MASTERY_VENT_ID,
					"internal_cd",
					PRIMAL_MASTERY_DURATION,
					PRIMAL_MASTERY_VENT_BONUS
				)
				RpgCombat.apply_aura(w, p, vent)
		"thunderstorm":
			if _elemental(p) and p["resource_type"] == "mana":
				p["resource"] = minf(
					float(p["max_resource"]),
					float(p["resource"]) + _jr(float(p["max_resource"]) * STORMBREAK_MANA_FRACTION)
				)
		"primal_exaltation":
			RpgShamanWar.apply_primal_exaltation(w, p)
		"stoneward":
			if not target.is_empty():
				RpgShamanWar.apply_stoneward(w, p, target)
		"lightning_shield":
			RpgShamanWar.on_thunder_ward_activated(w, p)
		"unleash_weapon":
			RpgShamanKit.run_unleash(w, p, target)


## directDamage's shaman tails after a hit (effect_dispatch.ts:1011-1020).
static func after_direct_damage(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	id: String,
	final: int,
	resolved: int,
	threat_mult: float
) -> void:
	if p.get("class_id") != "shaman":
		return
	if id == "lightning_bolt":
		if _elemental(p):
			var fast := (
				RpgAbilityRules.has_id(p, PRIMAL_MASTERY_ID) or RpgShamanWar.exaltation_active(p)
			)
			add_thunder_charges(
				w, p, (2 if fast else 1) + RpgShamanWar.pyrebrand_bonus_charge(w, p)
			)
		RpgShamanWar.trigger_ward_cycle(w, p)
		roll_overload(w, p, target, id, final, resolved, threat_mult)
	if id == "earth_shock":
		consume_vent(w, p, id, target, final)
		RpgShamanWar.stonebound_jolt(w, p, target)
	if id == "lava_burst":
		add_thunder_charges(w, p, 1)


## The chainDamage arm's Chain Lightning tail.
static func after_chain(
	w: RpgEncounter,
	p: Dictionary,
	id: String,
	first: Dictionary,
	planned: int,
	landed: int,
	threat_mult: float
) -> void:
	if id != "chain_lightning" or first.is_empty():
		return
	if _elemental(p):
		add_thunder_charges(w, p, 1)
	RpgShamanWar.trigger_ward_cycle(w, p)
	roll_overload(w, p, first, id, planned, landed, threat_mult)


## rollArcOverload: a known Arc Overload repeats half the bolt (20%), +1 charge.
static func roll_overload(
	w: RpgEncounter,
	p: Dictionary,
	target: Dictionary,
	id: String,
	planned: int,
	landed: int,
	threat_mult: float
) -> void:
	if not id in ["lightning_bolt", "chain_lightning"] or planned <= 0 or landed <= 0:
		return
	if target["dead"] or not _elemental(p) or not knows(w, "lightning_overload"):
		return
	if not w.rng.chance(ARC_OVERLOAD_CHANCE):
		return
	RpgCombat.deal_damage(
		w,
		p,
		target,
		maxi(1, _jr(planned * ARC_OVERLOAD_DAMAGE_FRACTION)),
		false,
		"nature",
		"Arc Overload",
		"hit",
		false,
		{"mult": threat_mult, "ability_id": "lightning_overload"}
	)
	add_thunder_charges(w, p, 1)


## resolveThundercallAbility: an elemental's Cinder Jolt burns for 27 s.
static func resolve(p: Dictionary, k: Dictionary) -> Dictionary:
	if not _elemental(p) or k["def"]["id"] != "flame_shock":
		return k
	var out := k.duplicate()
	var effects: Array = []
	for src: Dictionary in k["effects"]:
		var e := src.duplicate(true)
		if e["type"] == "dot":
			var per := _jr(float(e["total"]) / (float(e["duration"]) / float(e["interval"])))
			e["total"] = per * (CINDER_JOLT_DURATION / float(e["interval"]))
			e["duration"] = CINDER_JOLT_DURATION
		effects.append(e)
	out["effects"] = effects
	return out


## magmaBurstCritBonus.
static func magma_crit_bonus(p: Dictionary, id: String) -> float:
	return MAGMA_BURST_CRIT_BONUS if id == "lava_burst" and _elemental(p) else 0.0


## magmaBurstGuaranteedCrit: Magma Burst always crits a target burning with the
## shaman's Cinder Jolt.
static func magma_burst_crit(
	_w: RpgEncounter, p: Dictionary, def: Dictionary, target: Dictionary
) -> bool:
	if def["id"] != "lava_burst" or not _elemental(p) or target.is_empty():
		return false
	for a: Dictionary in target["auras"]:
		if a["id"] == "flame_shock" and a["kind"] == "dot" and a["source_id"] == p["id"]:
			return true
	return false


## thundercallOnDotTick: a landed Cinder Jolt tick may reset and quicken Magma Burst.
static func on_dot_tick(w: RpgEncounter, src: Dictionary, a: Dictionary, landed: int) -> void:
	if a["id"] != "flame_shock" or src.is_empty() or src["dead"] or landed <= 0:
		return
	if str(src["casting"].get("ability", "")) == "lava_burst":
		return
	if not _elemental(src) or not knows(w, "lava_burst"):
		return
	if not w.rng.chance(MAGMA_SURGE_CHANCE):
		return
	src["cooldowns"].erase("lava_burst")
	var surge := _state(src, MAGMA_SURGE_ID, "next_cast_instant", MAGMA_SURGE_DURATION, 1.0, "fire")
	surge["empower_abilities"] = ["lava_burst"]
	RpgCombat.apply_aura(w, src, surge)


# -- Ghost Wolf and the shared tails -----------------------------------------------


## onGhostWolfExited (Wayfarer Grace).
static func on_ghost_wolf_exited(w: RpgEncounter, p: Dictionary, _id: String) -> void:
	RpgShamanWar.on_ghost_wolf_exited(w, p)


## breakGhostWolf: any action but Ghost Wolf itself drops the wolf.
static func break_ghost_wolf(w: RpgEncounter, p: Dictionary) -> void:
	for a: Dictionary in p["auras"]:
		if a["id"] == "ghost_wolf":
			RpgAbilityRules.remove_aura(w, p, a)
			on_ghost_wolf_exited(w, p, "ghost_wolf")
			return


## onShamanCastCompleted.
static func on_cast_completed(w: RpgEncounter, p: Dictionary, id: String) -> void:
	RpgShamanWar.on_cast_completed(w, p, id)


## tickMendingCurrent: true when the hot is a Mending Current it ticked itself.
static func tick_mending_current(w: RpgEncounter, e: Dictionary, a: Dictionary) -> bool:
	return RpgShamanKit.tick_mending_current(w, e, a)


## The imbue arm's Galeheart / Rockbiter posture. True when it handled the cast.
static func imbue_posture(w: RpgEncounter, p: Dictionary, def: Dictionary, eff: Dictionary) -> bool:
	if not def["id"] in ["galeheart_weapon", "rockbiter_weapon"]:
		return false
	var posture := "galeheart" if def["id"] == "galeheart_weapon" else "stonebound"
	RpgShamanWar.apply_posture(w, p, posture, float(eff["bonus"]), float(eff["duration"]))
	return true
