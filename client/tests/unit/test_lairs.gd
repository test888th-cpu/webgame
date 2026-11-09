extends TestCase
## Boss lairs (areas.json "kind": "lair", AreaRules.LAIR): a short arena off
## the street with one boss fight, opened by the same unlock rules as a
## farming ground, reached by the field truck from the city and left west to
## it. The fight walls the hero in, and comes back after every rest, so a
## lair's boss can be farmed like a ground's field.

const FOOD := ["rice_box", "herbal_tonic"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A hero past the whole story at `level`, in shop gear, with food.
func _hero(level: int) -> PlayerProfile:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	for area_id in StreetMemory.street(c):
		StreetMemory.visit(profile, area_id)
	profile.level = level
	for item_id in ProgressionHarness.gear(c, level, "shop"):
		profile.add_item(item_id)
		profile.equip(item_id, c)
	for item_id: String in FOOD:
		profile.add_item(item_id, 20)
	return profile


func _boss(lair_id: String) -> String:
	for wave: Array in _content().area(lair_id)["encounters"][0]["waves"]:
		for kind: String in wave:
			if _content().enemy(kind).get("boss", false):
				return kind
	return ""


func test_each_lair_is_one_boss_fight_off_the_street() -> void:
	var c := _content()
	assert_eq(c.errors, PackedStringArray(), "the data validates")
	var lairs := AreaRules.lairs(c)
	assert_eq(lairs.size(), 5, "the spillway and the four rematches")
	for lair_id in lairs:
		var area := c.area(lair_id)
		assert_true(lair_id not in StreetMemory.street(c), lair_id + ": off the street")
		assert_eq(area["exits"], {"west": {"to": c.city_area, "entry": "west"}}, lair_id + ": exit")
		assert_true(not FarmSpawner.active(c, lair_id), lair_id + ": no living field")
		assert_eq(area["encounters"].size(), 1, lair_id + ": one fight")
		var boss := _boss(lair_id)
		assert_true(boss != "", lair_id + ": a boss in it")
		assert_true(c.enemy(boss).has("enrage"), lair_id + ": its boss has a fight timer")
		assert_true(str(area.get("purpose", "")) != "", lair_id + ": a purpose")
		var alloy := false
		for drop: Dictionary in c.enemy(boss)["loot"]["drops"]:
			alloy = alloy or (drop["item"] == "refined_alloy" and float(drop["chance"]) >= 1.0)
		assert_true(alloy, lair_id + ": its boss guarantees upgrade material")


func test_each_lair_opens_with_a_farming_ground() -> void:
	var c := _content()
	var ground_rules: Array = []
	for gid in AreaRules.farms(c):
		ground_rules.append(c.area(gid)["unlock"])
	for lair_id in AreaRules.lairs(c):
		assert_true(c.area(lair_id)["unlock"] in ground_rules, lair_id + ": opens with a ground")


func test_a_lair_opens_when_its_unlock_boss_falls() -> void:
	var c := _content()
	var profile := _hero(55)
	for lair_id in AreaRules.lairs(c):
		var boss := str(c.area(lair_id)["unlock"]["defeated"])
		profile.defeated.erase(boss)
		assert_true(not AreaRules.unlocked(profile, c, lair_id), lair_id + ": shut before")
		assert_true(lair_id not in AreaRules.open_lairs(profile, c), lair_id + ": not offered")
		assert_eq(
			AutoRules.problem(profile, c, lair_id), "This lair is not open yet.", "no auto there"
		)
		profile.defeated[boss] = 1
		assert_true(AreaRules.unlocked(profile, c, lair_id), lair_id + ": open after")
		assert_eq(AutoRules.problem(profile, c, lair_id), "", lair_id + ": auto may fight it")
		assert_eq(AreaRules.unlock_text(c, lair_id), "Defeat " + c.enemy(boss)["name"], "said")


func test_the_chain_follows_the_lairs_bosses() -> void:
	# Each 50-70 ground and lair opens when the lair before it falls, so the
	# rematches are fought in order of level.
	var c := _content()
	var by_level := AreaRules.lairs(c)
	by_level.sort_custom(
		func(a: String, b: String) -> bool: return c.area(a)["level"] < c.area(b)["level"]
	)
	for i in range(2, by_level.size()):
		var opener := str(c.area(by_level[i])["unlock"]["defeated"])
		assert_eq(opener, _boss(by_level[i - 1]), by_level[i] + ": opened by the lair before")


func test_the_fight_walls_in_pays_out_and_comes_back_after_a_rest() -> void:
	var c := _content()
	var lair_id := "spillway_gatehouse"
	var profile := _hero(int(c.area(lair_id)["level"]) + 2)
	profile.defeated["commander_arthit"] = 1
	var boss := _boss(lair_id)
	var zone := ZoneSim.new(c, profile, lair_id, "west", 7)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	var pilot := AutoPilot.new(c)
	var walled := false
	var won := false
	var xp := 0
	# Five minutes of auto battle at the lair's suggested level and a little.
	for tick in 18000:
		if zone.hero.is_ko():
			break
		var input := pilot.think(zone)
		if pilot.item:
			zone.use_item(pilot.item)
		for event in zone.tick(input):
			if event.type == "defeat":
				xp += int(event.data["xp"])
			won = won or event.type == "encounter_clear"
		walled = walled or zone.fight_locked()
		if won:
			break
	assert_true(walled, "the boss fight walls the hero in")
	assert_true(not zone.hero.is_ko(), "the hero lasts at the lair's level")
	assert_true(won, "and wins it")
	assert_true(int(profile.defeated.get(boss, 0)) > 0, "the boss is counted down")
	assert_true(xp > 0, "for XP")
	assert_true(StreetMemory.pending(profile, c, lair_id).is_empty(), "won until a rest")
	StreetMemory.rest(profile)
	assert_eq(StreetMemory.pending(profile, c, lair_id), [0] as Array[int], "back after a rest")


func test_the_validator_keeps_a_lair_to_one_boss_fight() -> void:
	var copy := ContentDB.load_all()
	var lair: Dictionary = copy.areas["spillway_gatehouse"]
	lair["spawning"] = copy.area("farm_core_spillway")["spawning"].duplicate(true)
	lair["encounters"] = [{"trigger_x": 420, "arena": [300, 1280], "waves": [["facility_trooper"]]}]
	copy.errors.clear()
	copy.validate()
	var said := "\n".join(copy.errors)
	assert_true("not a living field" in said, "no field in a lair")
	assert_true("one fight, with one boss in it" in said, "a boss in its fight")


func test_auto_battle_never_takes_the_hero_to_a_lair_or_a_ground() -> void:
	# Following the story (StoryAuto) only rides along the street; a lair or a
	# farming ground is entered only when the player rides there.
	var c := _content()
	var profile := _hero(70)
	for enemy_id: String in c.enemies:
		if c.enemy(enemy_id).get("boss", false):
			profile.defeated[enemy_id] = 1
	var street := StreetMemory.street(c)
	for area_id: String in c.areas:
		for cleared in [true, false]:
			var plan := StoryAuto.step(profile, c, area_id, cleared)
			if plan.has("to"):
				assert_true(
					str(plan["to"]) in street or str(plan["to"]) == area_id,
					"%s: the story rides along the street (%s)" % [area_id, plan["to"]]
				)
	for lair_id in AreaRules.lairs(c):
		assert_true(lair_id not in AreaRules.farms(c), lair_id + ": never a farming ground")
		assert_true(not FarmSpawner.active(c, lair_id), lair_id + ": no field for auto to hunt")
