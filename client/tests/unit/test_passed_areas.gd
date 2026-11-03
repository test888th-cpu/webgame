extends TestCase
## A street area the hero has already passed (ZoneSim.passed): its fights
## come back after a rest, for farming, but they hold no one in. The hero may
## fight, walk on east, walk back west, or leave by the pause menu; a fight
## walked away from comes back next visit. An area not passed yet still walls
## the hero in until the fight is won (test_zone_sim.gd covers that too).

const TEST_SAVE := "user://test_passed_areas_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A hero who has walked the street from Depot Yard up to and including
## `last`, opening every gate on the way, then rested (every fight is back).
func _profile_through(last: String) -> PlayerProfile:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	for area_id in StreetMemory.street(c):
		StreetMemory.visit(profile, area_id)
		var requires: Dictionary = c.area(area_id).get("exits", {}).get("east", {}).get(
			"requires", {}
		)
		if requires:
			profile.defeated[str(requires["defeat"])] = int(requires["count"])
		if area_id == last:
			break
	StreetMemory.rest(profile)
	return profile


func _walk(dir: Vector2) -> FighterInput:
	var input := FighterInput.new()
	input.move = dir
	return input


## Walks `zone`'s hero in `dir` for up to `ticks`, keeping them on their
## feet; returns the "exit" event's data, or {} when they never got out.
func _walk_out(zone: ZoneSim, dir: Vector2, ticks: int) -> Dictionary:
	for i in ticks:
		zone.hero.hp = zone.hero.max_hp
		for event in zone.tick(_walk(dir)):
			if event.type == "exit":
				return event.data
	return {}


## Walks east into the area's first fight; true once it has started.
func _into_first_fight(zone: ZoneSim) -> bool:
	for i in 1200:
		zone.hero.hp = zone.hero.max_hp
		zone.tick(_walk(Vector2.RIGHT))
		if zone.in_encounter():
			return true
	return false


func test_a_passed_area_lets_the_hero_walk_through_its_fights() -> void:
	var zone := ZoneSim.new(_content(), _profile_through("canal_works"), "saltmarket", "west", 3)
	assert_true(zone.passed, "Saltmarket is passed once Canal Works is reached")
	assert_true(_into_first_fight(zone), "its fights came back after the rest")
	assert_true(not zone.fight_locked(), "but the fight holds no one in")
	assert_eq(zone.walk, zone.bounds, "the whole street is walkable")
	assert_eq(zone.leave_problem(), "", "the pause menu's ways home work")
	var out := _walk_out(zone, Vector2.RIGHT, 2400)
	assert_eq(str(out.get("to", "")), "canal_works", "walked on east past the fight")


func test_the_hero_can_walk_back_west_out_of_a_passed_areas_fight() -> void:
	var zone := ZoneSim.new(_content(), _profile_through("canal_works"), "saltmarket", "west", 3)
	assert_true(_into_first_fight(zone), "a fight started")
	var out := _walk_out(zone, Vector2.LEFT, 1200)
	assert_eq(str(out.get("to", "")), "depot_yard", "walked back west")


func test_a_fight_walked_away_from_comes_back_and_a_won_one_stays_won() -> void:
	var c := _content()
	var profile := _profile_through("canal_works")
	var zone := ZoneSim.new(c, profile, "saltmarket", "west", 3)
	assert_true(_into_first_fight(zone), "a fight started")
	_walk_out(zone, Vector2.RIGHT, 2400)
	var all := StreetMemory.pending(profile, c, "saltmarket").size()
	assert_eq(all, c.area("saltmarket")["encounters"].size(), "not won, so all still to fight")
	# Win the first one where it stands (auto battle's pilot, a strong hero):
	# it stays won, as on any street.
	profile.level = 20
	var again := ZoneSim.new(c, profile, "saltmarket", "west", 3)
	assert_true(_into_first_fight(again), "the fight is there again")
	var pilot := AutoPilot.new(c)
	for i in 6000:
		again.hero.hp = again.hero.max_hp
		again.tick(pilot.think(again))
		if not again.in_encounter():
			break
	assert_true(StreetMemory.is_cleared(profile, "saltmarket", 0), "won and remembered")


func test_a_passed_areas_boss_fight_holds_no_one_in() -> void:
	var c := _content()
	var profile := _profile_through("rusted_corner")
	profile.defeated["sludge_foreman"] = 1
	var zone := ZoneSim.new(c, profile, "canal_works", "west", 3)
	assert_true(zone.passed, "Canal Works is passed once Rusted Corner is reached")
	var boss_at: int = c.area("canal_works")["encounters"].size() - 1
	for i in boss_at:
		StreetMemory.mark_cleared(profile, "canal_works", i)
	zone = ZoneSim.new(c, profile, "canal_works", "west", 3)
	assert_true(_into_first_fight(zone), "the Foreman's fight came back")
	assert_true(not zone.fight_locked(), "and can be walked past")
	var out := _walk_out(zone, Vector2.RIGHT, 3600)
	assert_eq(str(out.get("to", "")), "rusted_corner", "on east without beating him again")


func test_an_area_not_passed_yet_still_walls_the_hero_in() -> void:
	var c := _content()
	var profile := _profile_through("saltmarket")
	var zone := ZoneSim.new(c, profile, "saltmarket", "west", 3)
	assert_true(not zone.passed, "Canal Works not reached: not passed")
	assert_true(_into_first_fight(zone), "a fight started")
	assert_true(zone.fight_locked(), "it holds the hero in")
	assert_eq(zone.walk, zone.arena, "inside its ground")
	assert_true(zone.leave_problem() != "", "no way out by the menu")
	assert_eq(_walk_out(zone, Vector2.LEFT, 600), {}, "nor on foot")


func test_farming_grounds_and_world_boss_arenas_keep_their_fights() -> void:
	var c := _content()
	var profile := _profile_through("gang_hq")
	for enemy_id: String in c.enemies:
		if c.enemy(enemy_id).get("boss", false):
			profile.defeated[enemy_id] = 1
	var ground := ZoneSim.new(c, profile, "farm_saltmarket_backlots", "west", 3)
	assert_true(not ground.passed, "a farming ground is never 'passed'")
	for boss: String in c.world_bosses:
		var arena := str(WorldBossRules.spec(c, boss)["area"])
		assert_true(not ZoneSim.new(c, profile, arena, "west", 3).passed, arena + ": not passed")


func test_the_pause_menu_takes_the_hero_out_of_a_passed_areas_fight() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var passed := _profile_through("canal_works")
	game.profile.visited = passed.visited
	game.profile.defeated = passed.defeated
	game.enter_area("saltmarket", "west")
	assert_true(_into_first_fight(game.zone), "a fight in Saltmarket")
	assert_eq(game.city_problem(), "", "the return to the city is on offer")
	game._go_to_city()
	assert_eq(game.zone.area_id, game.content.city_area, "back in the city")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
