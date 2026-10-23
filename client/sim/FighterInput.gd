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
