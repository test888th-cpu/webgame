class_name CharacterTabs
extends RefCounted
## The two character tabs of the pause window.
##   Status     who the hero is, HP/energy/XP, and the attributes (read-only:
##              they come from the hero, the level and the equipment, shown
##              as base + gear), with what the next level brings.
##   Equipment  the six worn slots around the hero, and the bag as a grid.
##              Any item opens its card (ItemCard) with Equip / Unequip / Use
##              / Discard. Changes go through Game's actions.

const DOLL_LEFT := ["head", "body", "hands"]
const DOLL_RIGHT := ["weapon", "feet", "charm"]
const BAG_COLUMNS := 9
const BAG_MIN_CELLS := 36
## Cells show 16 px icons at 2x.
const SLOT_SIZE := 37.0


static func status(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var hero := content.hero(profile.hero)
	var columns := HBoxContainer.new()
	columns.name = "Status"
	columns.add_theme_constant_override("separation", UiTheme.PAD)

	# Left: the hero card.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _inset())
	card.custom_minimum_size.x = 176
	columns.add_child(card)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	card.add_child(left)
	left.add_child(UiKit.label(profile.name, UiTheme.SIZE_H1, UiTheme.TEXT))
	left.add_child(
		UiKit.label(
			"Level %d  %s" % [profile.level, str(hero["title"])],
			UiTheme.SIZE_SMALL,
			Color.from_string(str(hero.get("color", "")), UiTheme.ACCENT)
		)
	)
	var view := SpriteView.new()
	view.custom_minimum_size = Vector2(160, 112)
	left.add_child(view)
	view.show_art(content, game.view.hero_art(), 1.7)
	var fighter := game.zone.hero
	left.add_child(_bar_row("HP", fighter.hp, fighter.max_hp, UiTheme.HP))
	left.add_child(_bar_row("EN", int(fighter.energy), int(CombatRules.MAX_ENERGY), UiTheme.EP))
	var at_cap := profile.level >= profile.max_level(content)
	left.add_child(
		_bar_row("XP", profile.xp, 1 if at_cap else profile.xp_to_next(content), UiTheme.XP)
	)

	# Right: attributes, next level, record.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UiTheme.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	var attributes := UiKit.section("Attributes")
	right.add_child(attributes)
	var total := profile.stats(content)
	var gear := profile.gear_stats(content)
	for key: String in ItemText.STAT_NAMES:
		attributes.add_child(_attribute_row(key, float(total[key]), float(gear[key])))
	attributes.add_child(
		UiKit.label(
			"Attributes come from your hero, level and equipment.",
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_FAINT
		)
	)
	var next := UiKit.section("Next level")
	right.add_child(next)
	if at_cap:
		next.add_child(UiKit.label("Maximum level reached.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
	else:
		next.add_child(_next_level_line(content, profile))
	var record := UiKit.section("Record")
	right.add_child(record)
	var defeated := 0
	for enemy_id: String in profile.defeated:
		defeated += int(profile.defeated[enemy_id])
	var done := 0
	for quest_id: String in profile.quests:
		done += 1 if profile.quests[quest_id]["state"] == "turned_in" else 0
	record.add_child(
		UiKit.label(
			(
				"Enemies defeated %d     Quests done %d / %d     Coins %d"
				% [defeated, done, content.quests.size(), profile.money]
			),
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_DIM
		)
	)
	var go := UiKit.button("Equipment  >", GameMenus.switch_tab.bind(game, GameMenus.TAB_BAG))
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(go)
	return columns


static func equipment(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var columns := HBoxContainer.new()
	columns.name = "Equipment"
	columns.add_theme_constant_override("separation", UiTheme.PAD)

	# Left: the doll.
	var doll_card := PanelContainer.new()
	doll_card.add_theme_stylebox_override("panel", _inset())
	columns.add_child(doll_card)
	var doll_column := VBoxContainer.new()
	doll_column.add_theme_constant_override("separation", UiTheme.GAP)
	doll_card.add_child(doll_column)
	doll_column.add_child(UiKit.label("WORN", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	var doll := HBoxContainer.new()
	doll.add_theme_constant_override("separation", 6)
	doll_column.add_child(doll)
	doll.add_child(_slot_column(game, DOLL_LEFT))
	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_END
	doll.add_child(middle)
	var view := SpriteView.new()
	view.custom_minimum_size = Vector2(76, 104)
	middle.add_child(view)
	view.show_art(content, game.view.hero_art(), 1.6)
	var turn := HBoxContainer.new()
	turn.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_child(turn)
	for arrow: String in ["<", ">"]:
		var button := UiKit.button(arrow, view.turn)
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(20, 14)
		turn.add_child(button)
	doll.add_child(_slot_column(game, DOLL_RIGHT))
	var total := profile.stats(content)
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 8)
	for key: String in ItemText.STAT_NAMES:
		var pair := VBoxContainer.new()
		pair.add_theme_constant_override("separation", -2)
		pair.add_child(
			UiKit.label(ItemText.STAT_NAMES[key], UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
		)
		pair.add_child(
			UiKit.label(
				ItemText.stat_value(key, float(total[key])), UiTheme.SIZE_BODY, UiTheme.TEXT
			)
		)
		summary.add_child(pair)
	doll_column.add_child(summary)

	# Right: the bag.
	var bag := VBoxContainer.new()
	bag.add_theme_constant_override("separation", UiTheme.GAP)
	bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(bag)
	var header := HBoxContainer.new()
	bag.add_child(header)
	var title := UiKit.label("BAG", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiKit.icon_rect(content, "coin"))
	header.add_child(UiKit.label(str(profile.money), UiTheme.SIZE_BODY, UiTheme.GOLD))
	var ids := bag_order(content, profile)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "BagGrid"
	grid.columns = BAG_COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(grid)
	var cells := maxi(BAG_MIN_CELLS, ceili(ids.size() / float(BAG_COLUMNS)) * BAG_COLUMNS)
	for i in cells:
		var slot := ItemSlot.new(SLOT_SIZE)
		if i < ids.size():
			var item_id := ids[i]
			slot.name = "Bag_" + item_id
			slot.show_item(content, item_id, profile.count(item_id), profile.level)
			slot.pressed.connect(game.inspect_item.bind(item_id, ""))
		else:
			slot.focus_mode = Control.FOCUS_NONE
			slot.disabled = true
		grid.add_child(slot)
	bag.add_child(
		UiKit.label(
			"Select an item for details.  %d kinds of item" % ids.size(),
			UiTheme.SIZE_CAPTION,
			UiTheme.TEXT_FAINT
		)
	)
	return columns


## Bag order: consumables first, then gear by slot, rarest first.
static func bag_order(content: ContentDB, profile: PlayerProfile) -> Array[String]:
	var ids: Array[String] = []
	for item_id: String in profile.inventory:
		ids.append(item_id)
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			return _sort_key(content.item(a)) < _sort_key(content.item(b))
	)
	return ids


static func _sort_key(item: Dictionary) -> String:
	# Food first, then gear, then evidence at the end of the bag.
	var group: int = {"consumable": 0, "equipment": 1, "key": 2}.get(item.get("type"), 1)
	var slot := PlayerProfile.SLOTS.find(str(item.get("slot", "")))
	var rarity := ContentDB.RARITIES.size() - ContentDB.RARITIES.find(str(item.get("rarity")))
	return "%d%d%d%s" % [group, slot + 1, rarity, item.get("name", "")]


static func _slot_column(game: Game, slots: Array) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	for slot_name: String in slots:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		var slot := ItemSlot.new(SLOT_SIZE + 2)
		slot.name = "Worn_" + slot_name
		slot.placeholder = UiKit.icon(game.content, "slot_" + slot_name)
		var item_id: String = game.profile.equipment[slot_name]
		slot.show_item(game.content, item_id, 1, game.profile.level)
		if item_id:
			slot.pressed.connect(game.inspect_item.bind(item_id, slot_name))
		else:
			slot.tooltip_text = "%s: empty" % ItemText.SLOT_NAMES[slot_name]
		cell.add_child(slot)
		var caption := UiKit.label(
			ItemText.SLOT_NAMES[slot_name].to_upper(), UiTheme.SIZE_CAPTION - 1, UiTheme.TEXT_FAINT
		)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(caption)
		column.add_child(cell)
	return column


static func _attribute_row(key: String, total: float, gear: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_label := UiKit.label(ItemText.STAT_NAMES[key], UiTheme.SIZE_BODY, UiTheme.TEXT)
	name_label.custom_minimum_size.x = 52
	row.add_child(name_label)
	var value := UiKit.label(ItemText.stat_value(key, total), UiTheme.SIZE_H2, UiTheme.TEXT)
	value.custom_minimum_size.x = 34
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	var bonus := UiKit.label(
		"(%s gear)" % ItemText.bonus_value(key, gear) if absf(gear) > 0.0001 else "",
		UiTheme.SIZE_CAPTION,
		UiTheme.GOOD if gear >= 0.0 else UiTheme.DANGER
	)
	bonus.custom_minimum_size.x = 56
	row.add_child(bonus)
	var help := UiKit.label(ItemText.STAT_HELP[key], UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.clip_text = true
	row.add_child(help)
	return row


static func _next_level_line(content: ContentDB, profile: PlayerProfile) -> Control:
	var per_level: Dictionary = content.progression.get("per_level", {})
	var parts: Array[String] = []
	for key: String in ["max_hp", "power"]:
		if float(per_level.get(key, 0)) != 0.0:
			var gain := ItemText.bonus_value(key, float(per_level[key]))
			parts.append("%s %s" % [gain, ItemText.STAT_NAMES[key]])
	var unlocks := SkillRules.unlocked_at(content, profile.hero, profile.level + 1)
	for skill_id in unlocks:
		parts.append("new skill: " + str(content.skills[skill_id]["name"]))
	var line := UiKit.label(
		"Level %d:  %s" % [profile.level + 1, ",  ".join(parts)], UiTheme.SIZE_SMALL, UiTheme.TEAL
	)
	return line


static func _bar_row(text: String, value: int, maximum: int, color: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var caption := UiKit.label(text, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	caption.custom_minimum_size.x = 16
	row.add_child(caption)
	var bar := StatBar.new()
	bar.color = color
	bar.show_text = true
	bar.custom_minimum_size = Vector2(150, 9)
	bar.set_values(value, maximum, true)
	row.add_child(bar)
	return row


static func _inset() -> StyleBoxFlat:
	var style := UiTheme.panel_style()
	style.bg_color = Color("10121c")
	style.shadow_size = 0
	style.set_content_margin_all(6)
	return style
