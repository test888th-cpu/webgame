class_name RpgAbilityCost
extends RefCounted
## The resolved ability (combat/ability_resolution.ts resolveAbilityChain, then
## applyAbilityCostTail): an action replacement swaps the button's ability while its
## aura holds (action_replacement.ts); the class resolvers reshape it; a swapped
## ability gets its own talent pass; then the cost tail: Measured Fury (an arms
## warrior knowing it pays 90%, rounded), the draining-curse cost tax, Aether Surge's
## per-charge ramp, and a Cat Form inside the Bruin Rush window is free.


static func resolve(w: RpgEncounter, known: Dictionary) -> Dictionary:
	var p := w.player
	var k := replacement(w, known, p)
	k = RpgClassHooks.resolve_ability(w, p, k)
	if k["id"] != known["id"]:
		RpgTalents.apply_talent_mods(w.pack, k, p["mods"])
	k = RpgClassHooks.resolve_cast_time(w, p, known, k)
	var cost := float(k["cost"])
	if cost > 0.0 and p["spec_id"] == "arms" and _knows_passive(w, "measured_fury"):
		cost = maxf(0.0, RpgTalents.js_round(cost * 0.9))
	var tax := RpgWarlock.cost_tax_mult(p)
	if tax > 1.0 and cost > 0.0:
		cost = ceilf(cost * tax)
	if k["id"] == "arcane_surge" and cost > 0.0:
		cost = RpgTalents.js_round(cost * RpgMage.surge_cost_mult(p))
	if cost > 0.0 and RpgDruid.bruin_rush_makes_cat_free(p, str(k["id"])):
		cost = 0.0
	if cost == float(k["cost"]):
		return k
	var out := k.duplicate()
	out["cost"] = cost
	return out


static func _knows_passive(w: RpgEncounter, id: String) -> bool:
	for k: Dictionary in w.known():
		if k["id"] == id and k["def"].get("passive", false):
			return true
	return false


## resolveActionReplacement.
static func replacement(w: RpgEncounter, base: Dictionary, actor: Dictionary) -> Dictionary:
	var rules: Variant = base["def"].get("actionReplacement")
	if rules == null:
		return base
	for rule: Dictionary in rules if rules is Array else [rules]:
		if (
			rule.get("actorAuraKind") != null
			and not RpgAbilityRules.has_kind(actor, str(rule["actorAuraKind"]))
		):
			continue
		if rule.get("auraKind") == null and rule.get("absentAuraKind") == null:
			continue
		var present := rule.get("auraKind") == null
		if not present:
			for a: Dictionary in actor["auras"]:
				if (
					a["kind"] == rule["auraKind"]
					and int(a.get("stacks", 1)) >= int(rule.get("minStacks", 1))
				):
					present = true
		var absent := (
			rule.get("absentAuraKind") == null
			or not RpgAbilityRules.has_kind(actor, str(rule["absentAuraKind"]))
		)
		if present and absent:
			var def: Dictionary = w.pack["abilities"].get(str(rule["abilityId"]), {}).get("def", {})
			if def.is_empty():
				return base
			var out := RpgTalents._resolve_ranks(def, int(actor["level"]))
			out["threatMult"] = float(def.get("threat", {}).get("mult", 1))
			if def.get("maxCharges") != null:
				out["charges"] = int(def["maxCharges"])
			if base.get("ignoreStealthRequirement") != null:
				out["ignoreStealthRequirement"] = base["ignoreStealthRequirement"]
			if float(out["cooldown"]) > 0.0 and rule.get("auraKind") != null:
				out["cooldownId"] = base["id"]
			return out
	return base
