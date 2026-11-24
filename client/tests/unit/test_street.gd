extends TestCase
## The street (scenes/street/Street.tscn): the city's existing areas with the
## reference monsters of data/rpg/placement.json, run by RpgEncounter.

const TEST_SAVE := "user://test_street"
const SCENE := "res://scenes/street/Street.tscn"


func _character(area: String) -> Dictionary:
	var db := GameSession.content
	var state := RpgCharacter.create(db, RpgPack.of(db), "warrior")
	state["id"] = SaveStore.new_id()
	state["name"] = "Walker"
	state["area"] = area
	return state


func _setup(area: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE)
	SaveStore.root = TEST_SAVE
	var state := _character(area)
	assert_true(SaveStore.save_player(state), "saved")
	GameSession.character_id = state["id"]
	return state


func _teardown(state: Dictionary) -> void:
	SaveStore.delete_player(state["id"])
	SaveStore.root = SaveStore.DEFAULT_ROOT
	GameSession.character_id = ""


func _open() -> Node2D:
	var street: Node2D = load(SCENE).instantiate()
	street.set("navigate", false)
	tree.root.add_child(street)
	await tree.process_frame
	return street


func test_every_placed_area_exists_and_its_monsters_can_fight() -> void:
	var db := GameSession.content
	var pack := RpgPack.of(db)
	var placed: Dictionary = db.rpg["placement"]["areas"]
	assert_true(placed.size() > 30, "most areas have reference monsters")
	for id: String in placed:
		assert_true(db.areas.has(id), id + ": an existing area")
		for sp: Dictionary in placed[id]["spawns"]:
			assert_true(not RpgPack.monster(pack, sp["monster"]).is_empty(), sp["monster"])
			assert_true(db.art.has(sp["sprite"]), id + ": existing art " + sp["sprite"])


func test_levels_rise_along_the_old_order() -> void:
	var placed: Dictionary = GameSession.content.rpg["placement"]["areas"]
	assert_eq(int(placed["saltmarket"]["target_level"]), 1, "the first street is level 1")
	assert_true(
		int(placed["refinery"]["target_level"]) < int(placed["factory_gate"]["target_level"]),
		"later districts are higher"
	)
	assert_eq(int(placed["core_chamber"]["target_level"]), 20, "the end is the level cap")


func test_a_street_fight_kills_saves_and_respawns() -> void:
	var state := _setup("saltmarket")
	var street := await _open()
	var fight: RpgEncounter = street.get("fight")
	assert_true(fight != null and fight.zone_mode and fight.respawn, "a living street")
	assert_true(fight.mobs.size() > 0, "monsters on the street")
	assert_eq(street.get("area_id"), "saltmarket", "the saved area")
	fight.command({"op": "auto", "on": true})
	for _i in 60 * 120:
		street._physics_process(1.0 / 60.0)
		if int(street.get("state")["kills"]) >= 1:
			break
	assert_true(int(street.get("state")["kills"]) >= 1, "auto killed a monster")
	var dead_one: Dictionary = {}
	for m: Dictionary in fight.mobs:
		if m["dead"]:
			dead_one = m
	assert_true(not dead_one.is_empty(), "a corpse lies on the street")
	fight.events.clear()
	for _i in 20 * 61:
		fight.step()
	var rose := fight.events.filter(
		func(e: Dictionary) -> bool: return e["type"] == "respawn" and e["unit"] == dead_one["id"]
	)
	assert_true(not rose.is_empty(), "it rose again (respawn_policy.ts)")
	await street.quit_to_title()
	assert_eq(street.get("went_to"), "res://scenes/title/Title.tscn", "save and quit leaves")
	var saved := SaveStore.load_player(state["id"], GameSession.content)
	assert_true(int(saved["kills"]) >= 1, "the kill was saved")
	assert_eq(saved["area"], "saltmarket", "the area was saved")
	street.free()
	_teardown(state)


func test_walking_off_the_east_end_enters_the_next_area() -> void:
	var state := _setup("depot_yard")
	var street := await _open()
	var fight: RpgEncounter = street.get("fight")
	assert_eq(fight.mobs.size(), 0, "the safe yard has no monsters")
	fight.player["x"] = fight.bounds.y
	street.set("_travel_cooldown", 0.0)
	street._check_exits(1)
	assert_eq(street.get("area_id"), "saltmarket", "east of the depot yard")
	assert_true(float(street.get("fight").player["x"]) < 5.0, "entered from the west end")
	street.free()
	_teardown(state)


func test_the_street_uses_the_games_own_hud_and_hotbar() -> void:
	var state := _setup("saltmarket")
	var street := await _open()
	var hud: CanvasLayer = street.get("hud")
	assert_eq(hud.scene_file_path, "res://scenes/ui/Hud.tscn", "the game's HUD")
	var bar: Hotbar = hud.find_children("Hotbar", "Hotbar", true, false)[0]
	assert_eq(bar.entries[0]["type"], "attack", "slot 1 is the auto attack")
	for i in range(1, bar.entries.size()):
		if bar.entries[i]["type"] != "ability":
			continue
		var doc: Dictionary = RpgPack.of(GameSession.content)["abilities"][bar.entries[i]["id"]]
		assert_true(str(doc["status"]).begins_with("IMPLEMENTED"), "only runnable abilities")
	var fight: RpgEncounter = street.get("fight")
	fight.mobs[0]["x"] = float(fight.player["x"]) + 2.0
	street._slot(0)
	assert_true(fight.player["auto_attack"], "slot 1 targets and starts the attack")
	assert_true(not fight.mob.is_empty(), "a target chosen")
	await tree.process_frame
	assert_true(hud.get_node("Root/Boss").visible, "the target's bar shows")
	street.free()
	_teardown(state)


func test_the_street_shows_no_removed_mechanics() -> void:
	var state := _setup("saltmarket")
	var street := await _open()
	var hud: CanvasLayer = street.get("hud")
	await tree.process_frame
	var hints := ""
	for label: Label in hud.get_node("Root").find_children("*", "Label", true, false):
		if label.is_visible_in_tree():
			hints += label.text + " "
	for gone: String in ["Heavy", "Dodge", "Guard", "Grab"]:
		assert_true(not gone in hints, gone + ": no hint for a removed mechanic")
	for button: String in ["Heavy", "Dodge", "Guard", "Item"]:
		assert_true(not hud.get_node("Root/Touch/" + button).visible, button + ": no touch button")
	for menu: String in ["quests", "map"]:
		assert_true(not hud.get_node("Root/MenuBar/Menu_" + menu).visible, menu + ": not ported")
	street.free()
	_teardown(state)
