class_name MiniMap
extends Control
## The HUD's route card, top right (MapRules.route draws the facts):
##   SOUTH STREET  Saltmarket Street · Lv 2    the district, the area, its level
##   ● ─ ▴ ┃ ☠ ─ ○ ─ ○ ─ ○ ─ ○ ─ ☠ ─ ○ ─ ○ ─ ☠ BOSS   one node per area
##   1   2   3   4   5   6   7   8   9  10  11       each area's number
## Kept small (it shares the corner with the coins and the quest card): the
## hero's area is an orange dot under a small orange marker; a town is a
## teal dot; plain areas are dots, filled once reached; a horned orange
## skull marks a mini-boss and a round red one the district's boss, marked
## BOSS (both grey with a green tick once beaten; shown before they are
## reached, who they are only after: MapRules.about); a small gold flag
## stands over the goal. A red bar east of the hero means the way on is still
## shut; "GOAL" with an arrow says the goal lies in another district. The
## way travelled is solid, the way ahead dashed. The numbers say how far
## along the hero is; the names stay, because quests and the story send the
## hero to places by name. Hovering a node says what the hero knows of it; a
## click or tap opens the map. The route is rebuilt a few times a second.

signal pressed

const SIZE := Vector2(152, 36)
const PAD := 6.0
const HEADER_Y := 8.0
const ROUTE_Y := 20.0
const NUMBER_Y := 32.0
const REFRESH := 0.25
const ICONS := ["map_boss", "map_boss_beaten", "map_mini_boss", "map_mini_boss_beaten", "map_goal"]
## Room right of the last node for BOSS (and GOAL under it).
const LABEL_ROOM := 24.0
const ELLIPSIS := "…"

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
var _district := {}
var _step := 0.0
var _goal := ""
var _panel: StyleBoxFlat
## MapRules.route of the hero's district ({} off the street).
var _route := {}
var _icons := {}
var _refresh_left := 0.0


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
	for id: String in ICONS:
		_icons[id] = UiKit.icon(content, id)
	_refresh()
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
		elif info["kind"] == MapRules.BOSS:
			text += "\nThe district's boss waits here"
		elif info["kind"] == MapRules.MINI_BOSS:
			text += "\nA mini-boss waits here"
		if info["gate"] and areas[i] == zone.area_id:
			text += "\n" + str(info["gate"])
		if areas[i] == _goal:
			text += "\nYour goal"
		return text
	return tooltip_text


func _process(delta: float) -> void:
	if zone == null:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh()
	queue_redraw()


func _refresh() -> void:
	_refresh_left = REFRESH
	_route = MapRules.route(profile, content, zone.area_id)
	_goal = str(MapRules.goal(profile, content).get("area", ""))


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
	if _route.is_empty():
		return
	var nodes: Array = _route["nodes"]
	var here := int(_route["here"])
	var reached := int(_route["reached"])
	# The way travelled, solid; the way ahead, dashed.
	for i in range(1, nodes.size()):
		var a := node_at(i - 1) + Vector2(3, 0)
		var b := node_at(i) - Vector2(3, 0)
		if i <= reached:
			draw_line(a, b, UiTheme.TEXT_DIM, 1.5)
		else:
			draw_dashed_line(a, b, UiTheme.TEXT_FAINT, 1.0, 2.0)
	# The way on is shut: a red bar across the road just east of the hero.
	if here >= 0 and here < nodes.size() - 1 and not zone.exit_locked("east").is_empty():
		var gate := node_at(here).x + minf(4.5, _step / 2.0)
		draw_rect(Rect2(gate - 0.75, ROUTE_Y - 3.0, 1.5, 6.0), UiTheme.DANGER)
	for i in nodes.size():
		_draw_node(font, i, nodes[i], i <= reached)
		var color := UiTheme.TEXT_FAINT
		if i == here:
			color = UiTheme.ACCENT
		elif i <= reached:
			color = UiTheme.TEXT_DIM
		var digits := str(nodes[i]["number"])
		_text(font, Vector2(node_at(i).x - _width(font, digits) / 2.0, NUMBER_Y), digits, color)
	if here >= 0:
		# The hero: a small orange marker over their area.
		var tip := node_at(here) + Vector2(0, -5)
		var marker := [tip, tip + Vector2(-3, -4), tip + Vector2(3, -4)]
		draw_colored_polygon(PackedVector2Array(marker), UiTheme.ACCENT)
		draw_polyline(PackedVector2Array(marker + [tip]), Color(0, 0, 0, 0.8), 1.0)
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


func _draw_node(font: Font, index: int, node: Dictionary, reached: bool) -> void:
	var at := node_at(index)
	var beaten: bool = node["beaten"]
	var here: bool = node["state"] == MapRules.HERE
	match str(node["kind"]):
		MapRules.BOSS:
			_icon("map_boss_beaten" if beaten else "map_boss", at)
			var color := UiTheme.TEXT_DIM if beaten else UiTheme.DANGER
			_text(font, Vector2(at.x + 6.0, ROUTE_Y + 2.5), "BOSS", color)
		MapRules.MINI_BOSS:
			_icon("map_mini_boss_beaten" if beaten else "map_mini_boss", at)
		_:
			var color := UiTheme.TEXT_FAINT
			if here:
				color = UiTheme.ACCENT
			elif node["kind"] == MapRules.TOWN:
				color = UiTheme.TEAL
			elif reached:
				color = UiTheme.TEXT
			if here or reached or node["kind"] == MapRules.TOWN:
				draw_circle(at, 2.8 if here else 2.2, Color(0, 0, 0, 0.8))
				draw_circle(at, 2.0 if here else 1.5, color)
			else:
				draw_arc(at, 1.8, 0.0, TAU, 10, color, 1.0)
	if node["goal"] and not here:
		_icon("map_goal", at + Vector2(3, -6))


## Draws icon `id` (16x16) centred on `at`.
func _icon(id: String, at: Vector2) -> void:
	var texture: Texture2D = _icons.get(id)
	if texture:
		draw_texture(texture, (at - Vector2(8, 8)).round())
