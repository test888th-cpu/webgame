extends TestCase
## "Return to Depot Yard" from the pause menu: straight home to upgrade and
## rest, but never out of a fight. Arriving rests the hero like walking in.

const TEST_SAVE := "user://test_recall_save.json"


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


func test_recall_takes_the_hero_home_rested() -> void:
	var game := _game()
	game.enter_area("rail_yards", "west")
	StreetMemory.mark_cleared(game.profile, "saltmarket", 0)
	game.zone.hero.hp = 5
	game.profile.hp = 5
	assert_eq(game.zone.recall_problem(), "", "free to go out of a fight")
	game._recall()
	assert_eq(game.zone.area_id, game.content.start_area, "home")
	assert_eq(game.zone.hero.hp, game.zone.hero.max_hp, "rested")
	assert_true(game.profile.cleared.is_empty(), "every street's fights are back")
	_done(game)


func test_no_recall_in_the_middle_of_a_fight() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	var events: Array[ZoneEvent] = []
	game.zone._start_encounter(0, events)
	assert_true(game.zone.recall_problem() != "", "a fight is no place to leave")
	game._recall()
	assert_eq(game.zone.area_id, "saltmarket", "still in the fight")
	_done(game)


func test_the_pause_menu_offers_it_only_when_allowed() -> void:
	var game := _game()
	game.open_pause()
	var button := game.menu.find_child("Recall", true, false) as Button
	assert_true(button != null and button.disabled, "greyed out at home already")
	game.close_menu()
	game.enter_area("saltmarket", "west")
	game.open_pause()
	button = game.menu.find_child("Recall", true, false) as Button
	assert_true(button != null and not button.disabled, "on offer out in the street")
	_done(game)
