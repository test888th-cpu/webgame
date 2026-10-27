class_name AutoBattle
extends RefCounted
## Auto battle for Game: the on/off switch, the player's own input taking
## over whenever they touch the controls, a tally for the HUD, and the farm
## loop (area cleared, or out of food and hurt: home to rest, restock buns,
## ride the taxi back, go again). Every decision comes from sim/ (AutoPilot in
## the fight, AutoRules for the loop); this only carries them out through the
## same actions a player has: buttons, eating, the shop, the taxi fare.

## About a second and a half to see "Area clear" before heading home.
const REST_DELAY_TICKS := 90
## Choices offered in the pause menu (GameSession settings).
const HEAL_CHOICES := [0.3, 0.5, 0.7]
const FOOD_CHOICES := [0.0, 5.0, 10.0, 20.0]

var on := false
var pilot: AutoPilot
## The area being farmed: where the loop rides back to.
var farm_area := ""
var runs := 0
var kills := 0
var coins := 0
var xp := 0

var _game: Game
var _rest_ticks := 0
## Set while the loop itself changes area, so that is not taken for the
## player walking off.
var _travelling := false


func _init(game: Game) -> void:
	_game = game
	pilot = AutoPilot.new(game.content)


## Why auto cannot start here, or "".
func problem() -> String:
	return AutoRules.problem(_game.profile, _game.content, _game.zone.area_id)


func toggle() -> void:
	if on:
		stop("Auto off")
		return
	var why := problem()
	if why:
		_game.hud_toast(why)
		Sfx.play("denied", -4.0)
		return
	on = true
	farm_area = _game.zone.area_id
	runs = 1
	kills = 0
	coins = 0
	xp = 0
	_rest_ticks = 0
	pilot = AutoPilot.new(_game.content)
	Sfx.play("ui_select", -4.0)
	_game.hud_toast("Auto on. Move or attack to take back control.")


func stop(reason := "") -> void:
	if not on:
		return
	on = false
	_rest_ticks = 0
	if reason:
		_game.hud_toast(reason)


## This tick's hero input: the player's own whenever they press anything,
## otherwise the pilot's (eating included).
func input(manual: FighterInput, manual_used: bool) -> FighterInput:
	pilot.heal_below = float(GameSession.settings.get("auto_heal_at", 0.5))
	var chosen := pilot.think(_game.zone)
	if manual_used:
		return manual
	if pilot.item and _game.zone.use_item(pilot.item):
		_game.healed_by(pilot.item)
	return chosen


## After a tick: count what was won, then rest and return when it is time.
func after_step(events: Array[ZoneEvent]) -> void:
	for event in events:
		match event.type:
			"defeat":
				kills += 1
				xp += int(event.data["xp"])
			"pickup":
				if event.data["kind"] == "money":
					coins += int(event.data["amount"])
			"hero_down":
				stop("Knocked out. Auto off.")
				return
	if not on or not AutoRules.wants_rest(_game.zone, pilot):
		_rest_ticks = 0
		return
	_rest_ticks += 1
	if _rest_ticks >= REST_DELAY_TICKS:
		_rest_ticks = 0
		_rest_and_return()


## The player (not the loop) moved to another area: auto stops there.
func entered(area_id: String) -> void:
	if on and not _travelling and area_id != farm_area:
		stop("New area. Auto off.")


func _rest_and_return() -> void:
	var content := _game.content
	var cleared := pilot.status == AutoPilot.STATUS_CLEAR
	if not GameSession.settings.get("auto_loop", true):
		stop("Area clear. Auto off." if cleared else "Out of food. Auto off.")
		return
	var home := content.start_area
	var fare := maxi(0, AutoRules.fare(content, home))
	_travelling = true
	_game.enter_area(home, "")
	var keep := int(GameSession.settings.get("auto_food", 10.0))
	var bought := AutoRules.restock(_game.profile, content, home, keep, fare)
	if _game.profile.money < fare:
		_travelling = false
		stop("Not enough coins for the ride back. Auto off.")
		return
	_game.profile.money -= fare
	_game.enter_area(farm_area, "west")
	_travelling = false
	runs += 1
	var text := "Rested at %s" % content.area(home).get("name", home)
	if bought:
		text += ", bought %d food" % bought
	_game.hud_toast("%s. Run %d." % [text, runs])


## One line for the HUD: what it is doing and what this session has won.
func summary() -> String:
	return "Run %d  ·  %d KO  ·  +%d coins  ·  +%d XP" % [runs, kills, coins, xp]
