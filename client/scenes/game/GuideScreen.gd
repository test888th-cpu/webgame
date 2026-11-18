class_name GuideScreen
extends RefCounted
## The Guide (N): a farming guide in four tabs, Items, Monsters, Bosses and
## Maps, each a searchable, filterable, sortable list on the left and the
## chosen entry on the right (GuidePages). Every name on a page is a link to
## its own page (item -> who drops it -> where they fight -> what else drops
## there), with Back. Everything shown comes from the game's own data through
## LootIndex, the same rules that pay the drops, so the guide can never
## disagree with the game; nothing here is typed in by hand.
## Kept on its root (meta "guide") and refreshed in place, like the shop.

const TABS := ["items", "monsters", "bosses", "maps"]
const TAB_NAMES := {"items": "Items", "monsters": "Monsters", "bosses": "Bosses", "maps": "Maps"}
const LIST_WIDTH := 186.0
## Each tab's filter: [label, value] (value "" for all).
const SORTS := {
	"items": [["Grade", "grade"], ["Level", "level"], ["Name", "name"]],
	"monsters": [["Level", "level"], ["Name", "name"]],
	"bosses": [["Level", "level"], ["Name", "name"]],
	"maps": [["Level", "level"], ["Name", "name"]],
}

var game: Game
var content: ContentDB
## Per tab: {"search": LineEdit, "filter": OptionButton, "sort": OptionButton,
## "list": ItemList, "ids": Array, "detail": VBoxContainer, "chosen": id}.
var _tabs := {}
var _tab_box: TabContainer
## Pages opened before this one: [[tab, id], ...] (Back).
var _history: Array = []


func _init(p_game: Game) -> void:
	game = p_game
	content = p_game.content


static func build(p_game: Game) -> Control:
	var guide := GuideScreen.new(p_game)
	var root := guide._build()
	root.set_meta("guide", guide)
	return root


## The guide behind an open window, or null.
static func of(menu: Control) -> GuideScreen:
	var page := menu.find_child("Guide", true, false) if menu else null
	if page == null or not page.has_meta("guide"):
		return null
	return page.get_meta("guide")


func _build() -> Control:
	var page := VBoxContainer.new()
	page.name = "Guide"
	_tab_box = TabContainer.new()
	_tab_box.name = "Tabs"
	_tab_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_tab_box)
	for tab: String in TABS:
		_tab_box.add_child(_tab(tab))
	_tab_box.tab_changed.connect(func(_i: int) -> void: Sfx.play("ui_move", -6.0))
	for tab: String in TABS:
		refresh(tab)
	UiKit.focus_first(_tabs["items"]["search"])
	return page


func _tab(tab: String) -> Control:
	var row := HBoxContainer.new()
	row.name = TAB_NAMES[tab]
	row.add_theme_constant_override("separation", UiTheme.GAP + 2)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = LIST_WIDTH
	left.add_theme_constant_override("separation", UiTheme.GAP)
	row.add_child(left)
	var search := LineEdit.new()
	search.name = "Search"
	search.placeholder_text = "Search names and maps"
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	search.text_changed.connect(func(_t: String) -> void: refresh(tab))
	left.add_child(search)
	var pickers := HBoxContainer.new()
	pickers.add_theme_constant_override("separation", UiTheme.GAP)
	left.add_child(pickers)
	var filter := _picker("Filter", GuidePages.filters(content, tab), tab)
	filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pickers.add_child(filter)
	var sort := _picker("Sort", SORTS[tab], tab)
	pickers.add_child(sort)
	var list := ItemList.new()
	list.name = "List"
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(16, 16)
	list.item_selected.connect(func(i: int) -> void: _choose(tab, i, true))
	left.add_child(list)
	var scroll := ScrollContainer.new()
	scroll.name = "Detail"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 2)
	scroll.add_child(detail)
	_tabs[tab] = {
		"search": search,
		"filter": filter,
		"sort": sort,
		"list": list,
		"ids": [],
		"detail": detail,
		"chosen": "",
	}
	return row


func _picker(name: String, choices: Array, tab: String) -> OptionButton:
	var picker := OptionButton.new()
	picker.name = name
	picker.focus_mode = Control.FOCUS_NONE
	picker.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	for choice: Array in choices:
		picker.add_item(str(choice[0]))
		picker.set_item_metadata(picker.item_count - 1, str(choice[1]))
	picker.item_selected.connect(func(_i: int) -> void: refresh(tab))
	return picker


## The tab on show.
func current() -> String:
	return TABS[_tab_box.current_tab]


## The ids listed on `tab` now (search, filter and sort applied).
func listed(tab: String) -> Array:
	return _tabs[tab]["ids"]


## Lists `tab` again with its search, filter and sort, keeping the chosen
## entry when it is still listed.
func refresh(tab: String) -> void:
	var parts: Dictionary = _tabs[tab]
	var filter: OptionButton = parts["filter"]
	var sort: OptionButton = parts["sort"]
	var ids := GuidePages.entries(
		content,
		tab,
		(parts["search"] as LineEdit).text,
		str(filter.get_item_metadata(filter.selected)) if filter.item_count else "",
		str(sort.get_item_metadata(sort.selected))
	)
	parts["ids"] = ids
	var list: ItemList = parts["list"]
	list.clear()
	for id: String in ids:
		var row: Array = GuidePages.row(content, tab, id)
		list.add_item(str(row[0]), row[1])
		list.set_item_custom_fg_color(list.item_count - 1, row[2])
	var at := ids.find(parts["chosen"])
	if at < 0 and not ids.is_empty():
		at = 0
	if at >= 0:
		list.select(at)
		_choose(tab, at, false)
	else:
		_show(tab, "")


func _choose(tab: String, index: int, remember: bool) -> void:
	var ids: Array = _tabs[tab]["ids"]
	if index < 0 or index >= ids.size():
		return
	if remember and _tabs[tab]["chosen"] != "" and _tabs[tab]["chosen"] != ids[index]:
		_history.append([tab, _tabs[tab]["chosen"]])
	_show(tab, str(ids[index]))


## Opens entry `id` on `tab` ("items", "monsters", "bosses", "maps"): the
## links on every page call this. The page left is remembered for Back.
func open(tab: String, id: String) -> void:
	if _tabs[current()]["chosen"] != "":
		_history.append([current(), _tabs[current()]["chosen"]])
	_go(tab, id)


## Back to the page opened before this one.
func back() -> void:
	if _history.is_empty():
		return
	var page: Array = _history.pop_back()
	_go(str(page[0]), str(page[1]))


func _go(tab: String, id: String) -> void:
	_tab_box.current_tab = TABS.find(tab)
	var parts: Dictionary = _tabs[tab]
	if id not in parts["ids"]:
		# Not under the current search or filter: show everything.
		(parts["search"] as LineEdit).text = ""
		(parts["filter"] as OptionButton).select(0)
	parts["chosen"] = id
	refresh(tab)
	Sfx.play("ui_select", -6.0)


## The page shown on `tab` ("" for none).
func shown(tab: String) -> String:
	return str(_tabs[tab]["chosen"])


func _show(tab: String, id: String) -> void:
	_tabs[tab]["chosen"] = id
	var detail: VBoxContainer = _tabs[tab]["detail"]
	for child in detail.get_children():
		detail.remove_child(child)
		child.queue_free()
	if id == "":
		detail.add_child(UiKit.label("Nothing matches.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM))
		return
	if not _history.is_empty():
		var back_button := UiKit.button("< Back", back)
		back_button.name = "Back"
		back_button.focus_mode = Control.FOCUS_NONE
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_button.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
		detail.add_child(back_button)
	GuidePages.page(self, tab, id, detail)
