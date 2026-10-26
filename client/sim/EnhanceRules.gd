class_name EnhanceRules
extends RefCounted
## Upgrading gear at the workbench. Upgrades belong to the equipment *slot*
## (+0 to +N, N from progression.json): whatever is worn there gets
## bonus_per_level more of its own stats per level, so changing gear never
## throws an upgrade away. Each attempt costs coins and materials and
## succeeds at the level's rate; a failure keeps the item and the level, and
## adds pity_per_fail to the next try in that slot until one succeeds.
## The random roll comes from the caller (the server, once online).


static func level(profile: PlayerProfile, slot: String) -> int:
	return int(profile.enhance.get(slot, 0))


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
	return minf(1.0, float(cost["rate"]) + pity * int(profile.enhance_pity.get(slot, 0)))


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
	var cost := next_cost(profile, slot, content)
	var odds := chance(profile, slot, content)
	profile.money -= int(cost["coins"])
	for item_id: String in cost["items"]:
		profile.remove_item(item_id, int(cost["items"][item_id]))
	if rng.randf() < odds:
		profile.enhance[slot] = level(profile, slot) + 1
		profile.enhance_pity.erase(slot)
		return {"result": "success", "level": level(profile, slot)}
	profile.enhance_pity[slot] = int(profile.enhance_pity.get(slot, 0)) + 1
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
