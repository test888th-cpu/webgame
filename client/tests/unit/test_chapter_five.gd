extends TestCase
## Chapter 5, The Core Facility: four areas past Rattanachai Tower, Dr. Pim's
## quest chain, Subject 12 (a worker The Core changed) mid-chapter and
## Commander Arthit at the end, whose security lasers sweep a whole lane
## (hazard kind "laser") while he calls a trooper in.

const FACILITY := ["facility_gate", "test_labs", "machine_hall", "control_room"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## The Control Room with the hero and Arthit alone, the fight on, everyone's
## blows held back so only his lasers act.
func _arthit_fight() -> ZoneSim:
	var profile := PlayerProfile.new_game(_content())
	var zone := ZoneSim.new(_content(), profile, "control_room", "", 4)
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


## Ticks until Arthit's next laser warning, the hero kept at `at`.
func _until_laser(zone: ZoneSim, at: Vector2) -> Dictionary:
	var arthit := zone.fighter(zone.boss_id)
	for tick in 2000:
		_hold_all(zone)
		arthit.position = Vector2(1600, 330)
		zone.hero.position = at
		for event in zone.tick(FighterInput.new()):
			if event.type == "hazard_warn":
				return event.data
	return {}


func test_the_facility_follows_the_tower() -> void:
	var street := StreetMemory.street(_content())
	var at := street.find("sak_tower")
	for i in FACILITY.size():
		assert_eq(street[at + 1 + i], FACILITY[i], "%s in order" % FACILITY[i])
	var gate: Dictionary = _content().area("sak_tower")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "big_sak", "the facility opens once Big Sak is down")
	var levels: Array[int] = []
	for area_id: String in FACILITY:
		levels.append(int(_content().area(area_id)["level"]))
	assert_eq(levels, [33, 35, 37, 39] as Array[int], "levels rise through the chapter")


func test_dr_pim_leads_to_the_core_source() -> void:
	var first: Dictionary = _content().quests["facility_breach"]
	assert_eq(str(first["giver"]), "pim_facility", "Dr. Pim gives the chapter")
	assert_eq(str(first["requires"]), "big_sak", "after Chapter 4")
	var last: Dictionary = _content().quests["commander_arthit"]
	assert_true(last.has("ends_chapter"), "Arthit ends Chapter 5")
	assert_true(int(last["rewards"]["items"].get("core_source_data", 0)) == 1, "the source")
	for item_id: String in ["exposure_report", "core_source_data"]:
		assert_eq(str(_content().item(item_id)["type"]), "key", "%s is evidence" % item_id)


func test_the_hybrids_are_explained_where_they_appear() -> void:
	# Story bible §6: Hybrid Humanoids only with an in-game account of them.
	var report := str(_content().item("exposure_report")["description"])
	assert_true(report.contains("The Core") and report.contains("workers"), "the report says why")
	var quest: Dictionary = _content().quests["subject_twelve"]
	assert_true(str(quest["dialogue"]["offer"]).contains("workers"), "Dr. Pim says who they were")
	var reward: Dictionary = quest["rewards"]["items"]
	assert_true(int(reward.get("exposure_report", 0)) == 1, "handed over with Subject 12")
	var street := StreetMemory.street(_content())
	for area_id in street:
		var waves := JSON.stringify(_content().area(area_id).get("encounters", []))
		if waves.contains("hybrid_"):
			assert_true(
				street.find(area_id) >= street.find(FACILITY[0]),
				"%s: no hybrids before the facility" % area_id
			)


func test_a_laser_sweeps_the_whole_lane_at_the_hero_depth() -> void:
	var zone := _arthit_fight()
	assert_eq(zone.fighter(zone.boss_id).kind, "commander_arthit", "Arthit is out")
	var warn := _until_laser(zone, Vector2(1000, 300))
	assert_eq(str(warn.get("kind", "")), "laser", "a laser is called")
	assert_true((warn["half"] as Vector2).x >= 600.0, "wide as the street")
	var before := zone.hero.hp
	for tick in int(warn["ticks"]) + 2:
		_hold_all(zone)
		zone.hero.position = Vector2(600, 300)  # far along, same depth
		zone.tick(FighterInput.new())
	assert_true(zone.hero.hp < before, "walking along the street does not escape it")


func test_changing_lane_escapes_the_laser() -> void:
	var zone := _arthit_fight()
	var warn := _until_laser(zone, Vector2(1000, 300))
	var before := zone.hero.hp
	for tick in int(warn["ticks"]) + 2:
		_hold_all(zone)
		zone.hero.position = Vector2(1000, 300 + (warn["half"] as Vector2).y + 8.0)
		zone.tick(FighterInput.new())
	assert_eq(zone.hero.hp, before, "a step out of its lane is safe")


func test_the_pilot_changes_lane_out_of_a_laser() -> void:
	var zone := _arthit_fight()
	zone.hero.position = Vector2(1000, 300)
	zone.hazards.append({"at": Vector2(1000, 302), "ticks": 40, "half": Vector2(900, 9)})
	_hold_all(zone)
	var input := AutoPilot.new(_content()).think(zone)
	assert_true(absf(input.move.y) > 0.9 and absf(input.move.x) < 0.1, "up or down, not along")


func test_hazard_kinds_include_the_laser() -> void:
	var db := ContentDB.load_all()
	db.errors.clear()
	db._validate_enemy("commander_arthit", db.enemies["commander_arthit"])
	assert_true(db.errors.is_empty(), "a laser is a known hazard kind")
