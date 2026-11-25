class_name RpgThorns
extends RefCounted
## Thorns (src/sim/combat/thorns_charge.ts): a melee attacker that lands on a
## defender wearing a thorns aura takes its value back (Requital Aura, Lightning
## Shield). A charge-limited thorns spends a charge per reflect and waits out its
## internal cooldown; a spent one falls off.


## applyThornsReaction.
static func react(w: RpgEncounter, defender: Dictionary, attacker: Dictionary) -> void:
	if attacker.is_empty() or attacker["dead"]:
		return
	for a: Dictionary in (defender["auras"] as Array).duplicate():
		if a["kind"] != "thorns" or not _consume_charge(a):
			continue
		var value := RpgPaladinProcs.mastered_value(defender, str(a["id"]), float(a["value"]))
		RpgCombat.deal_damage(
			w, defender, attacker, int(value), false, str(a["school"]), str(a["id"]), "hit", true
		)
		if defender["kind"] == "player":
			RpgShamanWar.ward_smoothing(w, defender, str(a["id"]))
			if a["id"] == "lightning_shield":
				RpgShamanWar.on_thunder_ward_retaliated(w, defender)
			RpgTalentProcs.on_thorns_reflect(w, defender, str(a["id"]))
	for a: Dictionary in (defender["auras"] as Array).duplicate():
		if a["kind"] == "thorns" and a.get("charges") != null and int(a["charges"]) <= 0:
			defender["auras"].erase(a)
			w.log_event(
				{"type": "aura", "target": defender["id"], "name": a["id"], "gained": false}
			)


## consumeThornsCharge.
static func _consume_charge(a: Dictionary) -> bool:
	if a.get("charges") != null and int(a["charges"]) <= 0:
		return false
	if float(a.get("icd", 0.0)) > RpgCast.CAST_COMPLETE_EPS:
		return false
	if a.get("charges") != null:
		a["charges"] = int(a["charges"]) - 1
	if a.get("icd_max") != null:
		a["icd"] = float(a["icd_max"])
	return true


## tickThornsCooldown.
static func tick(w: RpgEncounter, a: Dictionary) -> void:
	if a["kind"] == "thorns" and float(a.get("icd", 0.0)) > 0.0:
		a["icd"] = maxf(0.0, float(a["icd"]) - w.dt)
