extends TestCase
## The street's game screens (scenes/street: StreetMenus, StreetMenuHost and the
## Character, Equipment, Bag and Skills pages, Settings): each shows the engine's own
## state and changes it only through the engine, and every change is saved.
## Items are added to the bags here, in the test only (never to real players).

const TEST_SAVE := "user://test_street_menus"
const SCENE := "res://scenes/street/Street.tscn"


func _street(cls: String, level := 1) -> Node2D:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE)
	SaveStore.root = TEST_SAVE
	var db := GameSession.content
	var state := RpgCharacter.create(db, RpgPack.of(db), cls)
	state["id"] = SaveStore.new_id()
	state["name"] = "Menus"
	state["area"] = "depot_yard"
	state["level"] = level
	assert_true(SaveStore.save_player(state), "saved")
	GameSession.character_id = state["id"]
	var street: Node2D = load(SCENE).instantiate()
	street.set("navigate", false)
	tree.root.add_child(street)
	await tree.process_frame
	return street


func _done(street: Node2D) -> void:
	SaveStore.delete_player(street.get("state")["id"])
	street.free()
	SaveStore.root = SaveStore.DEFAULT_ROOT
	GameSession.character_id = ""


func _menus(street: Node2D) -> StreetMenuHost:
	return street.get("menus")


func _node(street: Node2D, path: String) -> Node:
	var menu: Control = _menus(street).menu
	var found := menu.find_children(path, "", true, false)
	return found[0] if not found.is_empty() else null


func _saved(street: Node2D) -> Dictionary:
	return SaveStore.load_player(street.get("state")["id"], GameSession.content)


func test_character_shows_the_live_unit() -> void:
	var street := await _street("warrior")
	_menus(street).open_screen("character")
	assert_eq(_menus(street).menu_name, "character", "Character opens")
	var fight: RpgEncounter = street.get("fight")
	var label: Label = _node(street, "Stat_Attack_power")
	assert_eq(label.text, str(int(fight.player["attack_power"])), "the unit's own number")
	assert_eq((_node(street, "Stat_Armor") as Label).text, str(int(fight.player["armor"])), "armor")
	var spec: Button = _node(street, "Spec_arms")
	assert_true(spec != null and spec.disabled, "no specialization before its level")
	_menus(street).menu_action("spec", "arms")
	assert_eq(street.get("state")["spec_id"], "", "the engine refuses it too")
	_done(street)


func test_a_specialization_opens_at_its_level_and_is_saved() -> void:
	var db := GameSession.content
	var unlock := int(RpgPack.constant(RpgPack.of(db), "spec_unlock_level"))
	var street := await _street("warrior", unlock)
	_menus(street).open_screen("character")
	var spec: Button = _node(street, "Spec_arms")
	assert_true(not spec.disabled, "open at level %d" % unlock)
	spec.pressed.emit()
	assert_eq(street.get("state")["spec_id"], "arms", "chosen")
	assert_eq(street.get("fight").player["spec_id"], "arms", "the live unit has it")
	assert_eq(_saved(street)["spec_id"], "arms", "and the save")
	assert_true((_node(street, "Spec_fury") as Button).disabled, "one choice")
	_done(street)


func test_equipment_equips_a_real_copy_and_the_sheet_follows() -> void:
	var street := await _street("warrior")
	var state: Dictionary = street.get("state")
	var fight: RpgEncounter = street.get("fight")
	var menus := _menus(street)
	menus.open_screen("equipment")
	var slots := 0
	for s: Node in menus.menu.find_children("Worn_*", "", true, false):
		slots += 1
	assert_eq(slots, 13, "the reference's 13 slots")
	var worn := str(state["equipment"]["mainhand"])
	var quality := {"tier": 2, "weights": [1, 2]}
	RpgCharacter.add_item(state, "rusty_hatchet", 1, quality)
	menus.open_screen("bag")
	assert_eq(menus.menu_name, "bag", "Bag opens")
	menus.menu_select("bag:0")
	var equip: Button = _node(street, "Equip")
	assert_true(equip != null and not equip.disabled, "it can be worn")
	equip.pressed.emit()
	assert_eq(state["equipment"]["mainhand"], "rusty_hatchet", "worn")
	assert_eq(state["equipment_quality"]["mainhand"], quality, "the copy's quality goes with it")
	assert_eq(state["inventory"].size(), 1, "the old weapon came back, nothing doubled")
	assert_eq(state["inventory"][0]["item_id"], worn, "it is the old weapon")
	var fresh := RpgUnit.player(GameSession.content, street.get("pack"), state)
	assert_eq(fight.player["weapon"], fresh["weapon"], "the live unit swings the new weapon")
	assert_eq(_saved(street)["equipment"]["mainhand"], "rusty_hatchet", "saved")
	assert_eq(_saved(street)["equipment_quality"]["mainhand"], quality, "with its quality")
	menus.menu_select("worn:mainhand")
	(_node(street, "Unequip") as Button).pressed.emit()
	assert_true(not state["equipment"].has("mainhand"), "taken off")
	var back: Dictionary = state["inventory"][state["inventory"].size() - 1]
	assert_eq(back["item_id"], "rusty_hatchet", "into the bags")
	assert_eq(back["quality"], quality, "still the same copy")
	_done(street)


func test_a_refused_equip_changes_nothing() -> void:
	var street := await _street("mage")
	var state: Dictionary = street.get("state")
	RpgCharacter.add_item(state, "eastbrook_buckler", 1, null)
	var before: Dictionary = state.duplicate(true)
	var menus := _menus(street)
	menus.open_screen("bag")
	menus.menu_select("bag:0")
	var equip: Button = _node(street, "Equip")
	assert_true(equip.disabled, "a mage cannot use a shield")
	for _i in 3:
		menus.menu_action("equip", 0)
	assert_eq(state, before, "nothing moved, nothing doubled")
	_done(street)


func test_the_bag_shows_only_owned_copies() -> void:
	var street := await _street("rogue")
	var state: Dictionary = street.get("state")
	RpgCharacter.add_item(state, "spider_leg", 2, null)
	var menus := _menus(street)
	menus.open_screen("bag")
	var cells := 0
	for c: Node in menus.menu.find_children("Bag_*", "", true, false):
		cells += 1
	assert_eq(cells, 2, "one cell per carried copy")
	menus.menu_select("bag:1")
	assert_true(_node(street, "Equip").disabled, "junk is not equipment")
	_done(street)


func test_skills_show_the_spellbook_and_fill_the_hotbar() -> void:
	var street := await _street("warrior", 10)
	var state: Dictionary = street.get("state")
	var fight: RpgEncounter = street.get("fight")
	var pack: Dictionary = street.get("pack")
	var menus := _menus(street)
	menus.open_screen("skills")
	assert_eq(menus.menu_name, "skills", "Skills opens")
	var book := RpgSpellbook.book(pack, "warrior", 10, fight.player["mods"])
	var buttons := menus.menu.find_children("Skill_*", "", true, false)
	assert_eq(buttons.size(), book.size(), "the whole spellbook, known and locked")
	var usable := ""
	var blocked := ""
	for e: Dictionary in book:
		if e["state"] == "usable" and usable == "" and _plain_instant(pack, str(e["id"])):
			usable = e["id"]
		if e["state"] == "known_blocked" and blocked == "":
			blocked = e["id"]
	assert_true(usable != "", "a usable ability")
	menus.menu_action("hotbar", [1, usable])
	assert_eq(state["hotbar"][1], usable, "slot 3 holds it")
	assert_eq(_saved(street)["hotbar"][1], usable, "saved")
	await tree.process_frame
	assert_eq(street.get("hud").ability_at(2), usable, "the HUD's hotbar shows it")
	if blocked != "":
		menus.menu_action("hotbar", [2, blocked])
		assert_true(state["hotbar"][2] != blocked, "a known ability not in this build is refused")
		menus.menu_select("skill:" + blocked)
		assert_true(_node(street, "Assign_4") == null, "and cannot be put on the bar")
	menus.close_menu()
	fight.mobs.append(RpgUnit.mob(pack, "shore_scuttler", 1, float(fight.player["x"]) + 2.0))
	fight.mobs[-1]["id"] = 99
	var cost := float(pack["abilities"][usable]["def"]["cost"])
	# Touch and mouse: the HUD's own hotbar slot.
	fight.player["resource"] = 100.0
	var hud_bar: Hotbar = street.get("hud").find_children("Hotbar", "Hotbar", true, false)[0]
	hud_bar.slots[2].pressed.emit()
	assert_near(float(fight.player["resource"]), 100.0 - cost, "the slot cast it (its cost)")
	# The keyboard: the slot's number key, after the global cooldown.
	for _i in 40:
		fight.step()
	fight.player["resource"] = 100.0
	var key := InputEventAction.new()
	key.action = "slot_3"
	key.pressed = true
	street._unhandled_input(key)
	assert_near(float(fight.player["resource"]), 100.0 - cost, "the key cast the same one")
	_done(street)


## An instant that pays its cost when pressed, with no cast condition of its own
## (no queued swing, range floor, execute window or required aura).
func _plain_instant(pack: Dictionary, id: String) -> bool:
	var def: Dictionary = pack["abilities"][id]["def"]
	return (
		float(def["cost"]) > 0.0
		and float(def["castTime"]) == 0.0
		and not def.get("onNextSwing", false)
		and def.get("minRange") == null
		and def.get("requiresAuraKind") == null
		and RpgAbilityRules.execute_threshold(def) < 0.0
		and def.get("channel") == null
	)


func test_talents_only_where_the_engine_allows() -> void:
	var street := await _street("warrior", 5)
	var state: Dictionary = street.get("state")
	var pack: Dictionary = street.get("pack")
	var rows: Array = RpgTalents.class_talents(pack, "warrior")["rows"]
	var first: Dictionary = rows[0]
	var later: Dictionary = rows[rows.size() - 1]
	var menus := _menus(street)
	menus.open_screen("skills")
	menus.menu_action("talent", [int(later["level"]), later["options"][0]["id"]])
	assert_true(not state["talents"].has(str(int(later["level"]))), "a later row is refused")
	menus.menu_action("talent", [int(first["level"]), first["options"][0]["id"]])
	assert_eq(state["talents"][str(int(first["level"]))], first["options"][0]["id"], "chosen")
	assert_eq(_saved(street)["talents"], state["talents"], "saved")
	var talent: Button = _node(street, "Talent_" + str(later["options"][0]["id"]))
	assert_true(talent.disabled, "the later row's buttons are off")
	_done(street)


func test_settings_change_real_settings() -> void:
	var street := await _street("priest")
	var menus := _menus(street)
	var was := bool(GameSession.settings.get("show_fps", false))
	menus.open_screen("settings")
	var toggle: CheckButton = null
	for t: Node in menus.menu.find_children("*", "CheckButton", true, false):
		toggle = t
	assert_true(toggle != null and toggle.button_pressed == was, "shows the saved value")
	toggle.button_pressed = not was
	assert_eq(GameSession.settings["show_fps"], not was, "changed")
	menus.close_menu()
	menus.open_screen("settings")
	for t: Node in menus.menu.find_children("*", "CheckButton", true, false):
		toggle = t
	assert_eq(toggle.button_pressed, not was, "the same after reopening")
	var notice: Label = _node(street, "NoticeText")
	assert_true(notice.text.contains("Copyright (c) 2026 Levy Street"), "the MIT notice is there")
	GameSession.set_setting("show_fps", was)
	_done(street)


func test_screens_switch_close_and_block_the_fight() -> void:
	var street := await _street("hunter")
	var menus := _menus(street)
	for name: String in StreetMenus.ORDER:
		menus.open_screen(name)
		assert_eq(menus.menu_name, name, name + " opens")
	menus.cycle(1)
	assert_eq(menus.menu_name, "character", "E wraps to the first")
	menus.open_screen("character")
	assert_true(not menus.is_open(), "its own key closes it")
	menus.open_screen("bag")
	var press := InputEventAction.new()
	press.action = "attack_light"
	press.pressed = true
	street._unhandled_input(press)
	assert_true(not street.get("fight").player["auto_attack"], "no attack through a screen")
	assert_true(menus.is_open(), "still open")
	menus.close_menu()
	menus.open_pause()
	assert_true(_node(street, "QuitToTitle") != null, "the Esc menu saves and quits")
	_done(street)


func test_the_notice_is_the_pinned_licence_word_for_word() -> void:
	var shipped := LegalNotices.notices()
	assert_eq(shipped.size(), 1, "one notice")
	var n: Dictionary = shipped[0]
	assert_eq(n["revision"], "d2b91e0884cb269422c28d0b42d2a30a01de130a", "the pinned revision")
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	var file := FileAccess.get_file_as_string(
		root.path_join("LICENSES/World-of-ClaudeCraft-MIT.txt")
	)
	assert_true(file.begins_with("MIT License"), "LICENSES/ holds the pinned LICENSE")
	assert_eq(n["text"], file, "the shipped text is the same, word for word")
	assert_eq(n["text"].sha256_text(), n["sha256"], "the recorded hash")
	assert_true(CreditsText.build(GameSession.content).contains(n["text"]), "in the Credits")


func test_the_test_merchant_is_off_for_players() -> void:
	assert_eq(
		ProjectSettings.get_setting("iron_legacy/test_vendor_enabled"), false, "off by default"
	)
	if OS.get_environment("TEST_VENDOR_ENABLED") == "":
		assert_true(not GameSession.test_vendor_enabled(), "not in the game")
