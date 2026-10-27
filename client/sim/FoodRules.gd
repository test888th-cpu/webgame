class_name FoodRules
extends RefCounted
## Food: which of what the hero carries to eat now, and which to buy. Eating
## takes the smallest food that makes up most of what is missing (the
## biggest one in real trouble), so the good food is kept for when it
## matters. Buying looks for food sized to the hero: about a third of their
## health per bite, so a level 30 hero does not live on steamed buns and a
## new one does not spend everything on tonics. Shared by the quick-heal key,
## auto battle and its farm loop. Pure rules, shared with the server.

## Eat this share of what is missing or more, if one food can.
const COVER := 0.6
## The heal a food should give, as a share of maximum health, when buying.
const BITE := 0.3


## Healing foods in `content`, the smallest heal first.
static func foods(content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for item_id: String in content.items:
		var item := content.item(item_id)
		if item.get("type") == "consumable" and int(item.get("heal", 0)) > 0:
			out.append(item_id)
	out.sort_custom(
		func(a: String, b: String) -> bool:
			var ha := int(content.item(a)["heal"])
			var hb := int(content.item(b)["heal"])
			return ha < hb if ha != hb else a < b
	)
	return out


## How many healing foods `profile` carries, all kinds together.
static func carried(profile: PlayerProfile, content: ContentDB) -> int:
	var count := 0
	for item_id in foods(content):
		count += profile.count(item_id)
	return count


## The food to eat with `missing` health gone, or "" with nothing to eat.
## `urgent` takes the biggest heal carried.
static func choose(
	profile: PlayerProfile, content: ContentDB, missing: int, urgent := false
) -> String:
	var owned: Array[String] = []
	for item_id in foods(content):
		if profile.count(item_id) > 0:
			owned.append(item_id)
	if owned.is_empty():
		return ""
	if urgent:
		return owned.back()
	for item_id in owned:
		if int(content.item(item_id)["heal"]) >= missing * COVER:
			return item_id
	return owned.back()


## Foods sold in `item_ids`, best buy first for a hero of `max_hp`: the heal
## nearest a third of their health, then the cheaper.
static func shopping_list(content: ContentDB, item_ids: Array, max_hp: int) -> Array[String]:
	var out: Array[String] = []
	for item_id: String in item_ids:
		if item_id in foods(content):
			out.append(item_id)
	var bite := max_hp * BITE
	out.sort_custom(
		func(a: String, b: String) -> bool:
			var da := absf(int(content.item(a)["heal"]) - bite)
			var db := absf(int(content.item(b)["heal"]) - bite)
			if da != db:
				return da < db
			return int(content.item(a)["price"]) < int(content.item(b)["price"])
	)
	return out
