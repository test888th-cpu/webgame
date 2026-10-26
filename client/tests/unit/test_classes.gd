extends TestCase
## The six classes of the brief, each with its own edge and none best at
## everything: Kan reaches widest, Dao parries earliest, Pong's skills cannot
## be interrupted, and the toughest is also the slowest.

const BOUNDS := Rect2(0, 200, 2000, 200)
const CLASSES := [
	"The Boxer",
	"The Street Brawler",
	"The Footballer",
	"The Basketball Player",
	"The Police Officer",
	"The Soldier",
]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hero_fighter(hero_id: String) -> Fighter:
	var zone := ZoneSim.new(
		_content(), PlayerProfile.new_game(_content(), hero_id), "depot_yard", "", 1
	)
	return zone.hero


func test_all_six_classes_are_playable() -> void:
	var titles := []
	for hero_id: String in _content().hero_order:
		titles.append(str(_content().hero(hero_id)["title"]))
	for title: String in CLASSES:
		assert_true(title in titles, "%s is in the roster" % title)


func test_no_hero_is_best_at_everything() -> void:
	var best := {}
	for stat: String in ["max_hp", "power", "speed"]:
		var top := ""
		for hero_id: String in _content().hero_order:
			var value := float(_content().hero(hero_id)["stats"][stat])
			if top == "" or value > float(_content().hero(top)["stats"][stat]):
				top = hero_id
		best[stat] = top
	assert_true(
		not (best["max_hp"] == best["power"] and best["power"] == best["speed"]),
		"nobody tops health, power and speed together"
	)
	var pong: Dictionary = _content().hero("pong")["stats"]
	for hero_id: String in _content().hero_order:
		if hero_id != "pong":
			var other: Dictionary = _content().hero(hero_id)["stats"]
			assert_true(pong["speed"] < other["speed"], "the Soldier is slower than %s" % hero_id)
			assert_true(pong["max_hp"] > other["max_hp"], "and tougher than %s" % hero_id)


func test_the_basketball_player_reaches_widest() -> void:
	var widest := ""
	var reach := 0.0
	for hero_id: String in _content().hero_order:
		var skills: Array = _content().hero(hero_id)["skills"]
		var move := _content().moves.get_move(str(_content().skills[skills[3]]["move"]))
		if move.reach > reach:
			reach = move.reach
			widest = hero_id
	assert_eq(widest, "kan", "Kan's slam dunk covers the most street")


func test_the_police_officer_parries_from_further_out() -> void:
	var dao := _hero_fighter("dao")
	var mika := _hero_fighter("mika")
	assert_true(dao.parry_window > mika.parry_window, "a wider parry window")
	# A guard raised ~10 ticks before the hit: Dao parries, Mika only blocks.
	for pair: Array in [[dao, true], [mika, false]]:
		var hero: Fighter = pair[0]
		hero.position = Vector2(500, 300)
		hero.facing = 1
		var foe := Fighter.new(2, 2, Vector2(528, 300), 100)
		foe.facing = -1
		foe.moveset = {"light": "brute_slam"}
		var fighters: Array[Fighter] = [hero, foe]
		var startup := _content().moves.get_move("brute_slam").startup
		var events: Array[CombatEvent] = []
		for t in startup + 2:
			var inputs := {}
			if t == 0:
				var press := FighterInput.new()
				press.light = true
				inputs[2] = press
			if t >= startup - 10:
				var guard := FighterInput.new()
				guard.guard = true
				inputs[hero.id] = guard
			events.append_array(CombatRules.tick(fighters, inputs, _content().moves, BOUNDS))
		assert_eq(events[0].parried, pair[1], "%s parries: %s" % [hero.kind, pair[1]])


func test_the_soldier_cannot_be_interrupted_mid_skill() -> void:
	for pair: Array in [["pong", true], ["oren", false]]:
		var hero := _hero_fighter(pair[0])
		hero.position = Vector2(500, 300)
		hero.facing = 1
		hero.energy = 100.0
		var foe := Fighter.new(2, 2, Vector2(470, 300), 100)
		foe.facing = 1  # behind the hero, jabbing its back
		foe.moveset = {"light": "thug_jab"}
		var fighters: Array[Fighter] = [hero, foe]
		var skill_id := str(_content().hero(pair[0])["skills"][0])
		var press := FighterInput.new()
		press.skill = skill_id
		CombatRules.tick(fighters, {hero.id: press}, _content().moves, BOUNDS)
		var jab := FighterInput.new()
		jab.light = true
		CombatRules.tick(fighters, {2: jab}, _content().moves, BOUNDS)
		for t in _content().moves.get_move("thug_jab").startup + 2:
			CombatRules.tick(fighters, {}, _content().moves, BOUNDS)
		var still := hero.state == Fighter.State.ATTACK
		assert_eq(still, pair[1], "%s keeps the skill going: %s" % [pair[0], pair[1]])
