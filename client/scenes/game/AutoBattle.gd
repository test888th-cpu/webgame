class_name AutoBattle
extends RefCounted
## Auto battle for Game: the on/off switch, the player's own input taking
## over whenever they touch the controls, a tally for the HUD, the story
## (StoryAuto: take and hand in each stage's quest at its giver, fight
## through to the stage's boss, walk on east, ride the taxi to wherever the
## quest goes next), and the farm loop (area cleared, or out of food and hurt:
## home to rest, restock buns, ride the taxi back, go again). In a world boss
## arena it only fights, to the attempt's end. Every decision comes from sim/
## (AutoPilot in the fight, StoryAuto and AutoRules for the rest); this only
## carries them out through the same actions a player has: buttons, eating,
## the quest giver, the shop, the taxi fare.

## About a second and a half to see "Area clear" before heading home.
const REST_DELAY_TICKS := 90
## Under a second at a quest giver before taking or handing in a quest.
const QUEST_DELAY_TICKS := 45
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
## Ticks the current story step has waited, and whether this session has
## followed the story (so the story's end turns auto off).
var _story_ticks := 0
var _story_run := false
## Rides back to the same area with no one defeated in between: a second
## one means the story is stuck there, and auto stops instead of paying on.
var _same_rides := 0
## The left-behind quest last named in a toast (_story_note).
var _noted := ""
## Gear came in (a drop, a quest's rewards): try it on once out of the fight.
var _new_gear := false


func _init(game: Game) -> void:
	_game = game
	pilot = AutoPilot.new(game.content)


## Why auto cannot start here, or "".
func problem() -> String:
	return AutoRules.problem(_game.profile, _game.content, _game.zone.area_id, _follows_story())


## True when auto follows the story here: the setting is on, and this is
## neither a farming ground nor a world boss arena.
func _follows_story() -> bool:
	var area_id := _game.zone.area_id
	if AreaRules.kind(_game.content, area_id) == AreaRules.FARM:
		return false
	if _game.content.area(area_id).get("world_boss", false):
		return false
	return bool(GameSession.settings.get("auto_story", true))


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
	_story_ticks = 0
	_story_run = false
	_same_rides = 0
	_new_gear = true
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
				_same_rides = 0
			"pickup":
				if event.data["kind"] == "money":
					coins += int(event.data["amount"])
				else:
					_new_gear = true
			"hero_down":
				stop("Knocked out. Auto off.")
				return
			"fights_back":
				# A farming ground refilled: the next round, without a ride.
				runs += 1
	if on and _new_gear and not _game.zone.in_encounter():
		_new_gear = false
		_wear_upgrades()
	if on and _follows_story() and _story():
		_rest_ticks = 0
		return
	if not on or not AutoRules.wants_rest(_game.zone, pilot):
		_rest_ticks = 0
		return
	_rest_ticks += 1
	if _rest_ticks >= REST_DELAY_TICKS:
		_rest_ticks = 0
		_rest_and_return()


## Another area: auto stops there when the player (not the loop) went, but
## follows the story on when it was the pilot walking on east.
func entered(area_id: String) -> void:
	if not on or _travelling or area_id == farm_area:
		return
	if pilot.status == AutoPilot.STATUS_ONWARD and _follows_story():
		farm_area = area_id
		pilot.heading = 0
		return
	stop("New area. Auto off.")


## One story step (StoryAuto) after a tick. Returns true when it took this
## tick (a quest, a ride, waiting for one), false to let the fight and the
## farm loop's rest go on as usual.
func _story() -> bool:
	var zone := _game.zone
	pilot.heading = 0
	if zone.in_encounter() or zone.hero.is_ko():
		_story_ticks = 0
		return false
	var cleared := pilot.status == AutoPilot.STATUS_CLEAR
	var plan := StoryAuto.step(_game.profile, _game.content, zone.area_id, cleared)
	var step := str(plan["do"])
	if step in [StoryAuto.HERE, StoryAuto.DONE]:
		# HERE: fight on here and say where the quest is; DONE: the end.
		if step == StoryAuto.HERE:
			_story_note(plan)
		elif _story_run:
			stop("The story is complete. Auto off.")
		return step == StoryAuto.DONE and _story_run
	_story_run = true
	if step in [StoryAuto.EAST, StoryAuto.STAY]:
		pilot.heading = 1 if step == StoryAuto.EAST else 0
		return false
	# Drops and a street weapon first, then a moment to read the last toast.
	if pilot.status in [AutoPilot.STATUS_LOOT, AutoPilot.STATUS_WEAPON]:
		_story_ticks = 0
		return true
	_story_ticks += 1
	if plan["do"] == StoryAuto.QUEST:
		if _story_ticks >= QUEST_DELAY_TICKS:
			_story_ticks = 0
			_quest(str(plan["quest"]), bool(plan["turn_in"]))
		return true
	if _story_ticks >= REST_DELAY_TICKS:
		_story_ticks = 0
		_ride(str(plan["to"]))
	return true


## Puts on better gear the hero carries (AutoRules.wear_upgrades), when the
## setting is on, as the player would from the bag.
func _wear_upgrades() -> void:
	if not GameSession.settings.get("auto_gear", true):
		return
	var worn := AutoRules.wear_upgrades(_game.profile, _game.content)
	if worn.is_empty():
		return
	_game.zone.refresh_hero()
	SaveStore.save(_game.profile)
	var names: Array[String] = []
	for key in worn:
		names.append(str(_game.content.item(key).get("name", key)))
	_game.hud_toast("Equipped " + ", ".join(names))


## Says once why auto stays here although the quest is elsewhere (StoryAuto
## HERE), so the player knows where to take it up.
func _story_note(plan: Dictionary) -> void:
	if _noted == str(plan["quest"]):
		return
	_noted = str(plan["quest"])
	var area := str(_game.content.area(str(plan["to"])).get("name", plan["to"]))
	_game.hud_toast('Auto keeps fighting here. Quest "%s" is back at %s.' % [_noted, area])


## Takes or hands in `quest_id` at its giver, as the quest menu does.
func _quest(quest_id: String, turn_in: bool) -> void:
	if turn_in:
		# Game's hand-in pays the rewards, levels up and shows a chapter's end
		# or the epilogue, as the quest giver's menu does.
		_game._hand_in(quest_id)
		_new_gear = true
		return
	QuestRules.accept(_game.profile, quest_id, _game.content)
	_game.hud_toast("New quest: " + str(_game.content.quests[quest_id]["name"]))
	SaveStore.save(_game.profile)
	_game.view.update_npc_marks(_game.profile)


## To `area_id` for the story: home to the hub (resting, food restocked),
## then Win's taxi there, paying the fare as a player would.
func _ride(area_id: String) -> void:
	_same_rides = _same_rides + 1 if area_id == farm_area else 0
	if _same_rides > 1:
		stop("Nothing left to fight here. Auto off.")
		return
	farm_area = area_id
	_rest_and_return(true)


## Home to rest, then the taxi to `farm_area`. `story`: a ride the story
## needs, which goes whatever the farm loop setting says.
func _rest_and_return(story := false) -> void:
	var content := _game.content
	var cleared := pilot.status == AutoPilot.STATUS_CLEAR
	if not story and not GameSession.settings.get("auto_loop", true):
		stop("Area clear. Auto off." if cleared else "Out of food. Auto off.")
		return
	var home := AreaRules.rest_home(content, farm_area)
	var fare := maxi(0, AutoRules.fare(content, home))
	_travelling = true
	_game.enter_area(home, "")
	var keep := int(GameSession.settings.get("auto_food", 10.0))
	var bought := AutoRules.restock(_game.profile, content, home, keep, fare)
	if not EconomyRules.charge(_game.profile, fare):
		_travelling = false
		stop("Not enough coins for the ride back. Auto off.")
		return
	_game.enter_area(farm_area, "west")
	_travelling = false
	var text := "Rested at %s" % content.area(home).get("name", home)
	if bought:
		text += ", bought %d food" % bought
	if story:
		_game.hud_toast("%s. On to %s." % [text, content.area(farm_area).get("name", farm_area)])
		return
	runs += 1
	_game.hud_toast("%s. Run %d." % [text, runs])


## One line for the HUD: what it is doing and what this session has won.
func summary() -> String:
	return "Run %d  ·  %d KO  ·  +%d coins  ·  +%d XP" % [runs, kills, coins, xp]
