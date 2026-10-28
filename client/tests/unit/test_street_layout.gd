extends TestCase
## Where street furniture stands: lamp posts, poles, bins and cones on the
## sidewalk out of the fighters' lane; crates, drums and parked vehicles at the
## kerb, never in the middle of the road; and parked vehicles are solid.

## Furniture at the kerb stands no further into the road than this.
const KERB_DEPTH := 14.0
## Light and small furniture never stands on the road.
const SIDEWALK_ONLY := ["street_lamp", "power_pole", "trash_bin", "traffic_cone"]
const VEHICLES := ["taxi", "tuk_tuk", "songthaew", "pickup_truck", "car_wreck", "motorbike"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _walk(zone: ZoneSim, dir: Vector2, ticks: int) -> void:
	var input := FighterInput.new()
	input.move = dir
	for i in ticks:
		zone.tick(input)


func test_furniture_stands_on_the_sidewalk_or_at_the_kerb() -> void:
	for area_id: String in _content().areas:
		for obstacle: Dictionary in _content().area(area_id).get("obstacles", []):
			var kind := str(obstacle["kind"])
			var y := float(obstacle["y"])
			if kind in SIDEWALK_ONLY:
				assert_true(y < ZoneSim.LANE_TOP, "%s %s on the sidewalk" % [area_id, kind])
			else:
				assert_true(
					y >= ZoneSim.LANE_TOP and y <= ZoneSim.LANE_TOP + KERB_DEPTH,
					"%s %s at the kerb, not mid-road (y %s)" % [area_id, kind, y]
				)


func test_the_sidewalk_is_out_of_the_lane() -> void:
	assert_true(Scenery.ROAD_TOP < ZoneSim.LANE_TOP, "the kerb is above the fighters' lane")
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "saltmarket", "", 3)
	zone.hero.position = Vector2(300, 280)
	_walk(zone, Vector2.UP, 90)
	assert_true(zone.hero.position.y >= ZoneSim.LANE_TOP, "the hero stays on the road")


func test_every_street_has_parked_vehicles_that_block() -> void:
	var parked := 0
	for area_id: String in _content().areas:
		for obstacle: Dictionary in _content().area(area_id).get("obstacles", []):
			if str(obstacle["kind"]) in VEHICLES:
				parked += 1
	assert_true(parked >= 8, "vehicles are parked along the streets (%d)" % parked)
	for kind: String in VEHICLES:
		assert_true(_content().obstacles.has(kind), "%s is street furniture" % kind)


func test_the_hero_cannot_walk_through_a_parked_taxi() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 3)
	var taxi := _find(zone, "taxi")
	assert_true(not taxi.is_empty(), "depot yard has a taxi")
	var at: Vector2 = taxi["position"]
	var half: Vector2 = taxi["half"]
	zone.hero.position = Vector2(at.x - half.x - 30.0, at.y)
	_walk(zone, Vector2.RIGHT, 120)
	assert_true(
		zone.hero.position.x < at.x - half.x, "stopped at the taxi (%s)" % zone.hero.position
	)
	# Nobody squeezes between a parked vehicle and the kerb.
	zone.hero.position = Vector2(at.x - half.x - 30.0, ZoneSim.LANE_TOP)
	_walk(zone, Vector2.RIGHT, 120)
	assert_true(zone.hero.position.x < at.x - half.x, "no gap behind the taxi")


func test_an_enemy_goes_round_a_parked_vehicle_to_reach_the_hero() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "depot_yard", "", 3)
	var taxi := _find(zone, "taxi")
	var at: Vector2 = taxi["position"]
	var half: Vector2 = taxi["half"]
	zone.hero.position = Vector2(at.x - half.x - 40.0, at.y)
	var enemy := zone.spawn_enemy("smogling", Vector2(at.x + half.x + 40.0, at.y))
	var reached := false
	for i in 600:
		zone.tick(FighterInput.new())
		if enemy.position.x < at.x - half.x:
			reached = true
			break
	assert_true(reached, "came round the taxi (%s)" % enemy.position)


func _find(zone: ZoneSim, kind: String) -> Dictionary:
	for solid: Dictionary in zone.solids:
		if solid["kind"] == kind:
			return solid
	return {}


func test_every_street_weapon_can_be_picked_up() -> void:
	# Weapons are scattered at random: over many rolls in every area, each one
	# lies where the hero can stand on it and pick it up, and from nowhere the
	# hero can pick it up is an NPC in talk reach (E talks before it picks up:
	# a pipe by the taxi driver once opened the taxi instead).
	var content := ContentDB.load_all()
	var profile := PlayerProfile.new_game(content)
	var checked := 0
	for area_id: String in content.areas:
		if content.area(area_id).get("weapons", {}).is_empty():
			continue
		for seed in range(1, 121):
			var zone := ZoneSim.new(content, profile, area_id, "", seed)
			for i in zone.ground_weapons.size():
				var at: Vector2 = zone.ground_weapons[i]["position"]
				var where := "%s seed %d: the weapon at %s" % [area_id, seed, at]
				checked += 1
				assert_true(Bodies.is_clear(at, zone.solids, zone.bounds), where + " has room")
				assert_eq(zone.weapon_in_reach(at), i, where + " is reached from on top")
				assert_eq(_talker_near(zone, at), "", where + " is not by an NPC")
	assert_true(checked > 500, "many weapons checked (%d)" % checked)


## An NPC in talk reach of any spot within pickup reach of `at`, or "".
func _talker_near(zone: ZoneSim, at: Vector2) -> String:
	for npc: Dictionary in zone.area.get("npcs", []):
		var offset := (Vector2(npc["x"], npc["y"]) - at).abs()
		var reach := ZoneSim.TALK_REACH + ZoneSim.WEAPON_REACH
		if offset.x <= reach.x and offset.y <= reach.y:
			return str(npc["id"])
	return ""
