class_name CombatEvent
extends RefCounted
## Outcome of one hit, for presentation (damage numbers, flashes) and, later,
## for the server to turn into rewards. Produced only by CombatRules.

var attacker_id := 0
var defender_id := 0
var move_id := ""
var damage := 0
var blocked := false
var guard_broken := false
var knocked_down := false
var ko := false
var position := Vector2.ZERO
