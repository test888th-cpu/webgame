class_name DropTables
extends RefCounted
## Drops of the catalog's items (drop_tables.json), rolled after an enemy's
## own loot table (LootRules, unchanged). Each roll of an enemy's table goes
## through separate steps, each configured on its own:
##   1. does a drop happen    the table's "chance", per roll ("rolls" a kill)
##   2. which category        "categories" weights
##   3. which grade           "grade_weights" of the table's "source"
##                            ("monster" or "boss"), among the grades that
##                            category has; these are shares of a successful
##                            drop, not chances per kill
##   4. which item            evenly among the eligible items of that grade
##   5. how many              "quantity" per category ([min, max], else 1)
## A boss also rolls its own list ("bosses": {kind: [{"item", "chance",
## "quantity"}]}): its signature materials and prizes.
## Eligibility: an ordinary monster never rolls a Legendary or Godforged item
## or a "boss_only" one; an item with "sources" comes only from those bosses'
## own lists; a disabled item never drops. World bosses keep their own reward
## rules (world_boss.json) and roll nothing here; nor do training dummies.
## The caller passes the generator (the zone's own, kept apart from the one
## its fights use, so adding drops changes no fight). Pure rules.

const NEVER_FROM_MONSTERS: Array[String] = ["legendary", "godforged"]


## The table `kind` rolls, or {} for none.
static func table_for(content: ContentDB, kind: String) -> Dictionary:
	var drops: Dictionary = content.catalog.drops if content.catalog else {}
	var enemy := content.enemy(kind)
	if drops.is_empty() or enemy.is_empty() or enemy.get("training", false):
		return {}
	if is_world_boss(content, kind):
		return {}
	var named := str(
		drops.get("enemies", {}).get(
			kind, drops["defaults"]["boss" if enemy.get("boss") else "monster"]
		)
	)
	return drops.get("tables", {}).get(named, {})


static func is_world_boss(content: ContentDB, kind: String) -> bool:
	for boss: String in content.world_bosses:
		if str(content.world_bosses[boss].get("enemy", "")) == kind:
			return true
	return false


## What a kill of `kind` in `area` drops: [{"item": id, "amount": n}].
## Nothing in a world boss arena: its rewards are world_boss.json's alone.
static func roll(
	content: ContentDB, kind: String, rng: RandomNumberGenerator, area := {}
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var table := table_for(content, kind)
	if table.is_empty() or area.get("world_boss", false):
		return out
	var source := str(table.get("source", "monster"))
	for n in int(table.get("rolls", 1)):
		if rng.randf() >= float(table.get("chance", 0.0)):
			continue
		var cat := _weighted(table.get("categories", {}), rng)
		var pool := pool_for(content, cat, source)
		var grade := _weighted(grade_weights(content, source, pool), rng)
		if grade == "":
			continue
		var ids: Array = pool[grade]
		var item_id := str(ids[rng.randi_range(0, ids.size() - 1)])
		var span: Array = table.get("quantity", {}).get(cat, [1, 1])
		out.append({"item": item_id, "amount": rng.randi_range(int(span[0]), int(span[1]))})
	if content.enemy(kind).get("boss", false):
		for entry: Dictionary in content.catalog.drops.get("bosses", {}).get(kind, []):
			if (
				rng.randf() < float(entry["chance"])
				and ItemCatalog.enabled(content.item(entry["item"]))
			):
				var span: Array = entry.get("quantity", [1, 1])
				var amount := rng.randi_range(int(span[0]), int(span[1]))
				out.append({"item": str(entry["item"]), "amount": amount})
	return out


## The catalog items a `source` ("monster" or "boss") table may roll in
## `category`, by grade: {grade: [ids]}.
static func pool_for(content: ContentDB, category: String, source: String) -> Dictionary:
	var pool := {}
	for id in content.catalog.added:
		var item := content.item(id)
		if ItemCatalog.category(item) != category or not ItemCatalog.enabled(item):
			continue
		if item.has("sources") or item.get("rarity") == "godforged":
			continue  # a named boss's own, or a world boss reward
		var monster := source != "boss"
		if monster and (item.get("boss_only", false) or item["rarity"] in NEVER_FROM_MONSTERS):
			continue
		if not pool.has(item["rarity"]):
			pool[item["rarity"]] = []
		pool[item["rarity"]].append(id)
	return pool


## The `source`'s grade weights limited to the grades `pool` has.
static func grade_weights(content: ContentDB, source: String, pool: Dictionary) -> Dictionary:
	var all: Dictionary = content.catalog.drops.get("grade_weights", {}).get(source, {})
	var out := {}
	for grade: String in ContentDB.RARITIES:
		if pool.has(grade) and float(all.get(grade, 0.0)) > 0.0:
			if source != "boss" and grade in NEVER_FROM_MONSTERS:
				continue
			out[grade] = float(all[grade])
	return out


## The chance each catalog item drops from one kill of `kind` (at least one
## of it), worked out from the tables rather than rolled: for "Where to get",
## the balance notes and the tests.
static func chances(content: ContentDB, kind: String) -> Dictionary:
	var out := table_chances(content, table_for(content, kind))
	if content.enemy(kind).get("boss", false) and content.catalog:
		for entry: Dictionary in content.catalog.drops.get("bosses", {}).get(kind, []):
			var id := str(entry["item"])
			out[id] = 1.0 - (1.0 - float(out.get(id, 0.0))) * (1.0 - float(entry["chance"]))
	return out


## The chance each catalog item drops from one kill rolling `table`.
static func table_chances(content: ContentDB, table: Dictionary) -> Dictionary:
	var per_roll := {}
	if table.is_empty():
		return {}
	var source := str(table.get("source", "monster"))
	var cats: Dictionary = table.get("categories", {})
	var cat_total := _total(cats)
	for cat: String in cats:
		var pool := pool_for(content, cat, source)
		var grades := grade_weights(content, source, pool)
		var grade_total := _total(grades)
		for grade: String in grades:
			for id: String in pool[grade]:
				var p: float = float(table.get("chance", 0.0)) * cats[cat] / cat_total
				p *= grades[grade] / grade_total / pool[grade].size()
				per_roll[id] = float(per_roll.get(id, 0.0)) + p
	var out := {}
	for id: String in per_roll:
		out[id] = 1.0 - pow(1.0 - float(per_roll[id]), int(table.get("rolls", 1)))
	return out


static func _weighted(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := _total(weights)
	if total <= 0.0:
		return ""
	var pick := rng.randf() * total
	for key: String in weights:
		pick -= float(weights[key])
		if pick < 0.0:
			return key
	return str(weights.keys()[-1])


static func _total(weights: Dictionary) -> float:
	var total := 0.0
	for key: String in weights:
		total += float(weights[key])
	return total


## What is wrong with drop_tables.json, one message each.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var drops: Dictionary = content.catalog.drops
	var weights: Dictionary = drops.get("grade_weights", {})
	for source: String in ["monster", "boss"]:
		if not weights.has(source):
			out.append("drop_tables.grade_weights.%s: required" % source)
	for grade: String in NEVER_FROM_MONSTERS:
		if float(weights.get("monster", {}).get(grade, 0.0)) != 0.0:
			out.append("drop_tables.grade_weights.monster.%s: must be 0" % grade)
	if float(weights.get("boss", {}).get("godforged", 0.0)) != 0.0:
		out.append("drop_tables.grade_weights.boss.godforged: world bosses only, must be 0")
	var tables: Dictionary = drops.get("tables", {})
	for name: String in tables:
		var table: Dictionary = tables[name]
		var chance := float(table.get("chance", -1.0))
		if chance < 0.0 or chance > 1.0:
			out.append("drop_tables.tables.%s.chance: expected 0..1" % name)
		if str(table.get("source", "")) not in ["monster", "boss"]:
			out.append("drop_tables.tables.%s.source: monster or boss" % name)
		for cat: String in table.get("categories", {}):
			if cat not in ItemCatalog.CATEGORIES:
				out.append("drop_tables.tables.%s.categories: unknown %s" % [name, cat])
	for source: String in drops.get("defaults", {}):
		if not tables.has(str(drops["defaults"][source])):
			out.append("drop_tables.defaults.%s: unknown table" % source)
	for kind: String in drops.get("enemies", {}):
		var named := str(drops["enemies"][kind])
		if not content.enemies.has(kind) or (named != "" and not tables.has(named)):
			out.append("drop_tables.enemies.%s: unknown enemy or table" % kind)
	for kind: String in drops.get("bosses", {}):
		if not content.enemy(kind).get("boss", false) or is_world_boss(content, kind):
			out.append("drop_tables.bosses.%s: not a story boss" % kind)
		for entry: Dictionary in drops["bosses"][kind]:
			var chance := float(entry.get("chance", -1.0))
			if content.item(str(entry.get("item"))).is_empty() or chance <= 0.0 or chance > 1.0:
				out.append("drop_tables.bosses.%s: bad entry %s" % [kind, entry])
	return out
