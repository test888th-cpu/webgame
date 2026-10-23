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
}

const PAD_BUTTONS := {
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"move_up": JOY_BUTTON_DPAD_UP,
	"move_down": JOY_BUTTON_DPAD_DOWN,
}

## [axis, direction] for the left stick.
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _init() -> void:
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
		var motion := InputEventJoypadMotion.new()
		motion.axis = PAD_AXES[action][0]
		motion.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, motion)
