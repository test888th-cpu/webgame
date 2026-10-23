class_name TouchControls
extends RefCounted
## On-screen controls for touch devices: a d-pad on the left, combat and
## utility buttons on the right. Each is a TouchScreenButton bound to the same
## input action as the keyboard, so gameplay code only ever reads actions.

const PAD := [
	["Left", "move_left", Vector2(16, 276)],
	["Right", "move_right", Vector2(80, 276)],
	["Up", "move_up", Vector2(48, 244)],
	["Down", "move_down", Vector2(48, 308)],
]
const BUTTONS := [
	["Light", "attack_light", Vector2(560, 290), Color(0.9, 0.3, 0.3, 0.45), "J"],
	["Heavy", "attack_heavy", Vector2(600, 250), Color(0.95, 0.6, 0.2, 0.45), "K"],
	["Dodge", "dodge", Vector2(520, 250), Color(0.3, 0.6, 0.95, 0.45), "DODGE"],
	["Guard", "guard", Vector2(560, 210), Color(0.4, 0.85, 0.5, 0.45), "GUARD"],
	["Interact", "interact", Vector2(600, 170), Color(0.85, 0.85, 0.4, 0.45), "TALK"],
	["Item", "use_item", Vector2(520, 170), Color(0.6, 0.9, 0.7, 0.45), "EAT"],
	["Pause", "pause", Vector2(303, 4), Color(1, 1, 1, 0.3), "II"],
]


static func build() -> Control:
	var root := Control.new()
	root.name = "Touch"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for spec: Array in PAD:
		root.add_child(_button(spec[0], spec[1], spec[2], 30, Color(1, 1, 1, 0.22), ""))
	for spec: Array in BUTTONS:
		root.add_child(_button(spec[0], spec[1], spec[2], 34, spec[3], spec[4]))
	return root


static func _button(
	name: String, action: String, at: Vector2, size: float, color: Color, text: String
) -> TouchScreenButton:
	var button := TouchScreenButton.new()
	button.name = name
	button.position = at
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size)
	button.shape = shape
	button.shape_centered = false
	button.action = action
	button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var face := Polygon2D.new()
	face.color = color
	face.polygon = PackedVector2Array(
		[Vector2.ZERO, Vector2(size, 0), Vector2(size, size), Vector2(0, size)]
	)
	button.add_child(face)
	if text:
		var caption := Label.new()
		caption.text = text
		caption.size = Vector2(size, size)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", UiTheme.SIZE_CAPTION)
		button.add_child(caption)
	return button
