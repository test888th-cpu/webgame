extends Node2D
## Hero creation, between the title and the first area:
##   left    the roster: a card per hero (portrait, name, role, difficulty)
##   centre  the selected hero, large, showing off its moves, with its name,
##           role and tagline
##   right   about, play style, stats compared across the roster, and skills
##   bottom  the player's name for the hero, Back and Start
## Up/Down (or a click) picks a hero, Enter moves on to the name and Enter
## again starts; Esc steps back. Everything shown comes from heroes.json and
## skills.json, so adding a hero needs no change here.

const GAME_SCENE := "res://scenes/game/Game.tscn"
const TITLE_SCENE := "res://scenes/title/Title.tscn"
const BACKDROP_AREA := "depot_yard"
const CARD_SIZE := Vector2(138, 50)
const PANEL_WIDTH := 262.0
## The spotlight cycles through these animations to show the hero off.
const SHOWOFF := ["idle", "light", "idle", "heavy"]
const SHOWOFF_SECONDS := 1.6
## Suggestions for the Random button.
const RANDOM_NAMES := [
	"Ace",
	"Blaze",
	"Kai",
	"Rook",
	"Nova",
	"Jinx",
	"Tao",
	"Vega",
	"Iko",
	"Rex",
	"Zara",
	"Bo",
	"Juno",
	"Sable",
	"Kenji",
	"Lark",
	"Mako",
	"Pike",
	"Rin",
	"Sol"
]
## Stat bars are scaled against these values (the strongest hero fills them).
const STAT_ROWS := [
	["Health", "max_hp", UiTheme.HP],
	["Power", "power", UiTheme.ACCENT],
	["Defense", "defense", UiTheme.TEAL],
	["Speed", "speed", UiTheme.GOOD],
]

var content: ContentDB
var selected := ""
var cards := {}
var name_field: LineEdit
var start_button: Button

var _spotlight: Node2D
var _sprite: AnimatedSprite2D
var _showoff_step := 0
var _showoff_left := SHOWOFF_SECONDS
var _hero_name: Label
var _hero_title: Label
var _tagline: Label
var _details: VBoxContainer
var _name_hint: Label
var _name_edited := false
var _probe_timer := 0.0

@onready var _world: Node2D = $World
@onready var _ui: CanvasLayer = $Ui


func _ready() -> void:
	content = GameSession.content
	_build_backdrop()
	_build_layout()
	select(str(content.hero_order[0]))
	cards[selected].grab_focus.call_deferred()


func _build_backdrop() -> void:
	var scenery: Dictionary = content.environment.get("areas", {}).get(BACKDROP_AREA, {})
	if not scenery.is_empty():
		Scenery.build(_world, content, scenery)
	var camera := Camera2D.new()
	camera.position = Vector2(420, 180)
	_world.add_child(camera)
	var shade := ColorRect.new()
	shade.color = Color(UiTheme.BG, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)


func _build_layout() -> void:
	var header := VBoxContainer.new()
	header.position = Vector2(12, 8)
	header.add_theme_constant_override("separation", 0)
	_ui.add_child(header)
	header.add_child(UiKit.overlay_label("CREATE YOUR FIGHTER", UiTheme.SIZE_H1, UiTheme.ACCENT))
	header.add_child(
		UiKit.label(
			"Choose a hero, give them a name, and take back the streets.",
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_DIM
		)
	)
	_build_roster()
	_build_spotlight()
	_build_details_panel()
	_build_bottom_bar()


func _build_roster() -> void:
	var roster := VBoxContainer.new()
	roster.name = "Roster"
	roster.position = Vector2(12, 48)
	roster.add_theme_constant_override("separation", 6)
	_ui.add_child(roster)
	roster.add_child(UiKit.label("HEROES", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	for hero_id: String in content.hero_order:
		var card := _hero_card(hero_id)
		roster.add_child(card)
		cards[hero_id] = card


## A focusable card: portrait, name, role, gender and difficulty.
func _hero_card(hero_id: String) -> Button:
	var hero := content.hero(hero_id)
	var card := Button.new()
	card.name = "Card_" + hero_id
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.toggle_mode = true
	card.tooltip_text = str(hero["tagline"])
	card.focus_entered.connect(select.bind(hero_id))
	card.focus_entered.connect(Sfx.play.bind("ui_move", -6.0))
	card.pressed.connect(_confirm_hero.bind(hero_id))
	# Selected (pressed) cards stay dark with a bright frame so the text keeps
	# its contrast; the theme's pressed style is a solid orange.
	var rest := _card_style(UiTheme.PANEL_LIGHT, UiTheme.BORDER, 1)
	var chosen := _card_style(Color("2a2116"), UiTheme.ACCENT, 2)
	card.add_theme_stylebox_override("normal", rest)
	card.add_theme_stylebox_override("hover", _card_style(Color("262a44"), UiTheme.ACCENT_DARK, 1))
	card.add_theme_stylebox_override("pressed", chosen)
	card.add_theme_stylebox_override("hover_pressed", chosen)
	card.add_theme_stylebox_override("focus", _card_style(Color(0, 0, 0, 0), Color.WHITE, 1, false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("0b0c14")
	frame_style.border_color = Color.from_string(str(hero.get("color", "#f2a54a")), UiTheme.ACCENT)
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	var picture := TextureRect.new()
	picture.texture = UiKit.portrait(content, str(hero["sprites"]["default"]))
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.custom_minimum_size = Vector2(40, 40)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(picture)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -1)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	text.add_child(UiKit.label(str(hero["default_name"]), UiTheme.SIZE_H2, UiTheme.TEXT))
	text.add_child(
		UiKit.label(
			str(hero["title"]).to_upper(),
			UiTheme.SIZE_CAPTION,
			Color.from_string(str(hero.get("color", "")), UiTheme.ACCENT)
		)
	)
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 6)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.add_child(UiKit.label(str(hero.get("gender", "")), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	meta.add_child(_pips(int(hero["difficulty"])))
	text.add_child(meta)
	for node in text.find_children("*", "Control", true, false):
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _build_spotlight() -> void:
	_spotlight = Node2D.new()
	_spotlight.name = "Spotlight"
	_ui.add_child(_spotlight)
	var glow := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.8, 0.5, 0.28))
	gradient.set_color(1, Color(1, 0.8, 0.5, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	glow.texture = texture
	glow.position = Vector2(170, 90)
	glow.size = Vector2(150, 220)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(glow)
	_ui.move_child(glow, _spotlight.get_index())
	var names := VBoxContainer.new()
	names.position = Vector2(160, 44)
	names.custom_minimum_size.x = 170
	names.add_theme_constant_override("separation", -2)
	_ui.add_child(names)
	_hero_name = UiKit.overlay_label("", UiTheme.SIZE_H1 + 4, UiTheme.TEXT)
	_hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_name.add_theme_constant_override("outline_size", 5)
	names.add_child(_hero_name)
	_hero_title = UiKit.overlay_label("", UiTheme.SIZE_SMALL, UiTheme.ACCENT)
	_hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.add_child(_hero_title)
	_tagline = UiKit.label("", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, 170)
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline.add_theme_constant_override("outline_size", 3)
	names.add_child(_tagline)


func _build_details_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "Details"
	panel.position = Vector2(640 - PANEL_WIDTH - 10, 8)
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 306)
	panel.size = panel.custom_minimum_size
	_ui.add_child(panel)
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 3)
	panel.add_child(_details)


func _build_bottom_bar() -> void:
	var bar := PanelContainer.new()
	bar.name = "NameBar"
	var style := UiTheme.panel_style()
	style.bg_color = Color(0.05, 0.05, 0.09, 0.9)
	style.set_content_margin_all(5)
	bar.add_theme_stylebox_override("panel", style)
	bar.position = Vector2(10, 320)
	bar.custom_minimum_size = Vector2(620, 32)
	bar.size = bar.custom_minimum_size
	_ui.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	var caption := UiKit.label("NAME", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	name_field = LineEdit.new()
	name_field.name = "NameField"
	name_field.custom_minimum_size = Vector2(130, 20)
	name_field.max_length = PlayerProfile.NAME_MAX
	name_field.placeholder_text = "Your hero's name"
	name_field.add_theme_font_size_override("font_size", UiTheme.SIZE_H2)
	name_field.text_changed.connect(_on_name_changed)
	name_field.text_submitted.connect(func(_text: String) -> void: start())
	row.add_child(name_field)
	var dice := UiKit.button("Random", _random_name)
	dice.tooltip_text = "Suggest a name"
	row.add_child(dice)
	_name_hint = UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	_name_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_name_hint)
	row.add_child(UiKit.button("Back", _back))
	start_button = UiKit.button("Start  >", start)
	start_button.name = "Start"
	start_button.custom_minimum_size.x = 84
	var lit := UiTheme.menu_button_styles()["focus"] as StyleBoxFlat
	start_button.add_theme_stylebox_override("normal", _start_style())
	start_button.add_theme_stylebox_override("hover", lit)
	start_button.add_theme_stylebox_override("focus", lit)
	start_button.add_theme_font_size_override("font_size", UiTheme.SIZE_H2)
	row.add_child(start_button)


func _start_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.ACCENT_DARK
	style.border_color = UiTheme.ACCENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style


## Shows `hero_id` in the spotlight and the details panel.
func select(hero_id: String) -> void:
	if hero_id == selected or not content.heroes.has(hero_id):
		return
	var previous_default := str(content.hero(selected).get("default_name", ""))
	selected = hero_id
	var hero := content.hero(hero_id)
	for id: String in cards:
		cards[id].button_pressed = id == hero_id
	var color := Color.from_string(str(hero.get("color", "")), UiTheme.ACCENT)
	_hero_name.text = str(hero["name"])
	_hero_title.text = str(hero["title"]).to_upper()
	_hero_title.add_theme_color_override("font_color", color)
	_tagline.text = str(hero["tagline"])
	for child in _spotlight.get_children():
		child.queue_free()
	_sprite = Showcase.add(
		_spotlight, content, str(hero["sprites"]["default"]), Vector2(245, 300), 3.0
	)
	_showoff_step = 0
	_showoff_left = SHOWOFF_SECONDS
	_fill_details(hero)
	# Keep a name the player typed; otherwise suggest the hero's own.
	if not _name_edited or name_field.text == previous_default:
		name_field.text = str(hero["default_name"])
		_name_edited = false
	_on_name_changed(name_field.text)


func _fill_details(hero: Dictionary) -> void:
	for child in _details.get_children():
		child.queue_free()
	var about := UiKit.section("About")
	about.add_child(
		UiKit.label(str(hero["bio"]), UiTheme.SIZE_SMALL, UiTheme.TEXT, PANEL_WIDTH - 18)
	)
	_details.add_child(about)

	var style := UiKit.section("Play style")
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 3)
	for tag: String in hero.get("style", []):
		tags.add_child(_chip(tag))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tags.add_child(gap)
	tags.add_child(UiKit.label("Difficulty", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	tags.add_child(_pips(int(hero["difficulty"])))
	style.add_child(tags)
	_details.add_child(style)

	var stats := UiKit.section("Stats")
	var best := _best_stats()
	var base: Dictionary = hero["stats"]
	for row: Array in STAT_ROWS:
		var key: String = row[1]
		var bar := StatBar.new()
		bar.color = row[2]
		bar.show_text = false
		bar.custom_minimum_size = Vector2(110, 6)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.set_values(float(base[key]) + _bar_floor(key), best[key] + _bar_floor(key), true)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		var name_label := UiKit.label(row[0], UiTheme.SIZE_SMALL, UiTheme.TEXT)
		name_label.custom_minimum_size.x = 54
		line.add_child(name_label)
		line.add_child(bar)
		line.add_child(
			UiKit.label(_stat_text(key, base[key]), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM)
		)
		stats.add_child(line)
	_details.add_child(stats)

	var skills := UiKit.section("Skills")
	for skill_id: String in hero["skills"]:
		skills.add_child(_skill_row(skill_id))
	_details.add_child(skills)


func _skill_row(skill_id: String) -> Control:
	var skill: Dictionary = content.skills[skill_id]
	var move := content.moves.get_move(str(skill["move"]))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 5)
	line.tooltip_text = str(skill["description"])
	line.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon := UiKit.icon_rect(content, str(skill["icon"]))
	icon.custom_minimum_size = Vector2(16, 16)
	line.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", -2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	text.add_child(UiKit.label(str(skill["name"]), UiTheme.SIZE_SMALL, UiTheme.TEXT))
	var detail := UiKit.label(
		str(skill["description"]), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, PANEL_WIDTH - 80
	)
	detail.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.clip_text = true
	text.add_child(detail)
	var meta := UiKit.label(
		"Lv %d   %ds" % [skill["unlock_level"], roundi(skill["cooldown"] / 60.0)],
		UiTheme.SIZE_CAPTION,
		UiTheme.ACCENT
	)
	meta.tooltip_text = "Energy %d" % roundi(move.energy_cost)
	line.add_child(meta)
	return line


func _chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.set_corner_radius_all(6)
	style.content_margin_left = 5
	style.content_margin_right = 5
	chip.add_theme_stylebox_override("panel", style)
	chip.add_child(UiKit.label(text, UiTheme.SIZE_CAPTION, UiTheme.TEXT))
	return chip


## The highest value of each stat across the roster, so bars compare heroes.
func _best_stats() -> Dictionary:
	var best := {}
	for id: String in content.heroes:
		var base: Dictionary = content.hero(id)["stats"]
		for row: Array in STAT_ROWS:
			best[row[1]] = maxf(float(best.get(row[1], 0.0)), float(base[row[1]]))
	return best


## Keeps a zero (defense 0) visible as a sliver rather than an empty bar.
func _bar_floor(key: String) -> float:
	return 1.0 if key == "defense" else 0.0


func _stat_text(key: String, value: Variant) -> String:
	match key:
		"power":
			return "%d%%" % roundi(float(value) * 100.0)
		"speed":
			return "%d%%" % roundi(float(value) * 100.0)
	return str(roundi(float(value)))


## Difficulty as three small blocks, `count` of them lit.
func _pips(count: int) -> HBoxContainer:
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 2)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in 3:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(6, 4)
		pip.color = UiTheme.GOLD if i < count else Color(1, 1, 1, 0.15)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
	return pips


func _card_style(bg: Color, border: Color, width: int, filled := true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.draw_center = filled
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	return style


func _on_name_changed(text: String) -> void:
	_name_edited = text != str(content.hero(selected).get("default_name", ""))
	var valid := PlayerProfile.clean_name(text) != ""
	start_button.disabled = not valid
	if valid:
		_name_hint.text = (
			"Letters, numbers, spaces.  %d-%d characters."
			% [PlayerProfile.NAME_MIN, PlayerProfile.NAME_MAX]
		)
		_name_hint.add_theme_color_override("font_color", UiTheme.TEXT_FAINT)
	else:
		_name_hint.text = (
			"Use %d-%d letters or numbers." % [PlayerProfile.NAME_MIN, PlayerProfile.NAME_MAX]
		)
		_name_hint.add_theme_color_override("font_color", UiTheme.DANGER)


func _random_name() -> void:
	var options: Array = RANDOM_NAMES.filter(func(n: String) -> bool: return n != name_field.text)
	name_field.text = str(options[randi() % options.size()])
	_on_name_changed(name_field.text)


## Enter on a card: that hero is chosen, move on to the name.
func _confirm_hero(hero_id: String) -> void:
	select(hero_id)
	cards[hero_id].button_pressed = true
	name_field.grab_focus()
	name_field.select_all()
	name_field.caret_column = name_field.text.length()


## Creates the profile and starts the game, if the name is valid.
func start() -> void:
	var player_name := PlayerProfile.clean_name(name_field.text)
	if player_name == "":
		Sfx.play("denied")
		name_field.grab_focus()
		return
	GameSession.start_new_game(selected, player_name)
	get_tree().change_scene_to_file(GAME_SCENE)


func _back() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	if name_field.has_focus():
		cards[selected].grab_focus()
	else:
		_back()


func _process(delta: float) -> void:
	_showoff_left -= delta
	if _showoff_left <= 0.0 and _sprite:
		_showoff_left = SHOWOFF_SECONDS
		_showoff_step = (_showoff_step + 1) % SHOWOFF.size()
		var anim: String = SHOWOFF[_showoff_step]
		if _sprite.sprite_frames.has_animation(anim):
			_sprite.play(anim)
	_probe_timer += delta
	if _probe_timer >= 0.1:
		_probe_timer = 0.0
		GameSession.publish_probe({"scene": "create", "hero": selected, "name": name_field.text})
