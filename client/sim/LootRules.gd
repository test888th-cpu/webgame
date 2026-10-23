class_name LootRules
extends RefCounted
## Rolls a loot table with a caller-supplied generator. Drops are decided by
## whoever owns the generator: the zone simulation today, the authoritative
## zone server in Milestone 4. A client never rolls its own loot online.


## Returns {"money": int, "items": Array[String]}.
static func roll(loot: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var money: Array = loot.get("money", [0, 0])
	var items: Array[String] = []
	for drop: Dictionary in loot.get("drops", []):
		if rng.randf() < float(drop["chance"]):
			items.append(str(drop["item"]))
	return {"money": rng.randi_range(int(money[0]), int(money[1])), "items": items}
