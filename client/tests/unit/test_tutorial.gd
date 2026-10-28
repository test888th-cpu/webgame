extends TestCase
## The first-time tutorial: steps finish by doing what they teach, progress
## is saved, players from before it never see it, and it can be skipped.

const TEST_SAVE := "user://test_tutorial_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _press(field: String) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, true)
	return input


func test_a_new_hero_starts_the_tutorial() -> void:
	var profile := PlayerProfile.new_game(_content())
	assert_eq(profile.tutorial, 0, "first step")
	assert_eq(TutorialRules.current(profile, _content())["signal"], "move", "starts with moving")


func test_steps_finish_by_doing_them_in_order() -> void:
	var profile := PlayerProfile.new_game(_content())
	assert_true(not TutorialRules.notify(profile, "hit", _content()), "out of order: ignored")
	assert_true(TutorialRules.notify(profile, "move", _content()), "moving finishes step 1")
	assert_eq(TutorialRules.current(profile, _content())["signal"], "hit", "then punching")
	var count := int(TutorialRules.current(profile, _content())["count"])
	for i in count - 1:
		assert_true(not TutorialRules.notify(profile, "hit", _content()), "not yet")
	assert_true(TutorialRules.notify(profile, "hit", _content()), "enough punches")


func test_skipping_finishes_it() -> void:
	var profile := PlayerProfile.new_game(_content())
	TutorialRules.skip(profile, _content())
	assert_true(TutorialRules.is_done(profile, _content()), "done")
	assert_true(not TutorialRules.notify(profile, "move", _content()), "nothing left to count")


func test_progress_is_saved_and_old_saves_skip_it() -> void:
	var profile := PlayerProfile.new_game(_content())
	profile.tutorial = 3
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	assert_eq(loaded.tutorial, 3, "kept across a save")
	var old := profile.to_dict()
	old["version"] = 3
	old.erase("tutorial")
	var migrated := PlayerProfile.from_dict(old, _content())
	assert_true(TutorialRules.is_done(migrated, _content()), "a version 3 player has played")
	var silly := profile.to_dict()
	silly["tutorial"] = -5
	assert_eq(PlayerProfile.from_dict(silly, _content()).tutorial, 0, "clamped")


func test_actions_in_the_zone_become_signals() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 2)
	var move := FighterInput.new()
	move.move = Vector2.RIGHT
	var signals := TutorialRules.signals_for(zone.tick(move), zone.hero, move, _content().moves)
	assert_true("move" in signals, "moving")
	for i in 30:
		zone.tick(FighterInput.new())
	var dodge := _press("dodge")
	signals = TutorialRules.signals_for(zone.tick(dodge), zone.hero, dodge, _content().moves)
	assert_true("dodge" in signals, "dodging")
	for i in 30:
		zone.tick(FighterInput.new())
	var heavy := _press("heavy")
	signals = TutorialRules.signals_for(zone.tick(heavy), zone.hero, heavy, _content().moves)
	assert_true("heavy" in signals, "a heavy blow")


func test_the_game_teaches_as_you_play() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var move := FighterInput.new()
	move.move = Vector2.RIGHT
	game.step(move)
	assert_eq(game.profile.tutorial, 1, "moving finished the first step")
	await tree.process_frame  # the HUD redraws each frame
	var hud_text := _texts(game)
	assert_true(hud_text.contains("TUTORIAL  2 /"), "the HUD shows the next step")
	game.open_pause()
	game.skip_tutorial()
	assert_true(TutorialRules.is_done(game.profile, game.content), "skipped from the menu")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_every_step_is_valid() -> void:
	assert_true(_content().is_valid(), ", ".join(_content().errors))
	assert_true(_content().tutorial.size() >= 5, "a real tutorial")


func _texts(root: Node) -> String:
	var parts: Array[String] = []
	for label: Label in root.find_children("*", "Label", true, false):
		parts.append(label.text)
	return " | ".join(parts)
