extends TestCase
## What the player sees around the fights: enemies arrive with a puff of
## smoke (an elite with a flare), a boss's new phase flares, and a fallen
## enemy fades out instead of vanishing (GameFeedback, ZoneView).

const TEST_SAVE := "user://test_effects_save"


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	# Lay out at the 16:9 base size, as the UI tests do.
	tree.root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_arrivals_phases_and_fallen_enemies_have_effects() -> void:
	var game := _game()
	game.profile.level = 40
	game.content.areas["farm_facility_annex"]["spawning"]["elite_chance"] = 0.25
	game.enter_area("farm_facility_annex", "west")
	var arrived := false
	var elite := false
	for i in 400:
		for event in game.step(FighterInput.new()):
			arrived = arrived or event.type == "spawn"
			elite = elite or (event.type == "spawn" and event.data.get("elite", false))
		if elite:
			break
	game.content.areas["farm_facility_annex"]["spawning"]["elite_chance"] = 0.05
	assert_true(arrived, "enemies came")
	var puffs := game.view.effects.find_children("*", "AnimatedSprite2D", false, false)
	assert_true(puffs.size() > 0, "an arrival raises dust (%d)" % puffs.size())
	var enemy: Fighter = game.zone.enemies()[0]
	var enemy_view := game.view.view_of(enemy.id)
	game.zone.fighters.erase(enemy)
	game.view.sync()
	assert_true(game.view.view_of(enemy.id) == null, "the fallen enemy's view is let go")
	assert_true(is_instance_valid(enemy_view) and enemy_view.is_inside_tree(), "and fades out")
	for i in 3:
		await tree.process_frame
	# A slow frame (the effects loading) may finish the 0.3 s fade already.
	var gone := not is_instance_valid(enemy_view)
	assert_true(gone or enemy_view.modulate.a < 1.0, "fading out, or faded")
	_done(game)


func test_a_bosss_new_phase_flares() -> void:
	var game := _game()
	game.profile.level = 12
	game.enter_area("gang_hq", "west")
	var baron := game.zone.spawn_enemy("furnace_baron", Vector2(600, 300))
	game.view.sync()
	var before := game.view.effects.get_child_count()
	game._feedback.on_event(ZoneEvent.make("boss_phase", {"id": baron.id, "phase": 2}))
	assert_true(game.view.effects.get_child_count() >= before + 1, "a burst")
	_done(game)


func test_the_pixelfx_effects_load_and_play() -> void:
	var content := GameSession.content
	var imported: Dictionary = content.fx_credits
	assert_eq(imported.get("license"), "MIT", "MIT, as pixelfx is")
	var library := Fx._library(content)
	var frames: SpriteFrames = library["frames"]
	var effects: Dictionary = content.fx["effects"]
	var pixelfx := 0
	for id: String in effects:
		assert_true(frames.has_animation(id), id + ": an animation")
		assert_eq(frames.get_frame_count(id), int(effects[id]["frames"]), id + ": every frame")
		if effects[id].has("sheet"):
			pixelfx += 1
			var first := frames.get_frame_texture(id, 0) as AtlasTexture
			var size := Vector2(effects[id]["size"][0], effects[id]["size"][1])
			assert_eq(first.region.size, size, id + ": its frame size")
	assert_eq(pixelfx, 14, "the fourteen pixelfx effects")
	var holder := Node2D.new()
	tree.root.add_child(holder)
	var played := Fx.spawn(holder, content, "crit", Vector2(100, 100))
	assert_true(played != null and played.is_playing(), "a pixelfx effect plays")
	holder.free()


func test_the_credits_carry_the_pixelfx_notice() -> void:
	var text := CreditsText.build(GameSession.content)
	assert_true("pixelfx" in text, "pixelfx is credited")
	assert_true("Copyright (c) 2026 Patch" in text, "with its copyright")
	assert_true("Copyright (c) 2026 Hugo Duprez" in text, "both of them")
	assert_true("Permission is hereby granted" in text, "and the MIT permission notice")
	assert_true("a84159688af3ca37a4be05a0d422b94451b2e24e" in text, "and the source it came from")
