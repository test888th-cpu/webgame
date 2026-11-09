extends SceneTree
## World boss reach for one hero (WorldBossRun with auto battle): for each
## world boss in --bosses, a hero at the boss's level with each --kits gear
## profile fights a fresh attempt for up to --minutes, --seeds times. Prints
## the damage dealt per minute, knock-outs, food eaten and the minutes one
## hero would need to empty the round's pool (sized for its "players"),
## against the round's open minutes. Read-only.
##
##   godot --headless --path client --script res://tests/harness/WorldBossCheck.gd -- \
##     --bosses=slag_titan,iron_sovereign --kits=C,D --seeds=4 --minutes=4
##
## Prints one "WORLDBOSS " JSON line per boss and kit.

const KITS := {
	"B": {"gear": "shop", "plus": 0},
	"C": {"gear": "boss", "plus": 5},
	"D": {"gear": "boss", "plus": 10},
}
const FOOD := {"rice_box": 30, "herbal_tonic": 30}


func _init() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=", true, 1)
			args[parts[0]] = parts[1]
	var content := ContentDB.load_all()
	var bosses := str(args.get("bosses", ",".join(content.world_bosses.keys()))).split(",")
	for boss in bosses:
		for kit in str(args.get("kits", "C,D")).split(","):
			var row := _measure(
				content, boss, kit, int(args.get("seeds", 4)), float(args.get("minutes", 4))
			)
			print("WORLDBOSS " + JSON.stringify(row))
	quit(0)


func _measure(
	content: ContentDB, boss: String, kit: String, seeds: int, minutes: float
) -> Dictionary:
	var spec: Dictionary = content.world_bosses[boss]
	var level := WorldBossRules.level(content, boss)
	var period := int(spec["period_minutes"]) * 60
	var now := 5 * period + int(spec.get("offset_minutes", 0)) * 60 + 30
	var dealt := 0
	var seconds := 0.0
	var downs := 0
	var food := 0
	var total := 0
	for seed_value in range(1, seeds + 1):
		var profile := _hero(content, level, kit)
		profile.defeated[str(spec["unlock"])] = 1
		var zone := ZoneSim.new(content, profile, str(spec["area"]), "west", seed_value)
		var run := WorldBossRun.new(zone, profile, content, boss, 5, now)
		zone.refresh_hero()
		zone.hero.hp = zone.hero.max_hp
		total = run.total
		var pilot := AutoPilot.new(content)
		var ticks := 0
		while ticks < int(minutes * 60.0 * CombatRules.TICK_RATE) and not run.ended:
			ticks += 1
			var input := pilot.think(zone)
			if pilot.item and zone.use_item(pilot.item):
				food += 1
			run.tick(zone, zone.tick(input))
		dealt += run.dealt
		seconds += float(ticks) / CombatRules.TICK_RATE
		downs += int(run.ended == "down")
	var per_minute := float(dealt) / maxf(1.0, seconds / 60.0)
	return {
		"boss": boss,
		"level": level,
		"kit": kit,
		"seeds": seeds,
		"players": int(spec.get("players", 1)),
		"pool": total,
		"damage_per_minute": roundi(per_minute),
		"minutes_to_empty_pool": snappedf(float(total) / maxf(1.0, per_minute), 0.1),
		"round_minutes": int(spec["open_minutes"]),
		"downs": downs,
		"food_per_minute": snappedf(float(food) / maxf(1.0, seconds / 60.0), 0.1),
	}


static func _hero(content: ContentDB, level: int, kit: String) -> PlayerProfile:
	var profile := PlayerProfile.new_game(content)
	for area_id in StreetMemory.street(content):
		StreetMemory.visit(profile, area_id)
	profile.level = level
	for item_id in ProgressionHarness.gear(content, level, str(KITS[kit]["gear"])):
		profile.add_item(item_id)
		profile.equip(item_id, content)
		var key := profile.own_copy(str(content.item(item_id)["slot"]))
		profile.enhance[key] = int(KITS[kit]["plus"])
	for item_id: String in FOOD:
		profile.add_item(item_id, int(FOOD[item_id]))
	return profile
