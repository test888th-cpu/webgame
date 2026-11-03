extends SceneTree
## The measurement harness: progression and economy numbers for balance
## decisions, from the game's own rules (ProgressionHarness).
##
##   godot --headless --path client --script res://tests/harness/HarnessRun.gd -- \
##       --out=/some/folder/outside/the/repository [--quick] [--config=path]
##
## --out is required and must be outside the repository: the harness never
## writes into the project. --quick runs the small set from the config (a
## few seconds); the default runs the full set (minutes). Writes report.json
## and report.md. Exit code 0 on success, 2 on bad arguments, 1 when an
## engine or script error was logged.
##
## Everything is measured, nothing is changed: no game data, no save. The
## boss reward models are comparison scenarios from the config, not game
## values.

const CONFIG := "res://tests/harness/harness_config.json"


## Engine and script errors logged during the run: any one fails it.
class Errors:
	extends Logger

	var seen: PackedStringArray = []

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		if error_type != Logger.ERROR_TYPE_WARNING:
			seen.append(
				"%s (%s:%d in %s)" % [rationale if rationale else code, file, line, function]
			)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var errors := Errors.new()
	OS.add_logger(errors)
	var out_dir := ""
	var quick := false
	var config_path := CONFIG
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--config="):
			config_path = arg.trim_prefix("--config=")
		quick = quick or arg == "--quick"
	var project := ProjectSettings.globalize_path("res://").simplify_path().get_base_dir()
	var target := ProjectSettings.globalize_path(out_dir).simplify_path() if out_dir else ""
	if target == "" or target == project or target.begins_with(project + "/"):
		print("usage: --out=<folder outside the repository %s> [--quick]" % project)
		quit(2)
		return
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(config_path))
	if not config is Dictionary:
		print("cannot read the config at %s" % config_path)
		quit(2)
		return
	var content := ContentDB.load_all()
	var report := _measure(content, config, "quick" if quick else "full")
	report["mode"] = "quick" if quick else "full"
	DirAccess.make_dir_recursive_absolute(target)
	var json := FileAccess.open(target.path_join("report.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify(report, "  "))
	json.close()
	var md := FileAccess.open(target.path_join("report.md"), FileAccess.WRITE)
	md.store_string(_markdown(report))
	md.close()
	print(
		(
			"harness: %s run, %d simulated runs, report in %s"
			% [report["mode"], report["simulated_runs"], target]
		)
	)
	if not errors.seen.is_empty():
		for error in errors.seen:
			print("ERROR engine error during the harness: " + error)
		quit(1)
		return
	quit(0)


func _measure(content: ContentDB, config: Dictionary, mode: String) -> Dictionary:
	var chosen: Dictionary = config[mode]
	var story := {}
	for name: String in config.get("story_scenarios", {}):
		var model := ProgressionHarness.story_model(content, config["story_scenarios"][name])
		if name != "baseline":
			model.erase("areas")
		story[name] = model
	var heroes: Array = content.hero_order if str(chosen["heroes"]) == "all" else chosen["heroes"]
	var areas: Array = (
		StreetMemory.street(content) if str(chosen["areas"]) == "street" else chosen["areas"]
	)
	var groups := {}
	var count := 0
	for area_id: String in areas:
		if content.area(area_id).get("encounters", []).is_empty():
			continue
		var boss := ProgressionHarness.boss_of(content, area_id)
		var modes: Array = [false, true] if boss != "" and bool(chosen["boss_only"]) else [false]
		for gear: String in chosen["gear"]:
			for boss_only: bool in modes:
				var runs: Array = []
				for hero: String in heroes:
					for seed: int in chosen["seeds"]:
						var setup := {
							"area": area_id,
							"hero": hero,
							"gear": gear,
							"seed": seed,
							"boss_only": boss_only,
							"food": chosen["food"],
							"max_ticks": int(chosen["max_ticks"]),
						}
						runs.append(ProgressionHarness.run_area(content, setup))
				count += runs.size()
				var key := "%s|%s|%s" % [area_id, gear, "boss_only" if boss_only else "area"]
				groups[key] = ProgressionHarness.summarize(runs)
	var bosses := {}
	for area_id: String in areas:
		var boss := ProgressionHarness.boss_of(content, area_id)
		var whole: Variant = groups.get("%s|shop|area" % area_id)
		var solo: Variant = groups.get("%s|shop|boss_only" % area_id)
		if boss == "" or whole == null or solo == null:
			continue
		var value := ProgressionHarness.boss_value(
			content, boss, int(content.area(area_id).get("level", 1))
		)
		bosses[area_id] = {
			"value": value,
			"models": ProgressionHarness.boss_models(whole, solo, value, config["boss_models"]),
		}
	return {
		"story": story,
		"areas": groups,
		"boss_models": bosses,
		"boss_model_parameters": config["boss_models"],
		"simulated_runs": count,
		"note": config.get("note", ""),
	}


func _markdown(report: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("# Measurement harness report (%s)" % report["mode"])
	lines.append("")
	lines.append("Story XP model: exact arithmetic. Area rows: simulated with AutoPilot.")
	lines.append("Boss models are comparison scenarios, not game values.")
	lines.append("")
	lines.append("## Story XP model")
	lines.append("")
	lines.append("| Scenario | Quest XP | Combat XP | Final level | XP to cap |")
	lines.append("|---|---|---|---|---|")
	for name: String in report["story"]:
		var s: Dictionary = report["story"][name]
		lines.append(
			(
				"| %s | %d | %d | %d | %d |"
				% [name, s["quest_xp"], s["combat_xp"], s["level"], s["to_cap"]]
			)
		)
	lines.append("")
	lines.append("## Simulated areas (per minute)")
	lines.append("")
	lines.append("| Area, gear, mode | Runs | KOs | Seconds | XP | Coins | Scrap | Alloy |")
	lines.append("|---|---|---|---|---|---|---|---|")
	for key: String in report["areas"]:
		var a: Dictionary = report["areas"][key]
		(
			lines
			. append(
				(
					"| %s | %d | %d | %.0f | %.0f | %.0f | %.2f | %.2f |"
					% [
						key,
						a["runs"],
						a["knockouts"],
						a["seconds_mean"],
						a["xp_per_min"],
						a["coins_per_min"],
						a["scrap_per_min"],
						a["alloy_per_min"],
					]
				)
			)
		)
	lines.append("")
	lines.append("## Boss reward comparison scenarios")
	lines.append("")
	lines.append("| Area | Scenario | XP/min | Coins/min | Alloy/min | Minutes per unique |")
	lines.append("|---|---|---|---|---|---|")
	for area_id: String in report["boss_models"]:
		var models: Dictionary = report["boss_models"][area_id]["models"]
		for name: String in models:
			var m: Dictionary = models[name]
			var unique := (
				"first kill only"
				if m["minutes_per_unique"] < 0
				else ("%.1f" % m["minutes_per_unique"])
			)
			lines.append(
				(
					"| %s | %s | %.0f | %.0f | %.2f | %s |"
					% [
						area_id,
						name,
						m["xp_per_min"],
						m["coins_per_min"],
						m["alloy_per_min"],
						unique
					]
				)
			)
	lines.append("")
	return "\n".join(lines)
