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
## Camera shake on heavy impacts, in pixels, and how much it fades per tick.
const SHAKE_PIXELS := 3.0
const SHAKE_FADE := 0.25

var zone: ZoneSim
var content: ContentDB
var camera: Camera2D
## Floating numbers and effects in world space.
var effects: Node2D

var _entities: Node2D
var _views := {}
var _pickups := {}
var _weapons := {}
var _npc_marks := {}
var _npc_prompts := {}
var _shake := 0.0


func build(p_zone: ZoneSim, p_content: ContentDB) -> void:
	zone = p_zone
	content = p_content
	_build_scenery()
	_entities = Node2D.new()
	_entities.name = "Entities"
	_entities.y_sort_enabled = true
	add_child(_entities)
	_build_npcs()
	effects = Node2D.new()
	effects.name = "Effects"
	add_child(effects)
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
			_pickups[id].collect()
			_pickups.erase(id)
	_sync_weapons()
	_update_prompts()
	_follow_hero()


func view_of(id: int) -> FighterView:
	return _views.get(id)


func show_hit(event: CombatEvent) -> void:
	var label := DamageNumber.new()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	effects.add_child(label)
	label.show_hit(event)
	var heavy := event.knocked_down or event.guard_broken or event.ko
	if (
		GameSession.settings.get("screen_shake", true)
		and (heavy or (event.defender_id == ZoneSim.HERO_ID and not event.blocked))
	):
		_shake = SHAKE_PIXELS if heavy else SHAKE_PIXELS * 0.5


func show_text(text: String, at: Vector2, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_constant_override("outline_size", 3)
	label.position = at + Vector2(-20, -60)
	effects.add_child(label)
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
	return content.hero_art(zone.profile)


func _make_fighter_view(f: Fighter) -> FighterView:
	var view: FighterView = FIGHTER_SCENE.instantiate()
	view.fighter = f
	view.content = content
	_entities.add_child(view)
	if f.team == ZoneSim.ENEMY_TEAM:
		view.setup_enemy(content.enemy(f.kind), content.art, zone.enemy_level(f.id))
	return view


func _make_pickup_view(pickup: Dictionary) -> Node2D:
	var loot := LootView.new()
	loot.setup(content, pickup, pickup.get("from", pickup["position"]))
	_entities.add_child(loot)
	return loot


func _follow_hero() -> void:
	# During a fight the camera is held inside the locked arena.
	var width := zone.bounds.end.x + ZoneSim.EDGE_MARGIN
	var fighting := zone.in_encounter()
	camera.limit_left = int(zone.arena.position.x - ZoneSim.EDGE_MARGIN) if fighting else 0
	camera.limit_right = int(zone.arena.end.x + ZoneSim.EDGE_MARGIN) if fighting else int(width)
	camera.limit_top = 0
	camera.limit_bottom = int(VIEW_HEIGHT)
	camera.position = Vector2(zone.hero.position.x, VIEW_HEIGHT / 2.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	_shake = maxf(0.0, _shake - SHAKE_FADE)


## Shakes the camera by up to `pixels` (if the player has shake turned on).
func shake(pixels: float) -> void:
	if GameSession.settings.get("screen_shake", true):
		_shake = maxf(_shake, pixels)


## Shows "[E] Talk" (or Shop) over the NPC the hero can talk to right now,
## or else "[E] Pick up" over the weapon at the hero's feet.
func _update_prompts() -> void:
	var near := npc_near(zone.hero)
	for npc_id: String in _npc_prompts:
		_npc_prompts[npc_id].visible = not near.is_empty() and near["id"] == npc_id
	var reach := zone.weapon_in_reach(zone.hero.position) if near.is_empty() else -1
	var lit: int = zone.ground_weapons[reach]["id"] if reach >= 0 else -1
	if zone.hero.state != Fighter.State.IDLE:
		lit = -1
	for id: int in _weapons:
		_weapons[id].set_highlight(id == lit)


func _sync_weapons() -> void:
	var present := {}
	for entry: Dictionary in zone.ground_weapons:
		present[entry["id"]] = true
		if not _weapons.has(entry["id"]):
			var weapon := WeaponView.new()
			weapon.setup(content, entry)
			_entities.add_child(weapon)
			_weapons[entry["id"]] = weapon
	for id: int in _weapons.keys():
		if not present.has(id):
			_weapons[id].queue_free()
			_weapons.erase(id)


func _build_scenery() -> void:
	if not Scenery.build(self, content, zone.area_id):
		_build_flat_scenery()
	_build_exit_signs()


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
		name_label.add_theme_constant_override("outline_size", 3)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-40, -58)
		name_label.size = Vector2(80, 10)
		view.add_child(name_label)
		var mark := Label.new()
		mark.add_theme_font_size_override("font_size", 12)
		mark.add_theme_constant_override("outline_size", 4)
		mark.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.position = Vector2(-10, -74)
		mark.size = Vector2(20, 14)
		view.add_child(mark)
		_npc_marks[npc["id"]] = mark
		var prompt := CenterContainer.new()
		prompt.name = "Prompt"
		prompt.position = Vector2(-40, -92)
		prompt.size = Vector2(80, 12)
		prompt.visible = false
		prompt.add_child(UiKit.key_hint("E", "Shop" if npc["role"] == "shop" else "Talk"))
		view.add_child(prompt)
		_npc_prompts[npc["id"]] = prompt


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
