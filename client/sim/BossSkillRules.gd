class_name BossSkillRules
extends RefCounted
## The bosses' own skills (boss_skills.json): a catalogue separate from the
## heroes' skills.json, one set per boss and mini-boss. Pure rules over
## ContentDB; BossSkills runs them in a fight and EnemyBrain chooses them.
##
## A skill is one of TYPES. Every boss also has one Ultimate ("ultimate":
## true, type "ultimate"): a cast whose "waves" of hazards cover a wide area,
## each wave warned on the ground on its own timer.
##
## The other TYPES:
## * a blow (STRIKES): its own move, or a combo's moves in turn ("moves"), with
##   a real hitbox; "range" [min, max] is how far ahead the boss must stand to
##   use it and "lane" how close in lane depth;
## * a cast (CASTS): a wind-up move without a hitbox (damage 0), then a
##   "hazard" (BossMechanics' hazards: warned on the ground, then landing) or a
##   "summon" of helpers.
## Every skill has a globally unique id ("MB_" mini-boss, "SB_" stage boss,
## "WB_" world boss, then the owner and a number), exactly one owner, its own
## moves (shared with nothing else), a "cooldown" in ticks and a "phase" from
## which it is used (0: from the start).

const TYPES := [
	"strike",
	"sweep",
	"charge",
	"leap",
	"grab",
	"combo2",
	"combo3",
	"ground",
	"crane",
	"row",
	"volley",
	"chain",
	"quake",
	"summon",
	"ultimate",
]
const CASTS := ["ground", "crane", "row", "volley", "chain", "quake", "summon", "ultimate"]
## How many skills each tier has besides its Ultimate.
const TIERS := {"mini": [3, 4], "stage": [4, 6], "world": [5, 8]}
## Every boss's Ultimate (the owner's rule): exactly this many; each hit
## ULT_DAMAGE times the boss's basic (light) blow; every wave warned at least
## ULT_MIN_WARN ticks; at most ULT_MAX_TILES tiles a wave (a crowd stays
## readable and cheap); a long cooldown.
const ULTIMATES := 1
const ULT_DAMAGE := [2.0, 3.0]
const ULT_MIN_WARN := 60
const ULT_MAX_TILES := 12
const ULT_MIN_COOLDOWN := 900
const PREFIX := {"mini": "MB", "stage": "SB", "world": "WB"}
## Fairness floors (ticks): a heavy blow's wind-up, a combo's light hit's,
## a hazard's warning on the ground.
const MIN_HEAVY_WINDUP := 18
const MIN_LIGHT_WINDUP := 12
## A skill's first blow (seen, then rolled: a quarter-second reaction plus the
## roll's start), a charge (which runs through its wind-up), and a combo's
## gap between a hero recovering from one blow and the next landing (the
## audit's R-1 and D-2).
const MIN_OPENER_WINDUP := 18
const MIN_CHARGE_WINDUP := 24
const MIN_ESCAPE := 17
## An Ultimate of two or more waves threatens at least this many times its
## boss's strongest regular skill, all waves together: a signature attack.
const ULT_SIGNATURE := 1.8
const MIN_WARN := 40
const MIN_COOLDOWN := 120


## The definition of skill `id` ({} if unknown).
static func skill(content: ContentDB, id: String) -> Dictionary:
	return content.boss_skills.get("skills", {}).get(id, {})


## The skill ids of boss `kind`, in order ([] if it has none).
static func of(content: ContentDB, kind: String) -> Array[String]:
	var out: Array[String] = []
	for id: Variant in content.boss_skills.get("bosses", {}).get(kind, {}).get("skills", []):
		out.append(str(id))
	return out


## Boss `kind`'s tier: "mini", "stage" or "world" ("" if not a boss).
static func tier(content: ContentDB, kind: String) -> String:
	return str(content.boss_skills.get("bosses", {}).get(kind, {}).get("tier", ""))


static func is_cast(data: Dictionary) -> bool:
	return str(data.get("type", "")) in CASTS


static func is_ultimate(data: Dictionary) -> bool:
	return bool(data.get("ultimate", false))


## Boss `kind`'s Ultimate ("" if it has none).
static func ultimate_of(content: ContentDB, kind: String) -> String:
	for id in of(content, kind):
		if is_ultimate(skill(content, id)):
			return id
	return ""


## What Fighter.skills holds for boss `kind`: {id: {"move": its first move,
## "cooldown"}}, so the shared combat rules start and cool them down.
static func fighter_table(content: ContentDB, kind: String) -> Dictionary:
	var out := {}
	for id in of(content, kind):
		var data := skill(content, id)
		out[id] = {"move": str(data["moves"][0]), "cooldown": int(data["cooldown"])}
	return out


## What EnemyBrain chooses from: [{"id", "range", "lane", "phase", "weight"}].
static func choices(content: ContentDB, kind: String) -> Array:
	var out: Array = []
	for id in of(content, kind):
		var data := skill(content, id)
		(
			out
			. append(
				{
					"id": id,
					"range": [float(data["range"][0]), float(data["range"][1])],
					"lane": float(data.get("lane", 0)),
					"phase": int(data.get("phase", 0)),
					"weight": float(data.get("weight", 1.0)),
				}
			)
		)
	return out


## Ticks of warning before skill `id` can first hurt: its first move's wind-up,
## plus the ground warning for a hazard.
static func telegraph(content: ContentDB, id: String) -> int:
	var data := skill(content, id)
	var first := content.moves.get_move(str(data["moves"][0]))
	var ticks := first.startup if first else 0
	if data.has("hazard"):
		ticks += int(data["hazard"]["warn"])
	var warns: Array = data.get("waves", []).map(func(w: Dictionary) -> int: return int(w["warn"]))
	if not warns.is_empty():
		ticks += int(warns.min())
	return ticks


## The skill's base damage before the boss's power: every hit of its moves
## added up, or one hazard's.
static func damage(content: ContentDB, id: String) -> int:
	var data := skill(content, id)
	if data.has("hazard"):
		return int(data["hazard"]["damage"])
	if data.has("waves"):
		# An Ultimate: one hit of its strongest wave (a hero caught by every
		# wave takes this per wave).
		return data["waves"].map(func(w: Dictionary) -> int: return int(w["damage"])).max()
	var total := 0
	for move_id: Variant in data.get("moves", []):
		var move := content.moves.get_move(str(move_id))
		total += move.damage if move else 0
	return total


## The skill whose moves include `move_id` ("" if none).
static func owner_of_move(content: ContentDB, move_id: String) -> String:
	for id: String in content.boss_skills.get("skills", {}):
		if move_id in skill(content, id).get("moves", []):
			return id
	return ""


## What is wrong with boss_skills.json, one message each.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var bosses: Dictionary = content.boss_skills.get("bosses", {})
	var skills: Dictionary = content.boss_skills.get("skills", {})
	for kind: String in content.enemies:
		if content.enemy(kind).get("boss", false) and not bosses.has(kind):
			out.append("boss_skills.bosses: %s has no skills" % kind)
	var listed := {}
	for kind: String in bosses:
		out.append_array(_boss_problems(content, kind, bosses[kind], listed))
	var taken := _moves_taken(content)
	for id: String in skills:
		if not listed.has(id):
			out.append("boss_skills.skills.%s: no boss lists it" % id)
		out.append_array(_skill_problems(content, id, skills[id], taken))
	return out


static func _boss_problems(
	content: ContentDB, kind: String, boss: Variant, listed: Dictionary
) -> PackedStringArray:
	var out: PackedStringArray = []
	var where := "boss_skills.bosses.%s" % kind
	if not boss is Dictionary or not content.enemy(kind).get("boss", false):
		return PackedStringArray([where + ": not a boss"])
	var band: Array = TIERS.get(str(boss.get("tier")), [])
	if band.is_empty():
		return PackedStringArray([where + ".tier: one of %s" % [TIERS.keys()]])
	var ids: Array = boss.get("skills", [])
	var ults := ids.filter(func(id: Variant) -> bool: return is_ultimate(skill(content, str(id))))
	var plain := ids.size() - ults.size()
	if plain < int(band[0]) or plain > int(band[1]):
		out.append("%s: %d to %d skills for a %s" % [where, band[0], band[1], boss["tier"]])
	if ults.size() != ULTIMATES:
		out.append("%s: exactly %d Ultimate (has %d)" % [where, ULTIMATES, ults.size()])
	var types := {}
	for id: Variant in ids:
		var data := skill(content, str(id))
		if data.is_empty():
			out.append("%s: unknown skill %s" % [where, id])
			continue
		if listed.has(str(id)):
			out.append("%s: %s is listed twice" % [where, id])
		listed[str(id)] = true
		if str(data.get("owner")) != kind:
			out.append("%s: %s belongs to %s" % [where, id, data.get("owner")])
		var prefix := "%s_%s_" % [PREFIX[str(boss["tier"])], kind.to_upper()]
		if not str(id).begins_with(prefix):
			out.append("%s: %s should start %s" % [where, id, prefix])
		types[str(data.get("type"))] = true
	if types.size() < mini(ids.size(), 3):
		out.append(where + ": at least three kinds of skill")
	return out


static func _skill_problems(
	content: ContentDB, id: String, data: Variant, taken: Dictionary
) -> PackedStringArray:
	var out: PackedStringArray = []
	var where := "boss_skills.skills.%s" % id
	if not data is Dictionary:
		return PackedStringArray([where + ": expected an object"])
	if content.skills.has(id):
		out.append(where + ": a hero's skill id")
	if not content.enemy(str(data.get("owner", ""))).get("boss", false):
		out.append(where + ".owner: not a boss")
	if str(data.get("name", "")) == "":
		out.append(where + ".name: required")
	if str(data.get("type")) not in TYPES:
		out.append(where + ".type: one of %s" % [TYPES])
		return out
	if int(data.get("cooldown", 0)) < MIN_COOLDOWN:
		out.append("%s.cooldown: at least %d ticks" % [where, MIN_COOLDOWN])
	var phases: Array = content.enemy(str(data.get("owner", ""))).get("phases", [])
	var phase := int(data.get("phase", -1))
	if phase < 0 or phase > phases.size():
		out.append("%s.phase: 0 to %d" % [where, phases.size()])
	var span: Array = data.get("range", [])
	if span.size() != 2 or float(span[0]) < 0.0 or float(span[0]) > float(span[1]):
		out.append(where + ".range: [min, max], 0 <= min <= max")
	out.append_array(_move_problems(content, id, data, taken))
	out.append_array(_look_problems(content, where, data))
	if is_ultimate(data) or str(data["type"]) == "ultimate":
		out.append_array(_ultimate_problems(content, where, data))
	elif str(data["type"]) == "summon":
		var summon: Dictionary = data.get("summon", {})
		if content.enemy(str(summon.get("enemy", ""))).is_empty():
			out.append(where + ".summon.enemy: unknown")
		if int(summon.get("count", 0)) < 1 or int(summon.get("max", 0)) < 1:
			out.append(where + ".summon: count and max at least 1")
	elif is_cast(data):
		var hazard: Dictionary = data.get("hazard", {})
		if str(hazard.get("kind")) not in BossMechanics.KINDS:
			out.append(where + ".hazard.kind: one of %s" % [BossMechanics.KINDS])
		if int(hazard.get("warn", 0)) < MIN_WARN:
			out.append("%s.hazard.warn: at least %d ticks" % [where, MIN_WARN])
		if int(hazard.get("damage", 0)) < 1 or (hazard.get("half", []) as Array).size() != 2:
			out.append(where + ".hazard: damage and half [x, y] required")
	return out


static func _ultimate_problems(
	content: ContentDB, where: String, data: Dictionary
) -> PackedStringArray:
	var out: PackedStringArray = []
	if not is_ultimate(data) or str(data.get("type")) != "ultimate":
		out.append(where + ": an Ultimate is type ultimate with ultimate: true")
	if int(data.get("cooldown", 0)) < ULT_MIN_COOLDOWN:
		out.append("%s.cooldown: an Ultimate at least %d ticks" % [where, ULT_MIN_COOLDOWN])
	var owner := content.enemy(str(data.get("owner", "")))
	var light := content.moves.get_move(str(owner.get("moveset", {}).get("light", "")))
	var waves: Array = data.get("waves", [])
	if waves.is_empty() or waves.size() > 4:
		out.append(where + ".waves: one to four")
	for i in waves.size():
		var wave: Dictionary = waves[i]
		var at := "%s.waves[%d]" % [where, i]
		if str(wave.get("kind")) not in BossMechanics.KINDS:
			out.append(at + ".kind: one of %s" % [BossMechanics.KINDS])
		if int(wave.get("warn", 0)) < ULT_MIN_WARN:
			out.append("%s.warn: at least %d ticks" % [at, ULT_MIN_WARN])
		var tiles := (wave.get("offsets", []) as Array).size() + int(wave.get("count", 0))
		if tiles < 1 or tiles > ULT_MAX_TILES:
			out.append("%s: 1 to %d tiles" % [at, ULT_MAX_TILES])
		var damage := float(wave.get("damage", 0))
		if (
			light
			and (damage < light.damage * ULT_DAMAGE[0] or damage > light.damage * ULT_DAMAGE[1])
		):
			out.append(
				"%s.damage: %s to %s times the basic blow" % [at, ULT_DAMAGE[0], ULT_DAMAGE[1]]
			)
	var strongest := 0
	for other in of(content, str(data.get("owner", ""))):
		if not is_ultimate(skill(content, other)) and not skill(content, other).has("summon"):
			strongest = maxi(strongest, damage(content, other))
	var total := 0
	for wave: Dictionary in waves:
		total += int(wave.get("damage", 0))
	if waves.size() >= 2 and total < strongest * ULT_SIGNATURE:
		out.append("%s: all waves at least %s times the strongest skill" % [where, ULT_SIGNATURE])
	var cast := content.moves.get_move(str(data.get("moves", [""])[0]))
	if cast and cast.anim in ["light", "heavy"]:
		out.append(where + ": an Ultimate has its own animation (not light or heavy)")
	return out


static func _move_problems(
	content: ContentDB, id: String, data: Dictionary, taken: Dictionary
) -> PackedStringArray:
	var out: PackedStringArray = []
	var where := "boss_skills.skills.%s.moves" % id
	var moves: Array = data.get("moves", [])
	if moves.is_empty():
		return PackedStringArray([where + ": at least one"])
	for i in moves.size():
		var move := content.moves.get_move(str(moves[i]))
		if move == null:
			out.append("%s: unknown move %s" % [where, moves[i]])
			continue
		if taken.get(move.id, id) != id:
			out.append("%s: %s is also %s's" % [where, move.id, taken[move.id]])
		taken[move.id] = id
		if is_cast(data):
			if move.damage != 0 or moves.size() != 1:
				out.append(where + ": a cast is one wind-up without a hitbox (damage 0)")
			continue
		if move.damage < 1 or move.reach <= 0.0:
			out.append("%s: %s needs damage and a hitbox" % [where, move.id])
		var least := MIN_HEAVY_WINDUP if move.knockdown else MIN_LIGHT_WINDUP
		if i == 0:
			least = maxi(least, MIN_OPENER_WINDUP)
		if move.advance >= EnemyBrain.CHARGE_ADVANCE:
			least = maxi(least, MIN_CHARGE_WINDUP)
			if move.active > CombatRules.DODGE_IFRAME_END - CombatRules.DODGE_IFRAME_START:
				out.append("%s: %s, a charge, is active no longer than a roll" % [where, move.id])
		if move.startup < least:
			out.append("%s: %s winds up at least %d ticks" % [where, move.id, least])
		if i + 1 < moves.size():
			var next := content.moves.get_move(str(moves[i + 1]))
			if next and escape_window(move, next) < MIN_ESCAPE:
				out.append("%s: after %s, %d ticks to escape" % [where, move.id, MIN_ESCAPE])
	return out


## A combo's window to escape after `hit` lands on its first active tick:
## ticks between the hero recovering and `next` landing.
static func escape_window(hit: MoveData, next: MoveData) -> int:
	return hit.active + hit.recovery + next.startup - hit.hitstun


static func _look_problems(
	content: ContentDB, where: String, data: Dictionary
) -> PackedStringArray:
	var out: PackedStringArray = []
	var fx := str(data.get("fx", ""))
	if fx == "" and not is_cast(data):
		out.append(where + ".fx: a blow needs its effect")
	if fx != "" and not content.fx.get("effects", {}).has(fx):
		out.append(where + ".fx: no such effect")
	if not content.audio.get("sounds", {}).has(str(data.get("sound"))):
		out.append(where + ".sound: no such sound")
	return out


## Moves already owned outside the boss catalogue: the heroes' skills (every
## blow, its later blows and its grab's throw, crash, shove and squeeze; a
## passive has none), the jobs' movesets and grabs, every enemy's moveset (and
## its phases') and the weapons'. Boss skill moves must be none of them.
static func _moves_taken(content: ContentDB) -> Dictionary:
	var taken := {}
	for id: String in content.skills:
		var skill: Dictionary = content.skills[id]
		_claim(taken, SkillSequence.moves(skill), "hero skill " + id)
		var grab: Variant = skill.get("grab", {})
		if grab is Dictionary:
			_claim(taken, (grab as Dictionary).values(), "hero skill " + id)
	for job: String in content.jobs:
		var data: Dictionary = content.jobs[job]
		for part: String in ["moveset", "grab"]:
			var named: Variant = data.get(part, {})
			if named is Dictionary:
				_claim(taken, (named as Dictionary).values(), "job " + job)
	for kind: String in content.enemies:
		var data := content.enemy(kind)
		var sets: Array = [data.get("moveset", {})]
		for phase: Dictionary in data.get("phases", []):
			sets.append(phase.get("moveset", {}))
		for moveset: Dictionary in sets:
			for move_id: Variant in moveset.values():
				taken[str(move_id)] = "enemy " + kind
	for weapon_id: String in content.weapons:
		for move_id: Variant in content.weapons[weapon_id].get("moveset", {}).values():
			taken[str(move_id)] = "weapon " + weapon_id
	return taken


## Marks the move ids among `values` (other values, such as tick counts, are
## skipped) as owned by `owner`.
static func _claim(taken: Dictionary, values: Array, owner: String) -> void:
	for value: Variant in values:
		if value is String:
			taken[value] = owner
