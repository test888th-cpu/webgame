extends TestCase
## Every class in the reference roster has temporary art for both body types, the art
## exists and plays the animations combat needs, and the mapping is visual only
## (docs/ASSET_PIPELINE_POLICY.md).

const VISUALS := "res://data/class_visuals.json"
const ROSTER := "res://data/rpg_reference.json"
const ANIMATIONS := ["idle", "walk", "light", "heavy", "stab", "swing", "hurt", "down", "dodge"]


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_every_class_has_male_and_female_art_that_plays() -> void:
	var classes: Dictionary = _json(VISUALS)["classes"]
	var roster: Dictionary = _json(ROSTER)["classes"]
	assert_eq(classes.keys().size(), 9, "nine classes mapped")
	var seen := {}
	for id: String in roster:
		assert_true(classes.has(id), "%s has visuals" % id)
		for body: String in ["male", "female"]:
			var entry: Dictionary = classes[id][body]
			assert_eq(entry["visual_id"], "character.%s.%s" % [id, body], "stable visual id")
			assert_true(not seen.has(entry["visual_id"]), "visual id unique")
			seen[entry["visual_id"]] = true
			var sprite := String(entry["sprite"])
			var path := "res://assets/characters/%s/%s.tres" % [sprite, sprite]
			assert_true(ResourceLoader.exists(path), "%s exists" % path)
			var frames := load(path) as SpriteFrames
			for anim: String in ANIMATIONS:
				assert_true(frames.has_animation(anim), "%s plays %s" % [sprite, anim])
				assert_true(frames.get_frame_count(anim) > 0, "%s %s has frames" % [sprite, anim])


func test_the_mapping_holds_no_gameplay_fields() -> void:
	# Art can be swapped by editing this file alone, so it must not carry rules.
	var allowed := ["visual_id", "sprite", "status"]
	var classes: Dictionary = _json(VISUALS)["classes"]
	for id: String in classes:
		for body: String in classes[id]:
			for key: String in classes[id][body]:
				assert_true(key in allowed, "%s.%s: %s is visual only" % [id, body, key])
