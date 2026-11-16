class_name TradeCart
extends RefCounted
## A shop cart: the items a player picks to buy from one shop, or to sell to
## it, gathered first and settled together in one checkout. Every limit and
## price comes from ShopRules, so a cart can never hold or settle a deal the
## shop itself would refuse. Pure rules: the server can take a cart (its mode,
## shop and lines) as one request and run the same checks.
##
## The checkout is all or nothing: everything is checked before anything
## changes hands, and a deal that fails part way (it should not) puts the
## coins and the bag back as they were.

const BUY := "buy"
const SELL := "sell"
## Most different items one cart holds (a size limit on one request).
const MAX_LINES := 20

var mode := BUY
var shop_id := ""
## {item key: amount}, in the order they were added.
var lines := {}


func _init(p_mode: String, p_shop_id: String) -> void:
	mode = p_mode
	shop_id = p_shop_id


## What one `item_id` costs (buying) or pays (selling) at this shop.
static func unit_price(content: ContentDB, p_mode: String, item_id: String) -> int:
	if p_mode == SELL:
		return ShopRules.sell_price(content, item_id)
	return int(content.item(item_id).get("price", 0))


## The most of `item_id` this cart may hold: buying, one deal's worth of a
## ware (ShopRules.max_amount: stacks of food and materials, gear one at a
## time); selling, every one carried that the shop will take. 0 when the shop
## does not trade it.
func limit(profile: PlayerProfile, content: ContentDB, item_id: String) -> int:
	if mode == SELL:
		return profile.count(item_id) if ShopRules.sell_price(content, item_id) > 0 else 0
	if not ShopRules.is_open(profile, content, shop_id):
		return 0
	if item_id not in ShopRules.wares(profile, content, shop_id):
		return 0
	return ShopRules.max_amount(content, item_id)


func amount(item_id: String) -> int:
	return int(lines.get(item_id, 0))


## Adds up to `count` of `item_id`, as far as limit() and MAX_LINES allow.
## Returns how many went in.
func add(profile: PlayerProfile, content: ContentDB, item_id: String, count := 1) -> int:
	if not lines.has(item_id) and lines.size() >= MAX_LINES:
		return 0
	var added := clampi(count, 0, limit(profile, content, item_id) - amount(item_id))
	if added > 0:
		lines[item_id] = amount(item_id) + added
	return added


## Takes up to `count` of `item_id` back out. Returns how many came out.
func take(item_id: String, count := 1) -> int:
	var taken := clampi(count, 0, amount(item_id))
	if taken == amount(item_id):
		lines.erase(item_id)
	elif taken > 0:
		lines[item_id] = amount(item_id) - taken
	return taken


func clear() -> void:
	lines.clear()


func is_empty() -> bool:
	return lines.is_empty()


## How many items the cart holds in all.
func count_items() -> int:
	var total := 0
	for item_id: String in lines:
		total += amount(item_id)
	return total


## What the whole cart costs or pays.
func total(content: ContentDB) -> int:
	var sum := 0
	for item_id: String in lines:
		sum += unit_price(content, mode, item_id) * amount(item_id)
	return sum


## Brings the cart in line with the bag and the shop now (an item sold, eaten
## or dropped meanwhile, a stack used up): lines over their limit shrink,
## lines no longer possible go. Returns true when anything changed.
func prune(profile: PlayerProfile, content: ContentDB) -> bool:
	var changed := false
	for item_id: String in lines.keys():
		var most := limit(profile, content, item_id)
		if amount(item_id) > most:
			changed = true
			if most <= 0:
				lines.erase(item_id)
			else:
				lines[item_id] = most
	return changed


## True when selling the cart would part with rare gear or an upgraded item,
## which asks once more before it goes.
func precious(profile: PlayerProfile, content: ContentDB) -> bool:
	if mode != SELL:
		return false
	for item_id: String in lines:
		if is_precious(profile, content, item_id):
			return true
	return false


## Rare (or better) gear, or an item carrying upgrades.
static func is_precious(profile: PlayerProfile, content: ContentDB, item_id: String) -> bool:
	var rarity := str(content.item(item_id).get("rarity", ""))
	return EnhanceRules.item_level(profile, item_id) > 0 or ContentDB.RARITIES.find(rarity) >= 2


## Why the cart cannot be settled now, or "": "empty", "too_many_lines", "bad_amount",
## "closed", "not_sold", "not_owned", "not_for_sale" or "not_enough_money".
func problem(profile: PlayerProfile, content: ContentDB) -> String:
	if lines.is_empty():
		return "empty"
	if lines.size() > MAX_LINES:
		return "too_many_lines"
	if mode == BUY and not ShopRules.is_open(profile, content, shop_id):
		return "closed"
	for item_id: String in lines:
		var why := _line_problem(profile, content, item_id)
		if why:
			return why
	if mode == BUY and profile.money < total(content):
		return "not_enough_money"
	return ""


## Why line `item_id` cannot be settled, or "".
func _line_problem(profile: PlayerProfile, content: ContentDB, item_id: String) -> String:
	if amount(item_id) < 1:
		return "bad_amount"
	if amount(item_id) <= limit(profile, content, item_id):
		return ""
	if mode == BUY:
		return "not_sold"
	return "not_owned" if ShopRules.sell_price(content, item_id) > 0 else "not_for_sale"


## Settles the whole cart through ShopRules, in deals of at most what one
## deal allows. Returns {"error": problem() or "", "items": how many changed
## hands, "coins": what was paid or earned}; on any error nothing changed and
## the cart is kept, on success the cart is empty.
func checkout(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	var error := problem(profile, content)
	if error:
		return {"error": error, "items": 0, "coins": 0}
	var before := {
		"money": profile.money,
		"inventory": profile.inventory.duplicate(true),
		"enhance": profile.enhance.duplicate(true),
		"enhance_pity": profile.enhance_pity.duplicate(true),
	}
	var items := 0
	for item_id: String in lines:
		var left := amount(item_id)
		var deal_most := (
			ShopRules.max_amount(content, item_id) if mode == BUY else ShopRules.MAX_AMOUNT
		)
		while left > 0:
			var deal := mini(left, deal_most)
			if mode == BUY:
				error = ShopRules.buy(profile, shop_id, item_id, content, deal)
			else:
				error = ShopRules.sell(profile, item_id, content, deal)
			if error:
				profile.money = before["money"]
				profile.inventory = before["inventory"]
				profile.enhance = before["enhance"]
				profile.enhance_pity = before["enhance_pity"]
				return {"error": error, "items": 0, "coins": 0}
			items += deal
			left -= deal
	var coins := absi(profile.money - int(before["money"]))
	lines.clear()
	return {"error": "", "items": items, "coins": coins}
