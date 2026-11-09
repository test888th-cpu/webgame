extends SceneTree
## Prices gear with the game's own ItemRules for content tooling
## (tools/content/level70_content.py), so no tool re-implements the budget:
##
##   godot --headless --path client --script res://tests/harness/ItemBudgetQuery.gd -- --in=req.json
##
## req.json is [{"slot", "rarity", "level", "stats"}, ...]; it prints one JSON
## array of {"budget", "score"} in the same order. Reads only; writes nothing.


func _initialize() -> void:
	var path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			path = arg.trim_prefix("--in=")
	var request: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not request is Array:
		print("usage: --in=<a JSON array of items>")
		quit(2)
		return
	var out: Array = []
	for item: Dictionary in request:
		out.append({"budget": ItemRules.budget(item), "score": ItemRules.score(item)})
	print("BUDGETS " + JSON.stringify(out))
	quit(0)
