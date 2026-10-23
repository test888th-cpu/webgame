extends TestCase
## LaneMovement is shared with the future zone server, so its rules are
## pinned down here.

const BOUNDS := Rect2(0, 100, 1000, 100)
const START := Vector2(500, 150)


func test_no_input_does_not_move() -> void:
	assert_eq(LaneMovement.step(START, Vector2.ZERO, 0.05, BOUNDS), START, "idle stays put")


func test_moves_along_street_at_walk_speed() -> void:
	var moved := LaneMovement.step(START, Vector2.RIGHT, 0.05, BOUNDS)
	assert_near(moved.x, START.x + LaneMovement.WALK_SPEED_X * 0.05, "x advances")
	assert_near(moved.y, START.y, "depth unchanged")


func test_depth_is_slower_than_street() -> void:
	var moved := LaneMovement.step(START, Vector2.DOWN, 0.05, BOUNDS)
	assert_near(moved.y, START.y + LaneMovement.WALK_SPEED_Y * 0.05, "y advances at depth speed")
	assert_true(LaneMovement.WALK_SPEED_Y < LaneMovement.WALK_SPEED_X, "depth is slower")


func test_oversized_input_is_normalised() -> void:
	# A modified client sending (10, 10) must not move faster than full stick.
	var cheat := LaneMovement.step(START, Vector2(10, 10), 0.05, BOUNDS)
	var legit := LaneMovement.step(START, Vector2(1, 1).normalized(), 0.05, BOUNDS)
	assert_near(cheat.x, legit.x, "x capped")
	assert_near(cheat.y, legit.y, "y capped")


func test_long_frames_are_capped() -> void:
	var moved := LaneMovement.step(START, Vector2.RIGHT, 5.0, BOUNDS)
	var expected := START.x + LaneMovement.WALK_SPEED_X * LaneMovement.MAX_STEP_SECONDS
	assert_near(moved.x, expected, "a 5 s hitch moves at most MAX_STEP_SECONDS worth")


func test_negative_delta_does_not_move_backwards() -> void:
	assert_eq(LaneMovement.step(START, Vector2.RIGHT, -1.0, BOUNDS), START, "negative dt ignored")


func test_clamped_to_walkable_bounds() -> void:
	var corner := Vector2(BOUNDS.end.x - 1, BOUNDS.end.y - 1)
	var moved := LaneMovement.step(corner, Vector2(1, 1), 0.1, BOUNDS)
	assert_eq(moved, BOUNDS.end, "stops at the far corner")
	var origin := LaneMovement.step(BOUNDS.position, Vector2(-1, -1), 0.1, BOUNDS)
	assert_eq(origin, BOUNDS.position, "stops at the near corner")


func test_facing_follows_horizontal_input_only() -> void:
	assert_eq(LaneMovement.facing(1, Vector2.LEFT), -1, "turns left")
	assert_eq(LaneMovement.facing(-1, Vector2.RIGHT), 1, "turns right")
	assert_eq(LaneMovement.facing(-1, Vector2.DOWN), -1, "depth-only keeps facing")
