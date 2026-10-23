class_name PlayerInput
extends RefCounted
## Turns the local input actions into one tick of FighterInput. Called from
## _physics_process so the edge-triggered buttons line up with sim ticks.


static func read() -> FighterInput:
	var input := FighterInput.new()
	input.move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input.light = Input.is_action_just_pressed("attack_light")
	input.heavy = Input.is_action_just_pressed("attack_heavy")
	input.dodge = Input.is_action_just_pressed("dodge")
	input.guard = Input.is_action_pressed("guard")
	return input
