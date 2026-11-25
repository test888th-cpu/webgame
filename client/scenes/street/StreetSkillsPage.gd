class_name StreetSkillsPage
extends RefCounted
## The street's Skills screen, in the original Skills window: Abilities (the class's
## whole spellbook, RpgSpellbook.book, each with its state: usable, known but not
## run by this engine, or locked by level, specialization, talent or quest), the
## selected ability's reference data, and its place on the hotbar
## (RpgSpellbook.assign, usable abilities only); Talents (the reference's rows, each
## choice through RpgCharacter.choose_talent, the engine's own check).

const STATE_TEXT := {
	"usable": ["Usable", UiTheme.GOOD],
	"passive": ["Passive, always on", UiTheme.GOOD],
	"known_blocked": ["Known, not in this build yet", UiTheme.GOLD],
	"level": ["Locked by level", UiTheme.TEXT_DIM],
	"spec": ["Locked by specialization", UiTheme.TEXT_DIM],
	"talent": ["Talent ability", UiTheme.TEXT_DIM],
	"quest": ["Quest ability", UiTheme.TEXT_DIM],
	"hidden": ["Not for players", UiTheme.TEXT_FAINT],
}
const LIST_WIDTH := 200.0
const SLOTS := 6


static func build(street: Node) -> Control:
	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	tabs.add_child(_abilities(street))
	tabs.add_child(_talents(street))
	tabs.set_tab_title(0, "Abilities")
	tabs.set_tab_title(1, "Talents")
	if str(street.menu_focus).begins_with("talent"):
		tabs.current_tab = 1
	return tabs


static func _abilities(street: Node) -> Control:
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var mods: Dictionary = street.fight.player["mods"]
	var book := RpgSpellbook.book(pack, str(state["class_id"]), int(state["level"]), mods)
	var columns := HBoxContainer.new()
	columns.name = "Abilities"
	columns.add_theme_constant_override("separation", UiTheme.PAD)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(LIST_WIDTH, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	columns.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 1)
	list.custom_minimum_size.x = LIST_WIDTH - 12
	scroll.add_child(list)
	var counts := {}
	for e: Dictionary in book:
		counts[e["state"]] = int(counts.get(e["state"], 0)) + 1
		var doc: Dictionary = pack["abilities"][e["id"]]
		var b := UiKit.button(str(doc["display_name"]), street.menu_select.bind("skill:" + e["id"]))
		b.name = "Skill_" + str(e["id"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", STATE_TEXT[e["state"]][1])
		list.add_child(b)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 2)
	columns.add_child(right)
	right.add_child(
		UiKit.label(
			(
				"%d usable, %d passive, %d known but not in this build, %d locked."
				% [
					counts.get("usable", 0),
					counts.get("passive", 0),
					counts.get("known_blocked", 0),
					(
						book.size()
						- counts.get("usable", 0)
						- counts.get("passive", 0)
						- counts.get("known_blocked", 0)
					)
				]
			),
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_DIM
		)
	)
	var focus := str(street.menu_focus)
	for e: Dictionary in book:
		if focus == "skill:" + str(e["id"]):
			_detail(street, right, e)
	if not focus.begins_with("skill:"):
		right.add_child(
			UiKit.label("Select an ability.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, 300)
		)
	right.add_child(_bar(street))
	return columns


## The ability's reference data (its def as the pack has it) and its state.
static func _detail(street: Node, box: VBoxContainer, e: Dictionary) -> void:
	var pack: Dictionary = street.pack
	var doc: Dictionary = pack["abilities"][e["id"]]
	var def: Dictionary = doc["def"]
	if e.has("known"):
		def = def.duplicate()
		for key: String in ["cost", "cooldown", "castTime"]:
			if e["known"].has(key):
				def[key] = e["known"][key]
	box.add_child(UiKit.label(str(doc["display_name"]), UiTheme.SIZE_H2, UiTheme.ACCENT))
	var resource := str(street.fight.player["resource_type"])
	var facts: Array[String] = [
		"School %s" % def.get("school", "-"),
		"Cost %s %s" % [_num(def.get("cost", 0)), resource],
		"Cooldown %ss" % _num(def.get("cooldown", 0)),
		(
			"Cast %s"
			% ("instant" if float(def.get("castTime", 0)) <= 0.0 else "%ss" % _num(def["castTime"]))
		),
		"Range %s yd" % _num(def.get("range", 0)),
		"Learned at level %d" % int(def.get("learnLevel", 1)),
	]
	if def.get("specs") != null:
		facts.append("Specializations: %s" % ", ".join(def["specs"]))
	box.add_child(UiKit.label("   ".join(facts), UiTheme.SIZE_SMALL, UiTheme.TEXT, 330))
	for fx: Dictionary in def.get("effects", []):
		box.add_child(UiKit.label("- " + _effect(fx), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, 330))
	var st: Array = STATE_TEXT[e["state"]]
	var line := str(st[0]) + ("" if str(e["reason"]) == "" else ": " + str(e["reason"]))
	var tag := UiKit.label(line, UiTheme.SIZE_SMALL, st[1], 330)
	tag.name = "SkillState"
	box.add_child(tag)
	if e["state"] == RpgSpellbook.USABLE:
		var row := HBoxContainer.new()
		row.add_child(UiKit.label("Put on hotbar:", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
		for i in SLOTS:
			var b := UiKit.button(str(i + 2), street.menu_action.bind("hotbar", [i, e["id"]]))
			b.name = "Assign_%d" % (i + 2)
			row.add_child(b)
		box.add_child(row)


## The hotbar's ability slots as saved (RpgSpellbook.hotbar), each clearable.
static func _bar(street: Node) -> Control:
	var pack: Dictionary = street.pack
	var bar := RpgSpellbook.hotbar(pack, street.state, street.fight.player["mods"], SLOTS)
	var row := HBoxContainer.new()
	row.name = "HotbarLayout"
	row.add_child(UiKit.label("Hotbar  1: Attack", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	for i in bar.size():
		var id := str(bar[i])
		var text := "%d: %s" % [i + 2, pack["abilities"][id]["display_name"] if id != "" else "-"]
		var b := UiKit.button(text, street.menu_action.bind("hotbar", [i, ""]), id == "")
		b.name = "Clear_%d" % (i + 2)
		b.tooltip_text = "Clear this slot" if id != "" else "Empty"
		b.add_theme_font_size_override("font_size", UiTheme.SIZE_CAPTION)
		row.add_child(b)
	return row


static func _talents(street: Node) -> Control:
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var scroll := ScrollContainer.new()
	scroll.name = "Talents"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTheme.GAP)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var chosen: Dictionary = state.get("talents", {})
	for row: Dictionary in RpgTalents.class_talents(pack, str(state["class_id"]))["rows"]:
		var lvl := int(row["level"])
		var open := int(state["level"]) >= lvl
		var section := UiKit.section(
			"Level %d%s" % [lvl, "" if open else "  (opens at level %d)" % lvl]
		)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UiTheme.GAP)
		for o: Dictionary in row["options"]:
			var picked: bool = chosen.get(str(lvl), "") == o["id"]
			var b := UiKit.button(
				("* " if picked else "") + str(o["display_name"]),
				street.menu_action.bind("talent", [lvl, o["id"]]),
				not open
			)
			b.name = "Talent_" + str(o["id"])
			b.tooltip_text = _talent_effect(o.get("effect", {}))
			line.add_child(b)
		section.add_child(line)
		box.add_child(section)
	return scroll


## An effect as its reference data says it: the type and its numbers.
static func _effect(fx: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in fx:
		if key != "type" and not (fx[key] is Dictionary or fx[key] is Array):
			parts.append("%s %s" % [key, _num(fx[key])])
	return "%s  %s" % [fx.get("type", ""), ", ".join(parts)]


static func _talent_effect(effect: Variant) -> String:
	return JSON.stringify(effect) if effect is Dictionary else ""


static func _num(v: Variant) -> String:
	if v is float and is_equal_approx(v, roundf(v)):
		return str(int(v))
	return str(v)
