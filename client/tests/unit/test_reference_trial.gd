extends TestCase
## Character creation and the character sheet (scenes/reference/ReferenceTrial.tscn),
## and the owner-ordered reset of the old player data.

const TEST_SAVE := "user://test_reference_trial"
const SCENE := "res://scenes/reference/ReferenceTrial.tscn"


func _open() -> Control:
	var screen: Control = load(SCENE).instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	return screen


func _button(screen: Node, node_name: String) -> Button:
	var found := screen.find_children(node_name, "Button", true, false)
	return found[0] if not found.is_empty() else null


func _clean() -> void:
	var dir := TEST_SAVE.path_join(SaveStore.PLAYER_DIR)
	if DirAccess.dir_exists_absolute(dir):
		for file in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file))


func test_a_named_character_is_created_and_sent_to_the_street() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE)
	SaveStore.root = TEST_SAVE
	_clean()
	GameSession.character_id = ""
	var screen := await _open()
	screen.set("navigate", false)
	_button(screen, "Class_warrior").pressed.emit()
	await tree.process_frame
	assert_true(screen.get("state").is_empty(), "no character without a name")
	var name_edit: LineEdit = screen.find_children("NameEdit", "LineEdit", true, false)[0]
	assert_true(tree.root.gui_get_focus_owner() != null, "something has focus (the name field)")
	name_edit.text = "Tester"
	_button(screen, "Class_warrior").pressed.emit()
	await tree.process_frame
	assert_eq(screen.get("went_to"), "res://scenes/street/Street.tscn", "into the city")
	var listed := SaveStore.players(GameSession.content)
	assert_eq(listed.size(), 1, "one production character")
	assert_eq(listed[0]["name"], "Tester", "the name was saved")
	assert_eq(listed[0]["class_id"], "warrior", "the class was saved")
	screen.free()
	# Opened again with that character: the sheet, and Enter the city.
	var again := await _open()
	again.set("navigate", false)
	var enter := _button(again, "EnterCity")
	assert_true(enter != null, "the sheet offers the city")
	enter.pressed.emit()
	assert_eq(again.get("went_to"), "res://scenes/street/Street.tscn", "back to the street")
	again.free()
	_clean()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_old_player_data_is_reset_once_and_nothing_else() -> void:
	var root := "user://test_player_reset"
	DirAccess.make_dir_recursive_absolute(root.path_join("characters").path_join("deleted"))
	var files := [
		"characters/abc.json",
		"characters/abc.json.bak",
		"characters/deleted/old.json",
		"save.json",
		"save.imported.json",
		"reference_slice.json",
		"settings.json",
	]
	for f: String in files:
		var out := FileAccess.open(root.path_join(f), FileAccess.WRITE)
		out.store_string("{}")
		out.close()
	var removed := SaveStore.reset_legacy_player_data(root)
	assert_eq(removed.size(), 6, "every old player file")
	assert_true(FileAccess.file_exists(root.path_join("settings.json")), "settings kept")
	assert_true(not DirAccess.dir_exists_absolute(root.path_join("characters")), "old roster gone")
	assert_eq(SaveStore.reset_legacy_player_data(root).size(), 0, "only once")
	DirAccess.remove_absolute(root.path_join("settings.json"))
	DirAccess.remove_absolute(root.path_join(SaveStore.RESET_MARKER))
	DirAccess.remove_absolute(root)


func test_old_formats_never_load_as_characters() -> void:
	var db := GameSession.content
	var pack := RpgPack.of(db)
	var hero := {"version": 13, "hero": "mika", "name": "Mika", "level": 16}
	assert_true(RpgSave.from_dict(hero, db, pack)["state"].is_empty(), "a hero save")
	var v2 := {"format": RpgSave.FORMAT, "version": 2, "character": {"class_id": "warrior"}}
	assert_true(RpgSave.from_dict(v2, db, pack)["state"].is_empty(), "a v2 trial save")
