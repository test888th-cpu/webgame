class_name RpgTalents
extends RefCounted
## Specializations, talents and the spellbook, as World of ClaudeCraft computes them
## (d2b91e08). Ports of:
## * content/talents.ts repairAllocation, computeTalentModifiers, accumulateTalentEffect;
## * content/classes.ts abilitiesKnownAt, applyTalentMods, scaleEffect;
## * talent_hit_mult.ts resolveTalentHitMult, spec_output_tuning.ts offensiveAbilityBonus.
## The data (talent trees, spec masteries and baselines, ability definitions) is the
## runtime pack's, evaluated from the source. tests/unit/test_rpg_talents.gd compares
## these ports with the source functions' own answers (rpg_talent_parity.json).
##
## An allocation is {spec: id or "", rows: {"5": option id, ...}}; one option per row,
## a row available from its level (repairAllocation drops anything else).

## accumulateTalentEffect takes the max, not the sum, of these.
const MAX_GLOBAL_KEYS: Array[String] = ["cheatDeathIcd", "castPushbackReduction"]
const INTEGRAL_BUFF_KINDS: Array[String] = [
	"buff_ap",
	"buff_armor",
	"buff_int",
	"buff_agi",
	"buff_sta",
	"buff_allstats",
	"buff_spellpower",
	"thorns",
]
const SCALABLE_BUFF_KINDS: Array[String] = [
	"buff_ap",
	"buff_armor",
	"buff_int",
	"buff_agi",
	"buff_spi",
	"buff_sta",
	"buff_allstats",
	"buff_spellpower",
	"thorns",
]


## JavaScript's Math.round: halves go up (floor(x + 0.5)).
static func js_round(x: float) -> float:
	return floorf(x + 0.5)


static func class_talents(pack: Dictionary, cls: String) -> Dictionary:
	return pack.get("talents", {}).get(cls, {"specs": [], "rows": []})


static func spec_def(pack: Dictionary, cls: String, spec_id: String) -> Dictionary:
	for s: Dictionary in class_talents(pack, cls)["specs"]:
		if s["id"] == spec_id:
			return s
	return {}


## repairAllocation: the spec only from SPEC_UNLOCK_LEVEL and only a real one; each
## row only at or above its level and only one of its own options.
static func repair(pack: Dictionary, cls: String, alloc: Dictionary, level: int) -> Dictionary:
	var spec := str(alloc.get("spec", ""))
	var unlock := int(pack["constants"]["spec_unlock_level"])
	if level < unlock or spec_def(pack, cls, spec).is_empty():
		spec = ""
	var rows := {}
	var chosen: Dictionary = alloc.get("rows", {}) if alloc.get("rows") is Dictionary else {}
	for row: Dictionary in class_talents(pack, cls)["rows"]:
		var key := str(int(row["level"]))
		var option := str(chosen.get(key, ""))
		if level < int(row["level"]) or option == "":
			continue
		for o: Dictionary in row["options"]:
			if o["id"] == option:
				rows[key] = option
	return {"spec": spec, "rows": rows}


## computeTalentModifiers.
static func mods_for(pack: Dictionary, cls: String, alloc: Dictionary, level: int) -> Dictionary:
	var mods: Dictionary = pack["empty_modifiers"].duplicate(true)
	mods["spec"] = null
	mods["role"] = null
	var tree := class_talents(pack, cls)
	if tree["specs"].is_empty():
		return mods
	var fixed := repair(pack, cls, alloc, level)
	var spec := spec_def(pack, cls, fixed["spec"])
	if not spec.is_empty():
		mods["spec"] = spec["id"]
		mods["role"] = spec["role"]
		for ability: String in spec["signature_ids"]:
			mods["grants"].append({"ability": ability, "rank": 1})
		accumulate(mods, spec.get("mastery_effect"), minf(1.0, maxf(0.0, level) / 20.0))
		accumulate(mods, spec.get("baseline"))
	for row: Dictionary in tree["rows"]:
		var option_id := str(fixed["rows"].get(str(int(row["level"])), ""))
		if option_id == "":
			continue
		for o: Dictionary in row["options"]:
			if o["id"] == option_id:
				mods["selected"][option_id] = true
				accumulate(mods, o.get("effect"))
	return mods


## accumulateTalentEffect: stats and globals add (two globals take the max), ability
## mods add per ability, grants and procs append.
static func accumulate(mods: Dictionary, effect: Variant, multiplier := 1.0) -> void:
	if not (effect is Dictionary):
		return
	var e: Dictionary = effect
	if e.get("stats") is Dictionary:
		for key: String in mods["stats"]:
			mods["stats"][key] = (
				float(mods["stats"][key]) + float(e["stats"].get(key, 0)) * multiplier
			)
	if e.get("global") is Dictionary:
		for key: String in mods["global"]:
			var v := float(e["global"].get(key, 0))
			if key in MAX_GLOBAL_KEYS:
				mods["global"][key] = maxf(float(mods["global"][key]), v)
			else:
				mods["global"][key] = float(mods["global"][key]) + v * multiplier
	for a: Dictionary in e.get("ability", []):
		var id := str(a["ability"])
		if not mods["abilities"].has(id):
			mods["abilities"][id] = _zero_ability_mod()
		var t: Dictionary = mods["abilities"][id]
		for key: String in [
			"dmgPct",
			"dmgPctVsDotted",
			"flatDmg",
			"costPct",
			"cooldownPct",
			"cooldownFlat",
			"castPct",
			"buffPct",
			"durationFlat",
			"critPct",
			"bonusCharges"
		]:
			t[key] = float(t[key]) + float(a.get(key, 0)) * multiplier
		if a.get("dmgPctVsDottedAbility") != null:
			t["dmgPctVsDottedAbility"] = a["dmgPctVsDottedAbility"]
		for flag: String in ["castWhileMoving", "damagePushbackImmune", "ignoreStealthRequirement"]:
			if a.get(flag, false):
				t[flag] = true
		for added: Variant in a.get("addEffects", []):
			t["addEffects"].append(added)
	if e.get("grant") is Dictionary:
		mods["grants"].append({"ability": e["grant"]["ability"], "rank": e["grant"].get("rank", 1)})
	if e.get("proc") != null:
		mods["procs"].append(e["proc"])


static func _zero_ability_mod() -> Dictionary:
	return {
		"dmgPct": 0.0,
		"dmgPctVsDotted": 0.0,
		"flatDmg": 0.0,
		"costPct": 0.0,
		"cooldownPct": 0.0,
		"cooldownFlat": 0.0,
		"castPct": 0.0,
		"buffPct": 0.0,
		"durationFlat": 0.0,
		"critPct": 0.0,
		"castWhileMoving": false,
		"damagePushbackImmune": false,
		"ignoreStealthRequirement": false,
		"bonusCharges": 0.0,
		"addEffects": [],
	}


## resolveTalentHitMult (with offensiveAbilityBonus).
static func hit_mult(pack: Dictionary, def: Dictionary, mods: Dictionary) -> Dictionary:
	var am: Dictionary = mods["abilities"].get(def["id"], {})
	var physical: bool = def.get("school") == "physical" or def.get("scalesWith") == "ranged"
	var global_dmg := float(
		mods["global"]["meleeDmgPct"] if physical else mods["global"]["spellDmgPct"]
	)
	var legacy := 1.0 + global_dmg + float(am.get("dmgPct", 0.0))
	var bonus := 0.0
	if mods["spec"] != null:
		var tuning: Dictionary = pack["offensive_spec_tuning"].get(str(def.get("class")), {}).get(
			str(mods["spec"]), {}
		)
		bonus = float(tuning.get("physical" if physical else "spell", 0.0))
	return {
		"dmg": legacy + bonus,
		"heal": 1.0 + float(mods["global"]["healPct"]) + float(am.get("dmgPct", 0.0)),
		"legacy": legacy,
	}


## abilitiesKnownAt(cls, level, mods): [{id, def, rank, cost, castTime, cooldown,
## effects, threatFlat, threatMult, bonusCharges, charges?}] in spellbook order.
static func known(pack: Dictionary, cls: String, level: int, mods: Dictionary) -> Array:
	var out: Array = []
	var base_ids: Array = pack["classes"][cls]["kit_abilities"]
	var ids: Array = base_ids.duplicate()
	var grant_ids := {}
	for g: Dictionary in mods["grants"]:
		grant_ids[g["ability"]] = true
	for g: Dictionary in mods["grants"]:
		if not g["ability"] in ids:
			ids.append(g["ability"])
	var spec: Variant = mods["spec"]
	for id: String in ids:
		var entry_doc: Dictionary = pack["abilities"].get(id, {})
		if entry_doc.is_empty():
			continue
		var def: Dictionary = entry_doc["def"]
		if def.get("hiddenFromPlayer", false):
			continue
		var granted: bool = grant_ids.has(id) or not id in base_ids
		var paladin_kit := cls == "paladin" and id in base_ids
		if (not granted or paladin_kit) and int(def["learnLevel"]) > level:
			continue
		if not granted and def.get("requiresQuest") != null:
			continue  # no reference quest is ever done in the trial
		if not granted and def.get("specs") != null:
			if spec == null or not spec in def["specs"]:
				continue
		if (
			not granted
			and def.get("excludeSpecs") != null
			and spec != null
			and spec in def["excludeSpecs"]
			and level >= int(def.get("excludeSpecsAtLevel", 0))
		):
			continue
		var entry := _resolve_ranks(def, level)
		if id == "execute" and spec == "arms":
			entry["cost"] = 10.0
		if id == "execute" and spec == "fury":
			entry["cost"] = 0.0
			entry["effects"] = entry["effects"] + [{"type": "gainResource", "amount": 20}]
			entry["cooldown"] = 6.0
		if id == "drain_life" and spec == "affliction":
			var fx: Array = []
			for e: Dictionary in entry["effects"]:
				var copy := e.duplicate(true)
				if copy["type"] == "drainTick":
					copy["healFrac"] = 1
				fx.append(copy)
			entry["effects"] = fx
		if def.get("maxCharges") != null:
			entry["charges"] = int(def["maxCharges"])
			entry["bonusCharges"] = maxi(0, int(def["maxCharges"]) - 1)
		if id == "ice_block" and spec == "frost":
			entry["charges"] = 2
			entry["bonusCharges"] = 1
		apply_talent_mods(pack, entry, mods)
		out.append(entry)
	return out


static func _resolve_ranks(def: Dictionary, level: int) -> Dictionary:
	var entry := {
		"id": def["id"],
		"def": def,
		"rank": 1,
		"cost": float(def["cost"]),
		"castTime": float(def["castTime"]),
		"cooldown": float(def["cooldown"]),
		"effects": (def["effects"] as Array).duplicate(true),
		"threatFlat": float(def.get("threat", {}).get("flat", 0)),
		"threatMult": float(def.get("threat", {}).get("mult", 1)),
		"bonusCharges": 0,
	}
	for r: Dictionary in def.get("ranks", []):
		if int(r["level"]) <= level:
			entry["rank"] = int(r["rank"])
			entry["cost"] = float(r["cost"])
			entry["effects"] = (r["effects"] as Array).duplicate(true)
			if r.get("castTime") != null:
				entry["castTime"] = float(r["castTime"])
			if r.get("threatFlat") != null:
				entry["threatFlat"] = float(r["threatFlat"])
	return entry


## applyTalentMods (the set-bonus branches need set items, which the trial has none of).
static func apply_talent_mods(pack: Dictionary, entry: Dictionary, mods: Dictionary) -> void:
	var def: Dictionary = entry["def"]
	var am: Dictionary = mods["abilities"].get(def["id"], {})
	var m := hit_mult(pack, def, mods)
	var dot_mult := 1.0 + float(mods["global"]["dotDmgPct"])
	var hot_mult := 1.0 + float(mods["global"]["hotHealPct"])
	var absorb_mult := 1.0 + float(mods["global"]["absorbPct"])
	var flat := float(am.get("flatDmg", 0.0))
	if not am.is_empty() and not (am["addEffects"] as Array).is_empty():
		for added: Dictionary in am["addEffects"]:
			entry["effects"].append(added.duplicate(true))
	if (
		m["dmg"] != 1.0
		or m["heal"] != 1.0
		or dot_mult != 1.0
		or hot_mult != 1.0
		or absorb_mult != 1.0
		or flat != 0.0
	):
		var scaled: Array = []
		for e: Dictionary in entry["effects"]:
			scaled.append(
				scale_effect(
					e, m["dmg"], m["heal"], dot_mult, hot_mult, absorb_mult, flat, m["legacy"]
				)
			)
		entry["effects"] = scaled
	if am.is_empty():
		return
	if am["costPct"]:
		entry["cost"] = maxf(0.0, js_round(entry["cost"] * (1.0 + am["costPct"])))
	if am["castPct"]:
		entry["castTime"] = maxf(0.0, entry["castTime"] * (1.0 + am["castPct"]))
	if am["cooldownPct"]:
		entry["cooldown"] = maxf(0.0, entry["cooldown"] * (1.0 + am["cooldownPct"]))
	if am["cooldownFlat"]:
		entry["cooldown"] = maxf(0.0, entry["cooldown"] + am["cooldownFlat"])
	if am["durationFlat"]:
		for e: Dictionary in entry["effects"]:
			if e["type"] in ["selfBuff", "buffTarget", "absorb", "hot", "enrageChance"]:
				e["duration"] = maxf(0.0, float(e["duration"]) + am["durationFlat"])
	for flag: String in ["castWhileMoving", "damagePushbackImmune", "ignoreStealthRequirement"]:
		if am[flag]:
			entry[flag] = true
	if am["bonusCharges"]:
		entry["bonusCharges"] = int(entry.get("bonusCharges", 0)) + int(am["bonusCharges"])
		entry["charges"] = int(entry.get("charges", 1)) + int(am["bonusCharges"])
	if am["buffPct"]:
		_scale_buffs(entry, 1.0 + am["buffPct"])


static func _scale_buffs(entry: Dictionary, mul: float) -> void:
	for e: Dictionary in entry["effects"]:
		match str(e["type"]):
			"selfBuff", "buffTarget":
				var v := float(e["value"]) * mul
				e["value"] = js_round(v) if str(e["kind"]) in INTEGRAL_BUFF_KINDS else v
			"finisherHaste":
				e["mult"] = 1.0 + (float(e["mult"]) - 1.0) * mul
			"imbue":
				e["bonus"] = js_round(float(e["bonus"]) * mul)
				_scale_coat(e, mul)
			"absorbSpentResource":
				e["mult"] = js_round(float(e["mult"]) * mul)
			"absorb":
				e["amount"] = js_round(float(e["amount"]) * mul)
				if e.get("casterMaxHpPct") != null:
					e["casterMaxHpPct"] = (
						js_round(float(e["casterMaxHpPct"]) * mul * 10000.0) / 10000.0
					)


static func _scale_coat(e: Dictionary, mul: float) -> void:
	var coat: Variant = e.get("coat")
	if coat is Dictionary and coat.get("rider") == "stackDot":
		coat["perTick"] = float(coat["perTick"]) * mul


static func _r(v: Variant, mult: float, flat := 0.0) -> float:
	return js_round(float(v) * mult + flat)


## scaleEffect.
static func scale_effect(
	eff: Dictionary,
	dmg: float,
	heal: float,
	dot: float,
	hot: float,
	absorb: float,
	flat: float,
	buff_dmg: float
) -> Dictionary:
	var e := eff.duplicate(true)
	match str(e["type"]):
		"weaponDamage":
			e["bonus"] = _r(e["bonus"], dmg, flat)
		"weaponStrike":
			e["bonus"] = _r(e["bonus"], dmg, flat)
			e["weaponMult"] = float(e.get("weaponMult", 1)) * dmg
		"directDamage", "chainDamage", "groundAoE":
			if e["type"] == "groundAoE" and e.get("allyBuffPct") != null:
				return e
			e["min"] = _r(e["min"], dmg, flat)
			e["max"] = _r(e["max"], dmg, flat)
		"dot":
			if e.get("directPct") != null:
				return e
			e["total"] = _r(e["total"], dmg * dot, flat)
			if e.get("perComboTotal") != null:
				e["baseTotal"] = _r(e.get("baseTotal", 0), dmg * dot, flat)
				e["perComboTotal"] = _r(e["perComboTotal"], dmg * dot)
		"aoeDamage", "aoeHeal":
			var mult := heal if e["type"] == "aoeHeal" else dmg
			e["min"] = _r(e["min"], mult, flat)
			e["max"] = _r(e["max"], mult, flat)
		"sporeBurst":
			e["min"] = _r(e["min"], dmg, flat)
			e["max"] = _r(e["max"], dmg, flat)
			e["healMin"] = _r(e["healMin"], heal, flat)
			e["healMax"] = _r(e["healMax"], heal, flat)
		"aoeRoot", "drainTick":
			e["min"] = _r(e["min"], dmg)
			e["max"] = _r(e["max"], dmg)
		"afflictionSentence":
			e["damageMult"] = float(e.get("damageMult", 1)) * dmg
			e["flat"] = float(e.get("flat", 0)) + flat
		"afflictionViolence", "afflictionLitany":
			e["damage"] = _r(e["damage"], dmg, flat)
		"finisherDamage":
			e["base"] = _r(e["base"], dmg, flat)
			e["perCombo"] = _r(e["perCombo"], dmg)
		"imbue":
			e["bonus"] = _r(e["bonus"], dmg, flat)
			_scale_coat(e, dmg)
		"heal", "chainHeal":
			if e["type"] == "heal" and e.get("casterMaxHpPct") != null:
				return e
			e["min"] = _r(e["min"], heal, flat)
			e["max"] = _r(e["max"], heal, flat)
		"paladinAegis":
			e["tickMin"] = _r(e["tickMin"], heal, flat)
			e["tickMax"] = _r(e["tickMax"], heal, flat)
			e["finalMin"] = _r(e["finalMin"], heal)
			e["finalMax"] = _r(e["finalMax"], heal)
		"massTemporalEcho":
			e["heal"] = {
				"min": _r(e["heal"]["min"], heal, flat), "max": _r(e["heal"]["max"], heal, flat)
			}
		"hot":
			e["total"] = _r(e["total"], heal * hot, flat)
		"consumeAura":
			_scale_consume_aura(e, dmg, heal, flat)
		"absorb":
			e["amount"] = _r(e["amount"], heal * absorb, flat)
			if e.get("casterMaxHpPct") != null:
				e["casterMaxHpPct"] = (
					js_round(float(e["casterMaxHpPct"]) * heal * absorb * 10000.0) / 10000.0
				)
		"aoeAllyAbsorb":
			e["amount"] = _r(e["amount"], heal * absorb, flat)
		"buffTarget", "selfBuff":
			if str(e["kind"]) in SCALABLE_BUFF_KINDS:
				e["value"] = _r(e["value"], buff_dmg, flat)
		"hunterBloodhook", "hunterShrapnel":
			e["damageMult"] = float(e.get("damageMult", 1)) * dmg
		"repositionToAim":
			if e.get("landingAoe") is Dictionary:
				e["landingAoe"]["min"] = _r(e["landingAoe"]["min"], dmg, flat)
				e["landingAoe"]["max"] = _r(e["landingAoe"]["max"], dmg, flat)
	return e


static func _scale_consume_aura(e: Dictionary, dmg: float, heal: float, flat: float) -> void:
	var deal: Variant = e.get("deal")
	if deal is Dictionary:
		e["deal"] = {"min": _r(deal["min"], dmg, flat), "max": _r(deal["max"], dmg, flat)}
	var h: Variant = e.get("heal")
	if h is Dictionary:
		var f := 0.0 if deal is Dictionary else flat
		e["heal"] = {"min": _r(h["min"], heal, f), "max": _r(h["max"], heal, f)}
