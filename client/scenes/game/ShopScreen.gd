class_name ShopScreen
extends RefCounted
## The vendor's screen: Buy and Sell tabs (Q/E), the wares or the bag on the
## left, the chosen item on the right. Under the item sits the deal bar
## (amount, total, Buy/Sell), pinned to the bottom of the window so it is on
## screen however long the item card is; the card scrolls above it.
## Left/Right change the amount, Enter on the list trades one. Prices and
## what may be sold come from ShopRules; Game's _buy/_sell make the change
## and rebuild the screen, which reopens on the same tab and item.
##
## Selling many at once: on the Sell tab each item can be ticked (the "Tick"
## box by its deal bar; "[x]" in the list), and "Sell ticked" sells every
## ticked stack in one go. The ticks survive the screen's rebuilds (kept on
## the game node as the "sell_ticked" meta) and are cleared once sold.

const SIZE := Vector2(600, 318)
const LIST_WIDTH := 190.0
const TABS := ["buy", "sell"]


## `game.menu_focus` "buy:<item>" or "sell:<item>" picks the tab and item.
static func build(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var data: Dictionary = content.shops[npc["shop"]]
	var parts := UiKit.screen(content, str(data["name"]), "coin", "", SIZE, game.close_menu)
	var body: VBoxContainer = parts["body"]
	body.add_child(
		UiKit.label(
			'%s:  "%s"' % [npc["name"], npc.get("line", "")],
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_DIM,
			SIZE.x - 24
		)
	)
	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	var focus := game.menu_focus.split(":")
	for mode: String in TABS:
		tabs.add_child(_page(game, npc, mode, focus[1] if focus[0] == mode else ""))
	tabs.current_tab = maxi(0, TABS.find(focus[0]))
	tabs.tab_changed.connect(
		func(index: int) -> void:
			Sfx.play("ui_move", -6.0)
			UiKit.focus_first(tabs.get_child(index))
	)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", UiTheme.GAP)
	footer.add_child(UiKit.key_hint("Enter", "Trade 1"))
	footer.add_child(UiKit.key_hint("< >", "Amount"))
	footer.add_child(UiKit.key_hint("Q / E", "Buy / Sell"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(gap)
	footer.add_child(UiKit.icon_rect(content, "coin"))
	var coins := UiKit.label(str(game.profile.money), UiTheme.SIZE_H2, UiTheme.GOLD)
	coins.name = "Coins"
	footer.add_child(coins)
	body.add_child(footer)
	return parts["root"]


## What the shop would buy from the bag, in bag order.
static func sellable(content: ContentDB, profile: PlayerProfile) -> Array[String]:
	var ids: Array[String] = []
	for item_id in CharacterTabs.bag_order(content, profile):
		if ShopRules.sell_price(content, item_id) > 0:
			ids.append(item_id)
	return ids


static func _page(game: Game, npc: Dictionary, mode: String, chosen: String) -> Control:
	var content := game.content
	var profile := game.profile
	var page := HBoxContainer.new()
	page.name = "Buy" if mode == "buy" else "Sell"
	page.add_theme_constant_override("separation", UiTheme.PAD)
	var ids: Array = ShopRules.wares(profile, content, str(npc["shop"])) if mode == "buy" else []
	if mode == "sell":
		ids = sellable(content, profile)
	if ids.is_empty():
		var none := UiKit.label(
			"Nothing in your bag the trader wants.", UiTheme.SIZE_BODY, UiTheme.TEXT_DIM
		)
		page.add_child(none)
		return page
	var list := ItemList.new()
	list.name = "List"
	list.custom_minimum_size.x = LIST_WIDTH
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(16, 16)
	list.allow_reselect = true
	if mode == "sell":
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", UiTheme.GAP)
		column.add_child(list)
		column.add_child(_many_bar(game, npc, ids))
		page.add_child(column)
	else:
		page.add_child(list)
	var ticked := ticks(game)
	var detail := VBoxContainer.new()
	detail.name = "Detail"
	detail.add_theme_constant_override("separation", UiTheme.GAP)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(detail)
	var selected := 0
	for i in ids.size():
		var item := content.item(ids[i])
		var price := _unit_price(content, mode, ids[i])
		var count := profile.count(ids[i])
		var text := "%s   %d" % [item["name"], price]
		if mode == "sell":
			var plus := EnhanceRules.item_level(profile, ids[i])
			var name := "%s +%d" % [item["name"], plus] if plus else str(item["name"])
			text = "%s%s  x%d   %d" % ["[x] " if ticked.has(ids[i]) else "", name, count, price]
		list.add_item(text, UiKit.icon(content, item["icon"]))
		var dim := mode == "buy" and profile.money < price
		list.set_item_custom_fg_color(i, UiTheme.TEXT_FAINT if dim else ItemText.rarity_color(item))
		if ids[i] == chosen:
			selected = i
	var next := ShopRules.next_stock(profile, content, str(npc["shop"]))
	if mode == "buy" and next:
		# The next trader's stock, as the list's last, unselectable row.
		var row := list.add_item(next, null, false)
		list.set_item_custom_fg_color(row, UiTheme.TEAL)
		list.set_item_tooltip(row, next)
	var show := func(index: int) -> void:
		if index < ids.size():
			_deal(game, npc, detail, mode, ids[index])
	list.item_selected.connect(
		func(index: int) -> void:
			Sfx.play("ui_move", -6.0)
			show.call(index)
	)
	list.item_activated.connect(
		func(index: int) -> void:
			if index < ids.size():
				_trade(game, npc, mode, ids[index], 1)
	)
	list.gui_input.connect(
		func(event: InputEvent) -> void:
			for dir: String in ["ui_left", "ui_right"]:
				if event.is_action_pressed(dir) and detail.has_meta("step"):
					detail.get_meta("step").call(-1 if dir == "ui_left" else 1)
					list.accept_event()
	)
	list.select(selected)
	list.ensure_current_is_visible()
	show.call(selected)
	return page


static func _unit_price(content: ContentDB, mode: String, item_id: String) -> int:
	if mode == "sell":
		return ShopRules.sell_price(content, item_id)
	return int(content.item(item_id).get("price", 0))


## The most of `item_id` one deal may move: what the hero can afford, or
## what is in the bag (always at least 1, so the bar can say what is short).
static func _most(game: Game, mode: String, item_id: String) -> int:
	if mode == "sell":
		return clampi(game.profile.count(item_id), 1, ShopRules.MAX_AMOUNT)
	var cap := ShopRules.max_amount(game.content, item_id)
	return clampi(ShopRules.affordable(game.profile, game.content, item_id), 1, cap)


## The chosen item: its card (scrolling) and the deal bar under it.
static func _deal(
	game: Game, npc: Dictionary, detail: VBoxContainer, mode: String, item_id: String
) -> void:
	for child in detail.get_children():
		detail.remove_child(child)
		child.queue_free()
	var content := game.content
	var profile := game.profile
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(scroll)
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", UiTheme.GAP)
	scroll.add_child(card)
	card.add_child(ItemCard.details(content, profile, item_id, "", mode == "buy"))
	var owned := profile.owned(ContentDB.base_id(item_id))
	card.add_child(UiKit.row("You own", UiKit.label(str(owned))))
	if mode == "sell" and EnhanceRules.item_level(profile, item_id) > 0:
		card.add_child(
			UiKit.label("Its upgrades are lost when sold.", UiTheme.SIZE_SMALL, UiTheme.DANGER)
		)
	if mode == "sell":
		var tick := CheckBox.new()
		tick.name = "Tick"
		tick.text = "Tick to sell with others"
		tick.focus_mode = Control.FOCUS_NONE
		tick.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
		tick.button_pressed = ticks(game).has(item_id)
		tick.toggled.connect(func(on: bool) -> void: set_tick(game, npc, item_id, on))
		detail.add_child(tick)
	detail.add_child(_bar(game, npc, detail, mode, item_id))


static func _bar(
	game: Game, npc: Dictionary, detail: VBoxContainer, mode: String, item_id: String
) -> Control:
	var content := game.content
	var bar := PanelContainer.new()
	bar.name = "Deal"
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(4)
	bar.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UiTheme.GAP)
	bar.add_child(line)
	var most := _most(game, mode, item_id)
	var amount := [1]
	var count := UiKit.label("1", UiTheme.SIZE_BODY)
	count.name = "Amount"
	count.custom_minimum_size.x = 18
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var total := UiKit.label("", UiTheme.SIZE_H2, UiTheme.GOLD)
	total.name = "Total"
	var unit := _unit_price(content, mode, item_id)
	var trade := UiKit.button("", func() -> void: pass)
	trade.name = "Trade"
	trade.focus_mode = Control.FOCUS_NONE  # Enter on the list trades
	trade.custom_minimum_size.x = 64
	var precious := (
		EnhanceRules.item_level(game.profile, item_id) > 0
		or ContentDB.RARITIES.find(str(content.item(item_id).get("rarity"))) >= 2
	)
	var update := func() -> void:
		count.text = str(amount[0])
		total.text = str(unit * amount[0])
		var short: bool = mode == "buy" and game.profile.money < unit * amount[0]
		trade.disabled = short
		trade.text = "Need %d more" % (unit * amount[0] - game.profile.money) if short else ""
		if not short:
			trade.text = ("Buy" if mode == "buy" else "Sell")
		trade.remove_theme_color_override("font_color")
	var step := func(by: int) -> void:
		var next := clampi(amount[0] + by, 1, most)
		if next != amount[0]:
			amount[0] = next
			Sfx.play("ui_move", -6.0)
			update.call()
	detail.set_meta("step", step)
	trade.pressed.connect(
		func() -> void:
			# Rare gear and upgraded items ask once more before they go.
			if mode == "sell" and precious and trade.text != "Sure?":
				trade.text = "Sure?"
				trade.add_theme_color_override("font_color", UiTheme.DANGER)
				return
			_trade(game, npc, mode, item_id, amount[0])
	)
	# The amount picker shows only where more than one can change hands.
	var picker: Array[Control] = [
		_step_button("-", step.bind(-1)),
		count,
		_step_button("+", step.bind(1)),
		_step_button("Max", func() -> void: step.call(most)),
	]
	for control in picker:
		control.visible = most > 1
		line.add_child(control)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(gap)
	line.add_child(UiKit.icon_rect(content, "coin"))
	line.add_child(total)
	line.add_child(trade)
	update.call()
	return bar


static func _step_button(text: String, on_press: Callable) -> Button:
	var button := UiKit.button(text, on_press)
	button.name = "Step" + text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(16, 14)
	button.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	return button


static func _trade(game: Game, npc: Dictionary, mode: String, item_id: String, amount: int) -> void:
	if mode == "buy":
		game._buy(npc, item_id, amount)
	else:
		game._sell(npc, item_id, amount)


## The items ticked to sell together: {item key: true}.
static func ticks(game: Game) -> Dictionary:
	if not game.has_meta("sell_ticked"):
		game.set_meta("sell_ticked", {})
	return game.get_meta("sell_ticked")


## Ticks or unticks `item_id`, then shows the screen again on it.
static func set_tick(game: Game, npc: Dictionary, item_id: String, on: bool) -> void:
	if on:
		ticks(game)[item_id] = true
	else:
		ticks(game).erase(item_id)
	Sfx.play("ui_move", -6.0)
	game.menu_focus = "sell:" + item_id
	game.open_shop(npc)


## Under the Sell list: tick all or none, and sell every ticked stack.
static func _many_bar(game: Game, npc: Dictionary, ids: Array) -> Control:
	var ticked := ticks(game)
	for key: String in ticked.keys():
		if key not in ids:
			ticked.erase(key)  # sold or gone since
	var coins := 0
	var precious := false
	for key: String in ticked:
		coins += ShopRules.sell_price(game.content, key) * game.profile.count(key)
		precious = precious or EnhanceRules.item_level(game.profile, key) > 0
		precious = precious or ContentDB.RARITIES.find(str(game.content.item(key)["rarity"])) >= 2
	var box := HBoxContainer.new()
	box.name = "Many"
	box.add_theme_constant_override("separation", UiTheme.GAP)
	var all := UiKit.button("Tick all", func() -> void: _tick_all(game, npc, ids, true))
	all.name = "TickAll"
	var none := UiKit.button("Clear", func() -> void: _tick_all(game, npc, ids, false))
	none.name = "TickNone"
	var sell := UiKit.button("Sell ticked (%d)  %d" % [ticked.size(), coins], func() -> void: pass)
	sell.name = "SellTicked"
	sell.disabled = ticked.is_empty()
	sell.pressed.connect(
		func() -> void:
			# Rare gear or upgraded items among them: ask once more.
			if precious and not sell.text.begins_with("Sure?"):
				sell.text = "Sure? %d items" % ticked.size()
				sell.add_theme_color_override("font_color", UiTheme.DANGER)
				return
			sell_ticked(game, npc)
	)
	for button: Button in [all, none, sell]:
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
		box.add_child(button)
	return box


static func _tick_all(game: Game, npc: Dictionary, ids: Array, on: bool) -> void:
	var ticked := ticks(game)
	ticked.clear()
	if on:
		for key: String in ids:
			ticked[key] = true
	Sfx.play("ui_move", -6.0)
	game.menu_focus = game.menu_focus if game.menu_focus.begins_with("sell:") else "sell:"
	game.open_shop(npc)


## Sells every ticked stack (ShopRules.sell, one stack at a time), says what
## it came to, saves once and shows the Sell tab again.
static func sell_ticked(game: Game, npc: Dictionary) -> void:
	var ticked := ticks(game)
	var sold := 0
	var coins := 0
	for key: String in ticked.keys():
		var price := ShopRules.sell_price(game.content, key)
		var count := game.profile.count(key)
		while count > 0:  # in deals of at most ShopRules.MAX_AMOUNT
			var deal := mini(count, ShopRules.MAX_AMOUNT)
			if ShopRules.sell(game.profile, key, game.content, deal) != "":
				break
			sold += deal
			coins += price * deal
			count -= deal
	ticked.clear()
	game._trade_done("" if sold > 0 else "nothing", "Sold %d items for %d coins" % [sold, coins])
	game.menu_focus = "sell:"
	game.open_shop(npc)
