extends SceneTree
## Farming-ground check for balance work (LevelingSim.farm_rate): for each
## ground in --areas and each hero level offset from the ground's suggested
## level in --offsets, runs --seeds sessions per gear profile and prints the
## mean XP, coins, Scrap Metal and Refined Alloy per hour and the knock-outs.
## Read-only.
##
##   godot --headless --path client --script res://tests/harness/FarmCheck.gd -- \
##     --areas=farm_foundry_depths,farm_iron_heart --offsets=-2,0,2 --seeds=8
##
## Prints one "FARM " JSON line per ground, level and gear.

const GEARS := {"B": {"gear": "shop", "plus": 0}, "C": {"gear": "boss", "plus": 5}}


func _init() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=", true, 1)
			args[parts[0]] = parts[1]
	var content := ContentDB.load_all()
	var areas := str(args.get("areas", "")).split(",", false)
	if areas.is_empty():
		areas = PackedStringArray(AreaRules.farms(content))
	var offsets := str(args.get("offsets", "0")).split(",")
	var seeds := int(args.get("seeds", 8))
	for area_id in areas:
		for offset in offsets:
			var level := int(content.area(area_id)["level"]) + int(offset)
			for gear: String in GEARS:
				print("FARM " + JSON.stringify(_measure(content, area_id, level, gear, seeds)))
	quit(0)


func _measure(
	content: ContentDB, area_id: String, level: int, gear: String, seeds: int
) -> Dictionary:
	var sums := {"xp_per_hour": 0.0, "coins_per_hour": 0.0, "scrap_per_hour": 0.0}
	sums["alloy_per_hour"] = 0.0
	var ko := 0
	for seed_value in range(1, seeds + 1):
		var setup := {"area": area_id, "level": level, "seed": seed_value}
		setup.merge(GEARS[gear])
		var run := LevelingSim.farm_rate(content, setup)
		for key: String in sums:
			sums[key] += float(run[key])
		ko += int(bool(run["ko"]))
	var out := {"area": area_id, "level": level, "gear": gear, "seeds": seeds, "ko": ko}
	for key: String in sums:
		out[key] = roundi(sums[key] / seeds)
	return out
