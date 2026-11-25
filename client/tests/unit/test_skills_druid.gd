extends SkillsCase
## The druid's port (docs/SKILLS_PORT.md): forms swap the bar and the sheet, the
## spec engines bank toward their payoffs, Nature's Boon, Spore Burst, Swiftmend,
## form entry, Bruin Rush's Pin and Typhoon.


func test_bear_and_cat_forms_swap_the_bar_and_park_the_mana() -> void:
	var f := _sturdy(_street(_char("druid", 12), [1.5]))
	var mana := float(f.player["resource"])
	var armor := int(f.player["armor"])
	var hp := int(f.player["max_hp"])
	assert_eq(_cast(f, "bear_form"), "", "Bruin Form")
	assert_eq(str(f.player["resource_type"]), "rage", "on rage")
	assert_near(float(f.player["resource"]), 0.0, "starting empty")
	assert_true(int(f.player["armor"]) > armor, "more armor")
	assert_true(int(f.player["max_hp"]) > hp, "a bigger pool")
	assert_near(float(f.player["saved_mana"]), mana - 30.0, "the mana parked (after the cost)")
	f.player["cooldowns"].clear()
	assert_eq(_cast(f, "cat_form"), "", "Cat Form across")
	assert_eq(str(f.player["resource_type"]), "energy", "on energy")
	assert_near(float(f.player["resource"]), 100.0, "a full bar out of combat")
	assert_eq(_cast(f, "claw"), "", "a cat strike in Cat Form")
	assert_eq(_cast(f, "cat_form"), "", "shift out")
	assert_eq(str(f.player["resource_type"]), "mana", "back on mana")


func test_cat_strikes_need_cat_form() -> void:
	var f := _sturdy(_street(_char("druid", 12), [1.5]))
	assert_eq(_cast(f, "claw"), "You must be in Cat Form.", "Claw outside Cat Form")


func test_feral_strikes_bank_old_blood_into_red_harvest() -> void:
	var f := _sturdy(_street(_char("druid", 20, "feral"), [1.5]))
	_cast(f, "cat_form")
	for i in 12:
		if RpgDruidEngine.stacks(f.player, "old_blood") >= 3:
			break
		f.player["cooldowns"].clear()
		_cast(f, "claw")
		f.run(2)
	assert_eq(RpgDruidEngine.stacks(f.player, "old_blood"), 3, "three stages")
	var k := f.known_entry("ferocious_bite")
	assert_eq(str(k["id"]), "redharvest", "Ferocious Bite becomes Red Harvest")


func test_balance_builders_bank_moontide_only_in_moonwing() -> void:
	var f := _sturdy(_street(_char("druid", 20, "balance"), [10.0]))
	f.player["mods"]["selected"] = {}
	RpgDruidEngine.on_cast(f, f.player, "wrath", f.mob)
	assert_eq(RpgDruidEngine.stacks(f.player, "moontide"), 0, "not outside Moonwing")
	_cast(f, "moonkin_form")
	for i in 3:
		RpgDruidEngine.on_cast(f, f.player, "wrath", f.mob)
	assert_eq(RpgDruidEngine.stacks(f.player, "moontide"), 3, "three stages")
	assert_eq(str(f.known_entry("starfire")["id"]), "sunlance", "Starfire becomes Sunlance")


func test_swiftmend_consumes_a_bloom_for_its_heal() -> void:
	var f := _street(_char("druid", 20, "restoration"), [40.0])
	f.player["hp"] = 50
	assert_eq(_cast(f, "swiftmend"), "", "the press goes out")
	assert_eq(int(f.player["hp"]), 50, "nothing to consume, no heal")
	f.player["cooldowns"].clear()
	_cast(f, "rejuvenation")
	f.player["gcd"] = 0.0
	assert_eq(_cast(f, "swiftmend"), "", "Swiftmend")
	assert_true(int(f.player["hp"]) > 50, "healed")
	assert_true(not _has_aura(f.player, "rejuvenation"), "the bloom consumed")


func test_spore_burst_bursts_on_its_fuse() -> void:
	var f := _sturdy(_street(_char("druid", 20, "balance"), [6.0]))
	f.player["hp"] = 100
	assert_eq(_cast(f, "spore_burst"), "", "Spore Burst")
	var hp := int(f.mob["hp"])
	f.run(int(5.0 / f.dt) + 2)
	assert_true(int(f.mob["hp"]) < hp, "the patch burst on the monster")
	assert_true(int(f.player["hp"]) > 100, "and healed the druid in it")


func test_prowl_shifts_into_cat_on_the_way() -> void:
	var f := _street(_char("druid", 12), [40.0])
	assert_eq(_cast(f, "prowl"), "", "Stalk from caster form")
	assert_true(RpgAbilityRules.has_kind(f.player, "form_cat"), "now a cat")
	assert_true(RpgStealth.is_stealthed(f.player), "and stealthed")


func test_bruin_rush_pins_through_a_cat_shift() -> void:
	var f := _sturdy(_street(_char("druid", 12), [15.0]))
	assert_eq(_cast(f, "bear_charge"), "", "Bruin Rush (shifts to Bruin)")
	assert_true(RpgDruid.bruin_rush_makes_cat_free(f.player, "cat_form"), "the window is open")
	f.player["cooldowns"].clear()
	assert_eq(_cast(f, "cat_form"), "", "Cat Form inside the window")
	assert_true(_has_aura(f.mob, "pin"), "the target is pinned")


func test_typhoon_throws_monsters_back_and_dazes() -> void:
	var f := _sturdy(_street(_char("druid", 12, "", {"11": "dru_r11_innervate"}), [3.0]))
	assert_eq(_cast(f, "typhoon"), "", "Typhoon")
	assert_near(float(f.mob["x"]), 18.0, "15 back along the street")
	assert_true(_has_aura(f.mob, "typhoon_daze"), "dazed")
