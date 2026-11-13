class_name AutoSkills
extends RefCounted
## What auto battle needs to know about the hero's skills to choose among
## them as a player would: how hard a skill hits in all (a grab on a boss or
## mini-boss only shoves, so it is worth only its shove), which skills are
## counter stances (answers to an attack, never openers), which only brace
## the hero, which need a full gauge, and how a combo route weighs a skill.
## Reads the same data the rules use.

const LINK_WEIGHT := 3.0
const OPENER_WEIGHT := 1.3
## A further ready link of the route a next skill leads into adds this share.
const LONG_ROUTE_BONUS := 0.5
## A route's later link alone, while its opener is ready within HOLD_TICKS.
const HOLD_WEIGHT := 0.4
const HOLD_TICKS := 60


## Damage of all of `skill`'s blows together on `target` (a Fighter.skills
## entry): its moves, and for a skill that grabs its throw, or only its
## shove when `target` cannot be held (a boss or mini-boss).
static func power(
	content: ContentDB, hero: Fighter, skill: Dictionary, target: Fighter = null
) -> float:
	var sum := 0.0
	for id: String in SkillSequence.moves(skill):
		var move := content.moves.get_move(id)
		sum += move.damage if move else 0
	var first := content.moves.get_move(str(skill.get("move", "")))
	if first != null and first.grab:
		var plan: Dictionary = skill.get("grab", {})
		var held := target == null or GrabRules.can_hold(target)
		var blow := "throw" if held else "shove"
		var landed := content.moves.get_move(str(plan.get(blow, hero.grab.get(blow, ""))))
		sum += landed.damage if landed else 0
	return sum * float(skill.get("scale", {}).get("damage", 1.0))


static func is_stance(content: ContentDB, skill: Dictionary) -> bool:
	var first := content.moves.get_move(str(skill.get("move", "")))
	return first != null and first.counter


## The counter stance worth taking against a blow landing in `ticks` ticks:
## ready, affordable, open when the blow arrives, the hardest reply first.
## "" when there is none.
static func stance(content: ContentDB, hero: Fighter, ticks: int) -> String:
	var best := ""
	var best_power := 0.0
	var ids: Array = hero.skills.keys()
	ids.sort()
	for skill_id: String in ids:
		var skill: Dictionary = hero.skills[skill_id]
		if not is_stance(content, skill) or hero.cooldown_left(skill_id) > 0:
			continue
		var first := content.moves.get_move(str(skill["move"]))
		if hero.energy < first.energy_cost or not UltimateRules.ready(hero, skill):
			continue
		if ticks < first.startup + 1 or ticks > first.startup + first.active - 2:
			continue
		var hits := power(content, hero, skill)
		if hits > best_power:
			best_power = hits
			best = skill_id
	return best


## A skill that only braces the hero (a buff with no blow of its own), ready
## to use now; "" when there is none.
static func brace(content: ContentDB, hero: Fighter) -> String:
	for skill_id: String in hero.skills:
		var skill: Dictionary = hero.skills[skill_id]
		var first := content.moves.get_move(str(skill.get("move", "")))
		if first == null or first.grab or first.counter:
			continue
		if power(content, hero, skill) > 0.0 or hero.cooldown_left(skill_id) > 0:
			continue
		if hero.energy >= first.energy_cost and not hero.stacks.has("buff:" + skill_id):
			return skill_id
	return ""


## How much auto battle favours `skill_id` for combos (ComboRules):
## - the next skill of a route the hero is on counts LINK_WEIGHT times, and
##   LONG_ROUTE_BONUS more for each further link of that route when all of
##   them are ready (so a shared opener goes on into the longer route);
## - the first skill of a route whose other skills are ready, OPENER_WEIGHT;
## - a later link of a route, used on its own while its route is not under
##   way and its opener will be ready within HOLD_TICKS, only HOLD_WEIGHT:
##   it is kept for the route instead of being spent alone. (Holding harder,
##   0.1 within 150 ticks, measured worse: more damage taken, fewer kills.)
static func combo_weight(hero: Fighter, skill_id: String) -> float:
	if skill_id in ComboRules.next_links(hero):
		return LINK_WEIGHT * (1.0 + LONG_ROUTE_BONUS * _ready_beyond(hero, skill_id))
	var opener := false
	var held := false
	for route: Dictionary in hero.combos:
		var links: Array = route["links"]
		var at := links.find(skill_id)
		if at == 0:
			var ready := true
			for later: Variant in links.slice(1):
				ready = ready and hero.skills.has(later) and hero.cooldown_left(str(later)) == 0
			opener = opener or ready
		elif at > 0 and hero.cooldown_left(str(links[0])) <= HOLD_TICKS:
			held = true
	if opener:
		return OPENER_WEIGHT
	return HOLD_WEIGHT if held else 1.0


## The most further links, all ready, of a route the hero is on whose next
## skill is `skill_id`.
static func _ready_beyond(hero: Fighter, skill_id: String) -> int:
	var most := 0
	var size := hero.combo_chain.size()
	for route: Dictionary in hero.combos:
		var links: Array = route["links"]
		if links.size() <= size or links.slice(0, size) != hero.combo_chain:
			continue
		if str(links[size]) != skill_id:
			continue
		var beyond := links.slice(size + 1)
		var ready := true
		for later: Variant in beyond:
			ready = ready and hero.skills.has(later) and hero.cooldown_left(str(later)) == 0
		if ready:
			most = maxi(most, beyond.size())
	return most
