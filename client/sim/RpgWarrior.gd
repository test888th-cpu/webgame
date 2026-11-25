class_name RpgWarrior
extends RefCounted
## The warrior's mechanics (src/sim/combat/warrior_stances.ts, auto_attack.ts
## procs, effect_dispatch.ts warrior branches, damage.ts kill windows,
## casting_lifecycle.ts Colossal Might).

const WARRIOR_STANCE_KINDS: Array[String] = [
	"battle_stance", "defensive_stance", "berserker_stance"
]


## warriorAbilityRageMult: 1 for anyone but a rage-using warrior.
static func ability_rage_mult(w: RpgEncounter, p: Dictionary) -> float:
	if p.get("class_id") != "warrior" or p["resource_type"] != "rage":
		return 1.0
	return (1.0 + float(p["mods"]["global"]["abilityRagePct"])) * w.rage_aura_mult(p)


## availableWarriorStanceKinds / defaultWarriorStanceId.
static func available_stances(spec: String) -> Array:
	if spec == "fury":
		return ["berserker_stance"]
	if spec == "arms" or spec == "prot":
		return ["battle_stance", "defensive_stance"]
	return ["battle_stance"]


static func default_stance(spec: String) -> String:
	return "berserker_stance" if spec == "fury" else "battle_stance"


## ensureWarriorStance: a warrior always wears a stance its spec allows (the
## default one when it wears none it may keep).
static func ensure_stance(w: RpgEncounter, p: Dictionary) -> void:
	if p["class_id"] != "warrior":
		return
	var spec := str(p["spec_id"])
	var worn: Array = []
	for a: Dictionary in p["auras"]:
		if str(a["kind"]) in WARRIOR_STANCE_KINDS:
			worn.append(a["kind"])
	var allowed := available_stances(spec)
	for k: String in worn:
		if k in allowed:
			return
	var auras: Array = p["auras"]
	for i in range(auras.size() - 1, -1, -1):
		if str(auras[i]["kind"]) in worn:
			var gone: Dictionary = auras[i]
			auras.remove_at(i)
			w.log_event({"type": "aura", "target": p["id"], "name": gone["id"], "gained": false})
	var id := default_stance(spec)
	var def: Dictionary = w.pack["abilities"].get(id, {}).get("def", {})
	for e: Dictionary in def.get("effects", []):
		if e["type"] != "selfBuff":
			continue
		(
			RpgCombat
			. apply_aura(
				w,
				p,
				{
					"id": id,
					"kind": str(e["kind"]),
					"remaining": float(e["duration"]),
					"duration": float(e["duration"]),
					"value": float(e["value"]),
					"source_id": p["id"],
					"school": def["school"],
				}
			)
		)
		return


## runEffects' warrior preamble: Red Harvest (with Cleaving Blows known) hands a
## Raging Gale charge back; Battle Rhythm grants a one-tick rage boost every third
## ability.
static func before_effects(w: RpgEncounter, p: Dictionary, def: Dictionary) -> void:
	if def["id"] == "red_harvest" and _knows_passive(w, "cleaving_blows"):
		var s: Dictionary = p.get("ability_charges", {}).get("raging_gale", {})
		if not s.is_empty() and int(s["charges"]) < int(s["max"]):
			s["charges"] = int(s["charges"]) + 1
			if not (s["recharges"] as Array).is_empty():
				s["recharges"].pop_back()
			p["cooldowns"].erase("raging_gale")
	if float(p["mods"]["global"]["battleRhythm"]) > 0.0:
		p["ability_rhythm"] = (int(p.get("ability_rhythm", 0)) + 1) % 3
		if int(p["ability_rhythm"]) == 0:
			(
				RpgCombat
				. apply_aura(
					w,
					p,
					{
						"id": "battle_rhythm_rage",
						"kind": "buff_rage_gen",
						"value": 0.2,
						"remaining": w.dt,
						"duration": w.dt,
						"source_id": p["id"],
						"school": def["school"],
					}
				)
			)


static func _knows_passive(w: RpgEncounter, id: String) -> bool:
	var k := w.known_entry(id)
	return not k.is_empty() and k["def"].get("passive", false)


## The weaponStrike arm's warrior cases: Mortal Strike spends Overpower's charge
## (x 1 + value x stacks); an enraged Raging Gale with Diabolical Twinstrike hits
## 15% harder. Returns [weapon_mult, bonus].
static func shape_weapon_strike(
	w: RpgEncounter, p: Dictionary, ability_id: String, mult: float, bonus: float
) -> Array:
	if ability_id == "mortal_strike":
		var charge := RpgAbilityRules.find_kind(p, "overpower_charge")
		if not charge.is_empty():
			mult *= 1.0 + float(charge["value"]) * int(charge.get("stacks", 1))
			RpgAbilityRules.remove_aura(w, p, charge)
	if (
		ability_id == "raging_gale"
		and RpgAbilityRules.has_kind(p, "enrage")
		and _knows_passive(w, "diabolical_twinstrike")
	):
		mult *= 1.15
		bonus = RpgTalents.js_round(bonus * 1.15)
	return [mult, bonus]


## maybeProcBattleTrance / maybeProcSuddenDeath on every connected warrior swing.
static func swing_procs(w: RpgEncounter, p: Dictionary, connected: bool) -> void:
	if not connected or p["class_id"] != "warrior":
		return
	var c: Dictionary = w.pack["constants"]
	var proc := w.rng.chance(float(RpgPack.swing(w.pack)["battle_trance_chance"]))
	if proc and p["spec_id"] != "fury":
		_proc(w, p, "battle_trance", float(c["battle_trance_duration"]))
	if p["spec_id"] != "arms" or not _knows_passive(w, "sudden_death"):
		return
	if w.rng.chance(float(RpgPack.swing(w.pack)["sudden_death_chance"])):
		_proc(w, p, "sudden_death", float(c["sudden_death_duration"]))


static func _proc(w: RpgEncounter, p: Dictionary, id: String, duration: float) -> void:
	(
		RpgCombat
		. apply_aura(
			w,
			p,
			{
				"id": id,
				"kind": id,
				"remaining": duration,
				"duration": duration,
				"value": 0.0,
				"source_id": p["id"],
				"school": "physical",
			}
		)
	)


## stanceMasteryAutoHaste.
static func stance_mastery_haste(w: RpgEncounter, p: Dictionary) -> float:
	if p["class_id"] != "warrior" or not RpgAbilityRules.has_kind(p, "berserker_stance"):
		return 0.0
	if float(p["mods"]["global"]["stanceMastery"]) <= 0.0:
		return 0.0
	return float(w.pack["constants"]["stance_mastery_berserker_haste"])


## The kill credit's warrior window: Victor's Surge for a warrior granted Victory
## Rush.
static func on_kill(w: RpgEncounter, p: Dictionary) -> void:
	if p["class_id"] != "warrior":
		return
	for g: Dictionary in p["mods"]["grants"]:
		if g["ability"] == "victory_rush":
			var window := float(w.pack["constants"]["victory_rush_window"])
			(
				RpgCombat
				. apply_aura(
					w,
					p,
					{
						"id": "victory_rush",
						"kind": "victory_rush",
						"value": 0.0,
						"remaining": window,
						"duration": window,
						"source_id": p["id"],
						"school": "physical",
					}
				)
			)
			return
