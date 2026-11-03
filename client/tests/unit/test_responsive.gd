extends TestCase
## Responsive gameplay (U1-A): the screen layout (ScreenLayout) at desktop,
## landscape phone and portrait phone sizes, and the real game following it:
## the street drawn where the layout puts it, touch controls and key hints by
## the input in use, game screens keeping the landscape canvas until their
## portrait designs, and turning the screen mid-game. Presentation only:
## nothing here touches how the game plays.

const TEST_SAVE := "user://test_responsive_save"
const PHONES := [Vector2(360, 640), Vector2(390, 844), Vector2(412, 915)]
const LANDSCAPE_PHONES := [Vector2(640, 360), Vector2(844, 390), Vector2(915, 412)]


func _layout(
	window: Vector2, device := "touch", portrait_ok := true, insets := Vector4.ZERO
) -> ScreenLayout:
	return ScreenLayout.compute(window, insets, device, portrait_ok)


## The rects a touch player presses, by name.
func _cells(l: ScreenLayout) -> Dictionary:
	var out := {}
	for name in [
		"Up", "Down", "Left", "Right", "Light", "Heavy", "Dodge", "Guard", "Interact", "Item"
	]:
		out[name] = l.pad_cell(name)
	out["Pause"] = l.pause_cell
	out["Auto"] = l.auto_cell
	out["Hotbar"] = l.hotbar
	for i in l.menu_items.size():
		var t := l.touch_size
		var col := i % maxi(1, l.menu_columns)
		var row := i / maxi(1, l.menu_columns)
		out["Menu_" + l.menu_items[i]] = Rect2(
			l.menu.position + Vector2(col, row) * (t + ScreenLayout.GAP), Vector2(t, t)
		)
	return out


func _check_no_overlap(cells: Dictionary, what: String) -> void:
	var names: Array = cells.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: Rect2 = cells[names[i]]
			var b: Rect2 = cells[names[j]]
			assert_true(
				not a.intersects(b),
				"%s: %s and %s do not overlap (%s, %s)" % [what, names[i], names[j], a, b]
			)


func test_desktop_and_keyboard_keep_todays_landscape() -> void:
	for window: Vector2 in [Vector2(1280, 720), Vector2(640, 360), Vector2(1920, 1080)]:
		var l := _layout(window, "keyboard")
		assert_eq(l.mode, ScreenLayout.LANDSCAPE, "%s landscape" % window)
		assert_eq(l.base, Vector2i(640, 360), "the 640x360 canvas")
		assert_eq(l.world, Rect2(0, 0, 640, 360), "the street fills the screen as before")
		assert_eq(l.hotbar, Rect2(), "the HUD keeps its own hotbar place")
		assert_eq(l.menu, Rect2(), "and its own menu bar")
		assert_true(not l.controls, "no touch controls")


func test_portrait_phones_get_a_hud_band_the_street_and_a_control_deck() -> void:
	for window: Vector2 in PHONES:
		var l := _layout(window)
		var what := "%s" % window
		assert_eq(l.mode, ScreenLayout.PORTRAIT, what + " portrait")
		assert_eq(l.base, Vector2i(360, 640), what + " 360-wide canvas")
		assert_near(l.size.x, 360.0, what + " logical width", 0.5)
		assert_true(l.hud.position.y == 0.0 and l.hud.size.y >= ScreenLayout.HUD_BAND, what)
		assert_true(l.hud.size.y <= ScreenLayout.HUD_BAND_MAX, what + " band not too tall")
		assert_eq(l.world.position.y, l.hud.end.y, what + " the street under the band")
		assert_eq(l.world.size.y, ScreenLayout.WORLD_HEIGHT, what + " street 360 tall")
		assert_eq(l.deck.position.y, l.world.end.y, what + " the deck under the street")
		assert_near(l.deck.end.y, l.size.y, what + " down to the bottom", 0.5)
		assert_true(l.world.size.x >= 320.0, what + " every arena (320+) fits across")
		var cells := _cells(l)
		_check_no_overlap(cells, what)
		for name: String in cells:
			var cell: Rect2 = cells[name]
			assert_true(l.deck.encloses(cell), "%s: %s in the deck" % [what, name])
			if name != "Hotbar":
				assert_true(cell.size.x * l.scale >= 43.9, "%s: %s 44 CSS px" % [what, name])
		assert_true(
			(
				l.hotbar.size.y / ScreenLayout.HOTBAR_NATURAL.y * ScreenLayout.HOTBAR_SLOT * l.scale
				>= 43.9
			),
			what + " hotbar slots 44 CSS px"
		)
		assert_true(l.left_pad.get_center().x < l.size.x / 3.0, what + " movement lower left")
		assert_true(l.right_pad.get_center().x > l.size.x * 2.0 / 3.0, what + " combat lower right")


func test_landscape_touch_keeps_controls_off_people_and_each_other() -> void:
	for window: Vector2 in LANDSCAPE_PHONES:
		var l := _layout(window)
		var what := "%s" % window
		assert_eq(l.mode, ScreenLayout.LANDSCAPE, what + " landscape")
		assert_eq(l.base, Vector2i(640, 360), what + " the 640x360 canvas")
		var kerb := l.world.position.y + ScreenLayout.KERB_Y
		assert_true(l.left_pad.position.y >= kerb, what + " arrows below the kerb")
		assert_true(l.right_pad.position.y >= kerb, what + " combat below the kerb")
		var cells := _cells(l)
		_check_no_overlap(cells, what)
		var screen := Rect2(Vector2.ZERO, l.size)
		for name: String in cells:
			var cell: Rect2 = cells[name]
			assert_true(screen.encloses(cell), "%s: %s on screen" % [what, name])
			if name != "Hotbar":
				assert_true(cell.size.x * l.scale >= 43.9, "%s: %s 44 CSS px" % [what, name])
	# On wider phones the hotbar's slots are touch-sized too.
	var wide := _layout(Vector2(844, 390))
	assert_true(wide.hotbar_scale() * ScreenLayout.HOTBAR_SLOT * wide.scale >= 43.9, "slots")


func test_safe_areas_are_kept_clear() -> void:
	var insets := Vector4(10, 44, 12, 34)
	var l := _layout(Vector2(390, 844), "touch", true, insets)
	var px := insets / l.scale
	assert_true(l.hud.size.y >= px.y + ScreenLayout.HUD_BAND, "the band clears the notch")
	for name: String in _cells(l):
		var cell: Rect2 = _cells(l)[name]
		assert_true(cell.end.y <= l.size.y - px.w + 0.01, "%s above the home bar" % name)
		assert_true(cell.position.x >= px.x - 0.01, "%s right of the left inset" % name)
		assert_true(cell.end.x <= l.size.x - px.z + 0.01, "%s left of the right inset" % name)


func test_screens_and_the_title_keep_landscape_and_hide_touch_controls() -> void:
	var l := _layout(Vector2(360, 640), "touch", false)
	assert_eq(l.mode, ScreenLayout.LANDSCAPE, "no portrait design yet: landscape canvas")
	var open := ScreenLayout.compute(Vector2(640, 360), Vector4.ZERO, "touch", true, true)
	assert_true(open.touch and not open.controls, "a screen is open: no touch buttons under it")


func test_the_clear_colour_is_the_games_own() -> void:
	var colour: Color = ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color"
	)
	assert_true(colour.is_equal_approx(UiTheme.BG), "no default grey behind the game")


# --- The real game -----------------------------------------------------------


func _game(window: Vector2i, device: String) -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	InputSetup.set_device(device)
	tree.root.size = window
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT
	InputSetup.set_device("keyboard")
	tree.root.size = Vector2i(1280, 720)


func _settle() -> void:
	for i in 3:
		await tree.process_frame


## Where world y `y` is drawn on screen (logical px).
func _screen_y(game: Game, y: float) -> float:
	return (game.view.get_viewport().get_canvas_transform() * Vector2(0, y)).y


func _hud(game: Game) -> CanvasLayer:
	return game.get("_hud")


func test_portrait_play_draws_the_street_under_the_hud_band() -> void:
	for window: Vector2 in PHONES:
		var game := _game(Vector2i(window), "touch")
		await _settle()
		var l: ScreenLayout = GameSession.layout
		assert_eq(l.mode, ScreenLayout.PORTRAIT, "%s portrait" % window)
		assert_eq(tree.root.content_scale_size, Vector2i(360, 640), "the 360-wide canvas")
		assert_near(_screen_y(game, 0.0), l.world.position.y, "%s street top" % window, 1.0)
		assert_near(_screen_y(game, 360.0), l.world.end.y, "%s street bottom" % window, 1.0)
		var hud := _hud(game)
		assert_true((hud.get("_touch") as Control).visible, "touch controls shown")
		assert_true(not (hud.get_node("Root/Hints") as Control).visible, "no key hints on touch")
		assert_true((hud.get_node("Root/Bands") as Control).visible, "the bands are drawn")
		var bag: Control = hud.get_node("Root/MenuBar/Menu_bag")
		assert_true(bag.visible and bag.size.x * l.scale >= 43.9, "a touch-sized Bag button")
		_done(game)


func test_a_keyboard_shows_hints_and_a_touch_brings_the_controls_back() -> void:
	var game := _game(Vector2i(640, 360), "touch")
	await _settle()
	var hud := _hud(game)
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_D
	InputSetup._input(key)
	assert_eq(InputSetup.device, "keyboard", "a key means the keyboard")
	assert_true((hud.get_node("Root/Hints") as Control).visible, "key hints shown")
	assert_true(not (hud.get("_touch") as Control).visible, "touch controls hidden")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	InputSetup._input(touch)
	assert_eq(InputSetup.device, "touch", "a touch means touch")
	var echo := InputEventMouseButton.new()
	echo.pressed = true
	echo.button_index = MOUSE_BUTTON_LEFT
	InputSetup._input(echo)
	assert_eq(InputSetup.device, "touch", "the browser's click after a tap is not a mouse")
	assert_true((hud.get("_touch") as Control).visible, "touch controls back")
	assert_true(not (hud.get_node("Root/Hints") as Control).visible, "hints gone")
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	InputSetup._input(pad)
	assert_eq(InputSetup.device, "gamepad", "a pad button means the gamepad")
	assert_true(not (hud.get_node("Root/Hints") as Control).visible, "no key hints for a pad")
	_done(game)


func test_a_screen_keeps_the_landscape_canvas_until_it_closes() -> void:
	var game := _game(Vector2i(360, 640), "touch")
	await _settle()
	game.open_inventory()
	await _settle()
	assert_eq(tree.root.content_scale_size, Vector2i(640, 360), "the Bag as it was (U1-B)")
	assert_true(not (_hud(game).get("_touch") as Control).visible, "no touch buttons under it")
	game.close_menu()
	await _settle()
	assert_eq(tree.root.content_scale_size, Vector2i(360, 640), "portrait again")
	assert_true((_hud(game).get("_touch") as Control).visible, "touch controls back")
	_done(game)


func test_turning_the_phone_mid_game_and_mid_screen() -> void:
	var game := _game(Vector2i(360, 640), "touch")
	await _settle()
	for window: Vector2i in [Vector2i(640, 360), Vector2i(412, 915), Vector2i(915, 412)]:
		tree.root.size = window
		await _settle()
		var l: ScreenLayout = GameSession.layout
		var portrait := window.y > window.x
		assert_eq(l.mode == ScreenLayout.PORTRAIT, portrait, "%s mode" % window)
		assert_near(_screen_y(game, 0.0), l.world.position.y, "%s street top" % window, 1.0)
		var pause: TouchScreenButton = _hud(game).get("_touch").get_node("Pause")
		assert_eq(pause.position, l.pause_cell.position, "%s pause button placed" % window)
	game.open_pause()
	tree.root.size = Vector2i(360, 640)
	await _settle()
	assert_eq(game.menu_name, "pause", "the pause menu stays open when turned")
	assert_eq(tree.root.content_scale_size, Vector2i(640, 360), "and keeps its canvas")
	game.close_menu()
	await _settle()
	assert_eq(GameSession.layout.mode, ScreenLayout.PORTRAIT, "portrait play again")
	_done(game)


func test_the_hotbar_is_the_size_the_layout_expects() -> void:
	var game := _game(Vector2i(1280, 720), "keyboard")
	await _settle()
	var bar: Control = _hud(game).get_node("Root/Hotbar")
	assert_eq(bar.get_combined_minimum_size(), ScreenLayout.HOTBAR_NATURAL, "220x34")
	_done(game)
