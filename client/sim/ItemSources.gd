class_name ItemSources
extends RefCounted
## Where an item comes from, for players (the item card's "Where to get"):
## who drops it and where they fight, the field elites of a farming ground
## (FarmSpawner "elite_drops"), the world bosses' reward rolls
## (world_boss.json tiers and kill), the shops and the quests. Worked out
## from the data on every call, so it can never disagree with the loot
## tables. Pure rules, shared with the server.

const DROP := "drop"
const ELITE := "elite"
const WORLD_BOSS := "world_boss"
const SHOP := "shop"
const QUEST := "quest"


## Every source of `key` (an item id or a copy key "<id>#<n>"): {"kind",
## "chance" (for the random ones), "text"}. Random sources come first, most
## likely first, then shops, then quests.
static func of(content: ContentDB, key: String) -> Array[Dictionary]:
	var item_id := ContentDB.base_id(key)
	var random: Array[Dictionary] = []
	random.append_array(_drops(content, item_id))
	random.append_array(_elites(content, item_id))
	random.append_array(_world_bosses(content, item_id))
	random.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["chance"] > b["chance"])
	var found: Array[Dictionary] = []
	found.append_array(random)
	for shop_id: String in content.shops:
		if item_id in ShopRules.all_items(content.shops[shop_id]):
			var price := int(content.item(item_id)["price"])
			var text := "%s, %d coins" % [content.shops[shop_id]["name"], price]
			found.append({"kind": SHOP, "text": text})
	for quest_id: String in content.quests:
		if content.quests[quest_id].get("rewards", {}).get("items", {}).has(item_id):
			found.append({"kind": QUEST, "text": 'Quest "%s"' % content.quests[quest_id]["name"]})
	return found


static func _drops(content: ContentDB, item_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for enemy_id: String in content.enemies:
		for drop: Dictionary in content.enemies[enemy_id].get("loot", {}).get("drops", []):
			if drop["item"] != item_id:
				continue
			var where := first_area_of(content, enemy_id)
			var text := (
				"%s (%s)%s"
				% [
					content.enemies[enemy_id]["name"],
					_percent(float(drop["chance"])),
					"  -  " + where if where else ""
				]
			)
			out.append({"kind": DROP, "chance": float(drop["chance"]), "text": text})
	return out


## A farming ground's field elites: any of its enemies may come as one.
static func _elites(content: ContentDB, item_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for area_id in AreaRules.farms(content):
		var spawning: Dictionary = content.area(area_id).get("spawning", {})
		for prize: Dictionary in spawning.get("elite_drops", []):
			if prize["item"] == item_id:
				var name := str(content.area(area_id).get("name", area_id))
				var chance := float(prize["chance"])
				var text := "Field elites, %s (%s)" % [name, _percent(chance)]
				out.append({"kind": ELITE, "chance": chance, "text": text})
	return out


## A world boss's reward rolls: the best chance, from a kill or a tier.
static func _world_bosses(content: ContentDB, item_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for boss: String in content.world_bosses:
		var spec: Dictionary = content.world_bosses[boss]
		var best := 0.0
		var rewards: Array = (spec.get("tiers", []) as Array).duplicate()
		rewards.append(spec.get("kill", {}))
		for reward: Dictionary in rewards:
			best = maxf(best, float(reward.get("rolls", {}).get(item_id, 0.0)))
		if best > 0.0:
			var name := str(content.enemy(str(spec["enemy"])).get("name", boss))
			var text := "World boss %s (up to %s)" % [name, _percent(best)]
			out.append({"kind": WORLD_BOSS, "chance": best, "text": text})
	return out


## The first area where `enemy_id` fights, its name: placed, in a fight, or
## in a farming ground's field. "" when it fights nowhere.
static func first_area_of(content: ContentDB, enemy_id: String) -> String:
	for area_id: String in content.areas:
		var area_data: Dictionary = content.areas[area_id]
		var found := false
		for placed: Dictionary in area_data.get("placed", []):
			found = found or placed["enemy"] == enemy_id
		for encounter: Dictionary in area_data.get("encounters", []):
			for wave: Variant in encounter.get("waves", []):
				found = found or enemy_id in (wave as Array)
		found = found or area_data.get("spawning", {}).get("pool", {}).has(enemy_id)
		if found:
			return str(area_data["name"])
	return ""


static func _percent(chance: float) -> String:
	var percent := chance * 100.0
	if percent >= 1.0:
		return "%d%%" % roundi(percent)
	return "%s%%" % String.num(percent, 1)
