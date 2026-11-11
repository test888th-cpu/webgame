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

## Skill effects that travel with the fighter (a charge's trail, a spin
## around the body). Every other skill effect is left in the world where the
## blow lands, and a ground effect (a slam's crack) on the street under the
## fighters: it does not slide along after them.
const FOLLOWS: Array[String] = ["rush", "whirlwind"]
const GROUND: Array[String] = ["slam"]
## A wide hazard's landing effect plays every FIELD_GAP px across a shocked
## field and every LASER_GAP px along a laser, within LASER_SPAN of the hero
## (what is on screen), MAX_SPOTS at most.
const FIELD_GAP := 36.0
const LASER_GAP := 90.0
const LASER_SPAN := 360.0
const MAX_SPOTS := 9
## An effect is drawn the width of what it hits (fit): never under MIN_FIT or
## over MAX_FIT of its art, so a small jab still shows and nothing balloons.
const MIN_FIT := 0.3
const MAX_FIT := 1.5

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
			# Quiet and short: coins are picked up all the time.
			if event.data["kind"] == "money":
				Sfx.play("coin", -8.0, 0.08)
			else:
				Sfx.play("pickup", -6.0)
				hud.pickups.add(content, str(event.data["item"]), int(event.data.get("amount", 1)))
		"level_up":
			level_up(event.data["level"], event.data.get("skills", []))
		"quest_complete":
			Sfx.play("quest")
		"encounter_clear":
			_gate_progress()
		"encounter_start":
			if view.zone.fight_locked():
				Sfx.play("arena_lock", -2.0)
			if event.data.get("boss", false):
				Sfx.play_later("boss_roar", 0.4)
		"boss_phase":
			Sfx.play("boss_roar")
			view.shake(4.0)
			_phase_burst(int(event.data["id"]))
		"spawn":
			_arrival(event.data)
		"boss_summon":
			Sfx.play("arena_lock", -4.0)
			for id: Variant in event.data.get("ids", []):
				var called := view.zone.fighter(int(id))
				if called:
					Fx.spawn(
						view.effects,
						content,
						BossFxRules.effect(content, "summon"),
						called.position
					)
		"defeat":
			if event.data.get("boss", false):
				_boss_down(int(event.data["id"]))
		"boss_shield":
			_show_shield(int(event.data["id"]), bool(event.data["up"]))
		"boss_enrage_warn", "boss_enrage":
			_enrage(event)
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
			var at: Vector2 = event.data["at"]
			var road := view.zone.bounds
			drop.lane = Vector2(road.position.y - at.y, road.end.y - at.y)
			# Read-only: the zone's entry for this drop (same spot, kind and
			# ticks left), whose countdown the warning follows.
			for entry: Dictionary in view.zone.hazards:
				var same: bool = entry["at"] == at and str(entry["kind"]) == drop.kind
				if same and absi(int(entry["ticks"]) - int(event.data["ticks"])) <= 1:
					drop.source = entry
					break
			# How loudly it warns: an Ultimate's waves in full, others minimal
			# (boss_fx.json "telegraph"; presentation only).
			var from := str(drop.source.get("from", ""))
			var levels: Dictionary = content.boss_fx.get("telegraph", {})
			var ultimate := (
				from != "" and BossSkillRules.is_ultimate(BossSkillRules.skill(content, from))
			)
			var source_key := "ultimate" if ultimate else ("skill" if from != "" else "cycle")
			var per_skill: Dictionary = levels.get("skills", {})
			drop.level = str(per_skill.get(from, levels.get(source_key, "full")))
			var caller := view.zone.fighter(view.zone.boss_id)
			if caller:
				drop.theme = str(content.boss_fx.get("bosses", {}).get(caller.kind, "brawl"))
			# On the street, under the fighters (its falling parts draw above).
			view.ground.add_child(drop)
			_drops.append(drop)
			Sfx.play("hazard_warn", -8.0)
		"hazard_hit":
			_drops = _drops.filter(func(d: HazardView) -> bool: return is_instance_valid(d))
			var half := Vector2(30, 10)
			if not _drops.is_empty():
				var landed: HazardView = _drops.pop_front()
				half = landed.half
				landed.land()
			var sound := {
				"steam": "steam_hiss",
				"sludge": "steam_hiss",
				"shock": "zap",
				"laser": "laser_beam",
				"quake": "break_metal",
				"rain": "break_metal",
			}
			Sfx.play(sound.get(event.data.get("kind"), "break_metal"), -2.0)
			if event.data.get("kind", "crane") in ["crane", "quake"]:
				# A container hitting the street: the ground shakes.
				view.shake(4.0)
			var kind := str(event.data.get("kind", "crane"))
			var landing := BossFxRules.hazard(content, kind)
			var spots := hazard_spots(kind, event.data["at"], half)
			var effect := landing if landing else "dust"
			# One burst the width of the marked area, or one per FIELD_GAP.
			var each := 2.0 * half.x if spots.size() == 1 else FIELD_GAP * 1.5
			for spot in spots:
				Fx.spawn(view.effects, content, effect, spot, false, fit(content, effect, each))
			view.shake(6.0)


## Every fight here won but the way on still shut (StreetMemory.gate): say
## what opens it and how far along it is, so the player knows why the street
## fills up again instead of letting them through.
func _gate_progress() -> void:
	var zone := view.zone
	if zone.in_encounter():
		return
	# Read only: StreetMemory.pending would refill the fights as it looks.
	for i in zone.area.get("encounters", []).size():
		if not StreetMemory.is_cleared(zone.profile, zone.area_id, i):
			return
	var gate := zone.exit_locked("east")
	if not gate.is_empty():
		hud.toast("%s  (%d/%d)" % [gate["hint"], int(gate["done"]), int(gate["count"])])


## A boss falls: the arena goes up in a blast and the screen shakes.
func _boss_down(id: int) -> void:
	var boss := view.zone.fighter(id)
	if boss == null:
		return
	Fx.spawn(view.effects, content, BossFxRules.effect(content, "defeat"), boss.position)
	view.shake(8.0)
	Sfx.play("break_metal", 0.0, 0.0, 0.6)


## An elite (FarmSpawner) arrives in a burst of gold light, a boss in a
## slam; anyone else just fades in (ZoneView), with no smoke.
func _arrival(data: Dictionary) -> void:
	var fighter := view.zone.fighter(int(data["id"]))
	if fighter == null:
		return
	if data.get("elite", false):
		Fx.spawn(view.effects, content, "elite_flare", fighter.position)
		Sfx.play("elite_arrive", -6.0)
	elif data.get("boss", false):
		Fx.spawn(view.effects, content, "boss_land", fighter.position)


## A boss entering a new phase flares red and throws out a shockwave, so the
## change in its pattern is seen as well as heard.
func _phase_burst(id: int) -> void:
	var boss := view.zone.fighter(id)
	if boss == null:
		return
	Fx.spawn(view.effects, content, "phase_burst", boss.position + CHEST)
	var boss_view := view.view_of(id)
	if boss_view:
		boss_view.impact(Color(1.0, 0.35, 0.25), 0.35, 0.12)


## Raises or drops the shield dome on fighter `id`'s view.
func _show_shield(id: int, up: bool) -> void:
	var fighter_view := view.view_of(id)
	if fighter_view == null:
		return
	var dome := fighter_view.get_node_or_null("ShieldDome")
	if up and dome == null:
		dome = Fx.spawn(fighter_view, content, BossFxRules.effect(content, "shield"), Vector2.ZERO)
		dome.name = "ShieldDome"
		Sfx.play("arena_lock", -2.0)
	elif not up and dome:
		dome.queue_free()
		var at := fighter_view.position + CHEST
		Fx.spawn(view.effects, content, BossFxRules.effect(content, "shield_break"), at)
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
		Fx.spawn(view.effects, content, "parry", at, side < 0)
		Sfx.play("hit_block", 0.0, 0.02, 1.45)
		if defender:
			defender.impact(Color(0.6, 1.0, 1.0), 0.15, 0.1)
		if attacker:
			attacker.impact(Color.WHITE, 0.0, 0.1)
		return
	if hit.blocked:
		Sfx.play("guard_break" if hit.guard_broken else "hit_block", -2.0)
		Fx.spawn(view.effects, content, "block", at, side < 0)
	else:
		var spark := "crit" if hit.critical else ("hit_heavy" if heavy else "hit")
		Fx.spawn(view.effects, content, spark, at, side < 0)
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
	var striker := view.zone.fighter(hit.attacker_id)
	var boss_blow: bool = striker != null and content.enemy(striker.kind).get("boss", false)
	if boss_blow and heavy and not hit.blocked and defender:
		# A boss's heavy blow lands with a burst of debris at the target's feet.
		var impact := BossFxRules.effect(content, "heavy_impact")
		var wide := fit(content, impact, hit_width(striker.move)) if striker.move else 1.0
		Fx.spawn(view.effects, content, impact, defender.position, false, wide)
		view.shake(3.0)
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
		if big and content.enemy(fighter.kind).get("boss", false):
			# A boss's heavy blow is telegraphed: its theme's glow gathers on it
			# through the wind-up, so the player can see it coming.
			var glow := BossFxRules.windup(content, fighter.kind)
			if glow:
				Fx.spawn(fighter_view, content, glow, CHEST, fighter.facing < 0)
		return
	var boss_skill := BossSkillRules.skill(content, skill_id)
	var skill: Dictionary = boss_skill if boss_skill else content.skills[skill_id]
	Sfx.play(str(skill["sound"]))
	var delay := fighter.move.startup * CombatRules.TICK_SECONDS
	var flip := fighter.facing < 0
	var effect := str(skill["fx"])
	if boss_skill:
		# A boss's skill gathers its theme's glow through the whole wind-up (a
		# cast's hazard is then warned on the ground, HazardView).
		var glow := BossFxRules.windup(content, fighter.kind)
		if glow:
			Fx.spawn(fighter_view, content, glow, CHEST, flip)
		if BossSkillRules.is_ultimate(boss_skill):
			# An Ultimate is called out: its name, a burst and the street shaking
			# through its long wind-up, before its waves are marked on the ground.
			hud.toast("ULTIMATE: %s" % str(boss_skill["name"]).to_upper())
			Fx.spawn(view.effects, content, effect, fighter.position + CHEST)
			view.shake(4.0)
			return
		if effect == "":
			return
	# As wide as the blow reaches (the owner's report: a skill that hit two
	# cells looked like four); under a scaled body, undo the body's scale.
	var size := fit(content, effect, hit_width(fighter.move))
	var body := size / maxf(fighter_view.scale.x, 0.01)
	if effect == "rush":
		# The trail follows the hero through the charge.
		Fx.spawn(fighter_view, content, effect, Vector2(0, -10), flip, body)
	elif effect in FOLLOWS:
		_later(delay, fighter_view, effect, Vector2.ZERO, flip, body)
	else:
		# Where the blow lands: an uppercut's arc rises just ahead, a strike's
		# burst at chest height in front; a ground effect under the fighter.
		var ahead := Vector2.ZERO
		if boss_skill:
			# A boss's blow lands on the middle of its hitbox, where it hits.
			var middle := fighter.move.reach_offset + fighter.move.reach / 2.0
			ahead = Vector2(fighter.facing * middle, 0.0 if effect in GROUND else CHEST.y)
		elif effect == "uppercut":
			ahead = Vector2(fighter.facing * 18.0, 0)
		elif effect not in GROUND:
			ahead = CHEST + Vector2(fighter.facing * 16.0, 0)
		_landed(delay, int(data["id"]), effect, ahead, flip, size)
	if effect == "slam":
		view.get_tree().create_timer(delay).timeout.connect(view.shake.bind(7.0))
		_dust(data["id"], delay)


## How wide `move` strikes: its reach plus the body it can catch at either end.
static func hit_width(move: MoveData) -> float:
	return move.reach + 2.0 * CombatRules.HURT_HALF_WIDTH


## The size to draw `effect` at so its art spans `span` px (MIN_FIT..MAX_FIT).
static func fit(content: ContentDB, effect: String, span: float) -> float:
	var art: Dictionary = content.fx.get("effects", {}).get(effect, {})
	var width := float(art.get("size", [span, 0])[0])
	return clampf(span / maxf(width, 1.0), MIN_FIT, MAX_FIT)


func _later(
	seconds: float, parent: Node2D, effect: String, at: Vector2, flip: bool, size := 1.0
) -> void:
	# By id: the view may be gone (area change) before the timer fires.
	var parent_id := parent.get_instance_id()
	parent.get_tree().create_timer(seconds).timeout.connect(
		func() -> void:
			var target := instance_from_id(parent_id) as Node2D
			if target and target.is_inside_tree():
				Fx.spawn(target, content, effect, at, flip, size)
	)


## Plays `effect` after `seconds` where fighter `fighter_id` then stands
## (plus `offset`), in the world: on the street for a GROUND effect, else
## over it. It stays there.
func _landed(
	seconds: float, fighter_id: int, effect: String, offset: Vector2, flip: bool, size := 1.0
) -> void:
	var view_id := view.get_instance_id()
	view.get_tree().create_timer(seconds).timeout.connect(
		func() -> void:
			var zone_view := instance_from_id(view_id) as ZoneView
			var fighter_view := zone_view.view_of(fighter_id) if zone_view else null
			if fighter_view == null:
				return
			var layer := zone_view.ground if effect in GROUND else zone_view.effects
			Fx.spawn(layer, content, effect, fighter_view.position + offset, flip, size)
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


## A boss's fight timer (BossEnrage): a warning a few seconds ahead, then the
## enrage itself, said on the HUD so the player knows why it hits harder.
func _enrage(event: ZoneEvent) -> void:
	var boss := view.zone.fighter(int(event.data["id"]))
	var boss_name := str(content.enemy(boss.kind)["name"]) if boss else "The boss"
	if event.type == "boss_enrage_warn":
		hud.toast("%s will enrage in %d seconds!" % [boss_name, int(event.data["seconds"])])
		Sfx.play("ui_select", -4.0, 0.0, 0.7)
		return
	hud.toast("%s is enraged: harder blows, faster hazards!" % boss_name)
	Sfx.play("boss_roar")
	view.shake(5.0)
	if boss:
		view.show_text("ENRAGED", boss.position + Vector2(0, -40), UiTheme.GOLD)


## Where a landing hazard's effect plays: across its whole footprint, so a
## wide one reads as one big strike, not a burst in its middle: lightning all
## over a shocked field, sparks all along a laser beam (the stretch on screen
## around the hero), one burst for anything narrow.
static func hazard_spots(kind: String, at: Vector2, half: Vector2) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	var reach := minf(half.x, LASER_SPAN) if kind == "laser" else half.x
	var gap := LASER_GAP if kind == "laser" else FIELD_GAP
	var count := clampi(floori(reach * 2.0 / gap) + 1, 1, MAX_SPOTS)
	if kind not in ["shock", "laser"] or count <= 1:
		return [at] as Array[Vector2]
	for i in count:
		var x := -reach + reach * 2.0 * i / (count - 1)
		var dy := 0.0 if kind == "laser" else half.y * (0.5 if i % 2 == 0 else -0.5)
		spots.append(at + Vector2(x, dy))
	return spots
