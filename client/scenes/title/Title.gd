extends Node2D
## Title screen. A slow pan along Saltmarket Street at night behind the logo
## and menu, the hero and a Murk creature in the foreground. Continue comes
## first when a save exists; New game asks before replacing a save.
## Prints the boot marker the browser smoke test waits for.

const BOOT_MARKER := "BOOT_OK"
const GAME_SCENE := "res://scenes/game/Game.tscn"
const BACKDROP_AREA := "saltmarket"
const PAN_SECONDS := 45.0

var menu: Control
var _modal: Control
var _probe_timer := 0.0

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera
@onready var _ui: CanvasLayer = $Ui


func _ready() -> void:
	var content := GameSession.content
	_build_backdrop(content)
	_build_ui(content)
	# The web smoke test waits for this exact line on the browser console.
	print("%s %s" % [BOOT_MARKER, BuildInfo.summary()])


func _build_backdrop(content: ContentDB) -> void:
	var scenery: Dictionary = content.environment.get("areas", {}).get(BACKDROP_AREA, {})
	if scenery.is_empty():
		return
	Scenery.build(_world, content, scenery)
	var width := float(content.area(BACKDROP_AREA).get("width", 960))
	_camera.limit_left = 0
	_camera.limit_right = int(width)
	_camera.position = Vector2(320, 180)
	var pan := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	pan.tween_property(_camera, "position:x", width - 320, PAN_SECONDS)
	pan.tween_property(_camera, "position:x", 320.0, PAN_SECONDS)


func _build_ui(content: ContentDB) -> void:
	var shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(UiTheme.BG, 0.94))
	gradient.set_color(1, Color(UiTheme.BG, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 8
	shade.texture = texture
	shade.position = Vector2.ZERO
	shade.size = Vector2(360, 360)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	_ui.add_child(shade)

	var logo := VBoxContainer.new()
	logo.position = Vector2(34, 42)
	logo.add_theme_constant_override("separation", -6)
	_ui.add_child(logo)
	var title := UiKit.overlay_label("IRONBOUND", UiTheme.SIZE_LOGO, UiTheme.ACCENT)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color("2a1406"))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	logo.add_child(title)
	logo.add_child(UiKit.overlay_label("S  T  R  E  E  T  S", UiTheme.SIZE_H1, UiTheme.TEAL))
	var tagline := UiKit.label(
		"Clear the Murk from Port Verrin, block by block.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM
	)
	tagline.position = Vector2(36, 118)
	_ui.add_child(tagline)

	menu = VBoxContainer.new()
	menu.name = "Menu"
	menu.position = Vector2(30, 150)
	menu.add_theme_constant_override("separation", 3)
	_ui.add_child(menu)
	if SaveStore.has_save():
		menu.add_child(UiKit.menu_button("Continue", _continue))
		menu.add_child(UiKit.menu_button("New game", _confirm_new_game))
	else:
		menu.add_child(UiKit.menu_button("New game", _new_game))
	menu.add_child(UiKit.menu_button("Characters", _gallery))
	menu.add_child(UiKit.menu_button("Credits", _credits))
	UiKit.focus_first(menu)

	_showcase(content, "hero_mika", Vector2(480, 326), 2.5, false)
	_showcase(content, "smogling", Vector2(585, 326), 2.0, true)

	var version := UiKit.label(BuildInfo.summary(), UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
	version.position = Vector2(UiTheme.SCREEN_MARGIN, 344)
	_ui.add_child(version)
	var hints := HBoxContainer.new()
	hints.add_theme_constant_override("separation", 10)
	hints.position = Vector2(34, 262)
	hints.add_child(UiKit.key_hint("Enter", "Select"))
	hints.add_child(UiKit.key_hint("W S", "Move"))
	hints.add_child(UiKit.key_hint("Esc", "Back"))
	_ui.add_child(hints)


func _showcase(content: ContentDB, id: String, at: Vector2, size: float, face_left: bool) -> void:
	var entry: Dictionary = content.art.get(id, {})
	if entry.get("status") != "imported":
		return
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.45)
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(at + Vector2(cos(angle) * 11.0 * size, sin(angle) * 2.5 * size))
	shadow.polygon = points
	_ui.add_child(shadow)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(str(entry["sheet"]).get_base_dir().path_join(id + ".tres"))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -Vector2(entry["origin"][0], entry["origin"][1])
	sprite.scale = Vector2(size, size)
	sprite.position = at
	sprite.flip_h = face_left
	_ui.add_child(sprite)
	sprite.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if _modal and event.is_action_pressed("pause"):
		_close_modal()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_probe_timer += delta
	if _probe_timer >= 0.1:
		_probe_timer = 0.0
		GameSession.publish_probe({"scene": "title", "has_save": SaveStore.has_save()})


func _new_game() -> void:
	GameSession.start_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _confirm_new_game() -> void:
	var window := UiKit.window("Start over?", Vector2(260, 104), "")
	var body: VBoxContainer = window["body"]
	body.add_child(
		UiKit.label(
			"Your saved progress will be replaced by a new game.",
			UiTheme.SIZE_BODY,
			UiTheme.TEXT_DIM,
			240
		)
	)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(UiKit.button("Keep my save", _close_modal))
	buttons.add_child(UiKit.button("Start over", _new_game))
	body.add_child(buttons)
	_open_modal(window["root"])


func _continue() -> void:
	if GameSession.continue_game():
		get_tree().change_scene_to_file(GAME_SCENE)


func _gallery() -> void:
	get_tree().change_scene_to_file("res://scenes/tools/Gallery.tscn")


func _credits() -> void:
	var window := UiKit.window("Credits", Vector2(440, 270))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(
		UiKit.label(CreditsText.build(GameSession.content), UiTheme.SIZE_SMALL, UiTheme.TEXT, 410)
	)
	window["body"].add_child(scroll)
	window["body"].add_child(UiKit.button("Close", _close_modal))
	_open_modal(window["root"])


func _open_modal(root: Control) -> void:
	_close_modal()
	_modal = root
	var layer := CanvasLayer.new()
	layer.layer = 5
	layer.add_child(root)
	_ui.add_child(layer)
	UiKit.focus_first(root)


func _close_modal() -> void:
	if _modal:
		_modal.get_parent().queue_free()
		_modal = null
		UiKit.focus_first(menu)
