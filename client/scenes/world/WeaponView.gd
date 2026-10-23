class_name WeaponView
extends Node2D
## A weapon lying on the street: its sprite on its side with a shadow and a
## glint now and then so it catches the eye, and its name with "[E] Pick up"
## while the hero stands over it. Presentation only; ZoneSim owns the weapon.

const GLINT_SECONDS := 2.6
## Lying flat, slightly askew, grip to the left.
const LIE_ANGLE := 84.0

var entry: Dictionary
var _sprite: Sprite2D
var _prompt: Control
var _time := 0.0


func setup(content: ContentDB, p_entry: Dictionary) -> void:
	entry = p_entry
	name = "Weapon%d" % entry["id"]
	position = entry["position"]
	var weapon: Dictionary = content.weapons.get(str(entry["weapon"]), {})
	_time = float(int(entry["id"]) % 7) * 0.37
	_sprite = Sprite2D.new()
	_sprite.texture = UiKit.icon(content, str(weapon.get("sprite", "")))
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Turn about the middle of the sprite so it lies centred on its spot.
	_sprite.rotation_degrees = LIE_ANGLE if int(entry["id"]) % 2 == 0 else -LIE_ANGLE
	_sprite.position = Vector2(0, -3)
	add_child(_sprite)
	_prompt = VBoxContainer.new()
	_prompt.name = "Prompt"
	_prompt.alignment = BoxContainer.ALIGNMENT_CENTER
	_prompt.position = Vector2(-50, -34)
	_prompt.size = Vector2(100, 24)
	_prompt.visible = false
	var label := Label.new()
	label.text = str(weapon.get("name", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiTheme.SIZE_CAPTION)
	label.add_theme_color_override("font_color", UiTheme.GOLD)
	label.add_theme_constant_override("outline_size", 3)
	_prompt.add_child(label)
	var hint := CenterContainer.new()
	hint.add_child(UiKit.key_hint("E", "Pick up"))
	_prompt.add_child(hint)
	add_child(_prompt)


func set_highlight(on: bool) -> void:
	_prompt.visible = on
	_sprite.modulate = Color(1.35, 1.3, 1.1) if on else Color.WHITE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	# A short glint sweeping along the weapon every few seconds.
	var phase := fmod(_time, GLINT_SECONDS) / 0.35
	if phase < 1.0:
		var x := lerpf(-12.0, 12.0, phase)
		draw_circle(Vector2(x, -3), 2.0, Color(1, 1, 0.9, 0.8 * (1.0 - phase)))
