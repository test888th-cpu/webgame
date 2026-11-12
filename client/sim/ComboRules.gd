class_name ComboRules
extends RefCounted
## Skill combos: each job's routes of two or three skills (jobs.json
## "skill_combos"). Using a route's skills in order, each one started within
## the route's "window" ticks of the last one landing a blow (or a hold),
## completes the route: its last skill hits "bonus" harder, the ultimate gauge
## gains "gauge", and the zone reports it ("combo" on the hit). A route only
## counts what lands: a skill that misses, or a stance nobody hits, breaks the
## chain, and so does being hit.
##
## Also the hit chain: blows landed one after another, each within
## HIT_CHAIN_TICKS of the last, until the fighter is hit. Shown on the HUD;
## it changes no outcome.
##
## Combat state on the Fighter (combos, combo_*), never saved. Pure rules,
## shared with the server.

## Ticks a hit chain stays alive without another blow landing.
const HIT_CHAIN_TICKS := 120
const MIN_LINKS := 2
const MAX_LINKS := 3
const MIN_WINDOW := 30
const MAX_WINDOW := 240
## A route's extra damage on its last skill, and its gauge, stay in these.
const MAX_BONUS := 1.0
const MAX_GAUGE := 25.0


## The routes `hero_id` has at `level`, as Fighter.combos holds them: {"id",
## "name", "links", "window", "bonus" (scaled for `mode`), "gauge"}.
static func unlocked(
	content: ContentDB, hero_id: String, level: int, mode := BalanceProfile.PVE
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var job: Dictionary = content.jobs.get(JobRules.job_of(content, hero_id), {})
	for route: Variant in job.get("skill_combos", []):
		if not route is Dictionary or level < int(route.get("unlock_level", 1)):
			continue
		(
			out
			. append(
				{
					"id": str(route["id"]),
					"name": str(route["name"]),
					"links": route["links"].duplicate(),
					"window": int(route["window"]),
					"bonus": float(route["bonus"]) * BalanceProfile.scale(route, mode, "damage"),
					"gauge": float(route.get("gauge", 0.0)),
				}
			)
		)
	return out


## Every route of the job of `hero_id`, unlocked or not (for screens).
static func routes(content: ContentDB, hero_id: String) -> Array:
	var job: Dictionary = content.jobs.get(JobRules.job_of(content, hero_id), {})
	return job.get("skill_combos", [])


## `f` started skill `skill_id`: it continues the chain, starts a new one, or
## (in no route) clears it. A route whose last link this is becomes the
## finisher the next landed blows are judged by.
static func on_skill(f: Fighter, skill_id: String) -> void:
	f.combo_finish = {}
	var chain: Array = f.combo_chain.duplicate()
	var going := not chain.is_empty() and f.combo_landed and f.combo_timer > 0
	chain = chain + [skill_id] if going else [skill_id]
	if not _is_prefix(f, chain):
		chain = [skill_id] if _is_prefix(f, [skill_id]) else []
	f.combo_chain = chain
	f.combo_landed = false
	f.combo_timer = 0
	for route: Dictionary in f.combos:
		if route["links"] == chain:
			f.combo_finish = route.duplicate()
			f.combo_shown = false


## A blow of `move` from `f` landed on someone (unblocked): the hit chain
## grows and the chain's latest link has landed.
static func on_hit(f: Fighter, move: MoveData) -> void:
	if f.combos.is_empty():
		return
	f.hit_chain += 1
	f.hit_chain_timer = HIT_CHAIN_TICKS
	if move != null and move.slam and move.id == _finish_throw(f):
		f.combo_finish["thrown"] = true
	_land(f)


## `f` seized someone with a grab: for a route, that is the link landing.
static func on_hold(f: Fighter) -> void:
	if not f.combos.is_empty():
		_land(f)


## A route `f` completed since the last report, as a "combo" zone event.
static func report(f: Fighter, events: Array[ZoneEvent]) -> void:
	if f.combo_done == "":
		return
	for route: Dictionary in f.combos:
		if route["id"] == f.combo_done:
			var data := {"id": f.id, "combo": route["id"], "name": route["name"]}
			events.append(ZoneEvent.make("combo", data))
	f.combo_done = ""


## `f` was hit, held or knocked out: the chain and the hit chain end.
static func on_hurt(f: Fighter) -> void:
	if f.combos.is_empty() and f.hit_chain == 0:
		return
	reset(f)
	f.hit_chain = 0
	f.hit_chain_timer = 0


static func reset(f: Fighter) -> void:
	f.combo_chain = []
	f.combo_landed = false
	f.combo_timer = 0
	f.combo_finish = {}


## One tick. A hold does not use up a window: the throw comes after it.
static func tick(f: Fighter) -> void:
	if f.hit_chain_timer > 0:
		f.hit_chain_timer -= 1
		if f.hit_chain_timer == 0:
			f.hit_chain = 0
	if f.combo_timer > 0 and f.state != Fighter.State.GRAB:
		f.combo_timer -= 1
		if f.combo_timer == 0:
			reset(f)


## The extra share of damage a blow of `move` from `f` deals: the route's
## bonus while its last skill is the one swinging (or its throw is landing).
static func bonus(f: Fighter, move: MoveData) -> float:
	if f.combo_finish.is_empty():
		return 0.0
	var finisher := str(f.combo_finish["links"][-1])
	if f.skill_id == finisher and f.state == Fighter.State.ATTACK:
		return float(f.combo_finish["bonus"])
	# A finishing grab's throw lands after the skill is over: once.
	if move != null and move.slam and not f.combo_finish.get("thrown", false):
		if move.id == _finish_throw(f) or move.id == _finish_crash(f):
			return float(f.combo_finish["bonus"])
	return 0.0


## The throw (and the crash of its body into others) of the finishing skill
## when it grabs: the skill's own, or the job's for a bare grab.
static func _finish_throw(f: Fighter) -> String:
	return _finish_grab(f, "throw")


static func _finish_crash(f: Fighter) -> String:
	return _finish_grab(f, "crash")


static func _finish_grab(f: Fighter, field: String) -> String:
	if f.combo_finish.is_empty():
		return ""
	var skill: Dictionary = f.skills.get(str(f.combo_finish["links"][-1]), {})
	var plan: Dictionary = skill.get("grab", {})
	return str(plan.get(field, f.grab.get(field, "")))


## The skills that would carry `f`'s chain on if started now.
static func next_links(f: Fighter) -> Array[String]:
	var out: Array[String] = []
	if f.combo_chain.is_empty() or not f.combo_landed or f.combo_timer <= 0:
		return out
	var size := f.combo_chain.size()
	for route: Dictionary in f.combos:
		var links: Array = route["links"]
		if links.size() > size and links.slice(0, size) == f.combo_chain:
			out.append(str(links[size]))
	return out


## Damage of a route on one target, before power: its skills' blows (a bare
## grab counts the job's throw) and the last skill's bonus. For balance.
static func route_damage(content: ContentDB, job_id: String, route: Dictionary) -> float:
	var sum := 0.0
	var last := 0.0
	for skill_id: Variant in route.get("links", []):
		last = skill_damage(content, job_id, str(skill_id))
		sum += last
	return sum + last * float(route.get("bonus", 0.0))


## Damage of all of one skill's blows on one target (its moves, a grab's
## throw or squeezes), with any bonus of its own on a staggered foe.
static func skill_damage(content: ContentDB, job_id: String, skill_id: String) -> float:
	var skill: Dictionary = content.skills.get(skill_id, {})
	var sum := 0.0
	for id: String in SkillSequence.moves(skill):
		var move := content.moves.get_move(id)
		sum += move.damage if move else 0
	var plan: Dictionary = skill.get("grab", {})
	var first := content.moves.get_move(str(skill.get("move", "")))
	var throw_id := str(plan.get("throw", ""))
	if throw_id == "" and first != null and first.grab:
		throw_id = str(content.jobs.get(job_id, {}).get("grab", {}).get("throw", ""))
	var throw := content.moves.get_move(throw_id)
	sum += throw.damage if throw else 0
	var squeeze := content.moves.get_move(str(plan.get("squeeze", "")))
	if squeeze and int(plan.get("every", 0)) > 0:
		sum += (int(plan["hold"]) - 1) / int(plan["every"]) * squeeze.damage
	var own: Dictionary = skill.get("bonus", {})
	return sum * (1.0 + float(own.get("effects", {}).get("damage", 0.0)))


static func _land(f: Fighter) -> String:
	if f.combo_chain.is_empty() or str(f.combo_chain[-1]) != f.skill_id:
		return ""
	var first := not f.combo_landed
	f.combo_landed = true
	f.combo_timer = _window(f)
	if first and not f.combo_finish.is_empty() and not f.combo_shown:
		f.combo_shown = true
		f.combo_done = str(f.combo_finish["id"])
		UltimateRules.fill(f, float(f.combo_finish["gauge"]))
		return f.combo_done
	return ""


## The longest window among the routes the chain is still on.
static func _window(f: Fighter) -> int:
	var most := 0
	for route: Dictionary in f.combos:
		if _starts(route, f.combo_chain):
			most = maxi(most, int(route["window"]))
	return most


static func _is_prefix(f: Fighter, chain: Array) -> bool:
	for route: Dictionary in f.combos:
		if _starts(route, chain):
			return true
	return false


static func _starts(route: Dictionary, chain: Array) -> bool:
	var links: Array = route["links"]
	return links.size() >= chain.size() and links.slice(0, chain.size()) == chain


## What is wrong with a job's routes (jobs.json "skill_combos").
static func problems(content: ContentDB, job_id: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var job: Dictionary = content.jobs.get(job_id, {})
	var where := "jobs.%s.skill_combos" % job_id
	var list: Variant = job.get("skill_combos")
	if not list is Array or list.is_empty():
		out.append(where + ": expected a list of routes")
		return out
	var kit: Array = job.get("skills", [])
	var ids := {}
	var all_links: Array = []
	for i in list.size():
		var route: Variant = list[i]
		var here := "%s[%d]" % [where, i]
		if not route is Dictionary:
			out.append(here + ": expected an object")
			continue
		var id := str(route.get("id", ""))
		if id == "" or ids.has(id):
			out.append(here + ".id: required and unique")
		ids[id] = true
		if str(route.get("name", "")) == "" or str(route.get("description", "")) == "":
			out.append(here + ": name and description required")
		out.append_array(_link_problems(content, route, kit, here))
		all_links.append(route.get("links", []))
		var window: Variant = route.get("window")
		if not (window is float or window is int) or window < MIN_WINDOW or window > MAX_WINDOW:
			out.append("%s.window: %d to %d ticks" % [here, MIN_WINDOW, MAX_WINDOW])
		var extra: Variant = route.get("bonus")
		if not (extra is float or extra is int) or extra <= 0 or extra > MAX_BONUS:
			out.append("%s.bonus: above 0, at most %s" % [here, MAX_BONUS])
		var gauge: Variant = route.get("gauge", 0)
		if not (gauge is float or gauge is int) or gauge < 0 or gauge > MAX_GAUGE:
			out.append("%s.gauge: 0 to %d" % [here, MAX_GAUGE])
		out.append_array(BalanceProfile.problems(route, here))
	for a: Variant in all_links:
		for b: Variant in all_links:
			if a is Array and b is Array and a != b and b.size() > a.size():
				if b.slice(0, a.size()) == a:
					out.append("%s: %s is the start of another route" % [where, a])
	return out


static func _link_problems(
	content: ContentDB, route: Dictionary, kit: Array, here: String
) -> PackedStringArray:
	var out: PackedStringArray = []
	var links: Variant = route.get("links")
	if not links is Array or links.size() < MIN_LINKS or links.size() > MAX_LINKS:
		out.append("%s.links: %d to %d skills" % [here, MIN_LINKS, MAX_LINKS])
		return out
	var highest := 1
	var seen := {}
	for skill_id: Variant in links:
		var skill: Dictionary = content.skills.get(str(skill_id), {})
		if str(skill_id) not in kit or str(skill.get("type", "")) != "active":
			out.append("%s.links: %s is not an active skill of this job" % [here, skill_id])
			continue
		if seen.has(skill_id):
			out.append("%s.links: %s twice" % [here, skill_id])
		seen[skill_id] = true
		highest = maxi(highest, int(skill.get("unlock_level", 1)))
	var level: Variant = route.get("unlock_level")
	if not (level is float or level is int) or int(level) < highest:
		out.append("%s.unlock_level: at least %d (its last skill to unlock)" % [here, highest])
	return out
