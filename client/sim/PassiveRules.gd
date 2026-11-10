class_name PassiveRules
extends RefCounted
## Passive skills: standing bonuses a fighter earns by how they fight. A
## passive (skills.json, "type": "passive", "passive": {...}) is data:
##   "effects": {"damage" | "crit" | "attack_speed": amount per stack}
##   "always": true    counts as one stack at all times (no counting), or
##   "gain": event     adds a stack (up to "max"), and restarts "duration"
##   "reset": event    drops every stack
##   "duration": ticks stacks last without a new one (0: until reset)
##   "when": "any" | "finisher" | "counter"   which blows the bonus applies to
##   "consume": true   the stacks are spent by the first blow they boost
## Events: "hit" (a blow landed unblocked), "miss" (an attack ended having
## touched nobody), "parry" (a perfect guard), "hurt" (took a blow).
## Stacks are combat state (Fighter.stacks), never saved.

const EVENTS: Array[String] = ["hit", "miss", "parry", "hurt"]
const EFFECTS: Array[String] = ["damage", "crit", "attack_speed"]
const WHEN: Array[String] = ["any", "finisher", "counter"]


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
		if applies(spec, move, defender):
			sum += float(spec.get("effects", {}).get(effect, 0.0)) * stacks_of(f, id)
	return sum


## Spends the "consume" passives that boosted this blow.
static func spend(f: Fighter, move: MoveData, defender: Fighter) -> void:
	for id: String in f.passives:
		var spec: Dictionary = f.passives[id]
		if bool(spec.get("consume", false)) and applies(spec, move, defender):
			f.stacks.erase(id)


## Whether a passive counts for this blow. A finisher is a move no light
## punch follows (a combination's last blow, the heavy, a skill); a counter is
## a blow on a foe left open by a parry.
static func applies(spec: Dictionary, move: MoveData, defender: Fighter) -> bool:
	match str(spec.get("when", "any")):
		"finisher":
			return move != null and not move.chains.has("light")
		"counter":
			return defender != null and defender.exposed > 0
	return true


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
