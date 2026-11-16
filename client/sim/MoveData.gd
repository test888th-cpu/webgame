class_name MoveData
extends RefCounted
## One attack, as plain data. Timings are in simulation ticks (60 per second).
## Built only through MoveLibrary, which validates every field.

var id := ""
## Ticks before the hitbox appears, while it is live, and after it closes.
var startup := 1
var active := 1
var recovery := 1
var damage := 0
## Ticks the defender cannot act after being hit.
var hitstun := 0
## Total distance in pixels the defender is pushed away.
var knockback := 0.0
## Hitbox in front of the attacker: starts `reach_offset` px ahead (negative
## reaches behind, for sweeps), extends
## `reach` px, and hits defenders within `depth_tolerance` px of lane depth.
var reach_offset := 0.0
var reach := 0.0
var depth_tolerance := 0.0
var energy_cost := 0.0
## Pixels the attacker travels forward during startup and active ticks (a
## lunge). Zero for attacks that stay in place.
var advance := 0.0
## Ignores guard entirely.
var guard_break := false
## Leaves the defender on the ground (and briefly invulnerable).
var knockdown := false
## A grab: deals nothing itself; if it closes on a foe the attacker holds
## them (GrabRules).
var grab := false
## A counter stance: deals nothing; a blow caught from the front while it is
## active starts the skill's reply (CounterRules).
var counter := false
## A slipping move: its user cannot be hit until its blow is through (the
## recovery is open).
var evade := false
## A throw, or a thrown body crashing into someone (for passives that
## strengthen slams).
var slam := false
## Heavy armour: its user is not knocked out of this move by blows during
## its startup and active ticks (the blows still deal their damage). Only for
## a class's committed heavy moves (a Brawler's finisher), never every move.
var armor := false
## Hits a foe lying on the street (on the ground, "off the ground"): a
## follow-up to a knockdown. Deals its damage only; the fall is not made
## longer, so no loop can keep a foe down.
var otg := false
## A counter stance that also catches guard-breaking blows (a perfect read).
var catch_all := false
## Energy the blow takes from the foe it lands on (a body blow winds them).
var energy_drain := 0.0
## Shows a warning during startup. Used for slow, heavy enemy attacks so a
## player has time to react.
var telegraph := false
## Which sprite animation plays this move ("light" or "heavy"). Presentation
## only; it never affects the rules.
var anim := "light"
## Moves this one can be cancelled into once it has landed a hit.
## Keyed by input ("light" / "heavy").
var chains := {}


func total_ticks() -> int:
	return startup + active + recovery


func is_active_tick(tick: int) -> bool:
	return tick >= startup and tick < startup + active
