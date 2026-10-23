extends Control
## Title screen: New Game, Continue (when a save exists) and the controls.
## Prints the boot marker the browser smoke test waits for.

const BOOT_MARKER := "BOOT_OK"
const GAME_SCENE := "res://scenes/game/Game.tscn"

var _probe_timer := 0.0


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.06, 0.06, 0.09)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	center.add_child(list)
	var title := UiKit.label(
		str(ProjectSettings.get_setting("application/config/name")), 28, Color(1, 0.75, 0.4)
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)
	var tagline := UiKit.label(
		"Clear the Murk from Port Verrin, block by block.", 9, Color(0.75, 0.75, 0.85)
	)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(tagline)
	list.add_child(UiKit.button("New game", _new_game))
	list.add_child(UiKit.button("Continue", _continue, not SaveStore.has_save()))
	const HELP := (
		"Move WASD/arrows  Light J  Heavy K  Dodge Space  Guard Shift\n"
		+ "Talk E  Eat H  Pause Esc  (gamepad and touch supported)"
	)
	var help := UiKit.label(HELP, 8, Color(0.6, 0.62, 0.7))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(help)
	var build := UiKit.label(BuildInfo.summary(), 6, Color(0.45, 0.47, 0.55))
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(build)
	UiKit.focus_first(list)
	# The web smoke test waits for this exact line on the browser console.
	print("%s %s" % [BOOT_MARKER, BuildInfo.summary()])


func _process(delta: float) -> void:
	_probe_timer += delta
	if _probe_timer >= 0.1:
		_probe_timer = 0.0
		GameSession.publish_probe({"scene": "title", "has_save": SaveStore.has_save()})


func _new_game() -> void:
	GameSession.start_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func _continue() -> void:
	if GameSession.continue_game():
		get_tree().change_scene_to_file(GAME_SCENE)
