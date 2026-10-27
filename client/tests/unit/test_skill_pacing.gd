extends TestCase
## Skill pacing: heroes get their skills back quickly, while enemies and
## bosses must wait longer between their heavy blows than a hero waits for
## any skill short of an ultimate, so they cannot chain them back to back.

## A hero's regular skills come back within this many ticks, ultimates within
## ULTIMATE_MAX (60 ticks a second).
const SKILL_MAX := 270
const ULTIMATE_MAX := 780

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hero_skill_cooldowns(ultimate: bool) -> Array[int]:
	var out: Array[int] = []
	for hero_id: String in _content().hero_order:
		var skills: Array = _content().heroes[hero_id]["skills"]
		for i in skills.size():
			if (i == skills.size() - 1) == ultimate:
				out.append(int(_content().skills[str(skills[i])]["cooldown"]))
	return out


func test_hero_skills_come_back_quickly() -> void:
	for cooldown in _hero_skill_cooldowns(false):
		assert_true(cooldown <= SKILL_MAX, "a skill waits %d ticks" % cooldown)
	for cooldown in _hero_skill_cooldowns(true):
		assert_true(cooldown <= ULTIMATE_MAX, "an ultimate waits %d ticks" % cooldown)


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
