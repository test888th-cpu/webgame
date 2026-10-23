extends TestCase
## Instantiates the real zone scene and drives it through input actions.


func _spawn_zone() -> Node2D:
	var zone: Node2D = load("res://scenes/world/TestZone.tscn").instantiate()
	tree.root.add_child(zone)  # runs _ready synchronously once the loop is live
	return zone


func test_zone_has_player_camera_and_hud() -> void:
	var zone := _spawn_zone()
	assert_true(zone.player is Player, "zone exposes the player")
	var camera: Camera2D = zone.get_node("Entities/Player/Camera")
	assert_eq(camera.limit_right, int(zone.ZONE_SIZE.x), "camera is bounded to the zone")
	assert_true(zone.has_node("Hud/Status"), "HUD has a status line")
	assert_eq(zone.get_node("Hud/Touch").get_child_count(), 4, "touch pad has four directions")
	zone.free()


func test_input_actions_move_the_player() -> void:
	var zone := _spawn_zone()
	var player: Player = zone.player
	var start := player.position
	Input.action_press("move_right")
	player._physics_process(0.05)
	Input.action_release("move_right")
	assert_true(player.position.x > start.x, "move_right moves right")
	Input.action_press("move_up")
	player._physics_process(0.05)
	Input.action_release("move_up")
	assert_true(player.position.y < start.y, "move_up moves into the lane")
	zone.free()


func test_player_cannot_leave_the_street() -> void:
	var zone := _spawn_zone()
	var player: Player = zone.player
	Input.action_press("move_left")
	Input.action_press("move_down")
	for i in 200:
		player._physics_process(0.1)
	Input.action_release("move_left")
	Input.action_release("move_down")
	assert_eq(player.position.x, zone.WALK_BOUNDS.position.x, "stops at the west edge")
	assert_eq(player.position.y, zone.WALK_BOUNDS.end.y, "stops at the kerb")
	zone.free()
