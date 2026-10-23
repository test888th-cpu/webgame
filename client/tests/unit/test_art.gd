extends TestCase
## Imported character art: every manifest entry loads in Godot with the
## animations and frame counts the manifest promises, and views use it.


func _art() -> Dictionary:
	return GameSession.content.art


func test_every_imported_asset_loads_as_spriteframes() -> void:
	assert_true(_art().size() >= 6, "the art pack is imported")
	for id: String in _art():
		var entry: Dictionary = _art()[id]
		if entry["status"] != "imported":
			continue
		var path := str(entry["sheet"]).get_base_dir().path_join(id + ".tres")
		var frames: SpriteFrames = load(path)
		assert_true(frames != null, "%s loads" % id)
		if frames == null:
			continue
		for anim: String in entry["animations"]:
			assert_true(frames.has_animation(anim), "%s has %s" % [id, anim])
			assert_eq(
				frames.get_frame_count(anim),
				int(entry["animations"][anim]["frames"]),
				"%s %s frame count" % [id, anim]
			)
			var texture: AtlasTexture = frames.get_frame_texture(anim, 0)
			assert_eq(texture.region.size, Vector2(64, 64), "%s %s frame size" % [id, anim])


func test_pixel_art_is_not_smoothed() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"),
		0,
		"project default filter is nearest"
	)


func test_fighter_view_plays_attacks_in_step_with_ticks() -> void:
	var view: FighterView = load("res://scenes/fighter/FighterView.tscn").instantiate()
	tree.root.add_child(view)
	var hero := Fighter.new(1, 1, Vector2(100, 300))
	view.fighter = hero
	view.set_art("hero_mika", _art())
	var sprite: AnimatedSprite2D = view.get_node("Sprite")
	view.sync()
	assert_eq(sprite.animation, &"idle", "idle at rest")
	var library := GameSession.content.moves
	var jab := library.get_move("jab")
	hero.enter(Fighter.State.ATTACK)
	hero.move = jab
	hero.state_tick = 0
	view.sync()
	assert_eq(sprite.animation, &"light", "a jab plays the light animation")
	assert_eq(sprite.frame, 0, "first frame at the first tick")
	hero.state_tick = jab.total_ticks() - 1
	view.sync()
	assert_eq(
		sprite.frame,
		sprite.sprite_frames.get_frame_count("light") - 1,
		"last frame at the last tick"
	)
	hero.facing = -1
	view.sync()
	assert_true(sprite.flip_h, "faces left by flipping")
	view.free()


func test_hero_art_follows_armour() -> void:
	SaveStore.path = "user://test_save.json"
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	assert_eq(game.view.hero_art(), "hero_mika", "default look")
	game.profile.add_item("work_jacket")
	game._equip("work_jacket")
	assert_eq(game.view.hero_art(), "hero_mika_armoured", "jacket changes the look")
	game.step(FighterInput.new())
	assert_eq(game.view.view_of(ZoneSim.HERO_ID).art_id, "hero_mika_armoured", "view updated")
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func test_gallery_and_credits_build() -> void:
	var gallery: Node = load("res://scenes/tools/Gallery.tscn").instantiate()
	tree.root.add_child(gallery)
	assert_true(
		gallery.find_children("*", "AnimatedSprite2D", true, false).size() >= 6,
		"gallery shows the characters"
	)
	gallery.free()
	var text := CreditsText.build(GameSession.content)
	assert_true(text.contains("OGA-BY"), "credits name licences")
	assert_true(text.contains("Stephen Challener"), "credits name LPC authors")
