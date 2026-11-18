extends TestCase
## The pixelfx effect library (art/pixelfx/effects.json, imported by
## tools/assets/import_pixelfx.py at a pinned commit): every sheet fits a browser
## texture, has a transparent background and sane timing; effects load only when
## they play; many play at once without errors; and the library is visual only, so
## removing an effect changes no gameplay data.

const MAX_TEXTURE := 4096


func _recipe() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join("../art/pixelfx/effects.json")
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _imported(content: ContentDB) -> Dictionary:
	var out := {}
	for id: String in content.fx["effects"]:
		if content.fx["effects"][id].has("sheet"):
			out[id] = content.fx["effects"][id]
	return out


func test_every_sheet_fits_a_browser_texture_and_is_transparent() -> void:
	var content := GameSession.content
	var imported := _imported(content)
	assert_eq(imported.size(), _recipe()["effects"].size(), "every recipe effect is imported")
	for id: String in imported:
		var effect: Dictionary = imported[id]
		var texture: Texture2D = load(str(effect["sheet"]))
		assert_true(texture != null, id + ": sheet loads")
		var image := texture.get_image()
		assert_true(image.get_width() <= MAX_TEXTURE, id + ": width fits WebGL")
		assert_true(image.get_height() <= MAX_TEXTURE, id + ": height fits WebGL")
		var size := Vector2i(effect["size"][0], effect["size"][1])
		var columns := int(effect["columns"])
		var rows := ceili(int(effect["frames"]) / float(columns))
		assert_true(columns * size.x <= image.get_width(), id + ": columns fit the sheet")
		assert_true(rows * size.y <= image.get_height(), id + ": rows fit the sheet")
		# A transparent background, not a solid one: in every frame under half the
		# pixels are fully opaque (glows may be faint everywhere; a painted
		# background would be opaque nearly everywhere). The worst today is 17.6%.
		assert_true(image.detect_alpha() != Image.ALPHA_NONE, id + ": has alpha")
		for frame in int(effect["frames"]):
			var cell := Vector2i(frame % columns * size.x, frame / columns * size.y)
			var opaque := 0
			var sampled := 0
			for y in range(0, size.y, 2):
				for x in range(0, size.x, 2):
					sampled += 1
					if image.get_pixel(cell.x + x, cell.y + y).a >= 1.0:
						opaque += 1
			assert_true(
				opaque * 2 < sampled, "%s frame %d: background is transparent" % [id, frame]
			)
		assert_true(float(effect["fps"]) > 0.0, id + ": has a frame rate")
		if not effect.get("loop", false):
			var seconds := int(effect["frames"]) / float(effect["fps"])
			assert_true(seconds <= 4.0, id + ": plays in at most 4 s (%.2f)" % seconds)


func test_many_effects_play_at_once() -> void:
	var content := GameSession.content
	var holder := Node2D.new()
	tree.root.add_child(holder)
	var ids := _imported(content).keys()
	var played := 0
	# Eight players each firing every effect in turn: dozens on screen together.
	for player in 8:
		for i in ids.size():
			var sprite := Fx.spawn(
				holder,
				content,
				ids[i],
				Vector2(40 + player * 120, 200 + i % 5 * 10),
				player % 2 == 1
			)
			if sprite != null and sprite.is_playing():
				played += 1
	assert_eq(played, ids.size() * 8, "every effect plays, for every player")
	for _frame in 10:
		await tree.process_frame
	holder.free()


func test_the_library_is_visual_only() -> void:
	# No gameplay file names a proposed effect, so removing or replacing one
	# changes no skill, move, item or enemy.
	var proposed := []
	var recipe: Dictionary = _recipe()["effects"]
	for id: String in recipe:
		if str(recipe[id].get("use", "")).begins_with("PROPOSED"):
			proposed.append(id)
	assert_eq(proposed.size(), 37, "the 37 proposed effects")
	for file: String in ["skills.json", "moves.json", "items.json", "enemies.json", "jobs.json"]:
		var text := FileAccess.get_file_as_string("res://data/" + file)
		for id: String in proposed:
			assert_true(not ('"%s"' % id in text), "%s does not name %s" % [file, id])
	# Removing one from the content leaves everything else valid and playable.
	var content := ContentDB.load_all()
	content.fx["effects"].erase(proposed[0])
	content.validate()
	assert_eq(content.errors.size(), 0, "content still validates without " + str(proposed[0]))
