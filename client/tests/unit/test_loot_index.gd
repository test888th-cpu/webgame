extends TestCase
## LootIndex: every source of every item, from the rules that pay it, with
## the real chance per kill (closed form, checked against the formulas and a
## seeded run), the grade rules, a loot identity for every boss, and the
## generated docs/ITEM_DROP_DATABASE.md kept in step with the data.

const RAID: Array[String] = ["floodgate_marshal", "crucible_king", "founders_engine"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_committed_report_is_what_the_data_says() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../docs/ITEM_DROP_DATABASE.md")
	var committed := FileAccess.get_file_as_string(path)
	assert_true(committed != "", "docs/ITEM_DROP_DATABASE.md exists")
	assert_true(
		committed == DropReport.build(_content()),
		"out of date: run res://tests/harness/DropReportRun.gd"
	)


func test_every_enemy_has_a_traceable_drop_list() -> void:
	var c := _content()
	for enemy_id: String in c.enemies:
		var kind := LootIndex.kind_of(c, enemy_id)
		if kind == LootIndex.TRAINING:
			assert_true(LootIndex.drops(c, enemy_id).is_empty(), "the dummy drops nothing")
			continue
		var list := LootIndex.drops(c, enemy_id)
		assert_true(not list.is_empty(), enemy_id + ": something to drop")
		for drop: Dictionary in list:
			assert_true(c.items.has(drop["item"]), "%s: %s exists" % [enemy_id, drop["item"]])
			var chance := float(drop["chance"])
			assert_true(
				chance > 0.0 and chance <= 1.0, "%s: %s a real chance" % [enemy_id, drop["item"]]
			)
			var span: Array = drop["quantity"]
			assert_true(span[0] >= 1 and span[1] >= span[0], "%s: quantity range" % enemy_id)
			assert_eq(drop["guaranteed"], chance >= 1.0, "%s: guaranteed only at 100%%" % enemy_id)


func test_chances_follow_the_rules_exactly() -> void:
	var c := _content()
	for enemy_id: String in ["smogling", "director_wiroj"]:
		for drop: Dictionary in LootIndex.drops(c, enemy_id):
			match drop["how"]:
				"catalog":
					var s: Dictionary = drop["steps"]
					var one: float = (
						s["roll_chance"] * s["category_share"] * s["grade_share"] * s["item_share"]
					)
					var want := 1.0 - pow(1.0 - one, s["rolls"])
					assert_near(
						drop["chance"], want, "%s %s: closed form" % [enemy_id, drop["item"]]
					)
				"loot":
					var table: Array = c.enemy(enemy_id)["loot"]["drops"]
					var own := table.filter(
						func(d: Dictionary) -> bool: return d["item"] == drop["item"]
					)
					assert_near(drop["chance"], float(own[0]["chance"]), "%s: its table" % enemy_id)
	# A farming ground: the loot at its reward scale, an elite's three rolls.
	var farm := "farm_saltmarket_backlots"
	var spawning: Dictionary = c.area(farm)["spawning"]
	var scale := float(spawning.get("reward_scale", 1.0))
	var base := float(c.enemy("smogling")["loot"]["drops"][0]["chance"])
	for drop: Dictionary in LootIndex.drops(c, "smogling"):
		if drop["area"] == farm and drop["item"] == c.enemy("smogling")["loot"]["drops"][0]["item"]:
			if drop["how"] == "loot":
				assert_near(drop["chance"], minf(1.0, base * scale), "scaled in the ground")
			elif drop["how"] == "elite":
				var one := minf(1.0, base * scale)
				assert_near(drop["chance"], 1.0 - pow(1.0 - one, 3), "an elite rolls three times")


func test_a_seeded_run_agrees_with_the_worked_out_chances() -> void:
	var c := _content()
	var odds := {}
	for drop: Dictionary in LootIndex.drops(c, "smogling"):
		if drop["how"] == "catalog":
			odds[drop["item"]] = drop["chance"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var kills := 60000
	var seen := {}
	for kill in kills:
		var got := {}
		for drop: Dictionary in DropTables.roll(c, "smogling", rng):
			got[drop["item"]] = true
		for id: String in got:
			seen[id] = int(seen.get(id, 0)) + 1
	for id: String in ["enhance_stone_basic", "ore_iron", "focus_gum"]:
		var expected: float = odds[id] * kills
		var tolerance := 4.0 * sqrt(expected) + 2.0
		assert_true(
			absf(float(seen.get(id, 0)) - expected) <= tolerance,
			"%s: %d seen, %.0f expected" % [id, seen.get(id, 0), expected]
		)


func test_grade_rules_hold_in_every_source() -> void:
	var c := _content()
	assert_eq(
		c.world_bosses.keys().filter(
			func(b: String) -> bool: return c.world_bosses[b].get("raid", false)
		),
		RAID,
		"the three raid world bosses are marked"
	)
	for enemy_id: String in c.enemies:
		var kind := LootIndex.kind_of(c, enemy_id)
		for drop: Dictionary in LootIndex.drops(c, enemy_id):
			var grade := str(c.item(drop["item"]).get("rarity", ""))
			if kind in [LootIndex.MONSTER, LootIndex.ELITE]:
				assert_true(
					grade not in ["legendary", "godforged"], "%s: %s" % [enemy_id, drop["item"]]
				)
				assert_true(
					not c.item(drop["item"]).get("boss_only", false), enemy_id + ": no boss prize"
				)
			if grade == "godforged":
				assert_true(
					drop["how"] in ["tier", "kill"],
					"%s: Godforged only as a world boss reward" % enemy_id
				)


func test_every_boss_has_a_loot_identity() -> void:
	var c := _content()
	var monster_items := {}
	for enemy_id: String in c.enemies:
		if LootIndex.kind_of(c, enemy_id) in [LootIndex.MONSTER, LootIndex.ELITE]:
			for drop: Dictionary in LootIndex.drops(c, enemy_id):
				# A farming ground's prizes (its field elites carry the district
				# bosses' Epic gear by design) are the ground's, not the monster's.
				if drop["how"] in ["loot", "catalog"]:
					monster_items[drop["item"]] = true
	var lists := {}
	for enemy_id: String in c.enemies:
		if LootIndex.kind_of(c, enemy_id) not in LootIndex.BOSSES:
			continue
		var own := {}
		for drop: Dictionary in LootIndex.drops(c, enemy_id):
			if (
				drop["how"] in ["loot", "boss_list", "tier", "kill"]
				and not monster_items.has(drop["item"])
			):
				own[drop["item"]] = true
		assert_true(not own.is_empty(), enemy_id + ": something no ordinary monster drops")
		var key := ",".join(own.keys())
		assert_true(not lists.has(key), "%s: not the same list as %s" % [enemy_id, lists.get(key)])
		lists[key] = enemy_id


func test_sources_and_the_item_card_agree() -> void:
	var c := _content()
	for id: String in c.items:
		var found := LootIndex.sources(c, id)
		var card := ItemSources.of(c, id)
		assert_eq(found.is_empty(), card.is_empty(), id + ": both find a source, or neither")
		for source: Dictionary in found:
			if source["kind"] == "enemy":
				var places := LootIndex.places(c, str(source["id"]))
				var area := str(source["area"])
				assert_true(
					area == "" or places.any(func(p: Dictionary) -> bool: return p["area"] == area),
					"%s: %s fights where it drops" % [id, source["id"]]
				)


func test_an_area_lists_who_is_there_and_what_drops() -> void:
	var c := _content()
	var info := LootIndex.area_info(c, "farm_saltmarket_backlots")
	var ids: Array = info["enemies"].map(func(e: Dictionary) -> String: return e["id"])
	for kind: String in c.area("farm_saltmarket_backlots")["spawning"]["pool"]:
		assert_true(kind in ids, kind + " is listed")
	for drop: Dictionary in c.area("farm_saltmarket_backlots")["spawning"]["drops"]:
		assert_true(info["items"].has(drop["item"]), str(drop["item"]) + ": the ground's prize")


func test_the_godforged_impact_report_is_up_to_date() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join(
		"../docs/GODFORGED_IMPACT_REPORT.md"
	)
	assert_true(
		FileAccess.get_file_as_string(path) == DropReport.godforged_impact(_content()),
		"out of date: run res://tests/harness/DropReportRun.gd"
	)


func test_sources_and_drops_agree_both_ways() -> void:
	var c := _content()
	for enemy_id: String in c.enemies:
		for drop: Dictionary in LootIndex.drops(c, enemy_id):
			var back := LootIndex.sources(c, str(drop["item"])).filter(
				func(s: Dictionary) -> bool:
					return (
						s.get("id") == enemy_id
						and s.get("how") == drop["how"]
						and s.get("area") == drop["area"]
					)
			)
			assert_true(
				not back.is_empty(), "%s -> %s: in the item's sources" % [enemy_id, drop["item"]]
			)
	for id: String in c.items:
		for source: Dictionary in LootIndex.sources(c, id):
			if source["kind"] == "enemy":
				var there := LootIndex.drops(c, str(source["id"])).filter(
					func(d: Dictionary) -> bool:
						return d["item"] == id and d["how"] == source["how"]
				)
				assert_true(not there.is_empty(), "%s <- %s: really drops it" % [id, source["id"]])
			elif source["kind"] == "shop":
				assert_true(c.shops.has(source["id"]), id + ": a real shop")
			else:
				assert_true(c.quests.has(source["id"]), id + ": a real quest")


func test_reward_types_and_data_status() -> void:
	var c := _content()
	var seen := {}
	for enemy_id: String in ["director_wiroj", "iron_colossus", "smogling"]:
		for drop: Dictionary in LootIndex.drops(c, enemy_id):
			var type := LootIndex.reward_type(drop)
			seen[type] = true
			if drop["how"] in ["tier", "kill", "elite"]:
				assert_eq(type, LootIndex.CONDITIONAL, "%s: on a condition" % drop["item"])
				assert_true(drop["condition"] != "", "and the condition is said")
			elif drop["guaranteed"]:
				assert_eq(type, LootIndex.GUARANTEED, drop["item"])
			if drop["pity"]:
				assert_true("rises" in str(drop["condition"]), "pity explained")
				assert_true("(rises)" in GuidePages.drop_text(c, drop), "and shown")
			var initial: bool = drop["how"] in ["catalog", "boss_list"]
			assert_eq(LootIndex.data_status(drop) == LootIndex.INITIAL, initial, drop["item"])
			assert_eq(GuidePages.drop_text(c, drop).ends_with("*"), initial, "marked *")
	assert_eq(seen.size(), 3, "guaranteed, random and conditional all met")
