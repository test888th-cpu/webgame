class_name ItemRules
extends RefCounted
## What a piece of gear is worth for its grade (ADR: gear grades). Every
## equipment item's stats add up to a score (STAT_WEIGHTS); its budget is
## what its level, slot and rarity allow:
##
##   budget = (BASE + PER_LEVEL * level) * SLOT_WEIGHTS[slot] * GRADES[rarity]
##
## and its score must stay within TOLERANCE of it. So a grade always means the
## same step up, whatever the slot or level: shop gear is Common or Uncommon
## (the steady baseline), Rare comes from enemies, Epic and Legendary from
## bosses (a story boss's signature piece, a world boss's prize), and an Epic
## or Legendary beats what the shop sells at its level by a clear margin
## without leaping a whole chapter ahead. Content checks this on load, so a
## new item cannot slip in too weak or too strong for its grade.

## Score per unit of each stat: +0.01 power counts as 1, 2 max HP as 1, ...
const STAT_WEIGHTS := {
	"power": 100.0,
	"max_hp": 0.5,
	"defense": 5.0,
	"crit": 200.0,
	"attack_speed": 150.0,
	"speed": 100.0,
}
const BASE := 10.0
const PER_LEVEL := 2.0
## How much each slot carries against the others (a weapon most).
## Set from what the shop's gear was already worth, slot by slot.
const SLOT_WEIGHTS := {
	"weapon": 1.3,
	"body": 0.92,
	"head": 0.73,
	"hands": 0.66,
	"feet": 0.55,
	"charm": 0.75,
}
## Each grade's share of the budget; Uncommon is the shop's standard.
const GRADES := {
	"common": 0.85,
	"uncommon": 1.0,
	"rare": 1.15,
	"epic": 1.35,
	"legendary": 1.6,
}
const TOLERANCE := 0.15
## Who may sell each grade: the shop never sells Rare or better.
const SHOP_GRADES := ["common", "uncommon"]
## Coins per point of budget: what gear the shops do not sell (boss and
## enemy drops) is worth when sold, so a spare boss piece is never dead
## weight. About what the shops ask for gear of the same worth.
const VALUE_PER_POINT := 11.0


## What `item`'s stats add up to (STAT_WEIGHTS).
static func score(item: Dictionary) -> float:
	var total := 0.0
	var stats: Dictionary = item.get("stats", {})
	for key: String in stats:
		total += float(STAT_WEIGHTS.get(key, 0.0)) * float(stats[key])
	return total


## What `item` may be worth for its level, slot and rarity.
static func budget(item: Dictionary) -> float:
	var level := float(item.get("level", 1))
	var slot := float(SLOT_WEIGHTS.get(str(item.get("slot", "")), 1.0))
	var grade := float(GRADES.get(str(item.get("rarity", "")), 1.0))
	return (BASE + PER_LEVEL * level) * slot * grade


## The list price of `item`: its "price" when a shop sells it, else what its
## grade and level make it worth (ShopRules sells at a share of this).
static func value(item: Dictionary) -> int:
	var price := int(item.get("price", 0))
	if price > 0 or item.get("type") != "equipment":
		return price
	return roundi(budget(item) * VALUE_PER_POINT)


## What the copy with key `key` is worth to `profile` now: its stats with
## its upgrades (EnhanceRules), scored. 0 for "" or anything not gear.
static func copy_score(profile: PlayerProfile, key: String, content: ContentDB) -> float:
	var item := content.item(key)
	if item.get("type") != "equipment":
		return 0.0
	var total := score(item)
	var extra := {"stats": EnhanceRules.copy_bonus(profile, key, item, content)}
	return total + score(extra)


## True when the carried copy `key` would be an upgrade on what `profile`
## wears in its slot right now and the hero may wear it (the bag's green
## arrow): worth more, or the slot is empty.
static func is_upgrade(profile: PlayerProfile, key: String, content: ContentDB) -> bool:
	var item := content.item(key)
	if item.get("type") != "equipment" or int(item.get("level", 1)) > profile.level:
		return false
	var worn := str(profile.equipment.get(str(item.get("slot", "")), ""))
	return copy_score(profile, key, content) > copy_score(profile, worn, content) + 0.01


## What is wrong with the equipment's grades, one message each: a score
## outside its budget, or a shop selling Rare or better.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in content.items:
		var item: Dictionary = content.items[id]
		if not item is Dictionary or item.get("type") != "equipment":
			continue
		var want := budget(item)
		var got := score(item)
		if absf(got - want) > want * TOLERANCE:
			out.append(
				(
					"items.%s.stats: worth %.1f, a level %d %s %s is worth %.1f (within %d%%)"
					% [
						id,
						got,
						int(item.get("level", 1)),
						item.get("rarity"),
						item.get("slot"),
						want,
						roundi(TOLERANCE * 100)
					]
				)
			)
	out.append_array(_unique_problems(content))
	for shop_id: String in content.shops:
		for item_id: Variant in ShopRules.all_items(content.shops[shop_id]):
			var item := content.item(str(item_id))
			if item.get("type") == "equipment" and item.get("rarity") not in SHOP_GRADES:
				out.append(
					(
						"shops.%s: sells %s, a %s item (shops sell %s gear)"
						% [shop_id, item_id, item.get("rarity"), " or ".join(SHOP_GRADES)]
					)
				)
	return out


## A unique item ("unique": true) is a quest's prize only: no shop sells it
## and no enemy, field elite or world boss drops it.
static func _unique_problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var dropped := {}
	for shop_id: String in content.shops:
		for item_id: Variant in ShopRules.all_items(content.shops[shop_id]):
			dropped[str(item_id)] = "shops.%s" % shop_id
	for enemy_id: String in content.enemies:
		for drop: Dictionary in content.enemies[enemy_id].get("loot", {}).get("drops", []):
			dropped[str(drop["item"])] = "enemies.%s" % enemy_id
	for area_id: String in content.areas:
		for prize: Variant in FarmSpawner.spec(content, area_id).get("elite_drops", []):
			if prize is Dictionary:
				dropped[str(prize.get("item", ""))] = "areas.%s" % area_id
	for boss: String in content.world_bosses:
		var data: Dictionary = content.world_bosses[boss]
		for part: Variant in data.get("tiers", []) + [data.get("kill", {})]:
			if part is Dictionary:
				for item_id: String in part.get("rolls", {}):
					dropped[item_id] = "world_bosses.%s" % boss
	var rewarded := false
	for id: String in content.items:
		if not content.items[id] is Dictionary or not content.items[id].get("unique", false):
			continue
		if dropped.has(id):
			out.append("items.%s: unique, yet %s gives it" % [id, dropped[id]])
		rewarded = false
		for quest_id: String in content.quests:
			rewarded = (
				rewarded or content.quests[quest_id].get("rewards", {}).get("items", {}).has(id)
			)
		if not rewarded:
			out.append("items.%s: unique, so a quest must give it" % id)
	return out
