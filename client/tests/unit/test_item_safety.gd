extends TestCase
## Nothing a player owns is lost: saves are written safely and recovered
## from a backup, unreadable characters are kept, items a build does not
## know are parked rather than dropped, loot left on the ground is banked,
## a world boss fight cut short is paid, and only one browser tab saves.

const ROOT := "user://test_item_safety"
const GAME_SCENE := preload("res://scenes/game/Game.tscn")


func _begin() -> void:
	SaveStore.root = ROOT
	SaveStore.read_only = false
	SaveStore.delete_all()


func _end() -> void:
	SaveStore.delete_all()
	SaveStore.read_only = false
	SaveStore.root = SaveStore.DEFAULT_ROOT


func _content() -> ContentDB:
	return GameSession.content


func _saved(name := "Keeper") -> PlayerProfile:
	var profile := PlayerProfile.new_game(_content(), "mika", name)
	profile.id = SaveStore.new_id()
	assert_true(SaveStore.save(profile), "saved")
	return profile


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_a_broken_save_falls_back_to_the_last_good_one() -> void:
	_begin()
	var profile := _saved()
	profile.money = 500
	SaveStore.save(profile)
	var path := SaveStore.path_of(profile.id)
	assert_true(FileAccess.file_exists(path + ".bak"), "the previous save is kept")
	_write(path, '{"version": 10, "trunc')
	var back := SaveStore.load_character(profile.id, _content())
	assert_true(back != null, "a broken save does not lose the character")
	assert_eq(SaveStore.characters(_content()).size(), 1, "still listed")
	# A crash between the write and the rename leaves only the new file.
	profile.money = 700
	SaveStore.save(profile)
	DirAccess.rename_absolute(path, path + ".tmp")
	assert_eq(SaveStore.load_character(profile.id, _content()).money, 700, "the newest is used")
	_end()


func test_an_unreadable_character_is_kept_and_holds_its_slot() -> void:
	_begin()
	for name: String in ["Ana", "Bea", "Cid"]:
		_saved(name)
	var broken := SaveStore.new_id()
	DirAccess.make_dir_recursive_absolute(SaveStore.folder())
	_write(SaveStore.path_of(broken), '{"version": 999}')
	assert_eq(SaveStore.characters(_content()).size(), 3, "three can be played")
	assert_eq(SaveStore.unreadable(_content()), [broken], "the fourth is shown as unreadable")
	assert_eq(SaveStore.slots_used(), 4, "and holds its slot")
	var extra := PlayerProfile.new_game(_content(), "mika", "Dot")
	extra.id = SaveStore.new_id()
	assert_true(not SaveStore.save(extra), "so no fifth is made in its place")
	assert_true(FileAccess.file_exists(SaveStore.path_of(broken)), "and its file is untouched")
	assert_true(SaveStore.delete_character(broken), "it can be deleted (moved aside)")
	assert_eq(SaveStore.slots_used(), 3, "freeing the slot")
	_end()


func test_items_this_build_does_not_know_are_parked_not_dropped() -> void:
	var profile := PlayerProfile.new_game(_content(), "mika")
	profile.level = 10
	var data := profile.to_dict()
	data["inventory"]["ghost_blade"] = 2
	data["inventory"]["ghost_blade#1"] = 1
	data["enhance"] = {"ghost_blade#1": 7}
	data["equipment"]["head"] = "taped_knuckles"  # a weapon in the head slot
	var loaded := PlayerProfile.from_dict(data, _content())
	assert_eq(loaded.unknown["inventory"], {"ghost_blade": 2, "ghost_blade#1": 1}, "parked")
	assert_eq(loaded.unknown["enhance"], {"ghost_blade#1": 7}, "with its upgrade")
	assert_eq(loaded.count("taped_knuckles"), 1, "worn gear that no longer fits goes to the bag")
	assert_eq(loaded.equipment["head"], "", "not into the wrong slot")
	var again := PlayerProfile.from_dict(loaded.to_dict(), _content())
	assert_eq(again.unknown, loaded.unknown, "kept through every save")
	var known := loaded.to_dict()
	known["unknown"]["inventory"]["steamed_bun"] = 3
	var back := PlayerProfile.from_dict(known, _content())
	assert_eq(back.count("steamed_bun"), loaded.count("steamed_bun") + 3, "known again: back")


func test_the_old_save_never_overwrites_a_newer_character() -> void:
	_begin()
	var old := PlayerProfile.new_game(_content(), "mika", "Old")
	var data := old.to_dict()
	data.erase("id")
	var legacy := ROOT.path_join(SaveStore.LEGACY_SAVE)
	_write(legacy, JSON.stringify(data))
	var imported := SaveStore.characters(_content())[0]
	imported.money = 9999
	SaveStore.save(imported)
	_write(legacy, JSON.stringify(data))  # as if its rename had failed
	assert_eq(SaveStore.characters(_content())[0].money, 9999, "progress since is kept")
	_end()


func test_a_second_tab_never_writes() -> void:
	_begin()
	var profile := _saved()
	SaveStore.read_only = true
	profile.money = 1
	assert_true(not SaveStore.save(profile), "no save")
	assert_true(not SaveStore.delete_character(profile.id), "no delete")
	SaveStore.read_only = false
	assert_true(
		SaveStore.load_character(profile.id, _content()).money != 1, "the file is as it was"
	)
	_end()


func test_loot_left_on_the_ground_is_banked_and_pickups_are_saved() -> void:
	_begin()
	GameSession.start_new_game("mika")
	var game: Game = GAME_SCENE.instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	var money := game.profile.money
	game.zone.pickups.append(
		{"kind": "money", "amount": 40, "position": Vector2(900, 300), "id": 90}
	)
	game.zone.pickups.append(
		{"kind": "item", "item": "scrap_metal", "amount": 2, "position": Vector2(900, 300)}
	)
	game.enter_area("saltmarket", "west")
	assert_eq(game.profile.money, money + 40, "coins left behind are banked on leaving")
	assert_eq(game.profile.count("scrap_metal"), 2, "and items")
	game.zone.pickups.append(
		{"kind": "money", "amount": 5, "position": game.zone.hero.position, "id": 91}
	)
	game.step(FighterInput.new())
	var saved := SaveStore.load_character(game.profile.id, game.content)
	assert_eq(saved.money, money + 45, "a pickup is saved at once")
	game.free()
	_end()


func test_a_world_boss_fight_cut_short_is_still_paid() -> void:
	var profile := PlayerProfile.new_game(_content(), "mika")
	profile.level = 30
	var boss := "tunnel_mother"
	var total := 10000
	WorldBossRules.note_attempt(profile, boss, 7, total, total, 30)
	var reloaded := PlayerProfile.from_dict(profile.to_dict(), _content())
	var money := reloaded.money
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var settled := WorldBossRules.settle(reloaded, _content(), rng)
	assert_true(settled.has(boss), "the cut-short attempt is banked")
	assert_true(reloaded.money > money, "and paid")
	assert_true(not reloaded.world_boss[boss].has("attempt"), "once")
	assert_true(WorldBossRules.settle(reloaded, _content(), rng).is_empty(), "never twice")


func test_coins_are_only_taken_when_there() -> void:
	var profile := PlayerProfile.new_game(_content(), "mika")
	profile.money = 50
	assert_true(not EconomyRules.charge(profile, 60), "not more than there is")
	assert_true(not EconomyRules.charge(profile, -5), "never a negative fare")
	assert_eq(profile.money, 50, "nothing taken")
	assert_true(EconomyRules.charge(profile, 20), "a fare")
	assert_eq(profile.money, 30, "taken once")
	assert_eq(EconomyRules.defeat_loss(profile, _content()), 3, "a knock-out costs 10%")
