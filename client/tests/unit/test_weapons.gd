extends TestCase
## Street weapons: picking up, fighting with, dropping on knock-down, breaking.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A level 1 street with nothing lying around, so tests place what they need.
func _zone() -> ZoneSim:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 7)
	zone.ground_weapons.clear()
	return zone


func _press(field: String) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, true)
	return input


func _types(events: Array[ZoneEvent]) -> Array[String]:
	var types: Array[String] = []
	for event in events:
		types.append(event.type)
	return types


func test_every_weapon_is_complete() -> void:
	for id: String in _content().weapons:
		var weapon: Dictionary = _content().weapons[id]
		for button: String in weapon["moveset"]:
			assert_true(
				_content().moves.get_move(weapon["moveset"][button]) != null,
				"%s %s move exists" % [id, button]
			)
		assert_true(int(weapon["durability"]) >= 1, "%s lasts at least one blow" % id)


func test_the_hero_picks_up_the_weapon_underfoot() -> void:
	var zone := _zone()
	zone.place_weapon("knife", zone.hero.position + Vector2(6, 2), 14)
	var events := zone.tick(_press("pick"))
	assert_true("weapon_pickup" in _types(events), "pickup reported")
	assert_eq(zone.hero.weapon, "knife", "holding the knife")
	assert_eq(zone.ground_weapons.size(), 0, "gone from the street")
	assert_eq(
		CombatRules.starter(zone.hero, _content().moves, "light"),
		"knife_slash",
		"Z slashes with it"
	)


func test_nothing_in_reach_means_nothing_picked() -> void:
	var zone := _zone()
	zone.place_weapon("knife", zone.hero.position + Vector2(80, 0), 14)
	zone.tick(_press("pick"))
	assert_eq(zone.hero.weapon, "", "still bare-handed")
	assert_eq(zone.ground_weapons.size(), 1, "the knife stays put")


func test_pick_with_a_weapon_and_nothing_near_drops_it() -> void:
	var zone := _zone()
	zone.equip_weapon(zone.hero, "plank", 5)
	var events := zone.tick(_press("pick"))
	assert_true("weapon_drop" in _types(events), "drop reported")
	assert_eq(zone.hero.weapon, "", "hands empty")
	assert_eq(zone.ground_weapons[0]["uses"], 5, "keeps its wear on the street")


func test_a_knocked_down_fighter_drops_the_weapon() -> void:
	var zone := _zone()
	zone.equip_weapon(zone.hero, "chair", 4)
	var enemy := zone.spawn_enemy("smogling", zone.hero.position + Vector2(30, 0))
	zone.equip_weapon(enemy, "bottle", 2)
	zone.brains.erase(enemy.id)  # stand still and take it
	zone.hero.facing = 1
	var events := zone.tick(_press("light"))
	for i in 40:
		events.append_array(zone.tick(FighterInput.new()))
	assert_true("weapon_drop" in _types(events), "the bottle flew out of its hand")
	assert_eq(enemy.weapon, "", "enemy empty-handed")
	assert_eq(zone.ground_weapons.size(), 1, "the bottle lies on the street")
	assert_eq(zone.hero.weapon_uses, 3, "the chair took one blow of wear")


func test_a_weapon_breaks_when_used_up() -> void:
	var zone := _zone()
	zone.equip_weapon(zone.hero, "bottle", 1)
	var enemy := zone.spawn_enemy("smogling", zone.hero.position + Vector2(24, 0))
	zone.brains.erase(enemy.id)
	zone.hero.facing = 1
	var events := zone.tick(_press("light"))
	for i in 30:
		events.append_array(zone.tick(FighterInput.new()))
	assert_true("weapon_break" in _types(events), "it shattered")
	assert_eq(zone.hero.weapon, "", "nothing left in hand")
	assert_eq(zone.ground_weapons.size(), 0, "nothing left to pick up")


func test_streets_scatter_weapons_by_their_pool() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "rail_yards", "", 11)
	var spec: Dictionary = zone.area["weapons"]
	assert_true(zone.ground_weapons.size() >= int(spec["count"][0]), "enough weapons")
	assert_true(zone.ground_weapons.size() <= int(spec["count"][1]), "not too many")
	for entry in zone.ground_weapons:
		assert_true(spec["pool"].has(entry["weapon"]), "%s is in the pool" % entry["weapon"])
		assert_true(zone.bounds.grow(1.0).has_point(entry["position"]), "on the street")


func test_the_hero_view_draws_the_held_weapon() -> void:
	var zone := _zone()
	var root := Node2D.new()
	Engine.get_main_loop().root.add_child(root)
	var view := ZoneView.new()
	root.add_child(view)
	view.build(zone, _content())
	var hero_view := view.view_of(ZoneSim.HERO_ID)
	var held := hero_view.get_node_or_null("Weapon") as Sprite2D
	assert_true(held == null or not held.visible, "bare hands show nothing")
	zone.equip_weapon(zone.hero, "pipe", 10)
	view.sync()
	held = hero_view.get_node("Weapon") as Sprite2D
	assert_true(held.visible and held.texture != null, "the pipe is in hand")
	var knife := zone.place_weapon("knife", zone.hero.position + Vector2(200, 0), 14)
	view.sync()
	assert_true(
		view.find_child("Weapon%d" % knife["id"], true, false) != null,
		"the knife lies on the street"
	)
	root.queue_free()


func test_weapons_are_not_scattered_under_npcs() -> void:
	for seed in 30:
		var zone := ZoneSim.new(
			_content(), PlayerProfile.new_game(_content()), "depot_yard", "", seed
		)
		for entry in zone.ground_weapons:
			for npc: Dictionary in zone.area["npcs"]:
				assert_true(
					absf(entry["position"].x - float(npc["x"])) >= ZoneSim.NPC_CLEARANCE,
					"seed %d: weapon clear of %s" % [seed, npc["id"]]
				)


func test_leaving_an_area_leaves_the_weapon_behind() -> void:
	var zone := _zone()
	zone.equip_weapon(zone.hero, "pipe", 7)
	zone.hero.position.x = zone.bounds.end.x
	var walk := FighterInput.new()
	walk.move = Vector2.RIGHT
	var events := zone.tick(walk)
	assert_eq(_types(events), ["weapon_drop", "exit"], "dropped, then left")
	assert_eq(zone.hero.weapon, "", "nothing carried out")
	assert_eq(zone.ground_weapons.back()["uses"], 7, "the pipe stays, worn as it was")
	var again := _zone()
	again.restore_weapons(zone.ground_weapons)
	assert_eq(again.ground_weapons.back()["weapon"], "pipe", "still there on return")
	var fresh := again.place_weapon("knife", Vector2(300, 300), 14)
	assert_true(fresh["id"] > int(zone.ground_weapons.back()["id"]), "ids never repeat")
