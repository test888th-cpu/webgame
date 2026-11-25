class_name RpgPaladin
extends RefCounted
## The paladin's Devotion and Divine Ascension (src/sim/paladin_devotion.ts), the
## Devotion family choice (combat/paladin_support.ts), the talent counters
## (combat/paladin_talents.ts) and dawnreaver_damage.ts. The procs and the class
## effect arms live in RpgPaladinProcs and RpgPaladinKit. State rides on the player
## as `paladin_devotion` {value, ascension_charges, ascension_remaining,
## out_of_combat_time, block_icd}.

const MAX_DEVOTION := 20
const ASCENSION_CHARGES := 5
const ASCENSION_DURATION := 45.0
const ASCENSION_AURA_ID := "divine_ascension"
const BLOCK_DEVOTION_ICD := 6.0
const DEBT_OF_LIGHT_DEVOTION := 1
const AURA_CHOICE_IDS: Array[String] = ["devotion_ward", "retribution_aura"]
const LONG_DEVOTION_IDS: Array[String] = ["radiant_devotion", "dawn_devotion", "grace_devotion"]
## paladin_support.ts PALADIN_DEVOTION_ABILITY_IDS.
const PALADIN_DEVOTION_ABILITY_IDS: Array[String] = [
	"devotion_ward", "retribution_aura", "radiant_devotion", "dawn_devotion", "grace_devotion"
]
const ASCENSION_ABILITIES := {
	"holy": ["mercy_lance", "dawns_embrace", "radiant_chorus", "solar_invocation"],
	"protection":
	[
		"vowkeeper_strike",
		"bastion_rite",
		"sunward_disc",
		"bastion_sweep",
		"holy_shield",
		"consecration",
		"oath_chain",
		"veilbound_march",
	],
	"retribution":
	[
		"final_edict",
		"dawnfall",
		"faithforged_guard",
		"hammer_of_wrath",
		"guardian_covenant",
		"valkyrs_calling",
	],
}
const DEVOTION_GAIN := {
	"holy": ["mercy_lance", "dawns_embrace", "radiant_chorus", "solar_invocation"],
	"protection": ["vowkeeper_strike", "sunward_disc", "bastion_sweep"],
	"retribution": ["hammer_of_wrath", "final_edict", "dawnfall"],
}
const COMMON_DIRECT_DEVOTION_ABILITIES: Array[String] = [
	"hammer_of_grace",
	"holy_light",
	"flash_of_light",
	"lay_on_hands",
	"exorcism",
	"crusader_strike",
	"holy_shock",
]


static func _jr(x: float) -> int:
	return int(floorf(x + 0.5))


## The paladin's devotion state (entity.ts creates it for every paladin).
static func _state(p: Dictionary) -> Dictionary:
	if p.get("kind") != "player" or p.get("class_id") != "paladin":
		return {}
	if not p.get("paladin_devotion") is Dictionary:
		p["paladin_devotion"] = {
			"value": 0,
			"ascension_charges": 0,
			"ascension_remaining": 0.0,
			"out_of_combat_time": 0.0,
			"block_icd": 0.0,
		}
	return p["paladin_devotion"]


static func _g(p: Dictionary, key: String) -> float:
	return float(p["mods"]["global"].get(key, 0.0))


## dawnreaverDamageMultiplier.
static func dawnreaver_damage_mult(p: Dictionary, ability_id: String) -> float:
	if p.get("class_id") != "paladin" or p.get("spec_id") != "retribution":
		return 1.0
	match ability_id:
		"final_edict", "dawnfall":
			return 2.0
		"hammer_of_wrath":
			return 1.75
		"sun_gods_verdict":
			return 1.5
	return 1.0


static func is_devotion_ability(id: String) -> bool:
	return id in PALADIN_DEVOTION_ABILITY_IDS


## isDivineAscensionActive.
static func ascension_active(p: Dictionary) -> bool:
	var s := _state(p)
	return (
		not s.is_empty()
		and int(s["ascension_charges"]) > 0
		and float(s["ascension_remaining"]) > 0.0
	)


## grantDevotion: whole points up to the cap; nothing while ascended.
static func grant_devotion(p: Dictionary, amount: float) -> int:
	var s := _state(p)
	if s.is_empty() or amount <= 0.0 or ascension_active(p):
		return 0
	var before := int(s["value"])
	s["value"] = mini(MAX_DEVOTION, before + int(floorf(amount)))
	s["out_of_combat_time"] = 0.0
	return int(s["value"]) - before


## grantAbilityDevotion: doubled under Avenging Wrath or Perpetual Sun.
static func grant_ability_devotion(p: Dictionary, amount: float) -> int:
	var mult := 1.0
	for a: Dictionary in p["auras"]:
		if a["id"] == "avenging_wrath" or a["id"] == "perpetual_sun_generation":
			mult = 2.0
	return grant_devotion(p, amount * mult)


## castAbility's Divine Ascension gate (casting_lifecycle.ts:1093) and the airborne
## Valkyr's Calling lock. "" lets the cast through.
static func cast_gate(p: Dictionary, ability_id: String) -> String:
	if RpgPaladinKit.valkyr_airborne(p):
		return "You are busy."
	if ability_id != "divine_ascension":
		return ""
	var s := _state(p)
	if s.is_empty() or int(s["value"]) < MAX_DEVOTION or ascension_active(p):
		return "That ability is not ready yet."
	return ""


## executeWindowBypassed's paladin windows: Hammer of Wrath ignores its execute
## window while ascended, under Avenging Wrath, or with Dawn's Wrath worn.
static func execute_bypassed(p: Dictionary, ability_id: String) -> bool:
	if ability_id != "hammer_of_wrath":
		return false
	if ascension_active(p):
		return true
	for a: Dictionary in p["auras"]:
		if a["id"] == "avenging_wrath" or a["kind"] == RpgPaladinProcs.DAWNS_WRATH_KIND:
			return true
	return false


static func _empowered(spec: String, ability_id: String) -> bool:
	return ability_id in ASCENSION_ABILITIES.get(spec, [])


static func _scaled(e: Dictionary, mult: float) -> Dictionary:
	e["min"] = float(_jr(float(e["min"]) * mult))
	e["max"] = float(_jr(float(e["max"]) * mult))
	return e


## resolveAscensionAbility: while ascended, the spec's empowered abilities (and the
## Holy Life Covenant / Protection Sacred Challenge upgrades) resolve stronger.
static func resolve(p: Dictionary, k: Dictionary) -> Dictionary:
	if p.get("class_id") != "paladin" or not ascension_active(p):
		return k
	var spec := str(p.get("spec_id", ""))
	var id := str(k["def"]["id"])
	var passive_upgrade := (
		(spec == "holy" and id == "life_covenant")
		or (spec == "protection" and id == "sacred_challenge")
	)
	if not _empowered(spec, id) and not passive_upgrade:
		return k
	var effects: Array = []
	for src: Dictionary in k["effects"]:
		effects.append(_ascend_effect(id, src.duplicate(true)))
	_ascension_extra(p, id, effects)
	var out := k.duplicate()
	out["effects"] = effects
	if id == "dawns_embrace":
		out["castTime"] = 0.0
	return out


static func _ascend_effect(id: String, e: Dictionary) -> Dictionary:
	var t := str(e["type"])
	match id:
		"mercy_lance":
			if t == "directDamage":
				e["guaranteedCrit"] = true
		"dawns_embrace":
			if t == "heal":
				_scaled(e, 1.35)
		"radiant_chorus":
			if t == "aoeHeal":
				_scaled(e, 1.2)["radius"] = 40.0
		"dawnfall":
			if t == "aoeDamage":
				_scaled(e, 1.5)["radius"] = 10.0
		"hammer_of_wrath", "consecration":
			if t in ["directDamage", "groundAoE"]:
				_scaled(e, 1.3)
		"valkyrs_calling":
			if t == "valkyrsCalling":
				_scaled(e, 1.5)["ascended"] = true
		"bastion_sweep":
			if t == "aoeDamage":
				_scaled(e, 1.3)["radius"] = 8.0
		"holy_shield":
			if t == "selfBuff" and e["kind"] == "buff_block":
				e["value"] = 0.4
				e["duration"] = 10.0
			elif t == "absorb":
				e["amount"] = float(_jr(float(e["amount"]) * 1.5))
				if e.get("casterMaxHpPct") != null:
					e["casterMaxHpPct"] = (
						float(_jr(float(e["casterMaxHpPct"]) * 1.5 * 10000.0)) / 10000.0
					)
				e["duration"] = 10.0
		"faithforged_guard":
			if t == "selfBuff" and e["kind"] == RpgPaladinProcs.DEBT_OF_LIGHT_KIND:
				e["value"] = float(_jr(float(e["value"]) * 1.5))
		"bastion_rite":
			if t == "selfBuff":
				e["duration"] = 10.0
		"sunward_disc":
			if t == "directDamage":
				_scaled(e, 1.3)
			elif t == "chainDamage":
				_scaled(e, 1.3)["jumps"] = 5
		"guardian_covenant":
			if t == "buffTarget" or t == "selfBuff":
				e["value"] = 0.3
		"oath_chain":
			if t == "pullTarget":
				e["maxTargets"] = 2
		"veilbound_march":
			if t == "veilboundMarch":
				e["ascended"] = true
	return e


static func _ascension_extra(p: Dictionary, id: String, effects: Array) -> void:
	match id:
		"final_edict":
			(
				effects
				. append(
					{
						"type": "aoeDamage",
						"min": 55.0,
						"max": 70.0,
						"radius": 6.0,
						"softCap": 5,
					}
				)
			)
		"solar_invocation":
			(
				effects
				. append(
					{
						"type": "aoeHeal",
						"min": 90.0,
						"max": 110.0,
						"radius": 10.0,
						"playersOnly": true,
						"centerOnTarget": true,
						"friendlyTargetOnly": true,
					}
				)
			)
		"vowkeeper_strike":
			(
				effects
				. append(
					{
						"type": "selfBuff",
						"kind": "absorb",
						"value": float(maxi(1, _jr(float(p["max_hp"]) * 0.06))),
						"duration": 6.0,
						"auraId": "vowkeeper_strike_absorb",
					}
				)
			)
		"life_covenant":
			effects.append({"type": "absorb", "amount": 120.0, "duration": 6.0})
		"sacred_challenge":
			effects.append({"type": "selfBuff", "kind": "buff_dr", "value": 0.15, "duration": 4.0})


## runEffects' prelude: the hp snapshot devotion generation reads (an effective hit
## or heal) and the Devotion family choice (replacePaladinDevotionChoice).
static func before_effects(
	w: RpgEncounter, p: Dictionary, def: Dictionary, ctx: Dictionary
) -> void:
	if p.get("class_id") != "paladin":
		return
	var hp := {p["id"]: int(p["hp"])}
	for m: Dictionary in w.mobs:
		hp[m["id"]] = int(m["hp"])
	ctx["paladin_hp"] = hp
	var id := str(def["id"])
	if id in AURA_CHOICE_IDS:
		strip_devotions(w, p, AURA_CHOICE_IDS, id)
	elif id in LONG_DEVOTION_IDS:
		strip_devotions(w, p, LONG_DEVOTION_IDS, id)


## stripPaladinDevotionsFromSource / replacePaladinDevotionChoice on the caster (the
## street's only friendly): the caster's other choice in `family` goes.
static func strip_devotions(
	w: RpgEncounter, p: Dictionary, family: Array[String], keep: String
) -> void:
	var removed := false
	for a: Dictionary in (p["auras"] as Array).duplicate():
		if a["source_id"] == p["id"] and a["id"] != keep and str(a["id"]) in family:
			p["auras"].erase(a)
			removed = true
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
	if removed:
		w.recalc_player()


## The effect arms paladin_devotion.ts answers (divineAscension, grantDevotion).
static func run_arm(w: RpgEncounter, p: Dictionary, eff: Dictionary) -> bool:
	match str(eff["type"]):
		"divineAscension":
			var s := _state(p)
			if cast_gate(p, "divine_ascension") != "" or s.is_empty():
				return true
			s["value"] = 0
			s["ascension_charges"] = ASCENSION_CHARGES + int(_g(p, "ascensionChargeBonus"))
			s["ascension_remaining"] = ASCENSION_DURATION
			s["out_of_combat_time"] = 0.0
			(
				RpgCombat
				. apply_aura(
					w,
					p,
					{
						"id": ASCENSION_AURA_ID,
						"kind": "internal_cd",
						"remaining": ASCENSION_DURATION,
						"duration": ASCENSION_DURATION,
						"value": 0.0,
						"charges": int(s["ascension_charges"]),
						"source_id": p["id"],
						"school": "holy",
					}
				)
			)
			if _g(p, "paladinDivineSteed") > 0.0:
				(
					RpgCombat
					. apply_aura(
						w,
						p,
						{
							"id": "divine_steed_burst",
							"kind": "buff_speed",
							"remaining": 5.0,
							"duration": 5.0,
							"value": 1.3,
							"source_id": p["id"],
							"school": "holy",
						}
					)
				)
			return true
		"grantDevotion":
			grant_devotion(p, float(eff["amount"]))
			return true
	return false


## runEffects' epilogue: devotion from an effective hit or heal (Zeal, Dawn Echo),
## then an empowered ability spends an Ascension charge (Divine Purpose may keep it;
## the last one fires Sacred Reserve and Perpetual Sun).
static func after_ability(w: RpgEncounter, p: Dictionary, def: Dictionary, ctx: Dictionary) -> void:
	if p.get("class_id") != "paladin" or not ctx.has("paladin_hp"):
		return
	var id := str(def["id"])
	var spec := str(p.get("spec_id", ""))
	var hp: Dictionary = ctx["paladin_hp"]
	var damaged := false
	var healed := int(p["hp"]) > int(hp.get(p["id"], p["hp"]))
	for m: Dictionary in w.mobs:
		damaged = damaged or int(m["hp"]) < int(hp.get(m["id"], m["hp"]))
	if damaged or healed:
		var gain := 0
		if id in COMMON_DIRECT_DEVOTION_ABILITIES or id in DEVOTION_GAIN.get(spec, []):
			gain = 1
		var gained := grant_ability_devotion(p, gain)
		if gained > 0 and _g(p, "paladinZeal") > 0.0 and _advance_counter(p, "paladin_zeal"):
			grant_devotion(p, 1)
		var echo: Dictionary = ctx.get("dawn_echo", {})
		if gained > 0 and not echo.is_empty() and _g(p, "paladinDawnEcho") > 0.0:
			if _advance_counter(p, "paladin_dawn_echo") and _repeat_dawn_echo(w, p, echo):
				grant_devotion(p, _g(p, "paladinDawnEchoDevotion"))
	var s := _state(p)
	if not ascension_active(p) or not _empowered(spec, id):
		return
	var final_charge := int(s["ascension_charges"]) == 1
	var keep := _g(p, "paladinDivinePurposeChance")
	if keep <= 0.0 or not w.rng.chance(keep):
		s["ascension_charges"] = int(s["ascension_charges"]) - 1
	if int(s["ascension_charges"]) <= 0:
		s["ascension_charges"] = 0
		s["ascension_remaining"] = 0.0
	_sync_aura(w, p)
	if final_charge and not p["dead"] and not ascension_active(p):
		if _g(p, "paladinSacredReserve") > 0.0:
			grant_devotion(p, 5)
		if _g(p, "paladinPerpetualSun") > 0.0:
			RpgPaladinProcs.unleash_perpetual_sun(w, p)


## syncDivineAscensionAura.
static func _sync_aura(w: RpgEncounter, p: Dictionary) -> void:
	var s := _state(p)
	for a: Dictionary in p["auras"]:
		if a["id"] != ASCENSION_AURA_ID or a["source_id"] != p["id"]:
			continue
		if not ascension_active(p):
			p["auras"].erase(a)
			w.log_event({"type": "aura", "target": p["id"], "name": a["id"], "gained": false})
			return
		a["remaining"] = float(s["ascension_remaining"])
		a["charges"] = int(s["ascension_charges"])
		return


## advancePaladinTalentCounter: true every third call.
static func _advance_counter(p: Dictionary, key: String) -> bool:
	var counters: Dictionary = RpgTalentProcs._state(p)["counters"]
	var next := int(counters.get(key, 0)) + 1
	if next >= 3:
		counters[key] = 0
		return true
	counters[key] = next
	return false


## repeatDawnEcho: 40% of the recorded outcome lands again.
static func _repeat_dawn_echo(w: RpgEncounter, p: Dictionary, echo: Dictionary) -> bool:
	var t: Dictionary = echo["target"]
	if t["dead"] or int(echo["amount"]) <= 0:
		return false
	var amount := maxi(1, _jr(int(echo["amount"]) * 0.4))
	if echo["kind"] == "healing":
		return RpgCombat.apply_heal(w, p, t, amount, false) > 0
	var before := int(t["hp"])
	RpgCombat.deal_damage(w, p, t, amount, false, str(echo["school"]), "Dawn Echo", "hit", true)
	return int(t["hp"]) < before


## Records the outcome Dawn Echo would repeat (weaponStrike, directDamage, heal).
static func note_outcome(
	ctx: Dictionary, kind: String, target: Dictionary, amount: int, school := "holy"
) -> void:
	ctx["dawn_echo"] = {"kind": kind, "target": target, "amount": amount, "school": school}


## updatePaladinDevotion, once per tick.
static func tick(p: Dictionary, dt: float) -> void:
	var s := _state(p)
	if s.is_empty():
		return
	s["block_icd"] = maxf(0.0, float(s["block_icd"]) - dt)
	if p["dead"]:
		s["value"] = 0
		s["ascension_charges"] = 0
		s["ascension_remaining"] = 0.0
		s["out_of_combat_time"] = 0.0
		return
	if float(s["ascension_remaining"]) > 0.0:
		s["ascension_remaining"] = maxf(0.0, float(s["ascension_remaining"]) - dt)
		if float(s["ascension_remaining"]) == 0.0:
			s["ascension_charges"] = 0
			if _g(p, "paladinSacredReserve") > 0.0:
				grant_devotion(p, 5)
	if p["in_combat"]:
		s["out_of_combat_time"] = 0.0
		return
	s["out_of_combat_time"] = float(s["out_of_combat_time"]) + dt


## A block a protection paladin makes (auto_attack.ts:698): one Devotion per
## BLOCK_DEVOTION_ICD, and a Solar Reprisal chance.
static func on_block(w: RpgEncounter, p: Dictionary) -> void:
	if p.get("class_id") != "paladin" or p.get("spec_id") != "protection":
		return
	var s := _state(p)
	if not ascension_active(p) and float(s["block_icd"]) <= 0.0:
		s["block_icd"] = BLOCK_DEVOTION_ICD
		grant_devotion(p, 1)
	RpgPaladinProcs.try_solar_reprisal(w, p, "block")


## grantGroundAoEDevotionOnFirstHit.
static func ground_devotion_on_first_hit(
	_w: RpgEncounter, src: Dictionary, area: Dictionary, effective: int
) -> void:
	if effective <= 0 or area.get("devotion_granted", false):
		return
	if area.get("devotion_on_first_hit") == null:
		return
	area["devotion_granted"] = true
	grant_ability_devotion(src, float(area["devotion_on_first_hit"]))


## The groundAoE arm's Consecration fields: a protection paladin's own zone cuts the
## damage they take while they stand in it (paladin_consecration.ts).
static func shape_consecration(
	_w: RpgEncounter, p: Dictionary, def: Dictionary, _eff: Dictionary, area: Dictionary
) -> void:
	if def["id"] != "consecration":
		return
	area["consecration"] = true
	if p.get("spec_id") == "protection":
		area["protection_dr"] = RpgPaladinProcs.PROTECTION_CONSECRATION_DR


## paladinHealingDoneMultiplier.
static func healing_done_mult(u: Dictionary) -> float:
	var bonus := 0.0
	for a: Dictionary in u["auras"]:
		if a["kind"] == "buff_healing_done" or a["kind"] == "sacred_form":
			bonus += float(a["value"])
	return 1.0 + bonus
