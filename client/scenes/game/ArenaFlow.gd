class_name ArenaFlow
extends RefCounted
## The arena in the game scene: the ladder screen from the arena master in
## the city, into the arena for a match (ArenaMatch decides it), the clock
## on the HUD, the result, and straight back to the ladder for the next
## challenge. Presentation and flow only: ranks and outcomes are the rules'.

## Seconds the result shows before the ladder is back, unless dismissed.
const RESULT_SECONDS := 2.5

var game: Game
## The match being played, or null.
var bout: ArenaMatch = null
var entering := false
## The arena master the ladder was opened from (to reopen it after a bout).
var _npc := {}


func _init(p_game: Game) -> void:
	game = p_game


func active() -> bool:
	return bout != null


## True when `area_id` is the arena and no match is being started: the arena
## is only ever entered for a bout.
func barred(area_id: String) -> bool:
	return game.content.area(area_id).get("arena", false) and not entering


## The ladder: rank, the five rivals offered, a fight button each.
func open_ladder(npc: Dictionary) -> void:
	_npc = npc
	var closed := ArenaRules.closed(game.profile, game.content)
	if closed:
		game.hud_toast("%s: %s" % [npc.get("name", "Arena"), closed])
		Sfx.play("denied", -4.0)
		return
	game._show("arena", ArenaScreen.ladder(game, npc))


## Into the arena against rival `id`.
func start(id: String) -> void:
	game.close_menu()
	game.auto.stop()
	entering = true
	game.enter_area(str(ArenaRules.spec(game.content)["area"]), "")
	entering = false
	bout = ArenaMatch.new(game.zone, game.profile, game.content, id)
	game._hud.attach(game.zone, game.profile, game.content)
	var data := ArenaRules.rival(game.content, id)
	var rank := ArenaRules.rank_of(game.profile, game.content, id)
	game._hud.chapter("VS %s" % data["name"], "Rank #%d" % rank)
	Sfx.play("arena_lock", -4.0)


## The hero's input this tick: none during the countdown or after the end.
func filter(input: FighterInput) -> FighterInput:
	return bout.filter(input) if bout else input


## After the zone's tick: the match's countdown, clock and result.
func after_step(events: Array[ZoneEvent]) -> void:
	if bout == null:
		return
	var own: Array[ZoneEvent] = []
	bout.tick(own)
	for event in own:
		events.append(event)
		match event.type:
			"arena_start":
				game._hud.chapter("FIGHT!", "")
				Sfx.play("boss_roar", -8.0)
			"arena_end":
				SaveStore.save(game.profile)
				game._show("arena_result", ArenaScreen.result(game, event.data))
				Sfx.play("level_up" if event.data["won"] else "denied", -2.0)


## The clock on the HUD while a match runs ("" otherwise).
func hud_text() -> String:
	if bout == null:
		return ""
	if bout.countdown > 0:
		return "ARENA  Starts in %d" % ceili(bout.countdown / float(CombatRules.TICK_RATE))
	return "ARENA  %d:%02d" % [bout.seconds_left() / 60, bout.seconds_left() % 60]


## Out of the arena to the city, rested; back to the ladder unless `stay_out`.
func leave(stay_out := false) -> void:
	bout = null
	game.profile.hp = game.profile.stats(game.content)["max_hp"]
	game.close_menu()
	game.enter_area(AreaRules.hub(game.content), "")
	if not stay_out and not _npc.is_empty():
		open_ladder(_npc)
