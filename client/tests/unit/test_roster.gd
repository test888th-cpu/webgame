extends TestCase
## An account's characters (RosterRules, SaveStore, the Characters screen):
## each has an id and a save of its own, a new hero never replaces another,
## the old single save becomes a character, deleting keeps the file aside,
## and nothing (upgrades included) leaks from one character to another.

const ROOT := "user://test_roster"
const TITLE_SCENE := "res://scenes/title/Title.tscn"


func _begin() -> void:
	SaveStore.root = ROOT
	SaveStore.delete_all()


func _end() -> void:
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _content() -> ContentDB:
	return GameSession.content


func _character(hero: String, name: String) -> PlayerProfile:
	GameSession.start_new_game(hero, name)
	assert_true(SaveStore.save(GameSession.profile), "%s saved" % name)
	return GameSession.profile


func test_ids_are_random_and_well_formed() -> void:
	var seen := {}
	for i in 200:
		var id := SaveStore.new_id()
		assert_true(RosterRules.is_id(id), "%s is an id" % id)
		seen[id] = true
	assert_eq(seen.size(), 200, "no two alike")
	for bad: String in ["", "0123", "ABCDEF0123456789", "../../save.json!", "0123456789abcdeg"]:
		assert_true(not RosterRules.is_id(bad), "%s is not" % bad)


func test_a_new_character_never_replaces_another() -> void:
	_begin()
	var ace := _character("pong", "Ace")
	ace.level = 20
	SaveStore.save(ace)
	var mika := _character("mika", "Mika")
	assert_true(ace.id != mika.id, "two ids")
	var roster := SaveStore.characters(_content())
	assert_eq(roster.size(), 2, "both are there")
	assert_true(GameSession.play(ace.id), "Ace can be played again")
	assert_eq(GameSession.profile.level, 20, "at level 20")
	assert_eq(GameSession.profile.name, "Ace", "as Ace")
	_end()


func test_the_last_played_comes_first_and_tampered_saves_are_refused() -> void:
	_begin()
	var a := _character("mika", "Ana")
	var b := _character("mika", "Bea")
	for pair: Array in [[a, 100], [b, 200]]:
		var data: Dictionary = pair[0].to_dict()
		data["saved_at"] = pair[1]
		_write(SaveStore.path_of(pair[0].id), JSON.stringify(data))
	assert_eq(SaveStore.characters(_content())[0].name, "Bea", "played last, listed first")
	_write(SaveStore.path_of(a.id), JSON.stringify(b.to_dict()))
	assert_eq(SaveStore.load_character(a.id, _content()), null, "a save claiming another id")
	assert_eq(SaveStore.load_character("../save", _content()), null, "a path is not an id")
	assert_eq(SaveStore.characters(_content()).size(), 1, "only the honest save is listed")
	_end()


func test_deleting_keeps_the_file_aside() -> void:
	_begin()
	var gone := _character("mika", "Gone")
	_character("mika", "Stays")
	assert_true(SaveStore.delete_character(gone.id), "deleted")
	var roster := SaveStore.characters(_content())
	assert_eq(roster.size(), 1, "out of the roster")
	assert_eq(roster[0].name, "Stays", "the other one stays")
	var kept := DirAccess.get_files_at(SaveStore.folder().path_join("deleted"))
	assert_eq(kept.size(), 1, "the file is kept aside")
	assert_true(kept[0].begins_with(gone.id), "under its id")
	assert_true(not SaveStore.delete_character("../../settings"), "only ids can be deleted")
	_end()


func test_the_old_single_save_becomes_a_character_once() -> void:
	_begin()
	var old := PlayerProfile.new_game(_content(), "mika", "Veteran")
	old.level = 20
	var data := old.to_dict()
	data.erase("id")
	_write(ROOT.path_join(SaveStore.LEGACY_SAVE), JSON.stringify(data))
	var roster := SaveStore.characters(_content())
	assert_eq(roster.size(), 1, "imported")
	assert_eq([roster[0].name, roster[0].level], ["Veteran", 20], "as it was")
	assert_true(RosterRules.is_id(roster[0].id), "with an id of its own")
	assert_true(not FileAccess.file_exists(ROOT.path_join(SaveStore.LEGACY_SAVE)), "moved")
	assert_true(FileAccess.file_exists(ROOT.path_join(SaveStore.IMPORTED_SAVE)), "and kept")
	assert_eq(SaveStore.characters(_content()).size(), 1, "imported once, not twice")
	_end()


func test_four_slots_and_one_name_each() -> void:
	var content := _content()
	assert_eq(RosterRules.max_characters(content), 4, "four characters per account")
	var three: Array[PlayerProfile] = []
	for name: String in ["Ana", "Bea", "Cid"]:
		three.append(PlayerProfile.new_game(content, "mika", name))
	assert_eq(RosterRules.problem(three, content, "Dot"), "", "a fourth is fine")
	assert_eq(RosterRules.problem(three, content, "bea"), "name", "names are the account's own")
	three.append(PlayerProfile.new_game(content, "mika", "Dot"))
	assert_eq(RosterRules.problem(three, content, "Eve"), "full", "not a fifth")


func test_characters_share_nothing() -> void:
	_begin()
	var a := _character("mika", "Ana")
	var b := _character("mika", "Bea")
	a.level = 10
	a.add_item("work_jacket")
	a.equip("work_jacket", _content())
	var copy := a.own_copy("body")
	a.enhance[copy] = 9
	a.money = 5000
	SaveStore.save(a)
	var again := SaveStore.load_character(b.id, _content())
	assert_eq(again.enhance, {}, "Bea's gear has no upgrades from Ana")
	assert_eq(again.owned("work_jacket"), 0, "nor her jacket")
	assert_true(again.money != 5000, "nor her coins")
	assert_eq(SaveStore.load_character(a.id, _content()).enhance, {copy: 9}, "Ana keeps hers")
	_end()


func test_the_characters_screen_plays_creates_and_deletes() -> void:
	_begin()
	_character("pong", "Ace")
	_character("mika", "Mika")
	var title: Node = load(TITLE_SCENE).instantiate()
	tree.root.add_child(title)
	tree.root.size = Vector2i(1280, 720)
	title.open_characters()
	await tree.process_frame
	await tree.process_frame
	var slots := title.find_child("Slots", true, false)
	assert_eq(slots.get_child_count(), 4, "four slots")
	var texts := []
	for card: Button in slots.get_children():
		texts.append(card.text)
	assert_eq(texts.count("+\nNew character"), 2, "two free")
	for node in title.find_child("Slots", true, false).find_children("*", "Control", true, false):
		var control: Control = node
		if control is Label and control.is_visible_in_tree():
			assert_true(
				Rect2(0, 0, 640, 360).grow(1).encloses(control.get_global_rect()),
				"%s fits" % (control as Label).text
			)
	(slots.get_child(1) as Button).grab_focus()
	var delete := title.find_child("Delete", true, false) as Button
	delete.pressed.emit()
	assert_eq(SaveStore.characters(_content()).size(), 2, "the first press only asks")
	assert_true(delete.text.contains("for good"), "by name")
	delete.pressed.emit()
	assert_eq(SaveStore.characters(_content()).size(), 1, "the second deletes")
	title.free()
	_end()


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
