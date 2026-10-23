extends Node
## Registers the game's input actions at startup.
##
## Bindings live in code rather than project.godot so they are reviewable in
## diffs and testable headlessly. Touch controls fire the same actions through
## TouchScreenButton, so gameplay code only ever reads actions.

const DEADZONE := 0.3

const KEYS := {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"attack_light": [KEY_J, KEY_Z],
	"attack_heavy": [KEY_K, KEY_X],
	"dodge": [KEY_SPACE, KEY_L],
	"guard": [KEY_SHIFT, KEY_I],
	"interact": [KEY_E, KEY_U],
	"use_item": [KEY_H, KEY_Q],
	"pause": [KEY_ESCAPE, KEY_P],
	# Menu tabs. These share keys with interact and use_item, which do
	# nothing while a menu is open.
	"menu_prev": [KEY_Q],
	"menu_next": [KEY_E],
}

const PAD_BUTTONS := {
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"move_up": JOY_BUTTON_DPAD_UP,
	"move_down": JOY_BUTTON_DPAD_DOWN,
	"attack_light": JOY_BUTTON_X,
	"attack_heavy": JOY_BUTTON_Y,
	"dodge": JOY_BUTTON_A,
	"guard": JOY_BUTTON_LEFT_SHOULDER,
	"interact": JOY_BUTTON_B,
	"use_item": JOY_BUTTON_RIGHT_SHOULDER,
	"pause": JOY_BUTTON_START,
	"menu_prev": JOY_BUTTON_LEFT_SHOULDER,
	"menu_next": JOY_BUTTON_RIGHT_SHOULDER,
}

## [axis, direction] for the left stick (movement only).
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}

## Hotbar slots 1-7 on the number row and the numpad. On a gamepad, slots
## are reached by holding the right trigger (skill_modifier) with a face
## button; PlayerInput does that mapping.
const HOTBAR_SLOTS := 7

## Extra keys for the built-in UI navigation actions, so menus follow the
## same WASD layout as walking.
const UI_KEYS := {"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D}


func _init() -> void:
	for slot in range(1, HOTBAR_SLOTS + 1):
		var action := "slot_%d" % slot
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action)
		for keycode: int in [KEY_0 + slot, KEY_KP_0 + slot]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
	if not InputMap.has_action("skill_modifier"):
		InputMap.add_action("skill_modifier", 0.5)
		var trigger := InputEventJoypadMotion.new()
		trigger.axis = JOY_AXIS_TRIGGER_RIGHT
		trigger.axis_value = 1.0
		InputMap.action_add_event("skill_modifier", trigger)
	for action: String in UI_KEYS:
		var key := InputEventKey.new()
		key.physical_keycode = UI_KEYS[action]
		InputMap.action_add_event(action, key)
	for action: String in KEYS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, DEADZONE)
		for keycode: Key in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
		var button := InputEventJoypadButton.new()
		button.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, button)
		if PAD_AXES.has(action):
			var motion := InputEventJoypadMotion.new()
			motion.axis = PAD_AXES[action][0]
			motion.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, motion)
