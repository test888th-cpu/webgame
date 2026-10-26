extends TestCase
## Fair-fight rules for enemy attacks (docs/BLUEPRINT.md §10.1): anything an
## enemy opens with that floors the hero or breaks their guard is announced
## long enough to react, every announced attack leaves a window to punish,
## and every boss phase brings a new attack rather than only bigger numbers.

## Ticks of warning before a telegraphed attack lands (~0.27 s).
const MIN_WARNING := 16
## Ticks a telegraphed attack leaves its user open afterwards.
const MIN_PUNISH := 20

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Every enemy's opening moves (starters, including boss phases), as
## "enemy.slot" -> move id.
func _openers() -> Dictionary:
	var found := {}
	for enemy_id: String in _content().enemies:
		var enemy: Dictionary = _content().enemies[enemy_id]
		var sets: Array = [enemy.get("moveset", {})]
		for phase: Dictionary in enemy.get("phases", []):
			sets.append(phase.get("moveset", {}))
		for i in sets.size():
			for slot: String in sets[i]:
				found["%s.%s%s" % [enemy_id, slot, "" if i == 0 else str(i)]] = sets[i][slot]
	return found


func test_heavy_openers_are_telegraphed_in_time() -> void:
	var openers := _openers()
	for key: String in openers:
		var move := _content().moves.get_move(str(openers[key]))
		if not (move.knockdown or move.guard_break):
			continue
		assert_true(move.telegraph, "%s (%s) floors or breaks guard: telegraph it" % [key, move.id])
		assert_true(
			move.startup >= MIN_WARNING,
			"%s (%s): %d ticks of warning, need %d" % [key, move.id, move.startup, MIN_WARNING]
		)


func test_telegraphed_attacks_leave_a_punish_window() -> void:
	var openers := _openers()
	for key: String in openers:
		var move := _content().moves.get_move(str(openers[key]))
		if move.telegraph:
			assert_true(
				move.recovery >= MIN_PUNISH,
				"%s (%s): %d ticks to punish, need %d" % [key, move.id, move.recovery, MIN_PUNISH]
			)


func test_every_boss_phase_brings_a_new_attack() -> void:
	for enemy_id: String in _content().enemies:
		var enemy: Dictionary = _content().enemies[enemy_id]
		if not enemy.get("boss", false):
			continue
		var seen: Array = enemy.get("moveset", {}).values()
		assert_true(not enemy.get("phases", []).is_empty(), "%s has phases" % enemy_id)
		for i in enemy.get("phases", []).size():
			var moves: Array = enemy["phases"][i].get("moveset", {}).values()
			var fresh := moves.filter(func(m: Variant) -> bool: return m not in seen)
			assert_true(not fresh.is_empty(), "%s phase %d adds an attack" % [enemy_id, i + 1])
			seen.append_array(moves)


func test_a_charging_boss_starts_its_rush_from_range() -> void:
	# The Furnace Baron's second phase charges: the AI must start it from
	# out of plain reach, or the charge would never be seen.
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "refinery", "", 5)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone.hero.position = Vector2(400, 300)
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	var boss := zone.spawn_enemy("furnace_baron", Vector2(520, 300))
	boss.hp = boss.max_hp / 3
	var started_at := -1.0
	for i in 600:
		zone.tick(FighterInput.new())
		if boss.state == Fighter.State.ATTACK and boss.move.id == "baron_rush":
			started_at = absf(boss.position.x - zone.hero.position.x)
			break
	assert_true(started_at > 0.0, "the enraged Baron charges")
	assert_true(started_at > 40.0, "from range (%d px)" % started_at)
