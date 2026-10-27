extends TestCase
## Chapter 2, the Port District: four areas past the Gang Headquarters, a
## quest chain from Uncle Chai at Port Road ending with Harbourmaster Chen,
## and Chen's crane: a container dropped on the hero's spot after a warning
## shadow, which hurts anyone under it but Chen himself.

const PORT := ["port_road", "freight_market", "container_yard", "crane_yard"]

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## A crane yard holding only the hero and Chen, the fight already on.
func _chen_fight() -> ZoneSim:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "crane_yard", "", 7)
	var events: Array[ZoneEvent] = []
	zone._start_encounter(1, events)
	zone._waves_left.clear()  # Chen alone, no wave after him
	for i in 240:
		zone.tick(FighterInput.new())
		if zone.boss_id != 0:
			break
	zone.hero.max_hp = 100000
	zone.hero.hp = 100000
	return zone


func _chen(zone: ZoneSim) -> Fighter:
	return zone.fighter(zone.boss_id)


## Chen keeps his brain (the fight goes on) but never swings: only the crane acts.
func _hold(zone: ZoneSim) -> void:
	var brain: EnemyBrain = zone.brains[zone.boss_id]
	brain.cooldown = 100000


func test_the_port_follows_the_gang_headquarters() -> void:
	var street := StreetMemory.street(_content())
	var at := street.find("gang_hq")
	for i in PORT.size():
		assert_eq(street[at + 1 + i], PORT[i], "%s in order" % PORT[i])
	var gate: Dictionary = _content().area("gang_hq")["exits"]["east"]["requires"]
	assert_eq(str(gate["defeat"]), "furnace_baron", "the port opens once the Baron is down")


func test_chen_ends_chapter_two_with_new_evidence() -> void:
	var quest: Dictionary = _content().quests["harbourmaster"]
	assert_eq(str(quest["objective"]["enemy"]), "harbourmaster_chen", "Chen is the target")
	assert_true(quest.has("ends_chapter"), "beating him ends the chapter")
	var evidence := _content().item("altered_manifest")
	assert_eq(str(evidence.get("type")), "key", "the manifest is evidence")
	assert_true(int(quest["rewards"]["items"].get("altered_manifest", 0)) == 1, "handed over")
	assert_eq(str(_content().quests["dock_shakedown"]["requires"]), "furnace_baron", "after ch. 1")


func test_the_crane_warns_then_drops_on_the_spot() -> void:
	var zone := _chen_fight()
	var chen := _chen(zone)
	chen.position = Vector2(1500, 280)
	var hazard: Dictionary = _content().enemy("harbourmaster_chen")["hazard"]
	var warned := -1
	var landed := -1
	var at := Vector2.ZERO
	for tick in int(hazard["every"]) + int(hazard["warn"]) + 10:
		zone.hero.position = Vector2(1000, 300)
		chen.position = Vector2(1500, 280)
		_hold(zone)
		for event in zone.tick(FighterInput.new()):
			if event.type == "hazard_warn" and warned < 0:
				warned = tick
				at = event.data["at"]
			if event.type == "hazard_hit" and landed < 0:
				landed = tick
	assert_true(warned >= 0, "the shadow appears")
	assert_near(at.x, 1000.0, "over where the hero stood")
	assert_eq(landed - warned, int(hazard["warn"]), "and the container lands after the warning")
	assert_true(zone.hero.hp < zone.hero.max_hp, "standing still under it hurts")


func test_stepping_out_of_the_shadow_is_safe_and_chen_is_never_hit() -> void:
	var zone := _chen_fight()
	var chen := _chen(zone)
	var hazard: Dictionary = _content().enemy("harbourmaster_chen")["hazard"]
	var hp := 0
	var chen_hp := 0
	var drop_at := Vector2.INF
	for tick in int(hazard["every"]) + int(hazard["warn"]) + 10:
		_hold(zone)
		if drop_at != Vector2.INF:
			# Chen stands right in it; the hero has walked well clear.
			chen.position = drop_at
			zone.hero.position = drop_at + Vector2(120, 0)
		for event in zone.tick(FighterInput.new()):
			if event.type == "hazard_warn":
				drop_at = event.data["at"]
				chen.position = drop_at
				zone.hero.position = drop_at + Vector2(120, 0)
				hp = zone.hero.hp
				chen_hp = chen.hp
	assert_true(hp > 0, "a drop was called")
	assert_eq(zone.hero.hp, hp, "out of the shadow: no harm")
	assert_eq(chen.hp, chen_hp, "the crane never hits Chen")


func test_the_crane_comes_faster_when_chen_is_enraged() -> void:
	var data: Dictionary = _content().enemy("harbourmaster_chen")
	var phase: Dictionary = data["phases"][0]
	assert_true(int(phase["hazard_every"]) < int(data["hazard"]["every"]), "faster in phase 2")
	assert_true(int(data["hazard"]["warn"]) >= 60, "always a full second of warning")


func test_no_crane_outside_a_boss_fight() -> void:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), "crane_yard", "", 7)
	for tick in 600:
		for event in zone.tick(FighterInput.new()):
			assert_true(event.type != "hazard_warn", "no drops before Chen is out")
	assert_true(zone.hazards.is_empty(), "nothing waiting to fall")
