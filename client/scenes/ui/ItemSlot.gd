class_name ItemSlot
extends Button
## One cell of the bag or the equipment doll: a framed icon in its rarity
## colour, a stack count, a faint silhouette when empty, and a red tint when
## the hero's level is too low to wear it. A Button, so keyboard, gamepad,
## mouse and touch all work, and grids get focus navigation for free.

var item_id := ""
var count := 0
var frame_color := UiTheme.BORDER
var icon_texture: Texture2D
## Shown when the slot is empty (equipment slots).
var placeholder: Texture2D
var too_high_level := false


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
		var at := (rect.size - picture.get_size()) / 2.0
		var tint := Color(1, 0.55, 0.55) if too_high_level else Color.WHITE
		draw_texture(picture, at.round(), tint)
	if count > 1:
		var font := get_theme_default_font()
		var at := Vector2(0, rect.size.y - 2)
		draw_string_outline(
			font, at, str(count), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2, 7, 3, Color.BLACK
		)
		draw_string(font, at, str(count), HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2, 7)
	if lit:
		draw_rect(
			rect.grow(-0.5), UiTheme.ACCENT if has_focus() else Color(1, 1, 1, 0.5), false, 1.5
		)
