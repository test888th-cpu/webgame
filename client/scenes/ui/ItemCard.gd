class_name ItemCard
extends RefCounted
## The item detail card: icon, name in its rarity colour, kind, level
## requirement, what it does, how it compares with what is worn now, its
## story, and what you can do with it. `details` is also the shop's right
## panel, so an item reads the same everywhere.

const WIDTH := 236.0
## Where-to-get lines shown before "and N more".
const SOURCES_SHOWN := 3


## The card's information, without buttons. `worn_slot` is set when showing
## an equipped item (no comparison with itself).
static func details(
	content: ContentDB, profile: PlayerProfile, item_id: String, worn_slot := ""
) -> VBoxContainer:
	var item := content.item(item_id)
	var box := VBoxContainer.new()
	box.name = "ItemDetails"
	box.add_theme_constant_override("separation", 3)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	head.add_child(_big_icon(content, item))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(names)
	names.add_child(UiKit.label(str(item["name"]), UiTheme.SIZE_H2, ItemText.rarity_color(item)))
	names.add_child(UiKit.label(ItemText.kind(item), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	if worn_slot:
		names.add_child(UiKit.label("Equipped", UiTheme.SIZE_CAPTION, UiTheme.ACCENT))
	box.add_child(HSeparator.new())
	if item.get("type") == "equipment":
		var needed := int(item.get("level", 1))
		var ok := profile.level >= needed
		box.add_child(
			UiKit.label(
				(
					"Requires level %d" % needed
					if ok
					else "Requires level %d  (you are %d)" % [needed, profile.level]
				),
				UiTheme.SIZE_SMALL,
				UiTheme.TEXT_DIM if ok else UiTheme.DANGER
			)
		)
	for line: Array in ItemText.effect_lines(item):
		box.add_child(UiKit.label(line[0], UiTheme.SIZE_BODY, line[1]))
	if item.get("type") == "equipment" and not worn_slot:
		var current := content.item(profile.equipment[item["slot"]])
		var changes := ItemText.compare_lines(item, current)
		var against := "Compared with %s" % current["name"] if current else "Slot is empty"
		box.add_child(UiKit.label(against, UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT))
		if current and changes.is_empty():
			box.add_child(UiKit.label("No change", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
		if current:
			for line: Array in changes:
				box.add_child(UiKit.label("  " + str(line[0]), UiTheme.SIZE_SMALL, line[1]))
	var lore := UiKit.label(
		str(item.get("description", "")), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, WIDTH - 16
	)
	box.add_child(lore)
	# Where to find more: the farming loop needs a target, not a guess.
	var sources := content.sources(item_id)
	if not sources.is_empty() and item.get("type") != "key":
		box.add_child(UiKit.label("WHERE TO GET", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT))
		for i in mini(sources.size(), SOURCES_SHOWN):
			box.add_child(
				UiKit.label("  " + str(sources[i]["text"]), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
			)
		if sources.size() > SOURCES_SHOWN:
			box.add_child(
				UiKit.label(
					"  and %d more" % (sources.size() - SOURCES_SHOWN),
					UiTheme.SIZE_CAPTION,
					UiTheme.TEXT_FAINT
				)
			)
	return box


## A modal card over `parent` with action buttons. Each action is
## {"text", "call", optional "confirm" (asks again before calling)}.
## Returns the overlay (free it to close).
static func popup(
	parent: Control,
	content: ContentDB,
	profile: PlayerProfile,
	item_id: String,
	worn_slot: String,
	actions: Array[Dictionary],
	on_close: Callable
) -> Control:
	var overlay := Control.new()
	overlay.name = "ItemCard"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				on_close.call()
	)
	overlay.add_child(shade)
	var frame := PanelContainer.new()
	frame.name = "Card"
	var style := UiTheme.panel_style()
	style.border_color = ItemText.rarity_color(content.item(item_id))
	style.set_border_width_all(1)
	frame.add_theme_stylebox_override("panel", style)
	frame.custom_minimum_size.x = WIDTH
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	frame.add_child(column)
	column.add_child(details(content, profile, item_id, worn_slot))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 4)
	column.add_child(buttons)
	for action: Dictionary in actions:
		var button := UiKit.button(str(action["text"]), func() -> void: pass)
		var confirm := str(action.get("confirm", ""))
		var call: Callable = action["call"]
		button.pressed.connect(
			func() -> void:
				if confirm and button.text != confirm:
					button.text = confirm
					button.add_theme_color_override("font_color", UiTheme.DANGER)
					return
				call.call()
		)
		buttons.add_child(button)
	buttons.add_child(UiKit.button("Close", on_close))
	parent.add_child(overlay)
	UiKit.focus_first(buttons)
	return overlay


static func _big_icon(content: ContentDB, item: Dictionary) -> PanelContainer:
	var holder := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b0c14")
	style.border_color = ItemText.rarity_color(item)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(3)
	holder.add_theme_stylebox_override("panel", style)
	holder.add_child(UiKit.icon_rect(content, str(item.get("icon", "")), 2.0))
	return holder
