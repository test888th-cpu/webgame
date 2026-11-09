class_name GameMenus
extends RefCounted
## Builds the in-game screens for Game.gd. Each screen does one job, in its
## own window with its icon, name, key and a close button:
##   Character  who the hero is and what they can do (CharacterTabs.status)
##   Bag        what is worn and carried (CharacterTabs.equipment)
##   Skills     what the hero can do, and which key does it (SkillsScreen)
##   Quests     the quest log
##   Map        where the hero is and where to go (MapTab)
##   Settings   game options, auto battle and the controls
## Esc opens the pause menu, which reaches every screen (the gamepad's way in)
## and holds the session actions: return home, save, quit. Also the shop, NPC
## conversations and the knock-out screen. Screens only show the profile and
## call back into Game's actions, which own every change; after an action
## Game simply rebuilds the screen. All styling comes from UiTheme/UiKit.

## Screen id -> [title, icon, toggle key, window size]. The id is also the
## menu name Game reports (the probe and tests read it).
const SCREENS := {
	"character": ["Character", "menu_character", "C", Vector2(560, 300)],
	"bag": ["Bag", "menu_bag", "B", Vector2(600, 318)],
	"skills": ["Skills", "menu_skills", "V", Vector2(580, 330)],
	"quests": ["Quests", "menu_quests", "O", Vector2(500, 300)],
	"map": ["Map", "menu_map", "M", Vector2(600, 318)],
	"settings": ["Settings", "menu_settings", "", Vector2(520, 300)],
}
const PAUSE_WIDTH := 190.0
## The pause menu's extra row for the ride to the city.
const LIST_WIDTH := 180.0
## The tallest a dialog's list (Win's rides, the notice board) grows before
## it scrolls, so the dialog always fits the 360 px screen.
const LIST_HEIGHT := 170.0
## Win's taxi: the group column's width and both panes' greatest height (the
## dialog's other rows take the rest of the 360 px canvas).
const GROUP_WIDTH := 128.0
const PICK_HEIGHT := 196.0
## Shown on Settings > Controls: action, keyboard, gamepad.
const CONTROLS := [
	["Move", "WASD / Arrows", "Left stick"],
	["Light attack (combo)", "J / Z", "X / Square"],
	["Heavy attack", "K / X", "Y / Triangle"],
	["Dodge", "Space / L", "A / Cross"],
	["Guard (hold); just before a hit: parry", "Shift / I", "LB / L1"],
	["Talk, shop", "E / U", "B / Circle"],
	["Eat (quick heal)", "H / Q", "RB / R1"],
	["Auto battle on / off (areas you have cleared)", "T", "Back / Select"],
	["Character", "C", "Start > Character"],
	["Bag", "B", "Start > Bag"],
	["Skills", "V", "Start > Skills"],
	["Quests", "O", "Start > Quests"],
	["Map", "M", "Right stick (press)"],
	["Pause menu", "Esc / P", "Start"],
]
const STATE_TAGS := {
	"active": ["In progress", UiTheme.TEAL],
	"complete": ["Ready to hand in", UiTheme.ACCENT],
	"turned_in": ["Done", UiTheme.GOOD],
}


## Screen `name` (a SCREENS id) in its own window.
static func screen(game: Game, name: String) -> Control:
	var spec: Array = SCREENS[name]
	var parts := UiKit.screen(game.content, spec[0], spec[1], spec[2], spec[3], game.close_menu)
	var page: Control
	match name:
		"character":
			page = CharacterTabs.status(game)
		"bag":
			page = CharacterTabs.equipment(game)
		"skills":
			page = SkillsScreen.build(game)
		"quests":
			page = _quests(game)
		"map":
			page = MapTab.build(game)
		_:
			page = _settings(game)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts["body"].add_child(page)
	return parts["root"]


## The game menu (Esc): back to the game, every screen, and the session
## actions. The street does not stop behind it, nor behind any screen.
static func pause_menu(game: Game) -> Control:
	var tutorial := not TutorialRules.is_done(game.profile, game.content)
	var tall := 232.0
	var parts := UiKit.window("Menu", Vector2(PAUSE_WIDTH, tall + (18.0 if tutorial else 0.0)), "")
	var body: VBoxContainer = parts["body"]
	body.add_theme_constant_override("separation", 2)
	body.add_child(_menu_item("Back to the game", "Esc", game.close_menu))
	for name: String in SCREENS:
		var spec: Array = SCREENS[name]
		body.add_child(_menu_item(spec[0], spec[2], game.open_screen.bind(name)))
	body.add_child(HSeparator.new())
	# The way back, from anywhere outside a fight: to the city (Iron City
	# Central) when the game has one, else to the start area (Game._recall).
	var content := game.content
	var recall: Button
	var problem := ""
	if content.city_area != "":
		var city := str(content.area(content.city_area).get("name", "the city"))
		recall = _menu_item("Return to %s" % city, "", game._go_to_city)
		problem = game.city_problem()
	else:
		var home := str(content.area(content.start_area).get("name", "home"))
		recall = _menu_item("Return to %s" % home, "", game._recall)
		problem = game.zone.recall_problem()
	recall.name = "Recall"
	recall.disabled = problem != ""
	recall.tooltip_text = problem
	body.add_child(recall)
	body.add_child(_menu_item("Save game", "", game._save_game))
	body.add_child(_menu_item("Save and quit to title", "", game._quit_to_title))
	if tutorial:
		body.add_child(_menu_item("Skip tutorial", "", game.skip_tutorial))
	return parts["root"]


## A compact pause-menu row: the action on the left, its key on the right.
static func _menu_item(text: String, key: String, on_press: Callable) -> Button:
	var button := UiKit.button(text, on_press)
	button.name = text.replace(" ", "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	button.custom_minimum_size = Vector2(PAUSE_WIDTH - 20, 15)
	if key:
		var cap := UiKit.label(key, UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
		cap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		cap.offset_left = -24
		cap.offset_right = -6
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.add_child(cap)
	return button


## Moves the open screen's tabs (Settings) by `step`, wrapping around.
static func cycle_tab(menu: Control, step: int) -> void:
	var tabs: TabContainer = menu.find_child("Tabs", true, false)
	if tabs:
		tabs.current_tab = posmod(tabs.current_tab + step, tabs.get_tab_count())


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
		# Evidence is a surprise on hand-in, not a reward to bargain for.
		if content.item(item_id).get("type") == "key":
			continue
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


## Settings: game options, auto battle and the controls, one tab each.
static func _settings(_game: Game) -> Control:
	var tabs := TabContainer.new()
	tabs.name = "Tabs"
	tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	var game_tab := VBoxContainer.new()
	game_tab.name = "Game"
	game_tab.add_theme_constant_override("separation", UiTheme.GAP)
	game_tab.add_child(_toggle("Screen shake on heavy hits", "screen_shake"))
	game_tab.add_child(_toggle("Show frame rate", "show_fps"))
	game_tab.add_child(_volume())
	game_tab.add_child(
		UiKit.label(
			"Progress also saves on its own when you change area, shop or hand in a quest.",
			UiTheme.SIZE_SMALL,
			UiTheme.TEXT_FAINT,
			440
		)
	)
	tabs.add_child(game_tab)
	tabs.add_child(_auto_options())
	tabs.add_child(_controls())
	for i in ["Game", "Auto battle", "Controls"].size():
		tabs.set_tab_title(i, ["Game", "Auto battle", "Controls"][i])
	tabs.tab_changed.connect(
		func(_index: int) -> void: UiKit.focus_first(tabs.get_current_tab_control())
	)
	return tabs


## Auto battle settings: when to eat, following the story, wearing better
## gear, the farm loop, food to keep stocked.
static func _auto_options() -> Control:
	var box := VBoxContainer.new()
	box.name = "AutoOptions"
	box.add_theme_constant_override("separation", UiTheme.GAP)
	box.add_child(
		_cycle("Eat when health is below", "auto_heal_at", AutoBattle.HEAL_CHOICES, "%d%%", 100.0)
	)
	box.add_child(_toggle("Story: take each quest and fight on to its boss", "auto_story"))
	box.add_child(_toggle("Wear better gear found", "auto_gear"))
	box.add_child(
		_toggle("Farm loop: when the area is clear, rest at home and ride back", "auto_loop")
	)
	box.add_child(_cycle("Food to keep stocked", "auto_food", AutoBattle.FOOD_CHOICES, "%d"))
	return box


## A row whose button steps through `choices` for setting `key`.
static func _cycle(
	text: String, key: String, choices: Array, format: String, scale := 1.0
) -> Control:
	var button := Button.new()
	button.name = key
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.x = 48
	var show := func() -> void:
		button.text = format % roundi(float(GameSession.settings.get(key, choices[0])) * scale)
	show.call()
	button.pressed.connect(
		func() -> void:
			var at := choices.find(GameSession.settings.get(key, choices[0]))
			GameSession.set_setting(key, choices[(at + 1) % choices.size()])
			show.call()
			Sfx.play("ui_move")
	)
	return UiKit.row(text, button)


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


## A conversation with a quest giver: their line, then what they offer.
## Talking to an NPC. Quest givers speak their quest's lines (quests.json
## "dialogue"): the offer, a nudge while it is under way, and `said` (what
## they just said on hand-in). The goal itself is always spelled out below
## the speech, so skipping the words never leaves a player lost.
static func conversation(game: Game, npc: Dictionary, said := "") -> Control:
	var content := game.content
	var profile := game.profile
	var parts := UiKit.dialog(str(npc["name"]), UiKit.portrait(content, str(npc.get("sprite", ""))))
	var body: VBoxContainer = parts["body"]
	var offers := 0
	var says := said if said else str(npc.get("line", ""))
	for quest_id in game.view.quests_of(npc):
		var state := QuestRules.status(profile, quest_id, content)
		var quest: Dictionary = content.quests[quest_id]
		var lines: Dictionary = quest.get("dialogue", {})
		if state == "available":
			offers += 1
			if not said:
				says = str(lines.get("offer", says))
			var heading := str(quest["name"]).to_upper()
			if quest.has("chapter"):
				heading = "%s  -  %s" % [str(quest["chapter"]).to_upper(), heading]
			body.add_child(UiKit.label(heading, UiTheme.SIZE_CAPTION, UiTheme.ACCENT))
			body.add_child(
				UiKit.label(
					"Goal: " + str(quest["description"]), UiTheme.SIZE_BODY, UiTheme.TEXT, 470
				)
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
			if not said:
				says = str(lines.get("active", 'Still on "%s"?' % quest["name"]))
			body.add_child(
				UiKit.label(
					"%s: %d of %d" % [quest["name"], profile.quests[quest_id]["progress"], count],
					UiTheme.SIZE_SMALL,
					UiTheme.TEAL
				)
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


## The motorbike taxi's stand, the way out to everything reached, for the
## driver's fare: pick a group on the left (the city, each district with an
## area reached before, the open farming grounds, the world bosses unlocked;
## AreaRules, WorldBossRules), then a place on the right. It opens on the
## hero's own district, its first ride focused, so a late-game list of forty
## rides never has to be scrolled through: any ride is a few presses away.
## Every group's rides are built at once and only the chosen one is shown.
static func travel(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var parts := UiKit.dialog(str(npc["name"]), UiKit.portrait(content, str(npc.get("sprite", ""))))
	var body: VBoxContainer = parts["body"]
	var fare := int(npc.get("fare", 0))
	var line := '"%s"' % str(npc.get("line", "Where to?"))
	body.add_child(UiKit.label(line, UiTheme.SIZE_BODY, UiTheme.TEXT_DIM, 470))
	body.add_child(UiKit.label("Fare: %d coins" % fare, UiTheme.SIZE_SMALL, UiTheme.GOLD))
	var groups := _ride_groups(game, npc, fare)
	if groups.is_empty():
		body.add_child(
			UiKit.label("Nowhere else you know yet.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM)
		)
	else:
		body.add_child(_ride_picker(groups, _first_group(game, groups)))
	body.add_child(_choice("Not now", game.close_menu))
	return parts["root"]


## A taxi's rides in groups, in the order shown: [{"name", "rides": [Button],
## "columns"}]. Each taxi keeps to its own routes ("routes" in areas.json):
## Win's ("story") the street's districts, two to a row; Uncle Thong's truck
## ("field") the farming grounds and the world bosses, one to a row.
static func _ride_groups(game: Game, npc: Dictionary, fare: int) -> Array[Dictionary]:
	var content := game.content
	var out: Array[Dictionary] = []
	if str(npc.get("routes", "story")) == "field":
		# Only from the hub (AreaRules.hub): never out of the story.
		var hub := AreaRules.rides_from_hub(content, game.zone.area_id)
		return _hub_rides(game, npc, fare) if hub else out
	var broke := game.profile.money < fare
	var city := content.city_area
	if city != "" and game.zone.area_id != city:
		var hub := content.area(city)
		var home := _choice("%s  (rest, farming, bosses)" % hub["name"], game._ride.bind(npc, city))
		home.name = "Ride_" + city
		home.disabled = broke
		out.append({"name": "City", "rides": [home], "columns": 1})
	var places := StreetMemory.destinations(game.profile, content, game.zone.area_id)
	for district in MapRules.districts(content):
		var rides: Array[Button] = []
		for area_id: String in district["areas"]:
			if area_id not in places:
				continue
			var area := content.area(area_id)
			var text := "%s  Lv %d" % [area["name"], int(area.get("level", 1))]
			var ride := _choice(text, game._ride.bind(npc, area_id))
			ride.name = "Ride_" + area_id
			ride.disabled = broke
			rides.append(ride)
		if not rides.is_empty():
			out.append({"name": str(district["name"]), "rides": rides, "columns": 2})
	return out


## The field truck's rides (from the hub only, AreaRules.hub): the open
## farming grounds and the world bosses.
static func _hub_rides(game: Game, npc: Dictionary, fare: int) -> Array[Dictionary]:
	var content := game.content
	var out: Array[Dictionary] = []
	var broke := game.profile.money < fare
	var grounds: Array[Button] = []
	for area_id in AreaRules.open_farms(game.profile, content):
		var ground := content.area(area_id)
		# A suggestion for the fights there; no level is needed to ride in.
		var text := "%s  (suggested Lv %d)" % [ground["name"], int(ground.get("level", 1))]
		var ride := _choice(text, game._ride.bind(npc, area_id))
		ride.name = "Ride_" + area_id
		ride.disabled = broke
		grounds.append(ride)
	if not grounds.is_empty():
		out.append({"name": "Farming", "rides": grounds, "columns": 1})
	var bosses: Array[Button] = []
	for boss: String in content.world_bosses:
		if WorldBossRules.unlocked(game.profile, content, boss):
			bosses.append(_world_boss_ride(game, npc, fare, boss))
	if not bosses.is_empty():
		out.append({"name": "World Bosses", "rides": bosses, "columns": 1})
	return out


## Which group the taxi opens on: the hero's own district, else (in the city,
## a farming ground or an arena) the furthest district with a ride.
static func _first_group(game: Game, groups: Array[Dictionary]) -> int:
	var here := str(MapRules.locate(game.content, game.zone.area_id).get("name", ""))
	var last := 0
	for i in groups.size():
		if groups[i]["name"] == here:
			return i
		if groups[i]["name"] not in ["City", "Farming", "World Bosses"]:
			last = i
	return last


## The two panes: group buttons (named "Heading_<group>", with how many rides
## each holds) and the chosen group's rides. Focusing or pressing a group
## shows its rides; pressing it also moves the focus onto its first ride.
static func _ride_picker(groups: Array[Dictionary], chosen: int) -> Control:
	var picker := HBoxContainer.new()
	picker.name = "Rides"
	picker.add_theme_constant_override("separation", UiTheme.PAD)
	var tabs := VBoxContainer.new()
	tabs.name = "Groups"
	tabs.custom_minimum_size.x = GROUP_WIDTH
	tabs.add_theme_constant_override("separation", 2)
	var panes := VBoxContainer.new()
	panes.name = "Places"
	panes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var buttons: Array[Button] = []
	var grids: Array[GridContainer] = []
	for group in groups:
		var rides: Array = group["rides"]
		var tab := UiKit.button("%s  %d" % [group["name"], rides.size()], func() -> void: pass)
		tab.name = "Heading_" + str(group["name"]).validate_node_name()
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
		tabs.add_child(tab)
		buttons.append(tab)
		var grid := GridContainer.new()
		grid.name = "Group_" + str(group["name"]).validate_node_name()
		grid.columns = int(group["columns"])
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		for ride: Button in rides:
			ride.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ride.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
			grid.add_child(ride)
		panes.add_child(grid)
		grids.append(grid)
	var show := func(index: int) -> void:
		for i in grids.size():
			grids[i].visible = i == index
			var color := UiTheme.ACCENT if i == index else UiTheme.TEXT
			buttons[i].add_theme_color_override("font_color", color)
	for i in buttons.size():
		buttons[i].focus_entered.connect(show.bind(i))
		buttons[i].pressed.connect(show.bind(i))
		buttons[i].pressed.connect(_focus_ride.bind(grids[i], buttons[i]))
	show.call(chosen)
	# The dialog opens on the chosen group's first ride it can take.
	var start: Control = buttons[chosen]
	for ride: Node in grids[chosen].get_children():
		if not (ride as Button).disabled:
			start = ride
			break
	start.set_meta("start_focus", true)
	picker.add_child(_scrolling(tabs, PICK_HEIGHT, "GroupScroll"))
	var places := _scrolling(panes, PICK_HEIGHT)
	places.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.add_child(places)
	return picker


## Focus `grid`'s first ride that can be taken, else stay on `tab`.
static func _focus_ride(grid: GridContainer, tab: Button) -> void:
	for ride: Node in grid.get_children():
		if not (ride as Button).disabled:
			(ride as Button).grab_focus()
			return
	tab.grab_focus()


## A heading inside a dialog's list.
static func _heading(text: String) -> Label:
	var heading := UiKit.label(text.to_upper(), UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
	heading.name = "Heading_" + text.validate_node_name()
	return heading


## `list` in a box at most `most` tall (LIST_HEIGHT unless said) that scrolls
## when the list is longer, keeping the focused row in view.
static func _scrolling(list: Control, most := LIST_HEIGHT, name := "Scroll") -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.add_child(list)
	# A first guess from the rows, then the list's real height once it is laid
	# out (minimum sizes are only known on screen): never cut, never too tall.
	var tall := 0.0
	for row: Node in list.get_children():
		tall += 22.0 if row is Button else (28.0 if row is VBoxContainer else 14.0)
	scroll.custom_minimum_size.y = minf(tall, most)
	# Signals of the box and list themselves, so they go when the dialog does.
	var fit := func() -> void:
		scroll.custom_minimum_size.y = minf(list.get_combined_minimum_size().y, most)
	scroll.ready.connect(fit)
	list.minimum_size_changed.connect(fit)
	return scroll


## The city's notice board: the hero's current job and where to report (the
## map's goal), the world bosses as far as the story has revealed them (named
## and timed once unlocked, like the map), and what is planned but not open:
## farming grounds and other services, marked as such. It only informs: the
## rides are Win's, at the taxi rank.
static func notice_board(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var profile := game.profile
	var parts := UiKit.dialog(str(npc["name"]), null)
	var body: VBoxContainer = parts["body"]
	var line := '"%s"' % str(npc.get("line", ""))
	body.add_child(UiKit.label(line, UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM, 520))
	var list := VBoxContainer.new()
	list.name = "Notices"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	var goal := MapRules.goal(profile, content)
	list.add_child(_heading("Current Job"))
	var job := "Nothing left to do. Farm, gear up, take on the World Bosses."
	if not goal.is_empty():
		var at := str(content.area(str(goal["area"])).get("name", ""))
		job = "%s  ·  %s" % [goal["text"], at]
	var job_label := UiKit.label("    " + job, UiTheme.SIZE_SMALL, UiTheme.TEXT)
	job_label.name = "Job"
	list.add_child(job_label)
	list.add_child(_heading("World Bosses"))
	for boss: String in content.world_bosses:
		var entry := VBoxContainer.new()
		entry.name = "Boss_" + boss
		entry.add_theme_constant_override("separation", 0)
		list.add_child(entry)
		# Like the map: a world boss is named only once the story unlocks it.
		if not WorldBossRules.unlocked(profile, content, boss):
			entry.add_child(UiKit.label("???", UiTheme.SIZE_SMALL, UiTheme.TEXT_FAINT))
			entry.add_child(
				UiKit.label(
					"    Rises later in the story.", UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT
				)
			)
			continue
		var data := WorldBossRules.spec(content, boss)
		var name := str(content.enemy(str(data["enemy"]))["name"])
		var arena := str(content.area(str(data["area"])).get("name", ""))
		var players := int(data.get("players", 1))
		var who := "%d players" % players if players > 1 else "solo"
		var level := WorldBossRules.level(content, boss)
		var text := "%s  ·  %s  ·  Lv %d, %s" % [name, arena, level, who]
		var wait := WorldBossRules.wait_text(content, boss, game._now())
		var state := "Rises again in %s." % wait
		var color := UiTheme.TEXT_DIM
		var round := WorldBossRules.window(content, boss, game._now())
		var tries := WorldBossRules.attempts_left(profile, content, boss, int(round["round"]))
		if round["open"]:
			state = "OUT NOW, for %s. %d of %d tries left." % [wait, tries, int(data["attempts"])]
			color = UiTheme.GOOD if tries > 0 else UiTheme.TEXT_DIM
		entry.add_child(UiKit.label(text, UiTheme.SIZE_SMALL, UiTheme.TEXT))
		entry.add_child(UiKit.label("    " + state, UiTheme.SIZE_CAPTION, color))
	# Farming today: any cleared street, re-armed by resting (StreetMemory).
	list.add_child(_heading("Farming"))
	var tip := UiKit.label(
		"    Farm any street you have cleared: rest here, ride out, fight.",
		UiTheme.SIZE_CAPTION,
		UiTheme.TEXT_DIM
	)
	tip.name = "FarmingTip"
	list.add_child(tip)
	var planned: Array = npc.get("farming_planned", [])
	if not planned.is_empty():
		list.add_child(_heading("Farming Grounds (planned, not open yet)"))
		for i in planned.size():
			var plan: Dictionary = planned[i]
			var levels: Array = plan["levels"]
			var text := (
				"%s, Lv %d-%d: not built yet" % [plan["district"], int(levels[0]), int(levels[1])]
			)
			var notice := UiKit.label("    " + text, UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT)
			notice.name = "Planned_%d" % i
			list.add_child(notice)
	var services: Array = npc.get("planned_services", [])
	if not services.is_empty():
		list.add_child(_heading("Also Planned"))
		for i in services.size():
			var notice := UiKit.label(
				"    %s: not open yet" % services[i], UiTheme.SIZE_CAPTION, UiTheme.TEXT_FAINT
			)
			notice.name = "Service_%d" % i
			list.add_child(notice)
	body.add_child(_scrolling(list))
	body.add_child(_choice("Close", game.close_menu))
	return parts["root"]


## Win's ride to world boss `boss`: open (with time left) or when it opens
## next, and what it is (its fixed level, the players it is built for).
static func _world_boss_ride(game: Game, npc: Dictionary, fare: int, boss: String) -> Control:
	var content := game.content
	var data := WorldBossRules.spec(content, boss)
	var name := str(content.enemy(str(data["enemy"]))["name"])
	var round := WorldBossRules.window(content, boss, game._now())
	var wait := WorldBossRules.wait_text(content, boss, game._now())
	var who := "Lv %d, " % WorldBossRules.level(content, boss)
	var players := int(data.get("players", 1))
	who += "%d players" % players if players > 1 else "solo"
	if round["open"]:
		var tries := WorldBossRules.attempts_left(game.profile, content, boss, int(round["round"]))
		who += ", %d tries left" % tries
	var text := (
		"WORLD BOSS %s  (%s; closes in %s)" % [name, who, wait]
		if round["open"]
		else "World Boss %s  (%s; back in %s)" % [name, who, wait]
	)
	var ride := _choice(text, game._ride_world_boss.bind(npc, boss))
	ride.name = "Ride_" + boss
	var able := WorldBossRules.problem(game.profile, content, boss, game._now()) == ""
	ride.disabled = not able or game.profile.money < fare
	return ride


## After a world boss attempt: what it did, the round so far against the
## hero's own part, the next tier, and what was won (the kill included).
static func world_boss_result(game: Game, run: WorldBossRun, paid: Dictionary) -> Control:
	var content := game.content
	var data := WorldBossRules.spec(content, run.boss)
	var boss_name := str(content.enemy(str(data["enemy"]))["name"])
	var titles := {"slain": "%s FALLS!" % boss_name.to_upper(), "time": "IT GOT AWAY"}
	titles["down"] = "KNOCKED DOWN"
	var portrait := UiKit.portrait(
		content, str(content.enemy(str(data["enemy"])).get("sprite", ""))
	)
	var parts := UiKit.dialog(str(titles.get(run.ended, "WORLD BOSS")), portrait)
	var body: VBoxContainer = parts["body"]
	var state := WorldBossRules.progress(game.profile, run.boss, run.round)
	var mine := WorldBossRules.part(content, run.boss, run.total)
	var players := int(data.get("players", 1))
	body.add_child(
		UiKit.label(
			(
				"You dealt %d damage (%.1f%% of the round's pool)."
				% [run.dealt, 100.0 * run.dealt / maxf(1.0, run.total)]
			),
			UiTheme.SIZE_BODY
		)
	)
	var tiers: Array = data["tiers"]
	var reached := 0
	for tier: Dictionary in tiers:
		reached += 1 if int(state["dealt"]) >= ceili(mine * float(tier["share"])) else 0
	var own := "your part" if players > 1 else "the round"
	body.add_child(
		UiKit.label(
			(
				"This round: %d%% of %s dealt, reward tier %d of %d."
				% [roundi(100.0 * float(state["dealt"]) / mine), own, reached, tiers.size()]
			),
			UiTheme.SIZE_BODY,
			UiTheme.TEAL
		)
	)
	if not state.get("killed", false):
		# Only the kill pays, within the hour; an escape pays nothing.
		var wait := WorldBossRules.wait_text(content, run.boss, game._now())
		var text := (
			"%s escaped: back at full strength next round. This round pays nothing." % boss_name
			if run.ended == "time"
			else (
				"No rewards until %s falls. It stays wounded for %s more; then it escapes."
				% [boss_name, wait]
			)
		)
		body.add_child(UiKit.label(text, UiTheme.SIZE_SMALL, UiTheme.DANGER, 470))
	if players > 1 and not state.get("killed", false):
		body.add_child(
			UiKit.label(
				"Built for %d players: bring them to bring it down." % players,
				UiTheme.SIZE_SMALL,
				UiTheme.TEXT_DIM
			)
		)
	if paid["tiers"] or paid["kill"]:
		var won: Array[String] = ["+%d coins" % paid["money"]]
		for item_id: String in paid["items"]:
			won.append("%s x%d" % [content.item(item_id)["name"], paid["items"][item_id]])
		body.add_child(
			UiKit.label("Rewards: " + ",  ".join(won), UiTheme.SIZE_BODY, UiTheme.GOLD, 470)
		)
	var home := str(content.area(AreaRules.hub(content)).get("name", "home"))
	var back := _choice("Back to %s" % home, game._leave_world_boss)
	back.name = "Leave"
	body.add_child(back)
	return parts["root"]


static func knocked_out(game: Game, loss: int, at_boss := false) -> Control:
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
	var here := str(game.zone.area.get("name", "the street"))
	var where := (
		"You come to just short of the fight. Try again."
		if at_boss
		else "You come to at the edge of %s. Fights you won stay won." % here
	)
	var text := UiKit.label(where, UiTheme.SIZE_H2, UiTheme.TEXT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(text)
	var cost := UiKit.label(
		"You dropped %d coins in the street." % loss if loss else "You had no coins to lose.",
		UiTheme.SIZE_BODY,
		UiTheme.GOLD
	)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(cost)
	var again := UiKit.button("Get back up", game._recover)
	again.custom_minimum_size = Vector2(140, 22)
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(again)
	return root


## The ending: what became of the city, one line at a time, then back to the
## street (the game goes on after the story for farming and gear).
static func epilogue(game: Game, chapter: Dictionary) -> Control:
	var root := Control.new()
	root.name = "Epilogue"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.06, 0.92)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UiTheme.GAP)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(column)
	var heading := UiKit.overlay_label(
		str(chapter["title"]).to_upper(), UiTheme.SIZE_LOGO - 6, UiTheme.GOLD
	)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var subtitle := UiKit.label("Epilogue: A City That Remains", UiTheme.SIZE_H2, UiTheme.TEAL)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	for line: String in chapter["epilogue"]:
		var text := UiKit.label(line, UiTheme.SIZE_BODY, UiTheme.TEXT, 520)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(text)
	var on := UiKit.button("Back to the streets", game.close_menu)
	on.name = "Continue"
	on.custom_minimum_size = Vector2(160, 22)
	on.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(on)
	on.call_deferred("grab_focus")
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
static func _meter(text: String, value: int, maximum: int, color: Color) -> Control:
	var bar := StatBar.new()
	bar.color = color
	bar.show_text = true
	bar.custom_minimum_size = Vector2(130, 9)
	bar.set_values(value, maximum, true)
	return UiKit.row(text, bar)
