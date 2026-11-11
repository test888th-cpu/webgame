extends TestCase
## Footsteps: soft footfalls for whoever walks, the hero's clear, a monster's
## quieter with distance and never a crowd drumming at once.


func _zone() -> ZoneSim:
	var db := GameSession.content
	return ZoneSim.new(db, PlayerProfile.new_game(db, "oren"), "saltmarket", "west", 3)


## Moves `f` `px` px east over `frames` frames, a frame each `msec`.
func _walk(steps: Footsteps, zone: ZoneSim, f: Fighter, px: float, frames: int) -> int:
	var heard := 0
	for i in frames:
		f.position.x += px / frames
		heard += steps.update(zone, 1000 + i * 16).count(f.id)
	return heard


func test_a_footfall_every_stride_while_walking() -> void:
	var zone := _zone()
	var steps := Footsteps.new()
	steps.update(zone, 0)
	var heard := _walk(steps, zone, zone.hero, Footsteps.STRIDE * 4, 40)
	assert_eq(heard, 4, "one per stride")
	zone.hero.enter(Fighter.State.DOWN)
	assert_eq(_walk(steps, zone, zone.hero, Footsteps.STRIDE * 3, 20), 0, "sliding is silent")


func test_monsters_are_quieter_and_fade_with_distance() -> void:
	var near := Footsteps.volume(false, 20.0)
	assert_true(near < Footsteps.volume(true, 0.0), "a monster is quieter than the hero")
	assert_true(Footsteps.volume(false, 200.0) < near, "and fades with distance")
	assert_eq(Footsteps.volume(false, Footsteps.HEARD + 1.0), Footsteps.SILENT, "far: unheard")


func test_a_crowd_does_not_drum() -> void:
	var zone := _zone()
	var steps := Footsteps.new()
	var crowd: Array[Fighter] = []
	for i in 6:
		crowd.append(zone.spawn_enemy("smogling", zone.hero.position + Vector2(30 + i * 4, 0)))
	steps.update(zone, 0)
	for f in crowd:
		f.position.x += Footsteps.STRIDE
	var heard := steps.update(zone, 1000)
	assert_eq(heard.size(), 1, "six strides on one frame: one footfall heard")


func test_footfalls_follow_the_feet_on_screen() -> void:
	var view: FighterView = load("res://scenes/fighter/FighterView.tscn").instantiate()
	tree.root.add_child(view)
	view.set_art("hero_oren", GameSession.content.art)
	var sprite := view.get_node("Sprite") as AnimatedSprite2D
	sprite.play("walk")
	var feet: Array[String] = []
	for frame in 8:
		sprite.frame = frame
		feet.append(view.footfall())
		feet.append(view.footfall())  # the same frame twice: one footfall
	assert_eq(feet.filter(func(f: String) -> bool: return f != ""), ["l", "r"], "left, right")
	assert_eq(feet[0], "l", "the left foot first")
	assert_eq(feet[FighterView.STEP_FRAMES[1] * 2], "r", "the right foot half a cycle on")
	sprite.play("idle")
	assert_eq(view.footfall(), "", "standing still: none")
	var cycle := 8.0 / 10.0  # the walk: 8 frames at 10 fps, two steps a cycle
	assert_near(Footsteps.STRIDE, LaneMovement.WALK_SPEED_X * cycle / 2.0, "no art: same pace")
	view.queue_free()
