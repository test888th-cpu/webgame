class_name ShopScreen
extends RefCounted
## The vendor's screen, a cart in three columns on each of the Buy and Sell
## tabs (Q/E):
##   left    the wares, or what the bag holds that the shop will take: a click
##           (or Enter) puts one in the cart, Shift+click or a right click as
##           many as one deal allows (selling: the whole stack);
##   middle  the chosen item's card, so gear can be compared before it is
##           bought;
##   right   the cart (TradeCart): each line with -, + and x, the total, the
##           coins left after, and Buy/Sell and Clear. The cart is settled in
##           one checkout, all or nothing; rare gear or an upgraded item asks
##           "Sure?" once before it is sold. Sell's "Add all" fills the cart
##           with the bag except such items, which go in one by one.
## Left/Right change how many of the chosen item are in the cart, X (or the
## heavy-attack button) settles it. Prices, limits and the deals themselves
## come from TradeCart and ShopRules; this only shows them and passes the
## player's choices on. The screen is kept on its root (meta "shop") and
## refreshes in place, so focus and the list's place survive every click.
## `game.menu_focus` "buy:<item>" or "sell:<item>" opens on that tab and item.

const SIZE := Vector2(628, 336)
const LIST_WIDTH := 172.0
const CART_WIDTH := 176.0
const TABS := [TradeCart.BUY, TradeCart.SELL]
const PROBLEMS := {
	"empty": "Nothing in the cart yet.",
	"not_enough_money": "Not enough coins.",
	"closed": "The shop is closed.",
	"not_sold": "The shop no longer sells something in the cart.",
	"not_owned": "Something in the cart is no longer in your bag.",
	"not_for_sale": "The shop will not take something in the cart.",
}

var game: Game
var npc: Dictionary
## {mode: TradeCart}
var carts := {}
## Per mode: {"ids", "list", "detail", "lines", "total", "after", "checkout",
## "chosen"}.
var _pages := {}
var _coins: Label
## The Sell button has asked "Sure?" once.
var _sure := false


func _init(p_game: Game, p_npc: Dictionary) -> void:
	game = p_game
	npc = p_npc
	for mode: String in TABS:
		carts[mode] = TradeCart.new(mode, str(npc["shop"]))


static func build(p_game: Game, p_npc: Dictionary) -> Control:
	var screen := ShopScreen.new(p_game, p_npc)
	var root := screen._build()
	# The screen's state lives as long as its window.
	root.set_meta("shop", screen)
	return root


## The screen behind an open shop window, or null.
static func of(menu: Control) -> ShopScreen:
	if menu == null or not menu.has_meta("shop"):
		return null
	return menu.get_meta("shop")


## What the shop would buy from the bag, in bag order.
static func sellable(content: ContentDB, profile: PlayerProfile) -> Array[String]:
	var ids: Array[String] = []
	for item_id in CharacterTabs.bag_order(content, profile):
		if ShopRules.sell_price(content, item_id) > 0:
			ids.append(item_id)
	return ids


func _build() -> Control:
	var content := game.content
	var data: Dictionary = content.shops[npc["shop"]]
	var parts := UiKit.screen(content, str(data["name"]), "coin", "", SIZE, game.close_menu)
	var body: VBoxContainer = parts["body"]
	var said := '%s:  "%s"' % [npc["name"], npc.get("line", "")]
	body.add_child(UiKit.label(said, UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, SIZE.x - 24))
	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	var focus := game.menu_focus.split(":")
	for mode: String in TABS:
		tabs.add_child(_page(mode, focus[1] if focus.size() > 1 and focus[0] == mode else ""))
	tabs.current_tab = maxi(0, TABS.find(focus[0]))
	tabs.tab_changed.connect(
		func(index: int) -> void:
			Sfx.play("ui_move", -6.0)
			_sure = false
			refresh()
			UiKit.focus_first(tabs.get_child(index))
	)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", UiTheme.GAP)
	footer.add_child(UiKit.key_hint("Click / Enter", "Add"))
	footer.add_child(UiKit.key_hint("< >", "Amount"))
	footer.add_child(UiKit.key_hint("X", "Checkout"))
	footer.add_child(UiKit.key_hint("Q / E", "Buy / Sell"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(gap)
	footer.add_child(UiKit.icon_rect(content, "coin"))
	_coins = UiKit.label("", UiTheme.SIZE_H2, UiTheme.GOLD)
	_coins.name = "Coins"
	footer.add_child(_coins)
	body.add_child(footer)
	refresh()
	return parts["root"]


## One tab: the list, the item card and the cart.
func _page(mode: String, chosen: String) -> Control:
	var page := HBoxContainer.new()
	page.name = "Buy" if mode == TradeCart.BUY else "Sell"
	page.add_theme_constant_override("separation", UiTheme.GAP + 2)
	var parts := {"chosen": chosen}
	_pages[mode] = parts
	# Left: what can go in the cart.
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = LIST_WIDTH
	left.add_theme_constant_override("separation", UiTheme.GAP)
	page.add_child(left)
	var heading := "WARES" if mode == TradeCart.BUY else "YOUR BAG"
	left.add_child(UiKit.label(heading, UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM))
	var list := ItemList.new()
	list.name = "List"
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(16, 16)
	list.allow_reselect = true
	list.allow_rmb_select = true
	left.add_child(list)
	parts["list"] = list
	var empty := UiKit.label(
		"Nothing in your bag the trader wants.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, LIST_WIDTH
	)
	empty.name = "Empty"
	left.add_child(empty)
	parts["empty"] = empty
	if mode == TradeCart.SELL:
		var all := _small_button("Add all", _add_all)
		all.name = "AddAll"
		all.tooltip_text = "Everything the shop takes, except rare gear and upgraded items."
		left.add_child(all)
	list.item_selected.connect(
		func(index: int) -> void:
			Sfx.play("ui_move", -6.0)
			_choose(mode, index)
	)
	list.item_clicked.connect(
		func(index: int, _at: Vector2, button: int) -> void:
			_choose(mode, index)
			var many := button == MOUSE_BUTTON_RIGHT or Input.is_key_pressed(KEY_SHIFT)
			add(mode, _chosen(mode), ShopRules.MAX_AMOUNT if many else 1)
	)
	list.gui_input.connect(func(event: InputEvent) -> void: _list_key(mode, list, event))
	# Middle: the chosen item's card.
	var scroll := ScrollContainer.new()
	scroll.name = "Detail"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", UiTheme.GAP)
	scroll.add_child(detail)
	parts["detail"] = detail
	page.add_child(_cart_panel(mode, parts))
	return page


## Right: the cart's lines, the total, the coins after, Buy/Sell and Clear.
func _cart_panel(mode: String, parts: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Cart"
	panel.custom_minimum_size.x = CART_WIDTH
	var style := UiTheme.panel_style()
	style.bg_color = UiTheme.PANEL_LIGHT
	style.shadow_size = 0
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UiTheme.GAP)
	panel.add_child(column)
	var heading := UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	heading.name = "Heading"
	column.add_child(heading)
	parts["heading"] = heading
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var lines := VBoxContainer.new()
	lines.name = "Lines"
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 1)
	scroll.add_child(lines)
	parts["lines"] = lines
	column.add_child(HSeparator.new())
	var sum := HBoxContainer.new()
	sum.add_theme_constant_override("separation", UiTheme.GAP)
	column.add_child(sum)
	var what := UiKit.label("Total", UiTheme.SIZE_BODY, UiTheme.TEXT_DIM)
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sum.add_child(what)
	sum.add_child(UiKit.icon_rect(game.content, "coin"))
	var total := UiKit.label("0", UiTheme.SIZE_H2, UiTheme.GOLD)
	total.name = "Total"
	sum.add_child(total)
	parts["total"] = total
	var after := UiKit.label("", UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM)
	after.name = "After"
	after.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(after)
	parts["after"] = after
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", UiTheme.GAP)
	column.add_child(buttons)
	var checkout_button := UiKit.button("", checkout.bind(mode))
	checkout_button.name = "Checkout"
	checkout_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(checkout_button)
	parts["checkout"] = checkout_button
	var clear := _small_button("Clear", clear_cart.bind(mode))
	clear.name = "Clear"
	buttons.add_child(clear)
	return panel


func cart(mode: String) -> TradeCart:
	return carts[mode]


## The tab on show: "buy" or "sell".
func current_mode() -> String:
	var tabs: TabContainer = _pages[TradeCart.BUY]["list"].get_parent().get_parent().get_parent()
	return TABS[tabs.current_tab]


## Puts up to `count` of `item_id` in the `mode` cart.
func add(mode: String, item_id: String, count := 1) -> void:
	if item_id == "":
		return
	var added: int = cart(mode).add(game.profile, game.content, item_id, count)
	if added > 0:
		Sfx.play("ui_select", -6.0)
	else:
		Sfx.play("denied", -6.0)
		game.hud_toast(_full_text(mode, item_id))
	_sure = false
	refresh()


## Takes up to `count` of `item_id` back out of the `mode` cart.
func take(mode: String, item_id: String, count := 1) -> void:
	if cart(mode).take(item_id, count) > 0:
		Sfx.play("ui_move", -6.0)
	_sure = false
	refresh()


func clear_cart(mode: String) -> void:
	cart(mode).clear()
	_sure = false
	refresh()


## Settles the `mode` cart (TradeCart.checkout), saying what it came to.
func checkout(mode: String) -> void:
	var basket := cart(mode)
	basket.prune(game.profile, game.content)
	var why := basket.problem(game.profile, game.content)
	if why == "" and basket.precious(game.profile, game.content) and not _sure:
		# Rare gear or upgraded items in the cart: ask once more.
		_sure = true
		Sfx.play("denied", -6.0)
		refresh()
		return
	_sure = false
	var result := basket.checkout(game.profile, game.content)
	if result["error"]:
		Sfx.play("denied", -4.0)
		game.hud_toast(str(PROBLEMS.get(result["error"], "That cannot be done.")))
		refresh()
		return
	var verb := "Bought" if mode == TradeCart.BUY else "Sold"
	var said := (
		"%s %d item%s for %d coins"
		% [verb, result["items"], "" if result["items"] == 1 else "s", result["coins"]]
	)
	game._trade_done("", said)
	refresh()


## Sell: everything the shop takes, except rare gear and upgraded items.
func _add_all() -> void:
	var basket := cart(TradeCart.SELL)
	var added := 0
	for item_id in sellable(game.content, game.profile):
		if not TradeCart.is_precious(game.profile, game.content, item_id):
			added += basket.add(game.profile, game.content, item_id, ShopRules.MAX_AMOUNT * 99)
	Sfx.play("ui_select" if added > 0 else "denied", -6.0)
	_sure = false
	refresh()


func _full_text(mode: String, item_id: String) -> String:
	var name := str(game.content.item(item_id).get("name", item_id))
	if not cart(mode).lines.has(item_id) and cart(mode).lines.size() >= TradeCart.MAX_LINES:
		return "The cart holds %d different items." % TradeCart.MAX_LINES
	if mode == TradeCart.SELL:
		return "All your %s are in the cart." % name
	if ShopRules.max_amount(game.content, item_id) == 1:
		return "Gear is bought one at a time."
	return "At most %d %s in one go." % [ShopRules.MAX_AMOUNT, name]


## Keys on the list: Enter adds one, Left/Right one less or one more of the
## chosen item, X settles the cart.
func _list_key(mode: String, list: ItemList, event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		add(mode, _chosen(mode))
	elif event.is_action_pressed("ui_right"):
		add(mode, _chosen(mode))
	elif event.is_action_pressed("ui_left"):
		take(mode, _chosen(mode))
	elif event.is_action_pressed("attack_heavy"):
		checkout(mode)
	else:
		return
	list.accept_event()


func _chosen(mode: String) -> String:
	return str(_pages[mode]["chosen"])


func _choose(mode: String, index: int) -> void:
	var ids: Array = _pages[mode]["ids"]
	if index < 0 or index >= ids.size():
		return
	if _pages[mode]["chosen"] != ids[index]:
		_pages[mode]["chosen"] = ids[index]
		_show_detail(mode)


## Shows both tabs as the bag, the coins and the carts are now.
func refresh() -> void:
	for mode: String in TABS:
		cart(mode).prune(game.profile, game.content)
		_refresh_list(mode)
		_show_detail(mode)
		_refresh_cart(mode)
	_coins.text = str(game.profile.money)


func _ids(mode: String) -> Array:
	if mode == TradeCart.BUY:
		return ShopRules.wares(game.profile, game.content, str(npc["shop"]))
	return sellable(game.content, game.profile)


## The list: name, upgrade, how many are left to add (selling) or are in the
## cart (buying), and the price of one.
func _refresh_list(mode: String) -> void:
	var content := game.content
	var profile := game.profile
	var parts: Dictionary = _pages[mode]
	var list: ItemList = parts["list"]
	var ids := _ids(mode)
	parts["ids"] = ids
	var basket := cart(mode)
	var scroll := list.get_v_scroll_bar().value
	list.clear()
	var selected := 0
	for i in ids.size():
		var key: String = ids[i]
		var item := content.item(key)
		var plus := EnhanceRules.item_level(profile, key)
		var name := "%s +%d" % [item["name"], plus] if plus else str(item["name"])
		var price := TradeCart.unit_price(content, mode, key)
		var text := "%s   %d" % [name, price]
		if mode == TradeCart.SELL:
			text = "%s  x%d   %d" % [name, profile.count(key) - basket.amount(key), price]
		elif basket.amount(key) > 0:
			text = "%s   %d   · %d in cart" % [name, price, basket.amount(key)]
		list.add_item(text, UiKit.icon(content, item["icon"]))
		list.set_item_tooltip(i, "%s\nClick: add one.  Shift or right click: add more." % name)
		var dim := (
			(mode == TradeCart.BUY and profile.money < price)
			or (mode == TradeCart.SELL and profile.count(key) <= basket.amount(key))
		)
		list.set_item_custom_fg_color(i, UiTheme.TEXT_FAINT if dim else ItemText.rarity_color(item))
		if key == _chosen(mode):
			selected = i
	var next := ShopRules.next_stock(profile, content, str(npc["shop"]))
	if mode == TradeCart.BUY and next:
		# The next trader's stock, as the list's last, unselectable row.
		var row := list.add_item(next, null, false)
		list.set_item_custom_fg_color(row, UiTheme.TEAL)
		list.set_item_tooltip(row, next)
	list.visible = not ids.is_empty()
	parts["empty"].visible = ids.is_empty()
	if ids.is_empty():
		parts["chosen"] = ""
		return
	parts["chosen"] = ids[selected]
	list.select(selected)
	list.get_v_scroll_bar().value = scroll
	list.ensure_current_is_visible()


## The chosen item's card and how many the hero owns.
func _show_detail(mode: String) -> void:
	var detail: VBoxContainer = _pages[mode]["detail"]
	for child in detail.get_children():
		detail.remove_child(child)
		child.queue_free()
	var key := _chosen(mode)
	if key == "":
		return
	var profile := game.profile
	detail.add_child(ItemCard.details(game.content, profile, key, "", mode == TradeCart.BUY))
	var owned := profile.owned(ContentDB.base_id(key))
	detail.add_child(UiKit.row("You own", UiKit.label(str(owned))))
	if mode == TradeCart.SELL and EnhanceRules.item_level(profile, key) > 0:
		detail.add_child(
			UiKit.label("Its upgrades are lost when sold.", UiTheme.SIZE_SMALL, UiTheme.DANGER)
		)


## The cart's lines, total, the coins after and the checkout button.
func _refresh_cart(mode: String) -> void:
	var content := game.content
	var profile := game.profile
	var parts: Dictionary = _pages[mode]
	var basket := cart(mode)
	var lines: VBoxContainer = parts["lines"]
	for child in lines.get_children():
		lines.remove_child(child)
		child.queue_free()
	var verb := "BUY" if mode == TradeCart.BUY else "SELL"
	parts["heading"].text = "TO %s  (%d)" % [verb, basket.count_items()]
	if basket.is_empty():
		var hint := "Click an item on the left to add it."
		lines.add_child(UiKit.label(hint, UiTheme.SIZE_SMALL, UiTheme.TEXT_FAINT, CART_WIDTH - 12))
	for key: String in basket.lines:
		lines.add_child(_line(mode, key))
	var total := basket.total(content)
	parts["total"].text = str(total)
	var left := profile.money - total if mode == TradeCart.BUY else profile.money + total
	var after: Label = parts["after"]
	after.text = ("Coins after: %d" % left) if left >= 0 else ("%d coins short" % -left)
	after.add_theme_color_override("font_color", UiTheme.DANGER if left < 0 else UiTheme.TEXT_DIM)
	var button: Button = parts["checkout"]
	button.disabled = basket.problem(profile, content) != ""
	button.text = "Buy" if mode == TradeCart.BUY else "Sell"
	button.remove_theme_color_override("font_color")
	if _sure and mode == TradeCart.SELL:
		button.text = "Sure?"
		button.add_theme_color_override("font_color", UiTheme.DANGER)


## One cart line: icon, name, -, how many, +, x.
func _line(mode: String, key: String) -> Control:
	var content := game.content
	var item := content.item(key)
	var row := HBoxContainer.new()
	row.name = "Line_" + key.validate_node_name()
	row.add_theme_constant_override("separation", 2)
	var art := UiKit.icon_rect(content, str(item["icon"]))
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(art)
	var plus := EnhanceRules.item_level(game.profile, key)
	var name := UiKit.label(
		str(item["name"]) + (" +%d" % plus if plus else ""),
		UiTheme.SIZE_SMALL,
		ItemText.rarity_color(item)
	)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	name.mouse_filter = Control.MOUSE_FILTER_PASS
	name.tooltip_text = (
		"%s  x%d  =  %d coins"
		% [
			item["name"],
			cart(mode).amount(key),
			TradeCart.unit_price(content, mode, key) * cart(mode).amount(key),
		]
	)
	row.add_child(name)
	row.add_child(_small_button("-", take.bind(mode, key, 1)))
	var count := UiKit.label(str(cart(mode).amount(key)), UiTheme.SIZE_SMALL, UiTheme.TEXT)
	count.name = "Count"
	count.custom_minimum_size.x = 18
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(count)
	row.add_child(_small_button("+", add.bind(mode, key, 1)))
	var drop := _small_button("×", take.bind(mode, key, ShopRules.MAX_AMOUNT * 99))
	drop.name = "Drop"
	drop.tooltip_text = "Take out of the cart"
	row.add_child(drop)
	return row


static func _small_button(text: String, on_press: Callable) -> Button:
	var button := UiKit.button(text, on_press)
	button.name = "Step" + text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(14, 14)
	button.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	return button
