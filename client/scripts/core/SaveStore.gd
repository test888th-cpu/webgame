extends Node
## Local saves, one per character. On desktop they are files in the user
## data folder; in the browser Godot maps user:// to IndexedDB, so they
## survive reloads.
##
## This is an offline save for the single-player slice. From Milestone 4 the
## backend owns progression and this becomes a cache of the server's copy.

## Every character of the account has a save of its own, so starting a new
## hero never touches another: <root>/characters/<character id>.json. A
## deleted character's file moves to characters/deleted/ (kept, never
## counted). The single save of older builds (<root>/save.json) is imported
## as a character on first start and then kept as save.imported.json.
const DEFAULT_ROOT := "user://"
const LEGACY_SAVE := "save.json"
const IMPORTED_SAVE := "save.imported.json"
const UNREADABLE_SAVE := "save.unreadable.json"
## A character's files: the save, the last good save before it, and a save
## being written (complete once it is there: it is checked before renaming).
const SUFFIXES := [".json", ".json.bak", ".json.tmp"]
## Godot names the user data folder after the project, so renaming the game
## from "Ironbound Streets" to "The Iron Legacy" moved user:// to a new,
## empty folder (in the browser too: IndexedDB holds the same folder tree).
## Players' files are copied over from the old folder on first start; the
## originals are left in place, never deleted.
const FORMER_NAMES := ["Ironbound Streets"]
const CARRIED_FILES := ["save.json", "settings.json"]

var root := DEFAULT_ROOT
## Set when another browser tab holds the saves (see claim_web_lock): this
## tab then never writes, so it cannot overwrite or delete the other's files.
var read_only := false


func _init() -> void:
	# Runs before GameSession reads the settings.
	var here := OS.get_user_data_dir()
	# Once imported, the old save must not come back as a second character.
	var files := CARRIED_FILES.duplicate()
	for done: String in [IMPORTED_SAVE, UNREADABLE_SAVE]:
		if FileAccess.file_exists(DEFAULT_ROOT.path_join(done)):
			files.erase(LEGACY_SAVE)
	if DirAccess.dir_exists_absolute(DEFAULT_ROOT.path_join("characters")):
		files.erase(LEGACY_SAVE)
	for former: String in FORMER_NAMES:
		carry_over(here.get_base_dir().path_join(former), here, files)


## Copies each of `files` from `from_dir` to `to_dir` when it exists there
## and is not in `to_dir` yet, so newer files are never overwritten. Returns
## the files copied.
static func carry_over(from_dir: String, to_dir: String, files: Array) -> Array[String]:
	var copied: Array[String] = []
	for file: String in files:
		var source := from_dir.path_join(file)
		var target := to_dir.path_join(file)
		if not FileAccess.file_exists(source) or FileAccess.file_exists(target):
			continue
		var data := FileAccess.get_file_as_bytes(source)
		var out := FileAccess.open(target, FileAccess.WRITE)
		if out == null:
			push_warning(
				"could not carry %s over: %s" % [file, error_string(FileAccess.get_open_error())]
			)
			continue
		out.store_buffer(data)
		out.close()
		copied.append(file)
	return copied


## A new character id: 16 random hex digits (64 bits), so ids never clash
## between characters, accounts or devices. The server will key a character
## by (account, id) and its item copies by (character id, copy key).
static func new_id() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()


func folder() -> String:
	return root.path_join("characters")


func path_of(id: String) -> String:
	return folder().path_join(id + ".json")


func has_characters() -> bool:
	return not _ids().is_empty()


## Slots in use: every character with files, readable or not, so a save
## that cannot be read still holds its place (and is never overwritten).
func slots_used() -> int:
	return _ids().size()


## Every playable character, last played first.
func characters(content: ContentDB) -> Array[PlayerProfile]:
	_import_legacy(content)
	var found: Array[PlayerProfile] = []
	for id in _ids():
		var profile := load_character(id, content)
		if profile:
			found.append(profile)
	found.sort_custom(
		func(a: PlayerProfile, b: PlayerProfile) -> bool:
			return a.saved_at > b.saved_at if a.saved_at != b.saved_at else a.id < b.id
	)
	return found


## Characters whose every file fails to load (corrupt, or from a newer
## build). They are listed, not hidden, and kept until the player deletes.
func unreadable(content: ContentDB) -> Array[String]:
	var ids: Array[String] = []
	for id in _ids():
		if load_character(id, content) == null:
			ids.append(id)
	return ids


## Writes safely: the new save goes to a temporary file, is read back and
## compared, the current save is kept as .bak, and only then the new one
## takes its place. A failed write never touches the good save. A character
## not saved before is refused once the account is full
## (RosterRules.max_characters), so none is ever out of reach.
func save(profile: PlayerProfile) -> bool:
	if read_only:
		return false
	if not RosterRules.is_id(profile.id):
		push_warning("save refused: the character has no id")
		return false
	var limit := RosterRules.max_characters(GameSession.content)
	if not profile.id in _ids() and _ids().size() >= limit:
		push_warning("save refused: the account already has %d characters" % limit)
		return false
	DirAccess.make_dir_recursive_absolute(folder())
	profile.saved_at = int(Time.get_unix_time_from_system())
	var target := path_of(profile.id)
	var temp := target + ".tmp"
	var text := JSON.stringify(profile.to_dict())
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	var written := file.store_string(text) and file.get_error() == OK
	file.close()
	if not written or FileAccess.get_file_as_string(temp) != text:
		push_warning("save failed: the file did not read back as written")
		DirAccess.remove_absolute(temp)
		return false
	if FileAccess.file_exists(target):
		DirAccess.copy_absolute(target, target + ".bak")
	return DirAccess.rename_absolute(temp, target) == OK


## Character `id`: its save, else a complete save left by an interrupted
## rename, else its last good save. Null when none can be used. A file
## claiming another id is not trusted.
func load_character(id: String, content: ContentDB) -> PlayerProfile:
	if not RosterRules.is_id(id):
		return null
	var newest: PlayerProfile = null
	for suffix: String in SUFFIXES:
		var path := folder().path_join(id + suffix)
		if not FileAccess.file_exists(path):
			continue
		var profile := _read(path, content)
		if profile and profile.id == id and (newest == null or profile.saved_at > newest.saved_at):
			newest = profile
		if newest and suffix == ".json":
			return newest
	return newest


## Moves character `id`'s files out of the roster (to characters/deleted/).
func delete_character(id: String) -> bool:
	if read_only or not id in _ids():
		return false
	var bin := folder().path_join("deleted")
	DirAccess.make_dir_recursive_absolute(bin)
	var stamp := int(Time.get_unix_time_from_system())
	var moved := false
	for suffix: String in SUFFIXES:
		var path := folder().path_join(id + suffix)
		if FileAccess.file_exists(path):
			var aside := bin.path_join("%s-%d%s" % [id, stamp, suffix])
			moved = DirAccess.rename_absolute(path, aside) == OK or moved
	return moved


## Removes every save under `root` (tests use their own root).
func delete_all() -> void:
	for dir: String in [folder().path_join("deleted"), folder()]:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file))
		DirAccess.remove_absolute(dir)
	for file: String in [LEGACY_SAVE, IMPORTED_SAVE, UNREADABLE_SAVE]:
		if FileAccess.file_exists(root.path_join(file)):
			DirAccess.remove_absolute(root.path_join(file))


## In the browser every tab has its own copy of the files and writes it all
## back to IndexedDB, so two tabs would undo each other's saves (or delete a
## new character). The first tab takes a Web Lock and keeps it; a later tab
## finds it taken (web_lock_state() == "taken") and must not save.
func claim_web_lock() -> void:
	if not OS.has_feature("web"):
		return
	(
		JavaScriptBridge
		. eval(
			"""
		window.ironLegacyLock = 'pending';
		if (navigator.locks) {
			navigator.locks.request('the-iron-legacy-saves', {ifAvailable: true}, (lock) => {
				if (!lock) { window.ironLegacyLock = 'taken'; return; }
				window.ironLegacyLock = 'held';
				return new Promise(() => {});
			});
		} else { window.ironLegacyLock = 'held'; }
		""",
			true
		)
	)


## "held", "taken", "pending", or "held" off the web.
func web_lock_state() -> String:
	if not OS.has_feature("web"):
		return "held"
	return str(JavaScriptBridge.eval("window.ironLegacyLock || 'pending'", true))


func _ids() -> Array[String]:
	var ids: Array[String] = []
	if not DirAccess.dir_exists_absolute(folder()):
		return ids
	for file in DirAccess.get_files_at(folder()):
		var id := file.left(16)
		if RosterRules.is_id(id) and file.substr(16) in SUFFIXES and not id in ids:
			ids.append(id)
	return ids


func _read(path: String, content: ContentDB) -> PlayerProfile:
	# JSON.parse (unlike parse_string) reports bad input as a return code
	# instead of logging an engine error.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("save at %s is not valid JSON; ignoring it" % path)
		return null
	return PlayerProfile.from_dict(json.data, content)


## The one save of builds before character slots becomes a character; the
## old file is renamed, not deleted, and only once it is safely written. Its
## id comes from its content; if that character exists already (an earlier
## import whose rename failed) it is never overwritten. A save that cannot
## be read is set aside once (kept, not deleted) rather than re-read forever.
func _import_legacy(content: ContentDB) -> void:
	var legacy := root.path_join(LEGACY_SAVE)
	if read_only or not FileAccess.file_exists(legacy):
		return
	var profile := _read(legacy, content)
	if profile == null:
		DirAccess.rename_absolute(legacy, root.path_join(UNREADABLE_SAVE))
		return
	if not RosterRules.is_id(profile.id):
		profile.id = FileAccess.get_sha256(legacy).left(16)
	if profile.id in _ids() or save(profile):
		DirAccess.rename_absolute(legacy, root.path_join(IMPORTED_SAVE))
