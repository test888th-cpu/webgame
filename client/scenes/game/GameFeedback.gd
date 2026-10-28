class_name GameFeedback
extends RefCounted
## Turns zone events into what the player sees and hears: hit sparks, impact
## flashes and freezes, dust, skill effects, screen shake, sounds, the hurt
## vignette and the level-up banner. Presentation only: it reads events and
## never changes game state.

## Damage at or above this reads as a heavy hit.
const HEAVY_DAMAGE := 15
## Hit sparks appear at chest height.
const CHEST := Vector2(0, -26)
## Recorded punches (art/sounds/sounds.json), one picked at random per blow
## so a combo does not repeat the same sound.
const PUNCHES: Array[String] = [
	"punch_hit",
	"punch_hit_2",
	"punch_hit_3",
	"punch_hit_4",
	"punch_hit_5",
	"punch_hit_6",
	"punch_hit_7",
	"punch_hit_8",
	"punch_hit_9",
	"punch_hit_10",
]

var content: ContentDB
var view: ZoneView
var hud: Node
## Hazards on screen, oldest first, matched to ZoneSim's by order.
var _drops: Array[HazardView] = []


func _init(p_content: ContentDB, p_hud: Node) -> void:
	content = p_content
	hud = p_hud


func on_event(event: ZoneEvent) -> void:
	match event.type:
		"hit":
			_on_hit(event.hit)
		"swing":
			_on_swing(event.data)
		"dodge":
			_dust(event.data["id"])
			Sfx.play("dodge", -4.0)
		"pickup":
			Sfx.play("coin" if event.data["kind"] == "money" else "pickup", -3.0)
		"level_up":
			level_up(event.data["level"], event.data.get("skills", []))
		"quest_complete":
			Sfx.play("quest")
		"encounter_start":
			Sfx.play("arena_lock", -2.0)
			if event.data.get("boss", false):
				Sfx.play_later("boss_roar", 0.4)
		"boss_phase":
			Sfx.play("boss_roar")
			view.shake(4.0)
		"boss_summon":
			Sfx.play("arena_lock", -4.0)
		"boss_shield":
			_show_shield(int(event.data["id"]), bool(event.data["up"]))
		"hero_down":
			Sfx.play("ko")
		"weapon_eyed":
			# A boss has set off for a weapon: "!" over its head, so the hero
			# can race it there or get in the way.
			var boss := view.zone.fighter(int(event.data["id"]))
			if boss:
				view.show_text("!", boss.position + Vector2(16, -16), UiTheme.GOLD)
				Sfx.play("ui_select", -4.0, 0.0, 0.8)
		"weapon_pickup":
			Sfx.play("weapon_grab", -3.0)
			_boss_armed(event)
		"weapon_throw":
			Sfx.play("swing_heavy", -2.0, 0.06, 0.8)
		"weapon_drop":
			Sfx.play_later("weapon_drop", 0.12, -4.0)
		"weapon_break":
			Sfx.play("break_" + str(event.data["material"]), -2.0)
			Fx.spawn(view.effects, content, "dust", event.data["at"] + CHEST)
		"hazard_warn":
			var drop := HazardView.new()
			drop.position = event.data["at"]
			drop.setup(
				float(event.data["ticks"]) / CombatRules.TICK_RATE,
				str(event.data.get("kind", "crane")),
				event.data.get("half", Vector2(30, 10))
			)
			view.effects.add_child(drop)
			_drops.append(drop)
			Sfx.play("denied", -6.0)
		"hazard_hit":
			_drops = _drops.filter(func(d: HazardView) -> bool: return is_instance_valid(d))
			if not _drops.is_empty():
				_drops.pop_front().land()
			var sound := {"steam": "dodge", "laser": "swing_heavy"}
			Sfx.play(sound.get(event.data.get("kind"), "break_metal"), 0.0)
			Fx.spawn(view.effects, content, "dust", event.data["at"])
			view.shake(6.0)


## Raises or drops the shield dome on fighter `id`'s view.
func _show_shield(id: int, up: bool) -> void:
	var fighter_view := view.view_of(id)
	if fighter_view == null:
		return
	var dome := fighter_view.get_node_or_null("Shield")
	if up and dome == null:
		dome = ShieldView.new()
		dome.name = "Shield"
		fighter_view.add_child(dome)
		Sfx.play("arena_lock", -2.0)
	elif not up and dome:
		dome.queue_free()
		Sfx.play("break_metal", -4.0)


func level_up(level: int, skills: Array) -> void:
	var hero := view.view_of(ZoneSim.HERO_ID)
	if hero:
		Fx.spawn(hero, content, "levelup", Vector2.ZERO)
	Sfx.play("level_up")
	hud.level_up(level, skills)


func healed() -> void:
	var hero := view.view_of(ZoneSim.HERO_ID)
	if hero:
		Fx.spawn(hero, content, "heal", Vector2.ZERO)
	Sfx.play("heal", -2.0)


func _on_hit(hit: CombatEvent) -> void:
	var attacker := view.view_of(hit.attacker_id)
	var defender := view.view_of(hit.defender_id)
	var heavy := hit.knocked_down or hit.ko or hit.damage >= HEAVY_DAMAGE
	# Sparks sit between the two fighters, on the side the blow came from.
	var side := 1.0
	if attacker and defender:
		side = signf(attacker.position.x - defender.position.x)
	var at := hit.position + CHEST + Vector2(side * 6.0, 0)
	if hit.parried:
		# A crisp, bright clang and a beat of freeze on both fighters, so the
		# timing that earned it registers.
		Fx.spawn(view.effects, content, "block", at, side < 0)
		Fx.spawn(view.effects, content, "hit", at)
		Sfx.play("hit_block", 0.0, 0.02, 1.45)
		if defender:
			defender.impact(Color(0.6, 1.0, 1.0), 0.15, 0.1)
		if attacker:
			attacker.impact(Color.WHITE, 0.0, 0.1)
		return
	if hit.blocked:
		Sfx.play("guard_break" if hit.guard_broken else "hit_block", -2.0)
	else:
		Fx.spawn(view.effects, content, "hit_heavy" if heavy else "hit", at)
		_impact_sound(hit, heavy)
	var freeze := 0.09 if heavy else 0.05
	if defender:
		var hero_hit := hit.defender_id == ZoneSim.HERO_ID
		var color := Color(1, 0.25, 0.2) if hero_hit else Color.WHITE
		defender.impact(color, 0.12, 0.0 if hit.blocked else freeze)
		if hero_hit and not hit.blocked:
			Sfx.play("hero_hurt", -3.0)
			hud.hurt(1.5 if heavy else 1.0)
	if attacker and not hit.blocked:
		attacker.impact(Color.WHITE, 0.0, freeze)
	if hit.broken:
		# A boss beaten off its feet: rare, so it lands hard.
		view.shake(5.0)
		view.show_text("BREAK!", hit.position, UiTheme.GOLD)
	if hit.knocked_down or hit.ko:
		Sfx.play_later("knockdown", 0.18, -2.0)
		_dust(hit.defender_id, 0.2)
	if hit.ko and hit.defender_id != ZoneSim.HERO_ID:
		Sfx.play("ko", -4.0)


## Fists and feet land with a recorded punch (lower and backed by a thump
## when heavy); weapons keep their own synthesised impacts.
func _impact_sound(hit: CombatEvent, heavy: bool) -> void:
	var attacker := view.zone.fighter(hit.attacker_id)
	var armed := attacker != null and attacker.weapon != ""
	if armed:
		Sfx.play("hit_heavy" if heavy else "hit_light")
		return
	Sfx.play(PUNCHES.pick_random(), -1.0 if heavy else -3.0, 0.08, 0.86 if heavy else 1.0)
	if heavy:
		Sfx.play("hit_heavy", -8.0)


## A skill gets its effect on its first active tick and its own sound; plain
## attacks just whoosh (quieter for enemies, so the hero's blows stand out).
func _on_swing(data: Dictionary) -> void:
	var fighter := view.zone.fighter(data["id"])
	var fighter_view := view.view_of(data["id"])
	if fighter == null or fighter_view == null:
		return
	var skill_id: String = data["skill"]
	if skill_id == "":
		var move := content.moves.get_move(data["move"])
		var hero: bool = data["id"] == ZoneSim.HERO_ID
		var big := move.anim == "heavy" or move.knockdown
		var sound := "swing_heavy" if big else "swing_light"
		Sfx.play(sound, -6.0 if hero else -12.0)
		return
	var skill: Dictionary = content.skills[skill_id]
	Sfx.play(str(skill["sound"]))
	var delay := fighter.move.startup * CombatRules.TICK_SECONDS
	var flip := fighter.facing < 0
	var effect := str(skill["fx"])
	match effect:
		"rush":
			# The trail follows the hero through the charge.
			Fx.spawn(fighter_view, content, effect, Vector2(0, -10), flip)
		"uppercut":
			_later(delay, fighter_view, effect, Vector2(fighter.facing * 18.0, 0), flip)
		_:
			_later(delay, fighter_view, effect, Vector2.ZERO, flip)
	if effect == "slam":
		view.get_tree().create_timer(delay).timeout.connect(view.shake.bind(7.0))
		_dust(data["id"], delay)


func _later(seconds: float, parent: Node2D, effect: String, at: Vector2, flip: bool) -> void:
	# By id: the view may be gone (area change) before the timer fires.
	var parent_id := parent.get_instance_id()
	parent.get_tree().create_timer(seconds).timeout.connect(
		func() -> void:
			var target := instance_from_id(parent_id) as Node2D
			if target and target.is_inside_tree():
				Fx.spawn(target, content, effect, at, flip)
	)


func _dust(fighter_id: int, delay := 0.0) -> void:
	var fighter_view := view.view_of(fighter_id)
	if fighter_view == null:
		return
	if delay <= 0.0:
		Fx.spawn(view.effects, content, "dust", fighter_view.position)
		return
	_later_world(delay, fighter_id)


func _later_world(seconds: float, fighter_id: int) -> void:
	var view_id := view.get_instance_id()
	view.get_tree().create_timer(seconds).timeout.connect(
		func() -> void:
			var zone_view := instance_from_id(view_id) as ZoneView
			var fighter_view := zone_view.view_of(fighter_id) if zone_view else null
			if fighter_view:
				Fx.spawn(zone_view.effects, content, "dust", fighter_view.position)
	)


## A boss that picked up a weapon shows what it now swings.
func _boss_armed(event: ZoneEvent) -> void:
	var boss := view.zone.fighter(int(event.data["id"]))
	if boss == null or not content.enemy(boss.kind).get("boss", false):
		return
	var weapon: Dictionary = content.weapons.get(str(event.data["weapon"]), {})
	view.show_text(str(weapon.get("name", "")) + "!", boss.position, UiTheme.DANGER)
