extends TestCase
## Skill pacing: heroes get their skills back quickly, while enemies and
## bosses must wait longer between their heavy blows than a hero waits for
## any regular skill, so they cannot chain them back to back.

## A hero's regular skills come back within this many ticks; a job may have
## up to BIG_SKILLS slower ones, within BIG_MAX (60 ticks a second). An
## ultimate waits for its gauge, not for a clock.
const SKILL_MAX := 270
const BIG_MAX := 780
const BIG_SKILLS := 2

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## The cooldowns of every hero's active skills: the regular ones (within
## SKILL_MAX), or the big ones.
func _hero_skill_cooldowns(big: bool) -> Array[int]:
	var out: Array[int] = []
	for hero_id: String in _content().hero_order:
		for skill_id in SkillRules.actives(_content(), hero_id):
			var cooldown := int(_content().skills[skill_id]["cooldown"])
			if (cooldown > SKILL_MAX) == big:
				out.append(cooldown)
	return out


func test_hero_skills_come_back_quickly() -> void:
	for cooldown in _hero_skill_cooldowns(true):
		assert_true(cooldown <= BIG_MAX, "a big skill waits %d ticks" % cooldown)
	for hero_id: String in _content().hero_order:
		var big := 0
		for skill_id in SkillRules.actives(_content(), hero_id):
			big += 1 if int(_content().skills[skill_id]["cooldown"]) > SKILL_MAX else 0
		assert_true(big <= BIG_SKILLS, "%s has %d slow skills" % [hero_id, big])
		var gauge: Dictionary = _content().skills[SkillRules.ultimate(_content(), hero_id)]
		assert_true(int(gauge["cooldown"]) <= SKILL_MAX, hero_id + ": the gauge paces the ultimate")


func test_enemy_heavies_wait_longer_than_hero_skills() -> void:
	var longest: int = _hero_skill_cooldowns(false).max()
	for enemy_id: String in _content().enemies:
		var enemy: Dictionary = _content().enemies[enemy_id]
		# A ranged enemy's lob is its basic attack, not a signature blow.
		if not enemy.get("moveset", {}).has("heavy") or enemy.has("ranged"):
			continue
		var stages: Array = [enemy["ai"]]
		stages.append_array(enemy.get("phases", []))
		for stage: Dictionary in stages:
			assert_true(
				int(stage.get("heavy_cooldown", EnemyBrain.DEFAULT_HEAVY_COOLDOWN)) > longest,
				"%s waits longer than a hero between heavy blows" % enemy_id
			)
		if enemy.has("phases"):
			assert_true(
				int(enemy["ai"]["heavy_cooldown"]) >= 300, "%s, a boss, waits longest" % enemy_id
			)


func test_an_enemy_never_chains_heavy_blows() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "saltmarket", "", 3)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone._encounters.clear()
	zone.hero.position = Vector2(600, 300)
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	var baron := zone.spawn_enemy("furnace_baron", Vector2(640, 300))
	var brain: EnemyBrain = zone.brains[baron.id]
	brain.heavy_chance = 1.0
	var heavies: Array[int] = []
	var last_start := -1
	for tick in 1500:
		zone.tick(FighterInput.new())
		if baron.state != Fighter.State.ATTACK or baron.move == null:
			continue
		var started := tick - baron.state_tick
		if started != last_start and baron.move.id == str(baron.moveset.get("heavy", "")):
			heavies.append(started)
		last_start = started
	assert_true(heavies.size() >= 2, "the Baron still uses his heavy (%d)" % heavies.size())
	for i in range(1, heavies.size()):
		assert_true(
			heavies[i] - heavies[i - 1] >= brain.heavy_cooldown_ticks,
			"heavies %d ticks apart" % (heavies[i] - heavies[i - 1])
		)
