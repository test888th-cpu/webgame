class_name RpgProgression
extends RefCounted
## Reference levelling (World of ClaudeCraft at d2b91e08, REFERENCE-EXACT):
## src/sim/types.ts XP_TABLE, MAX_LEVEL, xpForLevel, zeroDiff, mobXpValue, the
## post-cap virtual levels (POSTCAP_GROWTH, MAX_VIRTUAL_LEVEL, xpToReachLevel,
## virtualLevel) and prestige (PRESTIGE_XP_PER_RANK, maxPrestigeRank). The one
## home of every XP rule. Not connected to gameplay yet.

## XP to go from level L to L+1, levels 1..20.
const XP_TABLE := [
	400,
	900,
	1400,
	2100,
	2800,
	3600,
	4500,
	5400,
	6500,
	7600,
	8800,
	10100,
	11400,
	12900,
	14400,
	16000,
	17700,
	19400,
	21300,
	23200,
]
const MAX_LEVEL := 20
## Past the cap each virtual level costs 10% more; the table stops at 200.
const POSTCAP_GROWTH := 1.1
const MAX_VIRTUAL_LEVEL := 200

## Cumulative lifetime XP to reach each virtual level (VLEVEL_CUM), built once.
static var _cum: Array[int] = []


## XP for `level` to the next: the table entry, clamped to the last one.
static func xp_for_level(level: int) -> int:
	return XP_TABLE[clampi(level - 1, 0, XP_TABLE.size() - 1)]


## Prestige: one rank per xp_for_level(MAX_LEVEL) earned past the cap.
static func prestige_xp_per_rank() -> int:
	return xp_for_level(MAX_LEVEL)


## Levels below the player at which a mob gives no XP.
static func zero_diff(player_level: int) -> int:
	if player_level <= 7:
		return 5
	if player_level <= 9:
		return 6
	if player_level <= 15:
		return 7
	return 8


## Kill XP: 45 + 5 x mobLevel, +5% per level above (max +4), scaled to 0 at
## zero_diff levels below.
static func mob_xp_value(mob_level: int, player_level: int) -> int:
	var base := 45.0 + 5.0 * mob_level
	var diff := mob_level - player_level
	if diff >= 0:
		return roundi(base * (1.0 + 0.05 * mini(diff, 4)))
	var zd := zero_diff(player_level)
	if -diff >= zd:
		return 0
	return roundi(base * (1.0 - float(-diff) / zd))


static func _table() -> Array[int]:
	if _cum.is_empty():
		var cum: Array[int] = [0, 0]
		var total := 0
		for lvl in range(1, MAX_LEVEL):
			total += XP_TABLE[lvl - 1]
			cum.append(total)
		var step := float(XP_TABLE[MAX_LEVEL - 1])
		for lvl in range(MAX_LEVEL, MAX_VIRTUAL_LEVEL):
			total += roundi(step)
			cum.append(total)
			step *= POSTCAP_GROWTH
		_cum = cum
	return _cum


## Lifetime XP needed to reach `level` (real 1..20, virtual past it).
static func xp_to_reach_level(level: int) -> int:
	return _table()[clampi(level, 1, MAX_VIRTUAL_LEVEL)]


## The (virtual) level a lifetime XP total reaches.
static func virtual_level(lifetime_xp: int) -> int:
	var cum := _table()
	var xp := maxi(0, lifetime_xp)
	var lo := 1
	var hi := MAX_VIRTUAL_LEVEL
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if cum[mid] <= xp:
			lo = mid
		else:
			hi = mid - 1
	return lo


static func max_prestige_rank(lifetime_xp: int) -> int:
	var earned := lifetime_xp - xp_to_reach_level(MAX_LEVEL)
	return 0 if earned <= 0 else earned / prestige_xp_per_rank()
