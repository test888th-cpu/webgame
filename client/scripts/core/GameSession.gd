extends Node
## Game-wide state that outlives scene changes: the loaded content and the
## profile being played. Scenes read it; only Game.gd changes the profile.

var content: ContentDB
var profile: PlayerProfile


func _ready() -> void:
	content = ContentDB.load_all()
	for error in content.errors:
		push_error("content: " + error)


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
