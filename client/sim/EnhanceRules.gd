class_name EnhanceRules
extends RefCounted
## Upgrading gear at the workbench. An upgrade belongs to one *copy* of an
## item (+0 to +N, N from progression.json): it gives bonus_per_level more of
## the item's own stats per level while worn, and stays with that copy when
## it is taken off. The first attempt on a worn item makes it a copy of its
## own (PlayerProfile.own_copy), so identical items in the bag stay +0.
## The workbench upgrades what is worn, so these rules take the slot and
## work on the item in it. Each attempt costs coins and materials and
## succeeds at the level's rate; a failure keeps the item and the level, and
## adds pity_per_fail to that item's next try until one succeeds.
## The random roll comes from the caller (the server, once online).


## The upgrade level of the item worn in `slot` (0 when the slot is empty).
static func level(profile: PlayerProfile, slot: String) -> int:
	return item_level(profile, str(profile.equipment.get(slot, "")))


## The upgrade level of the copy with key `item_id`, worn or in the bag.
static func item_level(profile: PlayerProfile, item_id: String) -> int:
	return int(profile.enhance.get(item_id, 0)) if item_id else 0


static func max_level(content: ContentDB) -> int:
	return content.progression.get("enhance", {}).get("levels", []).size()


## What the next level of `slot` costs: {"coins", "items": {id: count},
## "rate"}, or {} at the top.
static func next_cost(profile: PlayerProfile, slot: String, content: ContentDB) -> Dictionary:
	var levels: Array = content.progression.get("enhance", {}).get("levels", [])
	var current := level(profile, slot)
	return levels[current] if current < levels.size() else {}


## The chance the next attempt on `slot` succeeds, pity included.
static func chance(profile: PlayerProfile, slot: String, content: ContentDB) -> float:
	var cost := next_cost(profile, slot, content)
	if cost.is_empty():
		return 0.0
	var pity := float(content.progression["enhance"].get("pity_per_fail", 0.0))
	var item_id := str(profile.equipment.get(slot, ""))
	return minf(1.0, float(cost["rate"]) + pity * int(profile.enhance_pity.get(item_id, 0)))


## Why `slot` cannot be upgraded now ("" if it can): "empty" (nothing worn),
## "max", "coins" or "materials".
static func problem(profile: PlayerProfile, slot: String, content: ContentDB) -> String:
	if str(profile.equipment.get(slot, "")) == "":
		return "empty"
	var cost := next_cost(profile, slot, content)
	if cost.is_empty():
		return "max"
	if profile.money < int(cost["coins"]):
		return "coins"
	for item_id: String in cost["items"]:
		if profile.count(item_id) < int(cost["items"][item_id]):
			return "materials"
	return ""


## One attempt, all or nothing: checks, pays, rolls, applies. Returns
## {"result": "success" | "fail" | a problem(), "level": the slot's level}.
static func attempt(
	profile: PlayerProfile, slot: String, content: ContentDB, rng: RandomNumberGenerator
) -> Dictionary:
	var blocked := problem(profile, slot, content)
	if blocked:
		return {"result": blocked, "level": level(profile, slot)}
	var copy := profile.own_copy(slot)
	var cost := next_cost(profile, slot, content)
	var odds := chance(profile, slot, content)
	profile.money -= int(cost["coins"])
	for material: String in cost["items"]:
		profile.remove_item(material, int(cost["items"][material]))
	if rng.randf() < odds:
		profile.enhance[copy] = level(profile, slot) + 1
		profile.enhance_pity.erase(copy)
		return {"result": "success", "level": level(profile, slot)}
	profile.enhance_pity[copy] = int(profile.enhance_pity.get(copy, 0)) + 1
	return {"result": "fail", "level": level(profile, slot)}


## The extra stats upgrades add to `item` worn in `slot`: bonus_per_level of
## each of its positive stats per level (penalties are never amplified).
static func bonus(
	profile: PlayerProfile, slot: String, item: Dictionary, content: ContentDB
) -> Dictionary:
	var extra := {}
	var steps := level(profile, slot)
	if steps == 0:
		return extra
	var per := float(content.progression.get("enhance", {}).get("bonus_per_level", 0.0))
	var stats: Dictionary = item.get("stats", {})
	for key: String in stats:
		var value := float(stats[key])
		if value <= 0.0:
			continue
		var add := value * per * steps
		extra[key] = roundi(add) if key in ["max_hp", "defense"] else add
	return extra
