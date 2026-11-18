extends SceneTree
## Content completeness audit (docs/CONTENT_COMPLETENESS_AUDIT.md). Read-only.
##
##   godot --headless --path client --script res://tests/harness/ContentAudit.gd -- --out=<file>
##
## Writes one JSON report built only through the game's own rules, so the audit
## cannot disagree with play:
## * every item (items.json + item_catalog.json) with its fields and every
##   source LootIndex knows (enemy drops with the real per-kill chance, shops,
##   quests) plus hero starter kits;
## * every enemy with its places (LootIndex.places) and its drops
##   (LootIndex.drops);
## * the upgrade table as EnhanceRules prices it (rate, cost at item levels 1,
##   51 and 61, bonus per level);
## * counts of skills, moves, boss skills, areas, shops and quests;
## * problems: items with no source, drops naming an unknown item, chances
##   outside 0..1, enemies placed nowhere, and ContentDB's own validation.

const ITEM_LEVELS: Array[int] = [1, 51, 61]


func _initialize() -> void:
	var out := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var content := ContentDB.load_all()
	var report := {
		"items": _items(content),
		"enemies": _enemies(content),
		"enhance": _enhance(content),
		"counts": _counts(content),
		"problems": _problems(content),
	}
	var text := JSON.stringify(report, " ", true)
	if out == "":
		print(text)
	else:
		var file := FileAccess.open(out, FileAccess.WRITE)
		file.store_string(text)
		file.close()
		print("content audit written to ", out)
	quit()


func _starters(content: ContentDB) -> Dictionary:
	var out := {}
	for hero_id: String in content.heroes:
		var starter: Dictionary = content.hero(hero_id).get("starter", {})
		for item_id: String in starter.get("equipment", []):
			out[item_id] = true
		for item_id: String in starter.get("items", {}):
			out[item_id] = true
	return out


func _items(content: ContentDB) -> Dictionary:
	var starters := _starters(content)
	var out := {}
	for item_id: String in content.items:
		var item: Dictionary = content.item(item_id)
		out[item_id] = {
			"name": str(item.get("name", "")),
			"slot": str(item.get("slot", "")),
			"type": str(item.get("type", "")),
			"category": str(item.get("category", "")),
			"rarity": str(item.get("rarity", "")),
			"level": int(item.get("level", 0)),
			"price": int(item.get("price", 0)),
			"stats": item.get("stats", {}),
			"icon": str(item.get("icon", "")),
			"catalog": item_id in content.catalog.added,
			"starter": starters.has(item_id),
			"sources": LootIndex.sources(content, item_id),
		}
	return out


func _enemies(content: ContentDB) -> Dictionary:
	var out := {}
	for enemy_id: String in content.enemies:
		var enemy: Dictionary = content.enemy(enemy_id)
		out[enemy_id] = {
			"name": str(enemy.get("name", "")),
			"kind": LootIndex.kind_of(content, enemy_id),
			"level": int(enemy.get("level", 0)),
			"max_hp": int(enemy.get("max_hp", 0)),
			"xp": int(enemy.get("xp", 0)),
			"training": bool(enemy.get("training", false)),
			"places": LootIndex.places(content, enemy_id),
			"drops": LootIndex.drops(content, enemy_id),
			"money": enemy.get("loot", {}).get("money", [0, 0]),
		}
	return out


func _enhance(content: ContentDB) -> Dictionary:
	var enhance: Dictionary = content.progression.get("enhance", {})
	var rows: Array = []
	var levels: Array = enhance.get("levels", [])
	for i in levels.size():
		var row := {"to": i + 1, "rate": float(levels[i].get("rate", 0.0)), "cost": {}}
		for item_level in ITEM_LEVELS:
			row["cost"][str(item_level)] = EnhanceRules.scaled_cost(
				levels[i], enhance.get("item_level_costs", []), item_level
			)
		rows.append(row)
	return {
		"max": EnhanceRules.max_level(content),
		"bonus_per_level": float(enhance.get("bonus_per_level", 0.0)),
		"levels": rows,
	}


func _counts(content: ContentDB) -> Dictionary:
	return {
		"items": content.items.size(),
		"catalog_items": content.catalog.added.size(),
		"enemies": content.enemies.size(),
		"areas": content.areas.size(),
		"skills": content.skills.size(),
		"moves": content.moves.moves.size() if content.moves != null else 0,
		"shops": content.shops.size(),
		"quests": content.quests.size(),
		"heroes": content.heroes.size(),
		"world_bosses": content.world_bosses.size(),
	}


func _problems(content: ContentDB) -> Array:
	var out: Array = []
	for error: String in content.errors:
		out.append("content: " + error)
	var starters := _starters(content)
	for item_id: String in content.items:
		if LootIndex.sources(content, item_id).is_empty() and not starters.has(item_id):
			out.append("item without any source: " + item_id)
	for enemy_id: String in content.enemies:
		var enemy: Dictionary = content.enemy(enemy_id)
		if enemy.get("training", false):
			continue
		if LootIndex.places(content, enemy_id).is_empty():
			out.append("enemy placed in no area: " + enemy_id)
		for drop: Dictionary in LootIndex.drops(content, enemy_id):
			var item_id := str(drop["item"])
			if item_id != "" and content.item(item_id).is_empty():
				out.append("%s drops unknown item %s" % [enemy_id, item_id])
			var chance := float(drop["chance"])
			if chance < 0.0 or chance > 1.0:
				out.append("%s drop %s chance %f outside 0..1" % [enemy_id, item_id, chance])
	return out
