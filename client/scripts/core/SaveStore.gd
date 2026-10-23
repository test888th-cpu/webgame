extends Node
## Local save slot. On desktop this is a file in the user data folder; in the
## browser Godot maps user:// to IndexedDB, so it survives reloads.
##
## This is an offline save for the single-player slice. From Milestone 4 the
## backend owns progression and this becomes a cache of the server's copy.

const DEFAULT_PATH := "user://save.json"

var path := DEFAULT_PATH


func has_save() -> bool:
	return FileAccess.file_exists(path)


## Writes atomically: to a temporary file first, then renamed over the old
## save, so a crash mid-write cannot leave a truncated save behind.
func save(profile: PlayerProfile) -> bool:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(profile.to_dict()))
	file.close()
	return DirAccess.rename_absolute(temp, path) == OK


## Returns the saved profile, or null when there is no usable save.
func load_profile(content: ContentDB) -> PlayerProfile:
	if not has_save():
		return null
	# JSON.parse (unlike parse_string) reports bad input as a return code
	# instead of logging an engine error.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("save at %s is not valid JSON; ignoring it" % path)
		return null
	return PlayerProfile.from_dict(json.data, content)


func delete() -> void:
	if has_save():
		DirAccess.remove_absolute(path)
