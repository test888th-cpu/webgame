class_name RpgRogue
extends RefCounted
## The rogue's mechanics (src/sim/combat/rogue_engines.ts, rogue_stealth_opener.ts,
## rogue_talents.ts, sim.ts awardCombo, effect_dispatch.ts dropSelfFromHostileFocus,
## casting_lifecycle.ts vanishedLowBlowFallbackTarget). The three spec engines:
## combat's Redline (Body Blow deepens it, Knockout Blow cashes it), assassination's
## Venom Ritual (Venomrend at six stages), subtlety's Gloam bank (a full bank turns
## the next opener into the Shadow Veil). The item-set bonuses those engines read
## are 0: this game has no set items.

const VENOM_RITUAL_ID := "venom_ritual"
const REDLINE_ID := "redline"
const GLOAM_ID := "gloam"
const VEILSTRIKE_ID := "veilstrike"
const VEILED_EDGE_ID := "veiled_edge"
const BODY_BLOW_ID := "body_blow"
const KNOCKOUT_ID := "knockout_blow"
const DUSK_ECONOMY_AURA_ID := "dusk_economy"
const GLOAM_STAGES := 3
const VENOM_RITUAL_STAGES := 6
const VENOM_RITUAL_DURATION := 30.0
const GLOAM_DURATION := 60.0
const REDLINE_DURATION := 8.0
const REDLINE_MAX_DEPTH := 4
const KNOCKOUT_PER_PIP := 0.25
const VEILED_EDGE_BONUS := 0.5
const GLOAM_RHYTHM_KEY := "rog_gloam_rhythm"
const GLOAM_RHYTHM_EVERY := 2
const VENOM_STAGE_REFUND := 15.0
const VENOM_DART_EXTEND := 6.0
const VENOM_WOUND_CAP := 20.0
const DUSK_ECONOMY_LINGER_SEC := 6.0
const TRUE_STEALTH_OPENER_MULT := 2.0
const DUSK_OPENER_IDS: Array[String] = ["ambush", "garrote", "cheap_shot"]


static func _mine(p: Dictionary, id: String) -> Dictionary:
	for a: Dictionary in p["auras"]:
		if a["id"] == id and a["source_id"] == p["id"]:
			return a
	return {}


static func _aura(
	id: String, kind: String, duration: float, value: float, p: Dictionary, school: String
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


# -- combo points (sim.ts awardCombo, auras.ts updateComboExpiry) ---------------------


## awardCombo: points to a cap of 5, which fade COMBO_POINT_DURATION later.
static func award_combo(w: RpgEncounter, p: Dictionary, _target: Dictionary, points: int) -> void:
	p["combo_points"] = mini(5, int(p.get("combo_points", 0)) + points)
	p["combo_until"] = w.time + float(w.pack["constants"]["combo_point_duration"])


## updateComboExpiry.
static func combo_expiry(w: RpgEncounter, p: Dictionary) -> void:
	if int(p.get("combo_points", 0)) > 0 and w.time >= float(p.get("combo_until", 0.0)):
		p["combo_points"] = 0


# -- engines (rogue_engines.ts) ---------------------------------------------------------


static func _add_stage(
	w: RpgEncounter, p: Dictionary, id: String, kind: String, duration: float, cap: int
) -> void:
	var existing := _mine(p, id)
	if not existing.is_empty():
		existing["stacks"] = mini(cap, int(existing.get("stacks", 1)) + 1)
		existing["remaining"] = duration
		existing["duration"] = duration
		return
	var aura := _aura(id, kind, duration, 0.0, p, "physical")
	aura["stacks"] = 1
	RpgCombat.apply_aura(w, p, aura)


## rogueEngineOnFinisher: a four-point Eviscerate opens combat's Redline.
static func on_finisher(w: RpgEncounter, p: Dictionary, ability_id: String, spent: int) -> void:
	if spent < 4 or ability_id != "eviscerate":
		return
	if p["spec_id"] == "combat" and _mine(p, REDLINE_ID).is_empty():
		var run := _aura(REDLINE_ID, "redline", REDLINE_DURATION, KNOCKOUT_PER_PIP, p, "physical")
		run["stacks"] = 1
		RpgCombat.apply_aura(w, p, run)


## rogueEngineOnCast.
static func engine_on_cast(
	w: RpgEncounter, p: Dictionary, ability_id: String, target: Dictionary
) -> void:
	if p.get("class_id") != "rogue":
		return
	var spec := str(p["spec_id"])
	if spec == "combat":
		if ability_id == BODY_BLOW_ID:
			var run := _mine(p, REDLINE_ID)
			if not run.is_empty():
				run["stacks"] = mini(REDLINE_MAX_DEPTH, int(run.get("stacks", 1)) + 1)
		return
	if spec == "assassination":
		if ability_id == "venom_dart":
			_add_stage(
				w, p, VENOM_RITUAL_ID, "venom_ritual", VENOM_RITUAL_DURATION, VENOM_RITUAL_STAGES
			)
			_refund(p)
			if not target.is_empty():
				var wound := {}
				for a: Dictionary in target["auras"]:
					if a["id"] == "venomrend" and a["source_id"] == p["id"]:
						wound = a
				if not wound.is_empty():
					wound["remaining"] = minf(
						VENOM_WOUND_CAP, float(wound["remaining"]) + VENOM_DART_EXTEND
					)
					wound["duration"] = maxf(float(wound["duration"]), float(wound["remaining"]))
			return
		if ability_id == "backstab" or ability_id == "sinister_strike":
			_add_stage(
				w, p, VENOM_RITUAL_ID, "venom_ritual", VENOM_RITUAL_DURATION, VENOM_RITUAL_STAGES
			)
			if ability_id == "backstab":
				_refund(p)
		return
	if spec != "subtlety":
		return
	if ability_id in DUSK_OPENER_IDS:
		if not veil_allows_stealth_abilities(p):
			_add_stage(w, p, GLOAM_ID, "gloam", GLOAM_DURATION, GLOAM_STAGES)
		return
	if ability_id == "hemorrhage":
		var counters: Dictionary = RpgTalentProcs._state(p)["counters"]
		var count := int(counters.get(GLOAM_RHYTHM_KEY, 0)) + 1
		if count >= GLOAM_RHYTHM_EVERY:
			counters[GLOAM_RHYTHM_KEY] = 0
			_add_stage(w, p, GLOAM_ID, "gloam", GLOAM_DURATION, GLOAM_STAGES)
		else:
			counters[GLOAM_RHYTHM_KEY] = count


static func _refund(p: Dictionary) -> void:
	if p["resource_type"] == "energy":
		p["resource"] = minf(float(p["max_resource"]), float(p["resource"]) + VENOM_STAGE_REFUND)


static func gloam_bank_armed(p: Dictionary) -> bool:
	return int(_mine(p, GLOAM_ID).get("stacks", 0)) >= GLOAM_STAGES


static func veil_allows_stealth_abilities(p: Dictionary) -> bool:
	return not _mine(p, VEILSTRIKE_ID).is_empty()


## The veil waives the behind requirement (castAbility: veilAllowsStealthAbilities or
## an armed Gloam bank, outside true stealth).
static func veil_waives_behind(_w: RpgEncounter, p: Dictionary) -> bool:
	return veil_allows_stealth_abilities(p) or gloam_bank_armed(p)


## rogueGloamDetonation (runEffects' preamble): a subtlety opener outside stealth
## with a full bank spends it for the Shadow Veil and Veiled Edge.
static func gloam_detonation(w: RpgEncounter, p: Dictionary, ability_id: String) -> void:
	if not ability_id in DUSK_OPENER_IDS or p.get("spec_id") != "subtlety":
		return
	if RpgStealth.is_stealthed(p) or veil_allows_stealth_abilities(p) or not gloam_bank_armed(p):
		return
	RpgAbilityRules.remove_aura(w, p, _mine(p, GLOAM_ID))
	RpgCombat.apply_aura(w, p, _aura(VEILSTRIKE_ID, "buff_dmg_done", 6.0, 0.1, p, "shadow"))
	RpgCombat.apply_aura(
		w, p, _aura(VEILED_EDGE_ID, "veiled_edge", 6.0, VEILED_EDGE_BONUS, p, "shadow")
	)
	_dusk_linger_after_veil(w, p)
	w.recalc_player()


static func _dusk_linger_after_veil(w: RpgEncounter, p: Dictionary) -> void:
	if float(p["mods"]["global"]["duskEconomyPct"]) <= 0.0:
		return
	for a: Dictionary in p["auras"]:
		if a["id"] == DUSK_ECONOMY_AURA_ID:
			a["remaining"] = maxf(float(a["remaining"]), 6.0)
			a["duration"] = maxf(float(a["duration"]), 6.0)
			return
	RpgCombat.apply_aura(w, p, _aura(DUSK_ECONOMY_AURA_ID, "dusk_economy", 6.0, 0.5, p, "shadow"))


## detonatorFreeMultiplier: 0 (free) for the opener that detonates a full bank, or -1.
static func detonator_free_mult(p: Dictionary, ability_id: String) -> float:
	if not ability_id in DUSK_OPENER_IDS or p.get("spec_id") != "subtlety":
		return -1.0
	if RpgStealth.is_stealthed(p) or veil_allows_stealth_abilities(p):
		return -1.0
	return 0.0 if gloam_bank_armed(p) else -1.0


## knockoutRedlineMult: Knockout Blow spends the Redline run, 1 + 0.25 per pip past
## the first.
static func knockout_redline_mult(w: RpgEncounter, p: Dictionary, ability_id: String) -> float:
	if ability_id != KNOCKOUT_ID:
		return 1.0
	var run := _mine(p, REDLINE_ID)
	if run.is_empty():
		return 1.0
	RpgAbilityRules.remove_aura(w, p, run)
	return 1.0 + float(run["value"]) * (int(run.get("stacks", 1)) - 1)


## consumeVeiledEdge: Ambush spends the Veiled Edge (x 1 + its value).
static func consume_veiled_edge(w: RpgEncounter, p: Dictionary, ability_id: String) -> float:
	if ability_id != "ambush":
		return 1.0
	var edge := _mine(p, VEILED_EDGE_ID)
	if edge.is_empty():
		return 1.0
	RpgAbilityRules.remove_aura(w, p, edge)
	return 1.0 + float(edge["value"])


## capturedTrueStealthAmbush: a subtlety Ambush from true stealth.
static func true_stealth_ambush(p: Dictionary, ability_id: String) -> bool:
	return ability_id == "ambush" and p.get("spec_id") == "subtlety" and RpgStealth.is_stealthed(p)


## cleanRogueEngineState: a spec change drops the engines' auras and rhythm.
static func clean_engine_state(w: RpgEncounter, p: Dictionary) -> void:
	var ids := [VENOM_RITUAL_ID, REDLINE_ID, GLOAM_ID, VEILSTRIKE_ID, VEILED_EDGE_ID]
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["source_id"] == p["id"] and a["id"] in ids:
			RpgAbilityRules.remove_aura(w, p, a)
	if p.get("proc_state") is Dictionary:
		p["proc_state"]["counters"].erase(GLOAM_RHYTHM_KEY)


# -- Dusk Economy (rogue_talents.ts) ----------------------------------------------------


## duskCostMultiplier: 1 - duskEconomyPct while stealthed, lingering, or veiled; or -1.
static func dusk_cost_mult(p: Dictionary) -> float:
	var pct := float(p["mods"]["global"]["duskEconomyPct"]) if p.get("kind") == "player" else 0.0
	if pct <= 0.0:
		return -1.0
	for a: Dictionary in p["auras"]:
		if a["kind"] == "stealth":
			return 1.0 - pct
		if a["id"] == DUSK_ECONOMY_AURA_ID and a["kind"] == "dusk_economy":
			return 1.0 - pct
		if a["id"] == VEILSTRIKE_ID and a["source_id"] == p["id"]:
			return 1.0 - pct
	return -1.0


## combineCostMultipliers (-1 is "none").
static func combine(a: float, b: float) -> float:
	if a < 0.0:
		return b
	if b < 0.0:
		return a
	return a * b


## duskLingerOnStealthBreak, then the mage's Greater Invisibility aftereffect.
static func on_stealth_broken(w: RpgEncounter, u: Dictionary, aura: Dictionary) -> void:
	if u.get("kind") == "player" and float(u["mods"]["global"]["duskEconomyPct"]) > 0.0:
		var pct := float(u["mods"]["global"]["duskEconomyPct"])
		var existing := {}
		for a: Dictionary in u["auras"]:
			if a["id"] == DUSK_ECONOMY_AURA_ID:
				existing = a
		if not existing.is_empty():
			existing["remaining"] = DUSK_ECONOMY_LINGER_SEC
			existing["duration"] = DUSK_ECONOMY_LINGER_SEC
		else:
			RpgCombat.apply_aura(
				w,
				u,
				_aura(
					DUSK_ECONOMY_AURA_ID, "dusk_economy", DUSK_ECONOMY_LINGER_SEC, pct, u, "shadow"
				)
			)
	RpgMage.greater_invisibility_aftereffect(w, u, aura)


## foulPlayGuardsBreak: an incapacitate of the rogue's own survives its periodic harm.
static func foul_play_guards(source: Dictionary, breakable: Dictionary, direct: bool) -> bool:
	if direct or breakable["kind"] != "incapacitate" or source.is_empty():
		return false
	if breakable["source_id"] != source["id"] or source["kind"] != "player":
		return false
	return float(source["mods"]["global"]["foulPlayGuard"]) > 0.0


# -- stealth (effect_dispatch.ts, threat.ts) ---------------------------------------------


## The selfBuff arm's stealth tail. Vanish drops the caster from every monster's
## focus (dropSelfFromHostileFocus); any stealth makes the monsters drop it as a
## target (dropTargetsOnStealth). On the street a monster that loses the player
## stops pursuing (ADAPTED: there is no threat table to fall back on).
static func on_stealth_entered(w: RpgEncounter, p: Dictionary, def: Dictionary) -> void:
	if def["id"] == "vanish":
		p["combat_timer"] = 5.0
		p["in_combat"] = false
		p["auto_attack"] = false
		p["queued_on_swing"] = ""
		RpgWorld.set_target(w, {})
		for m: Dictionary in w.mobs:
			m["engaged"] = false


## hasEscapeStealth: Vanish's stealth makes the player undetectable.
static func has_escape_stealth(u: Dictionary) -> bool:
	for a: Dictionary in u["auras"]:
		if a["id"] == "vanish" and a["kind"] == "stealth":
			return true
	return false


## stealthDetectionMultiplier: 0.25 at equal level, +0.08 per level the observer is
## above, within [0.1, 1].
static func detection_mult(observer_level: int, stealthed_level: int) -> float:
	return clampf(0.25 + (observer_level - stealthed_level) * 0.08, 0.1, 1.0)


## vanishedLowBlowFallbackTarget: a stealthed Kidney Shot with no target takes the
## nearest hostile in melee range.
static func low_blow_fallback(w: RpgEncounter, p: Dictionary, def: Dictionary) -> Dictionary:
	if def["id"] != "kidney_shot" or not RpgStealth.is_stealthed(p):
		return {}
	var near := {}
	var best := INF
	for m: Dictionary in w.mobs:
		if m["dead"]:
			continue
		var d := absf(float(m["x"]) - float(p["x"]))
		if d > float(w.pack["constants"]["melee_range"]) or d >= best:
			continue
		near = m
		best = d
	return near
