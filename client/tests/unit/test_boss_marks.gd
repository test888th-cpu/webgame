extends TestCase
## The owner's rule: a mini-boss (a boss that waits before its district's
## end, MapRules.MINI_BOSS) wears the map's mini-boss mark overhead, on the
## boss bar and in its arrival toast, never the boss skull, so players can
## tell it from a district's final boss.

const TEST_SAVE := "user://test_boss_marks_save"
const MINI := "canal_works"
const FINAL := "gang_hq"


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	tree.root.size = Vector2i(1280, 720)
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.profile.level = 40
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


## Walks to `area_id`'s boss and returns the toasts seen on the way.
func _meet_boss(game: Game, area_id: String) -> Array[String]:
	game.enter_area(area_id, "west")
	var boss := MapRules.boss_of(game.content, area_id)
	var trigger := 0.0
	for encounter: Dictionary in game.content.area(area_id).get("encounters", []):
		for wave: Array in encounter.get("waves", []):
			if boss in wave:
				trigger = float(encounter["trigger_x"])
	var toasts: Array[String] = []
	var toast := game.get_node("Hud").find_child("Toast", true, false)
	for tick in 1200:
		game.zone.hero.hp = game.zone.hero.max_hp
		game.zone.hero.position.x = minf(game.zone.hero.position.x + 8.0, trigger + 20.0)
		for enemy in game.zone.enemies():
			# The waves before the boss stand down at once.
			if MapRules.boss_of(game.content, area_id) != enemy.kind and not enemy.is_ko():
				enemy.hp = 0
				enemy.enter(Fighter.State.KO)
		game.step(FighterInput.new())
		for label: Label in toast.find_children("*", "Label", true, false):
			if label.text not in toasts:
				toasts.append(label.text)
		if game.zone.boss_id and game.view.view_of(game.zone.boss_id) != null:
			break
	return toasts


func test_a_mini_boss_wears_the_mini_boss_mark_not_the_skull() -> void:
	var game := _game()
	assert_eq(MapRules.kind_of(game.content, MINI), MapRules.MINI_BOSS, "a mini-boss area")
	assert_eq(MapRules.kind_of(game.content, FINAL), MapRules.BOSS, "a district's last boss")
	var expected := {
		MINI: ["map_mini_boss", "Mini-boss ", "MINI-BOSS"], FINAL: ["map_boss", "", "BOSS"]
	}
	for area_id: String in expected:
		var want: Array = expected[area_id]
		var toasts := _meet_boss(game, area_id)
		assert_true(game.zone.boss_id != 0, area_id + ": the boss came")
		var view: Node = game.view.view_of(game.zone.boss_id)
		var name := str(game.content.enemy(game.zone.fighter(game.zone.boss_id).kind)["name"])
		var overhead := (view.get_node("Name") as Label).text
		assert_eq(overhead, str(want[1]) + name, area_id + ": overhead")
		var mark := view.get_node("Rank") as TextureRect
		var icon := UiKit.icon(game.content, str(want[0]))
		assert_eq((mark.texture as AtlasTexture).region, icon.region, area_id + ": its mark")
		var hud := game.get_node("Hud")
		hud._process(0.016)
		var bar_icon := hud.find_child("BossIcon", true, false) as TextureRect
		assert_eq((bar_icon.texture as AtlasTexture).region, icon.region, area_id + ": on the bar")
		var title := (hud.find_child("Boss", true, false) as Control).find_children(
			"*", "Label", true, false
		)
		var bar_text := (title[0] as Label).text
		assert_eq(bar_text.begins_with("MINI-BOSS"), area_id == MINI, area_id + ": " + bar_text)
		var announced := toasts.any(func(t: String) -> bool: return t.begins_with(want[2] + ":"))
		assert_true(announced, "%s: announced as %s (%s)" % [area_id, want[2], toasts])
	_done(game)
