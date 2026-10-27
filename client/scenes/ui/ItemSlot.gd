class_name ItemSlot
extends Button
## One cell of the bag or the equipment doll: a framed icon in its rarity
## colour, a stack count, a faint silhouette when empty, and a red tint when
## the hero's level is too low to wear it. A Button, so keyboard, gamepad,
## mouse and touch all work, and grids get focus navigation for free.
## With a mouse (or a finger) items can also be dragged between slots: a slot
## hands over `drag_data` when dragged, lights up while something it
## `accepts` is being dragged, and calls `dropped` with it. A right click
## runs `quick` (equip, use or take off) without opening the card.

var item_id := ""
var count := 0
var frame_color := UiTheme.BORDER
var icon_texture: Texture2D
## Shown when the slot is empty (equipment slots).
var placeholder: Texture2D
var too_high_level := false
## The slot's upgrade level, drawn as a gold "+N" in the corner (worn slots).
var upgrade := 0
## What this slot hands over when dragged ({} when it cannot be dragged).
var drag_data: Dictionary = {}
## (data: Dictionary) -> bool: whether a dragged hand-over may land here.
var accepts := Callable()
## (data: Dictionary) -> void: what happens when it does.
var dropped := Callable()
## The right-click action, if any.
var quick := Callable()
var _drop_lit := false


func _init(size_px := 28.0) -> void:
	custom_minimum_size = Vector2(size_px, size_px)
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


## Shows `p_item_id` (or an empty cell when ""), `p_count` of them.
func show_item(content: ContentDB, p_item_id: String, p_count := 1, level := 99) -> void:
	item_id = p_item_id
	count = p_count
	var item := content.item(item_id)
	icon_texture = UiKit.icon(content, str(item.get("icon", ""))) if item else null
	frame_color = ItemText.rarity_color(item) if item else UiTheme.BORDER
	too_high_level = item.get("type") == "equipment" and int(item.get("level", 1)) > level
	tooltip_text = "%s\n%s" % [item["name"], ItemText.kind(item)] if item else ""
	queue_redraw()


func _get_drag_data(_at: Vector2) -> Variant:
	if drag_data.is_empty() or icon_texture == null:
		return null
	if get_viewport().gui_is_dragging():
		set_drag_preview(_drag_picture())
	Sfx.play("ui_move", -6.0)
	return drag_data


## The picture that follows the pointer, centred on it, at the slot's size.
func _drag_picture() -> Control:
	var holder := Control.new()
	var picture := TextureRect.new()
	picture.texture = icon_texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size = size
	picture.position = -size / 2.0
	picture.modulate.a = 0.85
	holder.add_child(picture)
	return holder


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return _takes(data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	_drop_lit = false
	dropped.call(data)


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT and quick.is_valid():
		accept_event()
		quick.call()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var data: Variant = get_viewport().gui_get_drag_data()
		_drop_lit = data is Dictionary and data != drag_data and _takes(data)
		queue_redraw()
	elif what == NOTIFICATION_DRAG_END and _drop_lit:
		_drop_lit = false
		queue_redraw()


func _takes(data: Variant) -> bool:
	return data is Dictionary and accepts.is_valid() and dropped.is_valid() and accepts.call(data)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var lit := has_focus() or is_hovered()
	draw_rect(rect, Color(0, 0, 0, 0.7))
	var inner := rect.grow(-1)
	draw_rect(inner, Color("161824") if item_id else Color("10121c"))
	if item_id:
		# Rarity glow from the bottom, then the frame.
		draw_rect(
			Rect2(inner.position + Vector2(0, inner.size.y * 0.55), inner.size * Vector2(1, 0.45)),
			Color(frame_color, 0.16)
		)
	draw_rect(inner, frame_color if item_id else UiTheme.BORDER, false, 1.0)
	var picture := icon_texture if icon_texture else placeholder
	if picture:
		# Whole-number scaling only, so pixel art stays sharp.
		var zoom := maxi(1, floori((rect.size.x - 4.0) / picture.get_width()))
		var drawn := picture.get_size() * zoom
		var at := ((rect.size - drawn) / 2.0).round()
		var tint := Color(1, 0.55, 0.55) if too_high_level else Color.WHITE
		if icon_texture:
			# A dark drop shadow keeps the icon readable on any frame colour.
			draw_texture_rect(picture, Rect2(at + Vector2(1, 1), drawn), false, Color(0, 0, 0, 0.5))
		draw_texture_rect(picture, Rect2(at, drawn), false, tint)
	if count > 1:
		var font := get_theme_default_font()
		var at := Vector2(0, rect.size.y - 2)
		draw_string_outline(
			font, at, str(count), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2, 7, 3, Color.BLACK
		)
		draw_string(font, at, str(count), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2, 7)
	if upgrade > 0:
		var font := get_theme_default_font()
		var at := Vector2(2, 9)
		var text := "+%d" % upgrade
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color.BLACK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiTheme.GOLD)
	if _drop_lit:
		# Where the dragged item can go.
		draw_rect(inner, Color(UiTheme.ACCENT, 0.18))
		draw_rect(rect.grow(-0.5), UiTheme.ACCENT, false, 1.5)
	if lit:
		draw_rect(
			rect.grow(-0.5), UiTheme.ACCENT if has_focus() else Color(1, 1, 1, 0.5), false, 1.5
		)
