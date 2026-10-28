class_name MiniMap
extends Control
## The HUD's route card, top right:
##   SOUTH STREET   Saltmarket Street · Lv 2   the district, the area, its level
##   ⌂ ─ ▲ ┃ ○ ─ ○ ─ ○ ─ ○ ─ ○ ─ ○ ─ ☠ BOSS     one node per area, west to east
##   1   2   3   4   5   6   7   8   9  GOAL▸  each area's number in the district
## The numbers say how far along the district the hero is; the names stay,
## because quests and the story send the hero to places by name.
## The hero's area is an orange ▲; areas reached are filled rings, the rest
## empty; a town is a teal house; the district's last area, where its boss
## waits, is a red skull marked BOSS (grey with a tick once beaten). A red
## bar just east of the hero means the way on is still shut. The goal
## (MapRules.goal) flies a gold flag, or "GOAL" with an arrow says it lies
## in a district that way. The way travelled is solid, the way ahead dashed.
## Hovering a node says what the hero knows of it; a click or tap opens the
## map. Everything that only changes with the area is worked out in attach().

signal pressed

const SIZE := Vector2(172, 40)
const PAD := 6.0
const HEADER_Y := 10.0
const ROUTE_Y := 22.0
const NUMBER_Y := 35.0
## Room right of the last node for BOSS (and GOAL under it).
const LABEL_ROOM := 28.0
const ELLIPSIS := "…"

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
var _district := {}
## The district's boss (in its last area), or "".
var _boss := ""
var _step := 0.0
var _goal := ""
var _panel: StyleBoxFlat


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_panel = UiTheme.panel_style()
	_panel.bg_color = Color(0.05, 0.05, 0.09, 0.72)
	_panel.shadow_size = 0


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	_district = {}
	for district in MapRules.districts(content):
		if zone.area_id in district["areas"]:
			_district = district
	var areas := _areas()
	_boss = MapRules.boss_of(content, areas[-1]) if areas else ""
	_step = (SIZE.x - PAD * 2.0 - LABEL_ROOM) / maxf(1.0, areas.size() - 1)
	tooltip_text = str(zone.area.get("name", ""))
	if areas:
		tooltip_text = (
			"%s  %d / %d   (M: map)"
			% [_district["name"], areas.find(zone.area_id) + 1, areas.size()]
		)


## Where node `index` of the route sits.
func node_at(index: int) -> Vector2:
	return Vector2(PAD + _step * index, ROUTE_Y)


func _areas() -> Array:
	return _district.get("areas", [])


func _gui_input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.pressed
	if click or (event is InputEventScreenTouch and event.pressed):
		pressed.emit()
		accept_event()


## Hovering a node says what the hero knows of it, and no more.
func _get_tooltip(at: Vector2) -> String:
	if zone == null or absf(at.y - ROUTE_Y) > 7.0:
		return tooltip_text
	var areas := _areas()
	for i in areas.size():
		if absf(node_at(i).x - at.x) > 5.0:
			continue
		var info := MapRules.about(profile, content, areas[i], zone.area_id)
		var text := "%d. %s" % [i + 1, info["name"]]
		if info["level"]:
			text += "  Lv %d" % info["level"]
		if info["boss"]:
			text += "\nBoss: %s%s" % [info["boss"], "  (beaten)" if info["beaten"] else ""]
		elif i == areas.size() - 1 and _boss:
			text += "\nThe district's boss waits here"
		if info["gate"] and areas[i] == zone.area_id:
			text += "\n" + str(info["gate"])
		if areas[i] == _goal:
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
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	var line := header(font)
	if line["district"]:
		_text(font, Vector2(PAD, HEADER_Y), line["district"], UiTheme.TEAL)
	_text(font, Vector2(line["area_x"], HEADER_Y), line["area"], UiTheme.TEXT)
	if _areas():
		_draw_route(font)


## The header as drawn: {"district", "area", "area_x", "right": where the
## text ends}. A long district and area name never run off the card: the
## area name gives way (the level always shows).
func header(font: Font) -> Dictionary:
	var district := str(_district.get("name", "")).to_upper()
	var x := PAD + (_width(font, district + "   ") if district else 0.0)
	var level := "  ·  Lv %d" % zone.level
	var name := str(zone.area.get("name", ""))
	var area := name + level
	var room := size.x - PAD - x
	if _width(font, area) > room:
		while name.length() > 1 and _width(font, name + ELLIPSIS + level) > room:
			name = name.left(name.length() - 1)
		area = name.strip_edges() + ELLIPSIS + level
	return {"district": district, "area": area, "area_x": x, "right": x + _width(font, area)}


func _width(font: Font, text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_CAPTION).x


func _text(font: Font, at: Vector2, text: String, color: Color) -> void:
	draw_string_outline(
		font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_CAPTION, 3, Color(0, 0, 0, 0.8)
	)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_CAPTION, color)


func _draw_route(font: Font) -> void:
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
	# The way on is shut: a red bar across the road just east of the hero.
	if here >= 0 and here < areas.size() - 1 and not zone.exit_locked("east").is_empty():
		var gate := node_at(here).x + _step / 2.0
		draw_rect(Rect2(gate - 1.0, ROUTE_Y - 4.0, 2.0, 8.0), UiTheme.DANGER)
	for i in areas.size():
		_draw_node(font, i, areas[i])
		var color := UiTheme.TEXT_FAINT
		if i == here:
			color = UiTheme.ACCENT
		elif i <= reached:
			color = UiTheme.TEXT_DIM
		var digits := str(i + 1)
		_text(font, Vector2(node_at(i).x - _width(font, digits) / 2.0, NUMBER_Y), digits, color)
	_draw_goal_elsewhere(font)


## "GOAL" with an arrow under BOSS when the goal lies in another district of
## the street (a world boss arena is reached by taxi, so it has no way).
func _draw_goal_elsewhere(font: Font) -> void:
	var street := StreetMemory.street(content)
	if _goal == "" or _goal in _areas() or _goal not in street:
		return
	var east := street.find(_goal) > street.find(str(_areas()[0]))
	var left := node_at(_areas().size() - 1).x + 5.0
	var word := _width(font, "GOAL")
	var text_x := left if east else left + 5.0
	_text(font, Vector2(text_x, NUMBER_Y), "GOAL", UiTheme.GOLD)
	var tip := Vector2(left + word + 5.0, NUMBER_Y - 2.5) if east else Vector2(left, NUMBER_Y - 2.5)
	var back := -3.0 if east else 3.0
	draw_colored_polygon(
		PackedVector2Array([tip, tip + Vector2(back, -2.5), tip + Vector2(back, 2.5)]), UiTheme.GOLD
	)


func _draw_node(font: Font, index: int, area_id: String) -> void:
	var at := node_at(index)
	var seen := MapRules.state(profile, content, area_id, zone.area_id)
	if index == _areas().size() - 1 and _boss:
		var beaten := int(profile.defeated.get(_boss, 0)) > 0
		var color := UiTheme.TEXT_DIM if beaten else UiTheme.DANGER
		_skull(at, color)
		if beaten:
			draw_polyline(
				PackedVector2Array([at + Vector2(2, 3), at + Vector2(3, 4), at + Vector2(6, 1)]),
				UiTheme.GOOD,
				1.0
			)
		_text(font, Vector2(at.x + 5.0, ROUTE_Y + 2.5), "BOSS", color)
	elif content.area(area_id).get("safe", false) and seen != MapRules.UNKNOWN:
		_house(at, UiTheme.TEAL)
	elif seen == MapRules.KNOWN or seen == MapRules.HERE:
		draw_circle(at, 2.5, UiTheme.TEXT)
	else:
		draw_arc(at, 2.2, 0.0, TAU, 12, UiTheme.TEXT_FAINT, 1.0)
	if seen == MapRules.HERE:
		# The hero: an orange triangle standing on the node.
		var tip := at + Vector2(0, -1.5)
		var points := [tip + Vector2(-4, 4), tip + Vector2(0, -4), tip + Vector2(4, 4)]
		draw_colored_polygon(PackedVector2Array(points), UiTheme.ACCENT)
		draw_polyline(PackedVector2Array(points + [points[0]]), Color(0, 0, 0, 0.8), 1.0)
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
