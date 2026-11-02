extends TestCase
## The UI audit's detectors (tests/ui/UiAudit.gd), each shown a fixture with
## the fault it looks for and one without, so a detector that stops seeing a
## fault fails here even after the game's own problems are fixed. Then real
## input on the real game: a mouse click, a key and a touch each reach the
## screen they should open. The baseline file is checked for well-formed
## entries. Nothing here changes the game.

const SCREEN := Rect2(0, 0, 640, 360)
const TEST_SAVE := "user://test_ui_audit_save"
const BASELINE := "res://tests/ui/baseline.json"
const CHECKS := [
	"offscreen",
	"touch_target_small",
	"touch_covers_control",
	"touch_covers_npc",
	"touch_covers_lane",
	"touch_floating",
	"keyboard_hint_on_touch",
	"world_band",
	"text_too_small",
	"text_truncated",
	"text_outside_panel",
	"no_keyboard_focus",
	"control_covered",
]


func _fixture() -> Control:
	var root := Control.new()
	root.name = "Fixture"
	root.size = SCREEN.size
	tree.root.add_child(root)
	return root


func _touch(parent: Node, at: Vector2, side: float) -> TouchScreenButton:
	var button := TouchScreenButton.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(side, side)
	button.shape = shape
	button.shape_centered = false
	button.position = at
	parent.add_child(button)
	return button


func _settle(size := Vector2i(1280, 720)) -> void:
	tree.root.size = size
	await tree.process_frame
	await tree.process_frame


func _checks(found: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for finding in found:
		out.append(str(finding["check"]))
	return out


func test_offscreen_sees_what_leaves_the_screen_but_not_scrolled_rows() -> void:
	var root := _fixture()
	var panel := PanelContainer.new()
	panel.position = Vector2(600, 10)
	panel.custom_minimum_size = Vector2(100, 40)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(10, 10)
	scroll.size = Vector2(100, 50)
	root.add_child(scroll)
	var rows := VBoxContainer.new()
	scroll.add_child(rows)
	for i in 20:
		var row := Button.new()
		row.text = "Row %d" % i
		rows.add_child(row)
	await _settle()
	var found := UiAudit.offscreen(root, SCREEN)
	assert_eq(found.size(), 1, "only the panel off the edge: %s" % [found])
	panel.position = Vector2(400, 10)
	await _settle()
	assert_eq(UiAudit.offscreen(root, SCREEN).size(), 0, "nothing when it fits")
	root.free()


func test_touch_targets_are_measured_in_css_pixels() -> void:
	var root := _fixture()
	var small := _touch(root, Vector2(10, 10), 30)
	var tap := Button.new()
	tap.size = Vector2(20, 20)
	root.add_child(tap)
	await _settle()
	var at_one := UiAudit.touch_targets(
		root, [small] as Array[TouchScreenButton], [tap] as Array[Control], 1.0
	)
	assert_eq(at_one.size(), 2, "30 and 20 CSS px are too small")
	var at_three := UiAudit.touch_targets(
		root, [small] as Array[TouchScreenButton], [tap] as Array[Control], 3.0
	)
	assert_eq(at_three.size(), 0, "90 and 60 CSS px are fine")
	root.free()


func test_touch_overlaps_controls_people_and_the_lane() -> void:
	var root := _fixture()
	var button := _touch(root, Vector2(100, 250), 40)
	var tap := Button.new()
	tap.position = Vector2(110, 260)
	tap.size = Vector2(20, 20)
	root.add_child(tap)
	await _settle()
	var people: Array[Rect2] = [Rect2(120, 240, 24, 48)]
	var lane := Rect2(0, 250, 640, 90)
	var found := _checks(
		UiAudit.touch_overlaps(
			root, [button] as Array[TouchScreenButton], [tap] as Array[Control], people, lane
		)
	)
	for check in ["touch_covers_control", "touch_covers_npc", "touch_covers_lane"]:
		assert_true(check in found, "%s found" % check)
	button.position = Vector2(560, 10)
	await _settle()
	assert_eq(
		(
			UiAudit
			. touch_overlaps(
				root, [button] as Array[TouchScreenButton], [tap] as Array[Control], people, lane
			)
			. size()
		),
		0,
		"nothing covered in a clear corner"
	)
	root.free()


func test_floating_touch_controls_and_a_letterboxed_world() -> void:
	var root := _fixture()
	var high := _touch(root, Vector2(20, 100), 40)
	var low := _touch(root, Vector2(20, 1080), 40)
	await _settle()
	var tall := Rect2(0, 0, 640, 1138)
	var found := UiAudit.touch_floating(root, [high, low] as Array[TouchScreenButton], tall)
	assert_eq(found.size(), 1, "only the button far from the bottom")
	assert_eq(str(found[0]["node"]), UiAudit.stable_path(root, high), "the high one")
	assert_eq(
		_checks(UiAudit.world_band(Rect2(0, 389, 640, 360), tall)), ["world_band"], "a thin band"
	)
	assert_eq(UiAudit.world_band(Rect2(0, 0, 640, 360), SCREEN).size(), 0, "a full screen")
	root.free()


func test_keyboard_hints_shown_on_touch() -> void:
	var root := _fixture()
	var hints := HBoxContainer.new()
	hints.add_child(UiKit.key_hint("Esc", "Menu"))
	root.add_child(hints)
	await _settle()
	assert_eq(UiAudit.hints_on_touch(root, [hints] as Array[Control]).size(), 1, "seen")
	hints.visible = false
	assert_eq(UiAudit.hints_on_touch(root, [hints] as Array[Control]).size(), 0, "hidden is fine")
	root.free()


func test_small_text_is_one_finding_per_screen() -> void:
	var root := _fixture()
	for i in 3:
		root.add_child(UiKit.label("Small %d" % i, UiTheme.SIZE_CAPTION))
	await _settle()
	var found := UiAudit.small_text(root, 1.0)
	assert_eq(found.size(), 1, "one finding")
	assert_true("3 texts" in str(found[0]["detail"]), str(found[0]["detail"]))
	assert_eq(UiAudit.small_text(root, 2.0).size(), 0, "14 CSS px is readable")
	root.free()


func test_cut_spilling_and_escaping_text() -> void:
	var root := _fixture()
	var cut := Label.new()
	cut.text = "A long line that cannot fit in its box"
	cut.clip_text = true
	cut.position = Vector2(10, 10)
	cut.size = Vector2(40, 14)
	root.add_child(cut)
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 100)
	panel.size = Vector2(60, 30)
	root.add_child(panel)
	var inner := Control.new()
	panel.add_child(inner)
	var escaping := Label.new()
	escaping.text = "Out"
	escaping.position = Vector2(200, 0)
	inner.add_child(escaping)
	var fine := Label.new()
	fine.text = "Fits"
	fine.position = Vector2(10, 300)
	root.add_child(fine)
	await _settle()
	var found := UiAudit.text_overflow(root)
	var checks := _checks(found)
	assert_true("text_truncated" in checks, "the clipped line")
	assert_true("text_outside_panel" in checks, "the label outside its panel")
	assert_eq(found.size(), 2, "and nothing else: %s" % [found])
	cut.clip_text = false
	await _settle()
	assert_eq(_checks(UiAudit.text_overflow(root)), ["text_outside_panel"], "unclipped text grows")
	root.free()


func test_a_screen_without_keyboard_focus() -> void:
	var root := _fixture()
	var button := Button.new()
	button.text = "Buy"
	root.add_child(button)
	var outside := Button.new()
	tree.root.add_child(outside)
	await _settle()
	outside.grab_focus()
	assert_eq(_checks(UiAudit.focus_missing(root, outside)), ["no_keyboard_focus"], "lost")
	button.grab_focus()
	assert_eq(UiAudit.focus_missing(root, button).size(), 0, "focused inside")
	root.free()
	outside.free()


func test_a_button_hidden_under_another_control() -> void:
	var root := _fixture()
	var button := Button.new()
	button.position = Vector2(10, 10)
	button.size = Vector2(60, 20)
	root.add_child(button)
	var sheet := Panel.new()
	sheet.position = Vector2(0, 0)
	sheet.size = Vector2(200, 100)
	root.add_child(sheet)
	await _settle()
	assert_eq(_checks(UiAudit.covered(root)), ["control_covered"], "under the panel")
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	assert_eq(UiAudit.covered(root).size(), 0, "a panel that lets clicks through")
	root.free()


func test_text_scaling_and_longer_strings() -> void:
	var root := _fixture()
	var label := UiKit.label("Ginger Tea", UiTheme.SIZE_SMALL)
	root.add_child(label)
	UiAudit.scale_text(root, 1.5)
	assert_eq(label.get_theme_font_size("font_size"), 12, "8 px becomes 12")
	UiAudit.pseudo_text(root)
	assert_true(label.text.begins_with("Ginger Tea"), "the original text stays readable")
	assert_true(label.text.length() >= ceili("Ginger Tea".length() * 1.4), "40% longer")
	assert_eq(UiAudit.pseudo("  "), "  ", "blank text stays blank")
	root.free()


func test_paths_are_the_same_on_every_run() -> void:
	var root := _fixture()
	var box := VBoxContainer.new()
	root.add_child(box)
	var named := Button.new()
	named.name = "Buy"
	box.add_child(Label.new())
	box.add_child(named)
	assert_eq(UiAudit.stable_path(root, named), "VBoxContainer[0]/Buy", "names and places")
	assert_eq(
		UiAudit.stable_path(root, box.get_child(0)), "VBoxContainer[0]/Label[0]", "auto names"
	)
	root.free()


func test_the_baseline_names_real_checks_and_places() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	assert_true(parsed is Dictionary and parsed.get("known") is Array, "a list of known problems")
	for key: String in parsed.get("known", []):
		var parts := key.split(" | ")
		assert_eq(parts.size(), 3, "check | where | node: %s" % key)
		assert_true(parts[0] in CHECKS, "a real check: %s" % parts[0])
		assert_eq(parts[1].split("/").size(), 3, "size/variant/screen: %s" % parts[1])


# --- Real input on the real game -------------------------------------------


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Node) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## Canvas point `at` in window coordinates (the game is stretched).
func _window(at: Vector2) -> Vector2:
	return tree.root.get_final_transform() * at


func test_a_mouse_click_on_the_menu_bar_opens_the_bag() -> void:
	var game := _game()
	await _settle()
	var bag: Button = game.get("_hud").get_node("Root/MenuBar/Menu_bag")
	var at := _window(bag.get_global_rect().get_center())
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		tree.root.push_input(click)
	assert_eq(game.menu_name, "bag", "the click opened the bag")
	_done(game)


func test_keys_open_and_close_a_screen() -> void:
	var game := _game()
	await _settle()
	Input.action_press("bag")
	game._physics_process(0.0)
	Input.action_release("bag")
	assert_eq(game.menu_name, "bag", "B opened the bag")
	await tree.process_frame
	Input.action_press("pause")
	game._physics_process(0.0)
	Input.action_release("pause")
	assert_eq(game.menu, null, "Esc closed it")
	_done(game)


func test_a_touch_on_the_pause_button_opens_the_pause_menu() -> void:
	var game := _game()
	await _settle(Vector2i(640, 360))
	var touch: Control = game.get("_hud").get("_touch")
	touch.visible = true
	var pause: TouchScreenButton = touch.get_node("Pause")
	var at := _window(UiAudit.touch_rect(pause).get_center())
	var tap := InputEventScreenTouch.new()
	tap.index = 0
	tap.pressed = true
	tap.position = at
	tree.root.push_input(tap)
	game._physics_process(0.0)
	assert_eq(game.menu_name, "pause", "the touch opened the pause menu")
	tap = tap.duplicate()
	tap.pressed = false
	tree.root.push_input(tap)
	await _settle()
	_done(game)
