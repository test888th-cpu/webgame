extends TestCase
## Imported character art: every manifest entry loads in Godot with the
## animations and frame counts the manifest promises, and views use it.

const FIGHTER_VIEW := preload("res://scenes/fighter/FighterView.tscn")


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
			var size := Vector2(entry["frame_size"][0], entry["frame_size"][1])
			assert_eq(texture.region.size, size, "%s %s frame size" % [id, anim])


func test_pixel_art_is_not_smoothed() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"),
		0,
		"project default filter is nearest"
	)


func test_fighter_view_plays_attacks_in_step_with_ticks() -> void:
	var view: FighterView = FIGHTER_VIEW.instantiate()
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


func test_weapon_swings_play_the_overhead_swing_where_the_art_has_it() -> void:
	var swing := GameSession.content.moves.get_move("bat_swing")
	for art: Array in [["hero_mika", &"swing"], ["sludge_foreman", &"light"]]:
		var view: FighterView = FIGHTER_VIEW.instantiate()
		tree.root.add_child(view)
		var hero := Fighter.new(1, 1, Vector2(100, 300))
		view.fighter = hero
		view.set_art(art[0], _art())
		hero.enter(Fighter.State.ATTACK)
		hero.move = swing
		hero.state_tick = 0
		view.sync()
		var sprite: AnimatedSprite2D = view.get_node("Sprite")
		assert_eq(sprite.animation, art[1], "%s plays %s" % art)
		view.free()


func test_blows_land_with_the_fist_out() -> void:
	# The contact frames are the ones where the hand reaches furthest forward,
	# for every character drawn from LPC (heroes and monsters alike).
	for id: String in _art():
		var entry: Dictionary = _art()[id]
		if entry.get("source") != "lpc":
			continue
		for anim: String in ["light", "heavy", "swing", "stab"]:
			if not entry["animations"].has(anim):
				continue
			var contact: Array = entry["animations"][anim].get("contact", [])
			assert_eq(contact.size(), 2, "%s %s names its contact frames" % [id, anim])
			if contact.size() != 2:
				continue
			var hands: Array = entry["hands"][anim]
			var reach := 0.0
			for frame in range(int(contact[0])):
				reach = maxf(reach, float(hands[frame][0]))
			for frame in range(int(contact[0]), int(contact[1]) + 1):
				assert_true(
					float(hands[frame][0]) > reach, "%s %s: frame %d is out" % [id, anim, frame]
				)


func test_the_contact_frame_shows_when_the_blow_lands() -> void:
	var haymaker := GameSession.content.moves.get_move("haymaker")
	var contact := [4, 6]
	var at := func(tick: int) -> int: return FighterView.attack_frame(haymaker, tick, 8, contact)
	assert_eq(at.call(0), 0, "wind-up starts at the first frame")
	assert_true(at.call(haymaker.startup - 1) < 4, "still winding up a tick before the hit")
	assert_eq(at.call(haymaker.startup), 4, "the fist is out on the tick the hit lands")
	assert_true(at.call(haymaker.startup + haymaker.active - 1) <= 6, "and stays out while live")
	assert_eq(at.call(haymaker.total_ticks() - 1), 7, "recovered by the last tick")
	var view: FighterView = FIGHTER_VIEW.instantiate()
	tree.root.add_child(view)
	var hero := Fighter.new(1, 1, Vector2(100, 300))
	view.fighter = hero
	view.set_art("hero_mika", _art())
	hero.enter(Fighter.State.ATTACK)
	hero.move = haymaker
	hero.state_tick = haymaker.startup
	view.sync()
	var sprite: AnimatedSprite2D = view.get_node("Sprite")
	assert_eq([sprite.animation, sprite.frame], [&"heavy", 4], "Mika's haymaker lands fist out")
	view.free()


func test_hero_art_follows_armour() -> void:
	SaveStore.root = "user://test_save"
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	assert_eq(game.view.hero_art(), "hero_mika", "default look")
	game.profile.level = 3  # the jacket needs level 3
	game.profile.add_item("work_jacket")
	game._equip("work_jacket")
	assert_eq(game.view.hero_art(), "hero_mika_armoured", "jacket changes the look")
	game.step(FighterInput.new())
	assert_eq(game.view.view_of(ZoneSim.HERO_ID).art_id, "hero_mika_armoured", "view updated")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_credits_build() -> void:
	var text := CreditsText.build(GameSession.content)
	assert_true(text.contains("OGA-BY"), "credits name licences")
	assert_true(text.contains("Stephen Challener"), "credits name LPC authors")
	assert_true(text.contains("jakeeaton"), "credits name the recorded punch's author")
	assert_true(text.contains("License: Attribution 4.0"), "and its licence")
	assert_true(
		text.contains(
			(
				"multi punch.wav by Shikamarunara74 -- https://freesound.org/s/126317/"
				+ " -- License: Attribution 3.0"
			)
		),
		"the multi-punch credited in the wording its author asks for"
	)
	assert_eq(text.count("Shikamarunara74"), 1, "credited once for all its cuts")
	assert_true(
		text.contains(
			(
				"Punches.mp3 by mrrap4food -- https://freesound.org/s/619053/"
				+ " -- License: Creative Commons 0"
			)
		),
		"the CC0 punches credited as asked"
	)
	for punch: String in GameFeedback.PUNCHES:
		assert_true(GameSession.content.audio["sounds"].has(punch), "%s is a listed sound" % punch)


func test_every_area_is_built_from_the_street_kit() -> void:
	var content := GameSession.content
	for area_id: String in content.areas:
		assert_true(
			not content.environment.get("areas", {}).get(area_id, {}).is_empty(),
			"%s has a generated sky" % area_id
		)
		var kit: Dictionary = content.kit.get("areas", {}).get(area_id, {})
		assert_true(not kit.is_empty(), "%s is laid out from the kit" % area_id)
		var profile := PlayerProfile.new_game(content)
		var view := ZoneView.new()
		tree.root.add_child(view)
		view.build(ZoneSim.new(content, profile, area_id, "", 1), content)
		for layer in ["KitFar", "KitBack", "KitFront", "KitGround", "KitSidewalk", "KitFg"]:
			var node := view.get_node_or_null(layer) as Parallax2D
			assert_true(node != null, "%s has its %s layer" % [area_id, layer])
			if node != null:
				assert_eq(
					node.texture_filter,
					CanvasItem.TEXTURE_FILTER_LINEAR,
					"%s %s is drawn smooth" % [area_id, layer]
				)
		var front := view.get_node("KitFront")
		assert_true(front.get_child_count() >= 3, "%s has a row of buildings" % area_id)
		var reach := 0.0
		for sprite: Sprite2D in front.get_children():
			assert_true(sprite.texture != null, "%s building texture loads" % area_id)
			reach = maxf(reach, sprite.position.x + sprite.texture.get_width() * sprite.scale.x)
		assert_true(reach >= float(content.area(area_id)["width"]), "%s street is lined" % area_id)
		assert_true(
			view.get_node("KitFg").z_index > 0, "%s foliage is drawn over the fighters" % area_id
		)
		var furniture: Array[Node] = []
		for node: Node in view.find_children("*", "Node2D", true, false):
			if node.is_in_group(Scenery.FURNITURE_GROUP):
				furniture.append(node)
		assert_eq(
			furniture.size(),
			content.area(area_id).get("obstacles", []).size(),
			"%s street furniture is drawn" % area_id
		)
		for node: Node in furniture:
			assert_eq(
				node.get_parent().name, "Entities", "%s furniture sorts with fighters" % area_id
			)
		if kit.has("track"):
			var strip := view.get_node("KitTrack").get_child(0) as Sprite2D
			assert_true(strip.region_enabled, "%s track is one repeating strip" % area_id)
			assert_near(
				strip.region_rect.size.x * strip.scale.x,
				float(kit["track"]["to"]) - float(kit["track"]["from"]),
				"%s track runs unbroken" % area_id
			)
		view.free()


func test_the_camera_never_shows_past_the_end_of_the_street() -> void:
	# Every area, every fight's locked arena, on 16:9 and wider windows: the
	# camera's range is at least the view's width and stays on the street.
	var content := GameSession.content
	for area_id: String in content.areas:
		var area := content.area(area_id)
		var width := float(area["width"])
		var spans: Array[Vector2] = [Vector2(0, width)]
		for encounter: Dictionary in area.get("encounters", []):
			var left := maxf(ZoneSim.EDGE_MARGIN, float(encounter["arena"][0]))
			var right := minf(width - ZoneSim.EDGE_MARGIN, float(encounter["arena"][1]))
			spans.append(Vector2(left - ZoneSim.EDGE_MARGIN, right + ZoneSim.EDGE_MARGIN))
		for view: float in [640.0, 720.0, 854.0]:
			for span in spans:
				var limits := ZoneView.camera_limits(span, width, view)
				var what := "%s %s in a %d-wide view" % [area_id, span, view]
				assert_true(limits.y - limits.x >= view - 1.0, what + ": room for the view")
				if width >= view:
					assert_true(limits.x >= 0.0 and limits.y <= width, what + ": on the street")
				assert_true(
					limits.x <= span.x and limits.y >= span.y, what + ": the whole arena shows"
				)


func test_the_ground_runs_past_both_ends() -> void:
	var content := GameSession.content
	for area_id: String in content.kit.get("areas", {}):
		var view := ZoneView.new()
		tree.root.add_child(view)
		view.build(ZoneSim.new(content, PlayerProfile.new_game(content), area_id, "", 1), content)
		var width := float(content.area(area_id)["width"])
		for strip: Sprite2D in view.get_node("KitGround").get_children():
			var left := strip.position.x
			var right := left + strip.region_rect.size.x * strip.scale.x
			assert_true(left <= -320.0, "%s ground starts before the street" % area_id)
			assert_true(right >= width + 320.0, "%s ground runs past its end" % area_id)
		view.free()


func test_kit_pieces_stand_on_the_street() -> void:
	var content := GameSession.content
	var pieces: Dictionary = content.kit["pieces"]
	for area_id: String in content.kit["areas"]:
		for placed: Dictionary in content.kit["areas"][area_id]["placed"]:
			assert_true(pieces.has(placed["piece"]), "%s piece %s" % [area_id, placed["piece"]])
			if placed["layer"] == "sidewalk":
				assert_true(
					float(placed["y"]) <= ZoneSim.LANE_TOP,
					"%s %s stands behind the fighting lane" % [area_id, placed["piece"]]
				)
	# Painted at least twice the game size, drawn scaled down to stay sharp.
	for piece_id: String in pieces:
		assert_true(int(pieces[piece_id]["hd"]) >= 2, "%s is HD" % piece_id)
