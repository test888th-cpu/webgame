extends TestCase
## RpgSpellbook (the Skills screen's spellbook and the hotbar layout) and the
## copy-keeping equip of RpgCharacter, and their save round trip.


func _db() -> ContentDB:
	return GameSession.content


func _pack() -> Dictionary:
	return RpgPack.of(_db())


func test_the_book_agrees_with_abilities_known_at() -> void:
	var pack := _pack()
	for cls: String in ["warrior", "mage", "priest", "rogue", "hunter"]:
		var state := RpgCharacter.create(_db(), pack, cls)
		state["level"] = 12
		var u := RpgUnit.player(_db(), pack, state)
		var known := {}
		for k: Dictionary in RpgTalents.known(pack, cls, 12, u["mods"]):
			known[k["id"]] = true
		for e: Dictionary in RpgSpellbook.book(pack, cls, 12, u["mods"]):
			var is_known: bool = e["state"] == "usable" or e["state"] == "known_blocked"
			assert_eq(is_known, known.has(e["id"]), cls + ": " + str(e["id"]))
			if e["state"] == "usable":
				assert_true(
					str(pack["abilities"][e["id"]]["status"]).begins_with("IMPLEMENTED"),
					str(e["id"]) + ": only implemented abilities are usable"
				)


func test_the_hotbar_keeps_only_usable_abilities() -> void:
	var pack := _pack()
	var state := RpgCharacter.create(_db(), pack, "warrior")
	state["level"] = 10
	var mods: Dictionary = RpgUnit.player(_db(), pack, state)["mods"]
	var usable := RpgSpellbook.usable_ids(pack, "warrior", 10, mods)
	var bar := RpgSpellbook.hotbar(pack, state, mods, 6)
	assert_eq(bar.size(), 6, "six ability slots")
	assert_eq(bar, usable.slice(0, 6), "by default, the usable ones in order")
	assert_eq(RpgSpellbook.assign(pack, state, mods, 5, usable[0], 6), "", "moved")
	assert_eq(state["hotbar"][5], usable[0], "in slot 7")
	assert_true(not usable[0] in state["hotbar"].slice(0, 5), "and only once")
	# A known ability this engine does not run (any class's first one) is refused,
	# and a stale saved entry shows empty.
	var refused := 0
	for cls: String in pack["classes"]:
		var s := RpgCharacter.create(_db(), pack, cls)
		s["level"] = 20
		var m: Dictionary = RpgUnit.player(_db(), pack, s)["mods"]
		var ok := RpgSpellbook.usable_ids(pack, cls, 20, m)
		for k: Dictionary in RpgTalents.known(pack, cls, 20, m):
			if k["id"] in ok or k["def"].get("passive", false):
				continue
			assert_eq(
				RpgSpellbook.assign(pack, s, m, 0, str(k["id"]), 6),
				"That ability cannot be used yet.",
				cls + ": a known ability this engine does not run is refused"
			)
			s["hotbar"] = [str(k["id"])]
			assert_eq(
				RpgSpellbook.hotbar(pack, s, m, 6)[0], "", cls + ": a stale entry shows empty"
			)
			refused += 1
			break
	assert_true(refused > 0, "some class still has a known ability not run")


func test_equip_keeps_the_copy_and_refusals_change_nothing() -> void:
	var pack := _pack()
	var state := RpgCharacter.create(_db(), pack, "warrior")
	var q := {"tier": 3, "weights": [4]}
	RpgCharacter.add_item(state, "rusty_hatchet", 1, null)
	RpgCharacter.add_item(state, "rusty_hatchet", 1, q)
	assert_eq(RpgCharacter.equip_problem(_db(), pack, state, 1), "", "it can be worn")
	assert_eq(RpgCharacter.equip(_db(), pack, state, "rusty_hatchet", "", 1), "", "worn")
	assert_eq(state["equipment_quality"]["mainhand"], q, "the chosen copy, not the first")
	assert_eq(state["inventory"][0]["quality"], null, "the other copy stays as it was")
	var before := state.duplicate(true)
	assert_true(RpgCharacter.equip(_db(), pack, state, "worn_sword", "", 0) != "", "wrong copy")
	assert_true(RpgCharacter.equip_problem(_db(), pack, state, 9) != "", "no such copy")
	assert_eq(state, before, "refusals change nothing")
	var saved := RpgSave.from_dict(RpgSave.to_dict(state), _db(), pack)
	assert_eq(saved["problems"].size(), 0, "loads")
	assert_eq(saved["state"]["equipment_quality"], state["equipment_quality"], "quality saved")
	state["hotbar"] = ["hamstring", "", "berserker_rage"]
	var again := RpgSave.from_dict(RpgSave.to_dict(state), _db(), pack)
	assert_eq(again["state"]["hotbar"], state["hotbar"], "the hotbar is saved")
