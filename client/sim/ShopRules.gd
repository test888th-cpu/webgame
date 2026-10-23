class_name ShopRules
extends RefCounted
## Buying from a shop. Prices and stock come from shops.json / items.json.


## Returns "" on success, otherwise the reason: "unknown_shop", "not_sold" or
## "not_enough_money".
static func buy(
	profile: PlayerProfile, shop_id: String, item_id: String, content: ContentDB
) -> String:
	var shop: Dictionary = content.shops.get(shop_id, {})
	if shop.is_empty():
		return "unknown_shop"
	if item_id not in shop.get("items", []):
		return "not_sold"
	var price := int(content.item(item_id).get("price", 0))
	if profile.money < price:
		return "not_enough_money"
	profile.money -= price
	profile.add_item(item_id)
	return ""
