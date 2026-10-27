class_name MapNode
extends Button
## One area on the map screen (MapRules.about): a box with the area's level
## in its threat colour, joined to the area west of it by a line. Filled
## orange where the hero stands; a teal frame for a town (shop, quests,
## taxi); a red corner for a boss (green once beaten); a gold dot for the
## goal. A focusable button so keyboard and gamepad can walk the map; it only
## shows, never travels.

const LINK := 8.0
const BOX := Vector2(30, 16)

var info: Dictionary = {}
var goal := false
var hero_level := 1
## The first area of its row has no line to the west.
var first := false


func setup(p_info: Dictionary, p_goal: bool, p_hero_level: int, p_first: bool) -> void:
	info = p_info
	goal = p_goal
	hero_level = p_hero_level
	first = p_first
	custom_minimum_size = Vector2(LINK + BOX.x, BOX.y + 2)
	focus_mode = Control.FOCUS_ALL
	flat = true
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	tooltip_text = str(info["name"])
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var seen := str(info["state"])
	var faint := seen == MapRules.UNKNOWN
	var mid := size.y / 2.0
	if not first:
		draw_line(
			Vector2(0, mid), Vector2(LINK, mid), UiTheme.TEXT_FAINT if faint else UiTheme.BORDER, 2
		)
	var box := Rect2(Vector2(LINK, mid - BOX.y / 2.0), BOX)
	var fill := {
		MapRules.HERE: UiTheme.ACCENT_DARK,
		MapRules.KNOWN: UiTheme.PANEL_LIGHT,
		MapRules.IN_SIGHT: UiTheme.PANEL,
	}
	if fill.has(seen):
		draw_rect(box, fill[seen])
	var frame := UiTheme.TEAL if not info["services"].is_empty() else UiTheme.BORDER
	draw_rect(box, UiTheme.TEXT_FAINT if faint else frame, false, 1.0)
	if info["boss"]:
		var corner := box.position + Vector2(box.size.x, 0)
		var mark := UiTheme.GOOD if info["beaten"] else UiTheme.DANGER
		draw_colored_polygon(
			PackedVector2Array([corner, corner + Vector2(-6, 0), corner + Vector2(0, 6)]), mark
		)
	var text := "?" if faint else str(info["level"])
	var color := UiTheme.TEXT_FAINT
	if not faint:
		color = UiTheme.THREAT[LevelRules.threat(int(info["level"]), hero_level)]
	if seen == MapRules.HERE:
		color = UiTheme.TEXT
	var font := get_theme_default_font()
	var font_size := UiTheme.SIZE_SMALL
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := (
		box.position + Vector2((box.size.x - width) / 2.0, box.size.y / 2.0 + font_size * 0.35)
	)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	if goal:
		draw_circle(box.position + Vector2(2.5, 2.5), 2.5, UiTheme.GOLD)
	if has_focus():
		draw_rect(box.grow(1), UiTheme.TEXT, false, 1.0)
