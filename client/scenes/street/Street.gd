extends Node2D
## The game: The Iron Legacy's existing city areas (their scenery, furniture and
## exits, data/areas.json) with World of ClaudeCraft's monsters on them
## (data/rpg/placement.json, PROPOSED), all run by the one reference engine,
## RpgEncounter in zone mode with respawn. The player is the saved RpgSave v3
## character (SaveStore player/). This scene reads input and draws; every action is
## an engine command (client/scenes/CLAUDE.md).
##
## ADAPTED (docs/ADAPTATION_REGISTER.md):
## * PROD-SCALE: the engine's street axis is in yards; it is drawn at 16 px per yard
##   on the area's own width, and every unit stands on one lane line (cosmetic depth
##   per unit only);
## * PROD-AUTO: auto walks to its target (RpgEncounter._auto_walk);
## * exits: walking off a street end with an exit enters the next area.

const TITLE_SCENE := "res://scenes/title/Title.tscn"
const HUD_SCENE := preload("res://scenes/ui/Hud.tscn")
const LANE_Y := 300.0
const SAVE_EVERY := 5.0
const VIEW_HEIGHT := 360.0

var content: ContentDB
var pack: Dictionary
var state: Dictionary = {}
var fight: RpgEncounter
var area_id := ""
var area: Dictionary = {}
## The game's own HUD (scenes/ui/Hud.tscn), read from the engine (Hud.attach_rpg).
var hud: CanvasLayer
## The game screens (Character, Equipment, Bag, Skills, Settings, the Esc menu).
var menus: StreetMenuHost
var px_per_yard := 16.0
## Tests turn scene changes off and read where the street would go.
var navigate := true
var went_to := ""
var _world: Node2D
var _camera: Camera2D
var _views := {}
var _player_view: UnitSprite
var _facing := {}
var _accum := 0.0
var _save_timer := 0.0
var _probe_timer := 0.0
var _seed := 1
var _travel_cooldown := 0.0
var _loot_button: Button
var _revive_button: Button


func _ready() -> void:
	content = GameSession.content
	pack = RpgPack.of(content)
	px_per_yard = float(content.rpg.get("placement", {}).get("px_per_yard", 16))
	_seed = int(Time.get_ticks_usec() & 0x7FFFFFFF) | 1
	if GameSession.character_id != "":
		state = SaveStore.load_player(GameSession.character_id, content)
	if state.is_empty():
		get_tree().call_deferred("change_scene_to_file", TITLE_SCENE)
		return
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.slot_pressed.connect(_slot)
	hud.auto_pressed.connect(_action.bind("auto"))
	hud.menu_pressed.connect(func(screen: String) -> void: menus.open_screen(screen))
	menus = StreetMenuHost.new(self)
	add_child(menus)
	_build_actions()
	var start := str(state.get("area", ""))
	if not content.areas.has(start):
		start = content.start_area
	enter_area(start, "")


# -- areas -----------------------------------------------------------------------


## Builds area `id` and its street of monsters. `side`: the entry ("west", "east"
## or "" for the area's start).
func enter_area(id: String, side: String) -> void:
	area_id = id
	area = content.area(id)
	state["area"] = id
	if _world:
		remove_child(_world)
		_world.queue_free()
	_views.clear()
	_facing.clear()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	move_child(_world, 0)
	if not Scenery.build(_world, content, id, true):
		_flat_scenery()
	var width_yd := float(area.get("width", 960)) / px_per_yard
	var spawns: Array = content.rpg.get("placement", {}).get("areas", {}).get(id, {}).get(
		"spawns", []
	)
	var start_x := 3.0
	if side == "east":
		start_x = width_yd - 3.0
	_seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF
	fight = RpgEncounter.start_zone(content, pack, state, spawns, RpgRng.seeded(_seed), start_x)
	fight.respawn = true
	fight.auto_mode = false
	fight.bounds = Vector2(0.5, width_yd - 0.5)
	_player_view = _make_view(fight.player, _player_art(), str(state["name"]), UiTheme.ACCENT)
	for i: int in fight.mobs.size():
		_add_mob_view(fight.mobs[i], spawns[i] if i < spawns.size() else {})
	_camera = Camera2D.new()
	_camera.limit_left = 0
	_camera.limit_right = int(area.get("width", 960))
	_camera.limit_top = 0
	_camera.limit_bottom = int(VIEW_HEIGHT)
	_world.add_child(_camera)
	_camera.make_current()
	hud.attach_rpg(fight, state, content)
	var levels := _levels_here(id)
	hud.toast(
		(
			"%s: a safe street" % area.get("name", id)
			if levels == ""
			else "%s: monsters level %s" % [area.get("name", id), levels]
		)
	)
	_travel_cooldown = 0.5
	_save()


func _levels_here(id: String) -> String:
	var rec: Dictionary = content.rpg.get("placement", {}).get("areas", {}).get(id, {})
	if rec.is_empty() or rec.get("spawns", []).is_empty():
		return ""
	var lo := 99
	var hi := 0
	for mid: String in rec["monsters"]:
		var m := RpgPack.monster(pack, mid)
		lo = mini(lo, int(m["level_min"]))
		hi = maxi(hi, int(m["level_max"]))
	return "%d-%d" % [lo, hi]


func _flat_scenery() -> void:
	var palette: Dictionary = area.get("palette", {})
	var width := float(area.get("width", 960))
	var sky := ColorRect.new()
	sky.color = Color.from_string(str(palette.get("sky", "#1a1830")), Color.BLACK)
	sky.size = Vector2(width, 230)
	_world.add_child(sky)
	var street := ColorRect.new()
	street.color = Color.from_string(str(palette.get("street", "#38383f")), Color.DIM_GRAY)
	street.position = Vector2(0, 230)
	street.size = Vector2(width, VIEW_HEIGHT - 230)
	_world.add_child(street)


## The class's existing LPC sheet (data/class_visuals.json names them class_<id>_m).
func _player_art() -> String:
	return "class_%s_m" % state["class_id"]


func _make_view(u: Dictionary, art: String, title: String, color: Color) -> UnitSprite:
	var view := UnitSprite.new()
	view.unit_id = int(u["id"])
	view.name = "Unit_%d" % u["id"]
	_world.add_child(view)
	view.setup(content, art, title, color)
	view.set_meta("art", art)
	_views[int(u["id"])] = view
	_facing[int(u["id"])] = 1
	return view


func _add_mob_view(m: Dictionary, spawn: Dictionary) -> void:
	var name := str(RpgPack.monster(pack, str(m["template_id"])).get("display_name"))
	var title := "%s  Lv %d" % [name, m["level"]]
	_make_view(m, str(spawn.get("sprite", "")), title, UiTheme.TEXT)


func _travel(side: String) -> void:
	var exit: Dictionary = area.get("exits", {}).get(side, {})
	if exit.is_empty() or not content.areas.has(str(exit.get("to", ""))):
		return
	_store()
	enter_area(str(exit["to"]), str(exit.get("entry", "")))


# -- the loop --------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if fight == null:
		return
	_travel_cooldown = maxf(0.0, _travel_cooldown - delta)
	# No walking while a game screen is open (its keys move the focus).
	var dir := 0 if menus.is_open() else int(signf(Input.get_axis("move_left", "move_right")))
	if dir != 0 and fight.auto_mode:
		fight.command({"op": "auto", "on": false})
	if not fight.auto_mode and fight.outcome == "fighting":
		fight.command({"op": "move", "dir": dir})
	if fight.outcome == "fighting":
		_accum += delta
		while _accum >= fight.dt and fight.outcome == "fighting":
			_accum -= fight.dt
			fight.step()
	_read_events()
	_check_exits(dir)
	_save_timer += delta
	if _save_timer >= SAVE_EVERY:
		_save()


func _process(delta: float) -> void:
	if fight == null:
		return
	_sync_views(delta)
	_loot_button.visible = _has_loot() and not fight.player["dead"]
	_revive_button.visible = fight.outcome == "defeat"
	_probe_timer += delta
	if _probe_timer >= 0.1:
		_probe_timer = 0.0
		GameSession.publish_probe(probe())


func _check_exits(dir: int) -> void:
	if dir == 0 or _travel_cooldown > 0.0 or fight.player["dead"]:
		return
	var x := float(fight.player["x"])
	if dir < 0 and x <= fight.bounds.x + 0.01:
		_travel("west")
	elif dir > 0 and x >= fight.bounds.y - 0.01:
		_travel("east")


func _unhandled_input(event: InputEvent) -> void:
	if fight == null:
		return
	if menus.is_open():
		_menu_input(event)
		return
	for slot in range(1, InputSetup.HOTBAR_SLOTS + 1):
		if event.is_action_pressed("slot_%d" % slot):
			_slot(slot - 1)
	if event.is_action_pressed("attack_light"):
		_attack()
	elif event.is_action_pressed("auto_battle"):
		_action("auto")
	elif event.is_action_pressed("interact"):
		_action("revive" if fight.outcome == "defeat" else "loot")
	elif event.is_action_pressed("pause"):
		menus.open_pause()
	else:
		_screen_key(event)


## While a screen is open: Esc closes it, Q / E switch screens, C / B / V toggle
## theirs; nothing reaches the fight.
func _menu_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		menus.close_menu()
	elif event.is_action_pressed("menu_prev"):
		menus.cycle(-1)
	elif event.is_action_pressed("menu_next"):
		menus.cycle(1)
	else:
		_screen_key(event)
	get_viewport().set_input_as_handled()


func _screen_key(event: InputEvent) -> void:
	for screen: String in ["character", "bag", "skills"]:
		if event.is_action_pressed(screen):
			menus.open_screen(screen)
			get_viewport().set_input_as_handled()
			return


## J: target the nearest monster (unless one is targeted) and start the auto attack.
func _attack() -> void:
	if fight.mob.is_empty() or fight.mob["dead"]:
		_say(fight.command({"op": "target_nearest"}))
	_say(fight.command({"op": "attack"}))


func _cast(ability_id: String) -> void:
	if ability_id == "" or fight == null:
		return
	if fight.mob.is_empty() or fight.mob["dead"]:
		fight.command({"op": "target_nearest"})
	_say(fight.command({"op": "cast", "ability": ability_id}))


func _action(action: String) -> void:
	match action:
		"auto":
			fight.command({"op": "auto", "on": not fight.auto_mode})
		"loot":
			_say(RpgEncounter.take_loot(state))
			_save()
		"revive":
			_say(RpgEncounter.revive_at_corpse(content, pack, state))
			enter_area(area_id, "")


## Save and quit: the title opens only once the save is confirmed durable, so a
## reload right after it finds this state.
func quit_to_title() -> void:
	var ok: bool = await save_durably()
	if not ok:
		hud.toast("Could not save. Try again.")
		return
	went_to = TITLE_SCENE
	if navigate:
		get_tree().change_scene_to_file(TITLE_SCENE)


## Hotbar slot `index` (0-based): the first is the auto attack, the rest abilities.
func _slot(index: int) -> void:
	if index == 0:
		_attack()
	else:
		_cast(hud.ability_at(index))


## Loot and Resurrect: buttons over the hotbar, so touch and mouse reach them too.
func _build_actions() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.position.y -= 52
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(row)
	_loot_button = UiKit.button("Take loot (E)", _action.bind("loot"))
	_loot_button.name = "TakeLoot"
	_loot_button.focus_mode = Control.FOCUS_NONE
	row.add_child(_loot_button)
	_revive_button = UiKit.button("Resurrect (E)", _action.bind("revive"))
	_revive_button.name = "Resurrect"
	_revive_button.focus_mode = Control.FOCUS_NONE
	row.add_child(_revive_button)


func _has_loot() -> bool:
	for c: Dictionary in state.get("corpses", []):
		if int(c["loot"]["copper"]) > 0 or not c["loot"]["items"].is_empty():
			return true
	return false


func _say(text: String) -> void:
	if text != "" and not text.begins_with(RpgEncounter.SILENT):
		hud.toast(text)
		Sfx.play("denied", -8.0)


# -- engine events and views -----------------------------------------------------


func _read_events() -> void:
	for e: Dictionary in fight.events:
		match str(e.get("type", "")):
			"damage":
				_show_damage(e)
			"heal":
				_float_text(int(e["target"]), "+%d" % e["amount"], UiTheme.GOOD)
			"reward":
				var name := str(RpgPack.monster(pack, str(e["monster"])).get("display_name"))
				hud.toast("%s defeated: %d XP" % [name, e["xp"]])
				Sfx.play("coin", -6.0)
				if int(e["levels"]) > 0:
					Sfx.play("level_up")
					hud.chapter("LEVEL UP!", "Level %d" % state["level"])
				_save()
			"respawn":
				_respawned(int(e["unit"]))
			"error":
				_say(str(e.get("text", "")))
			"death":
				if int(e["unit"]) == int(fight.player["id"]):
					hud.chapter("YOU DIED", "Resurrect at your corpse (E)")
					Sfx.play("ko")
					_save()
	fight.events.clear()


func _show_damage(e: Dictionary) -> void:
	var amount := int(e["amount"])
	var to_player := int(e["target"]) == int(fight.player["id"])
	if amount <= 0:
		_float_text(int(e["target"]), str(e.get("kind", "miss")), UiTheme.TEXT_DIM)
		return
	if to_player:
		hud.hurt(0.6)
	var text := str(amount) + ("!" if e.get("crit", false) else "")
	_float_text(int(e["target"]), text, UiTheme.DANGER if to_player else UiTheme.GOLD)
	Sfx.play("hero_hurt" if to_player else ("hit_heavy" if e.get("crit") else "hit_light"), -6.0)


func _float_text(unit_id: int, text: String, color: Color) -> void:
	var view: UnitSprite = _views.get(unit_id)
	if view == null:
		return
	var label := UiKit.overlay_label(text, UiTheme.SIZE_SMALL, color)
	label.position = view.position + Vector2(-12, -90)
	_world.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 18.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)


func _respawned(unit_id: int) -> void:
	var view: UnitSprite = _views.get(unit_id)
	var art := ""
	if view:
		art = view.get_meta("art", "")
		view.queue_free()
	var m := fight.unit(unit_id)
	if not m.is_empty():
		_add_mob_view(m, {"sprite": art})


func _sync_views(delta: float) -> void:
	var units: Array = [fight.player]
	units.append_array(fight.mobs)
	for u: Dictionary in units:
		var view: UnitSprite = _views.get(int(u["id"]))
		if view == null or not is_instance_valid(view):
			continue
		var at := Vector2(float(u["x"]) * px_per_yard, LANE_Y + _depth(int(u["id"])))
		var face: int = _facing[int(u["id"])]
		var other := fight.mob if u == fight.player else fight.player
		if not other.is_empty() and (u == fight.player or u["engaged"]):
			face = 1 if float(other["x"]) >= float(u["x"]) else -1
		elif absf(at.x - view.position.x) > 0.05:
			face = 1 if at.x > view.position.x else -1
		_facing[int(u["id"])] = face
		view.show_unit(u, at, face, delta)
		if u != fight.player:
			view.mark(UiTheme.GOLD if u == fight.mob else UiTheme.TEXT)
	_camera.position = Vector2(float(fight.player["x"]) * px_per_yard, VIEW_HEIGHT / 2.0)


## Cosmetic lane depth so a crowd of monsters stays readable.
static func _depth(unit_id: int) -> float:
	return 0.0 if unit_id == 1 else float((unit_id * 7) % 5 - 2) * 6.0


# -- saving ----------------------------------------------------------------------


func _store() -> void:
	if fight != null:
		fight.store_vitals()


func _save() -> void:
	save_durably()


## Save, then wait until this state, or a newer one, is durable (DurableSave: on
## the web, a completed IndexedDB commit of it). False only if that has not
## happened within `seconds`; the commit goes on. Whether the latest state is
## saved is DurableSave's number for this file, never a flag set here.
func save_durably(seconds := 60.0) -> bool:
	_save_timer = 0.0
	_store()
	if not SaveStore.save_player(state):
		return false
	var path := _save_path()
	return await DurableSave.wait_durable(path, DurableSave.request(path), seconds)


func _save_path() -> String:
	return SaveStore.player_folder().path_join(str(state["id"]) + ".json")


## Read-only state for the browser smoke test: what the HUD already shows.
func probe() -> Dictionary:
	var target := fight.mob
	return {
		"scene": "street",
		"area": area_id,
		"name": str(state["name"]),
		"class": str(state["class_id"]),
		"level": int(state["level"]),
		"kills": int(state.get("kills", 0)),
		"hp": int(fight.player["hp"]),
		"x": float(fight.player["x"]),
		"dead": bool(fight.player["dead"]),
		"auto": fight.auto_mode,
		"monsters": fight.mobs.filter(func(m: Dictionary) -> bool: return not m["dead"]).size(),
		"target_hp": -1 if target.is_empty() else int(target["hp"]),
		"menu": menus.menu_name,
		"focus": _focus_name(),
		"save_requested": DurableSave.requested_seq(_save_path()),
		"save_durable": DurableSave.durable_seq(_save_path()),
		"settings_requested": DurableSave.requested_seq(GameSession.SETTINGS_PATH),
		"settings_durable": DurableSave.durable_seq(GameSession.SETTINGS_PATH),
		"show_fps": bool(GameSession.settings.get("show_fps", false)),
		"spec": str(state.get("spec_id", "")),
		"equipment": state["equipment"].duplicate(),
		"bag": state["inventory"].map(func(r: Dictionary) -> String: return r["item_id"]),
		"hotbar": state.get("hotbar", []).duplicate(),
		"talents": state.get("talents", {}).duplicate(),
		"attack_power": int(fight.player["attack_power"]),
		"armor": int(fight.player["armor"]),
	}


func _focus_name() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	return str(owner.name) if owner != null else ""
