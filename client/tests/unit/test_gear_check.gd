extends TestCase
## The gear check (GearCheck): a boss asks for a gear score, and a hero short
## of it deals less and takes more, whatever their level or food.

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func _hero(level: int, gear: String, plus := 0) -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content(), "oren")
	profile.level = level
	if gear != "starter":
		for item_id in ProgressionHarness.gear(_content(), level, gear):
			profile.add_item(item_id)
			profile.equip(item_id, _content())
	for slot: String in PlayerProfile.SLOTS:
		var key := str(profile.equipment[slot])
		if key != "" and plus > 0:
			profile.enhance[key] = plus
	return profile


func test_the_score_counts_gear_and_its_upgrades() -> void:
	var bare := GearCheck.score(_hero(30, "starter"), _content())
	var shop := GearCheck.score(_hero(30, "shop"), _content())
	var upgraded := GearCheck.score(_hero(30, "shop", 5), _content())
	assert_true(bare < shop and shop < upgraded, "%d < %d < %d" % [bare, shop, upgraded])


func test_only_bosses_ask_and_later_ones_ask_more() -> void:
	assert_eq(GearCheck.required(_content(), "smogling", 10), 0, "a street enemy does not")
	var early := GearCheck.required(_content(), "sludge_foreman", 5)
	var late := GearCheck.required(_content(), "director_wiroj", 50)
	assert_true(early > 0 and late > early * 4, "%d then %d" % [early, late])
	var world := GearCheck.required(_content(), "iron_colossus", 52)
	assert_true(world > late, "a world boss asks most (%d)" % world)


func test_shop_gear_is_ready_early_but_not_for_the_finale() -> void:
	var foreman := GearCheck.required(_content(), "sludge_foreman", 5)
	assert_true(GearCheck.score(_hero(3, "shop"), _content()) >= foreman, "early: the shop's set")
	var director := GearCheck.required(_content(), "director_wiroj", 50)
	assert_true(GearCheck.score(_hero(48, "shop"), _content()) < director, "the finale wants more")
	assert_true(GearCheck.score(_hero(48, "shop", 5), _content()) >= director, "upgraded, ready")


func test_falling_short_deals_less_and_takes_more() -> void:
	assert_eq(GearCheck.dealt(_content(), 0.0), 1.0, "ready: no change")
	assert_eq(GearCheck.taken(_content(), 0.0), 1.0, "ready: no change")
	assert_true(GearCheck.dealt(_content(), 0.3) < 0.7, "short: weaker blows")
	assert_true(GearCheck.taken(_content(), 0.3) > 1.5, "short: harder hits")
	var floor := float(_content().progression["gear_check"]["min_deal"])
	assert_eq(GearCheck.dealt(_content(), 1.0), floor, "never below the floor")
	assert_eq(GearCheck.shortfall(800, 400), 0.0, "past the mark brings nothing extra")


func test_a_boss_checks_on_arrival_and_its_brood_does_not() -> void:
	var zone := ZoneSim.new(_content(), _hero(30, "starter"), "saltmarket", "", 1)
	var boss := zone.spawn_enemy("sludge_foreman", Vector2(600, 300))
	var thug := zone.spawn_enemy("smogling", Vector2(500, 300))
	assert_true(boss.hurt_scale < 1.0 and boss.hit_scale > 1.0, "starter clothes fall short")
	assert_eq(thug.hurt_scale, 1.0, "a street enemy is unchanged")
	assert_true(Hud.gear_check_text(zone, boss).begins_with("UNDER-GEARED"), "the boss bar says so")
	var move := _content().moves.get_move(
		str(CombatRules.starter(zone.hero, _content().moves, "light"))
	)
	var plain := maxi(1, roundi(move.damage * zone.hero.power) - boss.defense)
	assert_true(CombatRules.damage_for(move, zone.hero, boss) < plain, "the hero's blow is cut")


func test_levels_and_food_alone_lose_to_the_director() -> void:
	# Level 50 in starter clothes with a bag of tonics, the case that used to
	# win: now it falls; upgraded shop gear wins.
	var weak := _director("starter", 0)
	var ready := _director("shop", 5)
	assert_true(weak["ko"], "starter clothes fall short")
	assert_true(not ready["ko"] and ready["clear"], "upgraded gear wins")


func _director(gear: String, plus: int) -> Dictionary:
	var profile := _hero(50, gear, plus)
	profile.add_item("herbal_tonic", 10)
	ProgressionHarness._clear_all_but_boss(_content(), profile, "core_chamber")
	var zone := ZoneSim.new(_content(), profile, "core_chamber", "west", 1)
	zone.refresh_hero()
	zone.hero.hp = zone.hero.max_hp
	var pilot := AutoPilot.new(_content())
	for tick in 36000:
		var input := pilot.think(zone)
		if pilot.item:
			zone.use_item(pilot.item)
		zone.tick(input)
		if pilot.status == AutoPilot.STATUS_CLEAR or zone.hero.is_ko():
			break
	return {"ko": zone.hero.is_ko(), "clear": pilot.status == AutoPilot.STATUS_CLEAR}
