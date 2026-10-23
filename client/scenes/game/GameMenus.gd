class_name GameMenus
extends RefCounted
## Builds the in-game screens for Game.gd: the tabbed pause window, the shop,
## NPC conversations and the knock-out screen. Screens only show the profile
## and call back into Game's actions, which own every change; after an action
## Game simply rebuilds the screen. All styling comes from UiTheme/UiKit.

## Pause window tabs, and the menu name Game reports for each (the probe and
## tests read it).
const TABS := ["Status", "Bag", "Quests", "Controls", "Game"]
const TAB_MENU_NAMES := ["pause", "inventory", "quests", "controls", "system"]
const TAB_STATUS := 0
const TAB_BAG := 1
const TAB_QUESTS := 2
const WINDOW_SIZE := Vector2(480, 296)
const SHOP_SIZE := Vector2(480, 272)
const LIST_WIDTH := 180.0
const DETAIL_WIDTH := 230.0
## Shown on the Controls tab: action, keyboard, gamepad.
const CONTROLS := [
	["Move", "WASD / Arrows", "Left stick"],
	["Light attack (combo)", "J / Z", "X / Square"],
	["Heavy attack", "K / X", "Y / Triangle"],
	["Dodge", "Space / L", "A / Cross"],
	["Guard (hold)", "Shift / I", "LB / L1"],
	["Talk, shop", "E / U", "B / Circle"],
	["Eat (quick heal)", "H / Q", "RB / R1"],
	["Menu", "Esc / P", "Start"],
	["Menu tabs", "Q  E", "LB  RB"],
]
const STATE_TAGS := {
	"active": ["In progress", UiTheme.TEAL],
	"complete": ["Ready to hand in", UiTheme.ACCENT],
	"turned_in": ["Done", UiTheme.GOOD],
}


static func pause(game: Game, tab: int) -> Control:
	var parts := UiKit.window("Paused", WINDOW_SIZE, "Q E  Tabs     Esc  Resume")
	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Focus stays on the tab's content; Q/E (LB/RB) switch tabs.
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	parts["body"].add_child(tabs)
	tabs.add_child(_status(game))
	tabs.add_child(_bag(game))
	tabs.add_child(_quests(game))
	tabs.add_child(_controls())
	tabs.add_child(_system(game))
	for i in TABS.size():
		tabs.set_tab_title(i, TABS[i])
	tabs.current_tab = tab
	tabs.tab_changed.connect(
		func(index: int) -> void:
			game.menu_name = TAB_MENU_NAMES[index]
			UiKit.focus_first(tabs.get_current_tab_control())
	)
	return parts["root"]


## Switches the open pause window's tab by `step`, wrapping around.
static func cycle_tab(menu: Control, step: int) -> void:
	var tabs: TabContainer = menu.find_child("Tabs", true, false)
	if tabs:
		tabs.current_tab = posmod(tabs.current_tab + step, tabs.get_tab_count())


static func _status(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var hero := game.zone.hero
	var stats := profile.stats(content)
	var columns := HBoxContainer.new()
	columns.name = "Status"
	columns.add_theme_constant_override("separation", UiTheme.PAD * 2)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UiTheme.GAP)
	left.custom_minimum_size.x = 200
	columns.add_child(left)
	var hero_data := content.hero(profile.hero)
	var hero_box := UiKit.section(
		"%s  -  %s  -  Level %d" % [profile.name, hero_data["title"], profile.level]
	)
	left.add_child(hero_box)
	hero_box.add_child(_meter("HP", hero.hp, hero.max_hp, UiTheme.HP))
	hero_box.add_child(_meter("Energy", hero.energy, CombatRules.MAX_ENERGY, UiTheme.EP))
	if profile.level < profile.max_level(content):
		hero_box.add_child(_meter("XP", profile.xp, profile.xp_to_next(content), UiTheme.XP))
	else:
		hero_box.add_child(UiKit.row("XP", UiKit.label("Max level", UiTheme.SIZE_BODY)))
	var stat_box := UiKit.section("Stats")
	left.add_child(stat_box)
	stat_box.add_child(
		UiKit.row("Damage", UiKit.label("%d%%" % roundi(float(stats["power"]) * 100.0)))
	)
	stat_box.add_child(UiKit.row("Defense", UiKit.label(str(stats["defense"]))))
	var coins := HBoxContainer.new()
	coins.add_child(UiKit.icon_rect(content, "coin"))
	coins.add_child(UiKit.label(str(profile.money), UiTheme.SIZE_BODY, UiTheme.GOLD))
	stat_box.add_child(UiKit.row("Coins", coins))

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UiTheme.GAP)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	var gear := UiKit.section("Equipped")
	right.add_child(gear)
	for slot: String in PlayerProfile.SLOTS:
		var item := content.item(profile.equipment[slot])
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UiTheme.GAP)
		line.add_child(UiKit.icon_rect(content, str(item.get("icon", ""))))
		line.add_child(UiKit.label(slot.capitalize(), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
		var name_label := UiKit.label(
			str(item.get("name", "Nothing")),
			UiTheme.SIZE_BODY,
			UiTheme.TEXT if item else UiTheme.TEXT_FAINT
		)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(name_label)
		gear.add_child(line)
	var where := UiKit.section("Location")
	right.add_child(where)
	where.add_child(UiKit.label(str(game.zone.area.get("name", "")), UiTheme.SIZE_BODY))
	var done := 0
	for quest_id: String in profile.quests:
		done += 1 if profile.quests[quest_id]["state"] == "turned_in" else 0
	where.add_child(
		UiKit.label(
			"Quests done: %d / %d" % [done, content.quests.size()],
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_DIM
		)
	)
	return columns


## The bag: equipped items first (marked), then everything carried. The
## right side describes the selected item and offers its action.
static func _bag(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var entries: Array[Dictionary] = []
	for slot: String in PlayerProfile.SLOTS:
		if profile.equipment[slot]:
			entries.append({"item": profile.equipment[slot], "slot": slot})
	for item_id: String in profile.inventory:
		entries.append({"item": item_id, "slot": ""})

	var columns := HBoxContainer.new()
	columns.name = "Bag"
	columns.add_theme_constant_override("separation", UiTheme.PAD)
	var list := _item_list()
	columns.add_child(list)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", UiTheme.GAP)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(detail)
	if entries.is_empty():
		list.visible = false
		detail.add_child(
			UiKit.label(
				"Your bag is empty. Ama in Depot Yard sells food and gear.",
				UiTheme.SIZE_BODY,
				UiTheme.TEXT_DIM,
				DETAIL_WIDTH + LIST_WIDTH
			)
		)
		return columns
	var selected := 0
	for i in entries.size():
		var entry := entries[i]
		var item := content.item(entry["item"])
		var text := str(item["name"])
		if entry["slot"]:
			text += "  (on)"
		elif profile.count(entry["item"]) > 1:
			text += "  x%d" % profile.count(entry["item"])
		list.add_item(text, UiKit.icon(content, str(item.get("icon", ""))))
		if entry["slot"]:
			list.set_item_custom_fg_color(i, UiTheme.ACCENT)
		if entry["item"] == game.menu_focus and (entry["slot"] != "") == game.menu_focus_equipped:
			selected = i
	var show := func(index: int) -> void: _bag_detail(game, detail, entries[index])
	list.item_selected.connect(show)
	list.item_activated.connect(func(index: int) -> void: _bag_action(game, entries[index]).call())
	list.select(selected)
	list.ensure_current_is_visible()
	show.call(selected)
	return columns


static func _bag_detail(game: Game, detail: VBoxContainer, entry: Dictionary) -> void:
	for child in detail.get_children():
		child.queue_free()
	var item := game.content.item(entry["item"])
	var kind := str(item["type"]).capitalize()
	if entry["slot"]:
		kind += "  -  equipped"
	_item_header(game.content, detail, item, kind)
	if not entry["slot"]:
		detail.add_child(
			UiKit.row("Carried", UiKit.label("x%d" % game.profile.count(entry["item"])))
		)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)
	var label: String
	if entry["slot"]:
		label = "Unequip"
	elif item["type"] == "consumable":
		label = "Use"
	else:
		label = "Equip"
	var action := UiKit.button(label, _bag_action(game, entry))
	action.focus_mode = Control.FOCUS_NONE  # Enter on the list does the same
	var bottom := HBoxContainer.new()
	bottom.add_child(UiKit.key_hint("Enter", label))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(gap)
	bottom.add_child(action)
	detail.add_child(bottom)


static func _bag_action(game: Game, entry: Dictionary) -> Callable:
	if entry["slot"]:
		return game._unequip.bind(entry["slot"])
	if game.content.item(entry["item"])["type"] == "consumable":
		return game._use.bind(entry["item"])
	return game._equip.bind(entry["item"])


static func _quests(game: Game) -> Control:
	var content := game.content
	var profile := game.profile
	var scroll := ScrollContainer.new()
	scroll.name = "Quests"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UiTheme.GAP)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	# Open quests first, finished ones after.
	var order: Array[String] = []
	for state: String in ["complete", "active", "turned_in"]:
		for quest_id: String in profile.quests:
			if profile.quests[quest_id]["state"] == state:
				order.append(quest_id)
	if order.is_empty():
		column.add_child(
			UiKit.label(
				"No quests yet. Chief Odo in Depot Yard has work for you.",
				UiTheme.SIZE_BODY,
				UiTheme.TEXT_DIM,
				420
			)
		)
	for quest_id in order:
		column.add_child(_quest_card(content, profile, quest_id))
	return scroll


static func _quest_card(content: ContentDB, profile: PlayerProfile, quest_id: String) -> Control:
	var quest: Dictionary = content.quests[quest_id]
	var entry: Dictionary = profile.quests[quest_id]
	var card := PanelContainer.new()
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var tag: Array = STATE_TAGS.get(entry["state"], ["", UiTheme.TEXT_DIM])
	box.add_child(UiKit.row(str(quest["name"]), UiKit.label(tag[0], UiTheme.SIZE_SMALL, tag[1])))
	box.add_child(UiKit.label(str(quest["description"]), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, 420))
	if entry["state"] != "turned_in":
		var count := int(quest["objective"]["count"])
		box.add_child(_meter("Progress", mini(int(entry["progress"]), count), count, UiTheme.TEAL))
	box.add_child(
		UiKit.label("Reward: " + reward_text(content, quest), UiTheme.SIZE_SMALL, UiTheme.GOLD)
	)
	return card


static func reward_text(content: ContentDB, quest: Dictionary) -> String:
	var rewards: Dictionary = quest.get("rewards", {})
	var parts: Array[String] = []
	if int(rewards.get("money", 0)):
		parts.append("%d coins" % int(rewards["money"]))
	if int(rewards.get("xp", 0)):
		parts.append("%d XP" % int(rewards["xp"]))
	var items: Dictionary = rewards.get("items", {})
	for item_id: String in items:
		parts.append("%s x%d" % [content.item(item_id).get("name", item_id), int(items[item_id])])
	return ",  ".join(parts) if parts else "-"


static func _controls() -> Control:
	var grid := GridContainer.new()
	grid.name = "Controls"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UiTheme.PAD * 2)
	grid.add_theme_constant_override("v_separation", 3)
	for heading: String in ["ACTION", "KEYBOARD", "GAMEPAD"]:
		grid.add_child(UiKit.label(heading, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	for line: Array in CONTROLS:
		grid.add_child(UiKit.label(line[0], UiTheme.SIZE_BODY))
		grid.add_child(UiKit.label(line[1], UiTheme.SIZE_BODY, UiTheme.ACCENT))
		grid.add_child(UiKit.label(line[2], UiTheme.SIZE_BODY, UiTheme.TEAL))
	return grid


static func _system(game: Game) -> Control:
	var column := VBoxContainer.new()
	column.name = "Game"
	column.add_theme_constant_override("separation", UiTheme.GAP)
	var buttons := VBoxContainer.new()
	buttons.custom_minimum_size.x = 160
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	buttons.add_child(UiKit.button("Resume", game.close_menu))
	buttons.add_child(UiKit.button("Save game", game._save_game))
	buttons.add_child(UiKit.button("Save and quit to title", game._quit_to_title))
	column.add_child(buttons)
	column.add_child(HSeparator.new())
	var options := UiKit.section("Options")
	column.add_child(options)
	options.add_child(_toggle("Screen shake on heavy hits", "screen_shake"))
	options.add_child(_toggle("Show frame rate", "show_fps"))
	options.add_child(_volume())
	column.add_child(
		UiKit.label(
			"Progress also saves on its own when you change area, shop or hand in a quest.",
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_FAINT,
			420
		)
	)
	return column


static func _volume() -> Control:
	var slider := HSlider.new()
	slider.name = "Volume"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.1
	slider.value = float(GameSession.settings.get("sfx_volume", 0.8))
	slider.custom_minimum_size = Vector2(120, 12)
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(
		func(value: float) -> void:
			GameSession.set_setting("sfx_volume", value)
			Sfx.play("ui_move")
	)
	return UiKit.row("Sound volume", slider)


static func _toggle(text: String, key: String) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.button_pressed = bool(GameSession.settings.get(key, false))
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.toggled.connect(func(on: bool) -> void: GameSession.set_setting(key, on))
	return toggle


## The vendor: wares on the left, the selected one described on the right.
static func shop(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var profile := game.profile
	var data: Dictionary = content.shops[npc["shop"]]
	var parts := UiKit.window(str(data["name"]), SHOP_SIZE, "Esc  Leave")
	var body: VBoxContainer = parts["body"]
	body.add_child(
		UiKit.label(
			'%s:  "%s"' % [npc["name"], npc.get("line", "")],
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_DIM,
			WINDOW_SIZE.x - 20
		)
	)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UiTheme.PAD)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	var list := _item_list()
	columns.add_child(list)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", UiTheme.GAP)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(detail)
	var wares: Array = data["items"]
	var selected := 0
	for i in wares.size():
		var item := content.item(wares[i])
		list.add_item(
			"%s   %d" % [item["name"], int(item["price"])], UiKit.icon(content, item["icon"])
		)
		if profile.money < int(item["price"]):
			list.set_item_custom_fg_color(i, UiTheme.TEXT_FAINT)
		if wares[i] == game.menu_focus:
			selected = i
	var show := func(index: int) -> void: _shop_detail(game, npc, detail, wares[index])
	list.item_selected.connect(show)
	list.item_activated.connect(func(index: int) -> void: game._buy(npc, wares[index]))
	list.select(selected)
	show.call(selected)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", UiTheme.GAP)
	footer.add_child(UiKit.key_hint("Enter", "Buy"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(gap)
	footer.add_child(UiKit.label("Your coins", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
	footer.add_child(UiKit.icon_rect(content, "coin"))
	footer.add_child(UiKit.label(str(profile.money), UiTheme.SIZE_H2, UiTheme.GOLD))
	body.add_child(footer)
	return parts["root"]


static func _shop_detail(
	game: Game, npc: Dictionary, detail: VBoxContainer, item_id: String
) -> void:
	for child in detail.get_children():
		child.queue_free()
	var item := game.content.item(item_id)
	_item_header(game.content, detail, item, str(item["type"]).capitalize())
	var owned := game.profile.count(item_id)
	for slot: String in PlayerProfile.SLOTS:
		owned += 1 if game.profile.equipment[slot] == item_id else 0
	detail.add_child(UiKit.row("You own", UiKit.label(str(owned))))
	var price := int(item["price"])
	var cost := HBoxContainer.new()
	cost.add_child(UiKit.icon_rect(game.content, "coin"))
	cost.add_child(UiKit.label(str(price), UiTheme.SIZE_BODY, UiTheme.GOLD))
	detail.add_child(UiKit.row("Price", cost))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)
	var short := game.profile.money < price
	var buy := UiKit.button(
		"Need %d more" % (price - game.profile.money) if short else "Buy",
		game._buy.bind(npc, item_id),
		short
	)
	buy.focus_mode = Control.FOCUS_NONE  # Enter on the list buys
	buy.size_flags_horizontal = Control.SIZE_SHRINK_END
	detail.add_child(buy)


## A conversation with a quest giver: their line, then what they offer.
static func conversation(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var profile := game.profile
	var parts := UiKit.dialog(str(npc["name"]), UiKit.portrait(content, str(npc.get("sprite", ""))))
	var body: VBoxContainer = parts["body"]
	var offers := 0
	var says := str(npc.get("line", ""))
	for quest_id in game.view.quests_of(npc):
		var state := QuestRules.status(profile, quest_id, content)
		var quest: Dictionary = content.quests[quest_id]
		if state == "available":
			offers += 1
			body.add_child(
				UiKit.label(str(quest["description"]), UiTheme.SIZE_BODY, UiTheme.TEXT, 470)
			)
			body.add_child(
				UiKit.label(
					"Reward: " + reward_text(content, quest), UiTheme.SIZE_SMALL, UiTheme.GOLD
				)
			)
			body.add_child(
				_choice('Accept  "%s"' % quest["name"], game._accept.bind(npc, quest_id))
			)
		elif state == "complete":
			offers += 1
			says = "Good work out there. Here's what I promised."
			body.add_child(
				_choice('Hand in  "%s"' % quest["name"], game._turn_in.bind(npc, quest_id))
			)
		elif state == "active":
			var count := int(quest["objective"]["count"])
			says = (
				'Still on "%s"? %d of %d so far.'
				% [quest["name"], profile.quests[quest_id]["progress"], count]
			)
	if offers == 0 and says == str(npc.get("line", "")):
		says = "Nothing more for now. Keep the streets clear."
	var line := UiKit.label('"%s"' % says, UiTheme.SIZE_BODY, UiTheme.TEXT_DIM, 470)
	body.add_child(line)
	body.move_child(line, 1)
	body.add_child(_choice("Goodbye", game.close_menu))
	return parts["root"]


static func _choice(text: String, on_press: Callable) -> Button:
	var choice := UiKit.button("  " + text, on_press)
	choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return choice


static func knocked_out(game: Game, loss: int) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.0, 0.02, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UiTheme.PAD)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(column)
	var heading := UiKit.overlay_label("KNOCKED OUT", UiTheme.SIZE_LOGO, UiTheme.DANGER)
	heading.add_theme_constant_override("outline_size", 8)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var home := str(game.content.area(game.content.start_area).get("name", "home"))
	var text := UiKit.label("The crew drags you back to %s." % home, UiTheme.SIZE_H2, UiTheme.TEXT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(text)
	var cost := UiKit.label(
		"You dropped %d coins in the street." % loss if loss else "You had no coins to lose.",
		UiTheme.SIZE_BODY,
		UiTheme.GOLD
	)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(cost)
	var again := UiKit.button("Get back up", game._recover.bind(loss))
	again.custom_minimum_size = Vector2(140, 22)
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(again)
	return root


static func _item_list() -> ItemList:
	var list := ItemList.new()
	list.custom_minimum_size.x = LIST_WIDTH
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(16, 16)
	list.focus_mode = Control.FOCUS_ALL
	list.allow_reselect = true
	list.item_selected.connect(func(_index: int) -> void: Sfx.play("ui_move", -6.0))
	return list


## Icon, name, kind, description and stat lines of an item.
static func _item_header(
	content: ContentDB, into: VBoxContainer, item: Dictionary, kind: String
) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UiTheme.PAD)
	head.add_child(UiKit.icon_rect(content, str(item.get("icon", "")), 2.0))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_child(UiKit.label(str(item["name"]), UiTheme.SIZE_H2))
	names.add_child(UiKit.label(kind, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	head.add_child(names)
	into.add_child(head)
	into.add_child(
		UiKit.label(
			str(item.get("description", "")), UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, DETAIL_WIDTH
		)
	)
	for line: Array in item_stats(item):
		into.add_child(UiKit.row(line[0], UiKit.label(line[1], UiTheme.SIZE_BODY, UiTheme.GOOD)))


## [label, value] pairs for what an item does.
static func item_stats(item: Dictionary) -> Array[Array]:
	var lines: Array[Array] = []
	if int(item.get("heal", 0)):
		lines.append(["Heals", "+%d HP" % int(item["heal"])])
	if int(item.get("energy", 0)):
		lines.append(["Energy", "+%d" % int(item["energy"])])
	if float(item.get("power", 0.0)):
		lines.append(["Damage", "+%d%%" % roundi(float(item["power"]) * 100.0)])
	if int(item.get("defense", 0)):
		lines.append(["Defense", "+%d" % int(item["defense"])])
	if int(item.get("max_hp", 0)):
		lines.append(["Max HP", "+%d" % int(item["max_hp"])])
	return lines


static func _meter(text: String, value: int, maximum: int, color: Color) -> Control:
	var bar := StatBar.new()
	bar.color = color
	bar.show_text = true
	bar.custom_minimum_size = Vector2(130, 9)
	bar.set_values(value, maximum, true)
	return UiKit.row(text, bar)
