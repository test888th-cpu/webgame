extends SceneTree
## Levelling-time measurements (LevelingSim) for progression decisions.
##
##   godot --headless --path client --script res://tests/harness/LevelingRun.gd -- \
##       --out=/folder/outside/the/repository [--quick] [--seeds=8] [--part=K/N]
##   godot ... LevelingRun.gd -- --out=<same folder> --merge
##
## Without --merge it measures: the story clear time, XP per hour on every
## farming ground at hero levels around it, and SYNTHETIC grounds re-levelled
## past 50 with synthetic gear. --part=K/N runs every N-th job from K (run N
## processes in parallel), each writing part_K.json; --merge then reads every
## part and writes report.json and report.md with the levelling plans.
## --out must be outside the repository. Nothing in the game is changed:
## synthetic levels and gear live in memory for one run.

const GEARS := {"B": {"gear": "shop", "plus": 0}, "C": {"gear": "boss", "plus": 5}}
const HOURS_PER_DAY := 2.0
## Target bands in hours (the owner's days x HOURS_PER_DAY, mid-points).
const TARGETS := [
	{"from": 50, "to": 60, "hours": 25.0},
	{"from": 60, "to": 65, "hours": 25.0},
	{"from": 65, "to": 70, "hours": 40.0},
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var opts := _options()
	var project := ProjectSettings.globalize_path("res://").simplify_path().get_base_dir()
	var out := str(opts["out"])
	if out == "" or out == project or out.begins_with(project + "/"):
		print("usage: --out=<folder outside the repository %s>" % project)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var content := ContentDB.load_all()
	if bool(opts["merge"]):
		_merge(content, out)
	else:
		_measure(content, opts)
	quit(0)


func _options() -> Dictionary:
	var opts := {"out": "", "quick": false, "seeds": 8, "part": 0, "parts": 1, "merge": false}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			opts["out"] = ProjectSettings.globalize_path(arg.trim_prefix("--out=")).simplify_path()
		elif arg.begins_with("--seeds="):
			opts["seeds"] = int(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--part="):
			var p := arg.trim_prefix("--part=").split("/")
			opts["part"] = int(p[0])
			opts["parts"] = int(p[1])
		opts["quick"] = opts["quick"] or arg == "--quick"
		opts["merge"] = opts["merge"] or arg == "--merge"
	return opts


## Every job, in a fixed order, so --part splits are stable.
func _jobs(content: ContentDB, seeds: int, quick: bool) -> Array:
	var jobs: Array = []
	for seed in range(1, seeds + 1):
		jobs.append({"kind": "story", "hero": "oren", "seed": seed})
	for area_id: String in content.areas:
		if AreaRules.kind(content, area_id) != AreaRules.FARM:
			continue
		var ground := int(content.area(area_id)["level"])
		for level in range(maxi(1, ground - 6), mini(ground + 7, 51), 2):
			for gear: String in GEARS:
				for seed in range(1, seeds + 1):
					jobs.append(
						{
							"kind": "ground",
							"area": area_id,
							"level": level,
							"gear": gear,
							"seed": seed
						}
					)
	for level in range(52, 71, 2):
		for gear: String in GEARS:
			for seed in range(1, seeds + 1):
				var job := {"kind": "syn", "area": "farm_core_overflow", "level": level}
				job.merge({"gear": gear, "seed": seed})
				jobs.append(job)
	if quick:
		return jobs.filter(func(j: Dictionary) -> bool: return int(j["seed"]) == 1).slice(0, 12)
	return jobs


func _measure(content: ContentDB, opts: Dictionary) -> void:
	var results: Array = []
	var jobs := _jobs(content, int(opts["seeds"]), bool(opts["quick"]))
	for i in jobs.size():
		if i % int(opts["parts"]) != int(opts["part"]):
			continue
		var job: Dictionary = jobs[i]
		var result := job.duplicate()
		if job["kind"] == "story":
			result.merge(LevelingSim.story_time(content, str(job["hero"]), int(job["seed"])))
		else:
			var setup := {"area": job["area"], "level": job["level"], "seed": job["seed"]}
			setup.merge(GEARS[job["gear"]])
			if job["kind"] == "syn":
				setup.merge({"area_level": job["level"], "syn_gear": true})
			var run := LevelingSim.farm_rate(content, setup)
			result.merge(
				{"xp_per_hour": run["xp_per_hour"], "ko": run["ko"], "kills": run["kills"]}
			)
		results.append(result)
	var path := str(opts["out"]).path_join("part_%d.json" % int(opts["part"]))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"seeds": opts["seeds"], "results": results}))
	print("leveling: %d jobs measured into %s" % [results.size(), path])


func _merge(content: ContentDB, out: String) -> void:
	var results: Array = []
	for name in DirAccess.get_files_at(out):
		if name.begins_with("part_") and name.ends_with(".json"):
			var part: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string(out.path_join(name))
			)
			results.append_array(part["results"])
	var report := _report(content, results)
	var json := FileAccess.open(out.path_join("report.json"), FileAccess.WRITE)
	json.store_string(JSON.stringify(report, "  "))
	var md := FileAccess.open(out.path_join("report.md"), FileAccess.WRITE)
	md.store_string(_markdown(report))
	print("leveling: merged %d results into %s" % [results.size(), out])


## Mean rates: {"real": {gear: {area: {level: xp/h}}}, "syn": {gear: {level: xp/h}}}.
func _rates(results: Array) -> Dictionary:
	var sums := {}
	for r: Dictionary in results:
		if r["kind"] == "story":
			continue
		var key := [r["kind"], r["gear"], r.get("area", ""), int(r["level"])]
		var entry: Array = sums.get(key, [0.0, 0, 0])
		entry[0] += float(r["xp_per_hour"])
		entry[1] += 1
		entry[2] += int(bool(r["ko"]))
		sums[key] = entry
	var rates := {"real": {}, "syn": {}, "ko": {}}
	for key: Array in sums:
		var mean: float = sums[key][0] / sums[key][1]
		var gear := str(key[1])
		if key[0] == "ground":
			var by_gear: Dictionary = rates["real"].get(gear, {})
			var by_area: Dictionary = by_gear.get(key[2], {})
			by_area[int(key[3])] = mean
			by_gear[key[2]] = by_area
			rates["real"][gear] = by_gear
		else:
			var syn: Dictionary = rates["syn"].get(gear, {})
			syn[int(key[3])] = mean
			rates["syn"][gear] = syn
		if int(sums[key][2]) > 0:
			rates["ko"]["%s %s %s %d" % key] = "%d/%d" % [sums[key][2], sums[key][1]]
	return rates


## XP per hour at `level` on SYNTHETIC grounds, interpolated between samples.
static func _syn_rate(syn: Dictionary, level: int) -> float:
	if syn.is_empty():
		return 0.0
	var below := -1
	var above := 1000
	for l: int in syn:
		if l <= level and l > below:
			below = l
		if l >= level and l < above:
			above = l
	if below < 0:
		return float(syn[above])
	if above == 1000 or above == below:
		return float(syn[below])
	var t := float(level - below) / (above - below)
	return lerpf(float(syn[below]), float(syn[above]), t)


func _report(content: ContentDB, results: Array) -> Dictionary:
	var rates := _rates(results)
	var story_s := 0.0
	var story_n := 0
	var story_ko := 0
	for r: Dictionary in results:
		if r["kind"] == "story":
			story_s += float(r["seconds"])
			story_ko += int(r["ko"])
			story_n += 1
	var curve: Dictionary = content.progression["xp"]
	var model := ProgressionHarness.story_model(content)
	var report := {
		"story_runs": story_n,
		"story_hours": story_s / maxi(1, story_n) / 3600.0,
		"story_knockouts": story_ko,
		"story_level": model["level"],
		"story_xp": int(model["quest_xp"]) + int(model["combat_xp"]),
		"rates": rates,
		"plans": {},
	}
	for gear: String in GEARS:
		var real: Dictionary = rates["real"].get(gear, {})
		var syn: Dictionary = rates["syn"].get(gear, {})
		var real_at := func(level: int) -> float: return LevelingSim.best_rate(real, level)
		var syn_at := func(level: int) -> float: return _syn_rate(syn, level)
		var finish := LevelingSim.plan(curve, int(model["level"]), 50, real_at)
		var farm_only := LevelingSim.plan(curve, 1, 50, real_at)
		var cur_real := LevelingSim.plan(curve, 50, 70, real_at)
		var cur_syn := LevelingSim.plan(curve, 50, 70, syn_at)
		var proposal := LevelingSim.propose(TARGETS, syn_at, 1.06)
		report["plans"][gear] = {
			"to_50_story_then_farm": report["story_hours"] + float(finish["hours"]),
			"to_50_farm_only": farm_only["hours"],
			"per_level_1_50_farm_only": farm_only["levels"],
			"current_curve_50_70_real_grounds": cur_real,
			"current_curve_50_70_synthetic_grounds": cur_syn,
			"proposal": proposal,
			"proposal_plan": LevelingSim.plan(proposal, 50, 70, syn_at),
		}
	return report


func _markdown(report: Dictionary) -> String:
	var lines: Array[String] = ["# Levelling-time report", ""]
	lines.append(
		(
			"Story: %d runs, %.2f h average, %d knock-outs; one pass reaches level %d."
			% [
				report["story_runs"],
				report["story_hours"],
				report["story_knockouts"],
				report["story_level"]
			]
		)
	)
	for gear: String in report["plans"]:
		var p: Dictionary = report["plans"][gear]
		lines.append("")
		lines.append("## Profile %s" % gear)
		lines.append("- Level 1 to 50, story then farm: %.2f h" % p["to_50_story_then_farm"])
		lines.append("- Level 1 to 50, farming only: %.2f h" % p["to_50_farm_only"])
		lines.append(
			(
				"- Level 50 to 70, current curve, real grounds: %.1f h"
				% p["current_curve_50_70_real_grounds"]["hours"]
			)
		)
		lines.append(
			(
				"- Level 50 to 70, current curve, SYNTHETIC grounds: %.1f h"
				% p["current_curve_50_70_synthetic_grounds"]["hours"]
			)
		)
		lines.append("- Proposal plan 50 to 70: %.1f h" % p["proposal_plan"]["hours"])
	lines.append("")
	lines.append("Hours per day assumed: %.1f." % HOURS_PER_DAY)
	return "\n".join(lines) + "\n"
