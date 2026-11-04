extends TestCase
## The street never stops: with the bag, the map, the game menu or even the
## game-over screen open, enemies, the clock and auto battle go on, as in an
## online game.

const TEST_SAVE := "user://test_live_menus_save"


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## Runs `frames` physics frames of the game as the engine would.
func _run(game: Game, frames: int) -> void:
	for i in frames:
		game._physics_process(1.0 / 60.0)


func test_the_street_goes_on_behind_every_screen() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	for open: Callable in [
		game.open_inventory, game.open_pause, func() -> void: game.open_screen("map")
	]:
		open.call()
		assert_true(game.menu != null, "%s is open" % game.menu_name)
		var before := game.zone.tick_count
		_run(game, 30)
		assert_eq(game.zone.tick_count - before, 30, "%s: the street went on" % game.menu_name)
		game.close_menu()
	_done(game)


func test_auto_fights_on_behind_the_bag() -> void:
	var game := _game()
	game.profile.level = 5
	game.enter_area("saltmarket", "west")
	game.auto.toggle()
	assert_true(game.auto.on, "auto on")
	game.open_inventory()
	var x := game.zone.hero.position.x
	_run(game, 240)
	assert_eq(game.menu_name, "bag", "the bag stays open")
	assert_true(game.zone.hero.position.x > x + 20.0, "and the hero walks on to the fight")
	_done(game)


func test_not_even_the_screens_that_wait_for_a_choice_stop_the_street() -> void:
	var game := _game()
	game.enter_area("saltmarket", "west")
	for name in Game.CHOICE_SCREENS:
		game._show(name, Control.new())
		var before := game.zone.tick_count
		_run(game, 10)
		assert_eq(game.zone.tick_count - before, 10, name + ": the street goes on")
		assert_eq(game.menu_name, name, name + ": still waiting for the choice")
		game.close_menu()
	_done(game)
