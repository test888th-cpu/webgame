class_name SkillPress
extends RefCounted
## Pressing a skill (a hotbar slot or the ultimate key): puts it into this
## tick's input when it can fire, and tells the player why when it cannot.
## The checks here are feedback only; the simulation decides again.


## True when `skill_id` went into `input`.
static func try(game: Game, skill_id: String, input: FighterInput) -> bool:
	var content := game.content
	var hero := game.zone.hero
	if not content.skills.has(skill_id):
		return false
	var skill: Dictionary = content.skills[skill_id]
	if not hero.skills.has(skill_id):
		game._hud.toast("%s unlocks at level %d" % [skill["name"], skill["unlock_level"]])
		return false
	if hero.cooldown_left(skill_id) > 0:
		return false
	if not UltimateRules.ready(hero, hero.skills[skill_id]):
		game._hud.toast("The ultimate gauge is not full yet. Keep fighting.")
		return false
	if GrabRules.barred(hero, content.moves.get_move(str(skill["move"]))):
		game._hud.toast("Hands full: press G to drop the weapon, then grab.")
		return false
	if hero.energy < SkillRules.energy_cost(content, skill_id):
		game._hud.flash_energy()
		return false
	input.skill = skill_id
	return true


## The ultimate key: the hero's ultimate, wherever it is (or is not) on the bar.
static func ultimate(game: Game, input: FighterInput) -> void:
	var skill_id := SkillRules.ultimate(game.content, game.profile.hero)
	if skill_id != "" and not try(game, skill_id, input):
		Sfx.play("denied", -4.0)
