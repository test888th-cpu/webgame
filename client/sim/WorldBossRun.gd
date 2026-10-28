class_name WorldBossRun
extends RefCounted
## One attempt at a world boss (WorldBossRules) in its arena zone: sets the
## arena to the boss's level for this hero, gives the boss the round's pool (what is
## left of it), counts the damage the hero deals to it, and ends when time
## runs out, the boss falls or the hero does. Pure: the zone is passed in on
## every call, never kept.

## Why it ended ("" while running): "time", "slain", "down" or "left".
var ended := ""
## Which world boss (world_boss.json id).
var boss := ""
var round := 0
var level := 1
## The round's whole pool, and how much of it the hero dealt this attempt.
var total := 0
var dealt := 0
var ticks_left := 0

var _boss_id := 0
var _remaining := 0


func _init(
	zone: ZoneSim, profile: PlayerProfile, content: ContentDB, p_boss: String, p_round: int
) -> void:
	boss = p_boss
	round = p_round
	level = WorldBossRules.level(content, boss)
	total = WorldBossRules.pool(content, boss)
	var state := WorldBossRules.progress(profile, boss, round)
	_remaining = maxi(1, total - int(state["dealt"]))
	var seconds := int(WorldBossRules.spec(content, boss)["attempt_seconds"])
	ticks_left = seconds * CombatRules.TICK_RATE
	# The arena takes the boss's level, so its brood fights at its side.
	zone.level = level - LevelRules.BOSS_BONUS


## Advances the attempt by the tick that produced `events`.
func tick(zone: ZoneSim, events: Array[ZoneEvent]) -> void:
	if ended:
		return
	if _boss_id == 0 and zone.boss_id != 0:
		_boss_id = zone.boss_id
		var giant := zone.fighter(_boss_id)
		giant.max_hp = total
		giant.hp = _remaining
	for event in events:
		if event.type == "hit" and event.hit.defender_id == _boss_id and _boss_id != 0:
			dealt += event.hit.damage
		elif event.type == "defeat" and int(event.data["id"]) == _boss_id:
			ended = "slain"
		elif event.type == "hero_down":
			ended = "down"
		elif event.type == "exit":
			ended = "left"
	if _boss_id != 0 and not ended:
		ticks_left -= 1
		if ticks_left <= 0:
			ended = "time"


## Seconds left, for the HUD.
func seconds_left() -> int:
	return ceili(maxf(0.0, ticks_left) / CombatRules.TICK_RATE)


## Share of the pool still standing (before this attempt's damage is banked).
func remaining_share() -> float:
	return clampf(float(_remaining - dealt) / maxf(1.0, total), 0.0, 1.0)
