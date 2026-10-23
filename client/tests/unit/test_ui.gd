extends TestCase
## Interface rules from docs/UI.md, checked on the real screens: every window
## fits the 640x360 base viewport, wrapping text always has a width (an
## unsized wrapping label stacks one word per line), something has focus so
## keyboard and gamepad work, and the world shows who you can talk to.

const TEST_SAVE := "user://test_save.json"
const SCREEN := Rect2(0, 0, 640, 360)
const TITLE_SCENE := "res://scenes/title/Title.tscn"


func _game() -> Game:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(node: Node) -> void:
	node.free()
	SaveStore.delete()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _settle() -> void:
	# Lay out at the 16:9 base size; the headless window is not 16:9 and
	# "expand" stretching would otherwise give the screens extra room.
	tree.root.size = Vector2i(1280, 720)
	await tree.process_frame
	await tree.process_frame


## Fails for any visible control outside the screen and any wrapping label
## without a width.
func _check_layout(root: Node, what: String) -> void:
	for node in root.find_children("*", "Control", true, false):
		var control: Control = node
		if not control.is_visible_in_tree():
			continue
		if control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
			assert_true(control.custom_minimum_size.x > 0, "%s: wrapping label has a width" % what)
		if control is PanelContainer or control is Button or control is Label:
			var rect := control.get_global_rect()
			assert_true(
				SCREEN.grow(1).encloses(rect),
				"%s: %s %s fits on screen (%s)" % [what, control.get_class(), control.name, rect]
			)


func _focus_in(game: Game) -> bool:
	var owner := tree.root.gui_get_focus_owner()
	return owner != null and game.menu.is_ancestor_of(owner)


func test_title_menu_without_a_save() -> void:
	SaveStore.path = TEST_SAVE
	SaveStore.delete()
	var title: Node = load(TITLE_SCENE).instantiate()
	tree.root.add_child(title)
	await _settle()
	var texts: Array[String] = []
	for button: Button in title.find_children("*", "Button", true, false):
		texts.append(button.text)
	assert_eq(texts, ["New game", "Characters", "Credits"], "title menu")
	var owner := tree.root.gui_get_focus_owner()
	assert_true(owner is Button and (owner as Button).text == "New game", "New game focused")
	_check_layout(title.get_node("Ui"), "title")
	_done(title)


func test_title_menu_offers_continue_first_with_a_save() -> void:
	SaveStore.path = TEST_SAVE
	SaveStore.save(PlayerProfile.new_game(GameSession.content))
	var title: Node = load(TITLE_SCENE).instantiate()
	tree.root.add_child(title)
	await _settle()
	var buttons := title.find_children("*", "Button", true, false)
	assert_eq((buttons[0] as Button).text, "Continue", "Continue first")
	assert_eq((buttons[1] as Button).text, "New game", "then New game")
	_done(title)


func test_every_pause_tab_fits_and_switches_with_the_tab_keys() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun", 3)
	game.profile.add_item("taped_knuckles")
	QuestRules.accept(game.profile, "clear_saltmarket", game.content)
	game.open_pause()
	for i in GameMenus.TABS.size():
		await _settle()
		assert_eq(game.menu_name, GameMenus.TAB_MENU_NAMES[i], "tab %d reported" % i)
		_check_layout(game.menu, "pause tab " + GameMenus.TABS[i])
		GameMenus.cycle_tab(game.menu, 1)
	await _settle()
	assert_eq(game.menu_name, "pause", "wraps back to Status")
	GameMenus.cycle_tab(game.menu, -1)
	assert_eq(game.menu_name, "system", "and backwards")
	_done(game)


func test_bag_lists_items_with_icons_and_keeps_the_selection_after_equipping() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun", 2)
	game.profile.add_item("taped_knuckles")
	game.open_inventory()
	await _settle()
	var list: ItemList = game.menu.find_children("*", "ItemList", true, false)[0]
	assert_eq(list.item_count, 2, "bun and knuckles")
	assert_true(list.get_item_icon(0) != null, "items show icons")
	assert_true(_focus_in(game), "the list has focus")
	game._equip("taped_knuckles")
	await _settle()
	list = game.menu.find_children("*", "ItemList", true, false)[0]
	assert_eq(list.get_selected_items(), PackedInt32Array([0]), "equipped item stays selected")
	assert_true(list.get_item_text(0).contains("(on)"), "and is marked as worn")
	_done(game)


func test_shop_fits_and_focuses_the_wares() -> void:
	var game := _game()
	game.profile.money = 5
	game.zone.hero.position = Vector2(410, 262)
	assert_true(game.try_interact(), "vendor in reach")
	await _settle()
	_check_layout(game.menu, "shop")
	assert_true(_focus_in(game), "wares focused")
	var buy: Array[Button] = []
	for button: Button in game.menu.find_children("*", "Button", true, false):
		if button.text.begins_with("Need"):
			buy.append(button)
	assert_eq(buy.size(), 1, "an unaffordable item says how much is missing")
	assert_true(buy[0].disabled, "and cannot be bought")
	_done(game)


func test_conversation_and_knock_out_screens_fit() -> void:
	var game := _game()
	game.zone.hero.position = Vector2(620, 262)
	assert_true(game.try_interact(), "chief in reach")
	await _settle()
	_check_layout(game.menu, "conversation")
	assert_true(_focus_in(game), "first choice focused")
	game.open_game_over()
	await _settle()
	_check_layout(game.menu, "knocked out")
	assert_true(_focus_in(game), "get-up button focused")
	_done(game)


func test_talk_prompt_shows_only_near_an_npc() -> void:
	var game := _game()
	game.zone.hero.position = Vector2(140, 300)
	game.step(FighterInput.new())
	var prompts := game.view.find_children("Prompt", "CenterContainer", true, false)
	assert_eq(prompts.size(), 2, "one prompt per NPC")
	for prompt: Control in prompts:
		assert_true(not prompt.visible, "hidden far away")
	game.zone.hero.position = Vector2(410, 262)
	game.step(FighterInput.new())
	var shown := 0
	for prompt: Control in prompts:
		shown += 1 if prompt.visible else 0
	assert_eq(shown, 1, "the vendor's prompt shows")
	_done(game)


func test_hud_fits_and_reads_the_hero() -> void:
	var game := _game()
	await _settle()
	var hud: CanvasLayer = game.get_node("Hud")
	_check_layout(hud.get_node("Root"), "hud")
	_done(game)


func test_hotbar_shows_seven_slots_with_locks_and_counts() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun", 3)
	await _settle()
	var hotbar: Hotbar = game.get_node("Hud").find_child("Hotbar", true, false)
	assert_eq(hotbar.slots.size(), 7, "seven slots")
	_check_layout(hotbar, "hotbar")
	assert_eq(hotbar.slots[3].locked_level, 2, "rush locked until Lv 2")
	assert_eq(hotbar.slots[4].locked_level, 3, "slam locked until Lv 3")
	assert_eq(hotbar.slots[5].count, 3, "bun count")
	assert_true(hotbar.slots[1].icon != null, "skills show icons")
	_done(game)


func test_pressing_a_skill_slot_casts_it_and_shows_the_cooldown() -> void:
	var game := _game()
	await _settle()
	var input := FighterInput.new()
	assert_true(game.use_slot(1, input), "uppercut accepted")
	game.step(input)
	assert_eq(game.zone.hero.move.id, "rising_uppercut", "the hero uses it")
	await _settle()
	var hotbar: Hotbar = game.get_node("Hud").find_child("Hotbar", true, false)
	assert_true(hotbar.slots[1].cooldown > 0.9, "cooldown sweep shown")
	assert_true(not game.use_slot(1, FighterInput.new()), "refused while cooling down")
	assert_true(not game.use_slot(4, FighterInput.new()), "locked slam refused")
	_done(game)


func test_hits_spawn_effects() -> void:
	var game := _game()
	var dummy: Fighter = game.zone.enemies()[0]
	game.zone.hero.position = dummy.position - Vector2(20, 0)
	game.zone.hero.facing = 1
	var input := FighterInput.new()
	input.light = true
	for i in 12:
		game.step(input if i == 0 else FighterInput.new())
	assert_true(game.hero_hits > 0, "jab landed")
	var sparks := game.view.effects.find_children("*", "AnimatedSprite2D", false, false)
	assert_true(sparks.size() > 0, "a hit spark plays")
	_done(game)


func test_skill_effect_plays_on_the_hero() -> void:
	var game := _game()
	await _settle()
	var input := FighterInput.new()
	game.use_slot(2, input)
	game.step(input)
	await tree.create_timer(0.25).timeout
	var hero_view := game.view.view_of(ZoneSim.HERO_ID)
	var effects := hero_view.find_children("*", "AnimatedSprite2D", false, false)
	assert_true(effects.size() >= 2, "the whirlwind plays on the hero (%d)" % effects.size())
	_done(game)
