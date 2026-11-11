extends TestCase
## A large warning's unchanging parts are recorded once (HazardLayers), reused
## every frame, recorded again only when what they are drawn from changes, and
## freed with the warning.


func _drop(kind: String, half: Vector2) -> HazardView:
	var drop := HazardView.new()
	drop.setup(2.0, kind, half)
	drop.level = "full"
	tree.root.add_child(drop)
	return drop


func _frames(count: int) -> void:
	for i in count:
		await tree.process_frame


func test_large_steam_records_its_layers_once_and_reuses_them() -> void:
	var drop := _drop("steam", Vector2(90, 46))
	await _frames(2)
	var first: Dictionary = drop._layers._items.duplicate()
	assert_eq(
		first.keys(),
		["fill", "ring0", "ring1", "halo", "dark", "hot", "flash"],
		"the fill, bands, seam lines and flash, in drawing order"
	)
	await _frames(5)
	assert_eq(drop._layers._items, first, "the same canvas items on later frames")
	drop.queue_free()
	await _frames(1)


func test_a_new_size_or_theme_records_them_again() -> void:
	var drop := _drop("rain", Vector2(34, 46))
	await _frames(2)
	var first: Dictionary = drop._layers._items.duplicate()
	assert_eq(first.keys(), ["fill", "dark", "edge", "shade", "bracket"], "large rain's layers")
	drop.half = Vector2(40, 46)
	await _frames(2)
	assert_true(drop._layers._items["fill"] != first["fill"], "a new size: recorded again")
	var second: Dictionary = drop._layers._items.duplicate()
	drop.theme = "tech"
	await _frames(2)
	assert_true(drop._layers._items["fill"] != second["fill"], "a new theme: recorded again")
	drop.queue_free()
	await _frames(1)


func test_small_and_minimal_warnings_record_nothing() -> void:
	var small := _drop("steam", Vector2(28, 46))
	var minimal := _drop("rain", Vector2(34, 46))
	minimal.level = "minimal"
	var sludge := _drop("sludge", Vector2(34, 46))
	await _frames(3)
	for drop: HazardView in [small, minimal, sludge]:
		assert_true(drop._layers.is_empty(), drop.kind + ": drawn as before, nothing recorded")
		drop.queue_free()
	await _frames(1)


func test_layers_are_kept_while_it_fades_and_freed_with_it() -> void:
	var drop := _drop("steam", Vector2(90, 46))
	await _frames(2)
	var layers: HazardLayers = drop._layers
	drop.land()
	await _frames(2)
	assert_eq(layers._items.size(), 7, "kept while it fades")
	drop.free()
	assert_true(layers._items.is_empty(), "freed with the warning")
