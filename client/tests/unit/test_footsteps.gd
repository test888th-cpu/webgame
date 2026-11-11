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
