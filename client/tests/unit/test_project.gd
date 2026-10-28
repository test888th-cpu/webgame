extends TestCase
## Guards the project properties the browser build depends on.


func test_protocol_version_is_positive() -> void:
	var build_info: Node = tree.root.get_node_or_null("BuildInfo")
	assert_true(build_info != null, "BuildInfo autoload is registered")
	if build_info:
		assert_true(build_info.PROTOCOL_VERSION > 0, "protocol version is positive")
		assert_true(build_info.summary().contains("protocol="), "summary reports the protocol")


func test_renderer_is_web_compatible() -> void:
	# WebGL 2 only supports the Compatibility renderer.
	for setting in [
		"rendering/renderer/rendering_method", "rendering/renderer/rendering_method.mobile"
	]:
		assert_eq(ProjectSettings.get_setting(setting), "gl_compatibility", setting)


func test_main_scene_is_the_title() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/title/Title.tscn",
		"main scene"
	)


func test_web_preset_is_single_threaded_release() -> void:
	# Threaded web builds need COOP/COEP headers on every host and proxy; the
	# decision to stay single-threaded is recorded in WEB_EXPORT.md.
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK, "export_presets.cfg loads")
	var found := false
	for section in presets.get_sections():
		if presets.get_value(section, "platform", "") == "Web":
			found = true
			var options := section + ".options"
			assert_eq(
				presets.get_value(options, "variant/thread_support"),
				false,
				"web export has threads disabled"
			)
			assert_eq(
				presets.get_value(section, "exclude_filter"), "tests/*", "tests are not shipped"
			)
	assert_true(found, "a Web export preset exists")


func test_actions_have_keyboard_and_gamepad_bindings() -> void:
	for action in InputSetup.KEYS:
		assert_true(InputMap.has_action(action), "%s exists" % action)
		var kinds := {}
		for event in InputMap.action_get_events(action):
			kinds[event.get_class()] = true
		var expected := ["InputEventKey"]
		# Keyboard-only screen keys: on a pad those screens are in the Start menu.
		if InputSetup.PAD_BUTTONS.has(action):
			expected.append("InputEventJoypadButton")
		else:
			assert_true(
				action in ["character", "bag", "skills", "quests"], "%s needs a pad button" % action
			)
		if action.begins_with("move_"):
			expected.append("InputEventJoypadMotion")
		for kind in expected:
			assert_true(kinds.has(kind), "%s has a %s binding" % [action, kind])


func test_physics_rate_matches_simulation_rate() -> void:
	assert_eq(
		Engine.physics_ticks_per_second,
		CombatRules.TICK_RATE,
		"one physics frame is one combat tick"
	)
