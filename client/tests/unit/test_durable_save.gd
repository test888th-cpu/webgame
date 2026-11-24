extends TestCase
## DurableSave's guarantees, with the browser store replaced by a controllable
## commit step (DurableSave.committer): a save is reported durable only when a
## commit of that state or a newer one completed; commits for a file run one at a
## time, newest text each time, so the store never ends on an older state; a failed
## commit retries and never counts. Then the street itself: rapid hotbar, gear and
## bag changes end with the latest state committed.

const DIR := "user://test_durable_save"
const SCENE := "res://scenes/street/Street.tscn"

## Frames each fake commit takes, consumed in order (then 1), and results to give
## (then "ok"). `log` records every commit started, in order.
var delays: Array[int] = []
var results: Array[String] = []
var log: Array[String] = []


func _fake(_key: String, text: String) -> String:
	log.append(text)
	var frames: int = delays.pop_front() if not delays.is_empty() else 1
	for _i in frames:
		await tree.process_frame
	return results.pop_front() if not results.is_empty() else "ok"


func _setup() -> void:
	DurableSave.reset()
	delays.clear()
	results.clear()
	log.clear()
	DurableSave.committer = _fake
	DirAccess.make_dir_recursive_absolute(DIR)


func _teardown() -> void:
	DurableSave.committer = Callable()
	DurableSave.reset()


func _write(path: String, text: String) -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return DurableSave.request(path)


func _frames(n: int) -> void:
	for _i in n:
		await tree.process_frame


func test_a_newer_save_is_never_reported_by_an_older_commit() -> void:
	_setup()
	var path := DIR.path_join("a.json")
	delays.assign([20, 40])
	var one := _write(path, "A")
	await _frames(2)
	var two := _write(path, "B")
	var three := _write(path, "C")
	assert_eq(DurableSave.durable_seq(path), 0, "nothing durable while A is in flight")
	await _frames(20)
	assert_eq(DurableSave.durable_seq(path), one, "A landed: only A's number is durable")
	assert_true(DurableSave.durable_seq(path) < three, "C is not reported yet")
	assert_true(await DurableSave.wait_durable(path, three, 5.0), "C lands")
	assert_true(await DurableSave.wait_durable(path, two, 0.1), "B counts: a newer state is")
	assert_eq(log, ["A", "C"] as Array[String], "one at a time; B was folded into C")
	var key := ProjectSettings.globalize_path(path)
	assert_eq(DurableSave.history[key][-1], "C", "the store ends on the newest text")
	_teardown()


func test_a_failed_commit_retries_and_never_counts() -> void:
	_setup()
	var path := DIR.path_join("b.json")
	results.assign(["error", "error"])
	var seq := _write(path, "X")
	await _frames(3)
	assert_eq(DurableSave.durable_seq(path), 0, "a failed commit is not durable")
	assert_eq(DurableSave.last_error(path), "error", "the failure is known")
	assert_true(await DurableSave.wait_durable(path, seq, 10.0), "a retry lands it")
	assert_eq(log.size(), 3, "two failures, then the commit that landed")
	assert_eq(DurableSave.last_error(path), "", "no error left")
	_teardown()


func test_a_wait_times_out_as_not_yet_and_the_commit_goes_on() -> void:
	_setup()
	var path := DIR.path_join("c.json")
	delays.assign([90])
	var seq := _write(path, "slow")
	assert_true(not await DurableSave.wait_durable(path, seq, 0.05), "a time-out is not success")
	assert_true(await DurableSave.wait_durable(path, seq, 10.0), "the same commit lands later")
	assert_eq(log.size(), 1, "no second commit was started for the time-out")
	_teardown()


func test_rapid_street_changes_end_with_the_latest_state_committed() -> void:
	_setup()
	SaveStore.root = DIR
	var db := GameSession.content
	var state := RpgCharacter.create(db, RpgPack.of(db), "warrior")
	state["id"] = SaveStore.new_id()
	state["name"] = "Racer"
	state["area"] = "depot_yard"
	state["level"] = 10
	RpgCharacter.add_item(state, "rusty_hatchet", 1, {"tier": 1, "weights": [3]})
	RpgCharacter.add_item(state, "spider_leg", 2, null)
	assert_true(SaveStore.save_player(state), "saved")
	GameSession.character_id = state["id"]
	var street: Node2D = load(SCENE).instantiate()
	street.set("navigate", false)
	tree.root.add_child(street)
	await tree.process_frame
	delays.assign([15, 15, 15, 15, 15, 15])
	var menus: StreetMenuHost = street.get("menus")
	var live: Dictionary = street.get("state")
	var usable := RpgSpellbook.usable_ids(
		RpgPack.of(db), "warrior", 10, street.get("fight").player["mods"]
	)
	# Rapid changes, each saving while earlier commits are still in flight.
	for i in 6:
		menus.menu_action("hotbar", [i % 6, usable[i % usable.size()]])
	menus.menu_action("equip", 0)
	menus.menu_action("unequip", "chest")
	var path := SaveStore.player_folder().path_join(str(live["id"]) + ".json")
	var last := DurableSave.requested_seq(path)
	assert_true(await DurableSave.wait_durable(path, last, 20.0), "the latest change lands")
	var key := ProjectSettings.globalize_path(path)
	var committed: Variant = JSON.parse_string(DurableSave.history[key][-1])
	var back: Dictionary = RpgSave.from_dict(committed, db, RpgPack.of(db))["state"]
	assert_eq(back["hotbar"], live["hotbar"], "the committed hotbar is the final one")
	assert_eq(back["equipment"], live["equipment"], "the committed gear is the final gear")
	assert_eq(back["equipment_quality"], live["equipment_quality"], "with its copy quality")
	var ids := func(s: Dictionary) -> Array:
		return s["inventory"].map(func(r: Dictionary) -> String: return r["item_id"])
	assert_eq(ids.call(back), ids.call(live), "the committed bag is the final bag")
	assert_true(log.size() < 9, "saves made while one was in flight were folded together")
	SaveStore.delete_player(live["id"])
	street.free()
	SaveStore.root = SaveStore.DEFAULT_ROOT
	GameSession.character_id = ""
	_teardown()


func _street(cls: String) -> Node2D:
	SaveStore.root = DIR
	var db := GameSession.content
	var state := RpgCharacter.create(db, RpgPack.of(db), cls)
	state["id"] = SaveStore.new_id()
	state["name"] = "Saver"
	state["area"] = "depot_yard"
	state["level"] = 10
	assert_true(SaveStore.save_player(state), "saved")
	GameSession.character_id = state["id"]
	var street: Node2D = load(SCENE).instantiate()
	street.set("navigate", false)
	tree.root.add_child(street)
	await tree.process_frame
	return street


func _street_done(street: Variant, id: String) -> void:
	SaveStore.delete_player(id)
	if is_instance_valid(street):
		street.free()
	SaveStore.root = SaveStore.DEFAULT_ROOT
	GameSession.character_id = ""


func _committed_state(path: String) -> Dictionary:
	var key := ProjectSettings.globalize_path(path)
	var db := GameSession.content
	return (
		RpgSave
		. from_dict(JSON.parse_string(DurableSave.history[key][-1]), db, RpgPack.of(db))["state"]
	)


func test_an_old_periodic_save_landing_does_not_confirm_a_newer_change() -> void:
	_setup()
	var street := await _street("warrior")
	var live: Dictionary = street.get("state")
	var path := SaveStore.player_folder().path_join(str(live["id"]) + ".json")
	await DurableSave.wait_durable(path, DurableSave.requested_seq(path), 5.0)
	log.clear()
	delays.assign([25, 25])
	street._save()  # the periodic save, slow to commit
	var periodic := DurableSave.requested_seq(path)
	var usable := RpgSpellbook.usable_ids(
		RpgPack.of(GameSession.content), "warrior", 10, street.get("fight").player["mods"]
	)
	street.get("menus").menu_action("hotbar", [5, usable[0]])
	var change := DurableSave.requested_seq(path)
	assert_true(change > periodic, "the change is a newer request")
	assert_true(await DurableSave.wait_durable(path, periodic, 5.0), "the periodic save lands")
	assert_true(DurableSave.durable_seq(path) < change, "and does not confirm the change")
	assert_true(await DurableSave.wait_durable(path, change, 5.0), "the change lands next")
	assert_eq(_committed_state(path)["hotbar"][5], usable[0], "with the change in it")
	_street_done(street, live["id"])
	_teardown()


func test_settings_saved_while_a_character_save_is_pending() -> void:
	_setup()
	var street := await _street("priest")
	var live: Dictionary = street.get("state")
	var path := SaveStore.player_folder().path_join(str(live["id"]) + ".json")
	await DurableSave.wait_durable(path, DurableSave.requested_seq(path), 5.0)
	delays.assign([40, 2, 2])
	street._save()
	var char_seq := DurableSave.requested_seq(path)
	var was := bool(GameSession.settings.get("show_fps", false))
	GameSession.set_setting("show_fps", not was)
	GameSession.set_setting("show_fps", was)
	var settings_seq := DurableSave.requested_seq(GameSession.SETTINGS_PATH)
	assert_true(
		await DurableSave.wait_durable(GameSession.SETTINGS_PATH, settings_seq, 5.0),
		"settings commit on their own, not behind the character"
	)
	assert_true(DurableSave.durable_seq(path) < char_seq, "the character save is still pending")
	var key := ProjectSettings.globalize_path(GameSession.SETTINGS_PATH)
	var final: Dictionary = JSON.parse_string(DurableSave.history[key][-1])
	assert_eq(final["show_fps"], was, "the committed settings are the last ones set")
	assert_true(await DurableSave.wait_durable(path, char_seq, 5.0), "the character lands too")
	_street_done(street, live["id"])
	_teardown()


func test_an_aborted_commit_is_retried_with_the_newest_state() -> void:
	_setup()
	var path := DIR.path_join("abort.json")
	delays.assign([5])
	results.assign(["abort"])
	var first := _write(path, "old")
	await _frames(2)
	var second := _write(path, "new")
	assert_true(await DurableSave.wait_durable(path, second, 10.0), "lands after the abort")
	assert_true(await DurableSave.wait_durable(path, first, 0.1), "the older request is covered")
	assert_eq(log, ["old", "new"] as Array[String], "the retry carried the newest text")
	var key := ProjectSettings.globalize_path(path)
	assert_eq(DurableSave.history[key], ["new"], "only the newest text was ever committed")
	_teardown()


func test_leaving_the_street_while_a_save_is_pending() -> void:
	_setup()
	var street := await _street("rogue")
	var live: Dictionary = street.get("state")
	var id := str(live["id"])
	var path := SaveStore.player_folder().path_join(id + ".json")
	await DurableSave.wait_durable(path, DurableSave.requested_seq(path), 5.0)
	delays.assign([30])
	RpgCharacter.add_item(live, "spider_leg", 1, null)
	street._save()
	var seq := DurableSave.requested_seq(path)
	street.free()  # the scene goes while its save is still committing
	assert_true(await DurableSave.wait_durable(path, seq, 5.0), "the save still lands")
	var back := _committed_state(path)
	assert_eq(back["inventory"].size(), 1, "with the change made before leaving")
	_street_done(street, id)
	_teardown()
