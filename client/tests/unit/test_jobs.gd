extends TestCase
## Jobs (jobs.json, JobRules) and per-mode balance (BalanceProfile): five jobs
## with one hero each, the unlock levels of a kit, kits checked on load,
## player skills kept apart from enemy moves, and PvE and PvP tuned apart.


func _fresh() -> ContentDB:
	return ContentDB.load_all()


## A job skill of `type` unlocking at `level`, built on an existing skill.
func _job_skill(db: ContentDB, job: String, type: String, level: int) -> Dictionary:
	var skill: Dictionary = db.skills["liver_shot"].duplicate(true)
	skill["job"] = job
	skill["type"] = type
	skill["unlock_level"] = level
	skill["profiles"] = {"pve": {}, "pvp": {"damage": 0.6}}
	return skill


## Gives the Boxer a whole kit at the levels jobs.json asks for.
func _build_boxer_kit(db: ContentDB) -> void:
	var kit := []
	for type: String in JobRules.KIT:
		for index in int(JobRules.KIT[type]):
			var id := "boxer_%s_%d" % [type, index]
			var level := JobRules.unlock_level(db, type, index)
			db.skills[id] = _job_skill(db, "boxer", type, level)
			kit.append(id)
	db.jobs["boxer"]["skills"] = kit


func test_five_jobs_each_have_their_own_hero() -> void:
	var db := _fresh()
	assert_true(db.is_valid(), "content loads: %s" % ", ".join(db.errors))
	assert_eq(db.job_order, ["boxer", "brawler", "grappler", "counter", "striker"], "five jobs")
	var pairs := {
		"riku": "boxer", "kan": "brawler", "oren": "grappler", "dao": "counter", "mika": "striker"
	}
	for hero_id: String in pairs:
		assert_eq(JobRules.job_of(db, hero_id), pairs[hero_id], hero_id + "'s job")
		assert_eq(JobRules.hero_of(db, pairs[hero_id]), hero_id, pairs[hero_id] + "'s hero")
	assert_eq(db.hero_order.size(), db.job_order.size(), "as many heroes as jobs")
	assert_eq(JobRules.job_of(db, "nobody"), "", "an unknown hero has no job")


func test_a_kit_unlocks_at_the_agreed_levels() -> void:
	var db := _fresh()
	assert_eq(db.job_unlocks["active"], [1.0, 10.0, 20.0, 25.0, 35.0, 40.0], "six actives")
	assert_eq(db.job_unlocks["passive"], [15.0, 30.0], "two passives")
	assert_eq(JobRules.unlock_level(db, "ultimate", 0), 50, "the ultimate at 50, not the cap")
	assert_eq(JobRules.unlock_level(db, "ultimate", 1), 0, "and only one")


func test_two_heroes_cannot_share_a_job() -> void:
	var db := _fresh()
	db.heroes["mika"]["job"] = "boxer"
	var found := ", ".join(JobRules.problems(db))
	assert_true("jobs.boxer: expected exactly one hero, found 2" in found, "two Boxers: " + found)
	assert_true("jobs.striker: expected exactly one hero, found 0" in found, "no Striker")
	db.heroes["mika"]["job"] = "wizard"
	assert_true("heroes.mika.job: unknown job" in ", ".join(JobRules.problems(db)), "unknown job")


func test_a_whole_kit_passes_and_a_partial_one_does_not() -> void:
	var db := _fresh()
	_build_boxer_kit(db)
	assert_eq(JobRules.problems(db), PackedStringArray(), "6 active, 2 passive, 1 ultimate")
	var kit: Array = db.jobs["boxer"]["skills"]
	var dropped: String = kit.pop_back()
	db.skills.erase(dropped)
	var found := ", ".join(JobRules.problems(db))
	assert_true("jobs.boxer.skills: expected" in found, "a kit one short is refused: " + found)


func test_a_kit_must_follow_the_unlock_levels() -> void:
	var db := _fresh()
	_build_boxer_kit(db)
	db.skills["boxer_ultimate_0"]["unlock_level"] = 70
	var found := ", ".join(JobRules.problems(db))
	assert_true("ultimate must unlock at levels [50]" in found, "an ultimate at 70: " + found)


func test_a_job_skill_needs_both_balance_profiles() -> void:
	var db := _fresh()
	_build_boxer_kit(db)
	db.skills["boxer_active_0"]["profiles"].erase("pvp")
	var found := ", ".join(JobRules.problems(db))
	assert_true("skills.boxer_active_0.profiles.pvp: required" in found, "no PvP: " + found)
	db.skills["boxer_active_0"]["profiles"] = {"pve": {"luck": 2}, "pvp": {"damage": 0}}
	found = ", ".join(JobRules.problems(db))
	assert_true("unknown field luck" in found, "an unknown field: " + found)
	assert_true("profiles.pvp.damage: expected a number above 0" in found, "a zero multiplier")


func test_player_skills_and_enemy_moves_never_mix() -> void:
	var db := _fresh()
	var hostile := JobRules.enemy_moves(db)
	assert_true(hostile.has("brute_slam"), "enemy moves are found")
	for skill_id: String in db.skills:
		var move := str(db.skills[skill_id]["move"])
		assert_true(not hostile.has(move), "%s is the player's alone" % skill_id)
	db.skills["liver_shot"]["move"] = "brute_slam"
	var found := ", ".join(JobRules.problems(db))
	assert_true("skills.liver_shot.move: brute_slam is an enemy's move" in found, found)


func test_modes_are_tuned_apart() -> void:
	var skill := {"cooldown": 600, "profiles": {"pve": {}, "pvp": {"damage": 0.6, "cooldown": 1.5}}}
	assert_near(BalanceProfile.scale(skill, "pve", "damage"), 1.0, "PvE untouched")
	assert_near(BalanceProfile.scale(skill, "pvp", "damage"), 0.6, "PvP scaled")
	assert_eq(BalanceProfile.cooldown(skill, "pve"), 600, "PvE cooldown as written")
	assert_eq(BalanceProfile.cooldown(skill, "pvp"), 900, "PvP cooldown longer")
	assert_near(BalanceProfile.scale({"cooldown": 5}, "pvp", "damage"), 1.0, "no profiles: 1.0")


func test_the_zone_uses_the_pve_profile_and_old_skills_are_unchanged() -> void:
	var db := _fresh()
	var before: Dictionary = SkillRules.unlocked(db, "riku", 70)
	assert_eq(
		int(before["liver_shot"]["cooldown"]), int(db.skills["liver_shot"]["cooldown"]), "same"
	)
	db.skills["liver_shot"]["profiles"] = {"pve": {"cooldown": 2.0}, "pvp": {"cooldown": 9.0}}
	var after: Dictionary = SkillRules.unlocked(db, "riku", 70)
	assert_eq(
		int(after["liver_shot"]["cooldown"]), 2 * int(db.skills["liver_shot"]["cooldown"]), "PvE"
	)


## The moves the light button walks through for `job`, from its first punch.
func _combo(db: ContentDB, job: String) -> Array[MoveData]:
	var chain: Array[MoveData] = []
	var id := str(db.jobs[job]["moveset"]["light"])
	while id != "" and chain.size() < 8:
		var move := db.moves.get_move(id)
		chain.append(move)
		id = str(move.chains.get("light", ""))
	return chain


func _total(chain: Array[MoveData]) -> int:
	var sum := 0
	for move in chain:
		sum += move.damage
	return sum


func test_each_hero_fights_with_their_job_s_own_punches() -> void:
	var db := _fresh()
	var starters := {}
	for hero_id: String in db.hero_order:
		var zone := ZoneSim.new(db, PlayerProfile.new_game(db, hero_id), "depot_yard", "", 1)
		var light := CombatRules.starter(zone.hero, db.moves, "light")
		assert_eq(light, str(db.jobs[JobRules.job_of(db, hero_id)]["moveset"]["light"]), hero_id)
		assert_true(CombatRules.starter(zone.hero, db.moves, "heavy") != "", hero_id + ": a heavy")
		starters[light] = true
	assert_eq(starters.size(), db.hero_order.size(), "no two jobs open with the same punch")


func test_the_combos_are_three_punches_and_the_striker_s_four() -> void:
	var db := _fresh()
	for job: String in ["boxer", "brawler", "grappler", "counter"]:
		assert_eq(_combo(db, job).size(), 3, job + ": three punches")
	assert_eq(_combo(db, "striker").size(), 4, "the Striker: jab, cross, rapid jab, finisher")
	for job: String in db.job_order:
		var chain := _combo(db, job)
		for move in chain:
			assert_true(move.chains.has("heavy"), "%s: %s can end in the heavy" % [job, move.id])


func test_each_combo_shows_its_job() -> void:
	var db := _fresh()
	var boxer := _combo(db, "boxer")
	var brawler := _combo(db, "brawler")
	var counter := _combo(db, "counter")
	var striker := _combo(db, "striker")
	assert_true(_total(boxer) > _total(counter), "the Counter Fighter's basics hit less")
	assert_true(boxer[2].damage > striker[3].damage, "no Striker punch matches the Boxer's last")
	assert_true(not boxer[2].knockdown, "the Boxer's last blow staggers; the foe stays up")
	assert_true(boxer[0].reach > striker[0].reach, "the Boxer's jab reaches furthest")
	for i in 3:
		assert_true(
			brawler[i].depth_tolerance > boxer[i].depth_tolerance, "the Brawler swings wider"
		)
	assert_true(brawler[2].knockback > boxer[2].knockback, "and shoves harder")
	assert_true(
		striker[0].total_ticks() < boxer[0].total_ticks(), "the Striker's jab is the quickest"
	)
	for move in striker:
		assert_true(move.damage <= boxer[1].damage + 2, "the Striker's punches are light")


func test_a_job_s_punches_are_never_an_enemy_s() -> void:
	var db := _fresh()
	db.jobs["boxer"]["moveset"]["light"] = "brute_slam"
	var found := ", ".join(JobRules.problems(db))
	assert_true("jobs.boxer.moveset: brute_slam is an enemy's move" in found, found)
	db.jobs["boxer"]["moveset"] = {"light": "nothing"}
	found = ", ".join(JobRules.problems(db))
	assert_true("jobs.boxer.moveset.light: unknown move" in found, "unknown move: " + found)
	assert_true("jobs.boxer.moveset.heavy: unknown move" in found, "no heavy")
