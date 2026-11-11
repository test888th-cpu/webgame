extends TestCase
## Boss lairs (areas.json "kind": "lair", AreaRules.LAIR): ten blocks of
## camps off the street (BlockRules), opened by the same unlock rules as a
## farming ground, reached by the field truck from the city and left west to
## it. Their boss roams them as a mini-boss (LairRules): it turns up in one
## block at random, with no arena, and comes back 30 minutes after it falls.

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
	return LairRules.boss(_content(), lair_id)


func test_each_lair_is_ten_blocks_of_field_with_a_roaming_mini_boss() -> void:
	var c := _content()
	assert_eq(c.errors, PackedStringArray(), "the data validates")
	var lairs := AreaRules.lairs(c)
	assert_eq(lairs.size(), 5, "the spillway and the four rematches")
	for lair_id in lairs:
		var area := c.area(lair_id)
		assert_true(lair_id not in StreetMemory.street(c), lair_id + ": off the street")
		assert_eq(area["exits"], {"west": {"to": c.city_area, "entry": "west"}}, lair_id + ": exit")
		assert_true(FarmSpawner.active(c, lair_id), lair_id + ": a living field")
		assert_eq(area["encounters"].size(), 0, lair_id + ": no fixed fight")
		assert_eq(BlockRules.count(c, lair_id), 10, lair_id + ": ten blocks")
		var boss := _boss(lair_id)
		assert_true(c.enemy(boss).get("boss", false), lair_id + ": a boss roams it")
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


func test_the_mini_boss_turns_up_in_one_block_then_after_30_minutes() -> void:
	var c := _content()
	var lair_id := "spillway_gatehouse"
	var profile := _hero(int(c.area(lair_id)["level"]))
	var now := 1_800_000_000
	var out: Array[int] = []
	for block in range(1, 11):
		if LairRules.here(profile, c, lair_id, block, now):
			out.append(block)
	assert_eq(out.size(), 1, "out in exactly one block at first")
	var zone := ZoneSim.new(c, profile, lair_id, "west", 3)
	zone.block = out[0]
	var boss := LairRules.arrive(zone, now)
	assert_true(boss != null and boss.kind == _boss(lair_id), "there when the hero walks in")
	assert_true(boss.ungrabbable, "a mini-boss is never grabbed")
	var other := ZoneSim.new(c, profile, lair_id, "west", 3)
	other.block = (out[0] % 10) + 1
	assert_eq(LairRules.arrive(other, now), null, "and in no other block")
	assert_true(LairRules.on_defeat(profile, c, lair_id, _boss(lair_id), now), "beaten")
	for block in range(1, 11):
		assert_true(not LairRules.here(profile, c, lair_id, block, now + 1799), "gone a while")
	var back := 0
	for block in range(1, 11):
		back += 1 if LairRules.here(profile, c, lair_id, block, now + 1800) else 0
	assert_eq(back, 1, "back in one block 30 minutes on")
	assert_true(
		not LairRules.on_defeat(profile, c, lair_id, "facility_trooper", now), "not a trooper"
	)
	var saved := PlayerProfile.from_dict(profile.to_dict(), c)
	assert_eq(LairRules.due(saved, lair_id), now + 1800, "the wait is saved")


func test_a_lair_mini_boss_is_beaten_at_the_lair_level() -> void:
	var c := _content()
	var lair_id := "spillway_gatehouse"
	var profile := _hero(int(c.area(lair_id)["level"]) + 2)
	var zone := ZoneSim.new(c, profile, lair_id, "west", 7)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	var boss := zone.spawn_enemy(_boss(lair_id), zone.hero.position + Vector2(160, 0))
	var pilot := AutoPilot.new(c)
	var won := false
	for tick in 18000:
		if zone.hero.is_ko():
			break
		var input := pilot.think(zone)
		if pilot.item:
			zone.use_item(pilot.item)
		for event in zone.tick(input):
			won = won or (event.type == "defeat" and event.data["id"] == boss.id)
		if won:
			break
	assert_true(not zone.fight_locked(), "no arena walls the hero in")
	assert_true(not zone.hero.is_ko(), "the hero lasts at the lair's level")
	assert_true(won, "and beats the mini-boss")
	assert_true(int(profile.defeated.get(boss.kind, 0)) > 0, "counted down")


func test_the_validator_keeps_a_lair_a_field_with_a_mini_boss() -> void:
	var copy := ContentDB.load_all()
	var lair: Dictionary = copy.areas["spillway_gatehouse"]
	lair.erase("spawning")
	lair["encounters"] = [{"trigger_x": 420, "arena": [300, 1280], "waves": [["facility_trooper"]]}]
	lair["mini_boss"] = "facility_trooper"
	lair["blocks"] = 1
	copy.errors.clear()
	copy.validate()
	var said := "\n".join(copy.errors)
	assert_true("a lair is a living field" in said, "a field in a lair")
	assert_true(".encounters: none" in said, "no fixed fight")
	assert_true(".mini_boss: a boss enemy" in said, "a boss roams it")
	assert_true("a lair is several blocks" in said, "several blocks")


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
		assert_true(FarmSpawner.active(c, lair_id), lair_id + ": a field auto hunts once there")
