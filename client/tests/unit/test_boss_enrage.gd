extends TestCase
## Boss enrage (BossEnrage): a lair boss's fight timer and a world boss's
## round enrage. Both only raise the pressure (harder blows, quicker
## hazards); neither ends a fight, takes an entry or touches food.

const LAIR := "coolant_control_room"
const REMATCH := "arthit_reinstated"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A zone in `area_id` with a hero who cannot fall, already inside the boss fight.
func _fight(area_id: String) -> ZoneSim:
	var profile := PlayerProfile.new_game(_content())
	profile.level = 55
	var zone := ZoneSim.new(_content(), profile, area_id, "west", 11)
	zone.hero.max_hp = 100000000
	zone.hero.hp = zone.hero.max_hp
	for tick in 600:
		zone.hero.position.x = float(_content().area(area_id)["encounters"][0]["trigger_x"]) + 10
		zone.tick(FighterInput.new())
		if zone.boss_id != 0:
			break
	return zone


func test_a_lair_boss_warns_then_enrages_on_its_timer() -> void:
	var zone := _fight(LAIR)
	assert_true(zone.boss_id != 0, "the boss is up")
	var boss := zone.fighter(zone.boss_id)
	assert_eq(boss.kind, REMATCH, "the rematch")
	var spec: Dictionary = _content().enemy(REMATCH)["enrage"]
	var times := BossEnrage.fight_ticks(spec)
	var power := boss.power
	var warned_at := -1
	var enraged_at := -1
	for tick in int(times["at"]) + 60:
		zone.hero.hp = zone.hero.max_hp
		for event in zone.tick(FighterInput.new()):
			if event.type == "boss_enrage_warn":
				warned_at = tick
				assert_eq(int(event.data["seconds"]), int(spec["warn_seconds"]), "says how long")
			elif event.type == "boss_enrage":
				enraged_at = tick
	assert_true(warned_at >= 0, "a warning first")
	assert_true(enraged_at > warned_at, "then the enrage")
	var gap := float(enraged_at - warned_at) / CombatRules.TICK_RATE
	assert_near(gap, float(spec["warn_seconds"]), "warned that many seconds ahead", 0.1)
	assert_near(boss.power, power * float(spec["damage"]), "harder blows", 0.001)
	assert_near(boss.rage, float(spec["cooldown"]), "quicker hazards", 0.001)
	assert_true(not boss.is_ko() and zone.in_encounter(), "the fight goes on")


func test_enrage_paces_hazards_and_raises_damage() -> void:
	var boss := Fighter.new()
	boss.power = 2.0
	BossEnrage.apply(boss, {"damage": 1.5, "cooldown": 0.5})
	assert_near(boss.power, 3.0, "power x damage", 0.001)
	assert_eq(BossEnrage.paced(boss, 300), 150, "intervals x cooldown")
	assert_eq(BossEnrage.paced(Fighter.new(), 300), 300, "calm bosses keep their pace")
	assert_eq(BossEnrage.paced(boss, 1), 1, "never below a tick")


func test_only_bosses_with_an_enrage_have_one() -> void:
	# The story's bosses keep their mechanics: only the 50-70 lairs' bosses
	# (and the spillway's) carry a fight timer.
	var c := _content()
	for id: String in c.enemies:
		if c.enemy(id).has("enrage"):
			var lair := false
			for lair_id in AreaRules.lairs(c):
				lair = lair or c.area(lair_id)["encounters"][0]["waves"][0].has(id)
			assert_true(lair, id + ": a lair boss")
	for street_id in StreetMemory.street(c):
		for encounter: Dictionary in c.area(street_id).get("encounters", []):
			for wave: Array in encounter["waves"]:
				for kind: String in wave:
					assert_true(not c.enemy(kind).has("enrage"), kind + ": no timer in the story")


func test_a_world_boss_enrages_for_the_rounds_last_seconds() -> void:
	var c := _content()
	var boss := "slag_titan"
	var spec: Dictionary = c.world_bosses[boss]
	var rage: Dictionary = spec["enrage"]
	var profile := PlayerProfile.new_game(c)
	profile.level = 60
	profile.defeated[str(spec["unlock"])] = 1
	var arena := str(spec["area"])
	var period := int(spec["period_minutes"]) * 60
	var opens := 3 * period + int(spec.get("offset_minutes", 0)) * 60
	var closes := opens + int(spec["open_minutes"]) * 60
	# Arrive with the warning still ahead: a few seconds before it.
	var arrive := closes - int(rage["last_seconds"]) - int(rage["warn_seconds"]) - 3
	var zone := ZoneSim.new(c, profile, arena, "west", 4)
	var run := WorldBossRun.new(zone, profile, c, boss, 3, arrive)
	zone.hero.max_hp = 100000000
	var power := -1.0
	var states: Array[String] = []
	var seconds := int(rage["warn_seconds"]) + 8
	for tick in seconds * CombatRules.TICK_RATE:
		zone.hero.hp = zone.hero.max_hp
		zone.hero.position.x = 200
		run.tick(zone, zone.tick(FighterInput.new()))
		if power < 0.0 and zone.boss_id != 0:
			power = zone.fighter(zone.boss_id).power
		if run.rage not in states:
			states.append(run.rage)
	assert_eq(states, ["", "warned", "enraged"] as Array[String], "calm, warned, enraged")
	var giant := zone.fighter(zone.boss_id)
	assert_near(giant.power, power * float(rage["damage"]), "harder blows", 0.001)
	assert_near(giant.rage, float(rage["cooldown"]), "quicker hazards", 0.001)
	assert_eq(run.ended, "", "the attempt goes on to the end of the round")
	assert_true("ENRAGED" in run.hud_text(), "said on the HUD: " + run.hud_text())


func test_world_boss_rules_stand_with_enrage() -> void:
	# Unlimited entries and attempts, no waiting between them: the enrage is
	# data on the fight, never a gate.
	var c := _content()
	for boss: String in c.world_bosses:
		var spec: Dictionary = c.world_bosses[boss]
		for limit in ["attempts", "daily_attempts", "cooldown_minutes", "entries"]:
			assert_true(not spec.has(limit), "%s: no %s" % [boss, limit])
		if spec.has("enrage"):
			for limit in ["attempts", "ends_fight", "lockout"]:
				assert_true(not spec["enrage"].has(limit), "%s: enrage is no gate" % boss)


func test_the_validator_checks_enrage() -> void:
	var c := _content()
	assert_eq(BossEnrage.content_problems(c), PackedStringArray(), "the shipped data is clean")
	var bad := {"after_seconds": 30, "warn_seconds": 40, "damage": 9.0, "cooldown": 0.0}
	var said := "\n".join(BossEnrage.problems(bad, "x", BossEnrage.FIGHT_KEYS))
	assert_true("warn_seconds" in said, "a warning inside the time")
	assert_true("damage" in said, "a sane multiplier")
	assert_true("cooldown" in said, "a pace above 0")
	said = "\n".join(BossEnrage.problems({"after_seconds": 10}, "x", BossEnrage.FIGHT_KEYS))
	assert_true("a number" in said, "every field given")
	var copy := ContentDB.load_all()
	copy.enemies["smogling"]["enrage"] = {
		"after_seconds": 60, "warn_seconds": 10, "damage": 1.5, "cooldown": 0.7
	}
	copy.errors.clear()
	copy.validate()
	assert_true("enemies.smogling.enrage: a boss's" in "\n".join(copy.errors), "bosses only")
