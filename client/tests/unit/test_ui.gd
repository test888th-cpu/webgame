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
	# Tests count coins and items from zero, without the starter kit.
	GameSession.profile.money = 0
	GameSession.profile.inventory.clear()
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
	assert_eq(texts, ["New game", "Gallery", "Credits"], "title menu")
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


func test_equipment_tab_shows_the_doll_and_the_bag() -> void:
	var game := _game()
	game.profile.add_item("steamed_bun", 2)
	game.profile.add_item("taped_knuckles")
	game.open_inventory()
	await _settle()
	_check_layout(game.menu, "equipment tab")
	for slot: String in PlayerProfile.SLOTS:
		assert_true(game.menu.find_child("Worn_" + slot, true, false) != null, "%s slot" % slot)
	var bun: ItemSlot = game.menu.find_child("Bag_steamed_bun", true, false)
	assert_eq(bun.count, 2, "stack count")
	assert_true(bun.icon_texture != null, "icon")
	assert_true(_focus_in(game), "something has focus")
	_done(game)


func test_item_card_equips_and_the_stats_follow() -> void:
	var game := _game()
	game.profile.add_item("taped_knuckles")
	game.open_inventory()
	await _settle()
	game.inspect_item("taped_knuckles", "")
	await _settle()
	assert_true(game.item_card != null, "card open")
	_check_layout(game.item_card, "item card")
	var text := _texts(game.item_card)
	assert_true(text.contains("+15 Attack"), "stats in player terms")
	assert_true(text.contains("Requires level 1"), "level requirement")
	assert_true(text.contains("Common Weapon"), "rarity and slot")
	game._equip("taped_knuckles")
	await _settle()
	assert_eq(game.profile.equipment["weapon"], "taped_knuckles", "worn")
	var worn: ItemSlot = game.menu.find_child("Worn_weapon", true, false)
	assert_eq(worn.item_id, "taped_knuckles", "shown on the doll")
	assert_true(tree.root.gui_get_focus_owner() == worn, "focus follows the item")
	GameMenus.switch_tab(game, GameMenus.TAB_STATUS)
	await _settle()
	assert_true(_texts(game.menu).contains("(+15 gear)"), "status shows the gear bonus")
	_done(game)


func test_level_requirements_and_discard() -> void:
	var game := _game()
	game.profile.add_item("hard_hat")
	game.profile.add_item("steamed_bun", 2)
	game._equip("hard_hat")
	assert_eq(game.profile.equipment["head"], "dock_beanie", "level 1 cannot wear a level 3 hat")
	assert_eq(game.profile.count("hard_hat"), 1, "still in the bag")
	game.inspect_item("steamed_bun", "")
	await _settle()
	var discard: Button = null
	for button: Button in game.item_card.find_children("*", "Button", true, false):
		if button.text == "Discard":
			discard = button
	discard.pressed.emit()
	assert_eq(game.profile.count("steamed_bun"), 2, "the first press only asks")
	discard.pressed.emit()
	assert_eq(game.profile.count("steamed_bun"), 1, "the second discards one")
	_done(game)


func _texts(root: Node) -> String:
	var parts: Array[String] = []
	for label: Label in root.find_children("*", "Label", true, false):
		parts.append(label.text)
	return " | ".join(parts)


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
	assert_eq(prompts.size(), 3, "one prompt per NPC")
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


func test_character_creation_shows_heroes_and_validates_the_name() -> void:
	var screen: Node = load("res://scenes/create/CharacterCreate.tscn").instantiate()
	tree.root.add_child(screen)
	await _settle()
	assert_eq(screen.cards.size(), GameSession.content.hero_order.size(), "a card per hero")
	assert_eq(screen.selected, "mika", "first hero selected")
	_check_layout(screen.get_node("Ui"), "character creation")
	var owner := tree.root.gui_get_focus_owner()
	assert_true(owner == screen.cards["mika"], "the selected card has focus")
	screen.cards["oren"].grab_focus()
	await _settle()
	assert_eq(screen.selected, "oren", "focus selects")
	assert_eq(screen.name_field.text, "Oren", "suggests the hero's name")
	screen.name_field.text = "x"
	screen.name_field.text_changed.emit("x")
	assert_true(screen.start_button.disabled, "a one-letter name cannot start")
	screen.name_field.text = "Big Tank"
	screen.name_field.text_changed.emit("Big Tank")
	assert_true(not screen.start_button.disabled, "a valid name can")
	screen.cards["mika"].grab_focus()
	await _settle()
	assert_eq(screen.name_field.text, "Big Tank", "a typed name is kept when switching hero")
	screen.free()
	SaveStore.path = SaveStore.DEFAULT_PATH


func test_hud_portrait_shows_the_hero_level_and_low_hp() -> void:
	var game := _game()
	await _settle()
	var portrait: HeroPortrait = game.get_node("Hud").find_child("Portrait", true, false)
	assert_true(portrait != null, "portrait on the hero card")
	assert_eq(portrait.level, 1, "level badge")
	assert_true(not portrait.low_hp, "healthy")
	game.zone.hero.hp = 10
	game.profile.level = 4
	await _settle()
	assert_eq(portrait.level, 4, "badge follows the level")
	assert_true(portrait.low_hp, "low HP warning")
	_done(game)


func test_loot_shows_the_item_icon_name_and_rarity() -> void:
	var game := _game()
	game.zone.pickups.append(
		{
			"id": 900,
			"kind": "item",
			"item": "iron_wraps",
			"amount": 1,
			"position": Vector2(300, 300)
		}
	)
	game.zone.pickups.append(
		{"id": 901, "kind": "money", "amount": 12, "position": Vector2(330, 300)}
	)
	game.view.sync()
	var loot: LootView = game.view.find_child("Loot900", true, false)
	assert_true(loot != null, "item on the ground")
	var name_label: Label = loot.get_node("Name")
	assert_eq(name_label.text, "Iron Wraps", "named")
	assert_eq(loot.color, ItemText.RARITY_COLORS["rare"], "in its rarity colour")
	var coins: LootView = game.view.find_child("Loot901", true, false)
	assert_eq((coins.get_node("Name") as Label).text, "12", "coins show the amount")
	game.zone.pickups.clear()
	game.view.sync()
	await tree.create_timer(0.35).timeout
	assert_true(not is_instance_valid(loot), "collected loot flies off and is freed")
	_done(game)


func test_gallery_lists_every_character_and_item_and_fits() -> void:
	var gallery: Control = load("res://scenes/tools/Gallery.tscn").instantiate()
	tree.root.add_child(gallery)
	await _settle()
	var content := GameSession.content
	for art_id: String in content.art:
		if content.art[art_id]["status"] == "imported":
			assert_true(gallery.buttons.has(art_id), "%s is in the roster" % art_id)
	assert_eq(gallery.names["hero_riku"], "Riku Sato", "characters go by their names")
	assert_eq(gallery.names["furnace_baron"], "The Furnace Baron", "enemies too")
	var owner := tree.root.gui_get_focus_owner()
	assert_true(owner != null and gallery.is_ancestor_of(owner), "something has focus")
	assert_true(gallery.selected != "", "the focused character is on the stage")
	(gallery.buttons["hero_riku"] as Button).grab_focus()
	await _settle()
	assert_eq(gallery.selected, "hero_riku", "focus picks a character")
	var heavy: Button = gallery.find_child("Anim_heavy", true, false)
	heavy.pressed.emit()
	var stage: SpriteView = gallery.find_child("Stage", true, false)
	assert_eq(stage.sprite.animation, &"heavy", "a move plays on the stage")
	for name: String in ["Tabs", "Stage", "Animations"]:
		var control: Control = gallery.find_child(name, true, false)
		assert_true(SCREEN.grow(1).encloses(control.get_global_rect()), "%s fits" % name)
	gallery.tabs.current_tab = 1
	await _settle()
	for item_id: String in content.items:
		assert_true(
			gallery.find_child("Item_" + item_id, true, false) != null, "%s is shown" % item_id
		)
	assert_true(gallery.find_child("ItemDetails", true, false) != null, "an item card shows")
	assert_true(gallery.find_child("Ground", true, false).get_child_count() == 1, "and how it lies")
	gallery.free()
