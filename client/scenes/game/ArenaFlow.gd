class_name ArenaFlow
extends RefCounted
## The arena in the game scene: the ladder screen from the arena master in
## the city, a rival's details and the challenge, into the arena for a match
## (ArenaMatch decides it), the clock on the HUD, the result, and back to
## the ladder. Presentation and flow only: ranks and outcomes are the rules'.
##
## Around a match the player's own health and ultimate gauge are kept
## (ArenaMatch.snapshot / restore), so nothing of the arena's doubled health
## or its gauge leaks into the city. A match the
## game closed during is settled as a forfeit the next time it starts.

var game: Game
## The match being played, or null.
var bout: ArenaMatch = null
var entering := false
## The arena master the ladder was opened from (to reopen it after a bout).
var _npc := {}


func _init(p_game: Game) -> void:
	game = p_game
	var settled := ArenaRules.settle_pending(game.profile, game.content)
	if not settled.is_empty() and not bool(settled.get("duplicate", false)):
		SaveStore.save(game.profile)
		var note := "Arena: the last match was left unfinished and counts as a forfeit."
		game.hud_toast.call_deferred(note)


func active() -> bool:
	return bout != null


## True when `area_id` is the arena and no match is being started: the arena
## is only ever entered for a bout.
func barred(area_id: String) -> bool:
	return game.content.area(area_id).get("arena", false) and not entering


## The ladder: standing, the five rivals offered, details for each.
func open_ladder(npc: Dictionary) -> void:
	_npc = npc
	var closed := ArenaRules.closed(game.profile, game.content)
	if closed:
		game.hud_toast("%s: %s" % [npc.get("name", "Arena"), closed])
		Sfx.play("denied", -4.0)
		return
	game._show("arena", ArenaScreen.ladder(game, npc))


## "New rivals": another spread of the same window, free.
func refresh_rivals() -> void:
	ArenaRules.refresh(game.profile, game.content)
	SaveStore.save(game.profile)
	open_ladder(_npc)


## A rival's gear, play style and difficulty, and the challenge.
func details(id: String) -> void:
	game._show("arena_details", ArenaScreen.details(game, id))


## Back from the details to the ladder.
func back() -> void:
	open_ladder(_npc)


## Into the arena against rival `id` (after the challenge is confirmed).
func start(id: String) -> void:
	if bout != null or not ArenaRules.fit(game.content, id):
		return
	game.close_menu()
	game.auto.stop()
	entering = true
	game.enter_area(str(ArenaRules.spec(game.content)["area"]), "")
	entering = false
	bout = ArenaMatch.new(game.zone, game.profile, game.content, id)
	game._hud.attach(game.zone, game.profile, game.content)
	var data := bout.loadout
	var rank := ArenaRules.rank_of(game.profile, game.content, id)
	game._hud.chapter("VS %s" % data["name"], "Rank #%d" % rank)
	Sfx.play("arena_lock", -4.0)


## The same rival again, from the result screen.
func rematch(id: String) -> void:
	leave(true, false)
	start(id)


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
				# Saved now: from here, closing the game is a forfeit.
				SaveStore.save(game.profile)
				game._hud.chapter("FIGHT!", "")
				Sfx.play("boss_roar", -8.0)
			"arena_end":
				SaveStore.save(game.profile)
				bout.shown()
				game._show("arena_result", ArenaScreen.result(game, event.data))
				var won := str(event.data.get("result", "")) == ArenaRules.WIN
				Sfx.play("level_up" if won else "denied", -2.0)


## The clock on the HUD while a match runs ("" otherwise).
func hud_text() -> String:
	if bout == null:
		return ""
	if bout.phase == ArenaMatch.Phase.COUNTDOWN:
		return "ARENA  Starts in %d" % ceili(bout.countdown / float(CombatRules.TICK_RATE))
	return "ARENA  %d:%02d" % [bout.seconds_left() / 60, bout.seconds_left() % 60]


## Out of the arena to the city with the health and gauge the player came
## in with; back to the ladder unless `stay_out`. `travel` false stays put
## (a rematch goes straight back in).
func leave(stay_out := false, travel := true) -> void:
	if bout != null:
		bout.returned()
		bout.restore()
	bout = null
	game.close_menu()
	if travel:
		game.enter_area(AreaRules.hub(game.content), "")
		if not stay_out and not _npc.is_empty():
			open_ladder(_npc)
