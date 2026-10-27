extends TestCase
## Slot upgrades: costs and chances come from data, an attempt is all or
## nothing, failure never loses the item or the level and raises the next
## chance, upgrades follow the slot through gear changes, and saves keep
## them (version 5).

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Mika in a Work Jacket (body) with plenty to spend.
func _profile() -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content(), "mika")
	profile.level = 10
	profile.add_item("work_jacket")
	profile.equip("work_jacket", _content())
	profile.money = 100000
	profile.add_item("scrap_metal", 99)
	profile.add_item("refined_alloy", 99)
	return profile


## A generator whose next randf() is below (lucky) or above (unlucky) `p`.
func _rng(lucky: bool) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	for seed in range(1, 500):
		rng.seed = seed
		var roll := rng.randf()
		if (roll < 0.05) == lucky and (lucky or roll > 0.95):
			rng.seed = seed
			return rng
	return rng


func test_a_success_raises_the_worn_item_and_pays_once() -> void:
	var profile := _profile()
	var cost := EnhanceRules.next_cost(profile, "body", _content())
	var money := profile.money
	var scrap := profile.count("scrap_metal")
	var outcome := EnhanceRules.attempt(profile, "body", _content(), _rng(true))
	assert_eq(outcome["result"], "success", "succeeded")
	assert_eq(EnhanceRules.level(profile, "body"), 1, "+1")
	assert_eq(profile.money, money - int(cost["coins"]), "paid the coins once")
	assert_eq(profile.count("scrap_metal"), scrap - int(cost["items"]["scrap_metal"]), "and scrap")


func test_a_failure_keeps_everything_but_the_cost_and_adds_pity() -> void:
	var profile := _profile()
	profile.enhance["work_jacket"] = 5
	var before := EnhanceRules.chance(profile, "body", _content())
	var outcome := EnhanceRules.attempt(profile, "body", _content(), _rng(false))
	assert_eq(outcome["result"], "fail", "failed")
	assert_eq(EnhanceRules.level(profile, "body"), 5, "the level stays")
	assert_eq(profile.equipment["body"], "work_jacket", "the item stays")
	assert_true(EnhanceRules.chance(profile, "body", _content()) > before, "next try is better")
	EnhanceRules.attempt(profile, "body", _content(), _rng(true))
	assert_eq(profile.enhance_pity.get("work_jacket", 0), 0, "pity resets on success")


func test_short_of_coins_or_materials_changes_nothing() -> void:
	var profile := _profile()
	profile.money = 0
	var before := profile.to_dict()
	assert_eq(EnhanceRules.attempt(profile, "body", _content(), _rng(true))["result"], "coins", "")
	assert_eq(profile.to_dict(), before, "nothing spent")
	profile.money = 100000
	profile.inventory.erase("scrap_metal")
	assert_eq(
		EnhanceRules.attempt(profile, "body", _content(), _rng(true))["result"], "materials", ""
	)
	profile.equipment["head"] = ""
	assert_eq(
		EnhanceRules.attempt(profile, "head", _content(), _rng(true))["result"], "empty", "no hat"
	)


func test_the_top_level_is_final() -> void:
	var profile := _profile()
	profile.enhance["work_jacket"] = EnhanceRules.max_level(_content())
	assert_true(EnhanceRules.next_cost(profile, "body", _content()).is_empty(), "no next level")
	assert_eq(EnhanceRules.attempt(profile, "body", _content(), _rng(true))["result"], "max", "")


func test_upgrades_add_stats_and_stay_with_the_item() -> void:
	var profile := _profile()
	var plain := profile.stats(_content())
	profile.enhance["work_jacket"] = 10
	var tuned := profile.stats(_content())
	assert_true(tuned["defense"] > plain["defense"], "+10 adds defense")
	assert_true(tuned["max_hp"] > plain["max_hp"], "and HP")
	profile.add_item("riveted_jacket")
	profile.equip("riveted_jacket", _content())
	assert_eq(EnhanceRules.level(profile, "body"), 0, "the new jacket is +0")
	assert_eq(EnhanceRules.item_level(profile, "work_jacket"), 10, "the old one is still +10")
	profile.unequip("body", _content())
	assert_eq(EnhanceRules.level(profile, "body"), 0, "an empty slot shows no upgrade")
	profile.equip("work_jacket", _content())
	assert_eq(profile.stats(_content()), tuned, "worn again, the +10 is back")


func test_penalties_are_never_amplified() -> void:
	var profile := _profile()
	profile.add_item("rebar_pipe")
	profile.equip("rebar_pipe", _content())
	profile.enhance["rebar_pipe"] = 10
	var extra := EnhanceRules.bonus(profile, "weapon", _content().item("rebar_pipe"), _content())
	assert_true(not extra.has("speed"), "the pipe's speed penalty stays as it is")


func test_saves_keep_upgrades_and_old_saves_move_them_to_the_item() -> void:
	var profile := _profile()
	profile.enhance["work_jacket"] = 4
	profile.enhance_pity["work_jacket"] = 2
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	assert_eq(loaded.enhance, {"work_jacket": 4}, "level kept")
	assert_eq(loaded.enhance_pity, {"work_jacket": 2}, "pity kept")
	var old := profile.to_dict()
	old["version"] = 4
	old.erase("enhance")
	old.erase("enhance_pity")
	assert_eq(PlayerProfile.from_dict(old, _content()).enhance, {}, "a v4 save starts at +0")
	var v8 := profile.to_dict()
	v8["version"] = 8
	v8["enhance"] = {"body": 6, "head": 3}
	v8["enhance_pity"] = {"body": 1}
	v8["equipment"]["head"] = ""
	var moved := PlayerProfile.from_dict(v8, _content())
	assert_eq(moved.enhance, {"work_jacket": 6}, "a slot's level moves to what was worn there")
	assert_eq(moved.enhance_pity, {"work_jacket": 1}, "and its pity")
	var hacked := profile.to_dict()
	hacked["enhance"] = {"work_jacket": 99, "nose": 3, "steamed_bun": 2}
	assert_eq(
		PlayerProfile.from_dict(hacked, _content()).enhance,
		{"work_jacket": EnhanceRules.max_level(_content())},
		"clamped; only equipment keeps upgrades"
	)


func test_costs_rise_and_chances_fall() -> void:
	var levels: Array = _content().progression["enhance"]["levels"]
	for i in range(1, levels.size()):
		assert_true(int(levels[i]["coins"]) > int(levels[i - 1]["coins"]), "coins rise at %d" % i)
		assert_true(
			float(levels[i]["rate"]) <= float(levels[i - 1]["rate"]), "rate falls at %d" % i
		)
	assert_true(_content().is_valid(), ", ".join(_content().errors))


func test_the_workbench_upgrades_from_the_item_card() -> void:
	SaveStore.path = "user://test_enhance_save.json"
	SaveStore.delete()
	GameSession.start_new_game("mika")
	var game: Node2D = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var profile: PlayerProfile = game.profile
	profile.money = 100000
	profile.add_item("scrap_metal", 50)
	var slot := ""
	for name: String in PlayerProfile.SLOTS:
		if profile.equipment[name] and not slot:
			slot = name
	game.open_inventory()
	game.inspect_item(profile.equipment[slot], slot)
	var card_text := _texts(game.item_card)
	assert_true(card_text.contains("UPGRADE"), "the card offers an upgrade")
	assert_true(card_text.contains("100% chance"), "and says the odds")
	game._upgrade(slot)
	assert_eq(EnhanceRules.level(profile, slot), 1, "+1 at the Depot")
	game._upgrade(slot)
	assert_eq(EnhanceRules.level(profile, slot), 1, "a double press is ignored")
	assert_true(SaveStore.has_save(), "saved")
	var item_id: String = profile.equipment[slot]
	assert_eq(PlayerProfile.from_dict(_saved(), game.content).enhance.get(item_id), 1, "on disk")
	var worn: ItemSlot = game.menu.find_child("Worn_" + slot, true, false)
	assert_eq(worn.upgrade, 1, "the slot shows +1 at once, without reopening the menu")
	game.close_item_card()
	game._unequip(slot)
	worn = game.menu.find_child("Worn_" + slot, true, false)
	assert_eq(worn.upgrade, 0, "taken off, the empty slot shows no upgrade")
	var bag: ItemSlot = game.menu.find_child("Bag_" + item_id, true, false)
	assert_eq(bag.upgrade, 1, "the +1 went to the bag with the item")
	game.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _saved() -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(SaveStore.path))


func _texts(root: Node) -> String:
	var parts: Array[String] = []
	for label: Label in root.find_children("*", "Label", true, false):
		parts.append(label.text)
	return " | ".join(parts)
