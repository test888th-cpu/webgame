extends TestCase
## Story instances, farming grounds, rematches (lairs), world boss areas and
## the city hub are separate session types (SessionRules, ARCHITECTURE.md D9).

## A fixed Unix time, so the world boss rounds are the same on every run.
const NOW := 1_790_000_000

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


func test_every_area_kind_has_a_session_type() -> void:
	for kind: String in AreaRules.KINDS:
		assert_true(SessionRules.BY_KIND.has(kind), "kind %s has a session type" % kind)
		assert_true(SessionRules.BY_KIND.get(kind) in SessionRules.TYPES, kind + " maps to a type")


func test_areas_run_as_their_session_types() -> void:
	var c := _content()
	for area_id in StreetMemory.street(c):
		assert_eq(SessionRules.session_type(c, area_id), SessionRules.STORY, area_id)
		assert_true(SessionRules.is_private(c, area_id), area_id + " is private")
	assert_eq(SessionRules.session_type(c, c.city_area), SessionRules.HUB, "the city")
	for area_id in AreaRules.farms(c):
		assert_eq(SessionRules.session_type(c, area_id), SessionRules.FARMING, area_id)
		assert_true(not SessionRules.is_private(c, area_id), area_id + " is shared")
	for area_id in AreaRules.lairs(c):
		assert_eq(SessionRules.session_type(c, area_id), SessionRules.REMATCH, area_id)
		assert_true(not SessionRules.is_private(c, area_id), area_id + " is shared")
	for boss: String in c.world_bosses:
		var arena := str(c.world_bosses[boss]["area"])
		assert_eq(SessionRules.session_type(c, arena), SessionRules.WORLD_BOSS, arena)
		assert_eq(SessionRules.arena_boss(c, arena), boss, arena + " is fought by " + boss)
	for type: String in SessionRules.SHARED_TYPES:
		assert_true(type != SessionRules.STORY, type + " is not the story")


## Farming grounds hold normal enemies and their elites, never a boss of any
## kind (story, lair or world boss); the validator refuses one.
func test_farming_grounds_hold_no_boss() -> void:
	var c := _content()
	assert_eq(SessionRules.problems(c), PackedStringArray(), "the shipped grounds")
	for area_id in AreaRules.farms(c):
		var pool: Dictionary = c.area(area_id)["spawning"]["pool"]
		for kind: String in pool:
			assert_true(not c.enemy(kind).get("boss", false), area_id + ": " + kind)
		assert_true(not c.area(area_id).has("mini_boss"), area_id + ": no mini-boss")
	var copy := ContentDB.load_all()
	var ground := AreaRules.farms(copy)[0]
	copy.areas[ground]["spawning"]["pool"]["sludge_foreman"] = 1
	var said := "\n".join(SessionRules.problems(copy))
	assert_true("a farming ground has no boss" in said, "a boss is refused: " + said)


func test_each_hero_gets_their_own_story_instance() -> void:
	var c := _content()
	for area_id in StreetMemory.street(c):
		var mine := SessionRules.instance_key(c, area_id, "hero_a", NOW)
		var theirs := SessionRules.instance_key(c, area_id, "hero_b", NOW)
		assert_eq(mine, "story/hero_a/%s" % area_id, area_id + ": the owner's copy")
		assert_true(mine != theirs, area_id + ": two heroes never share a story instance")
		var later := SessionRules.instance_key(c, area_id, "hero_a", NOW + 86_400)
		assert_eq(later, mine, area_id + ": the story keeps no clock")
	assert_eq(SessionRules.instance_key(c, "saltmarket", "", NOW), "", "no story without a hero")


func test_shared_and_world_boss_instances_are_one_for_everyone() -> void:
	var c := _content()
	var city_a := SessionRules.instance_key(c, c.city_area, "hero_a", NOW)
	assert_eq(city_a, SessionRules.instance_key(c, c.city_area, "hero_b", NOW), "one city")
	for area_id in AreaRules.farms(c) + AreaRules.lairs(c):
		var a := SessionRules.instance_key(c, area_id, "hero_a", NOW)
		assert_eq(a, SessionRules.instance_key(c, area_id, "hero_b", NOW), area_id + ": one")
		assert_true(a.begins_with(SessionRules.session_type(c, area_id)), a + " says its type")
	for boss: String in c.world_bosses:
		var arena := str(c.world_bosses[boss]["area"])
		var round := int(WorldBossRules.window(c, boss, NOW)["round"])
		var a := SessionRules.instance_key(c, arena, "hero_a", NOW)
		assert_eq(a, "world_boss/%s/%d" % [boss, round], arena + ": one per round")
		assert_eq(a, SessionRules.instance_key(c, arena, "hero_b", NOW), arena + ": everyone's")


func test_a_story_instance_admits_its_owner_alone() -> void:
	var c := _content()
	var area := "saltmarket"
	assert_true(SessionRules.may_join(c, area, "a", "a", []), "the owner enters")
	assert_true(SessionRules.may_join(c, area, "a", "a", ["a"]), "the owner reconnects")
	assert_true(not SessionRules.may_join(c, area, "b", "a", []), "nobody else enters")
	assert_true(not SessionRules.may_join(c, area, "b", "a", ["a"]), "nobody joins or helps")
	assert_true(not SessionRules.may_join(c, area, "a", "a", ["b"]), "never shared")
	assert_true(not SessionRules.may_join(c, area, "", "", []), "no anonymous hero")
	assert_true(SessionRules.may_join(c, c.city_area, "b", "", ["a"]), "the city is shared")
	var lair := AreaRules.lairs(c)[0]
	assert_true(SessionRules.may_join(c, lair, "b", "", ["a"]), "so is a lair")
	assert_true(SessionRules.may_join(c, "great_drain", "b", "", ["a"]), "so is the world boss")


## The story's gates read only the hero's own record: a world boss round,
## fought or fallen, opens and shuts nothing on the street.
func test_story_progress_ignores_world_boss_state() -> void:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	var before := {}
	for area_id in StreetMemory.street(c):
		before[area_id] = StreetMemory.gate(profile, c, area_id, "east")
	for boss: String in c.world_bosses:
		var round := int(WorldBossRules.window(c, boss, NOW)["round"])
		profile.world_boss[boss] = {"round": round, "killed": true, "down": true}
	for area_id in StreetMemory.street(c):
		assert_eq(StreetMemory.gate(profile, c, area_id, "east"), before[area_id], area_id)
