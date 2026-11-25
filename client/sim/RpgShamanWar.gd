class_name RpgShamanWar
extends RefCounted
## The shaman's Warspirit (src/sim/combat/shaman_warspirit.ts): an Enhancement shaman's
## Galeheart or Stonebound weapon is a posture; every third swing (two with Primal
## Exaltation) arms Stormcast (an instant, half-cost Arc Bolt, shock or Mending
## Waters), Galeheart echoes the swing twice, Stonebound guards. And the shaman's talent
## rows (shaman_talents.ts): Stoneward, Primal Exaltation, Flow State, Imbue Mastery,
## Ward Cycle, Flowing Elements, Wolfstep, Gathering Winds, Wayfarer Grace, Ancestral
## Bulwark and Warded Elements. Threat-only effects (Stonebound's threat and forced
## target) have no second player to sort on the street.

const GALEHEART_WEAPON_ID := "galeheart_weapon"
const STONEBOUND_WEAPON_ID := "rockbiter_weapon"
const CADENCE_ID := "shaman_warspirit_cadence"
const STORMCAST_ID := "shaman_stormcast"
const STORMCAST_CHEAP_ID := "shaman_stormcast_cheap"
const STORMSURGE_READY_ID := "shaman_stormsurge_ready"
const STORMSURGE_CHANCE := 0.25
const STORMSURGE_BAD_LUCK_CAP := 4
const STORMSURGE_FAILURES := "shaman_stormsurge_failures"
const STONEBOUND_ARMOR_ID := "shaman_stonebound_armor"
const STONEBOUND_STAMINA_ID := "shaman_stonebound_stamina"
const STONEBOUND_DR_ID := "shaman_stonebound_dr"
const STONEBOUND_WARD_SMOOTH_ID := "shaman_stonebound_ward_smooth"
const CADENCE_STEPS := 3
const GALEHEART_ECHO_COUNT := 2
const GALEHEART_ECHO_DAMAGE := 0.25
const LIVING_WEAPON_CLEAVE_PERCENT := 0.4
const LIVING_WEAPON_CLEAVE_TARGETS := 2
const STORMCAST_DURATION := 12.0
const ELEMENTAL_TRANCE_ID := "elemental_trance"
const ELEMENTAL_TRANCE_MANA_PCT := 0.2
const STORMCAST_ABILITIES: Array[String] = [
	"lightning_bolt", "earth_shock", "flame_shock", "frost_shock", "healing_wave"
]
const T_WOLFSTEP := "sha_r5_concussion"
const T_GATHERING_WINDS := "sha_r5_improved_lightning_shield"
const T_FLOWING := "sha_r5_imbue_mastery"
const T_STONEWARD := "sha_r8_improved_earth_shock"
const T_WARDED := "sha_r8_frost_bind"
const T_FLOW_STATE := "sha_r14_chain_lightning"
const T_IMBUE_MASTERY := "sha_r14_improved_flame_shock"
const T_WARD_CYCLE := "sha_r14_weapon_fury"
const T_PRIMAL_EXALTATION := "sha_r17_earthbind"
const T_WAYFARER := "sha_r17_improved_ghost_wolf"
const T_BULWARK := "sha_r17_elemental_warding"
const T_DEEP_RESERVOIR := "sha_r20_bloodlust"
const T_ECHOING := "sha_r20_elemental_fury"
const T_LIVING_WEAPON := "sha_r20_tidal_waves"
const STONEWARD_ID := "shaman_stoneward"
const PRIMAL_EXALTATION_ID := "shaman_primal_exaltation"
const FLOW_STATE_PROGRESS_ID := "shaman_flow_state_progress"
const FLOW_STATE_READY_ID := "shaman_flow_state_ready"
const FLOW_STATE_COST_REDUCTION := 40.0
const LONG := 86400.0


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _aura(
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


static func _find(p: Dictionary, id: String) -> Dictionary:
	for a: Dictionary in p["auras"]:
		if a["id"] == id:
			return a
	return {}


static func _drop(w: RpgEncounter, p: Dictionary, id: String) -> void:
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["id"] == id:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})


static func selected(p: Dictionary, option: String) -> bool:
	return p.get("class_id") == "shaman" and bool(p["mods"].get("selected", {}).get(option, false))


static func _warspirit(p: Dictionary) -> bool:
	return (
		p.get("kind") == "player"
		and p.get("class_id") == "shaman"
		and p.get("spec_id") == "enhancement"
	)


# -- posture and cadence ------------------------------------------------------------


static func posture(p: Dictionary) -> String:
	if RpgAbilityRules.has_id(p, STONEBOUND_WEAPON_ID):
		return "stonebound"
	if RpgAbilityRules.has_id(p, GALEHEART_WEAPON_ID):
		return "galeheart"
	return ""


## applyWarspiritPosture: the weapon imbue, and Stonebound's armor, guard and vigor.
static func apply_posture(
	w: RpgEncounter, p: Dictionary, kind: String, bonus: float, dur: float
) -> void:
	if not _warspirit(p):
		return
	for id: String in [
		GALEHEART_WEAPON_ID,
		STONEBOUND_WEAPON_ID,
		STONEBOUND_ARMOR_ID,
		STONEBOUND_STAMINA_ID,
		STONEBOUND_DR_ID,
		STONEBOUND_WARD_SMOOTH_ID
	]:
		_drop(w, p, id)
	var gale := kind == "galeheart"
	RpgCombat.apply_aura(
		w,
		p,
		_aura(
			p,
			GALEHEART_WEAPON_ID if gale else STONEBOUND_WEAPON_ID,
			"imbue",
			dur,
			0.0 if gale else bonus
		)
	)
	if gale:
		w.recalc_player()
		return
	RpgCombat.apply_aura(w, p, _aura(p, STONEBOUND_ARMOR_ID, "buff_armor_pct", dur, 40.0))
	var cut := 0.15 + (0.05 if selected(p, T_IMBUE_MASTERY) else 0.0)
	RpgCombat.apply_aura(w, p, _aura(p, STONEBOUND_DR_ID, "buff_dr", dur, cut))
	RpgCombat.apply_aura(w, p, _aura(p, STONEBOUND_STAMINA_ID, "buff_sta_pct", dur, 20.0))
	w.recalc_player()


static func cadence(p: Dictionary) -> int:
	var a := _find(p, CADENCE_ID)
	return 0 if a.is_empty() else clampi(int(a.get("stacks", 0)), 0, CADENCE_STEPS - 1)


static func _set_cadence(w: RpgEncounter, p: Dictionary, steps: int) -> void:
	var a := _find(p, CADENCE_ID)
	if steps <= 0:
		_drop(w, p, CADENCE_ID)
		return
	if not a.is_empty():
		a["stacks"] = steps
		a["remaining"] = LONG
		return
	var c := _aura(p, CADENCE_ID, "internal_cd", LONG, 0.0)
	c["stacks"] = steps
	RpgCombat.apply_aura(w, p, c)


## advanceWarspiritCadence: a white swing is one step, Ancestral Strike two; the
## third step arms Stormcast and Galeheart's echoes (Living Weapon cleaves them).
static func advance_cadence(
	w: RpgEncounter, p: Dictionary, target: Dictionary, dealt: int, steps := 1
) -> bool:
	if not _warspirit(p) or posture(p) == "":
		return false
	var goal := 2 if exaltation_active(p) else CADENCE_STEPS
	var total := cadence(p) + steps
	if total < goal:
		_set_cadence(w, p, total)
		return false
	_set_cadence(w, p, mini(goal - 1, total - goal))
	var instant := _aura(p, STORMCAST_ID, "next_cast_instant", STORMCAST_DURATION, 1.0)
	instant["empower_abilities"] = STORMCAST_ABILITIES.duplicate()
	RpgCombat.apply_aura(w, p, instant)
	var cheap := _aura(p, STORMCAST_CHEAP_ID, "next_cast_cheap", STORMCAST_DURATION, 0.5)
	cheap["empower_abilities"] = STORMCAST_ABILITIES.duplicate()
	RpgCombat.apply_aura(w, p, cheap)
	if posture(p) != "galeheart" or target["dead"]:
		return true
	var mult := 1.25 if selected(p, T_IMBUE_MASTERY) else 1.0
	var echo := maxi(1, _jr(dealt * GALEHEART_ECHO_DAMAGE * mult))
	for i in GALEHEART_ECHO_COUNT:
		if target["dead"]:
			break
		RpgCombat.deal_damage(w, p, target, echo, false, "nature", "Galeheart Echo")
	if not selected(p, T_LIVING_WEAPON):
		return true
	var near: Array = []
	for m: Dictionary in RpgAbilityRules.hostiles_in_radius(w, p, float(target["x"]), 8.0):
		if m["id"] != target["id"] and not m["dead"]:
			near.append(m)
	var tx := float(target["x"])
	near.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var da := absf(float(a["x"]) - tx)
			var db := absf(float(b["x"]) - tx)
			return da < db if da != db else int(a["id"]) < int(b["id"])
	)
	var cleave := maxi(1, _jr(echo * LIVING_WEAPON_CLEAVE_PERCENT))
	for m: Dictionary in near.slice(0, LIVING_WEAPON_CLEAVE_TARGETS):
		for i in GALEHEART_ECHO_COUNT:
			if not m["dead"]:
				RpgCombat.deal_damage(w, p, m, cleave, false, "nature", "Living Weapon")
	return true


## onStormcastConsumed: Deep Reservoir, Echoing Elements, Living Weapon's shield and
## the Stormsurge reset of Ancestral Strike (25%, never four misses running).
static func on_stormcast_consumed(w: RpgEncounter, p: Dictionary) -> void:
	if not _warspirit(p):
		return
	if selected(p, T_DEEP_RESERVOIR):
		_set_cadence(w, p, 1)
	if selected(p, T_ECHOING):
		RpgCombat.apply_aura(
			w,
			p,
			_aura(p, "shaman_echoing_elements_stormcast", "power_echo", STORMCAST_DURATION, 0.4)
		)
	if posture(p) == "stonebound" and selected(p, T_LIVING_WEAPON):
		var shield := float(maxi(1, _jr(int(p["max_hp"]) * 0.08)))
		RpgCombat.apply_aura(w, p, _aura(p, "shaman_living_weapon_absorb", "absorb", 12.0, shield))
	if float(p["cooldowns"].get("stormstrike", 0.0)) <= 0.0:
		return
	var counters: Dictionary = RpgTalentProcs._state(p)["counters"]
	var failures := int(counters.get(STORMSURGE_FAILURES, 0))
	if w.rng.chance(STORMSURGE_CHANCE) or failures + 1 >= STORMSURGE_BAD_LUCK_CAP:
		p["cooldowns"].erase("stormstrike")
		counters.erase(STORMSURGE_FAILURES)
		RpgCombat.apply_aura(w, p, _aura(p, STORMSURGE_READY_ID, "internal_cd", 6.0, 1.0))
		return
	counters[STORMSURGE_FAILURES] = failures + 1


## applyStoneboundWardSmoothing: Stonebound's thunder ward reflect cuts damage 10%.
static func ward_smoothing(w: RpgEncounter, p: Dictionary, ability_id: String) -> void:
	if ability_id == "lightning_shield" and _warspirit(p) and posture(p) == "stonebound":
		RpgCombat.apply_aura(w, p, _aura(p, STONEBOUND_WARD_SMOOTH_ID, "buff_dr", 3.0, 0.1))


## applyStoneboundJolt: on the street the jolted monster already fights the shaman
## (the forced target and threat order nothing).
static func stonebound_jolt(_w: RpgEncounter, _p: Dictionary, _target: Dictionary) -> void:
	pass


## elementalTranceManaFromDamage: Elemental Trance turns damage dealt into mana.
static func trance_mana(source: Dictionary, amount: int) -> void:
	if amount <= 0 or source.is_empty() or source.get("resource_type") != "mana":
		return
	if RpgAbilityRules.has_id(source, ELEMENTAL_TRANCE_ID):
		source["resource"] = minf(
			float(source["max_resource"]),
			float(source["resource"]) + maxi(1, _jr(amount * ELEMENTAL_TRANCE_MANA_PCT))
		)


# -- talents ------------------------------------------------------------------------


static func apply_stoneward(w: RpgEncounter, p: Dictionary, target: Dictionary) -> void:
	if not selected(p, T_STONEWARD) or target["dead"]:
		return
	_drop(w, target, STONEWARD_ID)
	var ward := _aura(p, STONEWARD_ID, "internal_cd", 60.0, 0.0)
	ward["charges"] = 6
	ward["icd"] = 0.0
	ward["icd_max"] = 3.0
	RpgCombat.apply_aura(w, target, ward)


## onShamanDamageTaken (Stoneward: 5% of max health per hit, 3 s apart, 6 charges).
static func on_damage_taken(w: RpgEncounter, target: Dictionary, amount: int) -> void:
	if amount <= 0 or target["dead"]:
		return
	for ward: Dictionary in (target["auras"] as Array).duplicate():
		if ward["id"] != STONEWARD_ID or int(ward.get("charges", 0)) <= 0:
			continue
		if float(ward.get("icd", 0.0)) > RpgCast.CAST_COMPLETE_EPS:
			continue
		var src := w.unit(int(ward["source_id"]))
		if src.is_empty() or src["dead"]:
			target["auras"].erase(ward)
			continue
		ward["charges"] = maxi(0, int(ward["charges"]) - 1)
		ward["icd"] = float(ward.get("icd_max", 3.0))
		RpgCombat.apply_heal(w, src, target, _jr(int(target["max_hp"]) * 0.05), false)
		if int(ward["charges"]) <= 0:
			target["auras"].erase(ward)


## tickShamanTalentAura.
static func tick_aura(w: RpgEncounter, a: Dictionary) -> void:
	if a["id"] == STONEWARD_ID and float(a.get("icd", 0.0)) > 0.0:
		a["icd"] = maxf(0.0, float(a["icd"]) - w.dt)


static func apply_primal_exaltation(w: RpgEncounter, p: Dictionary) -> void:
	if selected(p, T_PRIMAL_EXALTATION):
		RpgCombat.apply_aura(w, p, _aura(p, PRIMAL_EXALTATION_ID, "internal_cd", 12.0, 0.0))


static func exaltation_active(p: Dictionary) -> bool:
	return RpgAbilityRules.has_id(p, PRIMAL_EXALTATION_ID)


## shamanCastTimeMultiplier: Primal Exaltation halves Arc Bolt and Chain Lightning.
static func cast_time_mult(p: Dictionary, id: String) -> float:
	return 0.5 if id in ["lightning_bolt", "chain_lightning"] and exaltation_active(p) else 1.0


## shamanManaCost: a ready Flow State takes 40 off a mana cost.
static func mana_cost(p: Dictionary, cost: float) -> float:
	if cost <= 0.0 or p["resource_type"] != "mana" or not selected(p, T_FLOW_STATE):
		return cost
	if not RpgAbilityRules.has_id(p, FLOW_STATE_READY_ID):
		return cost
	return maxf(0.0, cost - FLOW_STATE_COST_REDUCTION)


## onShamanManaSpent: every 120 mana spent readies Flow State.
static func on_mana_spent(w: RpgEncounter, p: Dictionary, amount: float, eligible: bool) -> void:
	if not eligible or p["resource_type"] != "mana" or not selected(p, T_FLOW_STATE):
		return
	_drop(w, p, FLOW_STATE_READY_ID)
	if amount <= 0.0:
		return
	var progress := _find(p, FLOW_STATE_PROGRESS_ID)
	var total := float(progress.get("value", 0.0)) + amount
	var rest := total - 120.0 if total >= 120.0 else total
	if not progress.is_empty():
		progress["value"] = rest
		progress["remaining"] = LONG
	elif rest > 0.0:
		RpgCombat.apply_aura(w, p, _aura(p, FLOW_STATE_PROGRESS_ID, "internal_cd", LONG, rest))
	if total >= 120.0:
		RpgCombat.apply_aura(w, p, _aura(p, FLOW_STATE_READY_ID, "internal_cd", LONG, 0.0))


## pyrebrandBonusCharge: Imbue Mastery with Pyrebrand banks an extra charge every third bolt.
static func pyrebrand_bonus_charge(w: RpgEncounter, p: Dictionary) -> int:
	if not selected(p, T_IMBUE_MASTERY) or not RpgAbilityRules.has_id(p, "flametongue_weapon"):
		return 0
	var counter := _find(p, "shaman_pyrebrand_mastery")
	var next := int(counter.get("stacks", 0)) + 1
	if counter.is_empty():
		counter = _aura(p, "shaman_pyrebrand_mastery", "internal_cd", LONG, 0.0)
		RpgCombat.apply_aura(w, p, counter)
		counter = _find(p, "shaman_pyrebrand_mastery")
	counter["remaining"] = LONG
	counter["stacks"] = 0 if next >= 3 else next
	return 1 if next >= 3 else 0


## triggerWardCycle: a charge back on the thunder ward and 10 mana (6 s icd).
static func trigger_ward_cycle(w: RpgEncounter, p: Dictionary) -> void:
	if not selected(p, T_WARD_CYCLE) or RpgAbilityRules.has_id(p, "shaman_ward_cycle_icd"):
		return
	for ward: Dictionary in p["auras"]:
		if ward["id"] == "lightning_shield" and ward["kind"] == "thorns":
			var cap := 3
			var res := w.known_entry("lightning_shield")
			for e: Dictionary in res.get("effects", []):
				if e["type"] == "selfBuff":
					cap = int(e.get("charges", 3))
			ward["charges"] = mini(cap, int(ward.get("charges", cap)) + 1)
	if p["resource_type"] == "mana":
		p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + 10.0)
	RpgCombat.apply_aura(w, p, _aura(p, "shaman_ward_cycle_icd", "internal_cd", 6.0, 0.0))


## onShamanCastCompleted: Ghost Wolf's entry and exit tails; a shock leaves Flowing
## Elements (Arc Bolt and Mending Waters on the move).
static func on_cast_completed(w: RpgEncounter, p: Dictionary, id: String) -> void:
	if p.get("class_id") != "shaman":
		return
	if id == "ghost_wolf":
		if RpgAbilityRules.has_id(p, "ghost_wolf"):
			_on_wolf_entered(w, p)
		else:
			on_ghost_wolf_exited(w, p)
	if id in ["earth_shock", "flame_shock", "frost_shock"] and selected(p, T_FLOWING):
		var floes := _aura(p, "shaman_flowing_elements", "ice_floes", 8.0, 1.0)
		floes["empower_abilities"] = ["lightning_bolt", "healing_wave"]
		RpgCombat.apply_aura(w, p, floes)


static func _on_wolf_entered(w: RpgEncounter, p: Dictionary) -> void:
	if selected(p, T_WOLFSTEP):
		for a: Dictionary in (p["auras"] as Array).duplicate():
			if a["kind"] in ["root", "slow"]:
				p["auras"].erase(a)
	if (
		selected(p, T_GATHERING_WINDS)
		and not RpgAbilityRules.has_id(p, "shaman_gathering_winds_icd")
	):
		RpgCombat.apply_aura(w, p, _aura(p, "shaman_gathering_winds", "buff_speed", 3.0, 1.6))
		RpgCombat.apply_aura(w, p, _aura(p, "shaman_gathering_winds_icd", "internal_cd", 20.0, 0.0))


## onGhostWolfExited: Wayfarer Grace (8 s of casting on the move, 90 s icd).
static func on_ghost_wolf_exited(w: RpgEncounter, p: Dictionary) -> void:
	if not selected(p, T_WAYFARER) or RpgAbilityRules.has_id(p, "shaman_wayfarer_grace_icd"):
		return
	RpgCombat.apply_aura(w, p, _aura(p, "shaman_wayfarer_grace", "ice_floes", 8.0, 99.0))
	RpgCombat.apply_aura(w, p, _aura(p, "shaman_wayfarer_grace_icd", "internal_cd", 90.0, 0.0))


## onThunderWardActivated (Ancestral Bulwark) and onThunderWardRetaliated (Warded
## Elements).
static func on_thunder_ward_activated(w: RpgEncounter, p: Dictionary) -> void:
	if not selected(p, T_BULWARK) or RpgAbilityRules.has_id(p, "shaman_ancestral_bulwark_icd"):
		return
	RpgCombat.apply_aura(w, p, _aura(p, "shaman_ancestral_bulwark", "buff_dr", 6.0, 0.4))
	RpgCombat.apply_aura(w, p, _aura(p, "shaman_ancestral_bulwark_icd", "internal_cd", 120.0, 0.0))


static func on_thunder_ward_retaliated(w: RpgEncounter, p: Dictionary) -> void:
	if selected(p, T_WARDED):
		RpgCombat.apply_aura(w, p, _aura(p, "shaman_warded_elements", "buff_dr", 3.0, 0.1))
