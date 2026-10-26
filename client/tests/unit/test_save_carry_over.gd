extends TestCase
## Renaming the game moved the user data folder; SaveStore copies players'
## saves and settings over from the old one without ever losing or
## overwriting anything.

const OLD := "user://test_carry/old"
const NEW := "user://test_carry/new"


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _clean() -> void:
	for dir: String in [OLD, NEW]:
		for file: String in ["save.json", "settings.json"]:
			if FileAccess.file_exists(dir.path_join(file)):
				DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.make_dir_recursive_absolute(NEW)


func test_the_old_save_and_settings_are_carried_over() -> void:
	_clean()
	_write(OLD.path_join("save.json"), '{"version": 3}')
	_write(OLD.path_join("settings.json"), '{"sfx_volume": 0.5}')
	var copied := SaveStore.carry_over(OLD, NEW, SaveStore.CARRIED_FILES)
	assert_eq(copied.size(), 2, "both files copied")
	assert_eq(
		FileAccess.get_file_as_string(NEW.path_join("save.json")), '{"version": 3}', "same save"
	)
	assert_true(FileAccess.file_exists(OLD.path_join("save.json")), "the original stays")
	_clean()


func test_a_newer_save_is_never_overwritten() -> void:
	_clean()
	_write(OLD.path_join("save.json"), "old")
	_write(NEW.path_join("save.json"), "new")
	var copied := SaveStore.carry_over(OLD, NEW, SaveStore.CARRIED_FILES)
	assert_eq(copied.size(), 0, "nothing copied")
	assert_eq(FileAccess.get_file_as_string(NEW.path_join("save.json")), "new", "kept")
	_clean()


func test_nothing_to_carry_is_fine() -> void:
	_clean()
	var copied := SaveStore.carry_over("user://test_carry/missing", NEW, SaveStore.CARRIED_FILES)
	assert_eq(copied.size(), 0, "no old folder, nothing copied")
