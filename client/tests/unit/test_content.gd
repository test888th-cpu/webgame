extends TestCase
## Shipped content is valid, and the validator catches broken content.


func test_shipped_content_is_valid() -> void:
	var content := ContentDB.load_all()
	assert_true(content.is_valid(), "content errors:\n" + "\n".join(content.errors))
	assert_true(content.areas.has(content.start_area), "start area exists")


func test_validator_reports_broken_references() -> void:
	var content := ContentDB.load_all()
	content.errors.clear()
	content.enemies["broken"] = {
		"max_hp": 0,
		"speed": 1,
		"xp": 1,
		"moveset": {"light": "no_such_move", "kick": "jab"},
		"ai": null,
		"loot": {"money": [5, 1], "drops": [{"item": "no_such_item", "chance": 2}]},
		"phases": [{"below": 1.5}],
	}
	content.quests["broken"] = {"objective": {"type": "defeat", "enemy": "nobody", "count": 1}}
	content.shops["broken"] = {"items": ["no_such_item"]}
	content.areas["broken"] = {
		"width": 900,
		"exits": {"north": {"to": "nowhere", "entry": "up"}},
		"encounters":
		[{"trigger_x": 50, "arena": [100, 300], "max_alive": 1, "waves": [["ghost"]]}],
	}
	content.validate()
	var all := "\n".join(content.errors)
	for expected in [
		"enemies.broken.max_hp",
		"unknown move no_such_move",
		"unknown input kick",
		"loot.money",
		"unknown item no_such_item",
		"drops.chance",
		"phases.below",
		"quests.broken.objective: unknown enemy nobody",
		"shops.broken: unknown item",
		"exits: unknown side north",
		"unknown area nowhere",
		"at least 320 px wide",
		"trigger_x: must lie inside the arena",
		"unknown enemy ghost",
	]:
		assert_true(all.contains(expected), "reports: " + expected)


func test_every_enemy_can_attack_or_is_training() -> void:
	var content := ContentDB.load_all()
	for id: String in content.enemies:
		var e: Dictionary = content.enemies[id]
		if e.get("training", false):
			continue
		assert_true(e.get("moveset", {}).has("light"), "%s has a light attack" % id)
		assert_true(e.get("ai") != null, "%s has AI" % id)
