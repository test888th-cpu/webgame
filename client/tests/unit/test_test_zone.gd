extends TestCase
## Instantiates the real zone scene and drives it tick by tick.


func _spawn_zone() -> Node2D:
	var zone: Node2D = load("res://scenes/world/TestZone.tscn").instantiate()
	tree.root.add_child(zone)  # runs _ready synchronously once the loop is live
	zone.set_physics_process(false)  # tests drive ticks explicitly
	return zone


func _input(move := Vector2.ZERO, button := "") -> FighterInput:
	var input := FighterInput.new()
	input.move = move
	if button:
		input.set(button, true)
	return input


func test_zone_has_fighters_camera_and_hud() -> void:
	var zone := _spawn_zone()
	assert_true(zone.library.is_valid(), "zone loaded valid moves")
	assert_eq(zone.fighters.size(), 2, "hero and dummy")
	var camera: Camera2D = zone.get_node("Entities/Hero/Camera")
	assert_eq(camera.limit_right, int(zone.ZONE_SIZE.x), "camera is bounded to the zone")
	assert_true(zone.has_node("Hud/Bars/HpFill"), "HUD has an HP bar")
	assert_eq(zone.get_node("Hud/Touch").get_child_count(), 8, "4 move + 4 combat buttons")
	zone.free()


func test_steps_move_the_hero_and_views_follow() -> void:
	var zone := _spawn_zone()
	var start: Vector2 = zone.hero.position
	for i in 10:
		zone.step(_input(Vector2.RIGHT))
	assert_true(zone.hero.position.x > start.x, "hero moved right")
	assert_eq(zone.hero_view.position, zone.hero.position, "view follows the simulation")
	zone.step(_input(Vector2.UP))
	assert_true(zone.hero.position.y < start.y, "hero moved into the lane")
	zone.free()


func test_hero_cannot_leave_the_street() -> void:
	var zone := _spawn_zone()
	for i in 600:
		zone.step(_input(Vector2(-1, 1)))
	assert_eq(zone.hero.position.x, zone.WALK_BOUNDS.position.x, "stops at the west edge")
	assert_eq(zone.hero.position.y, zone.WALK_BOUNDS.end.y, "stops at the kerb")
	zone.free()


func test_hero_can_hit_and_ko_the_dummy_which_respawns() -> void:
	var zone := _spawn_zone()
	var dummy: Fighter = zone.dummy
	zone.hero.position = dummy.position - Vector2(24, 0)
	var events: Array[CombatEvent] = []
	var ticks := 0
	while not dummy.is_ko() and ticks < 3000:
		var button := "heavy" if ticks % 40 == 0 else ""
		events.append_array(zone.step(_input(Vector2.ZERO, button)))
		zone.hero.position = dummy.position - Vector2(24, 0)  # keep in reach
		ticks += 1
	assert_true(dummy.is_ko(), "dummy KO'd")
	assert_eq(zone.hits, events.size(), "zone counts hits")
	assert_true(zone.get_node("Effects").get_child_count() > 0, "damage numbers spawned")
	for i in zone.DUMMY_RESPAWN_TICKS:
		zone.step(_input())
	assert_eq(dummy.hp, dummy.max_hp, "dummy respawned at full HP")
	assert_eq(dummy.state, Fighter.State.IDLE, "dummy is back on its feet")
	zone.free()


func test_player_input_reads_actions() -> void:
	Input.action_press("move_right")
	Input.action_press("guard")
	var input := PlayerInput.read()
	Input.action_release("move_right")
	Input.action_release("guard")
	assert_eq(input.move, Vector2.RIGHT, "move_right maps to +x")
	assert_true(input.guard, "guard is held")
