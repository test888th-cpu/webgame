class_name MapTab
extends RefCounted
## The Map tab of the pause window (MapRules): where the hero is and where
## the goal is, then the street district by district, west to east, one row
## each, and the world boss arenas the hero knows. Walking the boxes
## (keyboard, gamepad, mouse) shows what is known of each area underneath.
## Read-only: travel stays with Win's taxi.

const NAME_WIDTH := 104.0
const DETAIL_WIDTH := 540.0


static func build(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var here := game.zone.area_id
	var goal := MapRules.goal(profile, content)
	var column := VBoxContainer.new()
	column.name = "Map"
	column.add_theme_constant_override("separation", 3)
	column.add_child(_where(content, game.zone))
	column.add_child(_goal_line(content, goal))
	var detail := _detail()
	var focus: MapNode = null
	var rows: Array = []
	for district in MapRules.districts(content):
		rows.append([district["name"], district["areas"]])
	var arenas := MapRules.arenas(profile, content)
	if not arenas.is_empty():
		rows.append(["World Bosses", arenas])
	for row: Array in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 0)
		column.add_child(line)
		var known := false
		var nodes := HBoxContainer.new()
		nodes.add_theme_constant_override("separation", 0)
		for area_id: String in row[1]:
			var info := MapRules.about(profile, content, area_id, here)
			known = known or info["state"] != MapRules.UNKNOWN
			var node := MapNode.new()
			node.name = "Area_" + area_id
			node.setup(
				info, goal.get("area") == area_id, profile.level, nodes.get_child_count() == 0
			)
			node.focus_entered.connect(_show.bind(detail, info, goal.get("area") == area_id))
			node.mouse_entered.connect(node.grab_focus)
			nodes.add_child(node)
			if area_id == here:
				focus = node
		var title := UiKit.label(
			str(row[0]) if known else MapRules.UNKNOWN_NAME, UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM
		)
		title.custom_minimum_size.x = NAME_WIDTH
		title.clip_text = true
		line.add_child(title)
		line.add_child(nodes)
	column.add_child(detail)
	column.add_child(_legend())
	if focus:
		# Open on the hero's own box (UiKit.focus_first); it fills the detail.
		focus.set_meta("start_focus", true)
	return column


## "Saltmarket Street  Lv 2" and, on the right, "South Street  2 / 11".
static func _where(content: ContentDB, zone: ZoneSim) -> Control:
	var line := HBoxContainer.new()
	var name := UiKit.label(
		"%s  Lv %d" % [zone.area.get("name", ""), zone.level], UiTheme.SIZE_H2, UiTheme.ACCENT
	)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name)
	var spot := MapRules.locate(content, zone.area_id)
	if spot:
		var where := "%s  %d / %d" % [spot["name"], int(spot["index"]) + 1, spot["count"]]
		line.add_child(UiKit.label(where, UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
	return line


static func _goal_line(content: ContentDB, goal: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UiTheme.GAP)
	line.add_child(UiKit.label("GOAL", UiTheme.SIZE_CAPTION, UiTheme.GOLD))
	var text := "Nothing left to do. Farm, gear up, take on the World Bosses."
	if goal:
		var area := str(content.area(str(goal["area"])).get("name", goal["area"]))
		text = "%s  (%s)" % [goal["text"], area]
	line.add_child(UiKit.label(text, UiTheme.SIZE_SMALL, UiTheme.TEXT))
	return line


static func _detail() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Detail"
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = 38
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	var heading := UiKit.label("", UiTheme.SIZE_BODY, UiTheme.TEXT)
	heading.name = "Heading"
	box.add_child(heading)
	var lines := UiKit.label("", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, DETAIL_WIDTH)
	lines.name = "Lines"
	box.add_child(lines)
	return panel


## Fills the detail panel with what is known of one area.
static func _show(panel: PanelContainer, info: Dictionary, goal: bool) -> void:
	var heading: Label = panel.find_child("Heading", true, false)
	var lines: Label = panel.find_child("Lines", true, false)
	var states := {
		MapRules.HERE: "You are here",
		MapRules.KNOWN: "Visited",
		MapRules.IN_SIGHT: "Not reached yet: the way on",
		MapRules.UNKNOWN: "Unknown: push further east to find it",
	}
	heading.text = str(info["name"])
	if int(info["level"]) > 0:
		heading.text += "   Lv %d" % info["level"]
	var parts: Array[String] = [states[info["state"]]]
	if goal:
		parts.append("Your goal is here")
	if not info["services"].is_empty():
		parts.append(", ".join(info["services"]))
	if info["boss"]:
		parts.append("%s (%s)" % [info["boss"], "beaten" if info["beaten"] else "boss"])
	if info["gate"]:
		parts.append(str(info["gate"]))
	lines.text = "  ·  ".join(parts)


static func _legend() -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UiTheme.PAD)
	var keys := [
		["Orange: you", UiTheme.ACCENT],
		["Gold dot: goal", UiTheme.GOLD],
		["Teal frame: town", UiTheme.TEAL],
		["Red corner: boss", UiTheme.DANGER],
		["Number: area level, coloured by danger", UiTheme.TEXT_DIM],
	]
	for key: Array in keys:
		line.add_child(UiKit.label(key[0], UiTheme.SIZE_CAPTION, key[1]))
	return line
