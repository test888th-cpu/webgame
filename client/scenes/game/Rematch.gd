class_name Rematch
extends RefCounted
## Presentation glue for story boss rematches (ReplayRules): Win's taxi
## ("Rematches" rides), the game menu ("Fight ... again") and the knock-out
## screen ("Try again"). The rules decide what is open and what the area holds;
## this only charges what a player already pays (the fare, a knock-out's
## dropped coins) and takes the hero there.


## Takes the hero to boss fight `index` of `area_id`, fresh, in their own
## story instance. Returns false (and says why) when it is not open.
static func start(game: Game, area_id: String, index: int) -> bool:
	var x := ReplayRules.rematch(game.profile, game.content, area_id, index)
	if x < 0.0:
		game._hud.toast("That fight is not open yet.")
		Sfx.play("denied", -4.0)
		return false
	game.close_menu()
	game.enter_area(area_id, "west", x)
	var foe := ReplayRules.foe(game.content, area_id, index)
	game._hud.toast("Rematch: %s" % game.content.enemy(foe).get("name", foe))
	SaveStore.save(game.profile)
	return true


## Win's taxi: the fare, as for any ride, then the rematch.
static func ride(game: Game, npc: Dictionary, area_id: String, index: int) -> void:
	var open := ReplayRules.unlocked(game.profile, game.content, area_id, index)
	if open and not EconomyRules.charge(game.profile, int(npc.get("fare", 0))):
		game._hud.toast("Not enough coins for the ride")
		Sfx.play("denied", -4.0)
		return
	start(game, area_id, index)


## The game menu: the boss fight nearest the hero in this area, again, from
## anywhere outside a fight. -1 when there is none here.
static func here(game: Game) -> int:
	if game.zone == null:
		return -1
	var index := ReplayRules.nearest(game.content, game.zone.area_id, game.zone.hero.position.x)
	return (
		index if ReplayRules.unlocked(game.profile, game.content, game.zone.area_id, index) else -1
	)


## The knock-out screen's "Try again": the same coins dropped and the same
## full health as getting back up in the city (Game._recover), then straight
## back into the fight that was lost. No wait and no limit.
static func retry(game: Game, index: int) -> void:
	EconomyRules.charge(game.profile, EconomyRules.defeat_loss(game.profile, game.content))
	game.profile.hp = game.profile.stats(game.content)["max_hp"]
	start(game, game.zone.area_id, index)
