class_name MapTab
extends RefCounted
## The Map tab of the pause window (MapRules): where the hero is and where
## the goal is, then sections kept apart (SHOWN picks them by where the hero
## stands). STORY: the street district by district, west to east, one row
## each. The hub (Iron City Central, off the street). FARMING GROUNDS: those
## open to the hero (AreaRules), by level. WORLD BOSSES: the arenas the hero
## knows. Walking the boxes (keyboard, gamepad, mouse) shows what is known
## of each area underneath. Read-only: travel stays with the taxi and truck.

const NAME_WIDTH := 104.0
const DETAIL_WIDTH := 540.0
const STORY := "story"
const HUB := "hub"
const FARMING := "farming"
const BOSSES := "bosses"
## What the map shows where the hero stands (the owner's rule, November
## 2026): on the street the story only, in a farming ground (or a lair off
## one) the grounds only, in a world boss arena the arenas only, and in the
## city everything, each under its own heading.
const SHOWN := {
	AreaRules.STREET: [STORY],
	AreaRules.FARM: [FARMING],
	AreaRules.LAIR: [FARMING],
	AreaRules.WORLD_BOSS: [BOSSES],
	AreaRules.CITY: [STORY, HUB, FARMING, BOSSES],
}

## Row titles in the colour of their part of the map.
const ROW_COLOURS := {
	HUB: UiTheme.TEAL,
	FARMING: UiTheme.ACCENT,
	BOSSES: UiTheme.DANGER,
}


static func build(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var here := game.zone.area_id
	var goal := MapRules.goal(profile, content)
	var column := VBoxContainer.new()
	column.name = "Map"
	# Tight rows: late in the game the two sections, ten rows, the detail and
	# the legend all fit on the 640x360 canvas.
	column.add_theme_constant_override("separation", 1)
	column.add_child(_where(content, game.zone))
	column.add_child(_goal_line(content, goal))
	var detail := _detail()
	var focus: MapNode = null
	var icons := {}
	for id: String in MiniMap.ICONS:
		icons[id] = UiKit.icon(content, id)
	var hub := str(content.area(AreaRules.hub(content)).get("name", ""))
	var shown: Array = sections(content, here)
	if shown.size() < SHOWN[AreaRules.CITY].size():
		var only := UiKit.label(
			"Only this part of the map here: open it in the city to see everything.",
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_DIM
		)
		only.name = "OnlyHere"
		column.add_child(only)
	# [section, row title, areas]: the story first, then the city, the
	# grounds and the arenas, each section only where it is shown.
	var rows: Array = []
	for district in MapRules.districts(content):
		rows.append([STORY, district["name"], district["areas"]])
	if content.city_area != "":
		rows.append([HUB, "City", [content.city_area]])
	# Farming grounds: only those open to the hero, once there is one.
	var grounds := AreaRules.open_farms(profile, content)
	if not grounds.is_empty():
		rows.append([FARMING, "Farming", _by_level(content, grounds)])
	var arenas := MapRules.arenas(profile, content)
	if not arenas.is_empty():
		rows.append([BOSSES, "World Bosses", arenas])
	var heading := ""
	for row: Array in rows:
		if row[0] not in shown:
			continue
		# In the city the parts off the street share one heading (it all fits
		# on the small canvas); each row's title wears its category's colour.
		var group: String = HUB if shown.size() > 1 and row[0] != STORY else row[0]
		if group != heading:
			heading = group
			column.add_child(_section(group, hub, WorldBossRules.entry_level(content)))
		var colour: Color = ROW_COLOURS.get(row[0], UiTheme.TEXT_DIM)
		row = row.slice(1)
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
			node.icons = icons
			node.setup(
				info, goal.get("area") == area_id, profile.level, nodes.get_child_count() == 0
			)
			var via := hub if row[0] in ["Farming", "World Bosses"] else ""
			node.focus_entered.connect(_show.bind(detail, info, goal.get("area") == area_id, via))
			node.mouse_entered.connect(node.grab_focus)
			nodes.add_child(node)
			if area_id == here:
				focus = node
		var title := UiKit.label(
			str(row[0]) if known else MapRules.UNKNOWN_NAME, UiTheme.SIZE_SMALL, colour
		)
		title.name = "Row_" + str(row[0]).replace(" ", "_")
		title.custom_minimum_size.x = NAME_WIDTH
		title.clip_text = true
		line.add_child(title)
		line.add_child(nodes)
	column.add_child(detail)
	column.add_child(_legend(content))
	if focus:
		# Open on the hero's own box (UiKit.focus_first); it fills the detail.
		focus.set_meta("start_focus", true)
	return column


## The sections the map shows in `area_id` (SHOWN; everything off the known kinds).
static func sections(content: ContentDB, area_id: String) -> Array:
	return SHOWN.get(AreaRules.kind(content, area_id), SHOWN[AreaRules.CITY])


## `ids` (areas) in order of their level.
static func _by_level(content: ContentDB, ids: Array[String]) -> Array[String]:
	var out := ids.duplicate()
	out.sort_custom(
		func(a: String, b: String) -> bool:
			return int(content.area(a).get("level", 0)) < int(content.area(b).get("level", 0))
	)
	return out


## A section's heading: what it holds and how it is reached.
static func _section(section: String, hub: String, boss_level: int) -> Control:
	var text := "STORY  ·  the street, west to east: walk, or Win's taxi"
	var colour := UiTheme.GOLD
	if section == HUB:
		text = "%s  ·  the city; farming grounds and world bosses by Uncle Thong's truck"
		text = text % hub.to_upper()
		colour = UiTheme.TEAL
	elif section == FARMING:
		text = "FARMING GROUNDS  ·  by level: Uncle Thong's truck; west leads one ground down"
		colour = UiTheme.ACCENT
	elif section == BOSSES:
		text = "WORLD BOSSES  ·  from level %d: Uncle Thong's truck" % boss_level
		colour = UiTheme.DANGER
	var label := UiKit.label(text, UiTheme.SIZE_CAPTION, colour)
	label.name = "Section_" + section
	return label


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


## Fills the detail panel with what is known of one area; `via` names the hub
## a farming ground or a world boss arena is reached from.
static func _show(panel: PanelContainer, info: Dictionary, goal: bool, via := "") -> void:
	var heading: Label = panel.find_child("Heading", true, false)
	var lines: Label = panel.find_child("Lines", true, false)
	var states := {
		MapRules.HERE: "You are here",
		MapRules.KNOWN: "Visited",
		MapRules.IN_SIGHT: "Not reached yet: the way on",
		MapRules.UNKNOWN: "Unknown: push further east to find it",
	}
	heading.text = str(info["name"])
	var farm := str(info.get("purpose", "")) != ""
	if int(info["level"]) > 0:
		heading.text += ("   Suggested Lv %d" if farm else "   Lv %d") % info["level"]
	if via:
		heading.text += "   ·   Uncle Thong's truck in %s" % via
	var parts: Array[String] = [states[info["state"]]]
	if farm:
		# A farming ground's level is advice for the fights there, not a gate.
		parts.append("No level needed to enter")
		parts.append(str(info["purpose"]))
	if goal:
		parts.append("Your goal is here")
	if not info["services"].is_empty():
		parts.append(", ".join(info["services"]))
	var kind := "boss" if info["kind"] == MapRules.BOSS else "mini-boss"
	if info["boss"]:
		parts.append("%s (%s)" % [info["boss"], "beaten" if info["beaten"] else kind])
	elif info["kind"] in [MapRules.BOSS, MapRules.MINI_BOSS]:
		parts.append("A %s waits here" % kind)
	if info["gate"]:
		parts.append(str(info["gate"]))
	# The Epic and Legendary gear to be won here.
	if str(info.get("prize_text", "")):
		parts.append(str(info["prize_text"]))
	lines.text = "  ·  ".join(parts)


static func _legend(content: ContentDB) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UiTheme.GAP)
	var keys := [
		["", "Orange: you", UiTheme.ACCENT],
		["", "Gold dot: goal", UiTheme.GOLD],
		["", "Teal frame: town", UiTheme.TEAL],
		["map_boss", "Boss", UiTheme.DANGER],
		["map_mini_boss", "Mini-boss", UiTheme.ACCENT],
		["", "Number: level, coloured by danger", UiTheme.TEXT_DIM],
	]
	for key: Array in keys:
		if key[0]:
			var mark := UiKit.icon_rect(content, key[0])
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.add_child(mark)
		line.add_child(UiKit.label(key[1], UiTheme.SIZE_CAPTION, key[2]))
	return line
