class_name ZoneView
extends Node2D
## Draws one ZoneSim: scenery built from the area's palette, NPCs, exits,
## fighters, pickups and hit effects. Holds no game state; `sync` mirrors the
## simulation every physics tick, creating and freeing views as fighters and
## pickups come and go.

const FIGHTER_SCENE := preload("res://scenes/fighter/FighterView.tscn")
const VIEW_HEIGHT := 360.0
## Camera shake on heavy impacts, in pixels, and how much it fades per tick.
const SHAKE_PIXELS := 3.0
const SHAKE_FADE := 0.25
## What E does at each NPC role, as the prompt over them says ("Talk" if
## not listed), and the mark always shown over a role that offers a service.
const VERBS := {"shop": "Shop", "travel": "Ride", "workbench": "Upgrade", "board": "Read"}
const MARKS := {"shop": "$", "travel": ">>", "workbench": "+", "board": "?"}
## Where landmark signs hang: on the shopfronts, above the marks and names
## over the people and things in the street.
const LANDMARK_Y := 128.0

var zone: ZoneSim
var content: ContentDB
var camera: Camera2D
## Floating numbers and effects in world space.
var effects: Node2D
## Effects left on the street itself (a skill's crack in the ground): under
## the fighters, and where they landed, not following anyone.
var ground: Node2D

var _entities: Node2D
var _views := {}
var _pickups := {}
var _weapons := {}
## Weapons in flight, by id: spinning sprites at chest height.
var _thrown := {}
## Exit signs by side, refreshed as their gates open.
var _exit_signs := {}
var _npc_marks := {}
var _npc_prompts := {}
var _shake := 0.0
## Set after the first sync: enemies there from the start are simply there.
var _shown := false


func build(p_zone: ZoneSim, p_content: ContentDB) -> void:
	zone = p_zone
	content = p_content
	_build_scenery()
	ground = Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	_entities = Node2D.new()
	_entities.name = "Entities"
	_entities.y_sort_enabled = true
	add_child(_entities)
	_build_npcs()
	_build_furniture()
	_build_landmarks()
	effects = Node2D.new()
	effects.name = "Effects"
	add_child(effects)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	sync()
	camera.reset_smoothing()
	# A turned or resized screen re-frames the street at once, even while
	# the game is paused under a menu.
	GameSession.layout_changed.connect(_reframe)


func _reframe(_layout: ScreenLayout) -> void:
	# A view on its way out (the area just changed) is no longer on screen.
	if zone == null or camera == null or not is_inside_tree():
		return
	_follow_hero()
	camera.reset_smoothing()


func sync() -> void:
	var alive := {}
	for f in zone.fighters:
		alive[f.id] = true
		if not _views.has(f.id):
			_views[f.id] = _make_fighter_view(f)
			if f.id != ZoneSim.HERO_ID and _shown:
				_fade_in(_views[f.id])
		if f.id == ZoneSim.HERO_ID:
			_views[f.id].set_art(hero_art(), content.art)
		else:
			_views[f.id].show_threat(zone.profile.level)
		_views[f.id].sync()
	for id: int in _views.keys():
		if not alive.has(id):
			_fade_out(_views[id])
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
	_sync_thrown()
	_update_exit_signs()
	_update_prompts()
	_follow_hero()
	_shown = true


## An enemy coming into the fight fades in over a moment instead of popping
## in. No smoke: nobody in this game teleports.
func _fade_in(fresh: FighterView) -> void:
	fresh.modulate.a = 0.0
	fresh.create_tween().tween_property(fresh, "modulate:a", 1.0, 0.25)


## A fallen enemy's body fades away instead of vanishing (no smoke).
func _fade_out(gone: FighterView) -> void:
	if not is_inside_tree() or gone.fighter == null or gone.fighter.id == ZoneSim.HERO_ID:
		gone.queue_free()
		return
	var tween := gone.create_tween()
	tween.tween_property(gone, "modulate:a", 0.0, 0.3)
	tween.tween_callback(gone.queue_free)


func view_of(id: int) -> FighterView:
	return _views.get(id)


func show_hit(event: CombatEvent) -> void:
	var label := DamageNumber.new()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	effects.add_child(label)
	label.show_hit(event)
	var heavy := (
		event.knocked_down or event.guard_broken or event.ko or event.counter or event.critical
	)
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
		if absf(offset.x) <= ZoneSim.TALK_REACH.x and absf(offset.y) <= ZoneSim.TALK_REACH.y:
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
		mark.visible = pending or MARKS.has(npc["role"])
		mark.text = str(MARKS.get(npc["role"], "!"))


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
	view.ambient = ambient_light(content, zone.area_id)
	_entities.add_child(view)
	if f.team == ZoneSim.ENEMY_TEAM:
		view.setup_enemy(content.enemy(f.kind), content.art, zone.enemy_level(f.id))
		if f.elite:
			view.mark_elite(content.enemy(f.kind))
		elif f.id == zone.boss_id and MapRules.kind_of(content, zone.area_id) == MapRules.MINI_BOSS:
			# The map's mini-boss mark, not the skull: a district's final boss and
			# the one waiting before it must not look alike.
			view.mark_mini_boss(content.enemy(f.kind))
	return view


## The light fighters stand in, in `area_id`: half way from white to the
## street kit's tint for the shopfronts behind them, so heroes and monsters
## take the colour of the street's light instead of looking pasted on.
static func ambient_light(content: ContentDB, area_id: String) -> Color:
	var tint: Dictionary = content.kit.get("areas", {}).get(area_id, {}).get("tint", {})
	var front := Color.from_string(str(tint.get("front", "#ffffff")), Color.WHITE)
	return Color.WHITE.lerp(front, 0.5)


func _make_pickup_view(pickup: Dictionary) -> Node2D:
	var loot := LootView.new()
	loot.setup(content, pickup, pickup.get("from", pickup["position"]))
	_entities.add_child(loot)
	return loot


func _follow_hero() -> void:
	var width := zone.bounds.end.x + ZoneSim.EDGE_MARGIN
	var span := Vector2(0, width)
	if zone.fight_locked():
		span = (
			Vector2(zone.arena.position.x, zone.arena.end.x) + Vector2(-1, 1) * ZoneSim.EDGE_MARGIN
		)
	var limits := camera_limits(span, width, get_viewport_rect().size.x)
	camera.limit_left = int(limits.x)
	camera.limit_right = int(limits.y)
	# Up and down the view is exactly as tall as its limits, so the street
	# (y 0 to VIEW_HEIGHT) lands where the screen layout wants it: under the
	# HUD band in portrait, filling the height in landscape (ScreenLayout).
	var top := street_top()
	var tall := get_viewport_rect().size.y
	camera.limit_top = int(roundf(-top))
	camera.limit_bottom = int(roundf(tall - top))
	camera.position = Vector2(zone.hero.position.x, tall / 2.0 - top)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	_shake = maxf(0.0, _shake - SHAKE_FADE)


## Where on screen the street's top edge goes (logical px), from the
## screen layout; with none, centred in the view as before.
func street_top() -> float:
	var layout: ScreenLayout = GameSession.layout
	if layout:
		return layout.world.position.y
	return (get_viewport_rect().size.y - VIEW_HEIGHT) / 2.0


## The camera's left and right limits for showing `span` (x from, x to: the
## whole area, or a fight's locked arena) of an area `width` wide in a view
## `view_width` wide. A camera whose limits are closer than the view is wide
## keeps the left one and shows past the right, beyond the end of the street
## (the gap players saw in narrow boss arenas, wider on wide windows). So a
## narrow span grows evenly to the view's width, then shifts back inside the
## street; only an area narrower than the view itself is shown centred.
static func camera_limits(span: Vector2, width: float, view_width: float) -> Vector2:
	var left := span.x
	var right := span.y
	var short := view_width - (right - left)
	if short > 0.0:
		left -= short / 2.0
		right += short / 2.0
	if left < 0.0:
		right -= left
		left = 0.0
	if right > width:
		left -= right - width
		right = width
	if left < 0.0:
		# The whole street is narrower than the view: centre it.
		var extra := -left
		left = -extra / 2.0
		right = width + extra / 2.0
	return Vector2(floorf(left), ceilf(right))


## Shakes the camera by up to `pixels` (if the player has shake turned on).
func shake(pixels: float) -> void:
	if GameSession.settings.get("screen_shake", true):
		_shake = maxf(_shake, pixels)


## Shows "[E] Talk" (or Shop) over the NPC the hero can talk to right now,
## or else "[E] Pick up" over the weapon at the hero's feet (not while the
## hero holds one: then E throws it).
func _update_prompts() -> void:
	var near := npc_near(zone.hero)
	for npc_id: String in _npc_prompts:
		_npc_prompts[npc_id].visible = not near.is_empty() and near["id"] == npc_id
	var reach := zone.weapon_in_reach(zone.hero.position) if near.is_empty() else -1
	var lit: int = zone.ground_weapons[reach]["id"] if reach >= 0 else -1
	if zone.hero.state != Fighter.State.IDLE or (zone.hero.weapon and zone.hero.throws):
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


func _sync_thrown() -> void:
	var present := {}
	for entry: Dictionary in zone.thrown:
		var id: int = entry["id"]
		present[id] = true
		if not _thrown.has(id):
			# A node on the lane (for depth sorting) holding the weapon at
			# chest height, where it spins.
			var holder := Node2D.new()
			var sprite := Sprite2D.new()
			var weapon: Dictionary = content.weapons.get(str(entry["weapon"]), {})
			sprite.texture = UiKit.icon(content, str(weapon.get("sprite", "")))
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(0, -28)
			holder.add_child(sprite)
			_entities.add_child(holder)
			_thrown[id] = holder
		var view: Node2D = _thrown[id]
		view.position = entry["position"]
		var flown := ZoneSim.THROW_TICKS - int(entry["ticks"])
		view.get_child(0).rotation = flown * 0.45 * float(entry["dir"])
	for id: int in _thrown.keys():
		if not present.has(id):
			_thrown[id].queue_free()
			_thrown.erase(id)


func _build_scenery() -> void:
	if not Scenery.build(self, content, zone.area_id, false):
		_build_flat_scenery()
	_build_exit_signs()


## Fallback for an area whose scenery has not been generated yet.
func _build_flat_scenery() -> void:
	var palette: Dictionary = zone.area.get("palette", {})
	var width := float(zone.area.get("width", 960))
	var ground := ZoneSim.LANE_TOP - 20.0
	# Past both ends too, as the street kit does (Scenery.GROUND_OVERRUN).
	var from := -Scenery.GROUND_OVERRUN
	var length := width + Scenery.GROUND_OVERRUN * 2.0
	_rect(Rect2(from, 0, length, ground), _color(palette, "sky", "#1a1830"))
	_rect(Rect2(from, ground, length, 20), _color(palette, "sidewalk", "#5c5a60"))
	_rect(
		Rect2(from, ZoneSim.LANE_TOP, length, VIEW_HEIGHT - ZoneSim.LANE_TOP),
		_color(palette, "street", "#38383f")
	)


## Lamp posts, poles, bins and crates: solid in the simulation, so drawn among
## the fighters, in front of or behind them by depth.
func _build_furniture() -> void:
	for obstacle: Dictionary in zone.area.get("obstacles", []):
		var node := Scenery.furniture(content, str(obstacle["kind"]))
		if node != null:
			node.position = Vector2(obstacle["x"], obstacle["y"])
			_entities.add_child(node)


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
		exit_sign.set_meta("place", str(target.get("name", "")))
		exit_sign.position = Vector2(8 if side == "west" else width - 198, ground + 2)
		exit_sign.size = Vector2(190, 12)
		exit_sign.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT if side == "west" else HORIZONTAL_ALIGNMENT_RIGHT
		)
		add_child(exit_sign)
		_exit_signs[side] = exit_sign
	_update_exit_signs()


## A locked exit reads "Locked" in red with how far the player has to go,
## so the way on is never a mystery; it turns back once the gate opens.
func _update_exit_signs() -> void:
	for side: String in _exit_signs:
		var exit_sign: Label = _exit_signs[side]
		var place := str(exit_sign.get_meta("place"))
		var gate := zone.exit_locked(side)
		var text := place
		if not gate.is_empty():
			text = "Locked  %d/%d  %s" % [int(gate["done"]), int(gate["count"]), place]
		exit_sign.text = "< " + text if side == "west" else text + " >"
		exit_sign.add_theme_color_override(
			"font_color", UiTheme.DANGER if not gate.is_empty() else UiTheme.TEXT
		)


func _build_npcs() -> void:
	for npc: Dictionary in zone.area.get("npcs", []):
		var view := _npc_body(npc)
		# Labels sit over the head, or over the top of a thing (a workbench).
		var top := -50.0
		if npc.has("piece"):
			top = minf(-Scenery.piece_height(content, str(npc["piece"])) - 8.0, -20.0)
		# The label rides on the NPC: what it is for ("service", e.g. Market) over
		# its mark and name on one line ("$ Ama"), so the two never part.
		if npc.has("service"):
			var service := Label.new()
			service.name = "Service"
			service.text = str(npc["service"]).to_upper()
			service.add_theme_font_size_override("font_size", 7)
			service.add_theme_constant_override("outline_size", 3)
			service.add_theme_color_override("font_color", UiTheme.GOLD)
			service.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			service.position = Vector2(-60, top - 20)
			service.size = Vector2(120, 10)
			view.add_child(service)
		var line := HBoxContainer.new()
		line.name = "Tag"
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 2)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position = Vector2(-60, top - 10)
		line.size = Vector2(120, 12)
		view.add_child(line)
		var mark := Label.new()
		mark.name = "Mark"
		mark.add_theme_font_size_override("font_size", 9)
		mark.add_theme_constant_override("outline_size", 3)
		mark.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		line.add_child(mark)
		var name_label := Label.new()
		name_label.name = "Name"
		name_label.text = str(npc["name"])
		name_label.add_theme_font_size_override("font_size", 7)
		name_label.add_theme_constant_override("outline_size", 3)
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(name_label)
		_npc_marks[npc["id"]] = mark
		var prompt := CenterContainer.new()
		prompt.name = "Prompt"
		prompt.position = Vector2(-40, top - (34 if npc.has("service") else 24))
		prompt.size = Vector2(80, 12)
		prompt.visible = false
		prompt.add_child(UiKit.key_hint("E", str(VERBS.get(npc["role"], "Talk"))))
		view.add_child(prompt)
		_npc_prompts[npc["id"]] = prompt


## Signs naming the parts of a place (areas.json "landmarks", e.g. the
## city's Taxi Rank and Market) over the shopfronts. Only words to read:
## nothing to press.
func _build_landmarks() -> void:
	var marks: Array = zone.area.get("landmarks", [])
	for i in marks.size():
		var mark: Dictionary = marks[i]
		var sign := Label.new()
		sign.name = "Landmark_%d" % i
		sign.text = str(mark["text"]).to_upper()
		sign.add_theme_font_size_override("font_size", UiTheme.SIZE_CAPTION)
		sign.add_theme_constant_override("outline_size", 3)
		sign.add_theme_color_override("font_color", UiTheme.GOLD)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.position = Vector2(float(mark["x"]) - 60.0, LANDMARK_Y)
		sign.size = Vector2(120, 10)
		add_child(sign)
		# Behind the fighters, so a sign never covers anyone.
		move_child(sign, _entities.get_index())


## A person (their character art) or a thing to use (a street-kit piece),
## standing at the NPC's spot among the fighters so depth sorts them.
func _npc_body(npc: Dictionary) -> Node2D:
	var at := Vector2(npc["x"], npc["y"])
	if npc.has("piece"):
		var thing := Scenery.piece_node(content, str(npc["piece"]))
		if thing != null:
			thing.name = "Station_" + str(npc["id"])
			thing.position = at
			_entities.add_child(thing)
			return thing
	var stand_in := Fighter.new(0, 0, at)
	stand_in.facing = -1
	var view: FighterView = FIGHTER_SCENE.instantiate()
	view.fighter = stand_in
	view.body_color = Color.from_string(str(npc.get("color", "#888888")), Color.GRAY)
	view.ambient = ambient_light(content, zone.area_id)
	_entities.add_child(view)
	view.set_art(str(npc.get("sprite", "")), content.art)
	view.sync()
	return view


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
