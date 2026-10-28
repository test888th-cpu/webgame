class_name CharacterSelect
extends RefCounted
## The account's characters, one card per slot (RosterRules.max_characters):
## the hero as they look now, their name, hero, level, where they are and
## when they were last played. Enter (or a click) on a card plays it; an
## empty slot makes a new character. Delete asks once more, by name, before
## the character goes (SaveStore keeps the file aside, it is never erased).

const SIZE := Vector2(600, 300)
const CARD := Vector2(134, 196)


## `on_play(id)`, `on_create()`, `on_delete(id)` and `on_close()` are the
## title screen's.
static func build(
	content: ContentDB,
	roster: Array[PlayerProfile],
	on_play: Callable,
	on_create: Callable,
	on_delete: Callable,
	on_close: Callable
) -> Control:
	var most := RosterRules.max_characters(content)
	var parts := UiKit.screen(content, "Characters", "menu_character", "", SIZE, on_close)
	var body: VBoxContainer = parts["body"]
	body.add_child(
		UiKit.label(
			(
				"%d of %d slots used. Each character keeps its own level, gear and story."
				% [roster.size(), most]
			),
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_DIM
		)
	)
	var row := HBoxContainer.new()
	row.name = "Slots"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var delete := UiKit.button("Delete", func() -> void: pass)
	delete.name = "Delete"
	delete.focus_mode = Control.FOCUS_NONE
	var chosen := [""]
	var pick := func(id: String) -> void:
		chosen[0] = id
		delete.disabled = id == ""
		delete.text = "Delete"
		delete.remove_theme_color_override("font_color")
	for i in most:
		var card: Button
		if i < roster.size():
			var character := roster[i]
			card = _card(content, character)
			card.pressed.connect(on_play.bind(character.id))
			card.focus_entered.connect(pick.bind(character.id))
		else:
			card = _empty_card()
			card.pressed.connect(on_create)
			card.focus_entered.connect(pick.bind(""))
		card.name = "Slot%d" % i
		row.add_child(card)
	delete.pressed.connect(
		func() -> void:
			var id: String = chosen[0]
			if id == "":
				return
			var who := ""
			for character in roster:
				who = character.name if character.id == id else who
			# The only way back is the saves folder: ask once more, by name.
			if delete.text == "Delete":
				delete.text = "Delete %s for good?" % who
				delete.add_theme_color_override("font_color", UiTheme.DANGER)
				return
			on_delete.call(id)
	)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", UiTheme.GAP)
	footer.add_child(UiKit.key_hint("Enter", "Play"))
	footer.add_child(UiKit.key_hint("A D", "Choose"))
	footer.add_child(UiKit.key_hint("Esc", "Back"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(gap)
	footer.add_child(delete)
	body.add_child(footer)
	pick.call(roster[0].id if roster else "")
	return parts["root"]


## "just now", "5 min ago", "3 h ago", "2 days ago".
static func ago(seconds: int) -> String:
	if seconds < 60:
		return "just now"
	if seconds < 3600:
		return "%d min ago" % (seconds / 60)
	if seconds < 86400:
		return "%d h ago" % (seconds / 3600)
	var days := seconds / 86400
	return "1 day ago" if days == 1 else "%d days ago" % days


static func _frame(button: Button, lit: Color) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := UiTheme.panel_style()
		style.bg_color = Color(0.07, 0.07, 0.12, 0.92)
		style.shadow_size = 0
		style.border_color = lit if state in ["hover", "focus"] else UiTheme.BORDER
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_content_margin_all(6)
		button.add_theme_stylebox_override(state, style)


static func _card(content: ContentDB, character: PlayerProfile) -> Button:
	var hero := content.hero(character.hero)
	var color := Color.from_string(str(hero.get("color", "")), UiTheme.ACCENT)
	var card := Button.new()
	card.custom_minimum_size = CARD
	card.focus_mode = Control.FOCUS_ALL
	card.tooltip_text = "Play %s" % character.name
	_frame(card, color)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	card.add_child(column)
	var view := SpriteView.new()
	view.custom_minimum_size = Vector2(0, 92)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(view)
	view.show_art(content, content.hero_art(character), 1.4)
	var lines := [
		[character.name, UiTheme.SIZE_H2, UiTheme.TEXT],
		[str(hero.get("title", "")).to_upper(), UiTheme.SIZE_CAPTION, color],
		["Level %d" % character.level, UiTheme.SIZE_BODY, UiTheme.ACCENT],
		[str(content.area(character.area).get("name", "")), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM],
	]
	if character.saved_at > 0:
		var seconds := int(Time.get_unix_time_from_system()) - character.saved_at
		lines.append(["Played " + ago(maxi(0, seconds)), UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT])
	for line: Array in lines:
		var label := UiKit.label(line[0], line[1], line[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	return card


static func _empty_card() -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD
	card.focus_mode = Control.FOCUS_ALL
	card.text = "+\nNew character"
	card.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	card.add_theme_color_override("font_focus_color", UiTheme.ACCENT)
	card.add_theme_color_override("font_hover_color", UiTheme.ACCENT)
	_frame(card, UiTheme.ACCENT)
	return card
