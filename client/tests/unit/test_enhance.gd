extends TestCase
## Upgrades: costs and chances come from data, an attempt is all or
## nothing, failure never loses the item or the level and raises the next
## chance, an upgrade belongs to the one copy that was upgraded and follows
## it through gear changes, and saves keep them (versions 5, 9 and 10).

const GAME_SCENE := preload("res://scenes/game/Game.tscn")

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
	var copy := profile.own_copy("body")
	profile.enhance[copy] = 5
	var before := EnhanceRules.chance(profile, "body", _content())
	var outcome := EnhanceRules.attempt(profile, "body", _content(), _rng(false))
	assert_eq(outcome["result"], "fail", "failed")
	assert_eq(EnhanceRules.level(profile, "body"), 5, "the level stays")
	assert_eq(profile.equipment["body"], copy, "the item stays")
	assert_true(EnhanceRules.chance(profile, "body", _content()) > before, "next try is better")
	EnhanceRules.attempt(profile, "body", _content(), _rng(true))
	assert_eq(profile.enhance_pity.get(copy, 0), 0, "pity resets on success")


func test_identical_copies_keep_their_own_upgrades() -> void:
	var profile := _profile()
	profile.add_item("work_jacket", 2)
	EnhanceRules.attempt(profile, "body", _content(), _rng(true))
	var copy: String = profile.equipment["body"]
	assert_eq(copy, "work_jacket#1", "the upgraded jacket became a copy of its own")
	assert_eq(EnhanceRules.level(profile, "body"), 1, "it is +1")
	assert_eq(profile.count("work_jacket"), 2, "the two in the bag are still a stack")
	assert_eq(EnhanceRules.item_level(profile, "work_jacket"), 0, "and still +0")
	assert_eq(profile.owned("work_jacket"), 3, "three jackets in all")
	assert_eq(_content().item(copy)["name"], "Work Jacket", "the copy is a Work Jacket")
	profile.equip("work_jacket", _content())
	assert_eq(EnhanceRules.level(profile, "body"), 0, "another jacket on: +0")
	assert_eq(profile.count(copy), 1, "the +1 is back in the bag, on its own")
	EnhanceRules.attempt(profile, "body", _content(), _rng(true))
	assert_eq(profile.equipment["body"], "work_jacket#2", "a second copy of its own")
	assert_eq(EnhanceRules.item_level(profile, copy), 1, "the first keeps its +1")


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
	var copy := profile.own_copy("body")
	profile.enhance[copy] = 4
	profile.enhance_pity[copy] = 2
	var loaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	assert_eq(loaded.equipment["body"], copy, "the copy is still worn")
	assert_eq(loaded.enhance, {copy: 4}, "level kept")
	assert_eq(loaded.enhance_pity, {copy: 2}, "pity kept")
	profile.equipment["body"] = "work_jacket"
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
	assert_eq(moved.enhance, {"work_jacket#1": 6}, "a slot's level moves to what was worn there")
	assert_eq(moved.enhance_pity, {"work_jacket#1": 1}, "and its pity")
	var hacked := profile.to_dict()
	hacked["equipment"]["body"] = "work_jacket#1"
	hacked["enhance"] = {"work_jacket#1": 99, "nose": 3, "steamed_bun#1": 2}
	hacked["inventory"]["work_jacket#7"] = 50
	var cleaned := PlayerProfile.from_dict(hacked, _content())
	assert_eq(
		cleaned.enhance,
		{"work_jacket#1": EnhanceRules.max_level(_content())},
		"clamped; only equipment keeps upgrades"
	)
	assert_eq(cleaned.count("work_jacket#7"), 1, "a copy of its own is one item")


func test_old_saves_give_a_shared_upgrade_to_one_copy() -> void:
	var profile := _profile()
	var v9 := profile.to_dict()
	v9["version"] = 9
	v9["equipment"]["weapon"] = "foreman_wrench"
	v9["inventory"]["foreman_wrench"] = 17
	v9["inventory"]["brass_knuckles"] = 2
	v9["enhance"] = {"foreman_wrench": 10, "brass_knuckles": 9}
	v9["enhance_pity"] = {"brass_knuckles": 3}
	var loaded := PlayerProfile.from_dict(v9, _content())
	assert_eq(loaded.equipment["weapon"], "foreman_wrench#1", "the worn wrench keeps the +10")
	assert_eq(EnhanceRules.level(loaded, "weapon"), 10, "+10")
	assert_eq(loaded.count("foreman_wrench"), 17, "the 17 in the bag are +0")
	assert_eq(EnhanceRules.item_level(loaded, "foreman_wrench"), 0, "+0")
	assert_eq(loaded.count("brass_knuckles"), 1, "one of the two knuckles stays plain")
	assert_eq(EnhanceRules.item_level(loaded, "brass_knuckles#1"), 9, "the other keeps +9")
	assert_eq(loaded.enhance_pity, {"brass_knuckles#1": 3}, "and its pity")


func test_costs_rise_and_chances_fall() -> void:
	var levels: Array = _content().progression["enhance"]["levels"]
	for i in range(1, levels.size()):
		assert_true(int(levels[i]["coins"]) > int(levels[i - 1]["coins"]), "coins rise at %d" % i)
		assert_true(
			float(levels[i]["rate"]) <= float(levels[i - 1]["rate"]), "rate falls at %d" % i
		)
	assert_true(_content().is_valid(), ", ".join(_content().errors))


func test_the_workbench_upgrades_from_the_item_card() -> void:
	SaveStore.root = "user://test_enhance_save"
	SaveStore.delete_all()
	GameSession.start_new_game("mika")
	var game: Node2D = GAME_SCENE.instantiate()
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
	assert_true(SaveStore.has_characters(), "saved")
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
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _saved() -> Variant:
	return JSON.parse_string(
		FileAccess.get_file_as_string(SaveStore.path_of(GameSession.profile.id))
	)


func _texts(root: Node) -> String:
	var parts: Array[String] = []
	for label: Label in root.find_children("*", "Label", true, false):
		parts.append(label.text)
	return " | ".join(parts)


func test_loading_keeps_upgrades_only_on_copies_the_hero_has() -> void:
	var profile := _profile()
	var copy := profile.own_copy("body")
	profile.enhance[copy] = 3
	var data := profile.to_dict()
	data["enhance"] = {copy: 3, "work_jacket": 5, "work_jacket#9": 7}
	data["inventory"][copy] = 1  # the worn copy written into the bag as well
	var loaded := PlayerProfile.from_dict(data, _content())
	assert_eq(loaded.enhance, {copy: 3}, "no stack-wide level, none on a copy not held")
	assert_eq(loaded.count(copy), 0, "a copy of its own is in one place: worn")
	assert_eq(loaded.equipment["body"], copy, "still worn")
	loaded.enhance_pity["work_jacket#2"] = 4  # a leftover
	loaded.add_item("work_jacket")
	loaded.equip("work_jacket", _content())
	assert_eq(loaded.own_copy("body"), "work_jacket#3", "a new copy never inherits a leftover")


func test_the_card_compares_upgraded_copies_and_warns_before_they_go() -> void:
	SaveStore.root = "user://test_enhance_card"
	SaveStore.delete_all()
	GameSession.start_new_game("mika")
	var game: Node2D = GAME_SCENE.instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var profile: PlayerProfile = game.profile
	profile.level = 10
	profile.add_item("foreman_wrench", 2)
	profile.equip("foreman_wrench", game.content)
	var worn := profile.own_copy("weapon")
	profile.enhance[worn] = 5
	game.open_inventory()
	game.inspect_item("foreman_wrench", "")
	var text := _texts(game.item_card)
	assert_true(text.contains("Compared with Foreman's Wrench +5"), "against the +5 one worn")
	assert_true(text.contains("-"), "a plain copy is a step down from it")
	game.close_item_card()
	profile.unequip("weapon", game.content)
	game.inspect_item(worn, "")
	text = _texts(game.item_card)
	assert_true(text.contains("Upgraded +5"), "a carried copy shows its level")
	var discard := ""
	for button: Button in game.item_card.find_children("*", "Button", true, false):
		if button.text == "Discard":
			button.pressed.emit()
			discard = button.text
	assert_eq(discard, "Discard +5 for good?", "and says what is lost")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
