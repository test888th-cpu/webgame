extends TestCase
## The street's light and shade: the road reaches past the bottom of any
## window, things standing on the street cast their shadow away from the light
## from their own base (Shade), fighters cast theirs too and take the area's
## light, and the street lamp carries no painted halo.

const TEST_SAVE := "user://test_scenery_light_save"


func _game() -> Game:
	SaveStore.root = TEST_SAVE
	SaveStore.delete_all()
	GameSession.start_new_game()
	var game: Game = load("res://scenes/game/Game.tscn").instantiate()
	tree.root.add_child(game)
	game.set_physics_process(false)
	return game


func _done(game: Game) -> void:
	game.free()
	SaveStore.delete_all()
	SaveStore.root = SaveStore.DEFAULT_ROOT


func test_the_road_reaches_past_the_bottom_of_the_view() -> void:
	var game := _game()
	game.enter_area("gang_hq", "west")
	var apron := game.view.find_child("RoadApron", true, false) as Sprite2D
	assert_true(apron != null, "the road runs on below its picture")
	var bottom := apron.position.y + apron.region_rect.size.y * apron.scale.y
	assert_true(bottom >= ZoneView.VIEW_HEIGHT + 20.0, "past the view (%s)" % bottom)
	_done(game)


func test_things_on_the_street_cast_shadows_from_their_base() -> void:
	var game := _game()
	game.enter_area("gang_hq", "west")
	var casts: Array[Sprite2D] = []
	for node in game.view.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite.flip_v and sprite.skew != 0.0:
			casts.append(sprite)
	assert_true(casts.size() > 10, "props, furniture and lamps cast shadows (%d)" % casts.size())
	for cast: Sprite2D in casts:
		assert_true(cast.flip_v, "laid down on the ground")
		assert_true(cast.skew != 0.0, "slanted away from the light")
		var thing := cast.get_parent().get_child(cast.get_index() + 2) as Sprite2D
		if thing and thing.texture == cast.texture:
			var base := thing.position.y + thing.texture.get_height() * thing.scale.y
			assert_near(cast.position.y, base, "from the thing's own base", 1.5)
	_done(game)


func test_fighters_cast_a_shadow_and_take_the_areas_light() -> void:
	var game := _game()
	game.enter_area("gang_hq", "west")
	game.zone.spawn_enemy("smogling", Vector2(500, 300))
	game.view.sync()
	for view: FighterView in game.view.find_children("*", "FighterView", true, false):
		var cast := view.get_node_or_null("Cast") as AnimatedSprite2D
		if cast == null:
			continue
		assert_true(cast.flip_v and cast.skew != 0.0, "a cast shadow on the street")
		assert_true(view.get_node("Shadow").get_index() < cast.get_index(), "over the contact")
	var hero := game.view.view_of(ZoneSim.HERO_ID)
	assert_true(hero.get_node_or_null("Cast") != null, "the hero casts one")
	var light := ZoneView.ambient_light(game.content, "gang_hq")
	assert_true(light != Color.WHITE and light.r > 0.8, "the street's light, softly")
	assert_eq(hero.ambient, light, "on the hero")
	_done(game)


func test_the_street_lamp_carries_no_painted_halo() -> void:
	# The lantern's own glass is yellow inside its outline; the painted halo was
	# the yellow-green that reached the outside.
	var image := (load("res://assets/kit/street_lamp.png") as Texture2D).get_image()
	var halo := 0
	for y in range(1, image.get_height() - 1):
		for x in range(1, image.get_width() - 1):
			var c := image.get_pixel(x, y)
			if not (c.a > 0.0 and c.g >= 0.88 * c.r and c.g > 0.35 and c.b < 0.62 * c.g):
				continue
			for step: Vector2i in [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
			]:
				if image.get_pixel(x + step.x, y + step.y).a == 0.0:
					halo += 1
					break
	# A few edge pixels sit on the threshold after import; the halo was hundreds.
	assert_true(halo < 20, "no yellow-green glow left beside the lantern (%d)" % halo)


func test_an_enemy_takes_its_own_tint_and_others_none() -> void:
	# A 50-70 monster that shares a story enemy's sprite is coloured by its
	# enemies.json "tint" in the sprite shader; story enemies stay white.
	var game := _game()
	game.enter_area("farm_coolant_vaults", "west")
	var runner := game.zone.spawn_enemy("vault_runner", Vector2(500, 300))
	var plain := game.zone.spawn_enemy("smogling", Vector2(600, 300))
	game.view.sync()
	var tinted := game.view.view_of(runner.id)
	var untinted := game.view.view_of(plain.id)
	var want := Color.from_string(str(game.content.enemy("vault_runner")["tint"]), Color.WHITE)
	assert_eq(tinted.tint, want, "the tier's colour")
	assert_eq(untinted.tint, Color.WHITE, "a story enemy as before")
	var sprite := tinted.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite:
		assert_eq(sprite.material.get_shader_parameter("tint"), want, "in the sprite's shader")
	_done(game)
