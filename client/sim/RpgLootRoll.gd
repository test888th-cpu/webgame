class_name RpgLootRoll
extends RefCounted
## Corpse loot for one recipient, as World of ClaudeCraft rolls it
## (src/sim/loot/loot_roll.ts rollLoot, then loot/enemy_quality.ts):
## * entries in table order; a normalOnly row is skipped (no draw) on a heroic claim;
## * a roll group draws ONE next(), partitioned by its rows' chances; a winner already
##   awarded on this kill falls forward to the next row of its group; a soulbound
##   class-locked row the recipient cannot use is removed and the group rescaled
##   (loot/class_locked_drop.ts usableRollGroup), its total kept;
## * a questId row draws only if the recipient needs it, and drops personally;
## * any other row is one chance(); copper pays int(ceil(base x 0.6), ceil(base x 1.4));
## * then one quality per copy of each quality-eligible item (quest drops excluded),
##   loot_quality/core.ts createLootQuality: int(0, 9999), and from 9000 five
##   int(1, 1000) weights.
## Entries use the loot registry's fields (item, copper, chance, roll_group, quest_id,
## normal_only, heroic_copper). Heroic variant swaps are not modelled: the runtime
## has no heroic claims (a heroic claim is refused by the caller).


## {copper, items: [{item_id, count, quality, quest}]}. `items_db`: item id -> record
## with kind, slot, quality, soulbound, required_class. `needs_quest`: Callable(quest_id)
## -> bool. `quality_source`: the killed mob may mint quality.
static func roll(
	entries: Array,
	items_db: Dictionary,
	recipient_class: String,
	needs_quest: Callable,
	quality_source: bool,
	rng: RpgRng,
	heroic := false
) -> Dictionary:
	var copper := 0
	var items: Array = []
	var rolled_groups := {}
	var awarded := {}
	for entry: Dictionary in entries:
		if heroic and entry.get("normal_only", false):
			continue
		var group: Variant = entry.get("roll_group")
		if group != null:
			if rolled_groups.has(group):
				continue
			rolled_groups[group] = true
			var rows := usable_group(
				entries.filter(func(e: Dictionary) -> bool: return e.get("roll_group") == group),
				items_db,
				recipient_class
			)
			var winner := pick_group_winner(rng.next(), rows, awarded)
			if not winner.is_empty() and winner.get("item") != null:
				items.append(_slot(str(winner["item"]), false))
				awarded[str(winner["item"])] = true
			continue
		var quest: Variant = entry.get("quest_id")
		if quest != null:
			# needsQuestDrop is false without an item, so such a row draws nothing.
			if entry.get("item") == null or not needs_quest.call(str(quest)):
				continue
			if not rng.chance(float(entry["chance"])):
				continue
			items.append(_slot(str(entry["item"]), true))
			continue
		if not rng.chance(float(entry["chance"])):
			continue
		if entry.get("copper") != null and float(entry["copper"]) > 0:
			var base := float(entry["copper"])
			copper += rng.int_range(ceili(base * 0.6), ceili(base * 1.4))
		var item_id: Variant = entry.get("item")
		if item_id != null and usable(str(item_id), items_db, recipient_class):
			items.append(_slot(str(item_id), false))
	if quality_source:
		for slot: Dictionary in items:
			if slot["quest"]:
				continue
			var def: Dictionary = items_db.get(slot["item_id"], {})
			if def.is_empty() or not quality_eligible(def):
				continue
			slot["quality"] = create_quality(rng)
	return {"copper": copper, "items": items}


static func _slot(item_id: String, quest: bool) -> Dictionary:
	return {"item_id": item_id, "count": 1, "quality": null, "quest": quest}


## pickRollGroupWinner: the first row whose cumulative chance exceeds the draw; an
## already awarded item falls forward through the group; {} when nothing drops.
static func pick_group_winner(draw: float, rows: Array, awarded: Dictionary) -> Dictionary:
	var cumulative := 0.0
	var index := -1
	for i in rows.size():
		cumulative += float(rows[i]["chance"])
		if draw < cumulative:
			index = i
			break
	if index == -1:
		return {}
	for offset in rows.size():
		var candidate: Dictionary = rows[(index + offset) % rows.size()]
		if candidate.get("item") == null or not awarded.has(str(candidate["item"])):
			return candidate
	return {}


## usableRollGroup: drop rows the recipient cannot use; rescale the rest so the
## group's total stays the same (the last row takes the remainder).
static func usable_group(rows: Array, items_db: Dictionary, cls: String) -> Array:
	var kept := rows.filter(
		func(e: Dictionary) -> bool:
			return e.get("item") == null or usable(str(e["item"]), items_db, cls)
	)
	if kept.size() == rows.size():
		return rows
	if kept.is_empty():
		return []
	var total := 0.0
	for e: Dictionary in rows:
		total += float(e["chance"])
	var kept_total := 0.0
	for e: Dictionary in kept:
		kept_total += float(e["chance"])
	if kept_total <= 0.0:
		return []
	var scale := total / kept_total
	var cumulative := 0.0
	var out := []
	for i in kept.size():
		var c := total - cumulative if i == kept.size() - 1 else float(kept[i]["chance"]) * scale
		cumulative += c
		var copy: Dictionary = kept[i].duplicate()
		copy["chance"] = c
		out.append(copy)
	return out


## lootItemUsableByClasses: only a soulbound, class-restricted item is withheld.
static func usable(item_id: String, items_db: Dictionary, cls: String) -> bool:
	var def: Dictionary = items_db.get(item_id, {})
	var req: Variant = def.get("required_class")
	if not def.get("soulbound", false) or not (req is Array) or (req as Array).is_empty():
		return true
	return cls in req


## isEligibleLootQualityItem.
static func quality_eligible(def: Dictionary) -> bool:
	var q: String = str(def.get("quality")) if def.get("quality") != null else "common"
	return (
		def.get("slot") != null
		and str(def.get("kind")) in ["weapon", "armor", "held_offhand"]
		and q in ["uncommon", "rare", "epic", "legendary"]
	)


## createLootQuality: null for an ordinary copy, else {tier, weights}.
static func create_quality(rng: RpgRng) -> Variant:
	var draw := rng.int_range(0, 9999)
	if draw < 9000:
		return null
	var tier := 1 if draw < 9900 else 2 if draw < 9990 else 3 if draw < 9999 else 4
	var weights := []
	for _i in 5:
		weights.append(rng.int_range(1, 1000))
	return {"tier": tier, "weights": weights}
