class_name GameMenus
extends RefCounted
## Builds the in-game screens for Game.gd. Each screen does one job, in its
## own window with its icon, name, key and a close button:
##   Character  who the hero is and what they can do (CharacterTabs.status)
##   Bag        what is worn and carried (CharacterTabs.equipment)
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
	"quests": ["Quests", "menu_quests", "O", Vector2(500, 300)],
	"map": ["Map", "menu_map", "M", Vector2(600, 318)],
	"settings": ["Settings", "menu_settings", "", Vector2(520, 300)],
}
const PAUSE_WIDTH := 190.0
const LIST_WIDTH := 180.0
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
		"quests":
			page = _quests(game)
		"map":
			page = MapTab.build(game)
		_:
			page = _settings(game)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts["body"].add_child(page)
	return parts["root"]


## The pause menu: back to the game, every screen, and the session actions.
static func pause_menu(game: Game) -> Control:
	var tutorial := not TutorialRules.is_done(game.profile, game.content)
	var parts := UiKit.window("Paused", Vector2(PAUSE_WIDTH, 250 if tutorial else 232), "")
	var body: VBoxContainer = parts["body"]
	body.add_theme_constant_override("separation", 2)
	body.add_child(_menu_item("Resume", "Esc", game.close_menu))
	for name: String in SCREENS:
		var spec: Array = SCREENS[name]
		body.add_child(_menu_item(spec[0], spec[2], game.open_screen.bind(name)))
	body.add_child(HSeparator.new())
	var home := str(game.content.area(game.content.start_area).get("name", "home"))
	var recall := _menu_item("Return to %s" % home, "", game._recall)
	recall.name = "Recall"
	var problem := game.zone.recall_problem()
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


## Auto battle settings: when to eat, the farm loop, food to keep stocked.
static func _auto_options() -> Control:
	var box := VBoxContainer.new()
	box.name = "AutoOptions"
	box.add_theme_constant_override("separation", UiTheme.GAP)
	box.add_child(
		_cycle("Eat when health is below", "auto_heal_at", AutoBattle.HEAL_CHOICES, "%d%%", 100.0)
	)
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


## The motorbike taxi's stand: one ride per area reached before, in street
## order, for the driver's fare.
static func travel(game: Game, npc: Dictionary) -> Control:
	var content := game.content
	var parts := UiKit.dialog(str(npc["name"]), UiKit.portrait(content, str(npc.get("sprite", ""))))
	var body: VBoxContainer = parts["body"]
	var fare := int(npc.get("fare", 0))
	var line := '"%s"' % str(npc.get("line", "Where to?"))
	body.add_child(UiKit.label(line, UiTheme.SIZE_BODY, UiTheme.TEXT_DIM, 470))
	body.add_child(UiKit.label("Fare: %d coins" % fare, UiTheme.SIZE_SMALL, UiTheme.GOLD))
	var places := StreetMemory.destinations(game.profile, content, game.zone.area_id)
	for area_id in places:
		var area := content.area(area_id)
		var text := "%s  (Lv %d)" % [area["name"], int(area.get("level", 1))]
		var ride := _choice(text, game._ride.bind(npc, area_id))
		ride.name = "Ride_" + area_id
		ride.disabled = game.profile.money < fare
		body.add_child(ride)
	if places.is_empty():
		body.add_child(
			UiKit.label("Nowhere else you know yet.", UiTheme.SIZE_SMALL, UiTheme.TEXT_DIM)
		)
	for boss: String in content.world_bosses:
		if WorldBossRules.unlocked(game.profile, content, boss):
			body.add_child(_world_boss_ride(game, npc, fare, boss))
	body.add_child(_choice("Not now", game.close_menu))
	return parts["root"]


## Win's ride to world boss `boss`: open (with time left) or when it opens
## next, and who it is for (the level it needs, the players it is built for).
static func _world_boss_ride(game: Game, npc: Dictionary, fare: int, boss: String) -> Control:
	var content := game.content
	var data := WorldBossRules.spec(content, boss)
	var name := str(content.enemy(str(data["enemy"]))["name"])
	var round := WorldBossRules.window(content, boss, game._now())
	var wait := WorldBossRules.wait_text(content, boss, game._now())
	var who := "Lv %d+, " % int(data["min_hero_level"]) if data.has("min_hero_level") else ""
	var players := int(data.get("players", 1))
	who += "%d players" % players if players > 1 else "solo"
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
	var titles := {"slain": "%s FALLS!" % boss_name.to_upper(), "time": "TIME'S UP"}
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
	var own := "your part" if players > 1 else "the round"
	body.add_child(
		UiKit.label(
			(
				"This round: %d%% of %s dealt, reward tier %d of %d."
				% [
					roundi(100.0 * float(state["dealt"]) / mine),
					own,
					int(state["tiers"]),
					tiers.size()
				]
			),
			UiTheme.SIZE_BODY,
			UiTheme.TEAL
		)
	)
	if int(state["tiers"]) < tiers.size():
		var next := float(tiers[int(state["tiers"])]["share"])
		body.add_child(
			UiKit.label(
				"Next reward at %d%% of %s." % [roundi(next * 100), own],
				UiTheme.SIZE_SMALL,
				UiTheme.TEXT_DIM
			)
		)
	if players > 1 and not state.get("killed", false):
		body.add_child(
			UiKit.label(
				"Built for %d players: the kill and its rarest drops need them all." % players,
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
	var home := str(content.area(content.start_area).get("name", "home"))
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
