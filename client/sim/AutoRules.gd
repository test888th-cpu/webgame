class_name AutoRules
extends RefCounted
## Where auto battle is allowed: in any area with a fight in it, story areas
## not cleared yet and their bosses included (AutoPilot plays only the
## buttons a player has, so it can win nothing a player could not), every
## world boss arena, and a farming ground once it is open
## (AreaRules.unlocked). Following the story (StoryAuto), it also starts
## where there is no one to fight, such as the hub or a quest giver's rest
## point, as long as the story has a next step.
## `is_beaten` tells which street areas the hero has already passed
## (StreetMemory.passed). Derived from what the profile already keeps, so
## nothing new is saved. Pure rules, shared with the server.
##
## It also holds the farm loop's decisions: when to go home and rest, what
## the taxi back costs, restocking food at home, and wearing better gear.

## Health share below which a hero with nothing to eat goes home to rest.
const LOW_HEALTH := 0.35


## Why auto battle cannot run in `area_id` right now, or "" when it can.
## `story`: auto follows the story (StoryAuto) when there is no fight here.
static func problem(
	profile: PlayerProfile, content: ContentDB, area_id: String, story := true
) -> String:
	if AreaRules.kind(content, area_id) == AreaRules.FARM:
		return (
			"" if AreaRules.unlocked(profile, content, area_id) else "This ground is not open yet."
		)
	if AreaRules.kind(content, area_id) == AreaRules.LAIR:
		if not AreaRules.unlocked(profile, content, area_id):
			return "This lair is not open yet."
	if not content.area(area_id).get("encounters", []).is_empty():
		return ""
	var world := bool(content.area(area_id).get("world_boss", false))
	if story and not world:
		if StoryAuto.step(profile, content, area_id, true)["do"] != StoryAuto.DONE:
			return ""
	return "No one to fight here."


## True once the hero has passed `area_id`: walked on to the next area east
## (its gate opened and was passed), or, at the end of the street, beaten
## every boss fighting there.
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
## health is low with nothing left to eat and no fight on to finish. Never
## in a world boss arena: the attempt is fought to its end.
static func wants_rest(zone: ZoneSim, pilot: AutoPilot) -> bool:
	if zone.area.get("world_boss", false):
		return false
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


## What auto pays to go from `home` to `to`: nothing to stay, nothing to a
## place one walk away (the city and Depot Yard are next door), else the
## taxi's fare (0 when `home` has no taxi).
static func ride_fare(content: ContentDB, home: String, to: String) -> int:
	if home == to or AreaRules.next_door(content, home, to):
		return 0
	return maxi(0, fare(content, home))


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
		if not ShopRules.is_open(profile, content, shop_id):
			continue
		var sold: Array = ShopRules.wares(profile, content, shop_id)
		for food in FoodRules.shopping_list(content, sold, max_hp):
			var price := int(content.item(food)["price"])
			while FoodRules.carried(profile, content) < keep and profile.money - price >= reserve:
				if ShopRules.buy(profile, shop_id, food, content) != "":
					break
				bought += 1
	return bought


## Puts on, slot by slot, the best gear the hero carries that beats what is
## worn (ItemRules.is_upgrade, the bag's "better" mark), as a player would
## from the bag. Returns the item keys put on.
static func wear_upgrades(profile: PlayerProfile, content: ContentDB) -> Array[String]:
	var best := {}
	for key: String in profile.inventory:
		if not ItemRules.is_upgrade(profile, key, content):
			continue
		var slot := str(content.item(key).get("slot", ""))
		var score := ItemRules.copy_score(profile, key, content)
		if not best.has(slot) or score > float(best[slot]["score"]):
			best[slot] = {"key": key, "score": score}
	var worn: Array[String] = []
	for slot: String in best:
		var key := str(best[slot]["key"])
		if profile.equip(key, content):
			worn.append(key)
	return worn
