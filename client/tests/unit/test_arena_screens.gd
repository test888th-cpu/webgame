extends TestCase
## The arena's screens in the game scene (ArenaFlow, ArenaScreen): the
## ladder's standing and five cards, "New rivals", a rival's details showing
## its real configured gear, the challenge only after confirming, and the
## result's draw, rematch and leave buttons each doing what they say.

const TEST_SAVE := "user://test_arena_screens"


func _game(level := 70) -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("riku")
	tree.root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.profile.level = level
	game.enter_area(game.content.city_area, "")
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _npc(game: Game) -> Dictionary:
	for entry: Dictionary in game.content.area(game.content.city_area)["npcs"]:
		if entry["role"] == "arena":
			return entry
	return {}


func _texts(root: Node) -> String:
	var out: PackedStringArray = []
	for node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return "\n".join(out)


func test_the_ladder_shows_standing_cards_and_new_rivals() -> void:
	var game := _game()
	game.arena.open_ladder(_npc(game))
	await tree.process_frame
	var text := _texts(game.menu)
	assert_true("Unranked (#51)" in text, "the rank")
	assert_true("0W 0L 0D" in text and "Win rate 0%" in text, "the record and win rate")
	assert_true("Champion: Iron Abbot" in text, "the champion")
	var cards := game.menu.find_children("Rival_*", "PanelContainer", true, false)
	assert_eq(cards.size(), 5, "five cards")
	for card: Node in cards:
		var label := (card.find_child("Difficulty", true, false) as Label).text
		assert_true(label in ["Easy", "Even", "Hard", "Very Hard"], "a difficulty: %s" % label)
		assert_true("AI " in _texts(card), "the AI level")
	var before := cards.map(func(n: Node) -> String: return n.name)
	(game.menu.find_child("Refresh", true, false) as Button).pressed.emit()
	await tree.process_frame
	var after := game.menu.find_children("Rival_*", "PanelContainer", true, false).map(
		func(n: Node) -> String: return n.name
	)
	assert_eq(game.menu_name, "arena", "still on the ladder")
	assert_eq(after[0], before[0], "the nearest stays")
	assert_eq(int(ArenaRules.state(game.profile, game.content)["refresh"]), 1, "counted, free")
	_done(game)


func test_details_show_the_configured_gear_and_need_a_confirm() -> void:
	var game := _game()
	game.arena.open_ladder(_npc(game))
	await tree.process_frame
	var card := game.menu.find_children("Rival_*", "PanelContainer", true, false)[0]
	var id := str(card.name).trim_prefix("Rival_")
	(card.find_child("Fight", true, false) as Button).pressed.emit()
	await tree.process_frame
	assert_eq(game.menu_name, "arena_details", "details first")
	assert_true(not game.arena.active(), "no match yet")
	var text := _texts(game.menu)
	var data := ArenaRules.rival(game.content, id)
	for slot: String in data["slots"]:
		var worn: Dictionary = data["slots"][slot]
		assert_true(str(game.content.item(str(worn["item"]))["name"]) in text, "its %s" % slot)
		assert_true("+%d" % int(worn["plus"]) in text, "its upgrade")
	assert_true(str(data["personality"]).capitalize() in text, "its style")
	(game.menu.find_child("Back", true, false) as Button).pressed.emit()
	await tree.process_frame
	assert_eq(game.menu_name, "arena", "Back returns to the ladder")
	_done(game)


func test_a_draw_result_offers_rematch_and_leave() -> void:
	var game := _game(70)
	game.arena.open_ladder(_npc(game))
	await tree.process_frame
	var id := ArenaRules.choices(game.profile, game.content)[0]
	game.arena.start(id)
	await tree.process_frame
	var bout := game.arena.bout
	bout.countdown = 1
	game.step(FighterInput.new())
	bout.ticks_left = 1
	bout.zone.hero.hp = bout.zone.hero.max_hp / 2
	bout.rival.hp = bout.rival.max_hp / 2
	game.step(FighterInput.new())
	assert_eq(game.menu_name, "arena_result", "the result shows")
	assert_true("DRAW" in _texts(game.menu), "a draw")
	assert_eq(ArenaRules.rank_of(game.profile, game.content), 51, "no rank change")
	var rematch := game.menu.find_child("Rematch", true, false) as Button
	assert_true(rematch != null, "a rematch is offered")
	var first := bout.match_id
	rematch.pressed.emit()
	await tree.process_frame
	assert_true(game.arena.active(), "a new match")
	assert_true(game.arena.bout.match_id > first, "with a new match id")
	assert_eq(game.arena.bout.rival_id, id, "against the same rival")
	var again := game.arena.bout
	again.countdown = 1
	game.step(FighterInput.new())
	again.zone.hero.state = Fighter.State.KO
	game.step(FighterInput.new())
	(game.menu.find_child("Leave", true, false) as Button).pressed.emit()
	await tree.process_frame
	assert_eq(game.zone.area_id, game.content.city_area, "Leave goes to the city")
	assert_eq(game.menu_name, "", "with no menu")
	var arena := ArenaRules.state(game.profile, game.content)
	assert_eq([int(arena["draws"]), int(arena["losses"])], [1, 1], "both results recorded once")
	assert_true(game.profile.hp <= int(game.profile.stats(game.content)["max_hp"]), "normal health")
	_done(game)
