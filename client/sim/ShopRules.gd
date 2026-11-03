class_name ShopRules
extends RefCounted
## Buying from and selling to a shop. Prices and stock come from shops.json /
## items.json; a shop buys anything with a price except evidence, at
## progression.json "sell_rate" of the price. Pure rules, so the server can
## run the same ones once the game is online.
##
## The city has one merchant (Ama's Market): its own "items" from the start,
## and more "stock" ([{"reached": area, "from": who brings it, "items"}]) as
## the story reaches each chapter, the wares of the street's other traders,
## brought to her stall. The wares are shown in one list, food first.

## Most of one stackable item bought or sold in one go.
const MAX_AMOUNT := 99


## True when `shop_id` trades with the hero: always, or once the story has
## reached the area in its "unlock" ({"reached": area}). The city's market
## holds every merchant; each opens for the chapter that brings them in.
static func is_open(profile: PlayerProfile, content: ContentDB, shop_id: String) -> bool:
	var rule: Dictionary = content.shops.get(shop_id, {}).get("unlock", {})
	return not rule.has("reached") or str(rule["reached"]) in profile.visited


## What a closed shop says: "Opens once you have reached Port Road.", or "".
static func closed_text(profile: PlayerProfile, content: ContentDB, shop_id: String) -> String:
	if is_open(profile, content, shop_id):
		return ""
	var place := str(content.shops[shop_id]["unlock"]["reached"])
	return "Opens once you have reached %s." % content.area(place).get("name", place)


## Everything `shop` (its shops.json entry) ever sells, in data order, once.
static func all_items(shop: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var lists: Array = [shop.get("items", [])]
	for stock: Dictionary in shop.get("stock", []):
		lists.append(stock.get("items", []))
	for list: Array in lists:
		for item_id: Variant in list:
			if str(item_id) not in out:
				out.append(str(item_id))
	return out


## What `shop_id` sells the hero now: its own items and every stock whose
## chapter is reached, once each; food and materials first (cheapest first),
## then gear by level.
static func wares(profile: PlayerProfile, content: ContentDB, shop_id: String) -> Array[String]:
	var shop: Dictionary = content.shops.get(shop_id, {})
	var open := shop.duplicate()
	open["stock"] = shop.get("stock", []).filter(
		func(stock: Dictionary) -> bool: return str(stock.get("reached", "")) in profile.visited
	)
	var out := all_items(open)
	out.sort_custom(
		func(a: String, b: String) -> bool:
			var ka := _order(content.item(a))
			var kb := _order(content.item(b))
			return ka < kb if ka != kb else a < b
	)
	return out


## What new stock `shop_id` gets next: "Kenji brings new stock once you reach
## Night Market.", or "" when every stock is in.
static func next_stock(profile: PlayerProfile, content: ContentDB, shop_id: String) -> String:
	for stock: Dictionary in content.shops.get(shop_id, {}).get("stock", []):
		var place := str(stock.get("reached", ""))
		if place not in profile.visited:
			var name := str(content.area(place).get("name", place))
			return "%s brings new stock once you reach %s." % [stock.get("from", "More"), name]
	return ""


## What is wrong with shops.json, one message each: unknown items or areas.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	for id: String in content.shops:
		var shop: Dictionary = content.shops[id]
		for item_id in all_items(shop):
			if content.item(item_id).is_empty():
				out.append("shops.%s: unknown item %s" % [id, item_id])
		var places: Array = [shop.get("unlock", {}).get("reached", "")]
		for stock: Dictionary in shop.get("stock", []):
			places.append(stock.get("reached", "?"))
		for place: Variant in places:
			if str(place) != "" and content.area(str(place)).is_empty():
				out.append("shops.%s: unknown area %s" % [id, place])
	return out


## Sorting key: food, then materials, then gear; by level, then price.
static func _order(item: Dictionary) -> Array:
	var rank: int = {"consumable": 0, "material": 1}.get(item.get("type"), 2)
	return [rank, int(item.get("level", 0)), int(item.get("price", 0))]


## Returns "" on success, otherwise the reason: "unknown_shop", "closed",
## "not_sold", "bad_amount" or "not_enough_money".
static func buy(
	profile: PlayerProfile, shop_id: String, item_id: String, content: ContentDB, amount := 1
) -> String:
	var shop: Dictionary = content.shops.get(shop_id, {})
	if shop.is_empty():
		return "unknown_shop"
	if not is_open(profile, content, shop_id):
		return "closed"
	if item_id not in wares(profile, content, shop_id):
		return "not_sold"
	if amount < 1 or amount > max_amount(content, item_id):
		return "bad_amount"
	var price := int(content.item(item_id).get("price", 0)) * amount
	if profile.money < price:
		return "not_enough_money"
	profile.money -= price
	profile.add_item(item_id, amount)
	return ""


## What a shop pays for one `item_id`; 0 when it will not buy it.
static func sell_price(content: ContentDB, item_id: String) -> int:
	var item := content.item(item_id)
	if item.is_empty() or item.get("type") == "key":
		return 0
	# Gear no shop sells (boss and enemy drops) sells by its grade and level.
	return floori(ItemRules.value(item) * float(content.progression.get("sell_rate", 0.0)))


## Sells `amount` carried (not worn) `item_id`. Returns "" on success,
## otherwise "not_for_sale", "bad_amount" or "not_owned".
static func sell(
	profile: PlayerProfile, item_id: String, content: ContentDB, amount := 1
) -> String:
	var price := sell_price(content, item_id)
	if price <= 0:
		return "not_for_sale"
	if amount < 1 or amount > MAX_AMOUNT:
		return "bad_amount"
	if not profile.discard(item_id, content, amount):
		return "not_owned"
	profile.money += price * amount
	return ""


## How many of `item_id` one purchase may take: food and materials stack,
## gear is bought one at a time.
static func max_amount(content: ContentDB, item_id: String) -> int:
	var stacks: bool = content.item(item_id).get("type") in ["consumable", "material"]
	return MAX_AMOUNT if stacks else 1


## The most of `item_id` the hero can afford in one purchase (0 if none).
static func affordable(profile: PlayerProfile, content: ContentDB, item_id: String) -> int:
	var price := maxi(1, int(content.item(item_id).get("price", 0)))
	return mini(max_amount(content, item_id), profile.money / price)
