class_name Game
extends Node2D
## The running game: owns the current zone simulation and its view, feeds the
## hero's input in at a fixed 60 ticks per second, reacts to zone events
## (damage numbers, rewards, area changes, defeat), and opens the menus
## (built by GameMenus). While a menu is open the simulation does not tick.

const READY_MARKER := "GAME_READY"
const PROBE_INTERVAL := 0.1
## Healing items the quick-use button tries, in order.
const QUICK_HEAL := ["steamed_bun", "ginger_tea"]

var content: ContentDB
var profile: PlayerProfile
var zone: ZoneSim
var view: ZoneView
## Hits landed by anyone, and by the hero, since the game started.
var hits := 0
var hero_hits := 0
var menu: Control = null
var menu_name := ""
## The item the rebuilt bag or shop selects again, so acting on an item does
## not jump the cursor back to the top.
## "bag:<item id>" or "worn:<slot>" on the Equipment tab.
var menu_focus := ""
## The item card open over the pause window, if any.
var item_card: Control = null

var _pending_exit := {}
## Weapons left lying in each area this session, by area id, so a street keeps
## what was dropped on it (not saved: weapons are not lasting player state).
var _street_weapons := {}
var _probe_timer := 0.0
## A hotbar slot clicked or tapped since the last tick (-1: none).
var _clicked_slot := -1
var _feedback: GameFeedback

@onready var _world: Node2D = $World
@onready var _hud: CanvasLayer = $Hud
@onready var _menus: CanvasLayer = $Menus


func _ready() -> void:
	content = GameSession.content
	if GameSession.profile == null:
		GameSession.start_new_game()
	profile = GameSession.profile
	_feedback = GameFeedback.new(content, _hud)
	_hud.slot_pressed.connect(func(index: int) -> void: _clicked_slot = index)
	enter_area(profile.area, "")
	print("%s %s" % [READY_MARKER, BuildInfo.summary()])


func enter_area(area_id: String, entry: String) -> void:
	if zone:
		_street_weapons[zone.area_id] = zone.ground_weapons.duplicate(true)
	if view:
		_world.remove_child(view)
		view.queue_free()
	profile.area = area_id
	zone = ZoneSim.new(content, profile, area_id, entry, randi())
	if _street_weapons.has(area_id):
		zone.restore_weapons(_street_weapons[area_id])
	view = ZoneView.new()
	_world.add_child(view)
	view.build(zone, content)
	view.update_npc_marks(profile)
	_feedback.view = view
	_hud.attach(zone, profile, content)
	_hud.toast(str(zone.area.get("name", area_id)))
	SaveStore.save(profile)


func _physics_process(_delta: float) -> void:
	if menu:
		if menu_name == "game_over":
			return
		if item_card and is_instance_valid(item_card):
			if Input.is_action_just_pressed("pause"):
				close_item_card()
		elif Input.is_action_just_pressed("pause"):
			close_menu()
		elif menu_name in GameMenus.TAB_MENU_NAMES:
			if Input.is_action_just_pressed("menu_prev"):
				GameMenus.cycle_tab(menu, -1)
			elif Input.is_action_just_pressed("menu_next"):
				GameMenus.cycle_tab(menu, 1)
		return
	if Input.is_action_just_pressed("pause"):
		Sfx.play("ui_select", -4.0)
		open_pause()
		return
	var modifier := Input.is_action_pressed("skill_modifier")
	# E talks to a nearby NPC; anywhere else it picks up (or drops) a weapon.
	var pick := false
	if not modifier and Input.is_action_just_pressed("interact"):
		if try_interact():
			return
		pick = true
	if not modifier and Input.is_action_just_pressed("use_item"):
		quick_heal()
	var input := PlayerInput.read()
	input.pick = pick
	_explain_refusals(input)
	var slot := PlayerInput.slot_pressed()
	if _clicked_slot >= 0:
		slot = _clicked_slot
		_clicked_slot = -1
	if slot >= 0:
		use_slot(slot, input)
	elif input.light:
		# Z/J are the attack slot too: light it up so the link is visible.
		_hud.flash_slot(0, true)
	step(input)


## A heavy attack or dodge without the energy for it does nothing in the
## simulation; say so with a sound and a blinking energy bar.
func _explain_refusals(input: FighterInput) -> void:
	var hero := zone.hero
	if hero.state != Fighter.State.IDLE:
		return
	var heavy := content.moves.get_move(CombatRules.starter(hero, content.moves, "heavy"))
	var short := (
		(input.heavy and heavy and hero.energy < heavy.energy_cost)
		or (input.dodge and hero.energy < CombatRules.DODGE_COST)
	)
	if short:
		Sfx.play("denied", -6.0)
		_hud.flash_energy()


## Presses hotbar slot `index` for this tick's input. Checks here only give
## the player feedback; the simulation decides again whether a skill fires.
func use_slot(index: int, input: FighterInput) -> bool:
	var entry: Dictionary = content.hotbar_for(profile.hero)[index]
	var ok := true
	match entry["type"]:
		"attack":
			input.light = true
		"skill":
			var skill_id: String = entry["id"]
			var skill: Dictionary = content.skills[skill_id]
			var move := content.moves.get_move(str(skill["move"]))
			if not zone.hero.skills.has(skill_id):
				_hud.toast("%s unlocks at level %d" % [skill["name"], skill["unlock_level"]])
				ok = false
			elif zone.hero.cooldown_left(skill_id) > 0:
				ok = false
			elif zone.hero.energy < move.energy_cost:
				_hud.flash_energy()
				ok = false
			else:
				input.skill = skill_id
		"item":
			ok = _use_hotbar_item(str(entry["id"]))
	_hud.flash_slot(index, ok)
	if not ok:
		Sfx.play("denied", -4.0)
	return ok


func _use_hotbar_item(item_id: String) -> bool:
	if profile.count(item_id) == 0:
		_hud.toast("No %s left" % content.item(item_id)["name"])
		return false
	if not zone.use_item(item_id):
		return false
	_feedback.healed()
	return true


## Advances the zone one tick with the given hero input.
func step(input: FighterInput) -> Array[ZoneEvent]:
	var events := zone.tick(input)
	for event in events:
		_handle(event)
		_feedback.on_event(event)
	view.sync()
	if _pending_exit:
		var exit := _pending_exit
		_pending_exit = {}
		enter_area(exit["to"], exit["entry"])
	return events


func _handle(event: ZoneEvent) -> void:
	match event.type:
		"hit":
			hits += 1
			if event.hit.attacker_id == ZoneSim.HERO_ID:
				hero_hits += 1
			view.show_hit(event.hit)
		"defeat":
			var data := content.enemy(event.data["kind"])
			view.show_text("+%d XP" % event.data["xp"], zone.hero.position, Color(0.6, 0.9, 1))
			if event.data.get("boss", false):
				_hud.toast("%s defeated!" % data.get("name", "Boss"))
			SaveStore.save(profile)
		"quest_complete":
			var quest: Dictionary = content.quests[event.data["quest"]]
			_hud.toast("Quest complete: %s" % quest["name"])
			view.update_npc_marks(profile)
		"pickup":
			if event.data["kind"] == "money":
				view.show_text(
					"+%d coins" % event.data["amount"], zone.hero.position, Color(1, 0.85, 0.3)
				)
			else:
				var item := content.item(event.data["item"])
				view.show_text(
					"+" + str(item.get("name")), zone.hero.position, ItemText.rarity_color(item)
				)
				if item.get("type") == "equipment":
					_hud.toast("Found %s" % item["name"])
		"encounter_start":
			if event.data.get("boss", false):
				_hud.toast("A boss approaches!")
		"boss_phase":
			_hud.toast("It's enraged!")
		"hero_down":
			open_game_over.call_deferred()
		"exit":
			_pending_exit = event.data
		"weapon_pickup", "weapon_break":
			if event.data["id"] == ZoneSim.HERO_ID:
				var weapon: Dictionary = content.weapons[event.data["weapon"]]
				var broke := event.type == "weapon_break"
				var text := ("%s broke!" if broke else "%s") % weapon["name"]
				view.show_text(
					text, zone.hero.position, Color(1, 0.6, 0.4) if broke else UiTheme.GOLD
				)


## Talks to the NPC in reach, if any. Returns true when something opened.
func try_interact() -> bool:
	var npc := view.npc_near(zone.hero)
	if npc.is_empty():
		return false
	if npc["role"] == "shop":
		open_shop(npc)
	else:
		open_quests(npc)
	return true


func quick_heal() -> bool:
	for item_id: String in QUICK_HEAL:
		if zone.use_item(item_id):
			view.show_text(
				str(content.item(item_id)["name"]), zone.hero.position, Color(0.6, 1, 0.7)
			)
			_feedback.healed()
			return true
	if zone.item_cooldown == 0:
		_hud.toast("Nothing to eat")
	Sfx.play("denied", -4.0)
	return false


func close_menu() -> void:
	if menu:
		menu.queue_free()
		Sfx.play("ui_back", -4.0)
	menu = null
	menu_name = ""
	menu_focus = ""
	item_card = null
	zone.refresh_hero()
	view.update_npc_marks(profile)


func _show(name: String, screen: Control) -> void:
	if menu:
		menu.queue_free()
	menu = screen
	menu_name = name
	_menus.add_child(menu)
	if menu_focus.begins_with("bag:") or menu_focus.begins_with("worn:"):
		_refocus.call_deferred()
	else:
		UiKit.focus_first(menu)


func open_pause(tab := GameMenus.TAB_STATUS) -> void:
	_show(GameMenus.TAB_MENU_NAMES[tab], GameMenus.pause(self, tab))


func open_inventory() -> void:
	open_pause(GameMenus.TAB_BAG)


func open_quest_log() -> void:
	open_pause(GameMenus.TAB_QUESTS)


func open_shop(npc: Dictionary) -> void:
	_show("shop", GameMenus.shop(self, npc))


func open_quests(npc: Dictionary) -> void:
	_show("quests_npc", GameMenus.conversation(self, npc))


func open_game_over() -> void:
	var loss := int(profile.money * float(content.progression.get("defeat_money_loss", 0.0)))
	_show("game_over", GameMenus.knocked_out(self, loss))


## Opens the card for `item_id` (worn in `worn_slot`, or "" if in the bag)
## over the Equipment tab, with the actions that apply to it.
func inspect_item(item_id: String, worn_slot: String) -> void:
	close_item_card()
	var item := content.item(item_id)
	var actions: Array[Dictionary] = []
	if worn_slot:
		actions.append({"text": "Unequip", "call": _unequip.bind(worn_slot)})
	elif item.get("type") == "equipment":
		actions.append({"text": "Equip", "call": _equip.bind(item_id)})
	else:
		actions.append({"text": "Use", "call": _use.bind(item_id)})
	if not worn_slot:
		actions.append({"text": "Discard", "confirm": "Discard 1?", "call": _discard.bind(item_id)})
	menu_focus = "worn:" + worn_slot if worn_slot else "bag:" + item_id
	item_card = ItemCard.popup(menu, content, profile, item_id, worn_slot, actions, close_item_card)
	Sfx.play("ui_select", -6.0)


func close_item_card() -> void:
	if item_card and is_instance_valid(item_card):
		item_card.queue_free()
		_refocus.call_deferred()
	item_card = null


func _refocus() -> void:
	if menu == null:
		return
	var target := menu_focus.replace("bag:", "Bag_").replace("worn:", "Worn_")
	var slot := menu.find_child(target, true, false) as Control
	if slot and slot.focus_mode != Control.FOCUS_NONE:
		slot.grab_focus()
	else:
		UiKit.focus_first(menu)  # e.g. the last of a stack was used


func _use(item_id: String) -> void:
	if zone.use_item(item_id):
		_hud.toast("Used " + str(content.item(item_id)["name"]))
		_feedback.healed()
	elif zone.item_cooldown > 0:
		_hud.toast("Wait a moment before using another item")
	else:
		_hud.toast("No effect right now")
	_reopen_bag("bag:" + item_id)


func _equip(item_id: String) -> void:
	var item := content.item(item_id)
	match profile.equip_problem(item_id, content):
		"level":
			_hud.toast("Requires level %d" % int(item.get("level", 1)))
			Sfx.play("denied", -4.0)
		"":
			profile.equip(item_id, content)
			zone.refresh_hero()
			_hud.toast("Equipped " + str(item["name"]))
			SaveStore.save(profile)
			_reopen_bag("worn:" + str(item["slot"]))
			return
	_reopen_bag("bag:" + item_id)


func _unequip(slot: String) -> void:
	var item_id: String = profile.equipment[slot]
	profile.unequip(slot, content)
	zone.refresh_hero()
	SaveStore.save(profile)
	_reopen_bag("bag:" + item_id)


func _discard(item_id: String) -> void:
	if profile.remove_item(item_id):
		_hud.toast("Discarded " + str(content.item(item_id)["name"]))
		SaveStore.save(profile)
	_reopen_bag("")


func _reopen_bag(focus: String) -> void:
	item_card = null
	menu_focus = focus
	open_inventory()


func _buy(npc: Dictionary, item_id: String) -> void:
	var error := ShopRules.buy(profile, npc["shop"], item_id, content)
	_hud.toast("Bought " + str(content.item(item_id)["name"]) if not error else "Not enough coins")
	SaveStore.save(profile)
	menu_focus = item_id
	open_shop(npc)


func _accept(npc: Dictionary, quest_id: String) -> void:
	QuestRules.accept(profile, quest_id, content)
	_hud.toast("New quest: " + str(content.quests[quest_id]["name"]))
	SaveStore.save(profile)
	open_quests(npc)


func _turn_in(npc: Dictionary, quest_id: String) -> void:
	var level := profile.level
	var rewards := QuestRules.turn_in(profile, quest_id, content)
	if profile.level > level:
		var unlocked: Array[String] = []
		for reached in range(level + 1, profile.level + 1):
			unlocked.append_array(SkillRules.unlocked_at(content, profile.hero, reached))
		_feedback.level_up(profile.level, unlocked)
	if rewards:
		_hud.toast("+%d coins  +%d XP" % [rewards["money"], rewards["xp"]])
		zone.refresh_hero()
		SaveStore.save(profile)
	open_quests(npc)


func _recover(loss: int) -> void:
	profile.money -= loss
	profile.hp = profile.stats(content)["max_hp"]
	close_menu()
	enter_area(content.start_area, "")


func _save_game() -> void:
	_hud.toast("Saved" if SaveStore.save(profile) else "Save failed")
	close_menu()


func _quit_to_title() -> void:
	SaveStore.save(profile)
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")


func _process(delta: float) -> void:
	_probe_timer += delta
	if _probe_timer < PROBE_INTERVAL or not OS.has_feature("web"):
		return
	_probe_timer = 0.0
	var foes: Array = []
	for enemy in zone.enemies():
		if not enemy.is_ko():
			foes.append(
				{"x": enemy.position.x, "y": enemy.position.y, "hp": enemy.hp, "kind": enemy.kind}
			)
	var street_weapons: Array = []
	for entry: Dictionary in zone.ground_weapons:
		street_weapons.append([entry["position"].x, entry["position"].y])
	(
		GameSession
		. publish_probe(
			{
				"scene": "game",
				"area": zone.area_id,
				"hero": profile.hero,
				"name": profile.name,
				"menu": menu_name,
				"x": zone.hero.position.x,
				"y": zone.hero.position.y,
				"facing": zone.hero.facing,
				"hp": zone.hero.hp,
				"energy": zone.hero.energy,
				"state": zone.hero.state_name(),
				"level": profile.level,
				"money": profile.money,
				"fighting": zone.in_encounter(),
				"enemies": foes,
				"hits": hits,
				"hero_hits": hero_hits,
				"cooldowns": zone.hero.cooldowns,
				"weapon": zone.hero.weapon,
				"street_weapons": street_weapons,
			}
		)
	)
