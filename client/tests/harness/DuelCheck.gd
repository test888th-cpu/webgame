extends SceneTree
## PvP 1 against 1 (DuelSim): every pairing of the heroes at each --levels,
## --seeds matches each way round. Prints each hero's win rate against the
## other jobs, the win table, the longest lock (ticks a fighter could not
## act), the largest single blow as a share of health, the mean match length
## and the combos each hero completed. Read-only.
##
##   godot --headless --path client --script res://tests/harness/DuelCheck.gd -- \
##     --levels=30,50,70 --seeds=10
##
## Prints one "DUEL " JSON line per level.


func _init() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.trim_prefix("--").split("=", true, 1)
			args[parts[0]] = parts[1]
	var content := ContentDB.load_all()
	var heroes: Array = content.hero_order
	var seeds := int(args.get("seeds", 10))
	for level in str(args.get("levels", "30,50,70")).split(","):
		var result := DuelSim.table(content, heroes, int(level), seeds)
		var line := {
			"level": int(level),
			"win_rate": DuelSim.win_rates(result),
			"wins": result["wins"],
			"longest_lock_ticks": result["lock"],
			"biggest_blow_share": snappedf(result["biggest"], 0.01),
			"biggest_blow": result["biggest_move"],
			"mean_seconds": snappedf(result["ticks"] / CombatRules.TICK_RATE, 0.1),
			"draws": result["draws"],
			"combos": result["combos"],
		}
		print("DUEL " + JSON.stringify(line))
	quit(0)
