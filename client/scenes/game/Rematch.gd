class_name Rematch
extends RefCounted
## Presentation glue for story boss and story mini-boss replays (ReplayRules):
## Win's taxi ("Boss Fights" rides), the game menu ("Fight ... again") and the
## knock-out screen ("Try again"). The rules decide what is open and what the
## area holds; this takes the hero there. A replay itself is free: only the
## taxi charges, its usual fare for the ride.


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


## The knock-out screen's "Try again": free (no coins dropped, unlike getting
## back up in the city), at full health, straight back into the boss fight
## that was lost. No wait and no limit.
static func retry(game: Game, index: int) -> void:
	game.profile.hp = game.profile.stats(game.content)["max_hp"]
	start(game, game.zone.area_id, index)
