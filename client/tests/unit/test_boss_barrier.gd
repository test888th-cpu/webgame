extends TestCase
## A boss's shield as a barrier (BossBarrier): its footprint is a wall to the
## hero, who is thrown out (floored, unhurt) if inside when it goes up; the
## boss's own side walks through; it goes with the shield or the boss; and
## every shielded boss's dome covers its whole body, head and raised weapon
## included, measured from the art.

const ART_SKIPPED: Array[String] = ["down", "hurt", "ko", "lift", "throw", "dodge"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _shield(kind: String) -> Dictionary:
	for phase: Dictionary in _content().enemy(kind).get("phases", []):
		if phase.has("shield"):
			return phase["shield"]
	return {}


## Saltmarket with Director Wiroj at `at`, no AI, and the hero at `hero_at`.
func _zone(at: Vector2, hero_at: Vector2) -> ZoneSim:
	var profile := PlayerProfile.new_game(_content(), "mika")
	profile.level = 20
	var zone := ZoneSim.new(_content(), profile, "saltmarket", "west", 5)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	zone.hero.position = hero_at
	var boss := zone.spawn_enemy("director_wiroj", at)
	zone.brains.erase(boss.id)
	return zone


func _raise(zone: ZoneSim) -> Array[ZoneEvent]:
	var events: Array[ZoneEvent] = []
	var boss := zone.fighter(zone.boss_id)
	BossBarrier.hold(zone, boss, _shield("director_wiroj"), true, events)
	return events


func test_every_shielded_boss_has_a_barrier_over_its_whole_body() -> void:
	var c := _content()
	var bosses := 0
	for kind: String in c.enemies:
		var shield := _shield(kind)
		if shield.is_empty():
			continue
		bosses += 1
		assert_true(shield.has("half") and shield.has("height"), kind + ": sized in the data")
		var data := c.enemy(kind)
		var art: Dictionary = c.art[str(data["sprite"])]
		var reach := _art_reach(art)
		var scale := float(data.get("scale", 1.0))
		var spec := BossBarrier.size(c, kind, shield)
		assert_true(
			float(spec["height"]) >= reach.y * scale,
			"%s: dome %d tall over a body %d tall" % [kind, spec["height"], reach.y * scale]
		)
		assert_true(
			(spec["half"] as Vector2).x >= reach.x * scale * 0.75,
			"%s: dome wide enough for its body" % kind
		)
	assert_true(bosses >= 9, "every shielded boss checked (%d)" % bosses)


## How far the art reaches from its feet in any standing pose: (half width,
## height), in its own pixels.
func _art_reach(art: Dictionary) -> Vector2:
	var sheet := (load(str(art["sheet"])) as Texture2D).get_image()
	var frame := Vector2i(art["frame_size"][0], art["frame_size"][1])
	var origin := Vector2i(art["origin"][0], art["origin"][1])
	var reach := Vector2.ZERO
	for anim: String in art["animations"]:
		if anim in ART_SKIPPED:
			continue
		var row := int(art["animations"][anim]["row"])
		for i in int(art["animations"][anim]["frames"]):
			var cell := Rect2i(Vector2i(i * frame.x, row * frame.y), frame)
			var used := sheet.get_region(cell).get_used_rect()
			if used.size == Vector2i.ZERO:
				continue
			reach.y = maxf(reach.y, origin.y - used.position.y)
			reach.x = maxf(reach.x, maxf(origin.x - used.position.x, used.end.x - origin.x))
	return reach


func test_a_hero_inside_when_it_goes_up_is_thrown_out_unhurt() -> void:
	var zone := _zone(Vector2(500, 300), Vector2(520, 302))
	var hp := zone.hero.hp
	var events := _raise(zone)
	var shoved := false
	for event in events:
		if event.type == "hit" and event.hit.defender_id == ZoneSim.HERO_ID:
			shoved = event.hit.knocked_down and event.hit.damage == 0
	assert_true(shoved, "floored, for no damage")
	assert_eq(zone.hero.state, Fighter.State.DOWN, "on the ground")
	for t in 40:
		zone.tick(FighterInput.new())
	assert_true(not BossBarrier.inside(zone.barriers[0], zone.hero.position), "out of it")
	assert_true(zone.hero.position.x > 520.0, "thrown away from the boss")
	assert_eq(zone.hero.hp, hp, "unhurt")


func test_near_a_wall_the_hero_is_thrown_out_the_other_way() -> void:
	var zone := _zone(Vector2(0, 300), Vector2(0, 300))
	var boss := zone.fighter(zone.boss_id)
	boss.position = Vector2(zone.walk.position.x + 10.0, 300)
	zone.hero.position = boss.position + Vector2(-4, 0)
	_raise(zone)
	for t in 60:
		zone.tick(FighterInput.new())
	assert_true(not BossBarrier.inside(zone.barriers[0], zone.hero.position), "out")
	assert_true(zone.hero.position.x > boss.position.x, "on the open side")


func test_the_hero_cannot_walk_into_it() -> void:
	var zone := _zone(Vector2(500, 300), Vector2(380, 300))
	_raise(zone)
	var walk := FighterInput.new()
	walk.move = Vector2.RIGHT
	for t in 240:
		zone.tick(walk)
	assert_true(not BossBarrier.inside(zone.barriers[0], zone.hero.position), "stopped outside")
	var reach: float = (zone.barriers[0]["half"] as Vector2).x + Bodies.PERSON.x
	assert_true(zone.hero.position.x > 500.0 - reach - 4.0, "right up against it")
	var up := FighterInput.new()
	up.move = Vector2(1, -1)
	for t in 120:
		zone.tick(up)
	assert_true(not BossBarrier.inside(zone.barriers[0], zone.hero.position), "nor round in")


func test_the_boss_side_walks_through_and_it_goes_with_the_shield() -> void:
	var zone := _zone(Vector2(500, 300), Vector2(200, 300))
	var crew := zone.spawn_enemy("smogling", Vector2(500, 300) + Vector2(20, 0))
	zone.brains.erase(crew.id)
	var events := _raise(zone)
	for event in events:
		assert_true(event.type != "hit", "its own side is not put out")
	var boss := zone.fighter(zone.boss_id)
	BossBarrier.hold(zone, boss, {}, false, [])
	assert_true(zone.barriers.is_empty(), "dropped with the shield")
	_raise(zone)
	boss.hp = 0
	boss.enter(Fighter.State.KO)
	BossBarrier.hold(zone, boss, _shield("director_wiroj"), false, [])
	assert_true(zone.barriers.is_empty(), "and gone with the boss")


func test_the_real_fight_raises_it_and_puts_the_hero_out() -> void:
	# Director Wiroj's own phase: below its share, the shield goes up.
	var zone := _zone(Vector2(500, 300), Vector2(515, 300))
	var boss := zone.fighter(zone.boss_id)
	var phase: Dictionary = _content().enemy("director_wiroj")["phases"][0]
	boss.hp = floori(boss.max_hp * float(phase["below"])) - 1
	var hp := zone.hero.hp
	var raised := false
	for t in 30:
		for event in zone.tick(FighterInput.new()):
			raised = raised or (event.type == "boss_shield" and event.data["up"])
		if raised:
			break
	assert_true(raised, "the shield went up")
	assert_eq(zone.barriers.size(), 1, "a barrier with it")
	for t in 40:
		zone.tick(FighterInput.new())
	assert_true(not BossBarrier.inside(zone.barriers[0], zone.hero.position), "hero put out")
	assert_eq(zone.hero.hp, hp, "unhurt by the barrier")
