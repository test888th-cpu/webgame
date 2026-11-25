class_name RpgDruidEngine
extends RefCounted
## The druid's spec engines (src/sim/combat/druid_engines.ts): Balance banks Moontide
## from Wrath, Starfire and Moonseed inside Moonwing Form; Feral banks Old Blood from
## its strikes (and Blooddrunk's bleed ticks); Restoration banks Verdance from planted
## blooms and Wildmend. Three stages swap the spec's payoff onto its button (the action
## replacements). Shifting into a form grants Loping Stride; Bruin Rush opens the Pin
## window a Cat Form shift spends. Nature's Boon (druid_natures_boon.ts) arms the
## boon spells. Set bonuses (Cinderbark, Wildfang, Grovespring) are gear the street
## never grants.

const MOONTIDE_ID := "moontide"
const OLD_BLOOD_ID := "old_blood"
const VERDANCE_ID := "verdance"
const STAGES := 3
const BACKING := 3600.0
const WILDMEND_ID := "healing_touch"
const VERDANCE_WILDMEND_CAST_TIMES: Array[float] = [2.2, 1.9, 1.5]
const HIGHMOON_TITHE_PCT := 0.15
const WILD_APEX_MULT := 1.25
const LOPING_STRIDE_SPEED := 1.6
const LOPING_STRIDE_DURATION := 3.0
const LOPING_STRIDE_ICD := 20.0
const LOPING_STRIDE_ICD_KEY := "dru_loping_stride"
const BRUIN_RUSH_WINDOW_ID := "bruin_rush_window"
const BRUIN_RUSH_WINDOW_SECONDS := 3.0
const PIN_SLOW_MULT := 0.5
const PIN_DURATION := 4.0
const T_WILDSHIFT := "dru_r5_improved_wrath"
const T_LONGSTRIDE := "dru_r5_ferocity"
const T_HIGHMOON := "dru_r14_moonfury"
const T_BLOODDRUNK := "dru_r14_savage_fury"
const T_SEEDSPREAD := "dru_r14_empowered_touch"
const T_NATURES_FURY := "dru_r20_improved_hurricane"
const T_WILD_APEX := "dru_r20_berserk"
const T_QUICKENING := "dru_r20_tranquility"
const PAYOFF_IDS: Array[String] = ["moonlash", "sunlance", "redharvest", "marrowbreak", "overbloom"]
const FORM_ABILITY_IDS: Array[String] = [
	"bear_form", "cat_form", "travel_form", "moonkin_form", "sporemender_form"
]
const MOONTIDE_BUILDERS: Array[String] = ["wrath", "starfire", "moonseed"]
const OLD_BLOOD_STRIKES: Array[String] = [
	"claw", "rake", "rip", "ferocious_bite", "maul", "swipe", "scratch", "pounce", "lunge"
]
const NATURES_BOON_ID := "natures_boon"
const NATURES_BOON_PPM := 4.0
const NATURES_BOON_DURATION := 10.0
const NATURES_BOON_POWER := 1.25
const NATURES_BOON_WILDBLOOM_POWER := 1.5
const CASTER_BOON_CHANCE := 0.1
const CASTER_BOON_ICD := 10.0
const GROVEHEART_BOON_ICD_KEY := "dru_grove_natures_boon"
const MOONGROVE_BOON_ICD_KEY := "dru_moon_natures_boon"


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


static func _druid(p: Dictionary, spec := "") -> bool:
	return (
		p.get("kind") == "player"
		and p.get("class_id") == "druid"
		and (spec == "" or p.get("spec_id") == spec)
	)


static func _selected(p: Dictionary, option: String) -> bool:
	return bool(p["mods"].get("selected", {}).get(option, false))


static func _owned(p: Dictionary, id: String) -> Dictionary:
	for a: Dictionary in p["auras"]:
		if a["id"] == id and a["source_id"] == p["id"]:
			return a
	return {}


static func _remove_owned(w: RpgEncounter, p: Dictionary, id: String) -> void:
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["id"] == id and a["source_id"] == p["id"]:
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})


static func stacks(p: Dictionary, id: String) -> int:
	var a := _owned(p, id)
	return 0 if a.is_empty() else int(a.get("stacks", 0))


static func _set_bank(w: RpgEncounter, p: Dictionary, id: String, n: int) -> void:
	var a := _owned(p, id)
	if not a.is_empty():
		a["stacks"] = n
		a["remaining"] = BACKING
		a["duration"] = BACKING
		return
	(
		RpgCombat
		. apply_aura(
			w,
			p,
			{
				"id": id,
				"kind": id,
				"remaining": BACKING,
				"duration": BACKING,
				"value": 0.0,
				"source_id": p["id"],
				"school": "nature",
				"stacks": n,
			}
		)
	)


## addStage: one stage up to the cap; Quickening pays a resource per stage.
static func _add_stage(w: RpgEncounter, p: Dictionary, id: String) -> void:
	var before := stacks(p, id)
	if before >= STAGES:
		return
	_set_bank(w, p, id, before + 1)
	if not _selected(p, T_QUICKENING):
		return
	var gain := 0.0
	match str(p["resource_type"]):
		"energy":
			gain = 5.0
		"rage":
			gain = 3.0
		_:
			gain = float(_jr(float(p["max_resource"]) * 0.02))
	p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + gain)


## seedNextEngineBank: an emptied bank restarts at one stage with Nature's Fury.
static func _seed(w: RpgEncounter, p: Dictionary, id: String) -> void:
	_set_bank(w, p, id, 1 if _selected(p, T_NATURES_FURY) else 0)


## druidEngineOnCast.
static func on_cast(w: RpgEncounter, p: Dictionary, id: String, target: Dictionary) -> void:
	if not _druid(p):
		return
	if id in FORM_ABILITY_IDS:
		if id == "travel_form" or _selected(p, T_WILDSHIFT):
			for a: Dictionary in (p["auras"] as Array).duplicate():
				if a["kind"] in ["root", "slow"] and not a.get("unbreakable_control", false):
					p["auras"].erase(a)
		var icds: Dictionary = RpgTalentProcs._state(p)["icds"]
		if not icds.has(LOPING_STRIDE_ICD_KEY):
			var long := _selected(p, T_LONGSTRIDE)
			icds[LOPING_STRIDE_ICD_KEY] = (
				_longstride_metric(w, "icd") if long else LOPING_STRIDE_ICD
			)
			var dur := _longstride_metric(w, "duration") if long else LOPING_STRIDE_DURATION
			RpgCombat.apply_aura(
				w, p, _aura(p, "loping_stride", "buff_speed", dur, LOPING_STRIDE_SPEED)
			)
	if id == "bear_charge" and not target.is_empty() and not target["dead"]:
		_remove_owned(w, p, BRUIN_RUSH_WINDOW_ID)
		var rush := _aura(p, BRUIN_RUSH_WINDOW_ID, "internal_cd", BRUIN_RUSH_WINDOW_SECONDS, 0.0)
		rush["value"] = float(target["id"])
		RpgCombat.apply_aura(w, p, rush)
	elif id == "cat_form":
		var rush := _owned(p, BRUIN_RUSH_WINDOW_ID)
		if not rush.is_empty():
			_remove_owned(w, p, BRUIN_RUSH_WINDOW_ID)
			var pinned := w.unit(int(rush["value"]))
			if not pinned.is_empty() and not pinned["dead"] and pinned["kind"] == "mob":
				var pin := _aura(p, "pin", "slow", PIN_DURATION, PIN_SLOW_MULT)
				pin["school"] = "physical"
				RpgCombat.apply_aura(w, pinned, pin)
				w.enter_combat(p, pinned)
	if id == "lunge":
		RpgDruidKit.start_lunge(w, p, target)
	var spec := str(p.get("spec_id", ""))
	if id == "spore_burst":
		var bank := (
			VERDANCE_ID if spec == "restoration" else (MOONTIDE_ID if spec == "balance" else "")
		)
		if bank != "" and stacks(p, bank) >= STAGES:
			_remove_owned(w, p, bank)
			_seed(w, p, bank)
		return
	if spec == "balance":
		if not RpgAbilityRules.has_kind(p, "form_moonkin"):
			return
		if id in MOONTIDE_BUILDERS:
			_add_stage(w, p, MOONTIDE_ID)
		elif id == "moonlash" or id == "sunlance":
			_remove_owned(w, p, MOONTIDE_ID)
			_seed(w, p, MOONTIDE_ID)
			if _selected(p, T_HIGHMOON) and p["resource_type"] == "mana":
				p["resource"] = minf(
					float(p["max_resource"]),
					float(p["resource"]) + _jr(float(p["max_resource"]) * HIGHMOON_TITHE_PCT)
				)
		return
	if spec == "feral" and (id == "redharvest" or id == "marrowbreak"):
		_remove_owned(w, p, OLD_BLOOD_ID)
		if _selected(p, T_NATURES_FURY):
			_set_bank(w, p, OLD_BLOOD_ID, 1)
		return
	if spec == "restoration" and id == WILDMEND_ID:
		_add_stage(w, p, VERDANCE_ID)


## longstrideMetrics: the talent's intrinsic duration and icd from the pack.
static func _longstride_metric(w: RpgEncounter, key: String) -> float:
	for row: Dictionary in w.pack["talents"]["druid"]["rows"]:
		for option: Dictionary in row["options"]:
			if option["id"] != T_LONGSTRIDE:
				continue
			var intrinsic: Dictionary = option["effect"].get("intrinsic", {})
			return float(intrinsic.get("metrics", {}).get(key, 0.0))
	return LOPING_STRIDE_DURATION if key == "duration" else LOPING_STRIDE_ICD


static func _aura(p: Dictionary, id: String, kind: String, dur: float, value: float) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"remaining": dur,
		"duration": dur,
		"value": value,
		"source_id": p["id"],
		"school": "nature",
	}


## druidEngineOnHotPlanted: Rejuvenation and Regrowth bank Verdance.
static func on_hot_planted(w: RpgEncounter, p: Dictionary, id: String) -> void:
	if id in ["rejuvenation", "regrowth"] and _druid(p, "restoration"):
		_add_stage(w, p, VERDANCE_ID)


## druidEngineOnLandedStrike: a feral strike banks Old Blood.
static func on_landed_strike(w: RpgEncounter, p: Dictionary, id: String) -> void:
	if id in OLD_BLOOD_STRIKES and _druid(p, "feral"):
		_add_stage(w, p, OLD_BLOOD_ID)


## druidEngineOnBleedTick: Blooddrunk banks Old Blood from Rake and Rip ticks.
static func on_bleed_tick(w: RpgEncounter, src: Dictionary, a: Dictionary) -> void:
	if src.is_empty() or src["dead"] or str(a["school"]) != "physical":
		return
	if not a["id"] in ["rake", "rip"] or not _druid(src, "feral"):
		return
	if _selected(src, T_BLOODDRUNK):
		_add_stage(w, src, OLD_BLOOD_ID)


## druidEngineCombatState: out of combat Old Blood and the rush window fade.
static func combat_state(w: RpgEncounter, p: Dictionary) -> void:
	if p["in_combat"] or not _druid(p):
		return
	if not _owned(p, OLD_BLOOD_ID).is_empty():
		_remove_owned(w, p, OLD_BLOOD_ID)
	if not _owned(p, BRUIN_RUSH_WINDOW_ID).is_empty():
		_remove_owned(w, p, BRUIN_RUSH_WINDOW_ID)


## druidApexPayoffMult: Wild Apex lifts every payoff 25%.
static func apex_payoff_mult(p: Dictionary, id: String) -> float:
	return WILD_APEX_MULT if id in PAYOFF_IDS and _selected(p, T_WILD_APEX) else 1.0


## verdanceWildmendCastTime: banked Verdance speeds Wildmend.
static func wildmend_cast_time(p: Dictionary, id: String, cast_time: float) -> float:
	if id != WILDMEND_ID or cast_time <= 0.0:
		return cast_time
	var n := 0
	for a: Dictionary in p["auras"]:
		if a["kind"] == "verdance":
			n = mini(int(a.get("stacks", 1)), VERDANCE_WILDMEND_CAST_TIMES.size())
			break
	if n <= 0:
		return cast_time
	return minf(cast_time, VERDANCE_WILDMEND_CAST_TIMES[n - 1])


static func _remaining_ticks(a: Dictionary) -> int:
	var interval := float(a.get("tick_interval", 1.0))
	var until := float(a.get("tick_timer", interval))
	if until > float(a["remaining"]):
		return 0
	return 1 + maxi(0, int(floorf((float(a["remaining"]) - until) / interval)))


## replantSporemending: a fresh Rejuvenation at its resolved strength.
static func replant_sporemending(
	w: RpgEncounter, p: Dictionary, target: Dictionary, cast_mult := 1.0
) -> void:
	var res := w.known_entry("rejuvenation")
	if res.is_empty():
		return
	var hot := {}
	for e: Dictionary in res["effects"]:
		if e["type"] == "hot":
			hot = e
	if hot.is_empty():
		return
	var hm := RpgTalents.hit_mult(w.pack, res["def"], p["mods"])
	var interval := float(hot["interval"])
	var base := maxi(1, _jr(float(hot["total"]) / (float(hot["duration"]) / interval)))
	var sp := RpgEffects.periodic_bonus(
		w,
		float(p["heal_power"]),
		float(w.pack["constants"]["healing_sp_scale"]),
		float(hot["duration"]),
		interval,
		float(hm["heal"]) * (1.0 + float(p["mods"]["global"]["hotHealPct"]))
	)
	var tick := float(base + sp)
	if cast_mult != 1.0:
		tick = float(maxi(1, _jr(tick * cast_mult)))
	var aura := _aura(p, "rejuvenation", "hot", float(hot["duration"]), 0.0)
	aura["value"] = RpgEffects.scale_primary(tick, RpgEffects.primary_heal_mult(p))
	aura["tick_interval"] = interval
	aura["tick_timer"] = interval
	RpgCombat.apply_aura(w, target, aura)


## resolveDruidOverbloom: every bloom of the druid's is harvested at harvestPct of
## its remaining healing (the street's only ally is the druid), then Sporemending is
## replanted on the cast target.
static func overbloom(w: RpgEncounter, p: Dictionary, target: Dictionary, pct: float) -> void:
	var left := 0.0
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["kind"] == "hot" and a["source_id"] == p["id"]:
			left += float(a["value"]) * _remaining_ticks(a)
			p["auras"].erase(a)
	if left > 0.0 and not p["dead"]:
		RpgCombat.apply_heal(w, p, p, _jr(left * pct * apex_payoff_mult(p, "overbloom")), false)
	replant_sporemending(w, p, target)
	if _selected(p, T_NATURES_FURY):
		_set_bank(w, p, VERDANCE_ID, 1)


# -- Nature's Boon -----------------------------------------------------------------


## naturesBoonPowerFor: an armed boon makes its spell 25% stronger (Sporemending 50%).
static func boon_power(p: Dictionary, id: String) -> float:
	if not RpgDruid.natures_boon_armed_for(p, id):
		return 1.0
	return NATURES_BOON_WILDBLOOM_POWER if id == "rejuvenation" else NATURES_BOON_POWER


## armNaturesBoon.
static func _arm_boon(w: RpgEncounter, p: Dictionary, abilities: Array[String]) -> void:
	var a := _owned(p, NATURES_BOON_ID)
	if not a.is_empty():
		a["kind"] = "next_cast_free"
		a["remaining"] = NATURES_BOON_DURATION
		a["duration"] = NATURES_BOON_DURATION
		a["empower_abilities"] = abilities.duplicate()
		return
	var boon := _aura(p, NATURES_BOON_ID, "next_cast_free", NATURES_BOON_DURATION, 0.0)
	boon["empower_abilities"] = abilities.duplicate()
	RpgCombat.apply_aura(w, p, boon)


## naturesBoonOnAutoAttack: a feral's swing arms the boon at 4 per minute and resets
## Oakhide.
static func boon_on_auto_attack(w: RpgEncounter, p: Dictionary) -> void:
	if not _druid(p, "feral"):
		return
	if not w.rng.chance(NATURES_BOON_PPM * RpgDruid.base_swing_speed(p) / 60.0):
		return
	_arm_boon(w, p, RpgDruid.NATURES_BOON_ABILITIES)
	p["cooldowns"].erase("barkskin")


static func _caster_boon(
	w: RpgEncounter, p: Dictionary, key: String, abilities: Array[String]
) -> void:
	var icds: Dictionary = RpgTalentProcs._state(p)["icds"]
	if icds.has(key) or not w.rng.chance(CASTER_BOON_CHANCE):
		return
	icds[key] = CASTER_BOON_ICD
	_arm_boon(w, p, abilities)


## naturesBoonOnCast: Balance's Wrath and Starfire, 10% (10 s icd).
static func boon_on_cast(w: RpgEncounter, p: Dictionary, id: String) -> void:
	if id in ["wrath", "starfire"] and _druid(p, "balance"):
		_caster_boon(w, p, MOONGROVE_BOON_ICD_KEY, RpgDruid.MOONGROVE_BOON_ABILITIES)


## naturesBoonOnHotTick: Restoration's own hot ticks, 10% (10 s icd).
static func boon_on_hot_tick(w: RpgEncounter, src: Dictionary, a: Dictionary) -> void:
	if src.is_empty() or src["dead"] or a["kind"] != "hot" or a["source_id"] != src["id"]:
		return
	if _druid(src, "restoration"):
		_caster_boon(w, src, GROVEHEART_BOON_ICD_KEY, RpgDruid.GROVEHEART_BOON_ABILITIES)
