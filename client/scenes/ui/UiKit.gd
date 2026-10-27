class_name UiKit
extends RefCounted
## Building blocks for screens, all styled by UiTheme. Rules every screen
## follows: text that may wrap gets an explicit width (never wrap inside an
## unsized container, which wraps every word); modal windows have a fixed
## size inside the 640x360 base viewport; the first actionable control gets
## focus so keyboard and gamepad always work.

const DIALOG_WIDTH := 560.0
## The part of a 64x64 LPC frame that shows the head and shoulders.
const PORTRAIT_CROP := Rect2(16, 10, 32, 32)


static func label(
	text: String, size := UiTheme.SIZE_BODY, color := UiTheme.TEXT, wrap_width := 0.0
) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if wrap_width > 0.0:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.custom_minimum_size.x = wrap_width
	return node


## A label readable over the game world: outlined.
static func overlay_label(text: String, size := UiTheme.SIZE_BODY, color := UiTheme.TEXT) -> Label:
	var node := label(text, size, color)
	node.add_theme_constant_override("outline_size", 3)
	return node


static func button(text: String, on_press: Callable, disabled := false) -> Button:
	var node := Button.new()
	node.text = text
	node.disabled = disabled
	node.focus_mode = Control.FOCUS_ALL
	node.pressed.connect(Sfx.play.bind("ui_select", -4.0))
	node.pressed.connect(on_press)
	return node


## The large, left-accented buttons of the title screen.
static func menu_button(text: String, on_press: Callable, disabled := false) -> Button:
	var node := button(text, on_press, disabled)
	var styles := UiTheme.menu_button_styles()
	for state: String in styles:
		node.add_theme_stylebox_override(state, styles[state])
	node.add_theme_font_size_override("font_size", UiTheme.SIZE_H2)
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.custom_minimum_size = Vector2(150, 22)
	node.focus_entered.connect(Sfx.play.bind("ui_move", -6.0))
	return node


## A modal window of a fixed size, centred over a dimmed screen. Returns
## {"root": Control (add to a CanvasLayer, free to close), "body": VBoxContainer}.
static func window(title: String, size: Vector2, close_hint := "Esc  Close") -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var frame := PanelContainer.new()
	frame.name = "Window"
	frame.custom_minimum_size = size
	frame.size = size
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	root.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UiTheme.GAP)
	frame.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := label(title, UiTheme.SIZE_H1, UiTheme.ACCENT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	if close_hint:
		var hint := label(close_hint, UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(hint)
	column.add_child(HSeparator.new())
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", UiTheme.GAP)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	return {"root": root, "body": body, "frame": frame}


## A titled block inside a window.
static func section(title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(label(title.to_upper(), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	return box


## Text on the left, any control on the right.
static func row(text: String, right: Control, color := UiTheme.TEXT) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UiTheme.GAP)
	var caption := label(text, UiTheme.SIZE_BODY, color)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.clip_text = true
	line.add_child(caption)
	line.add_child(right)
	return line


## A key-cap and what it does, e.g. [E] Talk.
static func key_hint(key: String, action: String) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 3)
	var cap := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.9, 0.86)
	style.set_corner_radius_all(2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	cap.add_theme_stylebox_override("panel", style)
	cap.add_child(label(key, UiTheme.SIZE_CAPTION, UiTheme.BG))
	line.add_child(cap)
	line.add_child(label(action, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	return line


## An icon from the generated UI sheet (tools/assets/gen_ui.py).
static func icon(content: ContentDB, id: String) -> Texture2D:
	var icons: Dictionary = content.ui.get("icons", {})
	var region: Array = icons.get("regions", {}).get(id, [])
	if region.is_empty():
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(icons["sheet"])
	atlas.region = Rect2(region[0], region[1], region[2], region[3])
	return atlas


static func icon_rect(content: ContentDB, id: String, scale := 1.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon(content, id)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.custom_minimum_size = Vector2(16, 16) * scale
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


## Gives keyboard/gamepad focus to the first visible, enabled focusable
## control (one marked with the "start_focus" meta first, for screens that
## open on something other than their first control). Deferred, so it also
## works on a screen built this frame.
static func focus_first(root: Node) -> void:
	# By id: the screen may be freed (replaced) before the deferred call runs.
	_focus_first_now.call_deferred(root.get_instance_id())


static func _focus_first_now(root_id: int) -> void:
	var root := instance_from_id(root_id) as Node
	if root == null or not root.is_inside_tree():
		return
	var first: Control = null
	for child in root.find_children("*", "Control", true, false):
		var control: Control = child
		if (
			control.focus_mode == Control.FOCUS_ALL
			and control.is_visible_in_tree()
			and not (control is BaseButton and control.disabled)
		):
			if control.has_meta("start_focus"):
				first = control
				break
			if first == null:
				first = control
	if first:
		first.grab_focus()


## A conversation box along the bottom of the screen, with an optional
## portrait. Grows upward to fit its body. Returns {"root", "body"}.
static func dialog(speaker: String, portrait: Texture2D) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.3)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var frame := PanelContainer.new()
	frame.name = "Dialog"
	frame.custom_minimum_size.x = DIALOG_WIDTH
	frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.grow_vertical = Control.GROW_DIRECTION_BEGIN
	frame.offset_left = -DIALOG_WIDTH / 2.0
	frame.offset_right = DIALOG_WIDTH / 2.0
	frame.offset_bottom = -UiTheme.SCREEN_MARGIN
	frame.offset_top = -UiTheme.SCREEN_MARGIN
	root.add_child(frame)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UiTheme.PAD)
	frame.add_child(line)
	if portrait:
		var holder := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("0b0c14")
		style.border_color = UiTheme.ACCENT_DARK
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		holder.add_theme_stylebox_override("panel", style)
		holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		line.add_child(holder)
		var picture := TextureRect.new()
		picture.texture = portrait
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(64, 64)
		holder.add_child(picture)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", UiTheme.GAP)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(body)
	body.add_child(label(speaker, UiTheme.SIZE_H2, UiTheme.ACCENT))
	return {"root": root, "body": body}


## The head and shoulders of a character, cut from the first idle frame of
## its imported SpriteFrames, or null when it has no art.
static func portrait(content: ContentDB, art_id: String) -> Texture2D:
	var entry: Dictionary = content.art.get(art_id, {})
	if entry.get("status") != "imported":
		return null
	var frames: SpriteFrames = load(str(entry["sheet"]).get_base_dir().path_join(art_id + ".tres"))
	if frames == null or not frames.has_animation("idle"):
		return null
	var frame := frames.get_frame_texture("idle", 0) as AtlasTexture
	if frame == null:
		return null
	var crop := AtlasTexture.new()
	crop.atlas = frame.atlas
	# Art drawn at other proportions than LPC says where its head is.
	var rect := PORTRAIT_CROP
	var custom: Array = entry.get("portrait", [])
	if custom.size() == 4:
		rect = Rect2(custom[0], custom[1], custom[2], custom[3])
	crop.region = Rect2(frame.region.position + rect.position, rect.size)
	return crop
