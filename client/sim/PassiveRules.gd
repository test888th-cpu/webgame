class_name PassiveRules
extends RefCounted
## Passive skills: standing bonuses a fighter earns by how they fight. A
## passive (skills.json, "type": "passive", "passive": {...}) is data:
##   "effects": {effect: amount per stack}: "damage", "crit" and
##       "attack_speed" add to the fighter's own; "resist" takes that share off
##       damage taken (capped at MAX_RESIST); "hold" lengthens grabs by that
##       share; "parry_window" adds ticks to the perfect guard
##   "always": true    counts as one stack at all times (no counting), or
##   "gain": event     adds a stack (up to "max"), and restarts "duration"
##   "reset": event    drops every stack
##   "duration": ticks stacks last without a new one (0: until reset)
##   "when": which blows the bonus applies to: "any"; "finisher" (a move no
##       light punch follows); "counter" (the foe is open after a parry);
##       "staggered" (the foe is reeling or open); "slam" (a throw or a thrown
##       body's crash); "skill" (a skill's blow); "attacking" (while this
##       fighter is mid-attack, for "resist")
##   "skill": id       only while that skill is being used
##   "consume": true   the stacks are spent by the first blow they boost
## Events: "hit" (a blow landed unblocked), "miss" (an attack ended having
## touched nobody), "parry" (a perfect guard), "hurt" (took a blow).
## An active skill may carry a "buff" ({"effects", "duration"}: one stack
## for that long each time the skill starts) or a "bonus" ({"when",
## "effects"}: applies to that skill's own blows); SkillRules turns both into
## specs here. Stacks are combat state (Fighter.stacks), never saved.

const EVENTS: Array[String] = ["hit", "miss", "parry", "hurt"]
const EFFECTS: Array[String] = ["damage", "crit", "attack_speed", "resist", "hold", "parry_window"]
const WHEN: Array[String] = [
	"any", "finisher", "counter", "staggered", "slam", "skill", "attacking"
]
## The most damage "resist" can take off, whatever the stacks.
const MAX_RESIST := 0.6
## The event a skill's own buff is gained on: "skill:<skill id>".
const SKILL_EVENT := "skill:"


## Stacks `f` holds of passive `id`.
static func stacks_of(f: Fighter, id: String) -> int:
	var spec: Dictionary = f.passives.get(id, {})
	if bool(spec.get("always", false)):
		return 1
	return int(f.stacks.get(id, {}).get("count", 0))


static func on_event(f: Fighter, event: String) -> void:
	for id: String in f.passives:
		var spec: Dictionary = f.passives[id]
		if str(spec.get("reset", "")) == event:
			f.stacks.erase(id)
		if str(spec.get("gain", "")) == event:
			var count := mini(int(spec.get("max", 1)), stacks_of(f, id) + 1)
			f.stacks[id] = {"count": count, "ticks": int(spec.get("duration", 0))}


## Runs timed stacks down by one tick.
static func tick(f: Fighter) -> void:
	for id: String in f.stacks.keys():
		var held: Dictionary = f.stacks[id]
		if int(held["ticks"]) > 0:
			held["ticks"] = int(held["ticks"]) - 1
			if held["ticks"] == 0:
				f.stacks.erase(id)


## The sum of `effect` over `f`'s passives, for a blow with `move` on
## `defender` (both null when no blow is involved: only "any" passives count).
static func bonus(
	f: Fighter, effect: String, move: MoveData = null, defender: Fighter = null
) -> float:
	var sum := 0.0
	for id: String in f.passives:
		var spec: Dictionary = f.passives[id]
		if applies(spec, f, move, defender):
			sum += float(spec.get("effects", {}).get(effect, 0.0)) * stacks_of(f, id)
	return sum


## Spends the "consume" passives that boosted this blow.
static func spend(f: Fighter, move: MoveData, defender: Fighter) -> void:
	for id: String in f.passives:
		var spec: Dictionary = f.passives[id]
		if bool(spec.get("consume", false)) and applies(spec, f, move, defender):
			f.stacks.erase(id)


## Whether a passive counts for this blow. A finisher is a move no light
## punch follows (a combination's last blow, the heavy, a skill); a counter is
## a blow on a foe left open by a parry.
static func applies(spec: Dictionary, f: Fighter, move: MoveData, defender: Fighter) -> bool:
	if spec.has("skill") and f.skill_id != str(spec["skill"]):
		return false
	match str(spec.get("when", "any")):
		"finisher":
			return move != null and not move.chains.has("light")
		"counter":
			return defender != null and defender.exposed > 0
		"staggered":
			var reeling := defender != null and defender.state == Fighter.State.HITSTUN
			return reeling or (defender != null and defender.exposed > 0)
		"slam":
			return move != null and move.slam
		"skill":
			return move != null and f.skill_id != "" and f.move == move
		"attacking":
			return f.state == Fighter.State.ATTACK
	return true


## The share of damage `f` shrugs off now (0..MAX_RESIST).
static func resist(f: Fighter) -> float:
	return clampf(bonus(f, "resist"), 0.0, MAX_RESIST)


## What is wrong with a skill's "buff" or "bonus" block.
static func rider_problems(spec: Variant, timed: bool, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if not spec is Dictionary:
		out.append(where + ": expected an object")
		return out
	var checked: Dictionary = spec.duplicate()
	checked["always"] = true
	out.append_array(problems(checked, where))
	var duration: Variant = spec.get("duration")
	if timed and (not (duration is float or duration is int) or duration < 1):
		out.append(where + ".duration: expected ticks, at least 1")
	return out


static func problems(spec: Variant, where: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if not spec is Dictionary:
		out.append(where + ": expected an object")
		return out
	var effects: Variant = spec.get("effects")
	if not effects is Dictionary or effects.is_empty():
		out.append(where + ".effects: expected at least one effect")
	else:
		for effect: Variant in effects:
			var amount: Variant = effects[effect]
			if str(effect) not in EFFECTS:
				out.append("%s.effects: unknown effect %s" % [where, effect])
			elif not (amount is float or amount is int) or amount <= 0:
				out.append("%s.effects.%s: expected a number above 0" % [where, effect])
	if str(spec.get("when", "any")) not in WHEN:
		out.append(where + ".when: expected any, finisher or counter")
	if bool(spec.get("always", false)):
		return out
	if str(spec.get("gain", "")) not in EVENTS:
		out.append(where + ".gain: expected hit, miss, parry or hurt (or always: true)")
	if spec.has("reset") and str(spec["reset"]) not in EVENTS:
		out.append(where + ".reset: unknown event")
	var most: Variant = spec.get("max")
	if not (most is float or most is int) or most < 1 or most != floorf(most):
		out.append(where + ".max: expected a whole number of stacks, at least 1")
	var duration: Variant = spec.get("duration", 0)
	if not (duration is float or duration is int) or duration < 0:
		out.append(where + ".duration: expected ticks, 0 or more")
	return out
