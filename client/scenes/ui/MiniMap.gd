class_name MiniMap
extends Control
## The HUD's route card, top right. Read top to bottom:
##   SOUTH STREET              AREA 1 / 11     the district and where in it
##   ▼
##   ●━━●━━○ ─ ○ ─ ○ ─ ⌂ ─ ○ ─ ○ ─ ☠          one node per area, west to east
##   Depot Yard · Lv 1                         the area the hero is in
##   ───▮────▮──▲────────▮│                   its fights left, the hero, the gate
## Nodes: the hero's area is a big orange ring under a marker; areas reached
## are filled, the next one east is an empty ring, the rest faint dots; a
## teal house is a town; a skull is a boss (grey with a tick once beaten);
## the goal (MapRules.goal) flies a gold flag, or a gold arrow points to it
## when it lies in another district. The way travelled is a solid line, the
## way ahead dashed. Hovering a node names it; a click or tap opens the map.

signal pressed

const SIZE := Vector2(172, 50)
const PAD := 6.0
const HEADER_Y := 9.0
const ROUTE_Y := 22.0
const AREA_Y := 37.0
const TRACK_Y := 44.0

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
	var step := (size.x - PAD * 2.0) / maxf(1.0, count - 1)
	return Vector2(PAD + step * index if count > 1 else size.x / 2.0, ROUTE_Y)


func _areas() -> Array:
	return _district.get("areas", [])


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
	var spot := MapRules.locate(content, zone.area_id)
	if spot:
		_text(font, Vector2(PAD, HEADER_Y), str(spot["name"]).to_upper(), UiTheme.TEAL)
		var where := "AREA %d / %d" % [int(spot["index"]) + 1, spot["count"]]
		_text(font, Vector2(PAD, HEADER_Y), where, UiTheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_draw_route()
	var area := "%s  ·  Lv %d" % [zone.area.get("name", ""), zone.level]
	_text(font, Vector2(PAD, AREA_Y), area, UiTheme.TEXT)
	_draw_track()


func _text(
	font: Font, at: Vector2, text: String, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	var width := size.x - PAD * 2.0
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
	if here >= 0:
		var top := node_at(here) - Vector2(0, 7)
		draw_colored_polygon(
			PackedVector2Array([top + Vector2(-3, -4), top + Vector2(3, -4), top]), UiTheme.ACCENT
		)
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
	var boss := MapRules.boss_of(content, area_id)
	if boss:
		var beaten := int(profile.defeated.get(boss, 0)) > 0
		_skull(at, UiTheme.TEXT_DIM if beaten else UiTheme.DANGER, seen == MapRules.HERE)
		if beaten:
			draw_polyline(
				PackedVector2Array([at + Vector2(2, 3), at + Vector2(3, 4), at + Vector2(6, 1)]),
				UiTheme.GOOD,
				1.0
			)
	elif content.area(area_id).get("safe", false) and seen != MapRules.UNKNOWN:
		_house(at, UiTheme.TEAL)
	else:
		match seen:
			MapRules.KNOWN:
				draw_circle(at, 2.5, UiTheme.TEXT)
			MapRules.IN_SIGHT:
				draw_arc(at, 2.5, 0.0, TAU, 12, UiTheme.TEXT_DIM, 1.0)
			MapRules.UNKNOWN:
				draw_circle(at, 1.2, UiTheme.TEXT_FAINT)
	if seen == MapRules.HERE:
		draw_arc(at, 4.5, 0.0, TAU, 18, UiTheme.ACCENT, 1.5)
		if not boss and not content.area(area_id).get("safe", false):
			draw_circle(at, 2.5, UiTheme.ACCENT)
	if area_id == _goal:
		var pole := at + Vector2(4, -3)
		draw_line(pole, pole + Vector2(0, -7), UiTheme.GOLD, 1.0)
		draw_colored_polygon(
			PackedVector2Array(
				[pole + Vector2(0, -7), pole + Vector2(4, -5.5), pole + Vector2(0, -4)]
			),
			UiTheme.GOLD
		)


## A small skull: the boss of an area.
func _skull(at: Vector2, color: Color, lit: bool) -> void:
	if lit:
		draw_circle(at, 3.5, UiTheme.ACCENT)
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


## This area west to east: fights still to win (red ticks, taller for a
## boss), a red bar at the east end while the way on is shut, the hero.
func _draw_track() -> void:
	var left := PAD
	var span := size.x - PAD * 2.0
	var width := float(zone.area.get("width", 960))
	draw_line(Vector2(left, TRACK_Y), Vector2(left + span, TRACK_Y), UiTheme.TEXT_FAINT, 1.0)
	var encounters: Array = zone.area.get("encounters", [])
	for i in encounters.size():
		if StreetMemory.is_cleared(profile, zone.area_id, i):
			continue
		var x := left + float(encounters[i]["trigger_x"]) / width * span
		var tall := 3.0
		for wave: Array in encounters[i]["waves"]:
			for kind: String in wave:
				if content.enemy(kind).get("boss", false):
					tall = 5.0
		draw_rect(Rect2(x - 1.0, TRACK_Y - tall, 2.0, tall + 1.0), UiTheme.DANGER)
	if not zone.exit_locked("east").is_empty():
		draw_rect(Rect2(left + span - 2.0, TRACK_Y - 3.0, 2.0, 5.0), UiTheme.DANGER)
	var hero_x := left + clampf(zone.hero.position.x / width, 0.0, 1.0) * span
	draw_rect(Rect2(hero_x - 1.5, TRACK_Y - 3.0, 3.0, 5.0), UiTheme.ACCENT)
