class_name MiniMap
extends Control
## The HUD's route card, top right, two lines:
##   SOUTH STREET   Depot Yard · Lv 1          the district, the area, its level
##   ⌂ ─ ○ ─ ▲ ─ ○ ─ ○ ─ ○ ─ ○ ─ ○ ─ ☠ BOSS     one node per area, west to east
## The hero's area is an orange ▲; areas reached are filled rings, the rest
## empty; a town is a teal house; the district's last area, where its boss
## waits, is a red skull marked BOSS (grey with a tick once beaten); the
## goal (MapRules.goal) flies a gold flag, or a gold arrow points to it in
## another district. The way travelled is solid, the way ahead dashed.
## Hovering a node names it; a click or tap opens the map.

signal pressed

const SIZE := Vector2(172, 32)
const PAD := 6.0
const HEADER_Y := 10.0
const ROUTE_Y := 23.0
## Room right of the last node for its BOSS label.
const BOSS_LABEL := 28.0

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
var _district := {}
var _goal := ""


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	_district = {}
	for district in MapRules.districts(content):
		if zone.area_id in district["areas"]:
			_district = district
	var spot := MapRules.locate(content, zone.area_id)
	tooltip_text = (
		"%s  %d / %d   (M: map)" % [spot["name"], int(spot["index"]) + 1, spot["count"]]
		if spot
		else str(zone.area.get("name", ""))
	)


## Where node `index` of the route sits.
func node_at(index: int) -> Vector2:
	var count: int = maxi(1, _areas().size())
	var step := (size.x - PAD * 2.0 - _label_room()) / maxf(1.0, count - 1)
	return Vector2(PAD + step * index if count > 1 else size.x / 2.0, ROUTE_Y)


func _areas() -> Array:
	return _district.get("areas", [])


## The district's boss: the one in its last area, or "".
func _district_boss() -> String:
	return MapRules.boss_of(content, _areas()[-1]) if _areas() else ""


func _label_room() -> float:
	return BOSS_LABEL if _district_boss() else 0.0


func _gui_input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.pressed
	if click or (event is InputEventScreenTouch and event.pressed):
		pressed.emit()
		accept_event()


## Hovering a node names it (as much as the hero knows of it).
func _get_tooltip(at: Vector2) -> String:
	if zone == null or absf(at.y - ROUTE_Y) > 7.0:
		return tooltip_text
	for i in _areas().size():
		if absf(node_at(i).x - at.x) <= 5.0:
			var info := MapRules.about(profile, content, _areas()[i], zone.area_id)
			var text := "%s  Lv %d" % [info["name"], info["level"]] if info["level"] else "???"
			if info["boss"]:
				text += "\nBoss: %s%s" % [info["boss"], "  (beaten)" if info["beaten"] else ""]
			elif MapRules.boss_of(content, _areas()[i]):
				text += "\nA boss waits here"
			if _areas()[i] == _goal:
				text += "\nYour goal"
			return text
	return tooltip_text


func _process(_delta: float) -> void:
	if zone:
		_goal = str(MapRules.goal(profile, content).get("area", ""))
		queue_redraw()


func _draw() -> void:
	if zone == null:
		return
	var panel := UiTheme.panel_style()
	panel.bg_color = Color(0.05, 0.05, 0.09, 0.72)
	panel.shadow_size = 0
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	var district := str(MapRules.locate(content, zone.area_id).get("name", "")).to_upper()
	var area := "%s  ·  Lv %d" % [zone.area.get("name", ""), zone.level]
	_text(font, Vector2(PAD, HEADER_Y), district, UiTheme.TEAL)
	var shift := (
		font
		. get_string_size(district + "   ", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_CAPTION)
		. x
	)
	_text(font, Vector2(PAD + shift, HEADER_Y), area, UiTheme.TEXT)
	_draw_route()


func _text(
	font: Font, at: Vector2, text: String, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	var width := size.x - at.x - 2.0
	draw_string_outline(font, at, text, align, width, UiTheme.SIZE_CAPTION, 3, Color(0, 0, 0, 0.8))
	draw_string(font, at, text, align, width, UiTheme.SIZE_CAPTION, color)


func _draw_route() -> void:
	var areas := _areas()
	var here := areas.find(zone.area_id)
	var reached := here
	for i in areas.size():
		if areas[i] in profile.visited:
			reached = maxi(reached, i)
	# The way travelled, solid; the way ahead, dashed.
	for i in range(1, areas.size()):
		var a := node_at(i - 1) + Vector2(3, 0)
		var b := node_at(i) - Vector2(3, 0)
		if i <= reached:
			draw_line(a, b, UiTheme.TEXT_DIM, 1.5)
		else:
			draw_dashed_line(a, b, UiTheme.TEXT_FAINT, 1.0, 2.0)
	for i in areas.size():
		_draw_node(i, areas[i])
	if _goal and _goal not in areas and not areas.is_empty():
		var street := StreetMemory.street(content)
		var east := street.find(_goal) > street.find(str(areas[0]))
		var tip := Vector2(size.x - 1.0, ROUTE_Y) if east else Vector2(1.0, ROUTE_Y)
		var back := -4.0 if east else 4.0
		draw_colored_polygon(
			PackedVector2Array([tip, tip + Vector2(back, -3), tip + Vector2(back, 3)]), UiTheme.GOLD
		)


func _draw_node(index: int, area_id: String) -> void:
	var at := node_at(index)
	var seen := MapRules.state(profile, content, area_id, zone.area_id)
	var last := index == _areas().size() - 1
	if last and _district_boss():
		var beaten := int(profile.defeated.get(_district_boss(), 0)) > 0
		_skull(at, UiTheme.TEXT_DIM if beaten else UiTheme.DANGER)
		if beaten:
			draw_polyline(
				PackedVector2Array([at + Vector2(2, 3), at + Vector2(3, 4), at + Vector2(6, 1)]),
				UiTheme.GOOD,
				1.0
			)
		var font := get_theme_default_font()
		var label := Vector2(at.x + 5.0, ROUTE_Y + 2.5)
		_text(font, label, "BOSS", UiTheme.TEXT_DIM if beaten else UiTheme.DANGER)
	elif content.area(area_id).get("safe", false) and seen != MapRules.UNKNOWN:
		_house(at, UiTheme.TEAL)
	elif seen == MapRules.KNOWN or seen == MapRules.HERE:
		draw_circle(at, 2.5, UiTheme.TEXT)
	else:
		draw_arc(at, 2.2, 0.0, TAU, 12, UiTheme.TEXT_FAINT, 1.0)
	if seen == MapRules.HERE:
		# The hero: an orange triangle standing on the node.
		var tip := at + Vector2(0, -1.5)
		draw_colored_polygon(
			PackedVector2Array([tip + Vector2(-4, 4), tip + Vector2(0, -4), tip + Vector2(4, 4)]),
			UiTheme.ACCENT
		)
		draw_polyline(
			PackedVector2Array(
				[
					tip + Vector2(-4, 4),
					tip + Vector2(0, -4),
					tip + Vector2(4, 4),
					tip + Vector2(-4, 4)
				]
			),
			Color(0, 0, 0, 0.8),
			1.0
		)
	if area_id == _goal:
		var pole := at + Vector2(3, -3)
		draw_line(pole, pole + Vector2(0, -7), UiTheme.GOLD, 1.0)
		draw_colored_polygon(
			PackedVector2Array(
				[pole + Vector2(0, -7), pole + Vector2(4, -5.5), pole + Vector2(0, -4)]
			),
			UiTheme.GOLD
		)


## A small skull: the district's boss.
func _skull(at: Vector2, color: Color) -> void:
	draw_circle(at + Vector2(0, -0.5), 3.0, color)
	draw_rect(Rect2(at + Vector2(-1.5, 1.5), Vector2(3, 2)), color)
	for eye: float in [-1.2, 1.2]:
		draw_circle(at + Vector2(eye, -0.5), 0.8, UiTheme.BG)


## A small house: a town (a safe area).
func _house(at: Vector2, color: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array(
			[at + Vector2(-3.5, -0.5), at + Vector2(0, -4), at + Vector2(3.5, -0.5)]
		),
		color
	)
	draw_rect(Rect2(at + Vector2(-2.5, -0.5), Vector2(5, 3.5)), color)
