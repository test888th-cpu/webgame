class_name RpgDruid
extends RefCounted
## The druid's engines (src/sim/combat/druid_*.ts). Nature's Boon
## (druid_natures_boon.ts): an armed window lets its named spells through a form.

const NATURES_BOON_ID := "natures_boon"
const NATURES_BOON_ABILITIES: Array[String] = ["rejuvenation", "barkskin"]
const GROVEHEART_BOON_ABILITIES: Array[String] = ["spore_burst"]
const MOONGROVE_BOON_ABILITIES: Array[String] = ["spore_burst"]
const NATURES_BOON_BEAR_ONLY: Array[String] = ["barkskin"]
## form_swing.ts (values from the runtime pack's constants when a pack is at hand;
## these mirror them for the unit-only helpers below).
const CAT_FORM_SWING_SPEED := 1.0
const CAT_FORM_DAMAGE_MULT := 1.22
const BEAR_FORM_SWING_MULT := 0.5
const BEAR_FORM_AUTO_DAMAGE_MULT := 0.5
const BEAR_FORM_AUTO_RAGE_MULT := 2.0
const WANDLESS_FORMS: Array[String] = ["form_bear", "form_cat", "form_travel", "form_foreman"]
## druid_sporemender.ts.
const SPOREMENDER_ARMOR_MULT := 1.4
const SPOREMENDER_HEALING_DONE_PCT := 0.2


static func _any_boon_ability(id: String) -> bool:
	return (
		id in NATURES_BOON_ABILITIES
		or id in GROVEHEART_BOON_ABILITIES
		or id in MOONGROVE_BOON_ABILITIES
	)


## naturesBoonFormAllows.
static func natures_boon_form_allows(u: Dictionary, ability_id: String) -> bool:
	if not ability_id in NATURES_BOON_BEAR_ONLY:
		return true
	return RpgAbilityRules.has_kind(u, "form_bear")


## naturesBoonArmedFor.
static func natures_boon_armed_for(u: Dictionary, ability_id: String) -> bool:
	if ability_id == "" or not _any_boon_ability(ability_id):
		return false
	if not natures_boon_form_allows(u, ability_id):
		return false
	for a: Dictionary in u["auras"]:
		if (
			a["id"] == NATURES_BOON_ID
			and a["kind"] == "next_cast_free"
			and a.get("empower_abilities") != null
			and ability_id in a["empower_abilities"]
		):
			return true
	return false


## druidEngineOnHotPlanted.
static func on_hot_planted(w: RpgEncounter, p: Dictionary, id: String) -> void:
	RpgDruidEngine.on_hot_planted(w, p, id)


## druidApexPayoffMult.
static func apex_payoff_mult(_w: RpgEncounter, p: Dictionary, id: String) -> float:
	return RpgDruidEngine.apex_payoff_mult(p, id)


## druidEngineOnLandedStrike.
static func on_landed_strike(w: RpgEncounter, p: Dictionary, id: String) -> void:
	RpgDruidEngine.on_landed_strike(w, p, id)


## baseSwingSpeed.
static func base_swing_speed(u: Dictionary) -> float:
	if RpgAbilityRules.has_kind(u, "form_cat"):
		return CAT_FORM_SWING_SPEED
	var speed := float(u.get("weapon", RpgUnit.UNARMED)["speed"])
	return speed * BEAR_FORM_SWING_MULT if RpgAbilityRules.has_kind(u, "form_bear") else speed


## catAutoWeaponRollMult.
static func cat_auto_roll_mult(u: Dictionary) -> float:
	if RpgAbilityRules.has_kind(u, "form_cat"):
		return CAT_FORM_SWING_SPEED / maxf(0.1, float(u["weapon"]["speed"]))
	return BEAR_FORM_AUTO_DAMAGE_MULT if RpgAbilityRules.has_kind(u, "form_bear") else 1.0


## catFormDamageMult.
static func cat_form_damage_mult(u: Dictionary) -> float:
	return CAT_FORM_DAMAGE_MULT if RpgAbilityRules.has_kind(u, "form_cat") else 1.0


## formAutoRageMult.
static func form_auto_rage_mult(u: Dictionary) -> float:
	return BEAR_FORM_AUTO_RAGE_MULT if RpgAbilityRules.has_kind(u, "form_bear") else 1.0


## wandAllowedInForm.
static func wand_allowed_in_form(u: Dictionary) -> bool:
	for a: Dictionary in u["auras"]:
		if str(a["kind"]) in WANDLESS_FORMS:
			return false
	return true


## bruinRushMakesCatFormFree.
static func bruin_rush_makes_cat_free(p: Dictionary, id: String) -> bool:
	if id != "cat_form":
		return false
	for a: Dictionary in p["auras"]:
		if a["id"] == RpgDruidEngine.BRUIN_RUSH_WINDOW_ID and a["kind"] == "internal_cd":
			return true
	return false


## druidEngineOnCast.
static func engine_on_cast(w: RpgEncounter, p: Dictionary, id: String, target: Dictionary) -> void:
	RpgDruidEngine.on_cast(w, p, id, target)


## naturesBoonOnCast.
static func natures_boon_on_cast(w: RpgEncounter, p: Dictionary, id: String) -> void:
	RpgDruidEngine.boon_on_cast(w, p, id)


## secondBloomOnHotExpired.
static func second_bloom_on_hot_expired(
	w: RpgEncounter, src: Dictionary, e: Dictionary, a: Dictionary
) -> void:
	var amount := float(a.get("closing_heal", 0.0))
	if amount <= 0.0 or e["dead"] or a["source_id"] != src["id"]:
		return
	RpgCombat.apply_heal(w, src, e, amount, false)


## sporemenderHealingDoneMult.
static func sporemender_healing_mult(healer: Dictionary) -> float:
	if healer.is_empty() or not RpgAbilityRules.has_kind(healer, "form_sporemender"):
		return 1.0
	return 1.0 + SPOREMENDER_HEALING_DONE_PCT


## naturesBoonOnHotTick.
static func natures_boon_on_hot_tick(w: RpgEncounter, healer: Dictionary, a: Dictionary) -> void:
	RpgDruidEngine.boon_on_hot_tick(w, healer, a)
