extends TestCase
## The story's quests come one per stage: taken at a rest point's quest
## giver, won by beating the stage's boss (the Reactor Walkway's sentinels
## for the last stage before the Director), handed in for coins, XP, the
## stage's own gear and its evidence. The last quest's prize is one of a
## kind, given once.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## The quests in the order the story hands them out.
func _chain() -> Array[String]:
	var order: Array[String] = []
	var next := ""
	for quest_id: String in _content().quests:
		if not _content().quests[quest_id].has("requires"):
			next = quest_id
	while next != "":
		order.append(next)
		var after := ""
		for quest_id: String in _content().quests:
			if str(_content().quests[quest_id].get("requires", "")) == next:
				after = quest_id
		next = after
	return order


func test_one_chain_one_quest_per_stage() -> void:
	var chain := _chain()
	assert_eq(chain.size(), _content().quests.size(), "every quest is on one chain")
	assert_eq(chain[0], "foreman", "it starts with the Sludge Foreman")
	assert_eq(chain[-1], "the_iron_legacy", "and ends with the Director")
	for quest_id in chain:
		var objective: Dictionary = _content().quests[quest_id]["objective"]
		var enemy := _content().enemy(str(objective["enemy"]))
		var stage_end: bool = enemy.get("boss", false) or quest_id == "the_walkway"
		assert_true(stage_end, "%s ends at its stage's boss (%s)" % [quest_id, objective["enemy"]])
		assert_true(objective["enemy"] != "any", quest_id + ": a named foe, not a head count")


func test_quests_are_given_at_the_storys_rest_points_only() -> void:
	var givers := {}
	for area_id in StreetMemory.street(_content()):
		for npc: Dictionary in _content().area(area_id).get("npcs", []):
			givers[npc["id"]] = area_id
	for quest_id: String in _content().quests:
		var giver := str(_content().quests[quest_id]["giver"])
		assert_true(givers.has(giver), "%s: %s stands on the story road" % [quest_id, giver])


func test_every_stage_pays_gear_and_the_last_one_a_unique_prize() -> void:
	var chain := _chain()
	for quest_id in chain:
		var items: Dictionary = _content().quests[quest_id]["rewards"]["items"]
		var gear := items.keys().filter(
			func(id: String) -> bool: return _content().item(id).get("type") == "equipment"
		)
		assert_true(not gear.is_empty(), quest_id + ": the stage's own gear")
	var prize := _content().item("heart_of_iron_city")
	assert_eq(prize.get("rarity"), "legendary", "the last prize is Legendary")
	assert_true(prize.get("unique", false), "and one of a kind")
	var last: Dictionary = _content().quests["the_iron_legacy"]["rewards"]["items"]
	assert_true(last.has("heart_of_iron_city"), "the last quest gives it")
	for quest_id in chain.slice(0, -1):
		var items: Dictionary = _content().quests[quest_id]["rewards"]["items"]
		assert_true(not items.has("heart_of_iron_city"), quest_id + ": not before")


func test_the_unique_prize_comes_from_the_last_quest_only() -> void:
	assert_eq(ItemRules.problems(_content()), PackedStringArray(), "the shipped data is clean")
	var dropped := ContentDB.load_all()
	dropped.enemies["director_wiroj"]["loot"]["drops"].append(
		{"item": "heart_of_iron_city", "chance": 0.01}
	)
	dropped.errors.clear()
	dropped.validate()
	var said := "\n".join(dropped.errors)
	assert_true("heart_of_iron_city: unique, yet enemies.director_wiroj" in said, "no drop")
	var lost := ContentDB.load_all()
	lost.quests["the_iron_legacy"]["rewards"]["items"].erase("heart_of_iron_city")
	lost.errors.clear()
	lost.validate()
	assert_true("unique, so a quest must give it" in "\n".join(lost.errors), "a quest gives it")


func test_handing_in_never_doubles_evidence_or_a_unique_prize() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	profile.add_item("torn_label")
	profile.quests["foreman"] = {"state": "complete", "progress": 1}
	QuestRules.turn_in(profile, "foreman", c)
	assert_eq(profile.count("torn_label"), 1, "evidence already held: not twice")
	assert_eq(profile.count("forged_note"), 1, "the new evidence is given")
	profile.add_item("heart_of_iron_city")
	profile.quests["the_iron_legacy"] = {"state": "complete", "progress": 1}
	QuestRules.turn_in(profile, "the_iron_legacy", c)
	assert_eq(profile.owned("heart_of_iron_city"), 1, "one of a kind stays one")


func test_the_story_xp_is_unchanged_and_the_hero_keeps_pace() -> void:
	var total := 0
	for quest_id: String in _content().quests:
		total += int(_content().quests[quest_id]["rewards"]["xp"])
	assert_eq(total, 136660, "the story's quest XP, as before the stages")


func test_a_save_from_before_the_stages_loads_its_stage_quests() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	var data := profile.to_dict()
	data["quests"] = {
		"foreman": {"state": "turned_in", "progress": 1},
		"glass_rain": {"state": "active", "progress": 3},
	}
	var loaded := PlayerProfile.from_dict(data, c)
	assert_eq(loaded.quests.keys(), ["foreman"], "a retired quest is dropped")
	assert_eq(QuestRules.status(loaded, "the_pit", c), "available", "the next stage is on offer")
	assert_eq(MapRules.goal(loaded, c)["text"], "New quest from Chief Odo", "and the map says so")
