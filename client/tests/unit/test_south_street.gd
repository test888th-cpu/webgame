extends TestCase
## South Street as a whole: one street from the yard to the refinery, levels
## rising eastwards, every gate winnable in its own area, every quest target
## somewhere to be found; and the Bottle Thrower fights at range.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _enemies_in(area_id: String) -> Array:
	var waves := JSON.stringify(_content().areas[area_id].get("encounters", []))
	var found := []
	for enemy_id: String in _content().enemies:
		if waves.contains('"%s"' % enemy_id):
			found.append(enemy_id)
	return found


func test_one_street_east_with_rising_levels() -> void:
	var seen := [_content().start_area]
	var here := _content().start_area
	while _content().areas[here]["exits"].has("east"):
		var exit: Dictionary = _content().areas[here]["exits"]["east"]
		var next := str(exit["to"])
		assert_true(next not in seen, "no loops at %s" % next)
		assert_eq(
			_content().areas[next]["exits"]["west"]["to"],
			here,
			"%s leads back to %s" % [next, here]
		)
		assert_true(
			int(_content().areas[next]["level"]) >= int(_content().areas[here]["level"]),
			"%s is no easier than %s" % [next, here]
		)
		seen.append(next)
		here = next
	var street_areas := _content().areas.keys().filter(
		func(id: String) -> bool: return not _content().area(id).get("world_boss", false)
	)
	assert_eq(seen.size(), street_areas.size(), "every area but the world boss's is on the street")


func test_every_gate_can_be_opened_where_it_stands() -> void:
	for area_id: String in _content().areas:
		var east: Dictionary = _content().areas[area_id]["exits"].get("east", {})
		if east.has("requires"):
			var guard := str(east["requires"]["defeat"])
			assert_true(guard in _enemies_in(area_id), "%s fights in %s" % [guard, area_id])


func test_every_quest_target_fights_somewhere() -> void:
	for quest_id: String in _content().quests:
		var target := str(_content().quests[quest_id]["objective"]["enemy"])
		if target == "any":
			continue
		var found := false
		for area_id: String in _content().areas:
			found = found or target in _enemies_in(area_id)
		assert_true(found, "%s's target %s can be found" % [quest_id, target])


func test_the_bottle_thrower_hangs_back_and_lobs() -> void:
	var profile := PlayerProfile.new_game(_content())
	var zone := ZoneSim.new(_content(), profile, "rusted_corner", "", 4)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone._encounters.clear()
	zone.hero.position = Vector2(600, 300)
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	var thrower := zone.spawn_enemy("street_thrower", Vector2(640, 290))
	var lobs := 0
	var floored := false
	var landed := 0
	for i in 900:
		for event in zone.tick(FighterInput.new()):
			if event.type == "weapon_throw" and event.data["id"] == thrower.id:
				lobs += 1
			if event.type == "hit" and event.hit.attacker_id == thrower.id:
				landed += 1
				floored = floored or event.hit.knocked_down
	assert_true(lobs >= 3, "lobbed %d bottles" % lobs)
	assert_true(landed > 0, "and they land")
	assert_true(not floored, "bottles stun, they do not floor")
	var gap := absf(thrower.position.x - zone.hero.position.x)
	assert_true(gap >= 70.0, "keeps its distance (%d px)" % gap)
	for entry in zone.ground_weapons:
		assert_true(entry["uses"] > 0, "lobbed bottles shatter instead of piling up")


func test_ranged_enemies_are_valid_data() -> void:
	assert_true(_content().is_valid(), ", ".join(_content().errors))
	assert_true(_content().enemies["street_thrower"].has("ranged"), "the thrower is ranged")


func test_clearing_a_fight_points_the_way_on() -> void:
	SaveStore.root = "user://test_street_save"
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var event := ZoneEvent.make("encounter_clear")
	game._handle(event)
	var go: Label = game.find_child("Go", true, false)
	assert_true(go != null and go.visible, "GO >> shows after a cleared fight")
	game._handle(ZoneEvent.make("encounter_start", {"arena": [0, 400], "boss": false}))
	assert_true(not go.visible, "and hides when the next one starts")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
