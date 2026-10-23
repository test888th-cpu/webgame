class_name PlayerInput
extends RefCounted
## Turns the local input actions into one tick of FighterInput. Called from
## _physics_process so the edge-triggered buttons line up with sim ticks.

## With the right trigger held, these gamepad actions press hotbar slots
## (0-based) instead of their own action.
const MODIFIED := {"attack_light": 1, "attack_heavy": 2, "dodge": 3, "interact": 4, "use_item": 6}


static func read() -> FighterInput:
	var input := FighterInput.new()
	input.move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input.guard = Input.is_action_pressed("guard")
	if Input.is_action_pressed("skill_modifier"):
		return input
	input.light = Input.is_action_just_pressed("attack_light")
	input.heavy = Input.is_action_just_pressed("attack_heavy")
	input.dodge = Input.is_action_just_pressed("dodge")
	return input


## The hotbar slot (0-based) pressed this tick, or -1.
static func slot_pressed() -> int:
	for slot in InputSetup.HOTBAR_SLOTS:
		if Input.is_action_just_pressed("slot_%d" % (slot + 1)):
			return slot
	if Input.is_action_pressed("skill_modifier"):
		for action: String in MODIFIED:
			if Input.is_action_just_pressed(action):
				return MODIFIED[action]
	return -1
