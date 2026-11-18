extends SceneTree
## Writes docs/ITEM_DROP_DATABASE.md (DropReport):
##   godot --headless --path client --script res://tests/harness/DropReportRun.gd


func _initialize() -> void:
	var content := ContentDB.load_all()
	var path := ProjectSettings.globalize_path("res://").path_join("../docs/ITEM_DROP_DATABASE.md")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(DropReport.build(content))
	file.close()
	print("wrote ", path)
	var impact := path.get_base_dir().path_join("GODFORGED_IMPACT_REPORT.md")
	file = FileAccess.open(impact, FileAccess.WRITE)
	file.store_string(DropReport.godforged_impact(content))
	file.close()
	print("wrote ", impact)
	quit()
