extends TestCase
## Skill combos (ComboRules): two routes per job, each completed by using its
## skills in order, each soon after the last lands. The finisher hits harder
## and fills the gauge; a miss, a hit taken or a pause breaks the chain. Every
## route can be completed by a player, the routes are balanced across jobs,
## and auto battle follows them.

const BOUNDS := Rect2(0, 200, 4000, 200)
## Comparable routes (the same tier) of different jobs deal, with each hero's
## power, within this share of the tier's mean.
const TIER_SPREAD := 0.15

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _press(field: String, value: Variant = true) -> FighterInput:
	var input := FighterInput.new()
	input.set(field, value)
	return input


## A level 70 `hero_id` and a sturdy foe in front that never attacks.
func _pair(hero_id: String) -> Array[Fighter]:
	var db := _content()
	var hero := Fighter.new(1, 1, Vector2(500, 300), 500)
	JobRules.equip(hero, db, hero_id)
	hero.skills = SkillRules.unlocked(db, hero_id, 70)
	hero.combos = ComboRules.unlocked(db, hero_id, 70)
	var foe := Fighter.new(2, 2, Vector2(524, 300), 100000)
	foe.facing = -1
	var fighters: Array[Fighter] = [hero, foe]
	return fighters


## Runs `ticks` ticks, `first` the first tick's inputs; returns the hits.
func _run(fighters: Array[Fighter], ticks: int, first := {}) -> Array[CombatEvent]:
	var hits: Array[CombatEvent] = []
	for t in ticks:
		var inputs: Dictionary = first if t == 0 else {}
		hits.append_array(CombatRules.tick(fighters, inputs, _content().moves, BOUNDS))
	return hits


## A level 70 `hero_id` in the empty yard with one sturdy dock thug, who
## fights back only when `fights`.
func _zone(hero_id: String, fights := false) -> ZoneSim:
	var db := _content()
	var profile := PlayerProfile.new_game(db, hero_id)
	profile.level = 70
	var zone := ZoneSim.new(db, profile, "depot_yard", "", 7)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
		zone.brains.erase(enemy.id)
	zone.hero.position = Vector2(300, 300)
	zone.hero.facing = 1
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	var foe := zone.spawn_enemy("dock_thug", Vector2(330, 300))
	foe.max_hp = 1000000
	foe.hp = 1000000
	if not fights:
		(zone.brains[foe.id] as EnemyBrain).cooldown = 1000000
	return zone


## What a player would press this tick to work through `route` on `foe`:
## the next skill once the foe is up and in reach (a stance just before its
## blow lands), any attack to throw what is held, else a step towards it.
func _player(zone: ZoneSim, route: Dictionary, foe: Fighter) -> FighterInput:
	var hero := zone.hero
	var input := FighterInput.new()
	if hero.state == Fighter.State.GRAB:
		input.light = true
	elif hero.state == Fighter.State.IDLE:
		var want := str(route["links"][0])
		for next in ComboRules.next_links(hero):
			if next in route["links"]:
				want = next
		var gap := foe.position - hero.position
		var dir := 1 if gap.x >= 0.0 else -1
		input.face = dir
		if absf(gap.y) > 4.0:
			input.move = Vector2(0, signf(gap.y))
		elif _ready_for(zone, want, foe, absf(gap.x)):
			input.skill = want
		elif absf(gap.x) > 24.0:
			input.move = Vector2(dir, 0)
		elif absf(gap.x) < 12.0:
			input.move = Vector2(-dir, 0)
	return input


## Whether pressing `skill_id` now, `distance` px from `foe`, would land: a
## stance just before the foe's blow lands; any other once the foe is up,
## close and the skill is ready.
func _ready_for(zone: ZoneSim, skill_id: String, foe: Fighter, distance: float) -> bool:
	var hero := zone.hero
	if hero.cooldown_left(skill_id) > 0:
		return false
	var first := _content().moves.get_move(str(hero.skills[skill_id]["move"]))
	if first.counter:
		var attacking := foe.state == Fighter.State.ATTACK and foe.move != null
		var due := foe.move.startup - foe.state_tick if attacking else -1
		return due >= first.startup + 1 and due <= first.startup + 4
	return CombatRules.is_vulnerable(foe) and distance >= 12.0 and distance <= 24.0


func test_every_job_has_an_early_and_a_late_route() -> void:
	var db := _content()
	assert_true(db.is_valid(), "content loads: %s" % ", ".join(db.errors))
	for job_id: String in db.job_order:
		var routes: Array = db.jobs[job_id]["skill_combos"]
		assert_eq(routes.size(), 2, job_id + ": two routes")
		assert_eq(int(routes[0]["unlock_level"]), 3, job_id + ": the first from Lv 3")
		assert_eq((routes[0]["links"] as Array).size(), 2, job_id + ": of two skills")
		assert_eq(int(routes[1]["unlock_level"]), 30, job_id + ": the second from Lv 30")
		assert_eq((routes[1]["links"] as Array).size(), 3, job_id + ": of three skills")
		assert_eq(ComboRules.problems(db, job_id), PackedStringArray(), job_id + ": valid")
	assert_eq(ComboRules.unlocked(db, "riku", 2).size(), 0, "none before Lv 3")
	assert_eq(ComboRules.unlocked(db, "riku", 29).size(), 1, "one from Lv 3")
	assert_eq(ComboRules.unlocked(db, "riku", 30).size(), 2, "both from Lv 30")


func test_every_route_can_be_completed_by_a_player() -> void:
	var db := _content()
	for hero_id: String in db.hero_order:
		var job := JobRules.job_of(db, hero_id)
		for route: Dictionary in db.jobs[job]["skill_combos"]:
			var stance := false
			for skill_id: Variant in route["links"]:
				var move := db.moves.get_move(str(db.skills[str(skill_id)]["move"]))
				stance = stance or move.counter
			var zone := _zone(hero_id, stance)
			var foe: Fighter = zone.enemies()[0]
			var done := ""
			var ticks := 0
			while ticks < 3000 and done == "":
				ticks += 1
				for event in zone.tick(_player(zone, route, foe)):
					if event.type == "combo" and event.data["id"] == zone.hero.id:
						done = str(event.data["combo"])
			assert_eq(done, str(route["id"]), "%s completes %s" % [hero_id, route["id"]])


func test_the_finisher_hits_harder_and_fills_the_gauge() -> void:
	var fighters := _pair("riku")
	var hero := fighters[0]
	var route: Dictionary = hero.combos[0]
	assert_eq(route["links"], ["power_jab", "heavy_cross"], "the Boxer's One-Two")
	var cross := _content().moves.get_move("heavy_cross")
	_run(fighters, 1, {1: _press("skill", "heavy_cross")})
	var plain := CombatRules.damage_for(cross, hero, fighters[1])
	assert_eq(hero.combo_chain, [], "Heavy Cross alone starts no route")
	_run(fighters, 300)
	hero.cooldowns.clear()
	hero.gauge = 0.0
	fighters[1].position.x = 524
	var hits := _run(fighters, 40, {1: _press("skill", "power_jab")})
	assert_eq(hits.size(), 1, "the jab lands")
	assert_eq(ComboRules.next_links(hero), ["heavy_cross"] as Array[String], "the cross is next")
	fighters[1].position.x = 524
	var events := _run(fighters, 1, {1: _press("skill", "heavy_cross")})
	assert_true(not hero.combo_finish.is_empty(), "the cross finishes the route")
	var bonus := float(route["bonus"])
	assert_eq(
		CombatRules.damage_for(cross, hero, fighters[1]),
		maxi(1, roundi(cross.damage * hero.power * (1.0 + bonus)) - fighters[1].defense),
		"and hits %d%% harder" % roundi(bonus * 100.0)
	)
	assert_true(CombatRules.damage_for(cross, hero, fighters[1]) > plain, "than without it")
	events.append_array(_run(fighters, 40))
	assert_eq(hero.combo_done, "one_two", "the route is completed")
	var per_hit := float(_content().job_gauge["per_hit"])
	assert_near(hero.gauge, per_hit * 2 + float(route["gauge"]), "and pays its gauge", 0.01)
	var jab := _content().moves.get_move("power_jab")
	hero.combo_done = ""
	assert_eq(
		CombatRules.damage_for(jab, hero, fighters[1]),
		maxi(1, roundi(jab.damage * hero.power) - fighters[1].defense),
		"no other skill gets the bonus"
	)


func test_a_pause_a_miss_or_a_blow_taken_breaks_the_chain() -> void:
	var slow := _pair("riku")
	_run(slow, 30, {1: _press("skill", "power_jab")})
	assert_true(not ComboRules.next_links(slow[0]).is_empty(), "a route is open")
	_run(slow, int(slow[0].combos[0]["window"]) + 5)
	assert_true(ComboRules.next_links(slow[0]).is_empty(), "too slow: it closes")
	var missed := _pair("riku")
	missed[1].position.x = 900
	_run(missed, 30, {1: _press("skill", "power_jab")})
	assert_true(ComboRules.next_links(missed[0]).is_empty(), "a miss opens nothing")
	var hurt := _pair("riku")
	_run(hurt, 30, {1: _press("skill", "power_jab")})
	hurt[1].position.x = 524
	hurt[1].moveset = {"light": "thug_jab"}
	_run(hurt, 20, {2: _press("light")})
	assert_true(hurt[0].hp < hurt[0].max_hp, "the hero is hit")
	assert_true(ComboRules.next_links(hurt[0]).is_empty(), "and the chain is broken")
	assert_eq(hurt[0].hit_chain, 0, "the hit chain too")


func test_a_wrong_skill_starts_over() -> void:
	var fighters := _pair("riku")
	var hero := fighters[0]
	_run(fighters, 30, {1: _press("skill", "power_jab")})
	_run(fighters, 40, {1: _press("skill", "uppercut")})
	assert_eq(hero.combo_chain, [], "Uppercut is in no route: the chain is gone")
	_run(fighters, 60)
	hero.cooldowns.clear()
	fighters[1].position.x = 520
	_run(fighters, 30, {1: _press("skill", "body_blow")})
	assert_eq(hero.combo_chain, ["body_blow"], "Body Blow opens the late route")
	assert_eq(ComboRules.next_links(hero), ["power_jab"] as Array[String], "the jab is next")


func test_the_hit_chain_counts_blows_in_a_row() -> void:
	var fighters := _pair("mika")
	var hero := fighters[0]
	_run(fighters, 12, {1: _press("light")})
	assert_eq(hero.hit_chain, 1, "one blow")
	_run(fighters, 12, {1: _press("light")})
	assert_eq(hero.hit_chain, 2, "two in a row")
	_run(fighters, ComboRules.HIT_CHAIN_TICKS + 2)
	assert_eq(hero.hit_chain, 0, "a pause ends it")
	assert_eq(fighters[1].hit_chain, 0, "enemies keep no chain")


func test_routes_are_balanced_across_jobs() -> void:
	var db := _content()
	var means: Array[float] = []
	for tier in 2:
		var values := {}
		var sum := 0.0
		for hero_id: String in db.hero_order:
			var job := JobRules.job_of(db, hero_id)
			var route: Dictionary = db.jobs[job]["skill_combos"][tier]
			var power := float(db.hero(hero_id)["stats"]["power"])
			values[hero_id] = ComboRules.route_damage(db, job, route) * power
			sum += values[hero_id]
		var mean := sum / values.size()
		means.append(mean)
		for hero_id: String in values:
			var off := absf(values[hero_id] - mean) / mean
			assert_true(
				off <= TIER_SPREAD,
				(
					"tier %d: %s's route deals %d, %d%% from the mean %d"
					% [tier + 1, hero_id, values[hero_id], roundi(off * 100.0), mean]
				)
			)
	assert_true(means[1] > means[0] * 1.4, "the late routes are worth clearly more")


func test_pvp_halves_the_bonus_and_pve_keeps_it() -> void:
	var db := _content()
	var pve := ComboRules.unlocked(db, "riku", 70)
	var pvp := ComboRules.unlocked(db, "riku", 70, BalanceProfile.PVP)
	for i in pve.size():
		assert_near(float(pvp[i]["bonus"]), float(pve[i]["bonus"]) * 0.5, "PvP half", 0.001)
	var raw: Dictionary = db.jobs["boxer"]["skill_combos"][0]
	assert_near(float(pve[0]["bonus"]), float(raw["bonus"]), "PvE as written")


func test_bad_routes_are_refused() -> void:
	var db := ContentDB.load_all()
	var routes: Array = db.jobs["boxer"]["skill_combos"]
	routes[0]["links"] = ["power_jab", "knockout_devastation"]
	routes[1]["links"] = ["power_jab"]
	routes[0]["window"] = 5
	routes[1]["bonus"] = 3.0
	routes[1]["unlock_level"] = 1
	var found := ", ".join(ComboRules.problems(db, "boxer"))
	for part: String in [
		"knockout_devastation is not an active skill", "links: 2 to 3", "window", "bonus"
	]:
		assert_true(part in found, "%s: %s" % [part, found])
	routes[0]["links"] = ["power_jab", "heavy_cross"]
	routes[1]["links"] = ["power_jab", "heavy_cross", "knockout_combo"]
	found = ", ".join(ComboRules.problems(db, "boxer"))
	assert_true("is the start of another route" in found, "no route inside another: " + found)
	routes[1]["links"] = ["body_blow", "power_jab", "knockout_combo"]
	routes[1]["unlock_level"] = 5
	found = ", ".join(ComboRules.problems(db, "boxer"))
	assert_true("unlock_level: at least 30" in found, "not before its last skill: " + found)


func test_auto_battle_completes_combos_for_every_job() -> void:
	var db := _content()
	for hero_id: String in db.hero_order:
		var zone := _zone(hero_id, true)
		var pilot := AutoPilot.new(db)
		var done := {}
		for t in 3600:
			var input := pilot.think(zone)
			if pilot.item:
				zone.use_item(pilot.item)
			for event in zone.tick(input):
				if event.type == "combo" and event.data["id"] == zone.hero.id:
					done[event.data["combo"]] = true
		assert_true(
			not done.is_empty(), "%s's auto battle completes a combo (%s)" % [hero_id, done]
		)


func test_the_skills_screen_lists_the_routes() -> void:
	var db := _content()
	var profile := PlayerProfile.new_game(db, "kan")
	var box := SkillsScreen._combos(db, profile)
	for route: Dictionary in db.jobs["brawler"]["skill_combos"]:
		var line := box.find_child("Combo_" + str(route["id"]), false, false) as Label
		assert_true(line != null, "%s is listed" % route["id"])
		assert_true(line.text.begins_with("Lv %d" % route["unlock_level"]), "with its level")
	box.free()


## The game scene for a new Riku, laid out at the 16:9 base size.
func _game() -> Game:
	SaveStore.root = "user://test_combo_save"
	SaveStore.delete_all()
	GameSession.start_new_game("riku")
	tree.root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_a_level_up_names_the_combo_it_opens() -> void:
	var game := _game()
	var hud := game.get_node("Hud")
	game.profile.level = 3
	hud.level_up(3, [])
	var detail: String = hud._banner_detail.text
	assert_true(detail.contains("New combo: One-Two"), "Lv 3 opens One-Two: " + detail)
	hud.level_up(4, [])
	assert_true(not hud._banner_detail.text.contains("combo"), "Lv 4 opens none")
	game.zone.hero.hit_chain = 5
	hud.show_combo("One-Two")
	await tree.process_frame
	assert_eq(hud._chain.text, "5 HITS", "the hit chain shows")
	assert_eq(hud._combo.text, "ONE-TWO!", "and the completed route")
	_done(game)


func test_the_hotbar_lights_the_next_skill_of_a_route() -> void:
	var game := _game()
	var hero := game.zone.hero
	hero.combos = ComboRules.unlocked(game.content, "riku", 70)
	hero.combo_chain = ["power_jab"]
	hero.combo_landed = true
	hero.combo_timer = 60
	await tree.process_frame
	var hotbar: Hotbar = game.get_node("Hud").find_child("Hotbar", true, false)
	var lit := []
	for i in hotbar.slots.size():
		if hotbar.slots[i].linked:
			lit.append(hotbar.entries[i]["id"])
	assert_eq(lit, ["heavy_cross"], "only Heavy Cross is lit")
	_done(game)
