extends TestCase
## Solid bodies: fighters, NPCs and street furniture cannot walk through each
## other; you have to go around.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A level 1 street with only what the test puts there.
func _street() -> ZoneSim:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "saltmarket", "", 3)
	zone.solids.clear()
	zone.ground_weapons.clear()
	zone.hero.position = Vector2(300, 300)
	return zone


func _post(zone: ZoneSim, at: Vector2) -> void:
	zone.solids.append({"position": at, "half": Vector2(5, 3), "kind": "power_pole"})


func _walk(zone: ZoneSim, dir: Vector2, ticks: int) -> void:
	var input := FighterInput.new()
	input.move = dir
	for i in ticks:
		zone.tick(input)


func test_a_post_stops_the_hero() -> void:
	var zone := _street()
	_post(zone, Vector2(340, 300))
	_walk(zone, Vector2.RIGHT, 60)
	var gap := Bodies.separation(
		zone.hero.position, Bodies.PERSON, Vector2(340, 300), Vector2(5, 3)
	)
	assert_true(gap >= 0.99, "never inside the post (%s)" % zone.hero.position)
	assert_true(zone.hero.position.x < 340.0, "still on this side")


func test_walking_around_gets_past() -> void:
	var zone := _street()
	_post(zone, Vector2(340, 300))
	_walk(zone, Vector2.RIGHT, 30)
	_walk(zone, Vector2.DOWN, 20)
	_walk(zone, Vector2.RIGHT, 40)
	assert_true(zone.hero.position.x > 360.0, "past the post after stepping round it")


func test_walking_at_an_angle_slides_along() -> void:
	var zone := _street()
	_post(zone, Vector2(320, 300))
	_walk(zone, Vector2.RIGHT, 20)
	var x := zone.hero.position.x
	_walk(zone, Vector2(1, 1).normalized(), 10)
	assert_true(zone.hero.position.y > 300.0, "slid down the lane")
	assert_true(zone.hero.position.x >= x, "not pushed back")


func test_fighters_bump_into_each_other() -> void:
	var zone := _street()
	var enemy := zone.spawn_enemy("training_dummy", Vector2(340, 300))
	_walk(zone, Vector2.RIGHT, 60)
	assert_true(
		Bodies.separation(zone.hero.position, Bodies.PERSON, enemy.position, Bodies.PERSON) >= 0.99,
		"the hero does not walk into the dummy"
	)
	assert_true(zone.hero.position.x < enemy.position.x, "and not through it")
	# Close enough to hit it all the same.
	assert_true(
		enemy.position.x - zone.hero.position.x < float(_content().moves.get_move("jab").reach),
		"within a jab"
	)


func test_npcs_are_solid() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 3)
	var npc: Dictionary = zone.area["npcs"][0]
	zone.hero.position = Vector2(float(npc["x"]) - 40.0, float(npc["y"]))
	_walk(zone, Vector2.RIGHT, 60)
	assert_true(zone.hero.position.x < float(npc["x"]), "stops at %s" % npc["id"])


func test_an_enemy_walks_around_a_crate_to_reach_the_hero() -> void:
	var zone := _street()
	zone.solids.append({"position": Vector2(400, 300), "half": Vector2(14, 6), "kind": "crates"})
	var enemy := zone.spawn_enemy("smogling", Vector2(460, 300))
	zone.hero.position = Vector2(330, 300)
	for i in 400:
		zone.tick(FighterInput.new())
		if enemy.position.x < 380.0:
			break
	assert_true(enemy.position.x < 380.0, "came round the crate (%s)" % enemy.position)


func test_knocked_down_bodies_do_not_block() -> void:
	var zone := _street()
	var enemy := zone.spawn_enemy("training_dummy", Vector2(330, 300))
	enemy.enter(Fighter.State.DOWN, 600)
	_walk(zone, Vector2.RIGHT, 40)
	assert_true(zone.hero.position.x > 330.0, "stepped over the fallen")


func test_streets_place_their_furniture_sensibly() -> void:
	for area_id: String in _content().areas:
		var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), area_id, "", 5)
		var area: Dictionary = zone.area
		assert_true(not area.get("obstacles", []).is_empty(), "%s has street furniture" % area_id)
		for solid: Dictionary in zone.solids:
			var at: Vector2 = solid["position"]
			if solid["kind"] == "npc":
				continue
			assert_true(
				at.x > 120.0 and at.x < float(area["width"]) - 60.0,
				"%s %s clear of the exits" % [area_id, solid["kind"]]
			)
			for entry: Dictionary in zone.ground_weapons:
				assert_true(
					Bodies.separation(entry["position"], Bodies.PERSON, at, solid["half"]) >= 1.0,
					"%s weapon not inside %s" % [area_id, solid["kind"]]
				)
		for entry in [
			ZoneSim.new(_content(), PlayerProfile.new_game(_content()), area_id, "west", 1),
			ZoneSim.new(_content(), PlayerProfile.new_game(_content()), area_id, "east", 1)
		]:
			assert_true(
				Bodies.can_step(
					entry.hero.position, entry.hero.position, Bodies.PERSON, entry.solids
				),
				"%s arrival spot is free" % area_id
			)
