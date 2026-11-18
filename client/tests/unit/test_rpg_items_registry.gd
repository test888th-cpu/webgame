extends TestCase
## Phase B2 item and quality registries (docs/PHASE_B2_PLAN.md R4/R5), against the
## values read in World of ClaudeCraft source at the pinned commit:
## * the six quality tiers (src/sim/types.ts) and per-copy quality
##   (src/sim/loot_quality/core.ts: draw 0..9999, plain below 9000, then tiers
##   1-4 below 9900 / 9990 / 9999 / above, +2 item levels per tier);
## * the reference item registry (data/registry/reference_items.json, not
##   shipped): every record of the reference's ITEMS table and Studio overlay,
##   evaluated from source; kinds from the ItemKind union, qualities, resolved
##   class restrictions, selection;
## * the legacy item registry against the live files, which stay unchanged.

const COMMIT := "d2b91e0884cb269422c28d0b42d2a30a01de130a"
const TIERS: Array[String] = ["poor", "common", "uncommon", "rare", "epic", "legendary"]


func _registry(name: String) -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join("../data/registry/" + name)
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_quality_tiers_and_per_copy_shares_match_the_source() -> void:
	var content := GameSession.content
	assert_eq(RpgQuality.problems(content).size(), 0, "quality registry valid")
	assert_eq(RpgQuality.tiers(content), TIERS, "six tiers, as in types.ts")
	var want := [[0, 0.9, 0], [1, 0.09, 2], [2, 0.009, 4], [3, 0.0009, 6], [4, 0.0001, 8]]
	var total := 0.0
	for row: Array in want:
		assert_near(
			RpgQuality.probability(content, row[0]), row[1], "tier %d chance" % row[0], 1e-9
		)
		assert_eq(RpgQuality.item_level_bonus(content, row[0]), row[2], "tier %d bonus" % row[0])
		total += RpgQuality.probability(content, row[0])
	assert_near(total, 1.0, "the shares add up to exactly 100%", 1e-12)


func test_draw_boundaries_follow_create_loot_quality() -> void:
	var content := GameSession.content
	# createLootQuality: draw < 9000 plain; < 9900 tier 1; < 9990 tier 2;
	# < 9999 tier 3; otherwise tier 4.
	var cases := {0: 0, 8999: 0, 9000: 1, 9899: 1, 9900: 2, 9989: 2, 9990: 3, 9998: 3, 9999: 4}
	for draw: int in cases:
		assert_eq(RpgQuality.tier_for_draw(content, draw), cases[draw], "draw %d" % draw)


func test_reference_items_are_complete_and_labelled() -> void:
	var doc := _registry("reference_items.json")
	var items: Dictionary = doc["items"]
	assert_eq(doc["source"]["commit"], COMMIT, "pinned commit")
	assert_eq(int(doc["count"]), items.size(), "count matches")
	assert_eq(doc["tables"], {"ITEMS": 2221.0, "STUDIO_CONTENT.items": 42.0}, "evaluated tables")
	assert_eq(items.size(), 2263, "2,263 reference item records")
	var kinds: Array = doc["kinds"]
	assert_true("weapon" in kinds and "armor" in kinds, "kinds read from the ItemKind union")
	var excluded := 0
	var deferred := 0
	for item_id: String in items:
		var item: Dictionary = items[item_id]
		assert_eq(item["id"], item_id, item_id + ": id")
		assert_true(str(item["kind"]) in kinds, item_id + ": an ItemKind")
		assert_eq(item["namespaced_id"], "reference:" + item_id, item_id + ": namespaced")
		assert_eq(item["unknown_values"], [], item_id + ": fully evaluated")
		var quality: Variant = item["quality"]
		assert_true(quality == null or str(quality) in TIERS, item_id + ": reference quality")
		var file := str(item["ref"]["file"])
		assert_true(file.begins_with("src/sim/"), item_id + ": source file")
		assert_true(doc["source"]["inputs"].has(file), item_id + ": its file is hashed")
		var selection := str(item["selection"])
		if file == "src/sim/content/scorching_wastes.ts":
			assert_true(selection.begins_with("EXCLUDED"), item_id + ": Scorching Wastes excluded")
			excluded += 1
		elif file.begins_with("src/sim/content/rift/"):
			assert_true(selection.begins_with("DEFERRED"), item_id + ": Rift deferred")
			deferred += 1
		else:
			assert_eq(selection, "PENDING_SELECTION", item_id + ": not yet selected")
		var required: Variant = item["required_class"]
		if required != null:
			assert_true(required["classes"] is Array, item_id + ": class list resolved")
			for class_id: String in required["classes"]:
				assert_true(class_id in RpgClassRegistry.ROSTER, item_id + ": " + class_id)
	assert_eq(excluded, 42, "42 Scorching Wastes items excluded")
	assert_eq(deferred, 24, "24 Rift items deferred")


func test_legacy_items_keep_their_identity_and_the_live_data_is_unchanged() -> void:
	var content := GameSession.content
	var legacy: Dictionary = _registry("legacy_items.json")["items"]
	assert_eq(legacy.size(), content.items.size(), "every live item is in the legacy registry")
	var godforged := 0
	var charms := 0
	for item_id: String in legacy:
		var rec: Dictionary = legacy[item_id]
		assert_eq(rec["status"], "LEGACY", item_id + ": legacy")
		var live: Dictionary = content.item(item_id)
		assert_eq(rec["rarity"], live.get("rarity"), item_id + ": rarity recorded as live")
		if rec.get("adapted_rarity") != null:
			godforged += 1
			assert_eq(rec["adapted_rarity"], "legendary", item_id + ": godforged maps to legendary")
			assert_true(str(rec["adaptation"]).begins_with("ADAPTED"), item_id + ": marked ADAPTED")
			# Data only: the live item keeps its legacy rarity until its phase.
			assert_eq(live.get("rarity"), "godforged", item_id + ": live data unchanged")
		if rec.get("slot") == "charm":
			charms += 1
			assert_eq(live.get("slot"), "charm", item_id + ": still a charm in play")
	assert_eq(godforged, 25, "25 godforged legacy items")
	assert_eq(charms, 31, "31 legacy charms")


func test_item_selection_statuses_are_complete_and_exclusive() -> void:
	var doc := _registry("reference_items.json")
	var items: Dictionary = doc["items"]
	var totals := {}
	for item_id: String in items:
		var label := str(items[item_id]["selection"]).split(":")[0]
		assert_true(label in ["PENDING_SELECTION", "EXCLUDED", "DEFERRED"], item_id + ": a status")
		totals[label] = int(totals.get(label, 0)) + 1
	assert_eq(totals, {"PENDING_SELECTION": 2197, "EXCLUDED": 42, "DEFERRED": 24}, "status totals")
	assert_eq(2197 + 42 + 24, items.size(), "the statuses cover all 2,263 items")
	# The 66 not pending: the Scorching Wastes items (Studio overlay) and the Rift items.
	for item_id: String in items:
		var item: Dictionary = items[item_id]
		var label := str(item["selection"]).split(":")[0]
		if label == "EXCLUDED":
			assert_eq(item["registry_table"], "STUDIO_CONTENT.items", item_id + ": Studio overlay")
		if label == "DEFERRED":
			assert_eq(item["ref"]["file"], "src/sim/content/rift/items.ts", item_id + ": Rift")
	var selection := _registry("loot_selection.json")
	assert_eq(
		selection["items"]["selection_counts"],
		{"DEFERRED": 24.0, "EXCLUDED": 42.0, "PENDING_SELECTION": 2197.0},
		"loot selection agrees"
	)
