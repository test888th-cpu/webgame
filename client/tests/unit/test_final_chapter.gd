extends TestCase
## The final chapter, The Iron Legacy: four areas past the Control Room and
## Director Wiroj in three distinct phases (story bible §4): his own blows;
## then the chamber's defences, steam, shocking floor plates and lasers in
## turn, while he hides behind a shield that drops when the system resets;
## then a desperate last stand. Beating him plays the epilogue.

const CORE := ["core_approach", "cooling_tunnels", "reactor_walkway", "core_chamber"]
const TEST_SAVE := "user://test_final_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## The Core Chamber with the hero and Wiroj alone, the fight on, his blows
## held back so only the chamber acts.
func _wiroj_fight() -> ZoneSim:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "core_chamber", "", 6)
	var events: Array[ZoneEvent] = []
	zone._start_encounter(1, events)
	zone._waves_left.clear()
	for i in 240:
		zone.tick(FighterInput.new())
		if zone.boss_id != 0:
			break
	zone.hero.max_hp = 1000000
	zone.hero.hp = 1000000
	return zone


func _hold(zone: ZoneSim) -> void:
	for id: int in zone.brains:
		(zone.brains[id] as EnemyBrain).cooldown = 100000


## Wiroj at `share` of his health, his phases caught up.
func _hurt(zone: ZoneSim, share: float) -> Fighter:
	var wiroj := zone.fighter(zone.boss_id)
	wiroj.hp = roundi(wiroj.max_hp * share)
	_hold(zone)
	zone.tick(FighterInput.new())
	return wiroj


func test_the_core_follows_the_control_room() -> void:
	var street := StreetMemory.street(_content())
	var at := street.find("control_room")
	for i in CORE.size():
		assert_eq(street[at + 1 + i], CORE[i], "%s in order" % CORE[i])
	assert_eq(street.back(), "core_chamber", "the street ends in the Core Chamber")
	var gate: Dictionary = _content().area("control_room")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "commander_arthit", "opened by beating Arthit")
	var wiroj := _content().enemy("director_wiroj")
	var level := LevelRules.enemy_level(wiroj, int(_content().area("core_chamber")["level"]))
	assert_eq(level, int(_content().progression["max_level"]), "Wiroj fights at the level cap")


func test_wiroj_has_three_distinct_phases() -> void:
	var phases: Array = _content().enemy("director_wiroj")["phases"]
	assert_eq(phases.size(), 2, "two changes: three phases")
	assert_true(phases[0].has("shield"), "phase 2 hides behind the defences")
	assert_eq(phases[0]["hazard"]["cycle"].size(), 3, "steam, shock and lasers")
	assert_true((phases[1]["hazard"] as Dictionary).is_empty(), "phase 3: defences down")
	assert_true(not phases[1].has("shield"), "and nothing to hide behind")


func test_his_first_phase_is_his_own_blows_only() -> void:
	var zone := _wiroj_fight()
	for tick in 900:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			assert_true(event.type != "hazard_warn", "no defences in phase 1")
	assert_true(CombatRules.is_vulnerable(zone.fighter(zone.boss_id)), "and he can be hit")


func test_the_shield_rises_and_resets_in_a_rhythm() -> void:
	var zone := _wiroj_fight()
	var wiroj := _hurt(zone, 0.6)
	var shield: Dictionary = _content().enemy("director_wiroj")["phases"][0]["shield"]
	var changes: Array[bool] = []
	var warned_while_open := false
	for tick in int(shield["up"]) + int(shield["down"]) + 10:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "boss_shield":
				changes.append(bool(event.data["up"]))
				if event.data["up"]:
					assert_true(not CombatRules.is_vulnerable(wiroj), "untouchable when up")
			if event.type == "hazard_warn" and not changes.is_empty() and not changes.back():
				warned_while_open = true
	assert_eq(changes, [true, false, true] as Array[bool], "up, reset, up again")
	assert_true(not warned_while_open, "no new hazards while the system resets")


func test_the_defences_come_in_turn() -> void:
	var zone := _wiroj_fight()
	_hurt(zone, 0.6)
	var kinds: Array[String] = []
	for tick in 400:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "hazard_warn":
				kinds.append(str(event.data["kind"]))
	assert_eq(kinds.slice(0, 3), ["steam", "shock", "laser"] as Array[String], "in turn")


func test_his_last_stand_drops_the_defences() -> void:
	var zone := _wiroj_fight()
	_hurt(zone, 0.6)
	var wiroj := _hurt(zone, 0.2)
	for tick in 60:
		_hold(zone)
		zone.tick(FighterInput.new())
	assert_true(CombatRules.is_vulnerable(wiroj), "the shield is gone for good")
	for tick in 600:
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			assert_true(event.type != "hazard_warn", "and so are the defences")


func test_beating_him_plays_the_epilogue() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.enter_area("core_approach", "west")
	game.profile.quests["the_iron_legacy"] = {"state": "complete", "progress": 1}
	var pim: Dictionary = {}
	for npc: Dictionary in game.zone.area["npcs"]:
		if npc["id"] == "pim_core":
			pim = npc
	game._turn_in(pim, "the_iron_legacy")
	assert_eq(game.menu_name, "epilogue", "the epilogue plays")
	var lines: Array = _content().quests["the_iron_legacy"]["ends_chapter"]["epilogue"]
	var shown: Array[String] = []
	for label: Label in game.menu.find_children("*", "Label", true, false):
		shown.append(label.text)
	for line: String in lines:
		assert_true(line in shown, "says: %s" % line.left(30))
	game.close_menu()
	assert_eq(game.menu_name, "", "and the streets go on")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
