extends TestCase
## Which edge a boss's reinforcements come in from (BossMechanics._summon):
## they alternate edges, west first. Only in a world boss arena
## (SessionRules.WORLD_BOSS) does one that would land within
## SUMMON_CLEARANCE of the hero come in from the other edge; story bosses,
## story mini-bosses, lairs and any other caller keep the plain alternation.

const MINION := "tar_hound"

var content: ContentDB


func _content() -> ContentDB:
	if content == null:
		content = ContentDB.load_all()
	return content


## Where (x) each reinforcement arrives when `caller` in `area_id` calls
## `count` of them with the hero standing at `hero_x` (from the arena's west
## edge when >= 0, else from its east edge).
func _arrivals(area_id: String, caller: String, hero_x: float, count := 1) -> Array[float]:
	var c := _content()
	var profile := PlayerProfile.new_game(c)
	var zone := ZoneSim.new(c, profile, area_id, "west", 3)
	var boss := zone.spawn_enemy(caller, zone.arena.get_center())
	var west := zone.arena.position.x
	var east := zone.arena.end.x
	zone.hero.position.x = west + hero_x if hero_x >= 0.0 else east + hero_x
	var events: Array[ZoneEvent] = []
	var data := {"enemy": MINION, "every": 1, "count": count, "max": 10}
	BossMechanics.new().summon(zone, boss, data, events)
	var out: Array[float] = []
	for event in events:
		if event.type == "boss_summon":
			for id: int in event.data["ids"]:
				out.append(zone.fighter(id).position.x)
	return out


## True when `x` is at the west end of `area_id`'s arena.
func _west(area_id: String, x: float) -> bool:
	var zone := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), area_id, "west", 3)
	return x < zone.arena.get_center().x


func test_every_caller_but_a_world_boss_keeps_its_old_edges() -> void:
	var c := _content()
	var cases := {
		"sak_tower": "big_sak",  # a story (stage) boss
		"canal_works": "sludge_foreman",  # a story mini-boss
		"spillway_gatehouse": LairRules.boss(c, "spillway_gatehouse"),  # a lair (rematch)
		"farm_saltmarket_backlots": "smog_warden",  # an ordinary caller, no boss
	}
	assert_eq(SessionRules.session_type(c, "sak_tower"), SessionRules.STORY, "story")
	assert_eq(ReplayRules.rank(c, "canal_works"), ReplayRules.MINI_BOSS, "a mini-boss")
	assert_eq(SessionRules.session_type(c, "spillway_gatehouse"), SessionRules.REMATCH, "lair")
	for area_id: String in cases:
		var near := _arrivals(area_id, str(cases[area_id]), 20.0)
		assert_eq(near.size(), 1, area_id + ": one arrives")
		if near:
			assert_true(_west(area_id, near[0]), area_id + ": west, even next to the hero")
		var far := _arrivals(area_id, str(cases[area_id]), 400.0)
		if far:
			assert_true(_west(area_id, far[0]), area_id + ": west with the hero far off")
		var two := _arrivals(area_id, str(cases[area_id]), -20.0, 2)
		assert_eq(two.size(), 2, area_id + ": two arrive")
		if two.size() == 2:
			assert_true(_west(area_id, two[0]) and not _west(area_id, two[1]), area_id + ": W, E")


func test_a_world_boss_never_sends_one_on_top_of_the_hero() -> void:
	var arena := "great_drain"
	assert_eq(SessionRules.session_type(_content(), arena), SessionRules.WORLD_BOSS, "a world boss")
	var near := _arrivals(arena, "tunnel_mother", 20.0)
	if near:
		assert_true(not _west(arena, near[0]), "hero at the west edge: it comes from the east")
	var far := _arrivals(arena, "tunnel_mother", 400.0)
	if far:
		assert_true(_west(arena, far[0]), "hero far off: the usual west edge")
	# The hero has crossed to the east edge mid-fight: the second, due east,
	# comes in from the west instead.
	var crossed := _arrivals(arena, "tunnel_mother", -20.0, 2)
	assert_eq(crossed.size(), 2, "two arrive")
	for x in crossed:
		assert_true(_west(arena, x), "both from the west, away from the hero (%d)" % x)
	for x in _arrivals(arena, "tunnel_mother", 20.0, 4):
		var hero_x := ZoneSim.new(_content(), PlayerProfile.new_game(_content()), arena, "west", 3)
		assert_true(
			absf(x - (hero_x.arena.position.x + 20.0)) >= BossMechanics.SUMMON_CLEARANCE,
			"none within the clearance (%d)" % x
		)
