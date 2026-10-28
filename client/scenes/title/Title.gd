extends Node2D
## Title screen. A slow pan along Saltmarket Street at night behind the logo
## and menu, the heroes and a Murk creature in the foreground. With saved
## characters, Continue (the one played last, shown on a card) comes first,
## then Characters: every character of the account, to play, make another
## (up to RosterRules.max_characters) or delete. Without, New game opens hero
## creation. A new character never replaces another.
## Prints the boot marker the browser smoke test waits for.

const BOOT_MARKER := "BOOT_OK"
const GAME_SCENE := "res://scenes/game/Game.tscn"
const CREATE_SCENE := "res://scenes/create/CharacterCreate.tscn"
const BACKDROP_AREA := "saltmarket"
const PAN_SECONDS := 45.0

var menu: Control
var _modal: Control
var _roster: Array[PlayerProfile] = []
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
	if not Scenery.build(_world, content, BACKDROP_AREA):
		return
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
	logo.position = Vector2(34, 34)
	logo.add_theme_constant_override("separation", -6)
	_ui.add_child(logo)
	logo.add_child(UiKit.overlay_label("T  H  E", UiTheme.SIZE_SMALL, UiTheme.TEAL))
	var title := UiKit.overlay_label("IRON", UiTheme.SIZE_LOGO, UiTheme.ACCENT)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color("2a1406"))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	logo.add_child(title)
	logo.add_child(UiKit.overlay_label("L  E  G  A  C  Y", UiTheme.SIZE_H1, UiTheme.TEAL))
	# Story bible §7: The Core is not named before chapter 3, so the tagline
	# only promises the street.
	var tagline := UiKit.label(
		"Take Iron City back, one street at a time.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM
	)
	tagline.position = Vector2(36, 124)
	_ui.add_child(tagline)

	menu = VBoxContainer.new()
	menu.name = "Menu"
	menu.position = Vector2(30, 150)
	menu.add_theme_constant_override("separation", 3)
	_ui.add_child(menu)
	_roster = SaveStore.characters(content)
	if _roster:
		menu.add_child(UiKit.menu_button("Continue", _continue))
		menu.add_child(UiKit.menu_button("Characters", open_characters))
	else:
		menu.add_child(UiKit.menu_button("New game", _new_game))
	menu.add_child(UiKit.menu_button("Gallery", _gallery))
	menu.add_child(UiKit.menu_button("Credits", _credits))
	UiKit.focus_first(menu)

	# The saved hero leads the line-up; otherwise the whole roster.
	var heroes: Array = content.hero_order.duplicate()
	var saved: PlayerProfile = _roster[0] if _roster else null
	if saved:
		heroes.erase(saved.hero)
		heroes.push_front(saved.hero)
		_save_card(content, saved)
	# Back to front, so the leading hero is drawn last (on top).
	for i in range(heroes.size() - 1, -1, -1):
		var sprites: Dictionary = content.hero(heroes[i])["sprites"]
		Showcase.add(
			_ui, content, sprites["default"], Vector2(470 - i * 46, 326 - i * 4), 2.5 - i * 0.3
		)
	Showcase.add(_ui, content, "smogling", Vector2(590, 326), 2.0, true)

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


func _unhandled_input(event: InputEvent) -> void:
	if _modal and event.is_action_pressed("pause"):
		_close_modal()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_probe_timer += delta
	if _probe_timer >= 0.1:
		_probe_timer = 0.0
		GameSession.publish_probe({"scene": "title", "has_save": not _roster.is_empty()})


func _new_game() -> void:
	get_tree().change_scene_to_file(CREATE_SCENE)


## Who you continue as: portrait, name, hero, level and where.
func _save_card(content: ContentDB, saved: PlayerProfile) -> void:
	var card := PanelContainer.new()
	card.name = "SaveCard"
	var style := UiTheme.panel_style()
	style.bg_color = Color(0.05, 0.05, 0.09, 0.82)
	style.set_content_margin_all(5)
	card.add_theme_stylebox_override("panel", style)
	card.position = Vector2(190, 150)
	_ui.add_child(card)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	card.add_child(line)
	var hero := content.hero(saved.hero)
	var picture := TextureRect.new()
	picture.texture = UiKit.portrait(content, str(hero["sprites"]["default"]))
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.custom_minimum_size = Vector2(32, 32)
	line.add_child(picture)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	line.add_child(text)
	text.add_child(UiKit.label(saved.name, UiTheme.SIZE_H2, UiTheme.TEXT))
	text.add_child(
		UiKit.label(
			"%s  -  Level %d" % [hero["title"], saved.level], UiTheme.SIZE_SMALL, UiTheme.ACCENT
		)
	)
	text.add_child(
		UiKit.label(
			str(content.area(saved.area).get("name", "")), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM
		)
	)


## The account's characters: play one, make another, or delete one.
func open_characters() -> void:
	_roster = SaveStore.characters(GameSession.content)
	_open_modal(
		CharacterSelect.build(GameSession.content, _roster, _play, _new_game, _delete, _close_modal)
	)


func _play(id: String) -> void:
	if GameSession.play(id):
		get_tree().change_scene_to_file(GAME_SCENE)


## Deleting rebuilds the whole title (the Continue card, the line-up and the
## menu all name the characters), back on the Characters screen if any are
## left.
func _delete(id: String) -> void:
	SaveStore.delete_character(id)
	Sfx.play("break_metal", -6.0)
	_modal = null
	for child in _ui.get_children():
		_ui.remove_child(child)
		child.queue_free()
	_build_ui(GameSession.content)
	if _roster:
		open_characters()


func _continue() -> void:
	if _roster:
		_play(_roster[0].id)


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
