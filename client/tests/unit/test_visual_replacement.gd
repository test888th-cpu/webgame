extends TestCase
## Replacing temporary art changes only the visual mapping, never gameplay or saves
## (docs/ASSET_PIPELINE_POLICY.md §4-§5): an item keeps its id, stats and save
## record when its look is redrawn, and a class keeps its stats when its sprite is
## swapped.

const HAT_ITEM := "crimson_warlord_helm"


## A save as loaded by the game, in a stable text form (keys sorted, no timestamp).
## Loading normalises a save (e.g. adds the start area to "visited"), so saves are
## compared load-for-load, before and after the art changes.
func _loaded(save: Dictionary, content: ContentDB) -> String:
	var copy := PlayerProfile.from_dict(JSON.parse_string(JSON.stringify(save)), content).to_dict()
	copy.erase("saved_at")
	return JSON.stringify(copy, "", true)


func test_redrawing_a_hat_keeps_the_item_its_stats_and_the_save() -> void:
	var content := ContentDB.load_all()
	var item: Dictionary = content.item(HAT_ITEM).duplicate(true)
	var look := str(item["appearance"])
	var asset := str(content.catalog.appearances[look]["asset"])
	var profile := PlayerProfile.new_game(content)
	profile.level = PlayerProfile.new_game(content).max_level(content)
	profile.add_item(HAT_ITEM)
	assert_true(profile.equip(HAT_ITEM, content), "the hat item can be worn")
	var stats_before := profile.stats(content)
	var save := profile.to_dict()
	var loaded_before := _loaded(save, content)
	assert_true(HAT_ITEM in loaded_before, "the save records the hat item by its id")

	# The replacement: the hat's file is swapped for the code-drawn headgear
	# under the same asset id (the release fallback in ASSET_PROVENANCE_GAPS.md).
	var specs: Dictionary = content.catalog.placeholders["appearance_assets"]
	specs[asset] = {"slot": "head", "style": "cap", "grade": "epic", "status": "placeholder"}
	GameSession.placeholder_art.erase("look:" + asset)
	var drawn := PlaceholderArt.appearance(content, asset)
	assert_true(drawn.get("texture") is Texture2D, "the redrawn look still renders")
	GameSession.placeholder_art.erase("look:" + asset)

	assert_eq(content.item(HAT_ITEM), item, "item definition unchanged")
	assert_eq(profile.stats(content), stats_before, "stats unchanged")
	assert_eq(_loaded(save, content), loaded_before, "the same save loads the same")
	var reloaded := PlayerProfile.from_dict(JSON.parse_string(JSON.stringify(save)), content)
	assert_eq(reloaded.stats(content), stats_before, "reloaded stats unchanged")


func test_swapping_a_class_sprite_changes_no_class_rule() -> void:
	var roster: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/rpg_reference.json"))["classes"]
	)
	var visuals: Dictionary = (
		JSON.parse_string(FileAccess.get_file_as_string("res://data/class_visuals.json"))["classes"]
	)
	for id: String in roster:
		var def: Dictionary = roster[id]
		for key: String in def:
			assert_true(
				not ("sprite" in key or "visual" in key or "image" in key),
				"%s: class data holds no art field (%s)" % [id, key]
			)
		var before := RpgStats.sheet(def, 20)
		visuals[id]["male"]["sprite"] = "class_mage_m"  # any other sprite
		var path := "res://assets/characters/class_mage_m/class_mage_m.tres"
		assert_true(ResourceLoader.exists(path), "the swapped sprite loads")
		assert_eq(RpgStats.sheet(def, 20), before, "%s: sheet unchanged" % id)
