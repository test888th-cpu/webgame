class_name WorldBossRun
extends RefCounted
## One attempt at a world boss (WorldBossRules) in its arena zone: sets the
## arena to the boss's level for this hero, gives the boss the round's pool (what is
## left of it), counts the damage the hero deals to it, and ends when the
## round's hour runs out, the boss falls, the hero does or leaves. Pure: the zone is passed in on
## every call, never kept.
##
## The round runs on the world's clock, not on how many ticks the hero's game
## has run: tick() takes the time `now` (the server's, once online), so a
## browser tab that sleeps in the background never stops the round. When the
## hour is up the boss escapes: it can no longer be hit, its mechanics stop,
## it walks off the arena and is gone, and only then does the attempt end
## ("time"), leaving the hero alone in the arena.

## How fast (px per tick) and for how long at most the boss escapes, and how
## far past the arena's edge it is gone.
const ESCAPE_SPEED := 4.0
const ESCAPE_TICKS := 180
const ESCAPE_MARGIN := 120.0

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
## When the round's hour ends (unix seconds).
var closes_at := 0
## True while the boss is escaping at the end of the hour.
var escaping := false
## Set by whoever shows the result once it is shown, so it is shown (and the
## damage banked) once: the street goes on behind the result screen.
var banked := false

## The round's enrage (world_boss.json "enrage", BossEnrage): "" before,
## "warned", then "enraged" for the round's last seconds.
var rage := ""

var _boss_id := 0
var _remaining := 0
var _rage_spec := {}
var _escape_ticks := 0
var _escape_x := 0.0


func _init(
	zone: ZoneSim,
	profile: PlayerProfile,
	content: ContentDB,
	p_boss: String,
	p_round: int,
	now: int
) -> void:
	boss = p_boss
	round = p_round
	level = WorldBossRules.level(content, boss)
	total = WorldBossRules.pool(content, boss)
	var state := WorldBossRules.progress(profile, boss, round)
	_remaining = maxi(1, total - int(state["dealt"]))
	# Until the round ends: the boss stays up for its hour, then escapes.
	closes_at = int(WorldBossRules.window(content, boss, now)["closes_at"])
	ticks_left = maxi(1, closes_at - now) * CombatRules.TICK_RATE
	_rage_spec = WorldBossRules.spec(content, boss).get("enrage", {})
	# The arena takes the boss's level, so its brood fights at its side.
	zone.level = level - LevelRules.BOSS_BONUS


## Advances the attempt by the tick that produced `events`, at time `now`
## (unix seconds; -1 counts ticks only, for tests that run the clock by ticks).
func tick(zone: ZoneSim, events: Array[ZoneEvent], now := -1) -> void:
	if ended:
		return
	if escaping:
		_tick_escape(zone)
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
		if now >= 0:
			# The world's clock wins: a tab asleep in the background loses no time.
			ticks_left = mini(ticks_left, (closes_at - now) * CombatRules.TICK_RATE)
		_tick_rage(zone)
		if ticks_left <= 0:
			_start_escape(zone)


## The hour is up: the boss stops fighting and makes for the east edge.
func _start_escape(zone: ZoneSim) -> void:
	escaping = true
	ticks_left = 0
	var boss := zone.fighter(_boss_id)
	if zone.boss_id == _boss_id:
		zone.boss_id = 0  # its hazards and summons stop (BossMechanics)
	if boss == null or boss.is_ko():
		ended = "time"
		return
	_escape_x = boss.position.x


## One step of the escape: untouchable and not attacking, it walks east past
## the arena's edge (or for ESCAPE_TICKS at most) and is gone.
func _tick_escape(zone: ZoneSim) -> void:
	var boss := zone.fighter(_boss_id)
	_escape_ticks += 1
	if boss == null:
		ended = "time"
		return
	boss.grace = maxi(boss.grace, 2)
	var brain: EnemyBrain = zone.brains.get(boss.id)
	if brain:
		brain.cooldown = maxi(brain.cooldown, 30)
	_escape_x += ESCAPE_SPEED
	boss.position.x = _escape_x
	boss.facing = 1
	if _escape_x > zone.bounds.end.x + ESCAPE_MARGIN or _escape_ticks >= ESCAPE_TICKS:
		zone.fighters.erase(boss)
		zone.brains.erase(boss.id)
		ended = "time"


## The round's last seconds: warned, then enraged (applied once per attempt).
func _tick_rage(zone: ZoneSim) -> void:
	if _rage_spec.is_empty() or rage == "enraged":
		return
	var last := float(_rage_spec["last_seconds"]) * CombatRules.TICK_RATE
	var warn := last + float(_rage_spec.get("warn_seconds", 0)) * CombatRules.TICK_RATE
	if ticks_left <= last:
		var giant := zone.fighter(_boss_id)
		if giant:
			BossEnrage.apply(giant, _rage_spec)
		rage = "enraged"
	elif ticks_left <= warn:
		rage = "warned"


## Seconds left, for the HUD.
func seconds_left() -> int:
	return ceili(maxf(0.0, ticks_left) / CombatRules.TICK_RATE)


## Share of the pool still standing (before this attempt's damage is banked).
func remaining_share() -> float:
	return clampf(float(_remaining - dealt) / maxf(1.0, total), 0.0, 1.0)


## The attempt's line on the HUD: the clock, the pool left and the enrage.
func hud_text() -> String:
	var text := (
		"WORLD BOSS  %d:%02d  ·  %d%% left"
		% [seconds_left() / 60, seconds_left() % 60, roundi(remaining_share() * 100)]
	)
	if escaping:
		return text + "  ·  IT ESCAPES"
	if rage == "warned":
		return text + "  ·  enrage soon"
	if rage == "enraged":
		return text + "  ·  ENRAGED"
	return text
