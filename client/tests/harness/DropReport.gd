class_name DropReport
extends RefCounted
## Writes docs/ITEM_DROP_DATABASE.md from the game's own data through
## LootIndex, so the report always says what the game does:
##   godot --headless --path client --script res://tests/harness/DropReportRun.gd
## test_loot_index.gd fails when the committed report is out of date.

const KIND_NAMES := {
	LootIndex.MONSTER: "Monster",
	LootIndex.ELITE: "Elite",
	LootIndex.MINI_BOSS: "Mini-boss",
	LootIndex.STAGE_BOSS: "Stage boss",
	LootIndex.WORLD_BOSS: "World boss",
	LootIndex.RAID_BOSS: "Raid world boss",
}
const HOW := {
	"loot": "own loot table",
	"catalog": "catalog drop table",
	"boss_list": "boss's own list",
	"ground": "farming ground prize",
	"elite": "field elite",
	"tier": "personal tier",
	"kill": "kill reward",
}


static func build(content: ContentDB) -> String:
	var out: PackedStringArray = []
	out.append("# Item and drop database")
	out.append("")
	out.append("Generated from the game's data by `client/tests/harness/DropReport.gd`")
	out.append("(LootIndex). Do not edit by hand: change the data and run")
	out.append("`godot --headless --path client --script res://tests/harness/DropReportRun.gd`.")
	out.append("")
	out.append("- Chances are the **actual chance per kill** (or per reward), worked out from the")
	out.append("  rules, never rolled. A selection weight is never shown as a chance: section G")
	out.append("  gives the conditional shares of the catalog's drop tables separately.")
	out.append("- Legacy drops (`items.json` items in enemies' tables, farming grounds, world")
	out.append("  bosses) are the game's existing values, preserved.")
	out.append("- The catalog's drops (`drop_tables.json`) are **INITIAL BALANCE VALUES**,")
	out.append("  not yet playtested.")
	out.append("")
	_items(content, out)
	var groups := {}
	for enemy_id: String in content.enemies:
		var kind := LootIndex.kind_of(content, enemy_id)
		if kind == LootIndex.TRAINING:
			continue
		var key := "monster" if kind in [LootIndex.MONSTER, LootIndex.ELITE] else kind
		if not groups.has(key):
			groups[key] = []
		groups[key].append(enemy_id)
	var sections := [
		["B. Monster drop matrix", "monster"],
		["C. Mini-boss drop matrix", LootIndex.MINI_BOSS],
		["D. Stage boss drop matrix", LootIndex.STAGE_BOSS],
		["E. World boss drop matrix", LootIndex.WORLD_BOSS],
		["F. Raid world boss drop matrix", LootIndex.RAID_BOSS],
	]
	for section: Array in sections:
		out.append("## " + str(section[0]))
		out.append("")
		if section[1] in [LootIndex.WORLD_BOSS, LootIndex.RAID_BOSS]:
			out.append("Tiers and the kill are paid only when the boss falls within its round,")
			out.append("to everyone who fought it (WorldBossRules); a hero who fell or left still")
			out.append("counts what they dealt. No entry limits or waiting times.")
			out.append("")
		for enemy_id: String in groups.get(section[1], []):
			_enemy(content, enemy_id, out)
	_steps(content, out)
	_index(content, out)
	return "\n".join(out) + "\n"


static func _items(content: ContentDB, out: PackedStringArray) -> void:
	out.append("## A. Item catalog")
	out.append("")
	out.append("| Item ID | Name | Category | Grade | Slot | Level | Stats | Sources |")
	out.append("|---|---|---|---|---|---|---|---|")
	var ids: Array = content.items.keys()
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var ca := ItemCatalog.category(content.item(a))
			var cb := ItemCatalog.category(content.item(b))
			return [ca, a] < [cb, b]
	)
	for id: String in ids:
		var item := content.item(id)
		var stats: Array[String] = []
		for key: String in item.get("stats", {}):
			stats.append("%s %s" % [key, item["stats"][key]])
		for key: String in ["heal", "energy"]:
			if item.has(key):
				stats.append("%s %s" % [key, item[key]])
		var found := LootIndex.sources(content, id).size()
		(
			out
			. append(
				(
					"| `%s` | %s | %s | %s | %s | %s | %s | %s |"
					% [
						id,
						item.get("name", id),
						ItemCatalog.category(item),
						item.get("rarity", ""),
						item.get("slot", "-"),
						item.get("level", "-"),
						", ".join(stats) if stats else "-",
						found if found else "none",
					]
				)
			)
		)
	out.append("")


static func _enemy(content: ContentDB, enemy_id: String, out: PackedStringArray) -> void:
	var enemy := content.enemy(enemy_id)
	var kind := LootIndex.kind_of(content, enemy_id)
	var places: Array[String] = []
	for place: Dictionary in LootIndex.places(content, enemy_id):
		var area := content.area(str(place["area"]))
		places.append(
			(
				"%s (Lv %d, %s)"
				% [area.get("name", place["area"]), int(area.get("level", 0)), place["how"]]
			)
		)
	out.append(
		"### %s (`%s`, %s)" % [enemy.get("name", enemy_id), enemy_id, KIND_NAMES.get(kind, kind)]
	)
	out.append("")
	out.append("- Found: " + (", ".join(places) if places else "no fixed place (a summon)"))
	var money: Array = enemy.get("loot", {}).get("money", [0, 0])
	out.append("- Coins: %d to %d per kill" % [int(money[0]), int(money[1])])
	out.append("")
	out.append("| Item | Grade | Chance per kill | Quantity | From | Where / condition |")
	out.append("|---|---|---|---|---|---|")
	for drop: Dictionary in LootIndex.drops(content, enemy_id):
		var item := content.item(str(drop["item"]))
		var where := (
			str(content.area(str(drop["area"])).get("name", ""))
			if drop["area"]
			else "anywhere it fights"
		)
		if drop["condition"]:
			where += "; " + str(drop["condition"])
		var span: Array = drop["quantity"]
		(
			out
			. append(
				(
					"| %s (`%s`) | %s | %s | %s | %s | %s |"
					% [
						item.get("name", drop["item"]),
						drop["item"],
						item.get("rarity", ""),
						"guaranteed" if drop["guaranteed"] else percent(drop["chance"]),
						str(span[0]) if span[0] == span[1] else "%d-%d" % [span[0], span[1]],
						HOW.get(drop["how"], drop["how"]),
						where,
					]
				)
			)
		)
	out.append("")


static func _steps(content: ContentDB, out: PackedStringArray) -> void:
	out.append("## G. Drop probability: per-kill chances and conditional shares")
	out.append("")
	out.append("An enemy's own loot table and a farming ground's prizes roll each item")
	out.append("independently: the chance listed is the chance per kill. A catalog table")
	out.append("rolls in steps; each share below is **conditional** on the step before.")
	out.append("")
	var drops: Dictionary = content.catalog.drops
	for name: String in drops.get("tables", {}):
		var table: Dictionary = drops["tables"][name]
		var source := str(table["source"])
		out.append("### Table `%s` (%s)" % [name, source])
		out.append("")
		out.append(
			(
				"- Rolls per kill: %d; a roll drops something: %s"
				% [int(table.get("rolls", 1)), percent(float(table["chance"]))]
			)
		)
		var cats: Dictionary = table["categories"]
		var total := DropTables._total(cats)
		out.append("")
		out.append("| Category | Share of a drop | Grade shares within it | Quantity |")
		out.append("|---|---|---|---|")
		for cat: String in cats:
			var pool := DropTables.pool_for(content, cat, source)
			var grades := DropTables.grade_weights(content, source, pool)
			var grade_total := DropTables._total(grades)
			var parts: Array[String] = []
			for grade: String in grades:
				parts.append(
					(
						"%s %s (%d items)"
						% [grade, percent(grades[grade] / grade_total), pool[grade].size()]
					)
				)
			var span: Array = table.get("quantity", {}).get(cat, [1, 1])
			out.append(
				(
					"| %s | %s | %s | %d-%d |"
					% [cat, percent(cats[cat] / total), ", ".join(parts), span[0], span[1]]
				)
			)
		out.append("")
	out.append("Grade weights by source (shares of a successful drop, before limiting to")
	out.append(
		(
			"the grades a category has): monster %s; boss %s."
			% [str(drops["grade_weights"]["monster"]), str(drops["grade_weights"]["boss"])]
		)
	)
	out.append("")


static func _index(content: ContentDB, out: PackedStringArray) -> void:
	out.append("## H. Item acquisition index")
	out.append("")
	var ids: Array = content.items.keys()
	ids.sort()
	for id: String in ids:
		var found := LootIndex.sources(content, id)
		var lines: Array[String] = []
		for source: Dictionary in found:
			match source["kind"]:
				"enemy":
					var enemy := content.enemy(str(source["id"]))
					var where := (
						str(content.area(str(source["area"])).get("name", ""))
						if source["area"]
						else ""
					)
					(
						lines
						. append(
							(
								"%s %s (%s%s)"
								% [
									enemy.get("name", source["id"]),
									(
										"guaranteed"
										if source["guaranteed"]
										else percent(source["chance"])
									),
									HOW.get(source["how"], source["how"]),
									", " + where if where else "",
								]
							)
						)
					)
				"shop":
					lines.append(
						"shop %s, %d coins" % [content.shops[source["id"]]["name"], source["price"]]
					)
				"quest":
					lines.append('quest "%s"' % content.quests[source["id"]]["name"])
		out.append(
			(
				"- `%s` %s: %s"
				% [
					id,
					content.item(id).get("name", id),
					"; ".join(lines) if lines else "**not currently obtainable**"
				]
			)
		)
	out.append("")


static func percent(chance: float) -> String:
	return LootIndex.percent_text(chance)


## docs/GODFORGED_IMPACT_REPORT.md: every Godforged item a non-raid world
## boss pays today, and what moving those rewards would change. Analysis only:
## no reward is changed by it.
static func godforged_impact(content: ContentDB) -> String:
	var out: PackedStringArray = []
	out.append("# Godforged impact report")
	out.append("")
	out.append("Generated by `client/tests/harness/DropReport.gd` (`godforged_impact`) from the")
	out.append("game's data. **Analysis only: no reward has been changed.** The owner's rule")
	out.append("says Godforged comes from Raid world bosses only; today all eight world")
	out.append("bosses pay Godforged prizes. Changing that waits for the owner's approval.")
	out.append("")
	var raid_levels: Array[int] = []
	var by_slot_raid := {}
	var rows: Array = []
	for boss: String in content.world_bosses:
		var spec: Dictionary = content.world_bosses[boss]
		var raid := bool(spec.get("raid", false))
		var name := str(content.enemy(str(spec["enemy"])).get("name", boss))
		if raid:
			raid_levels.append(int(spec["level"]))
		for drop: Dictionary in LootIndex.drops(content, str(spec["enemy"])):
			var item := content.item(str(drop["item"]))
			if item.get("rarity") != "godforged":
				continue
			if raid:
				by_slot_raid[item.get("slot", "")] = true
			else:
				rows.append([boss, name, int(spec["level"]), int(spec["players"]), drop, item])
	raid_levels.sort()
	out.append("## Raid world bosses (keep their Godforged)")
	out.append("")
	for boss: String in content.world_bosses:
		var spec: Dictionary = content.world_bosses[boss]
		if spec.get("raid", false):
			out.append(
				(
					"- %s (`%s`): Lv %d, built for %d players"
					% [
						content.enemy(str(spec["enemy"])).get("name", boss),
						boss,
						spec["level"],
						spec["players"]
					]
				)
			)
	out.append("")
	out.append("## Godforged paid by non-raid world bosses today")
	out.append("")
	out.append(
		"| World boss | Lv | Players | Item | Slot | Item Lv | Reward | Chance | Other sources |"
	)
	out.append("|---|---|---|---|---|---|---|---|---|")
	var items := {}
	for row: Array in rows:
		var drop: Dictionary = row[4]
		var item: Dictionary = row[5]
		var others := LootIndex.sources(content, str(drop["item"])).filter(
			func(s: Dictionary) -> bool:
				return s.get("id", "") != str(content.world_bosses[row[0]]["enemy"])
		)
		items[drop["item"]] = others.is_empty()
		(
			out
			. append(
				(
					"| %s | %d | %d | %s (`%s`) | %s | %d | %s | %s | %s |"
					% [
						row[1],
						row[2],
						row[3],
						item.get("name", drop["item"]),
						drop["item"],
						item.get("slot", "-"),
						int(item.get("level", 0)),
						drop["condition"],
						"guaranteed" if drop["guaranteed"] else percent(drop["chance"]),
						"none" if others.is_empty() else str(others.size()),
					]
				)
			)
		)
	out.append("")
	var only := items.keys().filter(func(id: String) -> bool: return items[id])
	var lowest := 999
	var slots := {}
	for row: Array in rows:
		lowest = mini(lowest, int(row[2]))
		slots[row[5].get("slot", "")] = true
	var lost_slots := slots.keys().filter(func(s: String) -> bool: return not by_slot_raid.has(s))
	var arena := 0
	for preset: Dictionary in content.arena.get("presets", {}).values():
		for worn: Dictionary in preset.get("slots", {}).values():
			if str(worn.get("item", "")) in items:
				arena += 1
	out.append("## What changing it would mean")
	out.append("")
	out.append(
		(
			"- %d distinct Godforged items come from non-raid world bosses; %d of them have"
			% [items.size(), only.size()]
		)
	)
	out.append("  no other source and would become unobtainable unless moved to another source.")
	out.append(
		(
			"- The first Godforged a player can earn today is at Lv %d (a non-raid world boss);"
			% lowest
		)
	)
	out.append(
		(
			"  with raids only it would be Lv %d (the lowest raid)."
			% (raid_levels[0] if raid_levels else 0)
		)
	)
	out.append(
		(
			"- Slots with Godforged only from non-raid bosses: %s."
			% (", ".join(lost_slots) if lost_slots else "none (raids cover every slot they do)")
		)
	)
	out.append(
		"- Arena rival presets wearing these items: %d slots (arena.json presets); the" % arena
	)
	out.append("  rivals' gear is a loadout, not a reward, and would not change.")
	out.append("- Players who already own these items keep them (saves hold item ids).")
	out.append("- The non-raid world bosses would need another top prize (Legendary gear or")
	out.append("  boss materials) so each keeps a reason to be fought.")
	out.append("")
	return "\n".join(out) + "\n"
