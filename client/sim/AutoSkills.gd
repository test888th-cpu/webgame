class_name AutoSkills
extends RefCounted
## What auto battle needs to know about the hero's skills to choose among
## them as a player would: how hard a skill hits in all, which skills are
## counter stances (answers to an attack, never openers), which only brace
## the hero, and which need a full gauge. Reads the same data the rules use.


## Damage of all of `skill`'s blows together on one target (a Fighter.skills
## entry): its moves, and the throw of a skill that grabs.
static func power(content: ContentDB, hero: Fighter, skill: Dictionary) -> float:
	var sum := 0.0
	for id: String in SkillSequence.moves(skill):
		var move := content.moves.get_move(id)
		sum += move.damage if move else 0
	var first := content.moves.get_move(str(skill.get("move", "")))
	if first != null and first.grab:
		var plan: Dictionary = skill.get("grab", {})
		var throw := content.moves.get_move(str(plan.get("throw", hero.grab.get("throw", ""))))
		sum += throw.damage if throw else 0
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
