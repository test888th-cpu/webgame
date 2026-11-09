class_name LevelingSim
extends RefCounted
## Levelling-time model for progression decisions (docs/HARNESS.md): how many
## hours a reference player needs per level, from the game's own rules.
##
## Two measured inputs, one calculation:
## * farm_rate: XP per hour on a farming ground, played by auto battle
##   (AutoPilot) with the same rest trips as ProgressionHarness.run_loop. XP is
##   counted from the kill events, so it is the XP a kill is worth at that
##   level even past the level cap, where PlayerProfile.add_xp pays nothing.
##   The hero is held at the measured level for the whole session.
## * story_time: seconds to clear every story area once at its own level
##   (ProgressionHarness.run_area), the reference player's path to level 50.
## * plan: hours per level from those rates and an XP curve, either the game's
##   (progression.json "xp") or a proposed one passed in. Nothing here changes
##   the game: proposed curves are dictionaries, never written to data.
##
## SYNTHETIC levels: the game ends at level 50, so measuring past it needs
## content that does not exist. `area_level` re-levels a farming ground in
## memory for one run, and `syn_gear` scales the level-50 gear by the ItemRules
## budget to the hero's level (ItemRules.BASE + PER_LEVEL * level). Both are
## restored or discarded after the run; results from them are labelled
## synthetic and decide no game value.

## Ticks per hour at the fixed simulation rate.
const TICKS_PER_HOUR := CombatRules.TICK_RATE * 3600


## XP needed to go from `level` to the next under `curve`: {"base", "growth",
## "square"} as progression.json "xp", plus optional "levels" {"N": xp} that
## overrides single levels (a proposed curve).
static func xp_to_next(curve: Dictionary, level: int) -> int:
	var overrides: Dictionary = curve.get("levels", {})
	if overrides.has(str(level)):
		return int(overrides[str(level)])
	var steps := level - 1
	return (
		int(curve.get("base", 0))
		+ int(curve.get("growth", 0)) * steps
		+ int(curve.get("square", 0)) * steps * steps
	)


## Total XP from level `from` to level `to` under `curve`.
static func xp_between(curve: Dictionary, from: int, to: int) -> int:
	var total := 0
	for level in range(from, to):
		total += xp_to_next(curve, level)
	return total


## One farming session at a fixed hero level. `setup`: "area", "level" (the
## hero's), "hero", "gear" ("shop" or "boss", ProgressionHarness.gear),
## "plus" (enhancement on every piece), "seed", "ticks" (default 18,000 =
## five minutes), "area_level" (synthetic re-level), "syn_gear" (bool).
## Returns {"xp", "ticks", "xp_per_hour", "kills", "ko", "trips"}.
static func farm_rate(content: ContentDB, setup: Dictionary) -> Dictionary:
	var area_id := str(setup["area"])
	var level := int(setup["level"])
	var real_level := int(content.area(area_id).get("level", 1))
	if setup.has("area_level"):
		content.areas[area_id]["level"] = int(setup["area_level"])
	var profile := _profile(content, setup)
	var result := _farm(content, profile, area_id, setup)
	content.areas[area_id]["level"] = real_level
	result["level"] = level
	return result


## Seconds to clear every story area once at its own level with shop gear,
## for one hero and seed (ProgressionHarness.run_area, auto battle).
## Returns {"seconds", "areas", "ko"}: knock-outs count areas not cleared.
static func story_time(content: ContentDB, hero: String, seed: int) -> Dictionary:
	var seconds := 0.0
	var ko := 0
	var areas := 0
	for area_id in StreetMemory.street(content):
		if content.area(area_id).get("encounters", []).is_empty():
			continue
		var run := ProgressionHarness.run_area(
			content,
			{"area": area_id, "hero": hero, "gear": "shop", "seed": seed, "food": {"rice_box": 10}}
		)
		seconds += float(run["seconds"])
		ko += int(run["ko"])
		areas += 1
	return {"seconds": seconds, "areas": areas, "ko": ko}


## Hours for each level `from`..`to`-1 under `curve`, given `rate_at`: a
## Callable(level) -> XP per hour (the best ground for that level). Returns
## {"levels": {level: hours}, "hours": total}.
static func plan(curve: Dictionary, from: int, to: int, rate_at: Callable) -> Dictionary:
	var levels := {}
	var total := 0.0
	for level in range(from, to):
		var rate := float(rate_at.call(level))
		var hours := INF if rate <= 0.0 else xp_to_next(curve, level) / rate
		levels[level] = hours
		total += hours
	return {"levels": levels, "hours": total}


## A proposed curve from target hours: `bands` [{"from", "to", "hours"}]
## spread each band's hours over its levels, rising by `growth` per level
## (1.0 = even), and turns hours into XP with `rate_at` (Callable(level) ->
## XP per hour). Returns {"levels": {"N": xp}} for xp_to_next. A proposal
## only: it is never written to game data.
static func propose(bands: Array, rate_at: Callable, growth := 1.0) -> Dictionary:
	var levels := {}
	for band: Dictionary in bands:
		var from := int(band["from"])
		var to := int(band["to"])
		var weights := 0.0
		for i in to - from:
			weights += pow(growth, i)
		for i in to - from:
			var hours := float(band["hours"]) * pow(growth, i) / weights
			levels[str(from + i)] = roundi(hours * float(rate_at.call(from + i)))
	return {"base": 0, "growth": 0, "square": 0, "levels": levels}


## The best measured rate for `level` among `rates` ({area: {level: xp per
## hour}}), using each ground's nearest measured hero level at or below
## `level` (a hero does not lose a ground by levelling).
static func best_rate(rates: Dictionary, level: int) -> float:
	var best := 0.0
	for area: String in rates:
		var by_level: Dictionary = rates[area]
		var nearest := -1
		for measured: int in by_level:
			if measured <= level and measured > nearest:
				nearest = measured
		if nearest >= 0 and level - nearest <= 2:
			best = maxf(best, float(by_level[nearest]))
	return best


static func _profile(content: ContentDB, setup: Dictionary) -> PlayerProfile:
	var level := int(setup["level"])
	var profile := PlayerProfile.new_game(content, str(setup.get("hero", "")))
	for street_area in StreetMemory.street(content):
		StreetMemory.visit(profile, street_area)
	var gear_level := mini(level, profile.max_level(content))
	for item_id in ProgressionHarness.gear(content, gear_level, str(setup.get("gear", "shop"))):
		profile.add_item(item_id)
		profile.equip(item_id, content)
	if bool(setup.get("syn_gear", false)) and level > gear_level:
		_scale_gear(content, profile, level)
	var plus := int(setup.get("plus", 0))
	for slot: String in PlayerProfile.SLOTS:
		var key := str(profile.equipment[slot])
		if key != "" and plus > 0:
			profile.enhance[key] = plus
	profile.level = level
	profile.money = 100000
	return profile


## Replaces each worn item with an in-memory copy scaled to `level` by the
## ItemRules budget (SYNTHETIC: no such items exist in the game).
static func _scale_gear(content: ContentDB, profile: PlayerProfile, level: int) -> void:
	for slot: String in PlayerProfile.SLOTS:
		var key := str(profile.equipment[slot])
		if key == "":
			continue
		var base := content.item(key)
		var ratio := (
			(ItemRules.BASE + ItemRules.PER_LEVEL * level)
			/ (ItemRules.BASE + ItemRules.PER_LEVEL * int(base.get("level", 1)))
		)
		var copy: Dictionary = base.duplicate(true)
		var stats: Dictionary = copy.get("stats", {})
		for stat: String in stats:
			var value := float(stats[stat]) * ratio
			stats[stat] = roundi(value) if stat in ["max_hp", "defense"] else value
		copy["level"] = level
		var synthetic := "syn_%s_%d" % [ContentDB.base_id(key), level]
		content.items[synthetic] = copy
		profile.add_item(synthetic)
		profile.equip(synthetic, content)


static func _farm(
	content: ContentDB, profile: PlayerProfile, area_id: String, setup: Dictionary
) -> Dictionary:
	var level := profile.level
	var seed := int(setup.get("seed", 1))
	var limit := int(setup.get("ticks", 18000))
	var home := AreaRules.rest_home(content, area_id)
	var fare := maxi(0, AutoRules.fare(content, home))
	AutoRules.restock(profile, content, home, 10, fare)
	var zone := ZoneSim.new(content, profile, area_id, "west", seed)
	zone.refresh_hero()
	var pilot := AutoPilot.new(content)
	var out := {"xp": 0, "kills": 0, "trips": 0, "ko": false}
	var ticks := 0
	var resting := 0
	while ticks < limit and not zone.hero.is_ko():
		ticks += 1
		var input := pilot.think(zone)
		if pilot.item:
			zone.use_item(pilot.item)
		for event in zone.tick(input):
			if event.type == "defeat" and not event.data.get("boss", false):
				out["xp"] += int(event.data["xp"])
				out["kills"] += 1
		# Hold the hero at the measured level for the whole session.
		profile.level = level
		profile.xp = 0
		resting = resting + 1 if AutoRules.wants_rest(zone, pilot) else 0
		if resting < AutoBattle.REST_DELAY_TICKS:
			continue
		resting = 0
		out["trips"] += 1
		AutoRules.restock(profile, content, home, 10, fare)
		zone = ZoneSim.new(content, profile, area_id, "west", seed + out["trips"])
		zone.refresh_hero()
		pilot = AutoPilot.new(content)
	out["ko"] = zone.hero.is_ko()
	out["ticks"] = ticks
	out["xp_per_hour"] = float(out["xp"]) * TICKS_PER_HOUR / maxi(1, ticks)
	return out
