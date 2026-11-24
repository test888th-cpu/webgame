extends TestCase
## The owner's TEMPORARY placeholder hats (tools/assets/
## import_placeholder_hats.py: 24 hats cut from the four magenta sheets):
## each is its own asset under its own look_head_* id; a
## covering hat hides the head's own top rows (hair or a cap) in every frame
## and is drawn there, a band sits over the hair; both mirror with the body;
## wearing another hat swaps the one shown, taking it off brings the head
## back; for all five heroes. Items, saves: test_item_testing_merchant.gd.

const TEST_SAVE := "user://test_hat_art"
const GAME_SCENE := preload("res://scenes/game/Game.tscn")
## The five heroes' items that wore drawn hats now wear the owner's.
const EXISTING := {
	"patched_street_cap": "officer_cap",
	"reinforced_bandana": "dragon_bandana",
	"riveted_work_helmet": "crested_knight_helm",
	"gilded_brawler_helm": "golden_lion_helm",
	"crimson_warlord_helm": "horned_crown",
}
const BANDS: Array[String] = [
	"crystal_tiara", "phoenix_tiara", "rising_sun_headband", "cyber_visor"
]
const HOODS: Array[String] = ["frost_fur_hood", "dragonscale_hood"]


func _hats() -> Dictionary:
	return JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/placeholder/hats/hats.json")
	)


func test_twenty_four_hats_from_the_four_sheets_each_its_own_asset() -> void:
	var c := ContentDB.load_all()
	var hats := _hats()
	assert_eq(hats.size(), 24, "24 hats")
	var per_sheet := {}
	for hat: String in hats:
		var meta: Dictionary = hats[hat]
		per_sheet[meta["sheet"]] = int(per_sheet.get(meta["sheet"], 0)) + 1
		var look := "look_head_" + hat
		var asset := str(c.catalog.appearances[look]["asset"])
		var spec: Dictionary = c.catalog.placeholders["appearance_assets"][asset]
		var texture: Texture2D = load(str(spec["image"]))
		assert_true(texture != null, hat + ": its sprite loads")
		assert_eq(Vector2i(texture.get_size()), Vector2i(meta["size"][0], meta["size"][1]), hat)
		var fit := "band" if hat in BANDS else ("hood" if hat in HOODS else "cover")
		assert_eq(spec["fit"], fit, hat + ": how it is worn")
		if fit == "hood":
			assert_true(spec.has("opening"), hat + ": its face opening")
		var anchor: Array = spec["anchor"]
		assert_true(anchor[0] < meta["size"][0] and anchor[1] < meta["size"][1], hat + ": anchor")
	assert_eq(per_sheet.size(), 4, "four sheets")
	for sheet: String in per_sheet:
		assert_eq(per_sheet[sheet], 6, sheet + ": six hats")
	var worn := {}
	for id: String in c.items:
		if c.item(id).get("slot") == "head" and id in c.catalog.added:
			var look := str(c.item(id)["appearance"])
			assert_true(look.trim_prefix("look_head_") in hats, id + ": one of the owner's hats")
			worn[look] = true
	assert_eq(worn.size(), 24, "every hat on its own item")
	for id: String in EXISTING:
		assert_eq(c.item(id)["appearance"], "look_head_" + EXISTING[id], id + ": keeps its id")


func _game(hero: String) -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game(hero)
	GameSession.profile.level = 30
	var game: Game = GAME_SCENE.instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	game.enter_area(game.content.city_area, "")
	game.zone.hero.position = Vector2(300, 290)
	return game


func _wear(game: Game, item_id: String) -> void:
	game.profile.add_item(item_id)
	game.profile.equip(item_id, game.content)
	game.zone.refresh_hero()


## The head's top rows of the frame on show, in the sprite's own space.
func _head_rows(sprite: AnimatedSprite2D) -> Rect2:
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var cover := EquipmentLayers.find_cover(frame.get_image())
	if sprite.flip_h:
		cover.position.x = frame.get_width() - cover.end.x
	return Rect2(sprite.offset + cover.position, cover.size)


func test_every_hero_both_ways_every_frame_the_hat_replaces_the_head() -> void:
	# A covering hat, a band and a hood, on every frame of every animation,
	# facing right and left, for all five heroes.
	for hero: String in ["riku", "mika", "oren", "kan", "dao"]:
		var game := _game(hero)
		var view := game.view.view_of(ZoneSim.HERO_ID)
		var sprite := view.get_node("Sprite") as AnimatedSprite2D
		var fighter := game.zone.hero
		for item_id: String in ["patched_street_cap", "rising_sun_headband", "frost_fur_hood"]:
			_wear(game, item_id)
			game.step(FighterInput.new())
			var gear := view.gear()
			var head := gear.get_node("Headgear") as Sprite2D
			var checked := 0
			for anim: StringName in sprite.sprite_frames.get_animation_names():
				if anim in [&"down", &"hurt"] or anim.begins_with("thrown"):
					continue  # lying or flung: no head on top
				sprite.animation = anim
				for frame in sprite.sprite_frames.get_frame_count(anim):
					for left: bool in [false, true]:
						sprite.frame = frame
						sprite.flip_h = left
						gear.update(fighter, game.content, sprite)
						var where := "%s %s %s:%d %s" % [hero, item_id, anim, frame, left]
						assert_true(head.visible, where + ": shown")
						assert_eq(head.flip_h, left, where + ": faces with the body")
						if gear.fit() == "band":
							assert_eq(gear.hidden_rect().size, Vector2.ZERO, where + ": hair kept")
						else:
							var rows := _head_rows(sprite)
							assert_eq(gear.hidden_rect(), rows, where + ": the old headwear hidden")
							var drawn := Rect2(head.position, head.texture.get_size())
							assert_true(drawn.intersects(rows), where + ": the hat on it")
						checked += 1
			assert_true(checked >= 60, "%s %s: %d frames checked" % [hero, item_id, checked])
		game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_another_hat_swaps_and_taking_it_off_brings_the_head_back() -> void:
	var game := _game("riku")
	var view := game.view.view_of(ZoneSim.HERO_ID)
	_wear(game, "lion_king_crown")
	game.step(FighterInput.new())
	var first: Texture2D = (view.gear().get_node("Headgear") as Sprite2D).texture
	_wear(game, "sakura_straw_hat")
	game.step(FighterInput.new())
	var head := view.gear().get_node("Headgear") as Sprite2D
	assert_true(head.texture != first, "the new hat shows")
	assert_eq(view.gear().get_child_count(), 1, "one hat, not two")
	assert_eq(game.profile.equipment["head"], "sakura_straw_hat", "worn")
	assert_eq(game.profile.count("lion_king_crown"), 1, "the old one back in the bag")
	game.profile.unequip("head", game.content)
	game.zone.refresh_hero()
	game.step(FighterInput.new())
	assert_true(not head.visible, "taken off: no hat")
	assert_eq(view.gear().hidden_rect().size, Vector2.ZERO, "and the head drawn whole again")
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_art_is_swapped_by_its_asset_entry_alone() -> void:
	# Replacing a placeholder (here: pointing the officer cap's look at another
	# sprite) changes only what is drawn: the item, its appearance id, the
	# worn slot and the save stay exactly as they were.
	var game := _game("riku")
	_wear(game, "patched_street_cap")
	game.step(FighterInput.new())
	var view := game.view.view_of(ZoneSim.HERO_ID)
	var before: Texture2D = (view.gear().get_node("Headgear") as Sprite2D).texture
	var saved := JSON.stringify(game.profile.to_dict())
	var catalog := game.content.catalog
	var look := "look_head_officer_cap"
	var old_asset := str(catalog.appearances[look]["asset"])
	catalog.appearances[look]["asset"] = "hat_horned_crown"
	game.step(FighterInput.new())
	var after: Texture2D = (view.gear().get_node("Headgear") as Sprite2D).texture
	assert_true(after != before, "the new art is drawn")
	assert_eq(game.content.item("patched_street_cap")["appearance"], look, "same appearance id")
	assert_eq(game.zone.hero.appearance, {"head": look}, "same look worn")
	assert_eq(game.profile.equipment["head"], "patched_street_cap", "same item worn")
	assert_eq(JSON.stringify(game.profile.to_dict()), saved, "the save does not change")
	catalog.appearances[look]["asset"] = old_asset
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_every_piece_of_art_is_marked_placeholder() -> void:
	var c := ContentDB.load_all()
	for kind: String in ["appearance_assets", "icons"]:
		for id: String in c.catalog.placeholders[kind]:
			assert_eq(c.catalog.placeholders[kind][id]["status"], "placeholder", id)
	c.catalog.placeholders["icons"]["ph_ore_iron"].erase("status")
	assert_true(", ".join(c.catalog.problems(c)).contains("ph_ore_iron.status"), "checked on load")
	var credits: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/placeholder/hats/credits.json")
	)
	assert_eq(credits["status"], "TEMPORARY / PLACEHOLDER", "the hats say so")
