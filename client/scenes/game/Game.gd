extends Node2D
## The running game: owns the current zone simulation and its view, feeds the
## hero's input in at a fixed 60 ticks per second, reacts to zone events
## (damage numbers, rewards, area changes, defeat), and opens the menus
## (pause/inventory, shop, quests, game over). While a menu is open the
## simulation does not tick.

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

var _pending_exit := {}
var _probe_timer := 0.0

@onready var _world: Node2D = $World
@onready var _hud: CanvasLayer = $Hud
@onready var _menus: CanvasLayer = $Menus


func _ready() -> void:
	content = GameSession.content
	if GameSession.profile == null:
		GameSession.start_new_game()
	profile = GameSession.profile
	enter_area(profile.area, "")
	print("%s %s" % [READY_MARKER, BuildInfo.summary()])


func enter_area(area_id: String, entry: String) -> void:
	if view:
		_world.remove_child(view)
		view.queue_free()
	profile.area = area_id
	zone = ZoneSim.new(content, profile, area_id, entry, randi())
	view = ZoneView.new()
	_world.add_child(view)
	view.build(zone, content)
	view.update_npc_marks(profile)
	_hud.attach(zone, profile, content)
	_hud.toast(str(zone.area.get("name", area_id)))
	SaveStore.save(profile)


func _physics_process(_delta: float) -> void:
	if menu:
		if menu_name != "game_over" and Input.is_action_just_pressed("pause"):
			close_menu()
		return
	if Input.is_action_just_pressed("pause"):
		open_pause()
		return
	if Input.is_action_just_pressed("interact") and try_interact():
		return
	if Input.is_action_just_pressed("use_item"):
		quick_heal()
	step(PlayerInput.read())


## Advances the zone one tick with the given hero input.
func step(input: FighterInput) -> Array[ZoneEvent]:
	var events := zone.tick(input)
	for event in events:
		_handle(event)
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
		"level_up":
			_hud.toast("Level up! Lv %d" % event.data["level"])
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
				view.show_text(
					"+" + str(content.item(event.data["item"]).get("name")),
					zone.hero.position,
					Color(0.6, 1, 0.7)
				)
		"encounter_start":
			if event.data.get("boss", false):
				_hud.toast("A boss approaches!")
		"boss_phase":
			_hud.toast("It's enraged!")
		"hero_down":
			open_game_over.call_deferred()
		"exit":
			_pending_exit = event.data


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
			return true
	_hud.toast("Nothing to eat")
	return false


func close_menu() -> void:
	if menu:
		menu.queue_free()
	menu = null
	menu_name = ""
	zone.refresh_hero()
	view.update_npc_marks(profile)


func _show(name: String, parts: Array) -> void:
	if menu:
		menu.queue_free()
	menu = parts[0]
	menu_name = name
	_menus.add_child(menu)
	UiKit.focus_first(menu)


func open_pause() -> void:
	var parts := UiKit.panel("Paused")
	var list: VBoxContainer = parts[1]
	var stats := profile.stats(content)
	(
		list
		. add_child(
			(
				UiKit
				. label(
					(
						"Lv %d   XP %d/%d   HP %d/%d   Coins %d\nPower x%.2f   Defense %d"
						% [
							profile.level,
							profile.xp,
							profile.xp_to_next(content),
							zone.hero.hp,
							zone.hero.max_hp,
							profile.money,
							stats["power"],
							stats["defense"],
						]
					)
				)
			)
		)
	)
	list.add_child(UiKit.button("Resume", close_menu))
	list.add_child(UiKit.button("Inventory", open_inventory))
	list.add_child(UiKit.button("Quests", open_quest_log))
	list.add_child(UiKit.button("Save game", _save_game))
	list.add_child(UiKit.button("Quit to title", _quit_to_title))
	_show("pause", parts)


func open_inventory() -> void:
	var parts := UiKit.panel("Inventory", 340)
	var list: VBoxContainer = parts[1]
	for slot: String in PlayerProfile.SLOTS:
		var equipped: String = profile.equipment[slot]
		var text := "%s: %s" % [slot.capitalize(), content.item(equipped).get("name", "-")]
		var action := UiKit.button("Unequip", _unequip.bind(slot), not equipped)
		list.add_child(UiKit.row(text, action))
	if profile.inventory.is_empty():
		list.add_child(UiKit.label("Your bag is empty.", 9, Color(0.7, 0.7, 0.75)))
	for item_id: String in profile.inventory:
		var item := content.item(item_id)
		var text := (
			"%s x%d  -  %s" % [item["name"], profile.count(item_id), item.get("description", "")]
		)
		var action: Button
		if item["type"] == "consumable":
			action = UiKit.button("Use", _use.bind(item_id))
		else:
			action = UiKit.button("Equip", _equip.bind(item_id))
		list.add_child(UiKit.row(text, action))
	list.add_child(UiKit.button("Back", open_pause))
	_show("inventory", parts)


func open_quest_log() -> void:
	var parts := UiKit.panel("Quests", 340)
	var list: VBoxContainer = parts[1]
	var any := false
	for quest_id: String in profile.quests:
		any = true
		list.add_child(UiKit.label(_quest_line(quest_id)))
	if not any:
		list.add_child(
			UiKit.label(
				"No quests yet. Chief Odo in Depot Yard has work.", 9, Color(0.7, 0.7, 0.75)
			)
		)
	list.add_child(UiKit.button("Back", open_pause))
	_show("quests", parts)


func open_shop(npc: Dictionary) -> void:
	var shop: Dictionary = content.shops[npc["shop"]]
	var parts := UiKit.panel(str(shop["name"]), 340)
	var list: VBoxContainer = parts[1]
	list.add_child(
		UiKit.label('%s: "%s"' % [npc["name"], npc.get("line", "")], 9, Color(0.8, 0.8, 0.9))
	)
	list.add_child(UiKit.label("Coins: %d" % profile.money, 10, Color(1, 0.85, 0.3)))
	for item_id: String in shop["items"]:
		var item := content.item(item_id)
		var price := int(item["price"])
		var text := (
			"%s (%d)  -  %s  [own %d]"
			% [item["name"], price, item.get("description", ""), profile.count(item_id)]
		)
		list.add_child(
			UiKit.row(text, UiKit.button("Buy", _buy.bind(npc, item_id), profile.money < price))
		)
	list.add_child(UiKit.button("Leave", close_menu))
	_show("shop", parts)


func open_quests(npc: Dictionary) -> void:
	var parts := UiKit.panel(str(npc["name"]), 340)
	var list: VBoxContainer = parts[1]
	list.add_child(UiKit.label('"%s"' % npc.get("line", ""), 9, Color(0.8, 0.8, 0.9)))
	for quest_id in view.quests_of(npc):
		var state := QuestRules.status(profile, quest_id, content)
		if state == "locked":
			continue
		var quest: Dictionary = content.quests[quest_id]
		list.add_child(UiKit.label(_quest_line(quest_id), 9))
		if state == "available":
			list.add_child(UiKit.label(str(quest["description"]), 8, Color(0.75, 0.75, 0.8)))
			list.add_child(
				UiKit.button("Accept: " + str(quest["name"]), _accept.bind(npc, quest_id))
			)
		elif state == "complete":
			list.add_child(
				UiKit.button("Hand in: " + str(quest["name"]), _turn_in.bind(npc, quest_id))
			)
	list.add_child(UiKit.button("Goodbye", close_menu))
	_show("quests_npc", parts)


func open_game_over() -> void:
	var loss := int(profile.money * float(content.progression.get("defeat_money_loss", 0.0)))
	var parts := UiKit.panel("Knocked out")
	var list: VBoxContainer = parts[1]
	list.add_child(UiKit.label("The crew drags you back to the depot."))
	var start_name := str(content.area(content.start_area).get("name", "home"))
	list.add_child(
		UiKit.button("Return to %s (lose %d coins)" % [start_name, loss], _recover.bind(loss))
	)
	_show("game_over", parts)


func _quest_line(quest_id: String) -> String:
	var quest: Dictionary = content.quests[quest_id]
	var state := QuestRules.status(profile, quest_id, content)
	var count := int(quest["objective"]["count"])
	match state:
		"active":
			return "%s  (%d/%d)" % [quest["name"], profile.quests[quest_id]["progress"], count]
		"complete":
			return "%s  - ready to hand in" % quest["name"]
		"turned_in":
			return "%s  - done" % quest["name"]
	return str(quest["name"])


func _use(item_id: String) -> void:
	if not zone.use_item(item_id):
		_hud.toast("No effect right now")
	open_inventory()


func _equip(item_id: String) -> void:
	profile.equip(item_id, content)
	zone.refresh_hero()
	open_inventory()


func _unequip(slot: String) -> void:
	profile.unequip(slot, content)
	zone.refresh_hero()
	open_inventory()


func _buy(npc: Dictionary, item_id: String) -> void:
	var error := ShopRules.buy(profile, npc["shop"], item_id, content)
	_hud.toast("Bought " + str(content.item(item_id)["name"]) if not error else "Not enough coins")
	SaveStore.save(profile)
	open_shop(npc)


func _accept(npc: Dictionary, quest_id: String) -> void:
	QuestRules.accept(profile, quest_id, content)
	_hud.toast("New quest: " + str(content.quests[quest_id]["name"]))
	SaveStore.save(profile)
	open_quests(npc)


func _turn_in(npc: Dictionary, quest_id: String) -> void:
	var rewards := QuestRules.turn_in(profile, quest_id, content)
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
	(
		GameSession
		. publish_probe(
			{
				"scene": "game",
				"area": zone.area_id,
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
			}
		)
	)
