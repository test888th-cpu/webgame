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
	for skill_id in ["ground_pound", "dash_strike"]:
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
	# The owner's report: an effect as wide as the blow reaches, not twice it.
	var slam := game.content.moves.get_move(str(game.content.skills["ground_pound"]["move"]))
	var art: Array = game.content.fx["effects"]["slam"]["size"]
	var drawn := float(art[0]) * (cracks[0] as Node2D).scale.x
	var reach := GameFeedback.hit_width(slam)
	assert_near(drawn, reach, "the crack spans the slam's reach (%d px)" % drawn, 1.0)
	for sprite: AnimatedSprite2D in hero_view.find_children("*", "AnimatedSprite2D", false, false):
		assert_true(sprite.animation != "slam", "the crack does not ride along with the hero")
	_done(game)


func test_every_hazard_draws_lands_and_sounds() -> void:
	var game := _game()
	var id := 0
	for kind: String in ["crane", "steam", "sludge", "shock", "laser"]:
		id += 1
		var drop := HazardView.new()
		drop.setup(0.2, kind, Vector2(60, 14))
		game.view.effects.add_child(drop)
		game._feedback._drops[id] = drop
		await tree.process_frame
		game._feedback.on_event(
			ZoneEvent.make("hazard_hit", {"id": id, "at": Vector2(400, 300), "kind": kind})
		)
		for i in 3:
			await tree.process_frame
		assert_true(drop._landed, kind + ": landed")
	assert_true(game.content.audio["sounds"].has("hazard_warn"), "a warning of its own")
	_done(game)


## The owner's report: a boss's marks stayed painted on the street long after
## it fell. Each warning goes with its own hazard: it lands, is called off, or
## (if its hazard went without a word) clears itself once it is overdue.
func test_hazard_marks_never_outlive_their_hazard() -> void:
	var game := _game()
	var marks: Array[HazardView] = []
	for id in [1, 2, 3]:
		var warn := {"id": id, "at": Vector2(300 + id * 80, 300), "ticks": 30, "kind": "sludge"}
		warn["half"] = Vector2(40, 12)
		game._feedback.on_event(ZoneEvent.make("hazard_warn", warn))
		marks.append(game._feedback._drops[id])
	# Out of order: the third lands first, and only it lands.
	game._feedback.on_event(ZoneEvent.make("hazard_hit", {"id": 3, "at": Vector2(540, 300)}))
	assert_true(marks[2]._landed, "the hazard that landed is the one that shows it")
	assert_true(not marks[0]._landed and not marks[1]._landed, "the others still warn")
	# The boss falls: what is left is called off, quickly and without impact.
	for id in [1, 2]:
		game._feedback.on_event(ZoneEvent.make("hazard_cancel", {"id": id}))
	assert_true(not marks[0]._landed, "a called-off hazard does not land")
	await tree.create_timer(HazardView.LAND_HOLD + HazardView.LAND_FADE + 0.2).timeout
	for mark in marks:
		assert_true(not is_instance_valid(mark), "no mark left on the street")
	assert_true(game._feedback._drops.is_empty(), "none still tracked")
	# The safety net: a warning whose hazard vanished unannounced clears itself.
	var stray := HazardView.new()
	stray.setup(0.1, "quake", Vector2(40, 12))
	game.view.ground.add_child(stray)
	var by := 0.1 * 1.5 + HazardView.OVERDUE_SLACK + HazardView.DISMISS_FADE + 0.3
	await tree.create_timer(by).timeout
	assert_true(not is_instance_valid(stray), "an orphaned warning clears itself")
	_done(game)


func test_every_skill_effect_is_drawn_the_width_it_hits() -> void:
	var c := GameSession.content
	for skill_id: String in c.skills:
		var skill: Dictionary = c.skills[skill_id]
		if SkillRules.is_passive(skill):
			continue
		var move := c.moves.get_move(str(skill["move"]))
		var art: Array = c.fx["effects"][str(skill["fx"])]["size"]
		var size := GameFeedback.fit(c, str(skill["fx"]), GameFeedback.hit_width(move))
		var drawn := float(art[0]) * size
		var reach := GameFeedback.hit_width(move)
		var bounded := size in [GameFeedback.MIN_FIT, GameFeedback.MAX_FIT]
		assert_true(
			bounded or absf(drawn - reach) < 1.0,
			"%s: %d px drawn for %d px of reach" % [skill_id, drawn, reach]
		)
		assert_true(drawn <= reach * 1.5 or bounded, skill_id + ": never balloons past its reach")


func test_every_boss_skill_shows_where_it_hits() -> void:
	# The boss skills (BossSkillRules): each plays its sound and its theme's
	# glow, and a blow's effect lands on the middle of its hitbox.
	var game := _game()
	var c := game.content
	var landed := 0
	for kind: String in c.boss_skills["bosses"]:
		var boss := game.zone.spawn_enemy(kind, game.zone.hero.position + Vector2(200, 0))
		game.view.sync()
		for id in BossSkillRules.of(c, kind):
			var data := BossSkillRules.skill(c, id)
			boss.move = c.moves.get_move(str(data["moves"][0]))
			boss.facing = -1
			game._feedback.on_event(
				ZoneEvent.make("swing", {"id": boss.id, "move": boss.move.id, "skill": id})
			)
			if str(data["fx"]) != "":
				landed += 1
		game.zone.fighters.erase(boss)
		game.zone.brains.erase(boss.id)
	assert_true(landed > 50, "the blows' effects on their way (%d)" % landed)
	await tree.create_timer(0.8).timeout
	# End on a frame boundary, as the other scene tests do.
	await tree.process_frame
	_done(game)
