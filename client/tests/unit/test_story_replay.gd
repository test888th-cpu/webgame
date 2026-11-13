extends TestCase
## Story boss and story mini-boss replays (ReplayRules, Rematch; BLUEPRINT
## D18): unlimited, fresh, private, free (but for the taxi's fare), and never a
## reset of the story or a second first-clear reward.

const TEST_SAVE := "user://test_story_replay_save"
## Canal Works: fight 0 holds the Smog Warden (an elite, not a boss fight),
## fight 1 the Sludge Foreman (a story mini-boss: its district goes on).
const AREA := "canal_works"
const BOSS_FIGHT := 1
const ELITE_FIGHT := 0
## Gang HQ ends South Street on the Furnace Baron, a stage boss.
const STAGE_AREA := "gang_hq"

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


func _all_reached() -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	for area_id in StreetMemory.street(_content()):
		StreetMemory.visit(profile, area_id)
	return profile


## Walks the hero east until a fight starts and its first wave is in.
static func _walk_into_fight(zone: ZoneSim) -> void:
	var input := FighterInput.new()
	input.move = Vector2.RIGHT
	for _i in 900:
		if zone.in_encounter():
			break
		zone.tick(input)
	for _i in 240:
		if not zone.enemies().is_empty():
			return
		zone.tick(FighterInput.new())


static func _boss(zone: ZoneSim, kind: String) -> Fighter:
	for f in zone.enemies():
		if f.kind == kind:
			return f
	return null


func test_story_bosses_and_mini_bosses_are_the_boss_fights() -> void:
	var c := _content()
	assert_eq(ReplayRules.foe(c, AREA, BOSS_FIGHT), "sludge_foreman", "the boss")
	assert_eq(ReplayRules.rank(c, AREA), ReplayRules.MINI_BOSS, "a story mini-boss")
	assert_eq(ReplayRules.rank(c, STAGE_AREA), ReplayRules.STAGE_BOSS, "the Baron: stage boss")
	assert_eq(ReplayRules.foe(c, AREA, ELITE_FIGHT), "", "an elite is not a boss fight")
	assert_eq(ReplayRules.foe(c, "saltmarket", 0), "", "nor is a street fight")
	for area_id in AreaRules.farms(c) + AreaRules.lairs(c) + [c.city_area, "great_drain"]:
		for i in c.area(area_id).get("encounters", []).size():
			assert_true(not ReplayRules.is_boss_fight(c, area_id, i), "%s is not story" % area_id)
	# Every story boss, and nothing else, can be fought again: 6 stage bosses
	# and 5 mini-bosses (MapRules.kind_of).
	var fights := ReplayRules.rematches(_all_reached(), c)
	var ranks := {ReplayRules.STAGE_BOSS: 0, ReplayRules.MINI_BOSS: 0}
	for fight in fights:
		assert_true(c.enemy(str(fight["foe"])).get("boss", false), str(fight["foe"]))
		ranks[fight["rank"]] += 1
	assert_eq(ranks, {ReplayRules.STAGE_BOSS: 6, ReplayRules.MINI_BOSS: 5}, "11 boss fights")


func test_a_fight_opens_once_its_area_is_reached() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	assert_true(not ReplayRules.unlocked(profile, c, AREA, BOSS_FIGHT), "not reached yet")
	assert_eq(ReplayRules.rematch(profile, c, AREA, BOSS_FIGHT), -1.0, "no replay")
	assert_true(not profile.cleared.has(AREA), "and nothing changed")
	StreetMemory.visit(profile, AREA)
	assert_true(ReplayRules.unlocked(profile, c, AREA, BOSS_FIGHT), "open once reached")


func test_replays_are_unlimited_and_leave_the_story_alone() -> void:
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
		assert_eq(x, float(arena[0]), "replay %d starts at the fight" % attempt)
	assert_true(not StreetMemory.is_cleared(profile, AREA, BOSS_FIGHT), "the boss is back")
	assert_true(StreetMemory.is_cleared(profile, AREA, ELITE_FIGHT), "nothing else to replay")
	assert_eq(profile.quests, before["quests"], "quests kept")
	assert_eq(profile.visited, before["visited"], "areas reached kept")
	assert_eq(profile.defeated, before["defeated"], "kills kept: the gates stay open")
	assert_eq(profile.money, before["money"], "the rule charges nothing")
	assert_eq(profile.inventory, before["inventory"], "evidence and items kept")
	assert_eq(StreetMemory.gate(profile, c, AREA, "east"), {}, "the way on stays open")


func test_each_replay_is_a_fresh_fight() -> void:
	var c := _content()
	var profile := _profile()
	for attempt in 3:
		var x := ReplayRules.rematch(profile, c, AREA, BOSS_FIGHT)
		var zone := ZoneSim.new(c, profile, AREA, "west", 7 + attempt, x)
		assert_eq(zone._encounters[ELITE_FIGHT]["state"], "cleared", "straight to the boss")
		_walk_into_fight(zone)
		assert_true(zone.in_encounter(), "attempt %d: the fight starts" % attempt)
		var boss := _boss(zone, "sludge_foreman")
		assert_true(boss != null, "attempt %d: the boss is there" % attempt)
		if boss:
			assert_eq(boss.hp, boss.max_hp, "attempt %d: at full health" % attempt)
			assert_eq(zone.phase_of(boss.id), 0, "attempt %d: its first phase" % attempt)
			boss.hp = 1  # Wounded in this attempt; the next starts over.
		profile.defeated["sludge_foreman"] = attempt + 1


## A once-only drop (evidence, a unique item) already owned is left out alone;
## the rest of the table keeps dropping on every replay.
func test_only_once_only_drops_are_held_back() -> void:
	var c := _content()
	var profile := _profile()
	var evidence := ""
	var gear := ""
	for item_id: String in c.items:
		if evidence == "" and c.item(item_id).get("type") == "key":
			evidence = item_id
		if gear == "" and c.item(item_id).get("slot") != null:
			gear = item_id
	assert_true(evidence != "" and gear != "", "the game has evidence and gear")
	var table := {"drops": [{"item": evidence, "chance": 1.0}, {"item": gear, "chance": 1.0}]}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var first: Array = LootRules.roll(table, rng, profile, "sludge_foreman", c)["items"]
	assert_eq(first, [evidence, gear], "both, while the evidence is not owned")
	profile.add_item(evidence, 1)
	profile.add_item(gear, 1)
	for replay in 5:
		var items: Array = LootRules.roll(table, rng, profile, "sludge_foreman", c)["items"]
		assert_eq(items, [gear], "replay %d: the gear again, never the evidence" % replay)
	assert_true(LootRules.eligible(gear, profile, c), "gear stays eligible")
	assert_true(not LootRules.eligible(evidence, profile, c), "owned evidence does not")


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


func test_wins_taxi_rides_straight_to_a_boss_fight_for_its_fare() -> void:
	var game := _game()
	game.enter_area("main_city", "west")
	var win := _win(game)
	game._show("travel", GameMenus.travel(game, win))
	var name := "Rematch_%s_%d" % [AREA, BOSS_FIGHT]
	var ride := game.menu.find_child(name, true, false) as Button
	assert_true(ride != null and not ride.disabled, "a ride to the Sludge Foreman")
	if ride:
		assert_true("mini-boss" in ride.text, "marked a mini-boss: " + ride.text)
	assert_true(game.menu.find_child("Rematch_fight_club_1", true, false) == null, "not reached")
	var elite := "Rematch_%s_%d" % [AREA, ELITE_FIGHT]
	assert_true(game.menu.find_child(elite, true, false) == null, "no elite fights")
	ride.pressed.emit()
	assert_eq(game.zone.area_id, AREA, "rode there")
	assert_eq(game.profile.money, 100 - int(win.get("fare", 0)), "the usual fare, nothing more")
	assert_eq(game.zone._encounters[BOSS_FIGHT]["state"], "pending", "the boss waits")
	_done(game)


func test_the_game_menu_replays_the_fight_for_free() -> void:
	var game := _game()
	game.enter_area(AREA, "east")
	game.open_pause()
	var again := game.menu.find_child("Rematch", true, false) as Button
	assert_true(again != null, "Fight ... again in the menu")
	if again:
		assert_true("Sludge Foreman" in again.text, again.text)
		again.pressed.emit()
		assert_eq(game.zone._encounters[BOSS_FIGHT]["state"], "pending", "fresh")
		assert_eq(game.zone._encounters[ELITE_FIGHT]["state"], "cleared", "only that fight")
		assert_eq(game.profile.money, 100, "free")
	_done(game)


func test_a_lost_boss_fight_can_be_tried_again_at_once_for_free() -> void:
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
		assert_eq(game.profile.money, 100, "free: no coins dropped")
	_done(game)
