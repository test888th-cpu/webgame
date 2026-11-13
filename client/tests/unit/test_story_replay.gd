extends TestCase
## Story boss and mini-boss rematches (ReplayRules, Rematch; BLUEPRINT D17):
## unlimited, fresh, private, and never a reset of the story or a second
## first-clear reward.

const TEST_SAVE := "user://test_story_replay_save"
## Canal Works: fight 0 holds the Smog Warden (a mini-boss), fight 1 the
## Sludge Foreman (the boss).
const AREA := "canal_works"
const BOSS_FIGHT := 1
const MINI_FIGHT := 0

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _profile() -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	for area_id in ["depot_yard", "saltmarket", AREA, "rusted_corner"]:
		StreetMemory.visit(profile, area_id)
	return profile


func _walk() -> FighterInput:
	var input := FighterInput.new()
	input.move = Vector2.RIGHT
	return input


## Walks the hero east until a fight starts (or gives up).
static func _walk_into_fight(zone: ZoneSim) -> void:
	var input := FighterInput.new()
	input.move = Vector2.RIGHT
	for _i in 900:
		if zone.in_encounter():
			break
		zone.tick(input)
	# Its first wave steps in a moment later.
	for _i in 240:
		if not zone.enemies().is_empty():
			return
		zone.tick(FighterInput.new())


static func _boss(zone: ZoneSim, kind: String) -> Fighter:
	for f in zone.enemies():
		if f.kind == kind:
			return f
	return null


func test_story_bosses_and_mini_bosses_are_boss_fights() -> void:
	var c := _content()
	assert_eq(ReplayRules.foe(c, AREA, BOSS_FIGHT), "sludge_foreman", "the boss")
	assert_eq(ReplayRules.foe(c, AREA, MINI_FIGHT), "smog_warden", "the mini-boss")
	assert_eq(ReplayRules.foe(c, "saltmarket", 0), "", "a plain street fight is not one")
	for area_id in AreaRules.farms(c) + AreaRules.lairs(c) + [c.city_area, "great_drain"]:
		for i in c.area(area_id).get("encounters", []).size():
			assert_true(not ReplayRules.is_boss_fight(c, area_id, i), "%s is not story" % area_id)
	# Every story boss can be fought again.
	var bosses := {}
	for fight in ReplayRules.rematches(_all_reached(), c):
		bosses[fight["foe"]] = true
	for area_id in StreetMemory.street(c):
		for encounter: Dictionary in c.area(area_id).get("encounters", []):
			for wave: Array in encounter["waves"]:
				for kind: String in wave:
					if c.enemy(kind).get("boss", false):
						assert_true(bosses.has(kind), kind + " has a rematch")


func _all_reached() -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	for area_id in StreetMemory.street(_content()):
		StreetMemory.visit(profile, area_id)
	return profile


func test_a_fight_opens_once_its_area_is_reached() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	assert_true(not ReplayRules.unlocked(profile, c, AREA, BOSS_FIGHT), "not reached yet")
	assert_eq(ReplayRules.rematch(profile, c, AREA, BOSS_FIGHT), -1.0, "no rematch")
	assert_true(not profile.cleared.has(AREA), "and nothing changed")
	StreetMemory.visit(profile, AREA)
	assert_true(ReplayRules.unlocked(profile, c, AREA, BOSS_FIGHT), "open once reached")


func test_rematches_are_unlimited_and_leave_the_story_alone() -> void:
	var c := _content()
	var profile := _profile()
	profile.defeated["sludge_foreman"] = 1
	profile.quests["test"] = {"state": "turned_in", "progress": 1}
	var before := {
		"quests": profile.quests.duplicate(true),
		"visited": profile.visited.duplicate(),
		"defeated": profile.defeated.duplicate(),
		"money": profile.money,
		"inventory": profile.inventory.duplicate(true),
	}
	var arena: Array = c.area(AREA)["encounters"][BOSS_FIGHT]["arena"]
	for attempt in 50:
		StreetMemory.mark_cleared(profile, AREA, BOSS_FIGHT)
		var x := ReplayRules.rematch(profile, c, AREA, BOSS_FIGHT)
		assert_eq(x, float(arena[0]), "rematch %d starts at the fight" % attempt)
	assert_true(not StreetMemory.is_cleared(profile, AREA, BOSS_FIGHT), "the boss is back")
	assert_true(StreetMemory.is_cleared(profile, AREA, MINI_FIGHT), "nothing else to replay")
	assert_eq(profile.quests, before["quests"], "quests kept")
	assert_eq(profile.visited, before["visited"], "areas reached kept")
	assert_eq(profile.defeated, before["defeated"], "kills kept: the gates stay open")
	assert_eq(profile.money, before["money"], "the rule charges nothing")
	assert_eq(profile.inventory, before["inventory"], "evidence and items kept")
	assert_eq(StreetMemory.gate(profile, c, AREA, "east"), {}, "the way on stays open")


func test_each_rematch_is_a_fresh_fight() -> void:
	var c := _content()
	var profile := _profile()
	for attempt in 3:
		var x := ReplayRules.rematch(profile, c, AREA, BOSS_FIGHT)
		var zone := ZoneSim.new(c, profile, AREA, "west", 7 + attempt, x)
		assert_eq(zone._encounters[MINI_FIGHT]["state"], "cleared", "straight to the boss")
		_walk_into_fight(zone)
		assert_true(zone.in_encounter(), "attempt %d: the fight starts" % attempt)
		var boss := _boss(zone, "sludge_foreman")
		assert_true(boss != null, "attempt %d: the boss is there" % attempt)
		if boss:
			assert_eq(boss.hp, boss.max_hp, "attempt %d: at full health" % attempt)
			boss.hp = 1  # Wounded in this attempt; the next starts over.
		profile.defeated["sludge_foreman"] = attempt + 1


func test_no_enemy_drops_a_first_clear_reward() -> void:
	var c := _content()
	assert_eq(ReplayRules.problems(c), PackedStringArray(), "shipped drop tables")
	var copy := ContentDB.load_all()
	var evidence := ""
	for item_id: String in copy.items:
		if copy.item(item_id).get("type") == "key":
			evidence = item_id
			break
	assert_true(evidence != "", "the game has evidence")
	var foreman: Dictionary = copy.enemies["sludge_foreman"]
	foreman["loot"]["drops"].append({"item": evidence, "chance": 1.0})
	var said := "\n".join(ReplayRules.problems(copy))
	assert_true("sludge_foreman" in said, "a boss dropping evidence is refused: " + said)


func test_a_quest_reward_is_paid_once() -> void:
	var c := _content()
	var profile := _profile()
	var quest_id := str(c.quests.keys()[0])
	profile.quests[quest_id] = {"state": "complete", "progress": 1}
	assert_true(not QuestRules.turn_in(profile, quest_id, c).is_empty(), "paid once")
	var money := profile.money
	assert_eq(QuestRules.turn_in(profile, quest_id, c), {}, "never twice")
	assert_eq(profile.money, money, "no second payment")


# Scene tests: Win's taxi, the game menu and the knock-out screen.


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	for area_id in ["saltmarket", AREA]:
		StreetMemory.visit(game.profile, area_id)
	game.profile.money = 100
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _win(game: Game) -> Dictionary:
	for npc: Dictionary in game.content.area("main_city")["npcs"]:
		if npc.get("routes") == "story":
			return npc
	return {}


func test_wins_taxi_rides_straight_to_a_boss_fight() -> void:
	var game := _game()
	game.enter_area("main_city", "west")
	var win := _win(game)
	game._show("travel", GameMenus.travel(game, win))
	var name := "Rematch_%s_%d" % [AREA, BOSS_FIGHT]
	var ride := game.menu.find_child(name, true, false) as Button
	assert_true(ride != null and not ride.disabled, "a rematch ride to the Sludge Foreman")
	assert_true(game.menu.find_child("Rematch_fight_club_1", true, false) == null, "not reached")
	var mini := "Rematch_%s_%d" % [AREA, MINI_FIGHT]
	assert_true(game.menu.find_child(mini, true, false) == null, "mini-bosses: the game menu")
	ride.pressed.emit()
	assert_eq(game.zone.area_id, AREA, "rode there")
	assert_eq(game.profile.money, 100 - int(win.get("fare", 0)), "for the usual fare")
	assert_eq(game.zone._encounters[BOSS_FIGHT]["state"], "pending", "the boss waits")
	_done(game)


func test_the_game_menu_offers_the_fight_again() -> void:
	var game := _game()
	game.enter_area(AREA, "west")
	game.open_pause()
	var again := game.menu.find_child("Rematch", true, false) as Button
	assert_true(again != null, "Fight ... again in the menu")
	if again:
		assert_true("Smog Warden" in again.text, "the mini-boss nearest: " + again.text)
		again.pressed.emit()
		assert_eq(game.zone._encounters[MINI_FIGHT]["state"], "pending", "fresh")
		assert_eq(game.zone._encounters[BOSS_FIGHT]["state"], "cleared", "only that fight")
	_done(game)


func test_a_lost_boss_fight_can_be_tried_again_at_once() -> void:
	var game := _game()
	Rematch.start(game, AREA, BOSS_FIGHT)
	_walk_into_fight(game.zone)
	assert_true(game.zone.in_encounter(), "in the boss fight")
	game.zone.hero.hp = 0
	game.open_game_over()
	var retry := game.menu.find_child("TryAgain", true, false) as Button
	assert_true(retry != null, "Try again on the knock-out screen")
	if retry:
		retry.pressed.emit()
		assert_eq(game.zone.area_id, AREA, "straight back, not the city")
		assert_eq(game.zone._encounters[BOSS_FIGHT]["state"], "pending", "a fresh fight")
		assert_eq(game.zone.hero.hp, game.zone.hero.max_hp, "healed")
	_done(game)
