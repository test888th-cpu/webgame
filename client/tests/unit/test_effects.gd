extends TestCase
## What the player sees around the fights: enemies arrive with a puff of
## dust (an elite with a gold flare), a boss's new phase flares, and a fallen
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
	assert_true(enemy_view.modulate.a < 1.0, "fading (%s)" % enemy_view.modulate.a)
	_done(game)


func test_a_bosss_new_phase_flares() -> void:
	var game := _game()
	game.profile.level = 12
	game.enter_area("gang_hq", "west")
	var baron := game.zone.spawn_enemy("furnace_baron", Vector2(600, 300))
	game.view.sync()
	var before := game.view.effects.get_child_count()
	game._feedback.on_event(ZoneEvent.make("boss_phase", {"id": baron.id, "phase": 2}))
	assert_true(game.view.effects.get_child_count() >= before + 2, "a shockwave and a flash")
	_done(game)
