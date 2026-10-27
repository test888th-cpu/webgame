class_name ShopRules
extends RefCounted
## Buying from and selling to a shop. Prices and stock come from shops.json /
## items.json; a shop buys anything with a price except evidence, at
## progression.json "sell_rate" of the price. Pure rules, so the server can
## run the same ones once the game is online.

## Most of one stackable item bought or sold in one go.
const MAX_AMOUNT := 99


## Returns "" on success, otherwise the reason: "unknown_shop", "not_sold",
## "bad_amount" or "not_enough_money".
static func buy(
	profile: PlayerProfile, shop_id: String, item_id: String, content: ContentDB, amount := 1
) -> String:
	var shop: Dictionary = content.shops.get(shop_id, {})
	if shop.is_empty():
		return "unknown_shop"
	if item_id not in shop.get("items", []):
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
	return floori(int(item.get("price", 0)) * float(content.progression.get("sell_rate", 0.0)))


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
