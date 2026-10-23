class_name ZoneView
extends Node2D
## Draws one ZoneSim: scenery built from the area's palette, NPCs, exits,
## fighters, pickups and hit effects. Holds no game state; `sync` mirrors the
## simulation every physics tick, creating and freeing views as fighters and
## pickups come and go.

const FIGHTER_SCENE := preload("res://scenes/fighter/FighterView.tscn")
const VIEW_HEIGHT := 360.0
## How close the hero must stand to talk to an NPC.
const TALK_REACH := Vector2(34.0, 26.0)

var zone: ZoneSim
var content: ContentDB
var camera: Camera2D

var _entities: Node2D
var _effects: Node2D
var _views := {}
var _pickups := {}
var _npc_marks := {}


func build(p_zone: ZoneSim, p_content: ContentDB) -> void:
	zone = p_zone
	content = p_content
	_build_scenery()
	_entities = Node2D.new()
	_entities.name = "Entities"
	_entities.y_sort_enabled = true
	add_child(_entities)
	_build_npcs()
	_effects = Node2D.new()
	_effects.name = "Effects"
	add_child(_effects)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	sync()
	camera.reset_smoothing()


func sync() -> void:
	var alive := {}
	for f in zone.fighters:
		alive[f.id] = true
		if not _views.has(f.id):
			_views[f.id] = _make_fighter_view(f)
		if f.id == ZoneSim.HERO_ID:
			_views[f.id].set_art(hero_art(), content.art)
		_views[f.id].sync()
	for id: int in _views.keys():
		if not alive.has(id):
			_views[id].queue_free()
			_views.erase(id)
	var present := {}
	for pickup in zone.pickups:
		present[pickup["id"]] = true
		if not _pickups.has(pickup["id"]):
			_pickups[pickup["id"]] = _make_pickup_view(pickup)
	for id: int in _pickups.keys():
		if not present.has(id):
			_pickups[id].queue_free()
			_pickups.erase(id)
	_follow_hero()


func view_of(id: int) -> FighterView:
	return _views.get(id)


func show_hit(event: CombatEvent) -> void:
	var label := DamageNumber.new()
	label.add_theme_font_size_override("font_size", 10)
	_effects.add_child(label)
	label.show_hit(event)


func show_text(text: String, at: Vector2, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 8)
	label.position = at + Vector2(-20, -60)
	_effects.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 16, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


## The NPC the hero is close enough to talk to, or {}.
func npc_near(hero: Fighter) -> Dictionary:
	for npc: Dictionary in zone.area.get("npcs", []):
		var offset := Vector2(npc["x"], npc["y"]) - hero.position
		if absf(offset.x) <= TALK_REACH.x and absf(offset.y) <= TALK_REACH.y:
			return npc
	return {}


## Shows "$" over shopkeepers and "!" over quest givers with something to
## accept or hand in.
func update_npc_marks(profile: PlayerProfile) -> void:
	for npc: Dictionary in zone.area.get("npcs", []):
		var mark: Label = _npc_marks.get(npc["id"])
		if mark == null:
			continue
		var pending := false
		for quest_id in quests_of(npc):
			var state := QuestRules.status(profile, quest_id, content)
			pending = pending or state in ["available", "complete"]
		mark.visible = pending or npc["role"] == "shop"
		mark.text = "$" if npc["role"] == "shop" else "!"


func quests_of(npc: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for quest_id: String in content.quests:
		if content.quests[quest_id].get("giver") == npc["id"]:
			ids.append(quest_id)
	return ids


## The hero's art: the equipped armour's look if it has one, else the default.
func hero_art() -> String:
	var armour := content.item(zone.profile.equipment["armor"])
	if armour.has("hero_sprite"):
		return str(armour["hero_sprite"])
	return str(content.progression.get("hero", {}).get("sprite", ""))


func _make_fighter_view(f: Fighter) -> FighterView:
	var view: FighterView = FIGHTER_SCENE.instantiate()
	view.fighter = f
	_entities.add_child(view)
	if f.team == ZoneSim.ENEMY_TEAM:
		view.setup_enemy(content.enemy(f.kind), content.art)
	return view


func _make_pickup_view(pickup: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.position = pickup["position"]
	var shape := Polygon2D.new()
	if pickup["kind"] == "money":
		shape.color = Color(1.0, 0.82, 0.25)
		shape.polygon = PackedVector2Array(
			[
				Vector2(-3, -6),
				Vector2(3, -6),
				Vector2(4, -3),
				Vector2(3, 0),
				Vector2(-3, 0),
				Vector2(-4, -3)
			]
		)
	else:
		shape.color = Color(0.55, 0.85, 0.6)
		shape.polygon = PackedVector2Array(
			[Vector2(-4, -8), Vector2(4, -8), Vector2(4, 0), Vector2(-4, 0)]
		)
	node.add_child(shape)
	var tween := node.create_tween().set_loops()
	tween.tween_property(shape, "position:y", -3.0, 0.4)
	tween.tween_property(shape, "position:y", 0.0, 0.4)
	_entities.add_child(node)
	return node


func _follow_hero() -> void:
	# During a fight the camera is held inside the locked arena.
	var width := zone.bounds.end.x + ZoneSim.EDGE_MARGIN
	var fighting := zone.in_encounter()
	camera.limit_left = int(zone.arena.position.x - ZoneSim.EDGE_MARGIN) if fighting else 0
	camera.limit_right = int(zone.arena.end.x + ZoneSim.EDGE_MARGIN) if fighting else int(width)
	camera.limit_top = 0
	camera.limit_bottom = int(VIEW_HEIGHT)
	camera.position = Vector2(zone.hero.position.x, VIEW_HEIGHT / 2.0)


func _build_scenery() -> void:
	var scenery: Dictionary = content.environment.get("areas", {}).get(zone.area_id, {})
	if scenery.is_empty():
		_build_flat_scenery()
	else:
		_build_layered_scenery(scenery)
	_build_exit_signs()


## Generated pixel-art layers (tools/assets/gen_environment.py): a sky fixed to
## the screen, a skyline scrolling at 30%, then the street's facades and
## ground in the world, and props with lamp glow along the sidewalk.
func _build_layered_scenery(scenery: Dictionary) -> void:
	var layers: Dictionary = scenery["layers"]
	_parallax(layers["sky"], 0.0)
	_parallax(layers["far"], 0.3)
	_sprite(layers["buildings"]["file"], Vector2.ZERO)
	_sprite(layers["ground"]["file"], Vector2(0, ZoneSim.LANE_TOP - 20.0))
	var props: Dictionary = content.environment["props"]
	var sheet: Texture2D = load(props["sheet"])
	for placed: Dictionary in scenery["props"]:
		var region: Array = props["regions"][placed["prop"]]
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(region[0], region[1], region[2], region[3])
		var prop := Sprite2D.new()
		prop.texture = atlas
		prop.centered = false
		prop.position = Vector2(placed["x"] - region[2] / 2.0, placed["y"] - region[3])
		add_child(prop)
		if placed.get("glow", false):
			var glow_region: Array = props["regions"]["glow"]
			var glow_atlas := AtlasTexture.new()
			glow_atlas.atlas = sheet
			glow_atlas.region = Rect2(
				glow_region[0], glow_region[1], glow_region[2], glow_region[3]
			)
			var glow := Sprite2D.new()
			glow.texture = glow_atlas
			glow.position = Vector2(placed["x"], placed["y"] - region[3] + 10)
			glow.scale = Vector2(2.5, 2.5)
			var additive := CanvasItemMaterial.new()
			additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			glow.material = additive
			add_child(glow)


func _parallax(layer: Dictionary, scroll: float) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = Vector2(scroll, 1.0)
	parallax.repeat_size = Vector2(layer["size"][0], 0)
	parallax.repeat_times = 4
	add_child(parallax)
	var sprite := Sprite2D.new()
	sprite.texture = load(layer["file"])
	sprite.centered = false
	parallax.add_child(sprite)


func _sprite(path: String, at: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.centered = false
	sprite.position = at
	add_child(sprite)


## Fallback for an area whose scenery has not been generated yet.
func _build_flat_scenery() -> void:
	var palette: Dictionary = zone.area.get("palette", {})
	var width := float(zone.area.get("width", 960))
	var ground := ZoneSim.LANE_TOP - 20.0
	_rect(Rect2(0, 0, width, ground), _color(palette, "sky", "#1a1830"))
	_rect(Rect2(0, ground, width, 20), _color(palette, "sidewalk", "#5c5a60"))
	_rect(
		Rect2(0, ZoneSim.LANE_TOP, width, VIEW_HEIGHT - ZoneSim.LANE_TOP),
		_color(palette, "street", "#38383f")
	)


func _build_exit_signs() -> void:
	var width := float(zone.area.get("width", 960))
	var ground := ZoneSim.LANE_TOP - 20.0
	var exits: Dictionary = zone.area.get("exits", {})
	for side: String in exits:
		var target := content.area(exits[side]["to"])
		var exit_sign := Label.new()
		exit_sign.add_theme_font_size_override("font_size", 8)
		exit_sign.add_theme_color_override("font_outline_color", Color.BLACK)
		exit_sign.add_theme_constant_override("outline_size", 3)
		var place := str(target.get("name", ""))
		exit_sign.text = "< " + place if side == "west" else place + " >"
		exit_sign.position = Vector2(8 if side == "west" else width - 130, ground + 2)
		exit_sign.size = Vector2(122, 12)
		exit_sign.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT if side == "west" else HORIZONTAL_ALIGNMENT_RIGHT
		)
		add_child(exit_sign)


func _build_npcs() -> void:
	for npc: Dictionary in zone.area.get("npcs", []):
		var stand_in := Fighter.new(0, 0, Vector2(npc["x"], npc["y"]))
		stand_in.facing = -1
		var view: FighterView = FIGHTER_SCENE.instantiate()
		view.fighter = stand_in
		view.body_color = Color.from_string(str(npc.get("color", "#888888")), Color.GRAY)
		_entities.add_child(view)
		view.set_art(str(npc.get("sprite", "")), content.art)
		view.sync()
		var name_label := Label.new()
		name_label.text = str(npc["name"])
		name_label.add_theme_font_size_override("font_size", 7)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-40, -58)
		name_label.size = Vector2(80, 10)
		view.add_child(name_label)
		var mark := Label.new()
		mark.add_theme_font_size_override("font_size", 12)
		mark.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.position = Vector2(-10, -74)
		mark.size = Vector2(20, 14)
		view.add_child(mark)
		_npc_marks[npc["id"]] = mark


func _rect(rect: Rect2, color: Color) -> void:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)


func _color(palette: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(
		str(palette.get(key, fallback)), Color.from_string(fallback, Color.BLACK)
	)
