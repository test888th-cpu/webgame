class_name FighterInput
extends RefCounted
## One tick of intent from a player or an AI. Buttons are edge-triggered
## (true only on the tick they were pressed), except `guard`, which is held.
## This is all a client will ever send to the authoritative server.

var move := Vector2.ZERO
var light := false
var heavy := false
var dodge := false
var guard := false
## Skill id to use this tick ("" for none). The fighter must know the skill
## and have it off cooldown; otherwise the press is ignored.
var skill := ""
## Turn to face +1/-1 before acting (0: keep facing). Lets an AI turn toward a
## target without stepping.
var face := 0
