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


## How much auto battle favours `skill_id` for combos (ComboRules): the next
## skill of a route the hero is on counts LINK_WEIGHT times; the first skill
## of a route whose other skills are ready, OPENER_WEIGHT times.
static func combo_weight(hero: Fighter, skill_id: String) -> float:
	if skill_id in ComboRules.next_links(hero):
		return LINK_WEIGHT
	for route: Dictionary in hero.combos:
		var links: Array = route["links"]
		if str(links[0]) != skill_id:
			continue
		var ready := true
		for later: Variant in links.slice(1):
			ready = ready and hero.skills.has(later) and hero.cooldown_left(str(later)) == 0
		if ready:
			return OPENER_WEIGHT
	return 1.0
