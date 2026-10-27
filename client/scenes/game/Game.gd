class_name Game
extends Node2D
## The running game: owns the current zone simulation and its view, feeds the
## hero's input in at a fixed 60 ticks per second, reacts to zone events
## (damage numbers, rewards, area changes, defeat), and opens the menus
## (built by GameMenus). While a menu is open the simulation does not tick.

const READY_MARKER := "GAME_READY"
const PROBE_INTERVAL := 0.1
const UPGRADE_GAP_MS := 400

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
## Auto battle (AutoBattle): the switch, the farm loop and its tally.
var auto: AutoBattle
## The world boss attempt under way (WorldBossRun), or null.
var world_run: WorldBossRun = null
## Unix time to use instead of the clock (tests); -1 for the real clock.
var now_override := -1

var _pending_exit := {}
## Weapons left lying in each area this session, by area id, so a street keeps
## what was dropped on it (not saved: weapons are not lasting player state).
var _street_weapons := {}
var _probe_timer := 0.0
## A hotbar slot clicked or tapped since the last tick (-1: none).
var _clicked_slot := -1
var _feedback: GameFeedback
var _last_upgrade_ms := -100000
## Rolls upgrades. Offline the client rolls them; online the server will.
var _upgrade_rng := RandomNumberGenerator.new()
var _world_rng := RandomNumberGenerator.new()
## Each world boss's round last announced, so each opening is told once.
var _announced := {}
var _clock_timer := 0.0
var _entering_world_boss := false

@onready var _world: Node2D = $World
@onready var _hud: CanvasLayer = $Hud
@onready var _menus: CanvasLayer = $Menus


func _ready() -> void:
	_upgrade_rng.randomize()
	_world_rng.randomize()
	content = GameSession.content
	if GameSession.profile == null:
		GameSession.start_new_game()
	profile = GameSession.profile
	_feedback = GameFeedback.new(content, _hud)
	_hud.slot_pressed.connect(func(index: int) -> void: _clicked_slot = index)
	_hud.auto_pressed.connect(func() -> void: auto.toggle())
	_hud.map_pressed.connect(
		func() -> void:
			if not menu:
				open_pause(GameMenus.TAB_MAP)
	)
	enter_area(profile.area, "")
	auto = AutoBattle.new(self)
	print("%s %s" % [READY_MARKER, BuildInfo.summary()])


func enter_area(area_id: String, entry: String, start_x := -1.0) -> void:
	# The world boss arena is only ever entered for an attempt (Win's taxi).
	if content.area(area_id).get("world_boss", false) and not _entering_world_boss:
		area_id = content.start_area
		entry = ""
	if zone:
		_street_weapons[zone.area_id] = zone.ground_weapons.duplicate(true)
	if view:
		_world.remove_child(view)
		view.queue_free()
	profile.area = area_id
	zone = ZoneSim.new(content, profile, area_id, entry, randi(), start_x)
	if _street_weapons.has(area_id):
		zone.restore_weapons(_street_weapons[area_id])
	view = ZoneView.new()
	_world.add_child(view)
	view.build(zone, content)
	view.update_npc_marks(profile)
	_feedback.view = view
	_hud.attach(zone, profile, content)
	var spot := MapRules.locate(content, area_id)
	var arrived := str(zone.area.get("name", area_id))
	if spot:
		arrived += "  ·  %s %d/%d" % [spot["name"], int(spot["index"]) + 1, spot["count"]]
	_hud.toast(arrived)
	if auto:
		auto.entered(area_id)
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
		elif menu_name == "map" and Input.is_action_just_pressed("map"):
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
	if Input.is_action_just_pressed("map"):
		Sfx.play("ui_select", -4.0)
		open_pause(GameMenus.TAB_MAP)
		return
	if Input.is_action_just_pressed("auto_battle"):
		auto.toggle()
	var modifier := Input.is_action_pressed("skill_modifier")
	# E talks to a nearby NPC; anywhere else it picks up (or drops) a weapon.
	var pick := false
	if not modifier and Input.is_action_just_pressed("interact"):
		if try_interact():
			return
		pick = true
	var ate := not modifier and Input.is_action_just_pressed("use_item")
	if ate:
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
	if auto.on:
		input = auto.input(input, ate or slot >= 0 or PlayerInput.is_active(input))
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
	if world_run:
		world_run.tick(zone, events)
	if not TutorialRules.is_done(profile, content):
		for action: String in TutorialRules.signals_for(events, zone.hero, input, content.moves):
			tutorial_signal(action)
	view.sync()
	if world_run and world_run.ended:
		_finish_world_boss()
	if _pending_exit:
		var exit := _pending_exit
		_pending_exit = {}
		enter_area(exit["to"], exit["entry"])
	if auto:
		auto.after_step(events)
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
		"encounter_clear":
			# Only where the street goes on east (not at the end of the line).
			if not zone.in_encounter() and zone.area.get("exits", {}).has("east"):
				_hud.show_go()
		"encounter_start":
			_hud.show_go(false)
			if event.data.get("boss", false):
				_hud.toast("A boss approaches!")
		"boss_phase":
			_hud.toast("It's enraged!")
		"boss_shield":
			var shielded := bool(event.data["up"])
			_hud.toast("Defences up. Survive!" if shielded else "System reset. Strike now!")
		"boss_summon":
			var boss := content.enemy(zone.fighter(event.data["id"]).kind)
			_hud.toast("%s calls for backup!" % boss.get("name", "The boss"))
		"hero_down":
			if world_run == null:
				open_game_over.call_deferred()
		"exit":
			_pending_exit = event.data
		"exit_locked":
			_hud.toast(
				"%s  (%d/%d)" % [event.data["hint"], event.data["done"], event.data["count"]]
			)
			Sfx.play("denied", -4.0)
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
	elif npc["role"] == "travel":
		_show("travel", GameMenus.travel(self, npc))
	else:
		open_quests(npc)
	return true


func hud_toast(text: String) -> void:
	_hud.toast(text)


## Feedback for food eaten by auto battle, as for the quick-heal key.
func healed_by(item_id: String) -> void:
	view.show_text(str(content.item(item_id)["name"]), zone.hero.position, Color(0.6, 1, 0.7))
	_feedback.healed()


## The quick-heal key: the food that best fits what is missing (FoodRules).
func quick_heal() -> bool:
	var missing := zone.hero.max_hp - zone.hero.hp
	var item_id := FoodRules.choose(profile, content, missing)
	if item_id and zone.use_item(item_id):
		healed_by(item_id)
		return true
	if zone.item_cooldown == 0 and item_id == "":
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


## Counts a tutorial action; a finished step chimes, and the last one says
## the street is open.
func tutorial_signal(action: String) -> void:
	if not TutorialRules.notify(profile, action, content):
		return
	Sfx.play("quest", -4.0)
	if TutorialRules.is_done(profile, content):
		_hud.toast("Tutorial complete. The street is yours.")
	SaveStore.save(profile)


func skip_tutorial() -> void:
	TutorialRules.skip(profile, content)
	SaveStore.save(profile)
	close_menu()
	_hud.toast("Tutorial skipped. Controls are in the menu (Esc).")


func open_quests(npc: Dictionary, said := "") -> void:
	if npc.get("role") == "quests":
		tutorial_signal("talk")
	_show("quests_npc", GameMenus.conversation(self, npc, said))


func open_game_over() -> void:
	var loss := int(profile.money * float(content.progression.get("defeat_money_loss", 0.0)))
	var boss := zone.respawn_x() > zone.bounds.position.x + 24.0
	_show("game_over", GameMenus.knocked_out(self, loss, boss))


## Opens the card for `item_id` (worn in `worn_slot`, or "" if in the bag)
## over the Equipment tab, with the actions that apply to it.
func inspect_item(item_id: String, worn_slot: String) -> void:
	close_item_card()
	var item := content.item(item_id)
	var actions: Array[Dictionary] = []
	if worn_slot:
		var next := EnhanceRules.next_cost(profile, worn_slot, content)
		if next:
			var odds := roundi(EnhanceRules.chance(profile, worn_slot, content) * 100.0)
			var label := "Upgrade +%d (%d%%)" % [EnhanceRules.level(profile, worn_slot) + 1, odds]
			actions.append({"text": label, "call": _upgrade.bind(worn_slot)})
		actions.append({"text": "Unequip", "call": _unequip.bind(worn_slot)})
	elif item.get("type") == "equipment":
		actions.append({"text": "Equip", "call": _equip.bind(item_id)})
	elif item.get("type") == "consumable":
		actions.append({"text": "Use", "call": _use.bind(item_id)})
	# Evidence is the story: it cannot be thrown away.
	if not worn_slot and item.get("type") != "key":
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


## One upgrade attempt at the workbench (safe areas only). Saved at once,
## and a second press within UPGRADE_GAP_MS is ignored, so a double click
## never spends twice by accident.
func _upgrade(slot: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_upgrade_ms < UPGRADE_GAP_MS:
		return
	_last_upgrade_ms = now
	if not zone.area.get("safe", false):
		_hud.toast("Upgrade at the workbench in a safe area (the Depot Yard).")
		Sfx.play("denied", -4.0)
		return
	var outcome := EnhanceRules.attempt(profile, slot, content, _upgrade_rng)
	match outcome["result"]:
		"success":
			_hud.toast("Upgraded to +%d!" % outcome["level"])
			Sfx.play("level_up", -4.0)
		"fail":
			var odds := roundi(EnhanceRules.chance(profile, slot, content) * 100.0)
			_hud.toast("The upgrade failed. Next try: %d%%." % odds)
			Sfx.play("break_metal", -4.0)
		"coins":
			_hud.toast("Not enough coins.")
			Sfx.play("denied", -4.0)
		"materials":
			_hud.toast("Not enough materials. The item card says where to find them.")
			Sfx.play("denied", -4.0)
	zone.refresh_hero()
	SaveStore.save(profile)
	# Rebuild the screen behind the card too, so the slot's "+N" is current.
	_reopen_bag("worn:" + slot)
	inspect_item(str(profile.equipment[slot]), slot)


func _unequip(slot: String) -> void:
	var item_id: String = profile.equipment[slot]
	profile.unequip(slot, content)
	zone.refresh_hero()
	SaveStore.save(profile)
	_reopen_bag("bag:" + item_id)


func _discard(item_id: String) -> void:
	if profile.discard(item_id, content):
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
	var quest: Dictionary = content.quests[quest_id]
	if rewards:
		var found: Array[String] = []
		for item_id: String in rewards["items"]:
			if content.item(item_id).get("type") == "key":
				found.append(str(content.item(item_id)["name"]))
		var text := "+%d coins  +%d XP" % [rewards["money"], rewards["xp"]]
		_hud.toast(text + ("  New evidence: " + ", ".join(found) if found else ""))
		zone.refresh_hero()
		SaveStore.save(profile)
		var chapter: Dictionary = quest.get("ends_chapter", {})
		if chapter:
			_hud.chapter(str(chapter["title"]), str(chapter.get("subtitle", "")))
		if chapter.has("epilogue"):
			_show("epilogue", GameMenus.epilogue(self, chapter))
			return
	open_quests(npc, str(quest.get("dialogue", {}).get("done", "")) if rewards else "")


## Back on your feet where you fell: at the west end of the same area, or just
## short of the boss fight lost. Fights already won stay won (StreetMemory).
func _recover(loss: int) -> void:
	profile.money -= loss
	profile.hp = profile.stats(content)["max_hp"]
	close_menu()
	enter_area(zone.area_id, "west", zone.respawn_x())


## The motorbike taxi: pay the fare and ride to an area reached before.
func _ride(npc: Dictionary, area_id: String) -> void:
	var fare := int(npc.get("fare", 0))
	if profile.money < fare:
		_hud.toast("Not enough coins for the ride")
		Sfx.play("denied", -4.0)
		return
	profile.money -= fare
	close_menu()
	enter_area(area_id, "west")


## Unix time now (or the test's).
func _now() -> int:
	return now_override if now_override >= 0 else int(Time.get_unix_time_from_system())


## Win's ride to world boss `boss`: an attempt starts on arrival.
func _ride_world_boss(npc: Dictionary, boss: String) -> void:
	var problem := WorldBossRules.problem(profile, content, boss, _now())
	var fare := int(npc.get("fare", 0))
	if problem == "" and profile.money < fare:
		problem = "Not enough coins for the ride"
	if problem:
		_hud.toast(problem)
		Sfx.play("denied", -4.0)
		return
	profile.money -= fare
	close_menu()
	_start_world_boss(boss)


## Into `boss`'s arena for one attempt at this round's pool.
func _start_world_boss(boss: String) -> void:
	var data := WorldBossRules.spec(content, boss)
	var round := int(WorldBossRules.window(content, boss, _now())["round"])
	_entering_world_boss = true
	enter_area(str(data["area"]), "west")
	_entering_world_boss = false
	world_run = WorldBossRun.new(zone, profile, content, boss, round)
	_hud.attach(zone, profile, content)
	auto.stop()
	var name := str(content.enemy(str(data["enemy"]))["name"])
	_hud.toast("%s rises. %d seconds!" % [name, world_run.seconds_left()])


## The attempt is over: bank its damage, pay new tiers (and the kill), show
## what it won.
func _finish_world_boss() -> void:
	var run := world_run
	var paid := WorldBossRules.award(
		profile,
		content,
		run.boss,
		run.round,
		run.dealt,
		run.total,
		run.level,
		_world_rng,
		run.ended == "slain"
	)
	SaveStore.save(profile)
	if run.ended == "left":
		world_run = null
		_hud.toast("You left the fight. Damage banked.")
		return
	_show("world_boss", GameMenus.world_boss_result(self, run, paid))


## From the results back home, rested.
func _leave_world_boss() -> void:
	world_run = null
	profile.hp = profile.stats(content)["max_hp"]
	close_menu()
	enter_area(content.start_area, "")


## Straight home from the pause menu, out of a fight only. Arriving rests
## the hero (healed, every street's fights back) like walking in would; Win's
## taxi rides back out to any area reached.
func _recall() -> void:
	var problem := zone.recall_problem()
	if problem:
		_hud.toast(problem)
		Sfx.play("denied", -4.0)
		return
	close_menu()
	enter_area(content.start_area, "")
	_hud.toast("Back at %s. Rested, and the streets fill up again." % zone.area["name"])


func _save_game() -> void:
	_hud.toast("Saved" if SaveStore.save(profile) else "Save failed")
	close_menu()


func _quit_to_title() -> void:
	SaveStore.save(profile)
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")


## The world boss on the HUD: the attempt's clock while one runs, and a
## toast once when a round opens.
func _update_world_boss(delta: float) -> void:
	if world_run:
		_hud.show_world_boss(
			(
				"WORLD BOSS  %d:%02d  ·  %d%% left"
				% [
					world_run.seconds_left() / 60,
					world_run.seconds_left() % 60,
					roundi(world_run.remaining_share() * 100)
				]
			)
		)
		return
	_hud.show_world_boss("")
	_clock_timer -= delta
	if _clock_timer > 0.0:
		return
	_clock_timer = 1.0
	for boss: String in content.world_bosses:
		var round := WorldBossRules.window(content, boss, _now())
		if not round["open"] or not WorldBossRules.unlocked(profile, content, boss):
			continue
		if int(round["round"]) != int(_announced.get(boss, -1)):
			_announced[boss] = int(round["round"])
			var name := str(content.enemy(str(content.world_bosses[boss]["enemy"]))["name"])
			_hud.toast("World Boss: %s is out! Ask Win for a ride." % name)


func _process(delta: float) -> void:
	if auto:
		_hud.show_auto(auto, auto.on or auto.problem() == "")
	_update_world_boss(delta)
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
				"auto": auto.on,
				"auto_status": auto.pilot.status if auto.on else "",
			}
		)
	)
