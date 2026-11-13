extends TestCase
## The lairs' shared mini-boss (LairRules; the field truck's "Rematches"):
## ONE per lair across its ten blocks, out in a random eligible block at a
## random spot, there until beaten, its health kept between visits, its defeat
## resolved once with one wait for the next.

const LAIR := "spillway_gatehouse"
const NOW := 1_800_000_000
const TEST_SAVE := "user://test_rematch_spawns_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hero() -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content())
	profile.level = int(_content().area(LAIR)["level"])
	return profile


## The zone for block `block` of the lair, the hero arriving from the west.
func _zone(profile: PlayerProfile, block: int, seed := 3) -> ZoneSim:
	var zone := ZoneSim.new(_content(), profile, LAIR, "west", seed)
	zone.block = block
	return zone


static func _out_in(profile: PlayerProfile, c: ContentDB, lair: String, now: int) -> Array[int]:
	var out: Array[int] = []
	for block in range(1, BlockRules.count(c, lair) + 1):
		if LairRules.here(profile, c, lair, block, now):
			out.append(block)
	return out


func test_every_lair_has_ten_blocks_and_one_mini_boss() -> void:
	var c := _content()
	assert_eq(LairRules.problems(c), PackedStringArray(), "the shipped lairs")
	for lair_id in AreaRules.lairs(c):
		assert_eq(BlockRules.count(c, lair_id), 10, lair_id + ": ten blocks")
		assert_true(c.enemy(LairRules.boss(c, lair_id)).get("boss", false), lair_id + ": a boss")
		assert_eq(_out_in(_hero(), c, lair_id, NOW).size(), 1, lair_id + ": one out, not ten")
	var copy := ContentDB.load_all()
	copy.areas[LAIR]["blocks"] = 9
	assert_true("ten blocks" in "\n".join(LairRules.problems(copy)), "nine blocks are refused")


func test_looking_again_never_brings_out_a_second() -> void:
	var c := _content()
	var profile := _hero()
	var state := LairRules.observe(profile, c, LAIR, NOW)
	assert_eq(state["state"], LairRules.ACTIVE, "out at once the first time")
	for i in 20:
		var again := LairRules.observe(profile, c, LAIR, NOW + i * 600)
		assert_eq(again["encounter"], state["encounter"], "the same one (%d)" % i)
		assert_eq(again["block"], state["block"], "in the same block")
		assert_eq(Vector2(again["x"], again["y"]), Vector2(state["x"], state["y"]), "same spot")


func test_it_stays_until_beaten_however_long_and_whoever_leaves() -> void:
	var c := _content()
	var profile := _hero()
	var block: int = LairRules.observe(profile, c, LAIR, NOW)["block"]
	var zone := _zone(profile, block)
	assert_true(LairRules.arrive(zone, NOW) != null, "there when a hero walks in")
	LairRules.depart(zone)  # The hero walks off; nobody is near.
	var week := NOW + 7 * 86_400
	assert_eq(_out_in(profile, c, LAIR, week), [block], "a week on, still out, same block")
	var back := _zone(profile, block, 9)
	assert_true(LairRules.arrive(back, week) != null, "and there when a hero comes back")


func test_its_health_and_place_are_kept_between_visits() -> void:
	var c := _content()
	var profile := _hero()
	var block: int = LairRules.observe(profile, c, LAIR, NOW)["block"]
	var zone := _zone(profile, block)
	var boss := LairRules.arrive(zone, NOW)
	boss.hp = boss.max_hp / 3
	boss.position.x = 900.0
	LairRules.depart(zone)
	# A reconnect: the save is loaded again.
	var loaded := PlayerProfile.from_dict(profile.to_dict(), c)
	var other := _zone(loaded, block, 11)
	var same := LairRules.arrive(other, NOW + 60)
	assert_true(same != null, "the same mini-boss, not a new one")
	assert_eq(same.hp, boss.max_hp / 3, "as wounded as it was left")
	assert_true(absf(same.position.x - 900.0) < 40.0, "where it was left (%d)" % same.position.x)
	assert_eq(
		LairRules.observe(loaded, c, LAIR, NOW + 60)["encounter"],
		LairRules.observe(profile, c, LAIR, NOW)["encounter"],
		"one encounter, whoever loads it"
	)


func test_a_defeat_is_resolved_once_with_one_wait() -> void:
	var c := _content()
	var profile := _hero()
	LairRules.observe(profile, c, LAIR, NOW)
	var kind := LairRules.boss(c, LAIR)
	assert_true(LairRules.on_defeat(profile, c, LAIR, kind, NOW), "beaten")
	var next := LairRules.due(profile, LAIR)
	assert_eq(next, NOW + LairRules.respawn_seconds(c, LAIR), "the wait starts")
	assert_true(not LairRules.on_defeat(profile, c, LAIR, kind, NOW + 5), "not resolved twice")
	assert_eq(LairRules.due(profile, LAIR), next, "one wait, not a second")
	assert_eq(_out_in(profile, c, LAIR, next - 1), [], "none out during the wait")
	assert_eq(_out_in(profile, c, LAIR, next).size(), 1, "one out again when it ends")
	assert_eq(LairRules.observe(profile, c, LAIR, next)["encounter"], 2, "a new encounter")


func test_spawns_pick_random_blocks_and_spots_within_bounds() -> void:
	var c := _content()
	var width := float(c.area(LAIR)["width"])
	var blocks := {}
	var spots := {}
	var profile := _hero()
	var at := NOW
	for cycle in 40:
		var state := LairRules.observe(profile, c, LAIR, at)
		blocks[state["block"]] = true
		spots[roundi(state["x"])] = true
		assert_true(state["block"] >= 1 and state["block"] <= 10, "a block of the lair")
		var low := ZoneSim.EDGE_MARGIN + LairRules.SPAWN_MARGIN
		assert_true(state["x"] >= low and state["x"] <= width - low, "clear of the ends")
		var lane_end := ZoneSim.LANE_TOP + ZoneSim.LANE_DEPTH
		assert_true(state["y"] >= ZoneSim.LANE_TOP and state["y"] <= lane_end, "in the lane")
		LairRules.on_defeat(profile, c, LAIR, LairRules.boss(c, LAIR), at)
		at = LairRules.due(profile, LAIR)
	assert_true(blocks.size() >= 6, "many blocks over 40 spawns: %s" % [blocks.keys()])
	assert_true(spots.size() >= 30, "many spots: %d" % spots.size())


func test_only_eligible_blocks_are_used() -> void:
	var copy := ContentDB.load_all()
	copy.areas[LAIR]["mini_boss_blocks"] = [3, 7]
	var profile := PlayerProfile.new_game(copy)
	var at := NOW
	for cycle in 20:
		var block: int = LairRules.observe(profile, copy, LAIR, at)["block"]
		assert_true(block in [3, 7], "block %d is eligible" % block)
		LairRules.on_defeat(profile, copy, LAIR, LairRules.boss(copy, LAIR), at)
		at = LairRules.due(profile, LAIR)
	copy.areas[LAIR]["mini_boss_blocks"] = [11]
	assert_true("11 is not a block" in "\n".join(LairRules.problems(copy)), "out of range")


func test_it_never_turns_up_on_top_of_the_hero() -> void:
	var c := _content()
	var profile := _hero()
	var state := LairRules.observe(profile, c, LAIR, NOW)
	var zone := _zone(profile, state["block"])
	state["x"] = zone.hero.position.x + 10.0
	state["y"] = zone.hero.position.y
	profile.lairs[LAIR] = state
	var boss := LairRules.arrive(zone, NOW)
	var gap := absf(boss.position.x - zone.hero.position.x)
	assert_true(gap >= LairRules.HERO_CLEARANCE - 1.0, "set off from the hero (%d px)" % gap)


func test_a_version_12_save_keeps_its_wait() -> void:
	var c := _content()
	var data := _hero().to_dict()
	data["version"] = 12
	data["lairs"] = {LAIR: NOW + 900}
	var loaded := PlayerProfile.from_dict(data, c)
	assert_eq(LairRules.due(loaded, LAIR), NOW + 900, "the wait carried over")
	assert_eq(_out_in(loaded, c, LAIR, NOW), [], "none out before it ends")
	assert_eq(_out_in(loaded, c, LAIR, NOW + 900).size(), 1, "one after")
	assert_eq(int(loaded.to_dict()["version"]), PlayerProfile.SAVE_VERSION, "saved as current")


# Live: the mini-boss comes out while heroes are already in the lair
# (LairRules.watch, after every zone tick).


## A lair whose next mini-boss is due `wait` seconds after NOW.
func _waiting(wait: int) -> PlayerProfile:
	var profile := _hero()
	LairRules.observe(profile, _content(), LAIR, NOW)
	LairRules.on_defeat(profile, _content(), LAIR, LairRules.boss(_content(), LAIR), NOW - 1800)
	profile.lairs[LAIR]["next_at"] = NOW + wait
	return profile


## Ticks `zone` for `ticks` ticks through watch at time `now`; returns the events.
static func _watch(zone: ZoneSim, now: int, ticks: int) -> Array[ZoneEvent]:
	var all: Array[ZoneEvent] = []
	for _i in ticks:
		zone.hero.hp = zone.hero.max_hp
		all.append_array(LairRules.watch(zone, now, zone.tick(FighterInput.new())))
	return all


static func _count(zone: ZoneSim, kind: String) -> int:
	var n := 0
	for enemy in zone.enemies():
		n += 1 if enemy.kind == kind and not enemy.is_ko() else 0
	return n


func test_it_comes_out_into_the_block_a_hero_is_already_in() -> void:
	var c := _content()
	var profile := _waiting(10)
	var block := LairRules.block_of(c, LAIR, NOW + 10)
	var zone := _zone(profile, block)
	var kind := LairRules.boss(c, LAIR)
	assert_eq(LairRules.arrive(zone, NOW), null, "not out when the hero walks in")
	_watch(zone, NOW + 9, 60)
	assert_eq(_count(zone, kind), 0, "still waiting a second before")
	var events := _watch(zone, NOW + 10, 60)
	assert_eq(_count(zone, kind), 1, "out the moment it is due, with the hero still there")
	var spawned := 0
	for event in events:
		spawned += 1 if event.type == "spawn" and event.data["kind"] == kind else 0
	assert_eq(spawned, 1, "one spawn event for the view")
	_watch(zone, NOW + 600, 300)
	assert_eq(_count(zone, kind), 1, "never a second copy")
	var state: Dictionary = profile.lairs[LAIR]
	assert_eq(state["block"], block, "out in the picked block")


func test_a_hero_in_another_block_is_told_once() -> void:
	var c := _content()
	var profile := _waiting(10)
	var block := LairRules.block_of(c, LAIR, NOW + 10)
	var zone := _zone(profile, (block % 10) + 1)
	var told: Array[String] = []
	for event in _watch(zone, NOW + 10, 240):
		if event.type == "lair_status":
			told.append(str(event.data["text"]))
	assert_eq(told.size(), 1, "told once, not every look: %s" % [told])
	if told:
		assert_true(BlockRules.label(c, LAIR, block) in told[0], "where it is: " + told[0])
	assert_eq(_count(zone, LairRules.boss(c, LAIR)), 0, "and it is not in this block")


func test_its_health_is_recorded_while_fighting_and_survives_a_reload() -> void:
	var c := _content()
	var profile := _hero()
	var block: int = LairRules.observe(profile, c, LAIR, NOW)["block"]
	var zone := _zone(profile, block)
	var boss := LairRules.arrive(zone, NOW)
	boss.hp = boss.max_hp / 2
	_watch(zone, NOW, LairRules.WATCH_TICKS)
	var recorded: int = profile.lairs[LAIR]["hp"]
	assert_true(recorded > 0 and recorded <= boss.max_hp / 2, "recorded without leaving")
	assert_eq(profile.lairs[LAIR]["max_hp"], boss.max_hp, "and its full health")
	# The tab closes: the game's last save is all there is.
	var loaded := PlayerProfile.from_dict(profile.to_dict(), c)
	var again := LairRules.arrive(_zone(loaded, block, 12), NOW + 30)
	assert_eq(again.hp, recorded, "a reload finds it as wounded")
	var text := LairRules.status_text(loaded, c, LAIR, NOW + 30)
	assert_true("HP %d/%d" % [recorded, boss.max_hp] in text, "the truck shows it: " + text)


func test_a_defeat_in_play_is_resolved_once_and_survives_a_reload() -> void:
	var c := _content()
	var profile := _hero()
	var block: int = LairRules.observe(profile, c, LAIR, NOW)["block"]
	var zone := _zone(profile, block)
	var boss := LairRules.arrive(zone, NOW)
	var kind := boss.kind
	var defeat := ZoneEvent.make("defeat", {"id": boss.id, "kind": kind, "boss": true})
	var events: Array[ZoneEvent] = [defeat]
	LairRules.watch(zone, NOW, events)
	var next := LairRules.due(profile, LAIR)
	assert_eq(next, NOW + LairRules.respawn_seconds(c, LAIR), "one wait")
	assert_true(not LairRules.on_defeat(profile, c, LAIR, kind, NOW), "the game's own call: done")
	LairRules.watch(zone, NOW + 5, events)
	assert_eq(LairRules.due(profile, LAIR), next, "the same event twice: still one wait")
	var loaded := PlayerProfile.from_dict(profile.to_dict(), c)
	assert_eq(LairRules.due(loaded, LAIR), next, "the wait survives a reload")
	assert_eq(_out_in(loaded, c, LAIR, next - 1), [], "nothing back early after a reload")
	assert_eq(LairRules.observe(loaded, c, LAIR, next)["encounter"], 2, "then the next one")
	var text := LairRules.status_text(_waiting(600), c, LAIR, NOW)
	assert_true("back in 10m" in text, "the truck counts down: " + text)


func test_the_spawn_margin_is_configurable_and_checked() -> void:
	var copy := ContentDB.load_all()
	copy.areas[LAIR]["mini_boss_spawn_margin"] = 400
	var width := float(copy.area(LAIR)["width"])
	for cycle in 20:
		var spot := LairRules.spot_of(copy, LAIR, NOW + cycle * 1800)
		assert_true(spot.x >= 400.0 and spot.x <= width - 400.0, "clear by 400 (%d)" % spot.x)
	copy.areas[LAIR]["mini_boss_spawn_margin"] = width
	assert_true("mini_boss_spawn_margin" in "\n".join(LairRules.problems(copy)), "too wide")


func test_the_respawn_wait_is_the_lairs_own_setting() -> void:
	var c := _content()
	assert_eq(LairRules.respawn_seconds(c, LAIR), 1800, "the default: 30 minutes")
	for lair_id in AreaRules.lairs(c):
		assert_true(not c.area(lair_id).has("mini_boss_respawn_seconds"), lair_id + ": default")
	var copy := ContentDB.load_all()
	copy.areas[LAIR]["mini_boss_respawn_seconds"] = 600
	var profile := PlayerProfile.new_game(copy)
	LairRules.observe(profile, copy, LAIR, NOW)
	LairRules.on_defeat(profile, copy, LAIR, LairRules.boss(copy, LAIR), NOW)
	assert_eq(LairRules.due(profile, LAIR), NOW + 600, "a lair may set its own")
	assert_eq(_out_in(profile, copy, LAIR, NOW + 599), [], "never early")
	assert_eq(_out_in(profile, copy, LAIR, NOW + 600).size(), 1, "on time")
	copy.areas[LAIR]["mini_boss_respawn_seconds"] = 0
	assert_true("respawn_seconds" in "\n".join(LairRules.problems(copy)), "0 is refused")


func test_broken_lair_data_in_a_save_is_made_safe() -> void:
	var c := _content()
	var data := _hero().to_dict()
	for junk: Variant in [
		"junk",
		{LAIR: "junk"},
		{LAIR: {"state": 5, "hp": "x", "block": "seven", "next_at": -50}},
		{LAIR: {"state": "flying", "encounter": -3}},
		{"not_a_lair": {"state": "active"}},
	]:
		data["lairs"] = junk
		var loaded := PlayerProfile.from_dict(data, c)
		assert_true(loaded != null, "loads: %s" % [junk])
		assert_true(not loaded.lairs.has("not_a_lair"), "unknown areas dropped")
		var state := LairRules.clean(loaded.lairs.get(LAIR, {}))
		assert_true(state["state"] in LairRules.STATES, "a known state: %s" % [junk])
		assert_true(state["next_at"] >= 0 and state["encounter"] >= 0, "no negatives")
		assert_eq(_out_in(loaded, c, LAIR, NOW).size(), 1, "one mini-boss after: %s" % [junk])


## Migrating a version 12 save changes the lairs and nothing else: it loads
## exactly as the same data saved by this version does.
func test_a_version_12_save_keeps_everything_else() -> void:
	var c := _content()
	var hero := _hero()
	hero.money = 4321
	hero.add_item("taped_knuckles", 1)
	hero.defeated["sludge_foreman"] = 3
	hero.quests[str(c.quests.keys()[0])] = {"state": "turned_in", "progress": 1}
	StreetMemory.visit(hero, "canal_works")
	hero.world_boss["tunnel_mother"] = {"round": 9, "dealt": 50, "tiers": 0, "killed": false}
	var now_data := hero.to_dict()
	var old_data := now_data.duplicate(true)
	old_data["version"] = 12
	old_data["lairs"] = {LAIR: NOW + 900}
	var current := PlayerProfile.from_dict(now_data, c)
	var migrated := PlayerProfile.from_dict(old_data, c)
	var a := current.to_dict()
	var b := migrated.to_dict()
	for field: String in a:
		if field not in ["lairs", "saved_at"]:
			assert_eq(b[field], a[field], "%s kept" % field)
	assert_eq(migrated.money, 4321, "coins")
	assert_eq(migrated.defeated["sludge_foreman"], 3, "kills")
	assert_eq(int(migrated.world_boss["tunnel_mother"]["dealt"]), 50, "world boss damage")
	assert_eq(LairRules.due(migrated, LAIR), NOW + 900, "and the lair's wait")


# Scene: the game itself, a hero standing in the lair.


func test_in_the_game_it_appears_without_walking_out_and_its_health_is_saved() -> void:
	var game := _game()
	var c := game.content
	var kind := LairRules.boss(c, LAIR)
	game.profile.level = int(c.area(LAIR)["level"])
	game.now_override = NOW
	LairRules.observe(game.profile, c, LAIR, NOW)
	LairRules.on_defeat(game.profile, c, LAIR, kind, NOW - 1800)
	game.profile.lairs[LAIR]["next_at"] = NOW + 5
	var block := LairRules.block_of(c, LAIR, NOW + 5)
	game.enter_area(LAIR, "west", -1.0, block)
	assert_true(LairRules.present(game.zone) == null, "not out yet")
	game.now_override = NOW + 5
	for _i in 60:
		game.zone.hero.hp = game.zone.hero.max_hp
		game.step(FighterInput.new())
	var boss := LairRules.present(game.zone)
	assert_true(boss != null, "out, with the hero still in the block")
	if boss:
		boss.hp = boss.max_hp / 4
		for _i in LairRules.WATCH_TICKS:
			game.zone.hero.hp = game.zone.hero.max_hp
			game.step(FighterInput.new())
		game._save_game()  # As the autosave, a closed tab or the quit to title do.
		var saved := SaveStore.load_character(game.profile.id, c)
		var kept := int(saved.lairs[LAIR]["hp"])
		assert_true(kept > 0 and kept <= boss.max_hp / 4, "its wounds are in the save: %d" % kept)
	_done(game)


func test_the_field_truck_shows_the_mini_boss() -> void:
	var game := _game()
	var c := game.content
	game.now_override = NOW
	game.profile.money = 100
	for enemy_id: String in c.enemies:
		if c.enemy(enemy_id).get("boss", false):
			game.profile.defeated[enemy_id] = 1  # Every lair open.
	game.enter_area("main_city", "west")
	var truck := {}
	for npc: Dictionary in c.area("main_city")["npcs"]:
		if npc.get("routes") == "field":
			truck = npc
	LairRules.observe(game.profile, c, LAIR, NOW)
	# 1. Out, and nobody has met it yet: its block, "unhurt", no numbers.
	game._show("travel", GameMenus.travel(game, truck))
	var fresh := game.menu.find_child("Ride_" + LAIR, true, false) as Button
	assert_true(fresh != null and "unhurt" in fresh.text, "unhurt before anyone meets it")
	if fresh:
		assert_true("HP" not in fresh.text, "no made-up health: " + fresh.text)
		var at: int = game.profile.lairs[LAIR]["block"]
		assert_true(BlockRules.label(c, LAIR, at) in fresh.text, "its block: " + fresh.text)
	game.close_menu()
	# 2. Met and wounded: its block and HP.
	game.profile.lairs[LAIR]["hp"] = 1234
	game.profile.lairs[LAIR]["max_hp"] = 5000
	game._show("travel", GameMenus.travel(game, truck))
	var ride := game.menu.find_child("Ride_" + LAIR, true, false) as Button
	assert_true(ride != null, "a ride to the lair")
	if ride:
		var block: int = game.profile.lairs[LAIR]["block"]
		assert_true(BlockRules.label(c, LAIR, block) in ride.text, "its block: " + ride.text)
		assert_true("HP 1234/5000" in ride.text, "its health: " + ride.text)
	game.close_menu()
	# 3. Beaten: the wait, no stale health.
	LairRules.on_defeat(game.profile, c, LAIR, LairRules.boss(c, LAIR), NOW)
	game._show("travel", GameMenus.travel(game, truck))
	ride = game.menu.find_child("Ride_" + LAIR, true, false) as Button
	if ride:
		assert_true("back in 30m" in ride.text, "the wait, once beaten: " + ride.text)
		assert_true("HP" not in ride.text, "no stale health while it waits")
	_done(game)


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
