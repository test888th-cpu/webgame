class_name WorldBossFlow
extends RefCounted
## Steps of a world boss attempt in the game scene that do not need to live
## in Game.gd (which is at the file-length limit).


## The attempt is over: bank its damage, pay new tiers (and the kill), show
## what it won.
static func finish(game: Game) -> void:
	var run := game.world_run
	run.banked = true  # once: the street (and step) goes on behind the result
	var paid := WorldBossRules.award(
		game.profile,
		game.content,
		run.boss,
		run.round,
		run.dealt,
		run.total,
		run.level,
		game._world_rng,
		run.ended == "slain"
	)
	SaveStore.save(game.profile)
	if run.ended == "left":
		game.world_run = null
		game._hud.toast("You left the fight. Damage banked.")
		return
	game._show("world_boss", GameMenus.world_boss_result(game, run, paid))
