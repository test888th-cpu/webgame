extends TestCase
## World boss reinforcements (BossMechanics "summon" and "elite_summon",
## WorldBossRun): normal and elite minions called again and again on their own
## timers and caps, never on top of the hero, never touching the boss's pool,
## and gone (once) when the encounter ends. The shipped world bosses set no
## "elite_summon" yet (an owner decision), so these tests give the Tunnel
## Mother one in a copy of the content, naming an existing elite (the Smog
## Warden): no new enemy is made for them.

const MOTHER := "tunnel_mother"
const NORMAL := "tar_hound"
const ELITE := "smog_warden"
const TEST_SAVE := "user://test_world_boss_reinforcements_save"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Content where the Tunnel Mother calls both kinds quickly.
func _reinforced(below := 1.0) -> ContentDB:
	var c := ContentDB.load_all()
	var mother: Dictionary = c.enemies[MOTHER]
	mother["summon"] = {"enemy": NORMAL, "every": 60, "count": 2, "max": 3}
	mother["elite_summon"] = {"enemy": ELITE, "every": 90, "count": 1, "max": 1, "below": below}
	c.errors.clear()
	c.validate()
	return c


func _now(c: ContentDB, round: int) -> int:
	var spec: Dictionary = c.world_bosses[MOTHER]
	return round * int(spec["period_minutes"]) * 60 + int(spec["offset_minutes"]) * 60 + 60


## The boss up in its arena, the hero unable to fall and standing still.
func _arena(c: ContentDB, now: int) -> Array:
	var profile := PlayerProfile.new_game(c)
	profile.level = 40
	var zone := ZoneSim.new(c, profile, str(c.world_bosses[MOTHER]["area"]), "west", 5)
	var run := WorldBossRun.new(zone, profile, c, MOTHER, 4, now)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	for tick in 240:
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()), now)
		if zone.boss_id != 0:
			break
	return [zone, run]


static func _standing(zone: ZoneSim, kind: String) -> int:
	var n := 0
	for enemy in zone.enemies():
		if enemy.kind == kind and not enemy.is_ko():
			n += 1
	return n


func test_the_validator_checks_elite_reinforcements() -> void:
	assert_eq(_reinforced().errors, PackedStringArray(), "a valid elite_summon")
	var c := ContentDB.load_all()
	c.enemies[MOTHER]["elite_summon"] = {"enemy": NORMAL, "every": 0, "count": 1, "max": 1}
	var said := "\n".join(BossMechanics.summon_problems(c))
	assert_true("an elite enemy" in said, "a normal enemy is not an elite: " + said)
	assert_true("every: at least 1" in said, "a timer is needed")


func test_both_kinds_come_again_and_again_within_their_caps() -> void:
	var c := _reinforced()
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var boss := zone.fighter(zone.boss_id)
	assert_true(boss != null, "the boss is up")
	var calls := {NORMAL: 0, ELITE: 0}
	var pool := boss.hp
	for tick in 1200:
		zone.hero.hp = zone.hero.max_hp
		zone.hero.position = Vector2(zone.arena.position.x + 12.0, zone.hero.position.y)
		var events := zone.tick(FighterInput.new())
		run.tick(zone, events, now)
		for event in events:
			if event.type == "boss_summon":
				calls[event.data["kind"]] += 1
				for id: int in event.data["ids"]:
					var at := zone.fighter(id).position.x
					assert_true(
						absf(at - zone.hero.position.x) >= BossMechanics.SUMMON_CLEARANCE,
						"never on top of the hero (%d px)" % absf(at - zone.hero.position.x)
					)
		assert_true(_standing(zone, NORMAL) <= 3, "at most 3 normal minions at once")
		assert_true(_standing(zone, ELITE) <= 1, "at most 1 elite at once")
		# Knock the minions down now and then, so there is room to call more.
		if tick % 200 == 199:
			for enemy in zone.enemies():
				if enemy.id != boss.id:
					enemy.state = Fighter.State.KO
	assert_true(calls[NORMAL] >= 3, "normal minions called again and again: %d" % calls[NORMAL])
	assert_true(calls[ELITE] >= 2, "elites called again: %d" % calls[ELITE])
	assert_eq(boss.hp, pool, "calling reinforcements never touches the boss's pool")


func test_at_the_cap_the_call_waits_and_nobody_is_removed() -> void:
	var c := _reinforced()
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var reached := false
	var fallen := {}
	var seen := {}
	for tick in 900:
		zone.hero.hp = zone.hero.max_hp
		run.tick(zone, zone.tick(FighterInput.new()), now)
		assert_true(_standing(zone, NORMAL) <= 3, "never a fourth on its feet")
		reached = reached or _standing(zone, NORMAL) == 3
		for enemy in zone.enemies():
			if enemy.kind == NORMAL:
				seen[enemy.id] = true
				if enemy.is_ko():
					fallen[enemy.id] = true
		# A minion only ever leaves the arena once it has fallen (the boss's own
		# hazards hit its crew too); none is taken away to make room.
		for id: int in seen:
			if zone.fighter(id) == null:
				assert_true(fallen.has(id), "minion %d left only after falling" % id)
	assert_true(reached, "the cap was reached")


func test_elites_wait_for_their_health_share() -> void:
	var c := _reinforced(0.5)
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var boss := zone.fighter(zone.boss_id)
	for tick in 300:
		zone.hero.hp = zone.hero.max_hp
		run.tick(zone, zone.tick(FighterInput.new()), now)
	assert_eq(_standing(zone, ELITE), 0, "no elites while the boss is above half")
	boss.hp = boss.max_hp / 3
	for tick in 300:
		zone.hero.hp = zone.hero.max_hp
		run.tick(zone, zone.tick(FighterInput.new()), now)
	assert_eq(_standing(zone, ELITE), 1, "they come once it is below half")


func test_reinforcements_leave_with_the_boss_once() -> void:
	var c := _reinforced()
	var closes := int(WorldBossRules.window(c, MOTHER, _now(c, 4))["closes_at"])
	var start := closes - 20
	var setup := _arena(c, start)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var gone := 0
	for tick in 3000:
		zone.hero.hp = zone.hero.max_hp
		var events := zone.tick(FighterInput.new())
		run.tick(zone, events, start + tick / CombatRules.TICK_RATE)
		for event in events:
			gone += 1 if event.type == "despawn" else 0
		if run.ended:
			break
	assert_eq(run.ended, "time", "the boss escaped at the end of its hour")
	assert_true(gone > 0, "its minions went with it (%d)" % gone)
	assert_eq(zone.enemies().size(), 0, "nothing of the encounter is left")
	var again := zone.tick(FighterInput.new())
	run.tick(zone, again, closes + 60)
	for event in again:
		assert_true(event.type not in ["despawn", "spawn", "boss_summon"], "resolved once")


## Each world boss keeps its own level, pool, schedule and reinforcements.
func test_every_world_boss_has_its_own_configuration() -> void:
	var c := _content()
	var levels := {}
	var schedules := {}
	for boss: String in c.world_bosses:
		var spec: Dictionary = c.world_bosses[boss]
		levels[int(spec["level"])] = true
		schedules["%s/%s" % [spec["period_minutes"], spec["offset_minutes"]]] = true
		assert_true(int(spec["open_minutes"]) > 0, boss + ": an encounter time")
		assert_true(c.enemy(str(spec["enemy"])).has("summon"), boss + ": calls reinforcements")
	assert_true(levels.size() >= 5, "many levels: %s" % [levels.keys()])
	assert_true(schedules.size() >= 5, "many schedules: %s" % [schedules.keys()])


# Elite reinforcements reuse the game's existing elites, and stay off until a
# world boss is given an "elite_summon" (none is yet: an owner decision).


func test_no_production_world_boss_calls_elites() -> void:
	var c := _content()
	for kind: String in c.enemies:
		assert_true(not c.enemy(kind).has("elite_summon"), kind + ": no elite_summon shipped")
	# The Tunnel Mother as shipped: only its own normal minions come.
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var normal := str(c.enemy(MOTHER)["summon"]["enemy"])
	var calls := 0
	for tick in 1500:
		zone.hero.hp = zone.hero.max_hp
		var events := zone.tick(FighterInput.new())
		run.tick(zone, events, now)
		for event in events:
			if event.type == "boss_summon":
				calls += 1
				assert_eq(event.data["kind"], normal, "only its normal minions")
				var count := int(c.enemy(MOTHER)["summon"]["count"])
				assert_true(event.data["ids"].size() <= count, "no more than its count")
	assert_true(calls >= 1, "its normal minions still come (%d calls)" % calls)
	assert_eq(_standing(zone, ELITE), 0, "and no elite")


func test_a_summoned_elite_is_the_existing_elite() -> void:
	var c := _reinforced()
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var elite: Fighter = null
	var swung := false
	for tick in 1500:
		zone.hero.hp = zone.hero.max_hp
		var events := zone.tick(FighterInput.new())
		run.tick(zone, events, now)
		for event in events:
			if event.type == "boss_summon" and event.data["kind"] == ELITE and elite == null:
				elite = zone.fighter(int(event.data["ids"][0]))
			if elite and event.type == "swing" and int(event.data["id"]) == elite.id:
				swung = true
		if elite and swung:
			break
	assert_true(elite != null, "an elite came")
	if elite == null:
		return
	var data := c.enemy(ELITE)
	assert_true(data.get("elite", false), "an existing elite definition")
	assert_eq(elite.kind, ELITE, "its own kind")
	var reference := zone.spawn_enemy(ELITE, zone.arena.get_center())
	assert_eq(elite.max_hp, reference.max_hp, "its own stats at the arena's level")
	assert_eq(elite.power, reference.power, "its own power")
	assert_eq(elite.moveset, data.get("moveset", {}), "its own moves")
	assert_true(zone.brains.has(elite.id), "its own AI")
	assert_true(swung, "and it fights")


func test_repeated_triggers_never_pass_the_elite_cap() -> void:
	var c := ContentDB.load_all()
	c.enemies[MOTHER]["elite_summon"] = {"enemy": ELITE, "every": 1, "count": 3, "max": 2}
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var most := 0
	for tick in 600:
		zone.hero.hp = zone.hero.max_hp
		run.tick(zone, zone.tick(FighterInput.new()), now)
		most = maxi(most, _standing(zone, ELITE))
	assert_eq(most, 2, "a call every tick, three at a time, never past the cap of 2")


func test_malformed_elite_data_calls_nothing_and_is_reported() -> void:
	var bad := [
		"not an object",
		{"enemy": "no_such_enemy", "every": 60, "count": 1, "max": 1},
		{"enemy": NORMAL, "every": 60, "count": 1, "max": 1},
		{"enemy": ELITE, "every": "soon", "count": 1, "max": 1},
		{"enemy": ELITE, "count": 1, "max": 1},
		{"enemy": ELITE, "every": 60, "count": 1, "max": 1, "below": 2.0},
	]
	for spec: Variant in bad:
		var c := ContentDB.load_all()
		c.enemies[MOTHER]["elite_summon"] = spec
		assert_true(BossMechanics.summon_problems(c).size() > 0, "reported: %s" % [spec])
		assert_eq(BossMechanics.elite_spec(c, c.enemies[MOTHER]), {}, "unusable: %s" % [spec])
		var now := _now(c, 4)
		var setup := _arena(c, now)
		var zone: ZoneSim = setup[0]
		var run: WorldBossRun = setup[1]
		for tick in 300:
			zone.hero.hp = zone.hero.max_hp
			run.tick(zone, zone.tick(FighterInput.new()), now)
		assert_eq(_standing(zone, ELITE), 0, "no elite from %s" % [spec])
	var empty := ContentDB.load_all()
	empty.enemies[MOTHER]["elite_summon"] = {}
	assert_eq(BossMechanics.summon_problems(empty), PackedStringArray(), "{} is just off")


# The HUD's "An elite ... joins the battle!" (GameFeedback, on "boss_summon"
# with "elite"): only for an existing elite a world boss calls in, once per call.


## The "boss_summon" events when `caller` in `area_id` calls `count` of `kind`.
func _summon_events(area_id: String, caller: String, kind: String, count: int) -> Array:
	var c := _content()
	var zone := ZoneSim.new(c, PlayerProfile.new_game(c), area_id, "west", 3)
	var boss := zone.spawn_enemy(caller, zone.arena.get_center())
	var events: Array[ZoneEvent] = []
	var data := {"enemy": kind, "every": 1, "count": count, "max": 10}
	BossMechanics.new().summon(zone, boss, data, events)
	var out: Array = []
	for event in events:
		if event.type == "boss_summon":
			out.append(event)
	return out


func test_only_a_world_boss_elite_summon_is_marked_for_the_hud() -> void:
	var elite := _summon_events("great_drain", MOTHER, ELITE, 2)
	assert_eq(elite.size(), 1, "two elites in one call: one summon event, so one notice")
	if elite:
		assert_true(elite[0].data["elite"], "a world boss's elite is announced")
		assert_eq(elite[0].data["ids"].size(), 2, "both arrived")
	var normal := _summon_events("great_drain", MOTHER, NORMAL, 2)
	if normal:
		assert_true(not normal[0].data["elite"], "normal minions are not elites")
	var story := _summon_events("sak_tower", "big_sak", ELITE, 1)
	if story:
		assert_true(not story[0].data["elite"], "not a world boss: no world boss notice")


func test_the_hud_announces_an_elite_once_and_never_a_normal_minion() -> void:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var label: Label = game._hud._toast_text
	label.text = "-"
	var normal := ZoneEvent.make(
		"boss_summon", {"id": 0, "kind": NORMAL, "ids": [], "elite": false}
	)
	game._feedback.on_event(normal)
	assert_eq(label.text, "-", "a normal minion is not announced")
	var shipped := ZoneEvent.make("boss_summon", {"id": 0, "kind": NORMAL, "ids": []})
	game._feedback.on_event(shipped)
	assert_eq(label.text, "-", "an event without the flag is not announced")
	var elite := ZoneEvent.make("boss_summon", {"id": 0, "kind": ELITE, "ids": [], "elite": true})
	game._feedback.on_event(elite)
	var name := str(game.content.enemy(ELITE)["name"])
	assert_eq(label.text, "An elite %s joins the battle!" % name, "the elite is announced")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## An elite reinforcement arriving through the real world boss fight raises
## exactly one notice per call, and normal minions none.
func test_in_a_fight_each_elite_call_is_one_notice() -> void:
	var c := _reinforced()
	var now := _now(c, 4)
	var setup := _arena(c, now)
	var zone: ZoneSim = setup[0]
	var run: WorldBossRun = setup[1]
	var elite_calls := 0
	var flagged := 0
	for tick in 1200:
		zone.hero.hp = zone.hero.max_hp
		var events := zone.tick(FighterInput.new())
		run.tick(zone, events, now)
		for event in events:
			if event.type != "boss_summon":
				continue
			elite_calls += 1 if event.data["kind"] == ELITE else 0
			if event.data["elite"]:
				flagged += 1
				assert_eq(event.data["kind"], ELITE, "only the elite is flagged")
		if tick % 200 == 199:
			for enemy in zone.enemies():
				if enemy.id != zone.boss_id:
					enemy.state = Fighter.State.KO
	assert_true(elite_calls >= 1, "elites were called (%d)" % elite_calls)
	assert_eq(flagged, elite_calls, "one notice per elite call, none for normal minions")
