extends TestCase
## The five heroes, each with their own edge and none best at everything: Kan
## reaches widest, Dao parries earliest, and the toughest is also the slowest.
## Skill armour (heroes.json `skill_armor`) stays a rule any hero may be given.

const BOUNDS := Rect2(0, 200, 2000, 200)
const CLASSES := [
	"The Boxer",
	"The Brawler",
	"The Grappler",
	"The Counter Fighter",
	"The Street Striker",
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


func test_all_five_classes_are_playable() -> void:
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
	assert_eq(_content().hero_order.size(), 5, "five heroes")
	var oren: Dictionary = _content().hero("oren")["stats"]
	for hero_id: String in _content().hero_order:
		if hero_id != "oren":
			var other: Dictionary = _content().hero(hero_id)["stats"]
			assert_true(oren["speed"] < other["speed"], "Oren is slower than %s" % hero_id)
			assert_true(oren["max_hp"] > other["max_hp"], "and tougher than %s" % hero_id)


func test_the_brawler_s_ultimate_covers_the_most_street() -> void:
	var widest := ""
	var reach := 0.0
	for hero_id: String in _content().hero_order:
		var skill: Dictionary = _content().skills[SkillRules.ultimate(_content(), hero_id)]
		for move_id in SkillSequence.moves(skill):
			var move := _content().moves.get_move(move_id)
			if move.reach_offset < 0.0 and move.reach > reach:
				reach = move.reach
				widest = hero_id
	assert_eq(widest, "oren", "the Grappler's shockwave is the widest single blow")
	var around := 0
	for move_id in SkillSequence.moves(_content().skills["street_carnage"]):
		around += 1 if _content().moves.get_move(move_id).reach_offset < 0.0 else 0
	assert_true(around >= 4, "but Street Carnage hits all around again and again")


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


func test_skill_armour_cannot_be_interrupted_mid_skill() -> void:
	for pair: Array in [["oren", true], ["oren", false]]:
		var hero := _hero_fighter(pair[0])
		hero.skill_armor = pair[1]
		hero.position = Vector2(500, 300)
		hero.facing = 1
		hero.energy = 100.0
		var foe := Fighter.new(2, 2, Vector2(470, 300), 100)
		foe.facing = 1  # behind the hero, jabbing its back
		foe.moveset = {"light": "thug_jab"}
		var fighters: Array[Fighter] = [hero, foe]
		var skill_id := "heavy_cross"
		hero.skills = SkillRules.unlocked(_content(), "riku", 70)
		var press := FighterInput.new()
		press.skill = skill_id
		CombatRules.tick(fighters, {hero.id: press}, _content().moves, BOUNDS)
		var jab := FighterInput.new()
		jab.light = true
		CombatRules.tick(fighters, {2: jab}, _content().moves, BOUNDS)
		for t in _content().moves.get_move("thug_jab").startup + 2:
			CombatRules.tick(fighters, {}, _content().moves, BOUNDS)
		var still := hero.state == Fighter.State.ATTACK
		assert_eq(still, pair[1], "skill armour %s keeps the skill going" % pair[1])
