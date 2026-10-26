extends TestCase
## The story layer: quest givers speak their lines, the goal is always spelled
## out, evidence is handed over on completion and can never be thrown away,
## and the last quest of a chapter closes it.

const TEST_SAVE := "user://test_story_save.json"


func _game() -> Node2D:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _texts(root: Node) -> String:
	var parts: Array[String] = []
	for label: Label in root.find_children("*", "Label", true, false):
		parts.append(label.text)
	return " | ".join(parts)


func _talk_to_odo(game: Node2D) -> void:
	game.zone.hero.position = Vector2(620, 262)
	assert_true(game.try_interact(), "talking to the chief")


func test_the_offer_is_spoken_and_the_goal_spelled_out() -> void:
	var game := _game()
	_talk_to_odo(game)
	var quest: Dictionary = game.content.quests["clear_saltmarket"]
	var text := _texts(game.menu)
	assert_true(text.contains(str(quest["dialogue"]["offer"])), "speaks the offer")
	assert_true(text.contains("Goal: " + str(quest["description"])), "spells out the goal")
	assert_true(text.contains("PROLOGUE"), "names the chapter")
	assert_true(not text.contains("Torn Shipping Label"), "evidence is not dangled as a reward")
	_done(game)


func test_handing_in_gives_evidence_and_the_closing_line() -> void:
	var game := _game()
	game.profile.quests["clear_saltmarket"] = {"state": "complete", "progress": 8}
	_talk_to_odo(game)
	game._turn_in(game.view.npc_near(game.zone.hero), "clear_saltmarket")
	assert_eq(game.profile.count("torn_label"), 1, "evidence in the bag")
	var done := str(game.content.quests["clear_saltmarket"]["dialogue"]["done"])
	assert_true(_texts(game.menu).contains(done), "the chief says what it means")
	_done(game)


func test_evidence_cannot_be_discarded() -> void:
	var content := ContentDB.load_all()
	var profile := PlayerProfile.new_game(content)
	profile.add_item("torn_label")
	profile.add_item("steamed_bun")
	assert_true(not profile.discard("torn_label", content), "evidence stays")
	assert_eq(profile.count("torn_label"), 1, "still there")
	assert_true(profile.discard("steamed_bun", content), "food can go")


func test_every_main_quest_belongs_to_a_chapter_and_speaks() -> void:
	var content := ContentDB.load_all()
	for quest_id: String in content.quests:
		var quest: Dictionary = content.quests[quest_id]
		assert_true(str(quest.get("chapter", "")) != "", "%s has a chapter" % quest_id)
		for line: String in ContentDB.DIALOGUE_LINES:
			assert_true(
				str(quest.get("dialogue", {}).get(line, "")) != "",
				"%s says something on %s" % [quest_id, line]
			)


func test_story_secrets_are_kept_until_their_chapter() -> void:
	# Story bible §7: The Core is not named before chapter 3.
	var content := ContentDB.load_all()
	for quest_id: String in content.quests:
		assert_true(
			not JSON.stringify(content.quests[quest_id]).contains("The Core"),
			"%s does not name The Core" % quest_id
		)
	for item_id: String in content.items:
		assert_true(
			not str(content.items[item_id]["description"]).contains("The Core"),
			"%s does not name The Core" % item_id
		)


func test_story_items_must_not_be_for_sale() -> void:
	var content := ContentDB.load_all()
	content.items["torn_label"]["price"] = 50
	content.errors.clear()
	content.validate()
	assert_true(
		Array(content.errors).any(func(e: String) -> bool: return "not for sale" in e),
		"priced evidence is rejected"
	)
