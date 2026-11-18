class_name RpgCast
extends RefCounted
## Casting (src/sim/combat/casting_lifecycle.ts castAbility, updateCasting,
## applyAbility), for the abilities the runtime pack marks executable. Every refusal is
## the reference's message; the ones it makes silently return SILENT + a reason.

const SILENT := "silent:"
const CAST_QUEUE_WINDOW_SEC := 0.4
const CAST_PUSHBACK_SEC := 0.5
const CAST_COMPLETE_EPS := 1e-9


static func _cost_error(resource: String) -> String:
	match resource:
		"rage":
			return "Not enough rage!"
		"energy":
			return "Not enough energy!"
		"focus":
			return "Not enough Focus!"
	return "Not enough mana!"


## paladinManaCostMultiplier.
static func paladin_mana_mult(p: Dictionary) -> float:
	var reduction := 0.0
	for a: Dictionary in p["auras"]:
		if a["kind"] == "buff_mana_grace":
			reduction += float(a.get("value2", 0.03))
	return maxf(0.2, 1.0 - reduction)


static func _payable(p: Dictionary, cost: float) -> float:
	return ceilf(cost * paladin_mana_mult(p)) if p["resource_type"] == "mana" else cost


## The GCD (castAbility: max(MIN_GCD, playerGcdFor(cls) / spellHasteMult)).
static func gcd_for(w: RpgEncounter, p: Dictionary) -> float:
	var base := 1.0 if p["class_id"] == "rogue" else float(w.pack["constants"]["gcd"])
	var haste := float(p["spell_haste"])
	for a: Dictionary in p["auras"]:
		if a["kind"] == "buff_spellhaste":
			haste += float(a["value"])
	return maxf(float(w.pack["constants"]["min_gcd"]), base / (1.0 + maxf(0.0, haste)))


static func spell_haste_mult(p: Dictionary) -> float:
	var haste := float(p["spell_haste"])
	for a: Dictionary in p["auras"]:
		if a["kind"] == "buff_spellhaste":
			haste += float(a["value"])
	return 1.0 + maxf(0.0, haste)


## castAbility. Returns "" when the cast started or resolved.
static func cast(w: RpgEncounter, ability_id: String) -> String:
	var p := w.player
	var res := w.known_entry(ability_id)
	if res.is_empty():
		return "You do not know that ability."
	var def: Dictionary = res["def"]
	if p["dead"]:
		return SILENT + "dead"
	if def.get("passive", false):
		return SILENT + "passive"
	var status := str(w.pack["abilities"][ability_id]["status"])
	if not status.begins_with("IMPLEMENTED"):
		return "Not available in this build: " + str(w.pack["abilities"][ability_id]["reason"])
	if RpgCombat.is_stunned(p) and not def.get("usableWhileControlled", false):
		return "You are stunned!"
	if not p["casting"].is_empty():
		if float(p["casting"]["remaining"]) <= CAST_QUEUE_WINDOW_SEC:
			p["queued_cast"] = ability_id
			return SILENT + "queued"
		return "You are busy."
	if not def.get("offGcd", false) and float(p["gcd"]) > 0.0:
		if float(p["gcd"]) <= CAST_QUEUE_WINDOW_SEC:
			p["queued_cast"] = ability_id
		return SILENT + "gcd"
	if p["cooldowns"].has(ability_id):
		return "That ability is not ready yet."
	if float(p["resource"]) < _payable(p, float(res["cost"])):
		return _cost_error(str(p["resource_type"]))
	var target := {}
	if def.get("targetType") == "friendly":
		target = p  # resolveFriendlyTarget: no friendly target held, so the caster
	elif def.get("requiresTarget", false):
		target = w.mob
		if target["dead"]:
			return "You have no target."
		var d := w.distance()
		if d > w.player_attack_range(float(def["range"])):
			return "Out of range."
		if def.get("minRange") != null and d < float(def["minRange"]):
			return "Too close!"
	var cast_time := float(res["castTime"])
	var gcd := gcd_for(w, p)
	if cast_time > 0.0:
		var stretched := cast_time / spell_haste_mult(p)
		p["casting"] = {
			"ability": ability_id, "remaining": stretched, "total": stretched, "target": target
		}
		p["gcd"] = maxf(float(p["gcd"]), gcd)
		w.log_event({"type": "cast_start", "ability": ability_id, "time": stretched})
		return ""
	if not def.get("offGcd", false):
		p["gcd"] = maxf(float(p["gcd"]), gcd)
	return apply_ability(w, res, target)


## updateCasting: the bar runs down; at the end the ability applies, then a queued
## cast fires.
static func update_casting(w: RpgEncounter) -> void:
	var p := w.player
	if p["casting"].is_empty():
		return
	var c: Dictionary = p["casting"]
	c["remaining"] = float(c["remaining"]) - w.dt
	if float(c["remaining"]) > CAST_COMPLETE_EPS:
		return
	p["casting"] = {}
	w.log_event({"type": "cast_stop", "ability": c["ability"], "success": true})
	var res := w.known_entry(str(c["ability"]))
	if not res.is_empty():
		var refusal := apply_ability(w, res, c["target"])
		if refusal != "":
			w.log_event({"type": "error", "text": refusal})
	_fire_queued(w)


static func _fire_queued(w: RpgEncounter) -> void:
	var queued := str(w.player.get("queued_cast", ""))
	w.player.erase("queued_cast")
	if queued != "":
		w.command({"op": "cast", "ability": queued})


## A hit taken while casting delays the cast (pushbackCast).
static func pushback(p: Dictionary) -> void:
	if p["casting"].is_empty():
		return
	var factor := 1.0
	p["casting"]["remaining"] = float(p["casting"]["remaining"]) + CAST_PUSHBACK_SEC * factor
	p["casting"]["total"] = float(p["casting"]["total"]) + CAST_PUSHBACK_SEC * factor


## applyAbility: the target re-checked (range + 2), the cost re-checked, then billing,
## the cooldown, and the effects: at once for a friendly or physical ability, on a
## projectile for a spell (with the hostile spell resist roll on arrival).
static func apply_ability(w: RpgEncounter, res: Dictionary, target: Dictionary) -> String:
	var p := w.player
	var def: Dictionary = res["def"]
	var friendly: bool = def.get("targetType") == "friendly"
	if def.get("requiresTarget", false) and not friendly:
		if target.is_empty() or target["dead"]:
			return "You have no target."
		if w.distance() > w.player_attack_range(float(def["range"])) + 2.0:
			return "Out of range."
	var cost := float(res["cost"])
	if float(p["resource"]) < _payable(p, cost):
		return "Not enough %s!" % p["resource_type"]
	if cost > 0.0 and p["resource_type"] == "mana":
		cost = ceilf(cost * paladin_mana_mult(p))
	_spend(w, p, cost)
	if float(res["cooldown"]) > 0.0:
		p["cooldowns"][res["id"]] = float(res["cooldown"])
	if friendly:
		RpgEffects.run(w, p, target, res)
		return ""
	var fires_projectile: bool = (
		def["projectile"] if def.get("projectile") != null else def["school"] != "physical"
	)
	if not target.is_empty() and fires_projectile:
		var is_spell: bool = def["school"] != "physical"
		w.schedule_projectile(
			func(src: Dictionary, tgt: Dictionary) -> void:
				if is_spell and RpgCombat.spell_resisted(w, src, tgt):
					w.log_event(
						{
							"type": "damage",
							"source": src["id"],
							"target": tgt["id"],
							"amount": 0,
							"kind": "resist",
							"ability": def["name"]
						}
					)
					w.enter_combat(src, tgt)
					return
				RpgEffects.run(w, src, tgt, res)
		)
		return ""
	var resisted: bool = (
		not target.is_empty()
		and def["school"] != "physical"
		and target["kind"] == "mob"
		and RpgCombat.spell_resisted(w, p, target)
	)
	if resisted:
		w.log_event(
			{
				"type": "damage",
				"source": p["id"],
				"target": target["id"],
				"amount": 0,
				"kind": "resist",
				"ability": def["name"]
			}
		)
		w.enter_combat(p, target)
	else:
		RpgEffects.run(w, p, target, res)
	return ""


## spendResource (mana spending restarts the five-second rule).
static func _spend(_w: RpgEncounter, p: Dictionary, cost: float) -> void:
	p["resource"] = maxf(0.0, float(p["resource"]) - cost)
	if p["resource_type"] == "mana" and cost > 0.0:
		p["five_second_rule"] = 0.0
