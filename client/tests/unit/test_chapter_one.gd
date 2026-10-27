extends TestCase
## Chapter 1 runs the whole of South Street: the Parking Lot between the Rusted
## Corner and the Rail Yards, then past the Refinery down the Rat Nest to the
## Gang Headquarters, where the Furnace Baron closes the chapter. Each main
## quest leads to the area of the next, in order.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _street() -> Array[String]:
	var seen: Array[String] = [_content().start_area]
	var here := _content().start_area
	while _content().areas[here]["exits"].has("east"):
		here = str(_content().areas[here]["exits"]["east"]["to"])
		seen.append(here)
	return seen


func _fights_in(area_id: String, enemy_id: String) -> bool:
	return JSON.stringify(_content().areas[area_id]["encounters"]).contains('"%s"' % enemy_id)


func test_the_new_areas_stand_in_story_order() -> void:
	var street := _street()
	assert_eq(street.find("parking_lot"), street.find("rusted_corner") + 1, "after Rusted Corner")
	assert_eq(street.find("rail_yards"), street.find("parking_lot") + 1, "before Rail Yards")
	assert_eq(street.find("rat_nest"), street.find("refinery") + 1, "down from the Refinery")
	assert_eq(street[street.find("gang_hq") + 1], "port_road", "South Street ends at the Gang HQ")


func test_the_baron_closes_the_chapter_at_his_headquarters() -> void:
	assert_true(_fights_in("gang_hq", "furnace_baron"), "the Baron fights at his HQ")
	for area_id: String in _content().areas:
		if area_id != "gang_hq":
			assert_true(not _fights_in(area_id, "furnace_baron"), "only there (%s)" % area_id)
	var quest: Dictionary = _content().quests["furnace_baron"]
	assert_true(quest.has("ends_chapter"), "beating him ends Chapter 1")


func test_main_quests_follow_the_street() -> void:
	# Walking the quest chain from the first quest, each quest's target fights
	# no earlier on the street than the previous quest's.
	var street := _street()
	var quests := _content().quests
	var quest_id := ""
	for id: String in quests:
		if not quests[id].has("requires"):
			quest_id = id
	var last := 0
	var steps := 0
	while quest_id != "":
		var target := str(quests[quest_id]["objective"]["enemy"])
		var at := -1
		for i in street.size():
			if target == "any" or _fights_in(street[i], target):
				at = i if target != "any" else 1
				if at >= last:
					break
		assert_true(at >= last, "%s's target fights further along the street" % quest_id)
		last = at
		steps += 1
		var next := ""
		for id: String in quests:
			if str(quests[id].get("requires", "")) == quest_id:
				next = id
		quest_id = next
	assert_eq(steps, quests.size(), "one chain covers every main quest")


func test_new_areas_have_their_own_scenery() -> void:
	for area_id: String in ["parking_lot", "rat_nest", "gang_hq"]:
		var kit: Dictionary = _content().kit["areas"][area_id]
		assert_eq(kit["theme"], str(_content().areas[area_id]["kit_theme"]), area_id)
	var tunnel: Dictionary = _content().kit["areas"]["rat_nest"]
	assert_eq(tunnel["ground"]["road"], "tunnel_floor_tile", "the Rat Nest floor is the tunnel")
