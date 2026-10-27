extends TestCase
## Chapter 4, The Black Network: four areas past the Factory Drains, Kenji's
## quest chain along the money trail, the Ringmaster mid-chapter and Big Sak
## at the end, who whistles in his runners (BossMechanics "summon").

const NETWORK := ["warehouse_row", "underground_ring", "counting_house", "sak_tower"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Rattanachai Tower with the hero and Big Sak alone, the fight on, his blows
## held back so only his whistle acts.
func _sak_fight() -> ZoneSim:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "sak_tower", "", 3)
	var events: Array[ZoneEvent] = []
	zone._start_encounter(1, events)
	zone._waves_left.clear()
	for i in 240:
		zone.tick(FighterInput.new())
		if zone.boss_id != 0:
			break
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	return zone


func _hold_all(zone: ZoneSim) -> void:
	for id: int in zone.brains:
		(zone.brains[id] as EnemyBrain).cooldown = 100000


func _runners(zone: ZoneSim) -> int:
	var count := 0
	for enemy in zone.enemies():
		count += 1 if enemy.kind == "network_runner" and not enemy.is_ko() else 0
	return count


func test_the_network_follows_the_factory_drains() -> void:
	var street := StreetMemory.street(_content())
	var at := street.find("factory_drains")
	for i in NETWORK.size():
		assert_eq(street[at + 1 + i], NETWORK[i], "%s in order" % NETWORK[i])
	var gate: Dictionary = _content().area("factory_drains")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "unit_k7", "Warehouse Row opens once K-7 is down")
	var levels: Array[int] = []
	for area_id: String in NETWORK:
		levels.append(int(_content().area(area_id)["level"]))
	assert_eq(levels, [26, 27, 29, 31] as Array[int], "levels rise through the chapter")


func test_kenji_follows_the_money_to_the_core_facility() -> void:
	var first: Dictionary = _content().quests["follow_the_money"]
	assert_eq(str(first["giver"]), "kenji_network", "Kenji gives the chapter")
	assert_eq(str(first["requires"]), "unit_k7", "after Chapter 3")
	var books: Dictionary = _content().quests["cooked_books"]
	assert_true(int(books["rewards"]["items"].get("money_trail", 0)) == 1, "the money trail")
	var trail := str(_content().item("money_trail")["description"])
	assert_true(trail.contains("Director Wiroj"), "the slips name the Director")
	var last: Dictionary = _content().quests["big_sak"]
	assert_true(last.has("ends_chapter"), "Big Sak ends Chapter 4")
	assert_true(int(last["rewards"]["items"].get("facility_pass", 0)) == 1, "his pass")
	for item_id: String in ["money_trail", "facility_pass"]:
		assert_eq(str(_content().item(item_id)["type"]), "key", "%s is evidence" % item_id)


func test_the_director_is_not_named_before_chapter_four() -> void:
	# Story bible §4: the money trail first ties Big Sak to Director Wiroj.
	var early := [
		"Prologue",
		"Chapter 1: South Street",
		"Chapter 2: Port District",
		"Chapter 3: Industrial District",
	]
	for quest_id: String in _content().quests:
		var quest: Dictionary = _content().quests[quest_id]
		if str(quest.get("chapter", "")) in early:
			for item_id: String in quest["rewards"].get("items", {}):
				var text := str(_content().item(item_id).get("description", ""))
				assert_true(not text.contains("Wiroj"), "%s does not name him" % item_id)
			assert_true(not JSON.stringify(quest).contains("Wiroj"), "%s neither" % quest_id)


func test_the_ringmaster_bars_the_way_up() -> void:
	var gate: Dictionary = _content().area("underground_ring")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "ringmaster", "the Ringmaster holds the stairs")
	assert_true(bool(_content().enemy("ringmaster").get("boss", false)), "a mid-chapter boss")


func test_big_sak_whistles_in_his_runners() -> void:
	var zone := _sak_fight()
	assert_eq(zone.fighter(zone.boss_id).kind, "big_sak", "Big Sak is out")
	var summon: Dictionary = _content().enemy("big_sak")["summon"]
	var called := 0
	for tick in int(summon["every"]) + 2:
		_hold_all(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "boss_summon":
				called += event.data["ids"].size()
	assert_eq(called, int(summon["count"]), "a whistle brings his runners")
	assert_eq(_runners(zone), int(summon["count"]), "and there they stand")
	for tick in int(summon["every"]) * 3:
		_hold_all(zone)
		zone.tick(FighterInput.new())
	assert_eq(_runners(zone), int(summon["max"]), "never more than his limit at once")


func test_the_whistle_comes_faster_when_enraged_and_stops_when_he_falls() -> void:
	var data: Dictionary = _content().enemy("big_sak")
	var phase: Dictionary = data["phases"][0]
	assert_true(int(phase["summon_every"]) < int(data["summon"]["every"]), "faster in phase 2")
	var zone := _sak_fight()
	var sak := zone.fighter(zone.boss_id)
	sak.hp = 0
	sak.enter(Fighter.State.KO)
	for tick in int(data["summon"]["every"]) * 2:
		_hold_all(zone)
		for event in zone.tick(FighterInput.new()):
			assert_true(event.type != "boss_summon", "no whistle once he is down")


func test_only_bosses_whistle_for_help() -> void:
	var db := ContentDB.load_all()
	db.errors.clear()
	var bad: Dictionary = db.enemies["network_enforcer"].duplicate(true)
	bad["summon"] = {"enemy": "network_runner", "every": 100, "count": 1, "max": 1}
	db._validate_enemy("network_enforcer", bad)
	assert_true(not db.errors.is_empty(), "a summon on a plain enemy is an error")
	db.errors.clear()
	var unknown: Dictionary = db.enemies["big_sak"].duplicate(true)
	unknown["summon"]["enemy"] = "nobody"
	db._validate_enemy("big_sak", unknown)
	assert_true(not db.errors.is_empty(), "so is calling an enemy that does not exist")
