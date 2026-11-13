extends SceneTree
## Arena balance report (ArenaSim): the comparisons in docs/ARENA_BALANCE.md,
## --seeds matches each (sides swapped every other match), seeds 1000 +
## n * 7919. Prints one "ARENA " JSON line per comparison. Read-only.
##
##   godot --headless --path client --script res://tests/harness/ArenaBalance.gd -- \
##     --seeds=200 [--only=gear,ai,builds,personality,jobs,jobs_mixed,tiers,cap]
## (jobs_mixed: the job pairs with AI skill and personality drawn per match.)


func _init() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=", true, 1)
			args[parts[0]] = parts[1]
	var content := ContentDB.load_all()
	var seeds := int(args.get("seeds", 200))
	var only := str(args.get("only", "gear,ai,builds,personality,jobs,tiers,cap")).split(",")
	var job := str(content.job_order[0])
	var top := {"job": job, "level": 70, "grades": ["godforged"], "ai": 0.7}
	for group: String in only:
		for row: Array in scenarios(content, group, top, job):
			var started := Time.get_ticks_msec()
			var mix := group.ends_with("_mixed")
			var result := ArenaSim.series(content, row[1], row[2], seeds, float(row[3]), mix)
			result["name"] = row[0]
			result["group"] = group
			result["seeds"] = seeds
			result["ms"] = Time.get_ticks_msec() - started
			print("ARENA " + JSON.stringify(result))
	quit(0)


## [name, side a, side b, cap] rows of a group.
static func scenarios(content: ContentDB, group: String, top: Dictionary, job: String) -> Array:
	var rows: Array = []
	match group:
		"gear":
			var common := _with(top, {"grades": ["common"], "plus": 0})
			rows.append(["Godforged +0 vs Common +0", _with(top, {"plus": 0}), common, 0.0])
			for plus in [3, 7, 10]:
				var name := "Godforged +%d vs Godforged +0" % plus
				rows.append([name, _with(top, {"plus": plus}), _with(top, {"plus": 0}), 0.0])
		"ai":
			for pair: Array in [[0.9, 0.3], [0.7, 0.5], [1.0, 0.0]]:
				rows.append(
					[
						"AI %.1f vs AI %.1f (same gear)" % pair,
						_with(top, {"plus": 0, "ai": pair[0]}),
						_with(top, {"plus": 0, "ai": pair[1]}),
						0.0
					]
				)
			rows.append(
				[
					"+0 at AI 1.0 vs +7 at AI 0.3",
					_with(top, {"plus": 0, "ai": 1.0}),
					_with(top, {"plus": 7, "ai": 0.3}),
					0.0
				]
			)
		"builds":
			var mid := {"job": job, "level": 40, "grades": ["epic"], "plus": 0, "ai": 0.7}
			for pair: Array in [
				["heavy", "balanced"], ["fast", "defensive"], ["critical", "defensive"]
			]:
				rows.append(
					[
						"%s vs %s (epic, level 40)" % pair,
						_with(mid, {"preset": pair[0]}),
						_with(mid, {"preset": pair[1]}),
						0.0
					]
				)
		"personality":
			for pair: Array in [
				["counter", "aggressive"], ["tactical", "balanced"], ["defensive", "aggressive"]
			]:
				rows.append(
					[
						"%s vs %s (same gear)" % pair,
						_with(top, {"plus": 0, "personality": pair[0]}),
						_with(top, {"plus": 0, "personality": pair[1]}),
						0.0
					]
				)
		"jobs", "jobs_mixed":
			for a: String in content.job_order:
				for b: String in content.job_order:
					if a < b:
						rows.append(
							[
								"%s vs %s (Godforged +0)" % [a, b],
								_with(top, {"plus": 0, "job": a}),
								_with(top, {"plus": 0, "job": b}),
								0.0
							]
						)
		"tiers":
			# A player stand-in (AI 0.55, Godforged +0 at level 70) against a
			# rival from the middle of each tier, as configured.
			var proxy := _with(top, {"plus": 0, "ai": 0.55, "personality": "balanced"})
			for rank in [48, 43, 38, 33, 25, 18, 13, 8, 3]:
				var data := ArenaRules.rival(content, ArenaRules.rival_id(rank))
				var rival := {
					"job": data["job"],
					"level": data["level"],
					"ai": data["ai"],
					"personality": data["personality"],
					"preset": data["preset"],
					"slots": _slots_of(data),
				}
				rows.append(
					["Player stand-in vs rank %d (%s)" % [rank, data["tier"]], proxy, rival, 0.0]
				)
		"cap":
			for cap in [0.3, 0.15]:
				for plus in [7, 10]:
					rows.append(
						[
							"Godforged +%d vs +0 with a %d%% cap" % [plus, roundi(cap * 100)],
							_with(top, {"plus": plus}),
							_with(top, {"plus": 0}),
							cap
						]
					)
	return rows


static func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	out.merge(changes, true)
	return out


## A resolved rival's gear as per-slot settings (items and upgrades).
static func _slots_of(data: Dictionary) -> Dictionary:
	var out := {}
	for slot: String in data["slots"]:
		out[slot] = {"item": data["slots"][slot]["item"], "plus": data["slots"][slot]["plus"]}
	for slot: String in PlayerProfile.SLOTS:
		if not out.has(slot):
			out[slot] = {"empty": true}
	return out
