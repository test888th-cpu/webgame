class_name StreetCharacterPage
extends RefCounted
## The street's Character screen, in the original Character layout (CharacterTabs:
## a portrait card on the left, attribute sections on the right). Every number is
## the live combat unit's (RpgCharacter.sheet_of the engine's player, auras
## included), so the screen and the fight read one sheet; the specialization is
## chosen through RpgCharacter.choose_spec, the engine's own check.


static func build(street: Node) -> Control:
	var content: ContentDB = street.content
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var fight: RpgEncounter = street.fight
	var unit: Dictionary = fight.player
	var sheet := RpgCharacter.sheet_of(unit)
	var columns := HBoxContainer.new()
	columns.name = "Character"
	columns.add_theme_constant_override("separation", UiTheme.PAD)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", CharacterTabs._inset())
	card.custom_minimum_size.x = 176
	columns.add_child(card)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	card.add_child(left)
	left.add_child(UiKit.label(str(state["name"]), UiTheme.SIZE_H1, UiTheme.TEXT))
	left.add_child(
		UiKit.label(
			"Level %d  %s" % [state["level"], _class_line(content, state)],
			UiTheme.SIZE_SMALL,
			UiTheme.ACCENT
		)
	)
	var view := SpriteView.new()
	view.custom_minimum_size = Vector2(160, 100)
	left.add_child(view)
	view.show_art(content, "class_%s_m" % state["class_id"], 1.6)
	left.add_child(CharacterTabs._bar_row("HP", int(unit["hp"]), int(unit["max_hp"]), UiTheme.HP))
	if float(unit["max_resource"]) > 0.0:
		var res := str(unit["resource_type"]).substr(0, 2).to_upper()
		left.add_child(
			CharacterTabs._bar_row(
				res, int(unit["resource"]), int(unit["max_resource"]), UiTheme.EP
			)
		)
	var need := RpgProgression.xp_for_level(int(state["level"]))
	var capped := int(state["level"]) >= RpgProgression.MAX_LEVEL
	left.add_child(
		CharacterTabs._bar_row("XP", int(state["xp"]), 1 if capped else need, UiTheme.XP)
	)
	left.add_child(
		UiKit.label(
			"Kills %d   Copper %d" % [state.get("kills", 0), state["copper"]],
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_DIM
		)
	)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	columns.add_child(scroll)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UiTheme.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(right)
	right.add_child(_grid("Attributes", _attributes(sheet)))
	right.add_child(_grid("Defense", _defense(sheet)))
	right.add_child(_grid("Offense", _offense(sheet)))
	right.add_child(_spec_section(street, content, pack, state))
	right.add_child(_talent_summary(pack, state))
	return columns


static func _class_line(content: ContentDB, state: Dictionary) -> String:
	var cls := str(state["class_id"])
	var line := str(RpgClassRegistry.class_def(content, cls).get("display_name", cls.capitalize()))
	var spec := RpgClassRegistry.spec(content, cls, str(state.get("spec_id", "")))
	if not spec.is_empty():
		line += " (%s)" % spec.get("display_name", state["spec_id"])
	return line


static func _attributes(sheet: Dictionary) -> Array:
	var s: Dictionary = sheet["stats"]
	return [
		["Strength", str(int(s["str"]))],
		["Agility", str(int(s["agi"]))],
		["Stamina", str(int(s["sta"]))],
		["Intellect", str(int(s["int"]))],
		["Spirit", str(int(s["spi"]))],
	]


static func _defense(sheet: Dictionary) -> Array:
	var out := [
		["Armor", str(int(sheet["armor"]))],
		["Dodge", "%.1f%%" % (float(sheet["dodge"]) * 100.0)],
	]
	if int(sheet["block_value"]) > 0:
		out.append(["Block", "%.1f%%" % (float(sheet["block_chance"]) * 100.0)])
		out.append(["Block value", str(int(sheet["block_value"]))])
	return out


static func _offense(sheet: Dictionary) -> Array:
	var w: Dictionary = sheet["weapon"]
	var out := [
		["Attack power", str(int(sheet["attack_power"]))],
		["Spell power", str(int(sheet["spell_power"]))],
		["Crit", "%.1f%%" % (float(sheet["crit"]) * 100.0)],
		["Spell crit", "%.1f%%" % (float(sheet["spell_crit"]) * 100.0)],
		["Hit", "%.1f%%" % (float(sheet["hit_bonus"]) * 100.0)],
		["Weapon", "%d-%d / %.1fs" % [w["min"], w["max"], w["speed"]]],
	]
	if int(sheet["ranged_power"]) > 0:
		out.insert(1, ["Ranged power", str(int(sheet["ranged_power"]))])
	return out


static func _grid(title: String, rows: Array) -> Control:
	var box := UiKit.section(title)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", UiTheme.PAD)
	for r: Array in rows:
		var name := UiKit.label(r[0], UiTheme.SIZE_BODY, UiTheme.TEXT_DIM)
		name.custom_minimum_size.x = 70
		grid.add_child(name)
		var value := UiKit.label(r[1], UiTheme.SIZE_BODY, UiTheme.TEXT)
		value.name = "Stat_" + str(r[0]).replace(" ", "_")
		value.custom_minimum_size.x = 60
		grid.add_child(value)
	box.add_child(grid)
	return box


## The specialization: the one chosen, or the unlock level, or the choice (the
## engine's choose_spec decides; a refusal is shown, nothing is saved).
static func _spec_section(
	street: Node, content: ContentDB, pack: Dictionary, state: Dictionary
) -> Control:
	var box := UiKit.section("Specialization")
	var cls := str(state["class_id"])
	var unlock := int(RpgPack.constant(pack, "spec_unlock_level"))
	var chosen := str(state.get("spec_id", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTheme.GAP)
	for sp: Dictionary in RpgClassRegistry.specs(content, cls):
		var id := str(sp["id"])
		var text := str(sp.get("display_name", id))
		if id == chosen:
			text = "* " + text
		var b := UiKit.button(text, street.menu_action.bind("spec", id))
		b.name = "Spec_" + id
		b.disabled = chosen != "" or int(state["level"]) < unlock
		row.add_child(b)
	box.add_child(row)
	var note := ""
	if chosen == "" and int(state["level"]) < unlock:
		note = "Specializations open at level %d." % unlock
	elif chosen == "":
		note = "Choose a specialization."
	if note != "":
		box.add_child(UiKit.label(note, UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
	return box


static func _talent_summary(pack: Dictionary, state: Dictionary) -> Control:
	var box := UiKit.section("Talents")
	var chosen: Dictionary = state.get("talents", {})
	var lines: Array[String] = []
	for row: Dictionary in RpgTalents.class_talents(pack, str(state["class_id"]))["rows"]:
		var pick := str(chosen.get(str(int(row["level"])), ""))
		for o: Dictionary in row["options"]:
			if str(o["id"]) == pick:
				lines.append("Lv %d: %s" % [row["level"], o["display_name"]])
	box.add_child(
		UiKit.label(
			"\n".join(lines) if lines else "None chosen yet (Skills > Talents).",
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT if lines else UiTheme.TEXT_DIM,
			300
		)
	)
	return box
