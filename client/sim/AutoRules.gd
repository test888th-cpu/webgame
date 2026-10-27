class_name AutoRules
extends RefCounted
## Where auto battle is allowed: only in an area the hero has already beaten,
## so it farms streets the player has won by hand and never plays new ones
## for them. An area counts as beaten once the hero has walked on to the next
## area east (its gate opened and was passed), or, at the end of the street,
## once every boss fighting there has been defeated. Derived from what the
## profile already keeps, so nothing new is saved. Pure rules, shared with the
## server.
##
## It also holds the farm loop's decisions: when to go home and rest, what
## the taxi back costs, and restocking food at home.

## Health share below which a hero with nothing to eat goes home to rest.
const LOW_HEALTH := 0.35


## Why auto battle cannot run in `area_id` right now, or "" when it can.
static func problem(profile: PlayerProfile, content: ContentDB, area_id: String) -> String:
	var area := content.area(area_id)
	if area.get("encounters", []).is_empty():
		return "Nothing to fight here."
	if area.get("world_boss", false):
		return "Auto battle is not allowed against the World Boss."
	if not is_beaten(profile, content, area_id):
		return "Auto unlocks once you have cleared this area yourself."
	return ""


## True once the hero has beaten `area_id` by hand (see the class comment).
static func is_beaten(profile: PlayerProfile, content: ContentDB, area_id: String) -> bool:
	var area := content.area(area_id)
	var east: Dictionary = area.get("exits", {}).get("east", {})
	if east:
		return str(east["to"]) in profile.visited
	var bosses := 0
	for encounter: Dictionary in area.get("encounters", []):
		for wave: Array in encounter["waves"]:
			for kind: String in wave:
				if content.enemy(kind).get("boss", false):
					bosses += 1
					if int(profile.defeated.get(kind, 0)) == 0:
						return false
	return bosses > 0


## True when a farming hero should go home to rest: the area is cleared, or
## health is low with nothing left to eat and no fight on to finish.
static func wants_rest(zone: ZoneSim, pilot: AutoPilot) -> bool:
	if pilot.status == AutoPilot.STATUS_CLEAR:
		return true
	if zone.in_encounter() or zone.hero.is_ko():
		return false
	var share := float(zone.hero.hp) / maxf(1.0, zone.hero.max_hp)
	return share < LOW_HEALTH and not pilot.has_heals(zone.profile)


## The taxi fare from `area_id` (its travel NPC's), or -1 with no taxi there.
static func fare(content: ContentDB, area_id: String) -> int:
	for npc: Dictionary in content.area(area_id).get("npcs", []):
		if npc.get("role") == "travel":
			return int(npc.get("fare", 0))
	return -1


## Buys food sold in `area_id` (the best buy for this hero first, see
## FoodRules.shopping_list) until the hero carries `keep` foods in all, never
## spending the coins kept back (`reserve`, the taxi fare back out). Returns
## how many were bought.
static func restock(
	profile: PlayerProfile, content: ContentDB, area_id: String, keep: int, reserve: int
) -> int:
	var max_hp := int(profile.stats(content)["max_hp"])
	var bought := 0
	for npc: Dictionary in content.area(area_id).get("npcs", []):
		if npc.get("role") != "shop":
			continue
		var shop_id := str(npc["shop"])
		var sold: Array = content.shops.get(shop_id, {}).get("items", [])
		for food in FoodRules.shopping_list(content, sold, max_hp):
			var price := int(content.item(food)["price"])
			while FoodRules.carried(profile, content) < keep and profile.money - price >= reserve:
				if ShopRules.buy(profile, shop_id, food, content) != "":
					break
				bought += 1
	return bought
