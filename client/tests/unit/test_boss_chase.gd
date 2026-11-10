extends TestCase
## The owner's report: run far from a boss and it stood off calling its
## skills instead of coming after the hero. A boss now strides to catch up
## (BossMechanics.CATCH_UP) once the hero is CATCH_UP_FROM away, and walks at
## its own pace again up close.

const BOSS := "tunnel_mother"


func _fight() -> Array:
	var c := ContentDB.load_all()
	var spec: Dictionary = c.world_bosses[BOSS]
	var profile := PlayerProfile.new_game(c)
	profile.level = int(spec["level"])
	var period := int(spec["period_minutes"]) * 60
	var now := 3 * period + int(spec.get("offset_minutes", 0)) * 60 + 30
	var zone := ZoneSim.new(c, profile, str(spec["area"]), "west", 4)
	var run := WorldBossRun.new(zone, profile, c, BOSS, 3, now)
	zone.hero.max_hp = 100000000
	return [zone, run, now]


func test_a_slow_boss_strides_after_a_hero_who_runs_off() -> void:
	var fight := _fight()
	var zone: ZoneSim = fight[0]
	var run: WorldBossRun = fight[1]
	var boss: Fighter = null
	for tick in 600:
		zone.hero.hp = zone.hero.max_hp
		zone.hero.position.x = 200.0
		zone.tick(FighterInput.new())
		run.tick(zone, [], int(fight[2]))
		boss = zone.fighter(zone.boss_id) if zone.boss_id else null
		if boss and absf(boss.position.x - 200.0) < 100.0:
			break
	assert_true(boss != null, "the boss came")
	var own := boss.speed
	assert_true(own < zone.hero.speed, "a slow boss (%.2f)" % own)
	# The hero runs off to the far end of the arena and waits there.
	var far := zone.bounds.end.x - 20.0 if boss.position.x < zone.bounds.get_center().x else 40.0
	zone.hero.position.x = far
	var from := boss.position.x
	var fastest := own
	for tick in 120:
		zone.hero.hp = zone.hero.max_hp
		zone.tick(FighterInput.new())
		run.tick(zone, [], int(fight[2]))
		fastest = maxf(fastest, boss.speed)
	var covered := absf(boss.position.x - from)
	var hero_walk := LaneMovement.WALK_SPEED_X * zone.hero.speed * zone.hero.weapon_speed * 2.0
	assert_true(fastest > zone.hero.speed, "out-walks the hero while far (%.2f)" % fastest)
	assert_true(
		covered > hero_walk, "%d px in two seconds, the hero walks %d" % [covered, hero_walk]
	)
	# Up close again, its own pace.
	for tick in 600:
		zone.hero.hp = zone.hero.max_hp
		zone.tick(FighterInput.new())
		run.tick(zone, [], int(fight[2]))
		if absf(zone.hero.position.x - boss.position.x) < 80.0:
			break
	for tick in 2:
		zone.tick(FighterInput.new())
		run.tick(zone, [], int(fight[2]))
	var gap := absf(zone.hero.position.x - boss.position.x)
	assert_true(gap < BossMechanics.CATCH_UP_FROM, "caught up (%d px)" % gap)
	assert_near(boss.speed, own, "back to its own walk", 0.001)
