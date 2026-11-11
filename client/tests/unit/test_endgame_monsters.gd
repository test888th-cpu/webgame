extends TestCase
## The 50-70 farming grounds' monsters: each ground mixes three different
## fighting roles (no two share a sprite, moveset and AI) and one elite, so a
## field is never a wall of one heavy kind (the Iron Heart's two heavies were
## where knock-outs came from); every one carries its tier's tint
## (enemies.json "tint"), which the validator checks.

const ENDGAME := ["farm_coolant_vaults", "farm_reactor_underworks", "farm_foundry_depths"]
const LAST := "farm_iron_heart"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _grounds() -> Array:
	var out: Array = ENDGAME.duplicate()
	out.append(LAST)
	return out


func test_each_ground_mixes_three_roles_and_one_elite() -> void:
	var c := _content()
	for gid: String in _grounds():
		var plain: Array = []
		var elites := 0
		var looks := {}
		for kind: String in c.area(gid)["spawning"]["pool"]:
			var enemy := c.enemy(kind)
			if enemy.get("elite", false):
				elites += 1
				continue
			plain.append(kind)
			var look := [enemy.get("sprite"), enemy.get("moveset"), enemy.get("ai")]
			assert_true(not looks.has(JSON.stringify(look)), "%s: %s is its own role" % [gid, kind])
			looks[JSON.stringify(look)] = true
		assert_eq(plain.size(), 3, gid + ": three kinds in the field")
		assert_eq(elites, 1, gid + ": one elite")


func test_every_endgame_monster_and_boss_is_tinted() -> void:
	var c := _content()
	for gid: String in _grounds():
		for kind: String in c.area(gid)["spawning"]["pool"]:
			assert_true(c.enemy(kind).has("tint"), kind + ": tinted")
	for lair_id in AreaRules.lairs(c):
		var boss := LairRules.boss(c, lair_id)
		assert_true(c.enemy(boss).has("tint"), boss + ": tinted")
	for boss: String in ["slag_titan", "iron_sovereign"]:
		assert_true(c.enemy(boss).has("tint"), boss + ": tinted")


func test_story_enemies_keep_their_own_colours() -> void:
	var c := _content()
	for area_id in StreetMemory.street(c):
		for encounter: Dictionary in c.area(area_id).get("encounters", []):
			for wave: Array in encounter["waves"]:
				for kind: String in wave:
					assert_true(not c.enemy(kind).has("tint"), kind + ": as before")


func test_the_validator_checks_a_tint() -> void:
	var copy := ContentDB.load_all()
	copy.enemies["vault_runner"]["tint"] = "not a colour"
	copy.errors.clear()
	copy.validate()
	assert_true("enemies.vault_runner.tint" in "\n".join(copy.errors), "a bad tint is caught")
