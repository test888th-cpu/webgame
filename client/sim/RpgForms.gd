class_name RpgForms
extends RefCounted
## Shapeshift forms (src/sim/combat/forms.ts, form_requirement.ts,
## form_auto_unshift.ts and castAbility's form gates). A bar-swapping form (Bruin:
## rage, Cat: energy, Travel) parks the caster's mana in `saved_mana`; shifting out
## is free, shifting across bills the parked mana. The druid's own engines (Nature's
## Boon, form entry, the Bruin Rush window) live in RpgDruid.

const FORM_AURA_KIND := {"bear": "form_bear", "cat": "form_cat"}
const DAMAGING_EFFECT_TYPES: Array[String] = [
	"aoeDamage",
	"chainDamage",
	"directDamage",
	"dot",
	"finisherDamage",
	"groundAoE",
	"sporeBurst",
	"weaponDamage",
	"weaponStrike",
]
const HEALING_EFFECT_TYPES: Array[String] = [
	"aoeHeal",
	"chainHeal",
	"druidOverbloom",
	"heal",
	"hot",
	"selfHealPctMax",
	"selfHotPctMax",
	"sporeBurst"
]


static func is_form_kind(w: RpgEncounter, kind: String) -> bool:
	return kind in w.pack["constants"]["form_aura_kinds"]


static func is_resource_shift_kind(kind: String) -> bool:
	return kind in ["form_bear", "form_cat", "form_travel"]


static func is_action_locking_kind(kind: String) -> bool:
	return is_resource_shift_kind(kind) or kind == "form_fireball"


static func is_travel_kind(kind: String) -> bool:
	return kind in ["form_travel", "form_fireball"]


## isFormToggleAbility.
static func is_form_toggle(w: RpgEncounter, def: Dictionary) -> bool:
	for e: Dictionary in def.get("effects", []):
		if e["type"] == "selfBuff" and is_form_kind(w, str(e["kind"])):
			return true
	return false


## requiredForms.
static func required_forms(def: Dictionary) -> Array:
	var r: Variant = def.get("requiresForm")
	if r == null:
		return []
	return [r] if r is String else r


static func requirement_met(u: Dictionary, def: Dictionary) -> bool:
	var forms := required_forms(def)
	if forms.is_empty():
		return true
	for a: Dictionary in u["auras"]:
		for f: String in forms:
			if a["kind"] == FORM_AURA_KIND[f]:
				return true
	return false


static func is_healing_or_damaging(def: Dictionary) -> bool:
	for e: Dictionary in def.get("effects", []):
		if e["type"] == "consumeAura":
			if e.get("heal") != null or e.get("deal") != null:
				return true
			continue
		if e["type"] in DAMAGING_EFFECT_TYPES or e["type"] in HEALING_EFFECT_TYPES:
			return true
	return false


## willAutoUnshift.
static func will_auto_unshift(w: RpgEncounter, u: Dictionary, def: Dictionary) -> bool:
	if not required_forms(def).is_empty() or def.get("usableInForm", false):
		return false
	if is_form_toggle(w, def):
		return false
	var shifted := false
	for a: Dictionary in u["auras"]:
		shifted = shifted or is_resource_shift_kind(str(a["kind"]))
	if not shifted or RpgDruid.natures_boon_armed_for(u, str(def["id"])):
		return false
	return is_healing_or_damaging(def)


## formShiftKind: "off" (leaving this form), "cross" (bear <-> cat), or "".
static func shift_kind(w: RpgEncounter, u: Dictionary, def: Dictionary) -> String:
	if not is_form_toggle(w, def):
		return ""
	for a: Dictionary in u["auras"]:
		if a["id"] == def["id"]:
			return "off"
	for a: Dictionary in u["auras"]:
		if is_form_kind(w, str(a["kind"])):
			return "cross"
	return ""


## castAbility's form gate: a form ability needs its form; an action-locking form
## refuses the rest of the kit unless it auto-unshifts (or Nature's Boon allows it).
static func cast_gate(w: RpgEncounter, u: Dictionary, def: Dictionary) -> String:
	var forms := required_forms(def)
	if not forms.is_empty():
		if requirement_met(u, def):
			return ""
		if forms.size() > 1:
			return "You must be in Bruin or Cat Form."
		return "You must be in Bruin Form." if forms[0] == "bear" else "You must be in Cat Form."
	var locked := false
	for a: Dictionary in u["auras"]:
		locked = locked or is_action_locking_kind(str(a["kind"]))
	if (
		locked
		and not is_form_toggle(w, def)
		and not def.get("usableInForm", false)
		and not RpgDruid.natures_boon_armed_for(u, str(def["id"]))
		and not will_auto_unshift(w, u, def)
	):
		return "You can't do that while shapeshifted."
	return ""


## The pool a cast is weighed against: an auto-unshifting cast pays from the parked
## mana when the live bar is rage or energy.
static func casting_pool(w: RpgEncounter, u: Dictionary, def: Dictionary) -> float:
	if will_auto_unshift(w, u, def) and u["resource_type"] != "mana":
		return float(u.get("saved_mana", 0.0))
	return float(u["resource"])


## applyAutoUnshift at commit: the bar-swapping forms drop and the sheet recalcs.
static func before_commit(w: RpgEncounter, u: Dictionary, def: Dictionary, _shift: String) -> void:
	RpgDruidKit.apply_form_entry(w, u, str(def["id"]))
	if not will_auto_unshift(w, u, def):
		return
	var auras: Array = u["auras"]
	for i in range(auras.size() - 1, -1, -1):
		if is_resource_shift_kind(str(auras[i]["kind"])):
			var gone: Dictionary = auras[i]
			auras.remove_at(i)
			w.log_event({"type": "aura", "target": u["id"], "name": gone["id"], "gained": false})
	RpgStealth.break_stealth(w, u)
	w.recalc_player()


## spendAbilityCost's cross-shift: bill the parked mana when a form holds it.
static func spend_cross(u: Dictionary, cost: float) -> void:
	var parked := false
	for a: Dictionary in u["auras"]:
		parked = parked or is_resource_shift_kind(str(a["kind"]))
	if parked:
		u["saved_mana"] = maxf(0.0, float(u.get("saved_mana", 0.0)) - cost)
	else:
		RpgCast.spend(u, cost)
