extends Node
## Game-wide state that outlives scene changes: the loaded content and the
## profile being played. Scenes read it; only Game.gd changes the profile.

## The screen layout changed (window resized or turned, input switched, or a
## screen opened or closed): the HUD, camera and touch controls re-read
## `layout`.
signal layout_changed(layout: ScreenLayout)

const SETTINGS_PATH := "user://settings.json"
## Reads the page's CSS safe-area insets (notches, rounded corners, system
## bars) in CSS px, scaled to the canvas: "left,top,right,bottom".
const SAFE_AREA_JS := """
(() => {
  const probe = document.createElement('div');
  probe.style.cssText = 'position:fixed;visibility:hidden;'
    + 'padding:env(safe-area-inset-top) env(safe-area-inset-right) '
    + 'env(safe-area-inset-bottom) env(safe-area-inset-left)';
  document.body.appendChild(probe);
  const s = getComputedStyle(probe);
  const canvas = document.querySelector('canvas');
  const k = canvas && canvas.clientWidth ? canvas.width / canvas.clientWidth : 1;
  const out = [s.paddingLeft, s.paddingTop, s.paddingRight, s.paddingBottom]
    .map((v) => (parseFloat(v) || 0) * k).join(',');
  probe.remove();
  return out;
})()
"""

var content: ContentDB
var profile: PlayerProfile
## Player preferences (not progression): kept in their own small file.
## Effect animations, built on first use by Fx.
var fx_library := {}
## Where everything goes on screen now (ScreenLayout). Set by relayout().
var layout: ScreenLayout
var settings := {
	"show_fps": false,
	"screen_shake": true,
	"sfx_volume": 0.8,
	# Auto battle (AutoBattle): eat below this health share, farm in a loop
	# (rest at home and ride back), and how much food to keep stocked.
	"auto_heal_at": 0.5,
	"auto_loop": true,
	"auto_food": 10.0,
}

## The street is being played: portrait gets its own layout. Off for the
## title and hero creation, and while a game screen (Bag, Map…) is open:
## those keep the landscape layout until their portrait designs (U1-B).
var _street_shown := false
var _screen_open := false


func _ready() -> void:
	SaveStore.claim_web_lock()
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
	_add_font_fallbacks()
	get_tree().root.size_changed.connect(relayout)
	InputSetup.device_changed.connect(func(_device: String) -> void: relayout())
	relayout()


## The street is shown (Game) or not; a game screen is open over it or not.
func show_street(shown: bool, screen_open := false) -> void:
	if shown == _street_shown and screen_open == _screen_open:
		return
	_street_shown = shown
	_screen_open = screen_open
	relayout()


## Works out the layout for the window as it is now and applies its logical
## canvas size. Called on resize, turn, input switch and screen changes.
func relayout() -> void:
	var root := get_tree().root
	var portrait_ok := _street_shown and not _screen_open
	var next := ScreenLayout.compute(
		Vector2(root.size), _safe_insets(), InputSetup.device, portrait_ok, _screen_open
	)
	if root.content_scale_size != next.base:
		root.content_scale_size = next.base
	layout = next
	layout_changed.emit(layout)


## Safe-area insets in window px (left, top, right, bottom): the page's CSS
## env() insets on the web, the display's safe area on phones, else none.
func _safe_insets() -> Vector4:
	if OS.has_feature("web"):
		var text := str(JavaScriptBridge.eval(SAFE_AREA_JS, true))
		var parts := text.split(",")
		if parts.size() == 4:
			return Vector4(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))
		return Vector4.ZERO
	if OS.has_feature("android") or OS.has_feature("ios"):
		var screen := Rect2(Vector2.ZERO, DisplayServer.screen_get_size())
		var safe := Rect2(DisplayServer.get_display_safe_area())
		return Vector4(
			safe.position.x - screen.position.x,
			safe.position.y - screen.position.y,
			screen.end.x - safe.end.x,
			screen.end.y - safe.end.y
		)
	return Vector4.ZERO


## The engine's default font has no Thai glyphs; Noto Sans Thai (OFL) is
## added as a fallback so Thai player names and text render.
func _add_font_fallbacks() -> void:
	var path := str(content.fonts.get("thai", {}).get("file", ""))
	var font: Font = ThemeDB.fallback_font
	if path == "" or font == null:
		return
	var fallbacks := font.fallbacks
	fallbacks.append(load(path))
	font.fallbacks = fallbacks


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


## A new character with an id of its own; it is saved as soon as it enters
## the street, next to the account's other characters.
func start_new_game(hero_id := "", player_name := "") -> void:
	profile = PlayerProfile.new_game(content, hero_id, player_name)
	profile.id = SaveStore.new_id()


## Plays character `id`. Returns false when it has no usable save.
func play(id: String) -> bool:
	var loaded := SaveStore.load_character(id, content)
	if loaded == null:
		return false
	profile = loaded
	return true


## Publishes read-only state for the browser smoke test (web builds only).
## Contains nothing a player could not already see on screen.
func publish_probe(state: Dictionary) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.ironboundProbe = %s;" % JSON.stringify(state), true)
