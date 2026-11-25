class_name RpgWorld
extends RefCounted
## Queries and small actions on the street world (RpgEncounter) that the class and
## cast modules share: targeting, facing, the shield check, taunts, the ranged
## profile and the swing views.


static func set_target(w: RpgEncounter, m: Dictionary) -> void:
	w.mob = m


## nearestAttackingMob: the nearest living monster engaged with the player.
static func nearest_attacking_mob(w: RpgEncounter) -> Dictionary:
	var best := {}
	for m: Dictionary in w.mobs:
		if m["dead"] or not m["engaged"]:
			continue
		if best.is_empty() or _d(w, m) < _d(w, best):
			best = m
	return best


static func _d(w: RpgEncounter, m: Dictionary) -> float:
	return absf(float(m["x"]) - float(w.player["x"]))


## The player turns to face `u` (the street's facing is a side).
static func face(w: RpgEncounter, u: Dictionary) -> void:
	var dx := float(u["x"]) - float(w.player["x"])
	if absf(dx) >= RpgAbilityRules.FACING_HOLD_DIST:
		w.player["facing"] = signf(dx)


## shieldEquipped.
static func player_has_shield(w: RpgEncounter) -> bool:
	var item := RpgPack.item(w.pack, str(w.state["equipment"].get("offhand", "")))
	return bool(item.get("shield", false))


## applyTaunt: the monster turns on the player (an idle one is pulled).
static func apply_taunt(w: RpgEncounter, _source: Dictionary, m: Dictionary) -> void:
	if m["dead"]:
		return
	m["engaged"] = true
	w.enter_combat(w.player, m)


## rangedAutoProfile: a wand is put away in a wandless form.
static func ranged_profile(w: RpgEncounter) -> Dictionary:
	var r: Variant = w.pack["classes"][str(w.state["class_id"])]["ranged"]
	if not (r is Dictionary):
		return {}
	if r.get("wand", false) and not RpgDruid.wand_allowed_in_form(w.player):
		return {}
	return r


## The fields RpgSwing reads, in its names (armor and attack power effective).
static func swing_view(w: RpgEncounter, u: Dictionary) -> Dictionary:
	return {
		"kind": u["kind"],
		"class_id": u.get("class_id", ""),
		"spec_id": u.get("spec_id", ""),
		"level": u["level"],
		"weapon": u.get("weapon", RpgUnit.UNARMED),
		"attack_power": RpgCombat.effective_attack_power(u),
		"crit": u.get("crit", 0.05),
		"crit_dmg_phys": u.get("crit_dmg_phys", 0.0),
		"dodge": u.get("dodge", 0.05),
		"hit_bonus": u.get("hit_bonus", 0.0),
		"armor": RpgCombat.effective_armor(w, u),
		"str": u.get("str", 0),
		"block_chance": u.get("block_chance", 0.0),
		"block_value": u.get("block_value", 0),
	}
