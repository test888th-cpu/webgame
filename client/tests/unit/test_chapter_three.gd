extends TestCase
## Chapter 3, the Industrial District: four areas past the Crane Yard, Dr. Pim's
## quest chain, Security Chief Nattapong mid-chapter and Unit K-7 at the end,
## whose floor vents burst with steam (the hazard system, kind "steam").

const PLANT := ["factory_gate", "production_line", "waste_pools", "factory_drains"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_the_industrial_district_follows_the_port() -> void:
	var street := StreetMemory.street(_content())
	var at := street.find("crane_yard")
	for i in PLANT.size():
		assert_eq(street[at + 1 + i], PLANT[i], "%s in order" % PLANT[i])
	var gate: Dictionary = _content().area("crane_yard")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "harbourmaster_chen", "the plant opens once Chen is down")
	var levels: Array[int] = []
	for area_id: String in PLANT:
		levels.append(int(_content().area(area_id)["level"]))
	assert_eq(levels, [19, 21, 23, 24] as Array[int], "levels rise through the chapter")


func test_dr_pim_leads_to_the_core() -> void:
	var first: Dictionary = _content().quests["factory_doors"]
	assert_eq(str(first["giver"]), "dr_pim", "Dr. Pim gives the chapter")
	assert_eq(str(first["requires"]), "harbourmaster", "after Chapter 2")
	var last: Dictionary = _content().quests["unit_k7"]
	assert_true(last.has("ends_chapter"), "K-7 ends Chapter 3")
	assert_true(int(last["rewards"]["items"].get("experiment_log", 0)) == 1, "the log")
	assert_true(
		str(_content().item("experiment_log")["description"]).contains("The Core"),
		"where The Core is named for the first time"
	)
	assert_eq(str(_content().item("waste_sample").get("type")), "key", "the sample is evidence")


func test_the_chief_blocks_the_waste_pools() -> void:
	var gate: Dictionary = _content().area("production_line")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "security_chief", "Nattapong holds the way")
	var chief := _content().enemy("security_chief")
	assert_true(bool(chief.get("boss", false)), "a mid-chapter boss")
	assert_true(not chief.has("hazard"), "with no hazard of his own")


func test_k7_vents_burst_with_steam_on_the_hero() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "factory_drains", "", 9)
	var events: Array[ZoneEvent] = []
	zone._start_encounter(1, events)
	zone._waves_left.clear()
	for i in 240:
		zone.tick(FighterInput.new())
		if zone.boss_id != 0:
			break
	var k7 := zone.fighter(zone.boss_id)
	assert_eq(k7.kind, "unit_k7", "K-7 is out")
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	var hazard: Dictionary = _content().enemy("unit_k7")["hazard"]
	var kinds: Array[String] = []
	for tick in int(hazard["every"]) + int(hazard["warn"]) + 10:
		(zone.brains[zone.boss_id] as EnemyBrain).cooldown = 100000
		k7.position = Vector2(1500, 280)
		zone.hero.position = Vector2(1000, 300)
		for event in zone.tick(FighterInput.new()):
			if event.type in ["hazard_warn", "hazard_hit"]:
				kinds.append(str(event.data["kind"]))
	assert_eq(kinds, ["steam", "steam"] as Array[String], "a steam vent warns, then bursts")
	assert_true(zone.hero.hp < zone.hero.max_hp, "and scalds a hero who stays on it")


func test_hazard_kinds_are_checked_on_load() -> void:
	var db := ContentDB.load_all()
	db.errors.clear()
	var bad: Dictionary = db.enemies["unit_k7"].duplicate(true)
	bad["hazard"]["kind"] = "lava"
	db._validate_enemy("unit_k7", bad)
	assert_true(not db.errors.is_empty(), "an unknown hazard kind is an error")
