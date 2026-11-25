class_name RpgEncounter
extends RefCounted
## The trial world: one reference-rules character and one reference monster on a line,
## stepped at World of ClaudeCraft's own rate (types.ts TICK_RATE 20, DT = 1/20) in
## Sim.tick's order (sim.ts:5941): projectiles; the player (casting, auto attack,
## regen every 40th tick, timers, auras); the monster (its engaged tick, auras); then
## who is in combat. Every action enters through command(): auto mode only picks
## commands, as AutoPilot presses the same inputs a player does (ARCHITECTURE.md D7).
##
## Positions are one axis (x). The player stands at 0; the monster starts at the
## chosen distance and, once engaged, pursues at its moveSpeed to its combat
## profile's reach (mob/combat_profile.ts updatePursuitProfileCombat). Adapted
## (docs/ADAPTATION_REGISTER.md): one axis, no terrain or line of sight, the player
## holds position, and the fight's start distance is the trial's choice.

const SILENT := "silent:"

var content: ContentDB
var pack: Dictionary
var state: Dictionary
var rng: RpgRng
var player: Dictionary
## Every monster in this world; `mob` is the player's current target (or {}).
var mobs: Array = []
var mob: Dictionary = {}
var monster_id: String
var dt := 0.05
var time := 0.0
var tick_count := 0
var projectiles: Array = []
## Ground areas in play (RpgGround).
var ground: Array = []
var events: Array[Dictionary] = []
var auto_mode := true
## "fighting", "victory" or "defeat".
var outcome := "fighting"
var reward := {}
## A production street: the fight does not end when one monster dies, and the player
## walks (RUN_SPEED) and chooses targets.
var zone_mode := false
## -1, 0 or 1: the player's held walking direction on the street axis.
var move_dir := 0
var bounds := Vector2(-INF, INF)
## A living street: a slain monster rises again at its spawn point (respawn_policy.ts
## resolveRespawnSeconds: the template's own respawnSeconds, else the world's
## TRASH_RESPAWN_SECONDS), and the street never ends in "victory".
var respawn := false
## The damage the player's last melee swing dealt (meleeSwing's onDealt).
var last_melee_dealt := 0
var _known: Array = []


## A fight against `p_monster` standing `start_distance` away.
static func start(
	p_content: ContentDB,
	p_pack: Dictionary,
	p_state: Dictionary,
	p_monster: String,
	p_rng: RpgRng,
	start_distance := -1.0
) -> RpgEncounter:
	var e := RpgEncounter.new()
	e.content = p_content
	e.pack = p_pack
	e.state = p_state
	e.rng = p_rng
	e.monster_id = p_monster
	e.dt = 1.0 / float(p_pack["constants"]["tick_rate"])
	e.player = RpgUnit.player(p_content, p_pack, p_state)
	restore_vitals(e.player, p_state)
	var m := RpgPack.monster(p_pack, p_monster)
	var level := p_rng.int_range(int(m["level_min"]), int(m["level_max"]))
	var dist := (
		start_distance if start_distance >= 0.0 else float(m["combat_profile"]["desiredRange"])
	)
	e.mob = RpgUnit.mob(p_pack, p_monster, level, dist)
	e.mobs = [e.mob]
	e._refresh_known()
	return e


## A street of monsters (production areas): each spawn is {monster, x}; levels by the
## camp spawner's rule (`rng.int(minLevel, maxLevel)`, sim.ts:2432). The player
## stands at `player_x` and has no target until one engages or is chosen.
static func start_zone(
	p_content: ContentDB,
	p_pack: Dictionary,
	p_state: Dictionary,
	spawns: Array,
	p_rng: RpgRng,
	player_x := 0.0
) -> RpgEncounter:
	var e := RpgEncounter.new()
	e.content = p_content
	e.pack = p_pack
	e.state = p_state
	e.rng = p_rng
	e.dt = 1.0 / float(p_pack["constants"]["tick_rate"])
	e.player = RpgUnit.player(p_content, p_pack, p_state)
	e.player["x"] = player_x
	restore_vitals(e.player, p_state)
	var next_id := 2
	for sp: Dictionary in spawns:
		var m := RpgPack.monster(p_pack, str(sp["monster"]))
		if m.is_empty():
			continue
		var level := p_rng.int_range(int(m["level_min"]), int(m["level_max"]))
		var u := RpgUnit.mob(p_pack, str(sp["monster"]), level, float(sp["x"]))
		u["home_x"] = float(sp["x"])
		u["respawn_in"] = 0.0
		u["id"] = next_id
		next_id += 1
		e.mobs.append(u)
	e.zone_mode = true
	e._refresh_known()
	return e


## Health and resource as saved (a new character has none saved: its recalc filled
## health and mana and left rage, energy and focus at 0).
static func restore_vitals(u: Dictionary, state: Dictionary) -> void:
	var v: Variant = state.get("vitals")
	if not (v is Dictionary):
		return
	u["dead"] = bool(v.get("dead", false))
	u["hp"] = clampi(int(v.get("hp", u["hp"])), 0, int(u["max_hp"]))
	if u["dead"]:
		u["hp"] = 0
	u["resource"] = clampf(float(v.get("resource", 0.0)), 0.0, float(u["max_resource"]))


## Whether this character can fight in the trial, and why not.
static func can_fight(pack: Dictionary, state: Dictionary) -> String:
	return "" if pack.get("classes", {}).has(str(state.get("class_id", ""))) else "unknown class"


func log_event(e: Dictionary) -> void:
	e["tick"] = tick_count
	events.append(e)


func unit(id: int) -> Dictionary:
	if id == int(player["id"]):
		return player
	for m: Dictionary in mobs:
		if int(m["id"]) == id:
			return m
	return {}


## Distance to the current target (INF with none).
func distance() -> float:
	return _distance_to(mob)


func _distance_to(m: Dictionary) -> float:
	if m.is_empty():
		return INF
	return absf(float(m["x"]) - float(player["x"]))


## The nearest living monster (for targeting), or {}.
func _nearest_mob(engaged_only := false) -> Dictionary:
	var best := {}
	for m: Dictionary in mobs:
		if m["dead"] or (engaged_only and not m["engaged"]):
			continue
		if best.is_empty() or _distance_to(m) < _distance_to(best):
			best = m
	return best


func _set_target(m: Dictionary) -> void:
	mob = m


func _refresh_known() -> void:
	_known = RpgTalents.known(pack, str(state["class_id"]), int(state["level"]), player["mods"])


## The resolved ability as castAbility reads it (ctx.resolvedAbility): the known
## entry with the cost tail (applyAbilityCostTail) and the class swaps applied.
func known_entry(ability_id: String) -> Dictionary:
	for k: Dictionary in _known:
		if k["id"] == ability_id:
			return RpgAbilityCost.resolve(self, k)
	return {}


func known() -> Array:
	return _known


func recalc_player() -> void:
	RpgUnit.recalc(content, pack, player, state)


## The character changed out of the engine's own tick (gear, spec, talents chosen on
## a menu): the talent modifiers, the recalcPlayerStats sheet and the known
## abilities follow at once, so the screens and the next swing read one unit.
func character_changed() -> void:
	var was := str(player.get("spec_id", ""))
	RpgUnit.set_talents(content, pack, player, state)
	if str(player["spec_id"]) != was and player["class_id"] == "rogue":
		RpgRogue.clean_engine_state(self, player)
	recalc_player()
	_refresh_known()


func player_mainhand_is_two_hand() -> bool:
	var item := RpgPack.item(pack, str(state["equipment"].get("mainhand", "")))
	return str(item.get("kind")) == "weapon" and str(item.get("hand")) == "twohand"


## effectivePlayerAttackRange against the trial's monster.
func player_attack_range(authored: float) -> float:
	var base := authored if authored > 0.0 else float(pack["constants"]["melee_range"])
	var edge := float(mob.get("body_edge", 0.0)) if not mob.is_empty() else 0.0
	if base <= float(pack["constants"]["melee_range"]) and edge > base:
		return edge
	return base


# -- commands ----------------------------------------------------------------------


## The one entry point for every action. Returns "" or the refusal ("silent:..." for
## the ones the reference makes without a message). Commands: {"op": "attack"},
## {"op": "stop"}, {"op": "cast", "ability": id}, {"op": "auto", "on": bool}.
func command(cmd: Dictionary) -> String:
	if outcome != "fighting":
		return "The fight is over."
	var why := ""
	match str(cmd.get("op", "")):
		"attack":
			why = _start_auto_attack()
		"stop":
			player["auto_attack"] = false
		"auto":
			auto_mode = bool(cmd.get("on", true))
		"cast":
			why = RpgCast.cast(self, str(cmd.get("ability", "")))
		"move":
			move_dir = clampi(int(cmd.get("dir", 0)), -1, 1)
		"target", "target_nearest":
			var t := (
				_nearest_mob() if cmd["op"] == "target_nearest" else unit(int(cmd.get("id", -1)))
			)
			if t.is_empty() or t["kind"] != "mob" or t["dead"]:
				why = "Invalid attack target."
			else:
				_set_target(t)
		_:
			why = "Unknown command."
	return why


## startAutoAttack: a melee start in reach pulls the monster at once; a ranged start
## pulls it when the shot lands.
func _start_auto_attack() -> String:
	if player["dead"]:
		return SILENT + "dead"
	if mob.is_empty():
		return "Invalid attack target."
	if mob["dead"]:
		return SILENT + "target dead"
	player["auto_attack"] = true
	var ranged := RpgWorld.ranged_profile(self)
	var d := distance()
	var ranged_fires: bool = (
		not ranged.is_empty()
		and d <= float(ranged["maxRange"])
		and d >= (0.0 if ranged.get("wand", false) else float(ranged.get("minRange", 0)))
	)
	if not ranged_fires and d <= player_attack_range(0.0) and player["casting"].is_empty():
		mob["engaged"] = true
	return ""


# -- the tick ----------------------------------------------------------------------


## One 20 Hz tick, in Sim.tick's order.
func step() -> void:
	if outcome != "fighting":
		return
	time += dt
	tick_count += 1
	if auto_mode:
		_auto()
	RpgGround.tick(self)
	_advance_projectiles()
	if not player["dead"]:
		RpgWarrior.ensure_stance(self, player)
		RpgMotion.update_player(self)
		RpgCast.update_casting(self)
		RpgAutoAttack.update(self)
		if tick_count % int(pack["constants"]["regen_every_ticks"]) == 0:
			_regen()
	_update_timers()
	RpgRogue.combo_expiry(self, player)
	RpgCombat.update_auras(self, player)
	var engaged := false
	if respawn:
		_respawn_tick()
		_decay_corpses()
	for m: Dictionary in mobs:
		if not m["dead"]:
			_update_mob(m)
			RpgCombat.update_auras(self, m)
			engaged = engaged or bool(m["engaged"])
	player["in_combat"] = engaged or float(player["combat_timer"]) < 5.0


## Auto-combat: keep the auto attack on and use every executable ability that is
## ready, in spellbook order. It only sends commands; a refusal is skipped.
func _auto() -> void:
	if player["dead"]:
		return
	if mob.is_empty() or mob["dead"]:
		# Auto chooses the nearest monster already fighting the player, else the
		# nearest one (an automation choice, docs/ADAPTATION_REGISTER.md PROD-AUTO).
		var pick := _nearest_mob(true)
		_set_target(pick if not pick.is_empty() else _nearest_mob())
		player["auto_attack"] = false
		if mob.is_empty():
			return
	if not player["auto_attack"]:
		command({"op": "attack"})
	if zone_mode:
		_auto_walk()
	for k: Dictionary in _known:
		if str(pack["abilities"][k["id"]]["status"]).begins_with("IMPLEMENTED"):
			if _auto_wants(k):
				command({"op": "cast", "ability": k["id"]})


## Auto walks to its target until it can attack it (melee reach, or the ranged auto
## attack's range) and stops there: a walking choice only, the same RUN_SPEED and the
## same commands a player gives (docs/ADAPTATION_REGISTER.md PROD-AUTO).
func _auto_walk() -> void:
	var reach := player_attack_range(0.0)
	var ranged := RpgWorld.ranged_profile(self)
	if not ranged.is_empty():
		reach = float(ranged["maxRange"])
	var gap := float(mob["x"]) - float(player["x"])
	var dir := 0 if absf(gap) <= reach * 0.9 else int(signf(gap))
	command({"op": "move", "dir": dir})


## Auto mode does not recast a buff it already holds or a heal at full health, and
## never switches a stance, form or stealth (a toggle the player chooses).
func _auto_wants(k: Dictionary) -> bool:
	var def: Dictionary = k["def"]
	if RpgAbilityRules.is_toggle_buff(self, def) or def.get("exclusiveGroup") != null:
		return false
	if def.get("onNextSwing", false) and str(player.get("queued_on_swing", "")) == k["id"]:
		return false
	for eff: Dictionary in k["effects"]:
		match str(eff["type"]):
			"selfBuff", "buffTarget", "absorb", "hot":
				for a: Dictionary in player["auras"]:
					if str(a["id"]).begins_with(str(k["id"])):
						return false
			"heal":
				if int(player["hp"]) >= int(player["max_hp"]):
					return false
			"dot", "stun", "incapacitate", "root", "slow":
				for a: Dictionary in mob["auras"]:
					if str(a["id"]).begins_with(str(k["id"])):
						return false
	return true


## updateTimers.
func _update_timers() -> void:
	player["gcd"] = maxf(0.0, float(player["gcd"]) - dt)
	player["five_second_rule"] = float(player["five_second_rule"]) + dt
	player["combat_timer"] = float(player["combat_timer"]) + dt
	for id: String in player["cooldowns"].keys():
		var v := float(player["cooldowns"][id]) - dt
		if v <= 0.0:
			player["cooldowns"].erase(id)
		else:
			player["cooldowns"][id] = v
	RpgAbilityRules.tick_charges(player, dt)


## updateRegen (every 2 s): mana by Spirit under the five-second rule, energy +20,
## focus +10, rage -2 out of combat; health Sta x 0.3 + 2 out of combat.
func _regen() -> void:
	# Lifesap (Innervate) restores the live bar unless hard control stills it; a
	# druid out of Cat Form regains the parked energy at the base tick.
	if not RpgCombat.is_stunned(player):
		for a: Dictionary in player["auras"]:
			if a["kind"] == "resource_sap":
				player["resource"] = minf(
					float(player["max_resource"]),
					float(player["resource"]) + RpgTalents.js_round(float(a["value"]))
				)
	if player["resource_type"] != "energy" and float(player.get("parked_energy_deficit", 0.0)) > 0:
		player["parked_energy_deficit"] = maxf(
			0.0, float(player["parked_energy_deficit"]) - RpgResources.ENERGY_PER_TICK
		)
	match str(player["resource_type"]):
		"mana":
			var regen := RpgResources.mana_regen_per_tick(
				float(player["stats"]["spi"]),
				int(player["level"]),
				float(player["five_second_rule"]),
				float(player["mods"]["global"]["manaRegenPct"])
			)
			player["resource"] = minf(
				float(player["max_resource"]), float(player["resource"]) + regen
			)
		"energy":
			var energy := float(RpgResources.ENERGY_PER_TICK)
			for a: Dictionary in player["auras"]:
				if a["kind"] == "buff_energyregen":
					energy *= 1.0 + float(a["value"])
			player["resource"] = minf(
				float(player["max_resource"]),
				float(player["resource"]) + RpgTalents.js_round(energy)
			)
		"focus":
			player["resource"] = minf(
				float(player["max_resource"]),
				float(player["resource"]) + RpgResources.FOCUS_PER_TICK
			)
		"rage":
			if not player["in_combat"]:
				player["resource"] = maxf(
					0.0, float(player["resource"]) - RpgResources.RAGE_DECAY_PER_TICK
				)
	if not player["in_combat"] and int(player["hp"]) < int(player["max_hp"]):
		var heal := RpgTalents.js_round(float(player["stats"]["sta"]) * 0.3 + 2.0)
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + int(heal))
	var second := float(player["mods"]["global"]["secondWindPctPerSec"])
	var below := float(player["max_hp"]) * float(pack["constants"]["second_wind_threshold"])
	if second > 0.0 and int(player["hp"]) > 0 and float(player["hp"]) < below:
		var mend := mini(
			int(RpgTalents.js_round(float(player["max_hp"]) * second * 2.0)),
			int(player["max_hp"]) - int(player["hp"])
		)
		if mend > 0:
			player["hp"] = int(player["hp"]) + mend
			log_event({"type": "heal", "target": player["id"], "amount": mend})


# -- the player's swings (RpgAutoAttack) ------------------------------------------------


## One player melee swing (meleeSwing). Returns whether it connected;
## last_melee_dealt holds what it dealt.
func player_melee(target: Dictionary, opts: Dictionary, ability_name: String) -> bool:
	return RpgAutoAttack.melee(self, target, opts, ability_name)


# -- projectiles (projectile_travel.ts) ----------------------------------------------


## A bolt from the player at the current target.
## `to` and `from_x` aim a bolt at another target from another point (a bounce).
func schedule_projectile(resolve: Callable, to := {}, from_x := NAN) -> void:
	var aim: Dictionary = mob if to.is_empty() else to
	if aim.is_empty():
		return
	(
		projectiles
		. append(
			{
				"x": float(player["x"]) if is_nan(from_x) else from_x,
				"target": int(aim["id"]),
				"ttl": float(pack["constants"]["projectile_max_flight"]),
				"resolve": resolve,
			}
		)
	)


## advancePendingProjectiles: each bolt flies PROJECTILE_SPEED x DT toward its own
## target; within reach it resolves; past its flight time it resolves anyway; a dead
## source or target fizzles it.
func _advance_projectiles() -> void:
	if projectiles.is_empty():
		return
	var step := float(pack["constants"]["projectile_speed"]) * dt
	var reach := float(pack["constants"]["projectile_reach"])
	var flying: Array = projectiles
	projectiles = []
	var still: Array = []
	for proj: Dictionary in flying:
		var tgt := unit(int(proj["target"]))
		if player["dead"] or tgt.is_empty() or tgt["dead"]:
			continue
		var dist := absf(float(tgt["x"]) - float(proj["x"]))
		if dist <= maxf(reach, step):
			proj["resolve"].call(player, tgt)
			continue
		proj["ttl"] = float(proj["ttl"]) - dt
		if float(proj["ttl"]) <= 0.0:
			proj["resolve"].call(player, tgt)
			continue
		proj["x"] = float(proj["x"]) + signf(float(tgt["x"]) - float(proj["x"])) * step
		still.append(proj)
	projectiles = still + projectiles


# -- the monsters (mob/combat_profile.ts, sim.ts mobSwing) --------------------------


## The engaged tick of a melee mob: a stunned mob does nothing (locomotion.ts:575);
## otherwise its swing timer runs, it swings if in reach, closes to its desired range
## unless rooted (at moveSpeed x chase mult x slows), and swings again on entering
## reach.
func _update_mob(m: Dictionary) -> void:
	if player["dead"]:
		return
	if RpgCombat.is_stunned(m):
		RpgMotion.controlled_mob(self, m)
		return
	if (
		m["engaged"]
		and (RpgRogue.has_escape_stealth(player) or RpgHunter.is_feigning_death(player))
	):
		m["engaged"] = false
	if m["engaged"]:
		var to_player := float(player["x"]) - float(m["x"])
		if absf(to_player) >= RpgAbilityRules.FACING_HOLD_DIST:
			m["facing"] = signf(to_player)
	if not m["engaged"]:
		_idle_aggro_scan(m)
		return
	var prof: Dictionary = m["profile"]
	m["prev_x"] = m["x"]
	m["swing_timer"] = maxf(0.0, float(m["swing_timer"]) - dt)
	if prof.get("swingWhilePursuing", false):
		_mob_try_swing(m)
	if _distance_to(m) > float(prof["desiredRange"]) and not RpgCombat.is_rooted(m):
		var speed := (
			float(m["move_speed"])
			* float(prof.get("chaseSpeedMult", 1.0))
			* RpgCombat.move_speed_mult(m)
		)
		var gap := float(m["x"]) - float(player["x"])
		m["x"] = float(m["x"]) - signf(gap) * minf(speed * dt, absf(gap))
	if prof.get("immediateSwingOnEnterRange", false) or prof.get("swingWhilePursuing", false):
		_mob_try_swing(m)


## The idle mob's proximity aggro (mob/locomotion.ts idle arm): radius = max(4,
## min(MAX_AGGRO_RADIUS, aggroRadius + (mob level - player level) x 1.5)); a player
## the mob finds trivial (TRIVIAL_LEVEL_GAP levels above it) is ignored.
func _idle_aggro_scan(m: Dictionary) -> void:
	var gap := int(player["level"]) - int(m["level"])
	if gap >= int(pack["constants"]["trivial_level_gap"]):
		return
	if RpgHunter.is_feigning_death(player) or RpgRogue.has_escape_stealth(player):
		return
	var radius := maxf(
		4.0,
		minf(
			float(pack["constants"]["max_aggro_radius"]),
			float(m["aggro_radius"]) + (int(m["level"]) - int(player["level"])) * 1.5
		)
	)
	if RpgStealth.is_stealthed(player):
		radius *= RpgRogue.detection_mult(int(m["level"]), int(player["level"]))
	if _distance_to(m) < radius:
		m["engaged"] = true


## tryMobMeleeSwingInRange: within reach (+ the moving bonus when it moved) and the
## timer done, a swing, and the timer resets to its weapon speed.
func _mob_try_swing(m: Dictionary) -> void:
	if player["dead"] or m["dead"]:
		return
	var prof: Dictionary = m["profile"]
	var moved := absf(float(m["x"]) - float(m["prev_x"])) > 0.05
	var reach := (
		float(prof["meleeRange"]) + (float(prof.get("movingRangeBonus", 0)) if moved else 0.0)
	)
	if _distance_to(m) > reach or float(m["swing_timer"]) > 0.0:
		return
	var hit := RpgSwing.mob_swing(
		RpgWorld.swing_view(self, m),
		RpgWorld.swing_view(self, player),
		rng,
		float(RpgPack.swing(pack)["mob_crit_chance"]),
		_committed_tank()
	)
	m["swing_timer"] = float(m["weapon"]["speed"]) * RpgAutoAttack.swing_interval_mult(m, "melee")
	if hit["result"] == "hit" or hit["result"] == "block":
		if hit["result"] == "block":
			RpgPaladin.on_block(self, player)
		RpgCombat.deal_damage(
			self, m, player, int(hit["amount"]), hit["crit"], "physical", "", hit["result"]
		)
		if not m["dead"]:
			RpgThorns.react(self, player, m)
	else:
		log_event(
			{
				"type": "damage",
				"source": m["id"],
				"target": player["id"],
				"amount": 0,
				"kind": hit["result"]
			}
		)
		if hit["result"] == "dodge" or hit["result"] == "parry":
			_try_revenge_free()


## tryRevengeFree: a dodge or parry may make the next Revenge free (one draw, only
## for a player who knows Revenge).
func _try_revenge_free() -> void:
	if known_entry("revenge").is_empty():
		return
	if not rng.chance(float(pack["constants"]["revenge_free_chance"])):
		return
	var dur := float(pack["constants"]["revenge_free_duration"])
	(
		RpgCombat
		. apply_aura(
			self,
			player,
			{
				"id": "revenge_free",
				"kind": "revenge_free",
				"remaining": dur,
				"duration": dur,
				"value": 0.0,
				"source_id": player["id"],
				"school": "physical",
			}
		)
	)


## isCommittedTank: a protection warrior or paladin, a feral druid in Bruin Form, an
## enhancement shaman wearing Rockbiter.
func _committed_tank() -> bool:
	var cls := str(player["class_id"])
	var spec := str(player["spec_id"])
	if spec == "":
		return false
	if (cls == "warrior" and spec == "prot") or (cls == "paladin" and spec == "protection"):
		return true
	if cls == "druid" and spec == "feral":
		return RpgAbilityRules.has_kind(player, "form_bear")
	if cls == "shaman" and spec == "enhancement":
		for a: Dictionary in player["auras"]:
			if a["id"] == "rockbiter_weapon":
				return true
	return false


# -- combat state, rage, death -------------------------------------------------------


func enter_combat(source: Dictionary, target: Dictionary) -> void:
	if source.is_empty() or target.is_empty():
		return
	for u: Dictionary in [source, target]:
		if u["kind"] == "mob" and not u["dead"]:
			u["engaged"] = true
	player["combat_timer"] = 0.0


## rageGenAuraMult: Battle Stance (+STANCE_RAGE_GEN) is the warrior's from creation.
func rage_aura_mult(u: Dictionary) -> float:
	var mult := 1.0
	if u.get("class_id") == "warrior":
		mult += float(pack["constants"]["stance_rage_gen"])
	for a: Dictionary in u["auras"]:
		if a["kind"] == "buff_rage_gen":
			mult += float(a["value"])
	return mult


## dealDamage's rage from dealing: white physical damage only (rageFromDealing x
## autoRagePct x rageGenAuraMult for a warrior).
func rage_from_dealing(
	source: Dictionary, amount: int, school: String, ability: String, crit: bool
) -> void:
	if source["resource_type"] != "rage" or school != "physical" or ability != "":
		return
	var gain := RpgResources.rage_from_dealing(amount, int(source["level"]))
	if source["class_id"] == "warrior":
		var seasoned := 1.0
		if crit and source["spec_id"] == "arms":
			var k := known_entry("seasoned_soldier")
			if not k.is_empty() and k["def"].get("passive", false):
				seasoned = 1.1
		gain *= (
			(1.0 + float(source["mods"]["global"]["autoRagePct"]))
			* rage_aura_mult(source)
			* seasoned
		)
	gain *= RpgDruid.form_auto_rage_mult(source)
	source["resource"] = minf(float(source["max_resource"]), float(source["resource"]) + gain)


## dealDamage's rage from taking: a warrior gains damage / attacker level x the aura
## multiplier; another rage user rageFromTaking.
func rage_from_taking(source: Dictionary, target: Dictionary, amount: int) -> void:
	if target["resource_type"] != "rage":
		return
	var gain := (
		float(amount) / maxf(1.0, float(source["level"])) * rage_aura_mult(target)
		if target["class_id"] == "warrior"
		else RpgResources.rage_from_taking(amount, int(source["level"]))
	)
	target["resource"] = minf(float(target["max_resource"]), float(target["resource"]) + gain)


## A unit's death. The monster's: kill XP then the corpse's loot (damage.ts:1851-1969),
## rolled at the killing blow. The player's: defeat.
func kill(source: Dictionary, target: Dictionary) -> void:
	RpgPriest.on_death(self, target)
	target["dead"] = true
	target["hp"] = 0
	target["auras"] = []
	if target["kind"] == "mob":
		if target == mob:
			player["auto_attack"] = false
		if not player["dead"]:
			RpgKillCredit.on_kill(self, player)
		_reward(target)
		var alive := mobs.filter(func(m: Dictionary) -> bool: return not m["dead"])
		if respawn:
			target["respawn_in"] = _respawn_seconds(str(target["template_id"]))
		elif not zone_mode or alive.is_empty():
			outcome = "victory"
	else:
		player["casting"] = {}
		player["auto_attack"] = false
		player["combo_points"] = 0
		player["charge_target"] = -1
		player["leap"] = null
		outcome = "defeat"
	log_event(
		{"type": "death", "unit": target["id"], "by": -1 if source.is_empty() else source["id"]}
	)
	store_vitals()


## Kill credit for monster `m` (damage.ts:1851-1969, solo): XP, then its corpse's
## loot, rolled at the killing blow. Each corpse keeps its loot until taken, for
## CORPSE_DURATION (60 s) or the template's respawn time if shorter; the save keeps
## the corpses with the time they have left.
func _reward(m: Dictionary) -> void:
	var elite := float(pack["constants"]["elite_xp_mult"]) if m["elite"] else 1.0
	var xp := int(
		RpgTalents.js_round(
			(
				RpgProgression.mob_xp_value(int(m["level"]), int(player["level"]))
				* elite
				* float(m["xp_mult"])
				* float(pack["constants"]["solo_group_xp_bonus"])
			)
		)
	)
	var levels := RpgCharacter.gain_xp(state, xp)
	state["kills"] = int(state.get("kills", 0)) + 1
	var template := RpgPack.monster(pack, str(m["template_id"]))
	var loot := RpgLootRoll.roll(
		template["loot"],
		pack["items"],
		str(state["class_id"]),
		func(_q: String) -> bool: return false,
		true,
		rng
	)
	reward = {"xp": xp, "levels": levels, "loot": loot, "monster": m["template_id"]}
	var corpse := float(pack["constants"]["corpse_duration"])
	var respawn: Variant = template.get("respawn_seconds")
	if respawn != null:
		corpse = minf(corpse, float(respawn))
	if not state.get("corpses") is Array:
		state["corpses"] = []
	state["corpses"].append({"monster": m["template_id"], "loot": loot, "remaining": corpse})
	log_event({"type": "reward", "monster": m["template_id"], "xp": xp, "levels": levels})
	if levels > 0:
		player["level"] = int(state["level"])
		RpgUnit.set_talents(content, pack, player, state)
		recalc_player()
		_refresh_known()


func _respawn_seconds(monster_id: String) -> float:
	var own: Variant = RpgPack.monster(pack, monster_id).get("respawn_seconds")
	if own != null:
		return float(own)
	return float(pack["constants"]["trash_respawn_seconds"])


## A slain monster whose time is up rises at its spawn point: a fresh unit of the
## same template and id, its level drawn again (the camp spawner's rng.int).
func _respawn_tick() -> void:
	for i: int in mobs.size():
		var m: Dictionary = mobs[i]
		if not m["dead"]:
			continue
		m["respawn_in"] = float(m.get("respawn_in", 0.0)) - dt
		if float(m["respawn_in"]) > 0.0:
			continue
		var t := RpgPack.monster(pack, str(m["template_id"]))
		var level := rng.int_range(int(t["level_min"]), int(t["level_max"]))
		var fresh := RpgUnit.mob(pack, str(m["template_id"]), level, float(m["home_x"]))
		fresh["id"] = m["id"]
		fresh["home_x"] = m["home_x"]
		fresh["respawn_in"] = 0.0
		mobs[i] = fresh
		if mob == m:
			mob = {}
		log_event({"type": "respawn", "unit": fresh["id"]})


## Corpses on a living street decay as the world's time runs (CORPSE_DURATION or the
## template's respawn time, set at the kill), loot and all.
func _decay_corpses() -> void:
	var kept: Array = []
	for c: Dictionary in state.get("corpses", []):
		c["remaining"] = float(c["remaining"]) - dt
		if float(c["remaining"]) > 0.0:
			kept.append(c)
	state["corpses"] = kept


func store_vitals() -> void:
	state["vitals"] = {
		"hp": int(player["hp"]), "resource": float(player["resource"]), "dead": player["dead"]
	}


## Run whole ticks until the fight ends or `max_ticks` pass.
func run(max_ticks: int) -> String:
	var limit := tick_count + max_ticks
	while outcome == "fighting" and tick_count < limit:
		step()
	return outcome


# -- out of combat (static: no fight running) ------------------------------------------


## Take every corpse's loot into the bags (corpses lie where they fell; the trial and
## the street loot them in the order they died).
static func take_loot(state: Dictionary) -> String:
	var corpses: Array = state.get("corpses", [])
	var any := false
	for c: Dictionary in corpses:
		if int(c["loot"]["copper"]) == 0 and c["loot"]["items"].is_empty():
			continue
		any = true
		state["copper"] = int(state["copper"]) + int(c["loot"]["copper"])
		for slot: Dictionary in c["loot"]["items"]:
			RpgCharacter.add_item(state, str(slot["item_id"]), int(slot["count"]), slot["quality"])
		c["loot"] = {"copper": 0, "items": []}
	state["corpses"] = corpses.filter(
		func(c: Dictionary) -> bool: return float(c["remaining"]) > 0.0
	)
	return "" if any else "Nothing to loot."


## Time out of combat: `seconds` of 20 Hz ticks with the regen tick every 2 s (the
## world's tick counter phase is the trial's), and the corpse's time running down.
static func wait(content: ContentDB, pack: Dictionary, state: Dictionary, seconds: float) -> void:
	var u := RpgUnit.player(content, pack, state)
	restore_vitals(u, state)
	if u["dead"]:
		return
	var ticks := int(seconds * float(pack["constants"]["tick_rate"]))
	var every := int(pack["constants"]["regen_every_ticks"])
	for i in range(1, ticks + 1):
		if i % every != 0:
			continue
		match str(u["resource_type"]):
			"mana":
				var regen := RpgResources.mana_regen_per_tick(
					float(u["stats"]["spi"]),
					int(u["level"]),
					1e9,
					float(u["mods"]["global"]["manaRegenPct"])
				)
				u["resource"] = minf(float(u["max_resource"]), float(u["resource"]) + regen)
			"energy":
				u["resource"] = minf(100.0, float(u["resource"]) + RpgResources.ENERGY_PER_TICK)
			"focus":
				u["resource"] = minf(100.0, float(u["resource"]) + RpgResources.FOCUS_PER_TICK)
			"rage":
				u["resource"] = maxf(0.0, float(u["resource"]) - RpgResources.RAGE_DECAY_PER_TICK)
		if int(u["hp"]) < int(u["max_hp"]):
			var heal := RpgTalents.js_round(float(u["stats"]["sta"]) * 0.3 + 2.0)
			u["hp"] = mini(int(u["max_hp"]), int(u["hp"]) + int(heal))
	state["vitals"] = {"hp": int(u["hp"]), "resource": float(u["resource"]), "dead": false}
	var kept: Array = []
	for c: Dictionary in state.get("corpses", []):
		c["remaining"] = float(c["remaining"]) - seconds
		if float(c["remaining"]) > 0.0:
			kept.append(c)
	state["corpses"] = kept


## resurrectAtCorpse (spirit.ts reviveAt with RES_HP_FRACTION): health and mana at 50%,
## other resources 0. The trial has no graveyard or corpse run (ADAPTED).
static func revive_at_corpse(content: ContentDB, pack: Dictionary, state: Dictionary) -> String:
	var v: Variant = state.get("vitals")
	if not (v is Dictionary) or not v.get("dead", false):
		return "You are not dead."
	var u := RpgUnit.player(content, pack, state)
	var frac := float(pack["constants"]["res_hp_fraction"])
	var hp := maxi(1, int(RpgTalents.js_round(float(u["max_hp"]) * frac)))
	var res := (
		RpgTalents.js_round(float(u["max_resource"]) * frac)
		if u["resource_type"] == "mana"
		else 0.0
	)
	state["vitals"] = {"hp": hp, "resource": res, "dead": false}
	return ""
