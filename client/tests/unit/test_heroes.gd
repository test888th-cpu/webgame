extends TestCase
## Playable heroes: the roster data, player names, per-hero stats and skills,
## and saves that remember who you play.

const TEST_SAVE := "user://test_save.json"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_roster_has_a_female_and_a_male_hero_that_play_differently() -> void:
	var db := _content()
	assert_eq(db.hero_order, ["mika", "oren", "riku", "kan", "dao", "pong"], "roster order")
	assert_eq(db.hero("mika")["gender"], "Female", "Mika")
	assert_eq(db.hero("oren")["gender"], "Male", "Oren")
	var mika := PlayerProfile.new_game(db, "mika").stats(db)
	var oren := PlayerProfile.new_game(db, "oren").stats(db)
	assert_true(oren["max_hp"] > mika["max_hp"], "Oren is tougher")
	assert_true(oren["defense"] > mika["defense"], "and better armoured")
	assert_true(mika["power"] > oren["power"], "Mika hits harder")
	assert_true(oren["speed"] < mika["speed"], "and is faster")


func test_riku_is_the_all_rounder_between_the_other_two() -> void:
	var db := _content()
	var mika := PlayerProfile.new_game(db, "mika").stats(db)
	var oren := PlayerProfile.new_game(db, "oren").stats(db)
	var riku := PlayerProfile.new_game(db, "riku").stats(db)
	# Between the others on the core stats; his edge is precision.
	for stat: String in ContentDB.HERO_STATS:
		var low := minf(float(mika[stat]), float(oren[stat]))
		var high := maxf(float(mika[stat]), float(oren[stat]))
		assert_true(
			float(riku[stat]) >= low and float(riku[stat]) <= high,
			"Riku's %s lies between Mika's and Oren's" % stat
		)
	assert_true(
		float(riku["crit"]) > maxf(float(mika["crit"]), float(oren["crit"])),
		"the Boxer crits most often"
	)
	assert_eq(db.hero_art(PlayerProfile.new_game(db, "riku")), "hero_riku", "his own sprite")
	assert_eq(db.art["hero_riku"]["source"], "original", "drawn by tools/assets/gen_hero.py")


func test_player_names_are_cleaned_and_validated() -> void:
	assert_eq(PlayerProfile.clean_name("  Big   Ace "), "Big Ace", "spaces collapsed")
	assert_eq(PlayerProfile.clean_name("สมชาย"), "สมชาย", "Thai names are allowed")
	assert_eq(PlayerProfile.clean_name("O'Neil-2"), "O'Neil-2", "apostrophes, hyphens, digits")
	assert_eq(PlayerProfile.clean_name("A"), "", "too short")
	assert_eq(PlayerProfile.clean_name("ABCDEFGHIJKLMNOPQ"), "", "too long")
	assert_eq(PlayerProfile.clean_name("<script>"), "", "symbols rejected")
	assert_eq(PlayerProfile.clean_name("-dash"), "", "must start with a letter or digit")


func test_new_game_uses_the_chosen_hero_and_name() -> void:
	var profile := PlayerProfile.new_game(_content(), "oren", "Tank")
	assert_eq([profile.hero, profile.name], ["oren", "Tank"], "chosen")
	var fallback := PlayerProfile.new_game(_content(), "nobody", "!!")
	assert_eq([fallback.hero, fallback.name], ["mika", "Mika"], "defaults for bad input")


func test_each_hero_has_their_own_skills() -> void:
	var db := _content()
	var oren := SkillRules.unlocked(db, "oren", 1)
	assert_true(oren.has("headbutt") and oren.has("clothesline"), "Oren's Lv 1 skills")
	assert_true(not oren.has("rising_uppercut"), "not Mika's")
	assert_eq(db.hotbar_for("oren")[1]["id"], "headbutt", "Oren's hotbar slot 2")
	assert_eq(db.hotbar_for("mika")[1]["id"], "rising_uppercut", "Mika's hotbar slot 2")
	var zone := ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "depot_yard", "", 1)
	var input := FighterInput.new()
	input.skill = "rising_uppercut"
	zone.tick(input)
	assert_eq(zone.hero.state, Fighter.State.IDLE, "Oren cannot use Mika's skill")
	input.skill = "headbutt"
	zone.tick(input)
	assert_eq(zone.hero.move.id if zone.hero.move else "", "headbutt", "but can headbutt")
	assert_near(zone.hero.speed, 0.85, "Oren walks slower")


func test_each_hero_starts_with_a_kit() -> void:
	var mika := PlayerProfile.new_game(_content(), "mika")
	assert_eq(mika.equipment["feet"], "canvas_sneakers", "Mika starts in sneakers")
	assert_eq(mika.count("steamed_bun"), 3, "with buns")
	var oren := PlayerProfile.new_game(_content(), "oren")
	assert_eq(oren.equipment["body"], "padded_vest", "Oren starts in a vest")
	assert_eq(oren.money, 30, "and some coins")
	assert_eq(oren.hp, oren.stats(_content())["max_hp"], "at full health")


func test_saves_remember_the_hero_and_name() -> void:
	var db := _content()
	var profile := PlayerProfile.new_game(db, "oren", "Big Oren")
	var loaded := PlayerProfile.from_dict(profile.to_dict(), db)
	assert_eq([loaded.hero, loaded.name], ["oren", "Big Oren"], "round trip")
	var unknown := profile.to_dict()
	unknown["hero"] = "nobody"
	assert_eq(PlayerProfile.from_dict(unknown, db), null, "unknown hero rejected")


func test_version_1_saves_become_mika() -> void:
	var old := {"version": 1, "level": 3, "xp": 5, "money": 40, "area": "saltmarket"}
	var loaded := PlayerProfile.from_dict(old, _content())
	assert_true(loaded != null, "loads")
	assert_eq([loaded.hero, loaded.name, loaded.level], ["mika", "Mika", 3], "migrated")


func test_hero_art_follows_the_hero_and_armour() -> void:
	SaveStore.path = TEST_SAVE
	GameSession.start_new_game("oren", "Tank")
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	assert_eq(game.view.hero_art(), "hero_oren", "Oren's sprite")
	game.profile.level = 3
	game.profile.add_item("work_jacket")
	game._equip("work_jacket")
	assert_eq(game.view.hero_art(), "hero_oren_armoured", "armoured look")
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH
