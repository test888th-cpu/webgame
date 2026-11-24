class_name StreetGearPage
extends RefCounted
## The street's Equipment and Bag screens, in the original Bag layout (CharacterTabs:
## worn slots around the character, the bag as an ItemSlot grid, an item's details
## beside them). Equipment shows the reference's own slots (data/rpg/
## equipment_slots.json, 13 of them); the Bag shows only the copies the character
## carries (state.inventory, one row per copy). Equip and Take off go through
## RpgCharacter.equip / unequip via the street; a refused equip shows the engine's
## own reason (RpgCharacter.equip_problem) and changes nothing.

const BAG_COLUMNS := 8
const BAG_MIN_CELLS := 24
const SLOT_SIZE := 34.0
const DETAIL_WIDTH := 190.0


static func equipment(street: Node) -> Control:
	var content: ContentDB = street.content
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var columns := HBoxContainer.new()
	columns.name = "Equipment"
	columns.add_theme_constant_override("separation", UiTheme.PAD)
	var doll_card := PanelContainer.new()
	doll_card.add_theme_stylebox_override("panel", CharacterTabs._inset())
	columns.add_child(doll_card)
	var doll := HBoxContainer.new()
	doll.add_theme_constant_override("separation", 6)
	doll_card.add_child(doll)
	var slots := _slot_ids(content)
	var half := ceili(slots.size() / 2.0)
	doll.add_child(_worn_column(street, slots.slice(0, half)))
	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	doll.add_child(middle)
	var view := SpriteView.new()
	view.custom_minimum_size = Vector2(76, 104)
	middle.add_child(view)
	view.show_art(content, "class_%s_m" % state["class_id"], 1.6)
	doll.add_child(_worn_column(street, slots.slice(half)))
	columns.add_child(details(street))
	return columns


static func bag(street: Node) -> Control:
	var content: ContentDB = street.content
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var columns := HBoxContainer.new()
	columns.name = "Bag"
	columns.add_theme_constant_override("separation", UiTheme.PAD)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiTheme.GAP)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	var header := HBoxContainer.new()
	left.add_child(header)
	var rows: Array = state["inventory"]
	var title := UiKit.label(
		"BAG  %d item%s" % [rows.size(), "" if rows.size() == 1 else "s"],
		UiTheme.SIZE_CAPTION,
		UiTheme.TEXT_DIM
	)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiKit.icon_rect(content, "coin"))
	header.add_child(UiKit.label(str(state["copper"]), UiTheme.SIZE_BODY, UiTheme.GOLD))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "BagGrid"
	grid.columns = BAG_COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(grid)
	var cells := maxi(BAG_MIN_CELLS, ceili(rows.size() / float(BAG_COLUMNS)) * BAG_COLUMNS)
	for i in cells:
		var slot := ItemSlot.new(SLOT_SIZE)
		if i < rows.size():
			var item_id := str(rows[i]["item_id"])
			slot.name = "Bag_%d" % i
			slot.show_reference(content, pack, item_id, int(state["level"]))
			slot.pressed.connect(street.menu_select.bind("bag:%d" % i))
			if RpgCharacter.equip_problem(content, pack, state, i) == "":
				slot.quick = street.menu_action.bind("equip", i)
		else:
			slot.focus_mode = Control.FOCUS_NONE
			slot.disabled = true
		grid.add_child(slot)
	left.add_child(
		UiKit.label("Click: details   Right click: equip", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
	)
	columns.add_child(details(street))
	return columns


## The reference's slot ids, in their own order.
static func _slot_ids(content: ContentDB) -> Array:
	var out: Array = []
	for s: Dictionary in content.rpg.get("equipment", {}).get("reference", {}).get("slots", []):
		out.append(str(s["id"]))
	return out


static func _worn_column(street: Node, slot_ids: Array) -> VBoxContainer:
	var content: ContentDB = street.content
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	for slot_id: String in slot_ids:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var slot := ItemSlot.new(SLOT_SIZE - 6)
		slot.name = "Worn_" + slot_id
		slot.placeholder = UiKit.icon(content, str(RpgItemText.SLOT_ICONS.get(slot_id, "")))
		var item_id := str(state["equipment"].get(slot_id, ""))
		slot.show_reference(content, pack, item_id, int(state["level"]))
		if item_id != "":
			slot.pressed.connect(street.menu_select.bind("worn:" + slot_id))
			slot.quick = street.menu_action.bind("unequip", slot_id)
		else:
			slot.tooltip_text = "%s: empty" % RpgItemText.SLOT_NAMES.get(slot_id, slot_id)
			slot.focus_mode = Control.FOCUS_NONE
		row.add_child(slot)
		var words := VBoxContainer.new()
		words.add_theme_constant_override("separation", -3)
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_child(
			UiKit.label(
				RpgItemText.SLOT_NAMES.get(slot_id, slot_id).to_upper(),
				UiTheme.SIZE_CAPTION - 1,
				UiTheme.TEXT_FAINT
			)
		)
		if item_id != "":
			var worn := UiKit.label(
				RpgItemText.name_of(pack, item_id),
				UiTheme.SIZE_CAPTION,
				RpgItemText.color(pack, item_id)
			)
			worn.custom_minimum_size.x = 70
			worn.clip_text = true
			words.add_child(worn)
		row.add_child(words)
		column.add_child(row)
	return column


## The selected item (street.menu_focus "bag:<index>" or "worn:<slot>"): its name,
## grade, kind, stats, copy quality and sources, and what can be done with it.
static func details(street: Node) -> Control:
	var content: ContentDB = street.content
	var pack: Dictionary = street.pack
	var state: Dictionary = street.state
	var card := PanelContainer.new()
	card.name = "Details"
	card.add_theme_stylebox_override("panel", CharacterTabs._inset())
	card.custom_minimum_size.x = DETAIL_WIDTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var focus := str(street.menu_focus)
	var item_id := ""
	var quality: Variant = null
	var action: Button = null
	if focus.begins_with("bag:"):
		var index := int(focus.substr(4))
		if index < state["inventory"].size():
			item_id = str(state["inventory"][index]["item_id"])
			quality = state["inventory"][index].get("quality")
			var why := RpgCharacter.equip_problem(content, pack, state, index)
			action = UiKit.button("Equip", street.menu_action.bind("equip", index), why != "")
			action.tooltip_text = why
			action.name = "Equip"
			if why != "":
				box.set_meta("why", why)
	elif focus.begins_with("worn:"):
		var slot_id := focus.substr(5)
		item_id = str(state["equipment"].get(slot_id, ""))
		quality = state.get("equipment_quality", {}).get(slot_id)
		action = UiKit.button("Take off", street.menu_action.bind("unequip", slot_id))
		action.name = "Unequip"
	if item_id == "":
		box.add_child(
			UiKit.label(
				"Select an item to see its details.",
				UiTheme.SIZE_SMALL,
				UiTheme.TEXT_DIM,
				DETAIL_WIDTH - 12
			)
		)
		if action:
			action.free()
		return card
	box.add_child(
		UiKit.label(
			RpgItemText.name_of(pack, item_id),
			UiTheme.SIZE_H2,
			RpgItemText.color(pack, item_id),
			DETAIL_WIDTH - 12
		)
	)
	box.add_child(
		UiKit.label(RpgItemText.kind(pack, item_id), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM)
	)
	var lines := RpgItemText.stat_lines(pack, item_id)
	var copy := RpgItemText.copy_quality(quality)
	if copy != "":
		lines.append(copy)
	for line: String in lines:
		box.add_child(UiKit.label(line, UiTheme.SIZE_SMALL, UiTheme.TEXT, DETAIL_WIDTH - 12))
	var from := RpgItemText.sources(pack, item_id)
	if not from.is_empty():
		box.add_child(UiKit.label("DROPS FROM", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT))
		for line: String in from.slice(0, 4):
			box.add_child(UiKit.label(line, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	if action:
		box.add_child(action)
	if box.has_meta("why"):
		box.add_child(
			UiKit.label(str(box.get_meta("why")), UiTheme.SIZE_CAPTION, UiTheme.DANGER, 170)
		)
	if not str(RpgPack.item(pack, item_id).get("kind")) in ["weapon", "armor"]:
		box.add_child(
			UiKit.label("It has no use of its own.", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT, 170)
		)
	return card
