class_name EconomyRules
extends RefCounted
## Coins the game takes: the knock-out penalty and travel fares. Pure rules,
## so every place that charges (the taxi, the world boss ride, auto battle's
## ride back, getting up after a knock-out) charges the same way, and the
## server can run them once the game is online.


## What a knock-out costs: progression.json "defeat_money_loss" of the coins.
static func defeat_loss(profile: PlayerProfile, content: ContentDB) -> int:
	var rate := float(content.progression.get("defeat_money_loss", 0.0))
	return clampi(int(profile.money * rate), 0, profile.money)


## Takes `amount` coins if the hero has them. Returns false (taking nothing)
## when they do not or the amount is negative.
static func charge(profile: PlayerProfile, amount: int) -> bool:
	if amount < 0 or profile.money < amount:
		return false
	profile.money -= amount
	return true
