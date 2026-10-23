extends Node
## Game-wide state that outlives scene changes: the loaded content and the
## profile being played. Scenes read it; only Game.gd changes the profile.

const SETTINGS_PATH := "user://settings.json"

var content: ContentDB
var profile: PlayerProfile
## Player preferences (not progression): kept in their own small file.
var settings := {"show_fps": false, "screen_shake": true}


func _ready() -> void:
	content = ContentDB.load_all()
	for error in content.errors:
		push_error("content: " + error)
	# The project theme (an empty base_theme.tres set in project.godot) is
	# filled at startup, so every Control, including those under CanvasLayers
	# where a node theme would not reach, uses UiTheme.
	var project_theme := ThemeDB.get_project_theme()
	if project_theme:
		project_theme.merge_with(UiTheme.build())
	_load_settings()


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var json := JSON.new()
	if (
		json.parse(FileAccess.get_file_as_string(SETTINGS_PATH)) != OK
		or not json.data is Dictionary
	):
		return
	for key: String in settings:
		if json.data.has(key) and typeof(json.data[key]) == typeof(settings[key]):
			settings[key] = json.data[key]


func start_new_game() -> void:
	profile = PlayerProfile.new_game(content)


## Returns false when there is no usable save.
func continue_game() -> bool:
	var loaded := SaveStore.load_profile(content)
	if loaded == null:
		return false
	profile = loaded
	return true


## Publishes read-only state for the browser smoke test (web builds only).
## Contains nothing a player could not already see on screen.
func publish_probe(state: Dictionary) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.ironboundProbe = %s;" % JSON.stringify(state), true)
