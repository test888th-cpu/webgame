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
## Perfectly guarded (no damage; the attacker reels) and a hit on a reeling
## attacker (extra damage).
var parried := false
var counter := false
## A critical hit (CombatRules.CRIT_DAMAGE times the damage).
var critical := false
## Landed on a fighter who did not flinch (poise armor or a telegraphed
## wind-up): damage only.
var armored := false
var knocked_down := false
var ko := false
var position := Vector2.ZERO
