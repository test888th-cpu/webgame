class_name UiKit
extends RefCounted
## Small helpers for building menus in code. The viewport is 640x360, so text
## sizes are small and everything sits in one centred panel.


## A centred panel filling the screen behind it. Returns the panel root (to
## add to a CanvasLayer and free when closed) and the VBox to fill.
static func panel(title: String, width := 300.0) -> Array:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(width, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14, 0.96)
	style.border_color = Color(0.85, 0.55, 0.25)
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel", style)
	center.add_child(box)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	box.add_child(list)
	list.add_child(label(title, 14, Color(1, 0.8, 0.45)))
	return [root, list]


static func label(text: String, size := 9, color := Color.WHITE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


static func button(text: String, on_press: Callable, disabled := false) -> Button:
	var node := Button.new()
	node.text = text
	node.disabled = disabled
	node.add_theme_font_size_override("font_size", 9)
	node.pressed.connect(on_press)
	return node


## A row: text on the left, a button on the right.
static func row(text: String, action: Button) -> HBoxContainer:
	var line := HBoxContainer.new()
	var caption := label(text)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(caption)
	line.add_child(action)
	return line


## Gives keyboard/gamepad focus to the first enabled button in `root`.
static func focus_first(root: Node) -> void:
	for child in root.find_children("*", "Button", true, false):
		var b: Button = child
		if not b.disabled:
			b.grab_focus.call_deferred()
			return
