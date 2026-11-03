extends TestCase
## What the player sees around the fights: enemies fade in (an elite with a
## flare, no smoke), a boss's new phase flares, and a fallen
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
	# Game seeds each area from the global generator: fixed here, so an elite
	# comes in the same few seconds on every run.
	seed(5)
	game.enter_area("farm_facility_annex", "west")
	var arrived := false
	var elite := false
	var faded_in := false
	for i in 3000:
		for event in game.step(FighterInput.new()):
			if event.type != "spawn":
				continue
			arrived = true
			elite = elite or event.data.get("elite", false)
			var fresh := game.view.view_of(int(event.data["id"]))
			faded_in = faded_in or (fresh != null and fresh.modulate.a < 1.0)
		if elite:
			break
	game.content.areas["farm_facility_annex"]["spawning"]["elite_chance"] = 0.05
	assert_true(arrived, "enemies came")
	assert_true(elite, "an elite came")
	assert_true(faded_in, "an arrival fades in, no pop-in")
	var shown: Array[String] = []
	for sprite: AnimatedSprite2D in game.view.effects.find_children(
		"*", "AnimatedSprite2D", true, false
	):
		shown.append(str(sprite.animation))
	assert_true("elite_flare" in shown, "an elite arrives in gold light")
	for enemy in game.zone.enemies():
		if enemy.elite:
			var plate := game.view.view_of(enemy.id)
			assert_true((plate.get_node("Name") as Label).text.begins_with("Elite "), "named")
			assert_true(plate.get_node_or_null("Rank") != null, "with the elite star")
	assert_true("poof" not in shown, "and nobody in a puff of smoke (%s)" % [shown])
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
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/manifest.json")
	)
	var expected: int = manifest["fx_pixelfx"]["effects"].size()
	assert_eq(pixelfx, expected, "every imported pixelfx effect (%d)" % expected)
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


func test_every_boss_skill_has_its_effect() -> void:
	var content := GameSession.content
	assert_eq(BossFxRules.problems(content), PackedStringArray(), "boss_fx.json is complete")
	for id: String in content.enemies:
		if content.enemy(id).get("boss", false):
			assert_true(BossFxRules.windup(content, id) != "", id + ": a wind-up glow")
	var broken := ContentDB.load_all()
	broken.boss_fx["bosses"].erase("unit_k7")
	broken.boss_fx["hazards"].erase("steam")
	var said := "\n".join(BossFxRules.problems(broken))
	assert_true("boss_fx.bosses.unit_k7" in said, "a boss without a theme")
	assert_true("no effect for steam" in said, "a hazard without its effect")


func test_a_bosss_heavy_blow_shield_and_fall_show() -> void:
	var game := _game()
	game.profile.level = 30
	game.enter_area("control_room", "west")
	var boss := game.zone.spawn_enemy("commander_arthit", Vector2(500, 300))
	game.view.sync()
	var boss_view := game.view.view_of(boss.id)
	var heavy := str(game.content.enemy("commander_arthit")["moveset"]["heavy"])
	game._feedback.on_event(ZoneEvent.make("swing", {"id": boss.id, "move": heavy, "skill": ""}))
	var glows := boss_view.find_children("*", "AnimatedSprite2D", false, false)
	assert_true(not glows.is_empty(), "its heavy blow is telegraphed on it")
	game._feedback.on_event(ZoneEvent.make("boss_shield", {"id": boss.id, "up": true}))
	var dome := boss_view.get_node_or_null("ShieldDome") as AnimatedSprite2D
	assert_true(dome != null and dome.sprite_frames.get_animation_loop(dome.animation), "a dome")
	var before := game.view.effects.get_child_count()
	game._feedback.on_event(ZoneEvent.make("boss_shield", {"id": boss.id, "up": false}))
	assert_true(game.view.effects.get_child_count() > before, "it breaks with a burst")
	for kind in ["crane", "steam", "shock", "laser", "sludge"]:
		before = game.view.effects.get_child_count()
		var hit := {"at": Vector2(400, 300), "kind": kind}
		game._feedback.on_event(ZoneEvent.make("hazard_hit", hit))
		assert_true(game.view.effects.get_child_count() > before, kind + ": lands with its effect")
	before = game.view.effects.get_child_count()
	var fell := {"id": boss.id, "kind": "commander_arthit", "xp": 0, "boss": true}
	game._feedback.on_event(ZoneEvent.make("defeat", fell))
	assert_true(game.view.effects.get_child_count() > before, "a fallen boss goes up in a blast")
	_done(game)


func test_a_slam_stays_where_it_landed_and_a_charge_trail_follows() -> void:
	var game := _game()
	var hero := game.zone.hero
	var hero_view := game.view.view_of(ZoneSim.HERO_ID)
	for skill_id in ["furnace_slam", "shoulder_rush"]:
		hero.move = game.content.moves.get_move(str(game.content.skills[skill_id]["move"]))
		game._feedback.on_event(
			ZoneEvent.make("swing", {"id": ZoneSim.HERO_ID, "move": "", "skill": skill_id})
		)
	var landed_at := hero_view.position
	var trail := hero_view.find_children("*", "AnimatedSprite2D", false, false)
	assert_true(trail.any(func(s: Node) -> bool: return s.animation == "rush"), "a trail follows")
	await tree.create_timer(hero.move.startup * CombatRules.TICK_SECONDS + 0.4).timeout
	var cracks := game.view.ground.find_children("*", "AnimatedSprite2D", false, false)
	assert_eq(cracks.size(), 1, "the slam's crack is on the street")
	assert_eq((cracks[0] as Node2D).position, landed_at, "where the hero stood when it landed")
	for sprite: AnimatedSprite2D in hero_view.find_children("*", "AnimatedSprite2D", false, false):
		assert_true(sprite.animation != "slam", "the crack does not ride along with the hero")
	_done(game)


func test_every_hazard_draws_lands_and_sounds() -> void:
	var game := _game()
	for kind: String in ["crane", "steam", "sludge", "shock", "laser"]:
		var drop := HazardView.new()
		drop.setup(0.2, kind, Vector2(60, 14))
		game.view.effects.add_child(drop)
		game._feedback._drops.append(drop)
		await tree.process_frame
		game._feedback.on_event(
			ZoneEvent.make("hazard_hit", {"at": Vector2(400, 300), "kind": kind})
		)
		for i in 3:
			await tree.process_frame
		assert_true(drop._landed, kind + ": landed")
	assert_true(game.content.audio["sounds"].has("hazard_warn"), "a warning of its own")
	_done(game)
