class_name RpgQuality
extends RefCounted
## Item quality tiers and per-copy quality (Phase B2), read from
## client/data/rpg/quality.json, which tools/content/build_reference_registries.py
## generates from World of ClaudeCraft src/sim/types.ts (the quality union) and
## src/sim/loot_quality/core.ts createLootQuality (one integer draw; each outcome
## owns a share of it; +2 item levels per tier). Not used by gameplay yet: the
## game's legacy rarities are unchanged.


## The six reference quality tiers, lowest first.
static func tiers(content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for tier: Variant in content.rpg.get("quality", {}).get("tiers", []):
		out.append(str(tier))
	return out


static func _per_copy(content: ContentDB) -> Dictionary:
	return content.rpg.get("quality", {}).get("per_copy", {})


## The per-copy tier a draw lands on (0 = plain), as createLootQuality maps it.
static func tier_for_draw(content: ContentDB, draw: int) -> int:
	var at := int(_per_copy(content).get("draw_range", [0, 0])[0])
	for outcome: Dictionary in _per_copy(content).get("outcomes", []):
		at += int(outcome["draws"])
		if draw < at:
			return int(outcome["tier"])
	return -1


## The chance of per-copy tier `tier` (0 = plain): its share of the draw range.
static func probability(content: ContentDB, tier: int) -> float:
	var span := _span(content)
	for outcome: Dictionary in _per_copy(content).get("outcomes", []):
		if int(outcome["tier"]) == tier:
			return float(outcome["draws"]) / span if span > 0 else 0.0
	return 0.0


static func item_level_bonus(content: ContentDB, tier: int) -> int:
	for outcome: Dictionary in _per_copy(content).get("outcomes", []):
		if int(outcome["tier"]) == tier:
			return int(outcome["item_level_bonus"])
	return 0


static func _span(content: ContentDB) -> int:
	var draws: Array = _per_copy(content).get("draw_range", [0, -1])
	return int(draws[1]) - int(draws[0]) + 1


static func problems(content: ContentDB) -> PackedStringArray:
	var out := PackedStringArray()
	if tiers(content).size() != 6:
		out.append("rpg quality: expected 6 tiers, found %d" % tiers(content).size())
	if "godforged" in tiers(content):
		out.append("rpg quality: godforged is not a reference tier")
	var total := 0
	for outcome: Dictionary in _per_copy(content).get("outcomes", []):
		total += int(outcome["draws"])
	if total != _span(content) or total <= 0:
		out.append("rpg quality: per-copy draws sum to %d of %d" % [total, _span(content)])
	return out
