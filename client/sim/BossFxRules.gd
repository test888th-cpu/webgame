class_name BossFxRules
extends RefCounted
## How a boss's fight looks, from data/boss_fx.json: every boss has a theme
## (brawl, fire, toxic, tech, shadow) whose glow warns of its heavy blows,
## and the effects of heavy blows landing, hazards by kind, shields, summons
## and the boss's defeat are named once for all. Presentation data only (the
## effect ids are the manifest's), checked on load so a new boss or hazard
## cannot go without its effects.

## The effect that warns of boss `enemy_id`'s heavy blow, or "".
## How loudly a hazard warns (boss_fx.json "telegraph"), and what it is set for.
const TELEGRAPH_LEVELS: Array[String] = ["none", "minimal", "full"]
const TELEGRAPH_SOURCES: Array[String] = ["ultimate", "skill", "cycle"]


static func windup(content: ContentDB, enemy_id: String) -> String:
	var theme := str(content.boss_fx.get("bosses", {}).get(enemy_id, ""))
	return str(content.boss_fx.get("themes", {}).get(theme, {}).get("windup", ""))


## The effect a hazard of `kind` lands with, or "".
static func hazard(content: ContentDB, kind: String) -> String:
	return str(content.boss_fx.get("hazards", {}).get(kind, ""))


## One of the shared effects ("heavy_impact", "defeat", "summon", "shield",
## "shield_break"), or "".
static func effect(content: ContentDB, field: String) -> String:
	return str(content.boss_fx.get(field, ""))


## What is wrong with boss_fx.json, one message each: an effect it names that
## does not exist, a boss without a theme, a hazard kind without an effect.
static func problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var effects: Dictionary = content.fx.get("effects", {})
	var named: Array = []
	for theme: Variant in content.boss_fx.get("themes", {}).values():
		named.append(str(theme.get("windup", "")) if theme is Dictionary else "")
	for field in ["heavy_impact", "defeat", "summon", "shield", "shield_break"]:
		named.append(effect(content, field))
	named.append_array(content.boss_fx.get("hazards", {}).values())
	for id: Variant in named:
		if not effects.has(str(id)):
			out.append("boss_fx: no effect %s" % id)
	var kinds := {}
	for id: String in content.enemies:
		var enemy: Variant = content.enemies[id]
		if not enemy is Dictionary or not enemy.get("boss", false):
			continue
		if windup(content, id) == "":
			out.append("boss_fx.bosses.%s: a theme for every boss" % id)
		for block: Variant in [enemy] + enemy.get("phases", []):
			var rule: Variant = block.get("hazard", {}) if block is Dictionary else {}
			if not rule is Dictionary or rule.is_empty():
				continue
			if not rule.has("cycle"):
				kinds[str(rule.get("kind", "crane"))] = true
			for step: Variant in rule.get("cycle", []):
				kinds[str(step.get("kind", "crane"))] = true
	for kind: String in kinds:
		if hazard(content, kind) == "":
			out.append("boss_fx.hazards: no effect for %s" % kind)
	out.append_array(telegraph_problems(content))
	return out


## What is wrong with boss_fx.json "telegraph" (presentation only: how loudly
## a hazard warns): each of "ultimate", "skill" and "cycle" one of LEVELS;
## "skills" optionally sets a level per boss skill id. A level of "none" is
## refused for any skill that calls a hazard: its warning is what makes it fair.
static func telegraph_problems(content: ContentDB) -> PackedStringArray:
	var out: PackedStringArray = []
	var rules: Variant = content.boss_fx.get("telegraph", {})
	if not rules is Dictionary:
		out.append("boss_fx.telegraph: expected an object")
		return out
	for key: String in rules:
		if key == "skills":
			continue
		if key not in TELEGRAPH_SOURCES:
			out.append("boss_fx.telegraph.%s: unknown key" % key)
		elif str(rules[key]) not in TELEGRAPH_LEVELS:
			out.append(_bad_level("boss_fx.telegraph.%s" % key, rules[key]))
	var skills: Variant = rules.get("skills", {})
	if not skills is Dictionary:
		out.append("boss_fx.telegraph.skills: expected an object")
		return out
	for id: String in skills:
		var data := BossSkillRules.skill(content, id)
		var where := "boss_fx.telegraph.skills.%s" % id
		if data.is_empty():
			out.append(where + ": no such boss skill")
			continue
		where += " (%s)" % str(data.get("owner", ""))
		var level := str(skills[id])
		if level not in TELEGRAPH_LEVELS:
			out.append(_bad_level(where, skills[id]))
		elif level == "none" and (data.has("hazard") or data.has("waves")):
			out.append(where + ": a hazard's warning cannot be none")
	return out


static func _bad_level(where: String, value: Variant) -> String:
	return '%s: "%s" is not one of %s' % [where, value, ", ".join(TELEGRAPH_LEVELS)]
