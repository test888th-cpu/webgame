extends TestCase
## Auto battle at home (the city and Depot Yard, next door to each other and
## both healing on entry): it rests where it stands, walks between them
## instead of paying the taxi, and never strands a poor, hurt hero in the city.

const TEST_SAVE := "user://test_auto_home_save"


func _game() -> Node2D:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("oren")
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	TutorialRules.skip(game.profile, game.content)
	QuestRules.accept(game.profile, "foreman", game.content)
	return game


func _done(game: Node2D) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## Runs auto from `start` for up to `ticks`; returns the areas it went through.
func _auto(game: Node2D, start: String, ticks: int, poor_and_hurt := false) -> Array[String]:
	game.enter_area(start, "west")
	if poor_and_hurt:
		game.profile.money = 0
		game.profile.inventory.clear()
		game.zone.hero.hp = 10
		game.profile.hp = 10
	game.auto.toggle()
	var seen: Array[String] = [start]
	for t in ticks:
		if not game.auto.on or "saltmarket" in seen:
			break
		game.step(game.auto.input(FighterInput.new(), false))
		if game.zone.area_id != seen[-1]:
			seen.append(game.zone.area_id)
	return seen


func test_home_rests_in_place_and_walks_next_door() -> void:
	var c := GameSession.content
	assert_eq(AreaRules.rest_home(c, "depot_yard"), "depot_yard", "the yard heals: rest there")
	assert_eq(AreaRules.rest_home(c, "main_city"), "main_city", "so does the city")
	assert_eq(AreaRules.rest_home(c, "saltmarket"), "main_city", "the street rests in the city")
	assert_eq(AutoRules.ride_fare(c, "main_city", "depot_yard"), 0, "next door: no fare")
	assert_eq(AutoRules.ride_fare(c, "depot_yard", "depot_yard"), 0, "staying: no fare")
	assert_eq(AutoRules.ride_fare(c, "main_city", "canal_works"), 10, "a real ride is paid")


func test_a_poor_hurt_hero_in_the_yard_is_not_sent_to_the_city() -> void:
	var game := _game()
	var seen := _auto(game, "depot_yard", 3000, true)
	assert_true("main_city" not in seen, "no trip to the city: %s" % [seen])
	assert_true(game.auto.on, "auto keeps going")
	assert_true("saltmarket" in seen, "rested in the yard, then on east")
	_done(game)


func test_from_the_city_auto_walks_into_the_yard_and_on() -> void:
	var game := _game()
	var money: int = game.profile.money
	var step := StoryAuto.step(game.profile, game.content, "main_city", true)
	assert_eq(step["do"], StoryAuto.EAST, "the yard is next door: walk")
	var seen := _auto(game, "main_city", 4000)
	assert_eq(seen, ["main_city", "depot_yard", "saltmarket"] as Array[String], "on foot")
	assert_true(game.profile.money >= money, "no fare paid")
	_done(game)
