class_name MiniMap
extends Control
## The HUD's map strip under the area name, right-aligned with it:
##   top     one dot per area of the hero's district (MapRules), the hero's
##           orange, the goal ringed gold; a gold arrow at either end when the
##           goal lies in a district that way
##   bottom  this area, west to east: fights still to win (red ticks, a
##           bigger one for a boss), a red bar at the east end while the way on
##           is shut, and the hero (orange)
## Clicking or tapping it opens the Map tab (pressed).

signal pressed

const DOT_STEP := 9.0
const TRACK_Y := 12.0

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB
var _areas: Array = []
var _goal := ""


func _init() -> void:
	custom_minimum_size = Vector2(150, 16)
	mouse_filter = Control.MOUSE_FILTER_STOP


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content
	_areas = []
	for district in MapRules.districts(content):
		if zone.area_id in district["areas"]:
			_areas = district["areas"]
			var spot := MapRules.locate(content, zone.area_id)
			tooltip_text = (
				"%s  %d / %d   (M: map)" % [spot["name"], int(spot["index"]) + 1, spot["count"]]
			)


func _gui_input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.pressed
	if click or (event is InputEventScreenTouch and event.pressed):
		pressed.emit()
		accept_event()


func _process(_delta: float) -> void:
	if zone:
		_goal = str(MapRules.goal(profile, content).get("area", ""))
		queue_redraw()


func _draw() -> void:
	if zone == null:
		return
	var street := StreetMemory.street(content)
	var count := _areas.size()
	var left := size.x - 4.0 - DOT_STEP * maxi(0, count - 1)
	for i in count:
		var area_id: String = _areas[i]
		var at := Vector2(left + DOT_STEP * i, 4.0)
		var seen := MapRules.state(profile, content, area_id, zone.area_id)
		if i > 0:
			draw_line(at - Vector2(DOT_STEP - 2.0, 0), at - Vector2(2.0, 0), UiTheme.BORDER, 1.0)
		match seen:
			MapRules.HERE:
				draw_circle(at, 3.0, UiTheme.ACCENT)
			MapRules.KNOWN:
				draw_circle(at, 2.0, UiTheme.TEXT_DIM)
			MapRules.IN_SIGHT:
				draw_arc(at, 2.0, 0.0, TAU, 10, UiTheme.TEXT_DIM, 1.0)
			_:
				draw_circle(at, 1.0, UiTheme.TEXT_FAINT)
		if area_id == _goal:
			draw_arc(at, 4.5, 0.0, TAU, 14, UiTheme.GOLD, 1.0)
	if _goal and _goal not in _areas and count > 0:
		var east := street.find(_goal) > street.find(str(_areas[0]))
		var tip := Vector2(size.x, 4.0) if east else Vector2(left - 8.0, 4.0)
		var back := -4.0 if east else 4.0
		draw_colored_polygon(
			PackedVector2Array([tip, tip + Vector2(back, -3), tip + Vector2(back, 3)]), UiTheme.GOLD
		)
	_draw_track()


func _draw_track() -> void:
	var width := float(zone.area.get("width", 960))
	draw_rect(Rect2(Vector2(0, TRACK_Y - 1.0), Vector2(size.x, 4)), Color(0, 0, 0, 0.6))
	draw_line(Vector2(0, TRACK_Y + 1.0), Vector2(size.x, TRACK_Y + 1.0), UiTheme.TEXT_FAINT, 1.0)
	var encounters: Array = zone.area.get("encounters", [])
	for i in encounters.size():
		if StreetMemory.is_cleared(profile, zone.area_id, i):
			continue
		var x := float(encounters[i]["trigger_x"]) / width * size.x
		var tall := 3.0
		for wave: Array in encounters[i]["waves"]:
			for kind: String in wave:
				if content.enemy(kind).get("boss", false):
					tall = 5.0
		draw_rect(Rect2(x - 1.0, TRACK_Y + 1.0 - tall, 2.0, tall + 1.0), UiTheme.DANGER)
	if not zone.exit_locked("east").is_empty():
		draw_rect(Rect2(size.x - 2.0, TRACK_Y - 3.0, 2.0, 6.0), UiTheme.DANGER)
	var hero_x := zone.hero.position.x / width * size.x
	draw_rect(Rect2(hero_x - 1.5, TRACK_Y - 2.0, 3.0, 6.0), UiTheme.ACCENT)
