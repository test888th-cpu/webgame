extends TestCase
## Blocks (BlockRules): every farming ground and lair is ten blocks of the
## same street, walked through east and west; its own exits are at either end.

const TEST_SAVE := "user://test_blocks_save"


func _content() -> ContentDB:
	return GameSession.content


func test_every_ground_and_lair_is_ten_blocks() -> void:
	var c := _content()
	for area_id in AreaRules.farms(c) + AreaRules.lairs(c):
		assert_eq(BlockRules.count(c, area_id), 10, area_id)
	assert_eq(BlockRules.count(c, "saltmarket"), 1, "a street is one block")
	assert_eq(BlockRules.count(c, c.city_area), 1, "and so is the city")


func test_the_blocks_lead_one_into_the_next_and_back() -> void:
	var c := _content()
	var gid := "farm_rail_sidings"
	var first := BlockRules.exits(c, gid, 1)
	assert_eq(first["east"], {"to": gid, "entry": "west", "block": 2}, "block 1 east: block 2")
	var west: Dictionary = first["west"]
	assert_eq(west["to"], c.area(gid)["exits"]["west"]["to"], "block 1 west: the ground's exit")
	assert_eq(west["block"], 10, "into the lower ground's last block, from its east")
	var middle := BlockRules.exits(c, gid, 5)
	assert_eq(middle["west"], {"to": gid, "entry": "east", "block": 4}, "block 5 west: 4")
	assert_eq(middle["east"], {"to": gid, "entry": "west", "block": 6}, "block 5 east: 6")
	assert_true(not BlockRules.exits(c, gid, 10).has("east"), "the last block: no way on")
	var street := BlockRules.exits(c, "saltmarket", 1)
	for side: String in c.area("saltmarket")["exits"]:
		var own: Dictionary = c.area("saltmarket")["exits"][side]
		assert_eq(street[side]["to"], own["to"], "a street keeps its own exit " + side)
		assert_eq(street[side]["block"], 1, "into a one-block area")


func test_walking_through_all_ten_blocks_and_back() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game("oren")
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var c := _content()
	var gid := "farm_saltmarket_backlots"
	game.enter_area(gid, "west")
	var seen: Array[int] = [game.zone.block]
	for side in [1, -1]:
		for i in 9:
			_walk_off(game, side)
			seen.append(game.zone.block)
			assert_eq(game.zone.area_id, gid, "still the same ground")
	assert_eq(seen, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1], "1 to 10 and back")
	_walk_off(game, -1)
	assert_eq(game.zone.area_id, c.city_area, "block 1 west: back to the city")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## Puts the hero at the edge on `side` (+1 east, -1 west) and pushes on.
func _walk_off(game: Node2D, side: int) -> void:
	var zone: ZoneSim = game.zone
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	var edge := zone.bounds.end.x if side > 0 else zone.bounds.position.x
	zone.hero.position = Vector2(edge, zone.hero.position.y)
	var push := FighterInput.new()
	push.move = Vector2(side, 0)
	for t in 3:
		game.step(push)
		if game.zone != zone:
			return
