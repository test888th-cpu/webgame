class_name StreetMenus
extends RefCounted
## The street's game screens, in the original game's windows (UiKit.screen: icon,
## name, key and close button; GameMenus' sizes) and its Esc menu. Each screen has
## the same row of the five screens on top, so any one is a click (or Q / E) from
## another. Screens only show the engine's state and call the street's actions
## (Street.menu_action), which change it through the engine and rebuild the screen.

## Screen id -> [title, icon, toggle key, window size].
const SCREENS := {
	"character": ["Character", "menu_character", "C", Vector2(560, 310)],
	"equipment": ["Equipment", "slot_body", "", Vector2(560, 318)],
	"bag": ["Bag", "menu_bag", "B", Vector2(560, 318)],
	"skills": ["Skills", "menu_skills", "V", Vector2(590, 330)],
	"settings": ["Settings", "menu_settings", "", Vector2(520, 300)],
}
const ORDER: Array[String] = ["character", "equipment", "bag", "skills", "settings"]
## Settings > Controls on the street (the reference rules' actions only).
const CONTROLS := [
	["Move", "A D / Arrows", "Left stick"],
	["Target and attack", "J / Z", "X / Square"],
	["Abilities (hotbar 2-7)", "2 - 7", "RT + face button"],
	["Auto battle on / off", "T", "Back / Select"],
	["Loot / resurrect", "E / U", "B / Circle"],
	["Character", "C", "Start > Character"],
	["Bag", "B", "Start > Bag"],
	["Skills", "V", "Start > Skills"],
	["Switch screen", "Q / E", "LB / RB"],
	["Menu", "Esc / P", "Start"],
]
## The GameSession switches that do something on the street.
const TOGGLES := ["show_fps"]


static func screen(street: Node, name: String) -> Control:
	var spec: Array = SCREENS[name]
	var parts := UiKit.screen(street.content, spec[0], spec[1], spec[2], spec[3], street.close_menu)
	parts["root"].name = "Screen_" + name
	var body: VBoxContainer = parts["body"]
	body.add_child(_nav(street, name))
	var page: Control
	match name:
		"character":
			page = StreetCharacterPage.build(street)
		"equipment":
			page = StreetGearPage.equipment(street)
		"bag":
			page = StreetGearPage.bag(street)
		"skills":
			page = StreetSkillsPage.build(street)
		_:
			page = settings()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(page)
	return parts["root"]


## The original settings window's tabs (GameMenus.settings_tabs) with the street's
## switches and controls, and the third-party notices.
static func settings() -> Control:
	var notices := ScrollContainer.new()
	notices.name = "Notices"
	notices.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var text := UiKit.label(LegalNotices.text(), UiTheme.SIZE_CAPTION, UiTheme.TEXT_DIM, 470)
	text.name = "NoticeText"
	notices.add_child(text)
	return (
		GameMenus
		. settings_tabs(
			TOGGLES,
			CONTROLS,
			false,
			{"Notices": notices},
			"Progress saves on its own after each kill, every few seconds, and when you change area or gear."
		)
	)


## The row of screens on top of each window: the open one lit and inert.
static func _nav(street: Node, current: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Nav"
	row.add_theme_constant_override("separation", 2)
	for name: String in ORDER:
		var b := UiKit.button(SCREENS[name][0], street.open_screen.bind(name), name == current)
		b.name = "Nav_" + name
		b.icon = UiKit.icon(street.content, SCREENS[name][1])
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
		row.add_child(b)
	return row


## The Esc menu: back to the game, every screen, saving and leaving.
static func pause_menu(street: Node) -> Control:
	var parts := UiKit.window("Menu", Vector2(GameMenus.PAUSE_WIDTH, 210), "")
	parts["root"].name = "Screen_pause"
	var body: VBoxContainer = parts["body"]
	body.add_theme_constant_override("separation", 2)
	body.add_child(GameMenus._menu_item("Back to the game", "Esc", street.close_menu))
	for name: String in ORDER:
		var item := GameMenus._menu_item(
			SCREENS[name][0], SCREENS[name][2], street.open_screen.bind(name)
		)
		item.name = "Menu_" + name
		body.add_child(item)
	body.add_child(HSeparator.new())
	var save := GameMenus._menu_item("Save game", "", street.menu_action.bind("save", null))
	save.name = "SaveGame"
	body.add_child(save)
	var quit := GameMenus._menu_item("Save and quit to title", "", street.quit_to_title)
	quit.name = "QuitToTitle"
	body.add_child(quit)
	return parts["root"]
