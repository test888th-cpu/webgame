extends TestCase
## Locked exits: the way east opens once the hero has defeated the enemy that
## guards it, the player is told what opens it, and the way back is open.


func _content() -> ContentDB:
	return ContentDB.load_all()


## The hero at the east end of `area`, pushing east, with `defeated` kills.
func _at_east_end(content: ContentDB, area: String, defeated := {}) -> ZoneSim:
	var profile := PlayerProfile.new_game(content)
	profile.defeated = defeated.duplicate()
	var zone := ZoneSim.new(content, profile, area, "east", 3)
	for enemy in zone.enemies():
		zone.fighters.erase(enemy)
	zone.brains.clear()
	zone._encounters.clear()  # no fight starting at the gate
	zone.hero.position.x = zone.bounds.end.x
	return zone


func _push(zone: ZoneSim, dir: Vector2, ticks: int) -> Array[ZoneEvent]:
	var input := FighterInput.new()
	input.move = dir
	var events: Array[ZoneEvent] = []
	for i in ticks:
		events.append_array(zone.tick(input))
	return events


func _count(events: Array[ZoneEvent], type: String) -> int:
	return events.filter(func(e: ZoneEvent) -> bool: return e.type == type).size()


func test_a_guarded_exit_stays_shut_and_says_why() -> void:
	var content := _content()
	var zone := _at_east_end(content, "saltmarket")
	var events := _push(zone, Vector2.RIGHT, 30)
	assert_eq(_count(events, "exit"), 0, "cannot leave")
	assert_eq(_count(events, "exit_locked"), 1, "told once while pushing")
	var gate: Dictionary = (
		events.filter(func(e: ZoneEvent) -> bool: return e.type == "exit_locked")[0].data
	)
	assert_eq(gate["defeat"], "smog_warden", "names the guard")
	assert_eq(gate["done"], 0, "none down yet")
	assert_true(str(gate["hint"]) != "", "with a hint")


func test_defeating_the_guard_opens_the_way() -> void:
	var content := _content()
	var zone := _at_east_end(content, "saltmarket", {"smog_warden": 1})
	assert_true(zone.exit_locked("east").is_empty(), "open")
	var events := _push(zone, Vector2.RIGHT, 1)
	assert_eq(_count(events, "exit"), 1, "leaves for Canal Works")


func test_counts_must_be_met() -> void:
	var content := _content()
	var zone := _at_east_end(content, "rail_yards", {"dock_thug": 7})
	assert_eq(int(zone.exit_locked("east")["done"]), 7, "7 of 8")
	zone.profile.defeated["dock_thug"] = 8
	assert_true(zone.exit_locked("east").is_empty(), "8 of 8 opens it")


func test_the_way_back_is_always_open() -> void:
	var content := _content()
	for area: String in content.areas:
		var exits: Dictionary = content.areas[area].get("exits", {})
		if exits.has("west"):
			assert_true(
				not exits["west"].has("requires"), "%s: the way back is never locked" % area
			)


func test_gates_must_name_a_real_enemy() -> void:
	var content := _content()
	content.areas["saltmarket"]["exits"]["east"]["requires"]["defeat"] = "no_such_enemy"
	content.errors.clear()
	content.validate()
	assert_true(
		Array(content.errors).any(func(e: String) -> bool: return "no_such_enemy" in e),
		"unknown guard reported"
	)
