extends SceneTree
## Compares boss enrage timers on the boss lairs (BossEnrage): for each lair
## boss and each "after_seconds" in --timers (plus no enrage), runs auto
## battle (AutoPilot) at the lair's suggested level with --kits gear over
## --seeds seeds and reports kill rate, knock-outs, time to kill, how often
## the enrage was reached and food eaten. Read-only: the timers are changed
## in memory only.
##
##   godot --headless --path client --script res://tests/harness/EnrageCompare.gd \
##     -- --timers=60,75,90 --seeds=6 --kits=shop,boss [--level_offset=0]
##
## Prints one "ENRAGE " JSON line per lair, timer and kit.

const FOOD := {"rice_box": 20, "herbal_tonic": 10}
const LIMIT_SECONDS := 360


func _init() -> void:
	var args := _args()
	var timers: Array[int] = [0]
	for t in str(args.get("timers", "60,75,90")).split(","):
		timers.append(int(t))
	var seeds := int(args.get("seeds", 6))
	var kits := str(args.get("kits", "shop,boss")).split(",")
	var offset := int(args.get("level_offset", 0))
	var content := ContentDB.load_all()
	for lair_id in AreaRules.lairs(content):
		var boss := _boss(content, lair_id)
		var spec: Dictionary = content.enemy(boss).get("enrage", {}).duplicate()
		for kit in kits:
			for timer in timers:
				if timer == 0:
					content.enemies[boss].erase("enrage")
				else:
					var copy := spec.duplicate()
					copy["after_seconds"] = timer
					content.enemies[boss]["enrage"] = copy
				var level := int(content.area(lair_id)["level"]) + offset
				var row := _run(content, lair_id, boss, level, kit, seeds)
				row["timer"] = timer
				print("ENRAGE " + JSON.stringify(row))
		content.enemies[boss]["enrage"] = spec
	quit(0)


func _run(
	content: ContentDB, lair_id: String, boss: String, level: int, kit: String, seeds: int
) -> Dictionary:
	var won := 0
	var downs := 0
	var kill_seconds: Array[float] = []
	var enraged := 0
	var food := 0
	for seed_value in range(1, seeds + 1):
		var profile := _hero(content, level, kit)
		var before := 0
		for item_id: String in FOOD:
			before += profile.count(item_id)
		var zone := ZoneSim.new(content, profile, lair_id, "west", seed_value)
		zone.refresh_hero()
		zone.hero.hp = zone.hero.max_hp
		var pilot := AutoPilot.new(content)
		var started := -1
		var killed := -1
		var raged := false
		for tick in LIMIT_SECONDS * CombatRules.TICK_RATE:
			if zone.hero.is_ko():
				break
			var input := pilot.think(zone)
			if pilot.item:
				zone.use_item(pilot.item)
			for event in zone.tick(input):
				if event.type == "encounter_start":
					started = tick
				elif event.type == "boss_enrage":
					raged = true
				elif event.type == "defeat" and str(event.data.get("kind", "")) == boss:
					killed = tick
			if killed < 0 and zone.boss_id != 0 and zone.fighter(zone.boss_id).is_ko():
				killed = tick
			if killed >= 0:
				break
		var after := 0
		for item_id: String in FOOD:
			after += profile.count(item_id)
		food += before - after
		if zone.hero.is_ko():
			downs += 1
		if killed >= 0:
			won += 1
			kill_seconds.append(float(killed - maxi(started, 0)) / CombatRules.TICK_RATE)
		enraged += int(raged)
	kill_seconds.sort()
	var median := kill_seconds[kill_seconds.size() / 2] if not kill_seconds.is_empty() else -1.0
	return {
		"lair": lair_id,
		"boss": boss,
		"level": level,
		"kit": kit,
		"seeds": seeds,
		"won": won,
		"downs": downs,
		"enraged": enraged,
		"median_kill_s": snappedf(median, 0.1),
		"slowest_kill_s": kill_seconds.back() if not kill_seconds.is_empty() else -1.0,
		"food_per_fight": snappedf(float(food) / seeds, 0.1),
	}


static func _hero(content: ContentDB, level: int, kit: String) -> PlayerProfile:
	var profile := PlayerProfile.new_game(content)
	for area_id in StreetMemory.street(content):
		StreetMemory.visit(profile, area_id)
	for enemy_id: String in content.enemies:
		if content.enemy(enemy_id).get("boss", false):
			profile.defeated[enemy_id] = 1
	profile.level = level
	for item_id in ProgressionHarness.gear(content, level, kit):
		profile.add_item(item_id)
		profile.equip(item_id, content)
	for item_id: String in FOOD:
		profile.add_item(item_id, int(FOOD[item_id]))
	return profile


static func _boss(content: ContentDB, lair_id: String) -> String:
	for wave: Array in content.area(lair_id)["encounters"][0]["waves"]:
		for kind: String in wave:
			if content.enemy(kind).get("boss", false):
				return kind
	return ""


static func _args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=", true, 1)
			out[parts[0]] = parts[1]
	return out
