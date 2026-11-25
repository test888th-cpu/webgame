class_name RpgMotion
extends RefCounted
## Movement on the street's axis: the player's walk (player_motion.ts, with the cast
## cancel on movement input), a charge in flight (sim.ts updateChargeMovement,
## charge_route.ts), a Heroic Leap in flight (heroic_leap.ts advanceHeroicLeap), and
## a controlled monster's flight or wander (sim.ts updateFearMovement, locomotion.ts
## polymorph wander). Headings are the reference's angles; on the street only their
## x component moves a unit (sin(angle), ADAPTED, docs/SKILLS_PORT.md).

const LEAP_FLIGHT_DURATION := 0.6
const POLYMORPH_WANDER_SPEED := 1.6


## One tick of the player's own movement. A charge or a leap owns it while it runs.
static func update_player(w: RpgEncounter) -> void:
	var p := w.player
	var from := float(p["x"])
	_update_player(w, p)
	if not p["dead"]:
		RpgPaladinKit.after_move(w, p, from)


static func _update_player(w: RpgEncounter, p: Dictionary) -> void:
	if RpgPaladinKit.advance_valkyr(w, p):
		return
	if _advance_leap(w, p):
		return
	if _advance_charge(w, p):
		return
	if w.move_dir == 0 or RpgCombat.is_rooted(p):
		return
	if not p["casting"].is_empty():
		var res := w.known_entry(str(p["casting"]["ability"]))
		var floes := RpgMage.ice_floes_for(p, str(p["casting"]["ability"]))
		if (
			res.is_empty()
			or not (
				res["def"].get("castWhileMoving", false)
				or res.get("castWhileMoving", false)
				or not floes.is_empty()
				or RpgAbilityRules.has_kind(p, "processional_grace")
			)
		):
			RpgCast.cancel_cast(w)
	p["facing"] = float(w.move_dir)
	var speed := float(w.pack["constants"]["run_speed"]) * RpgCombat.player_speed_mult(w, p)
	p["x"] = clampf(float(p["x"]) + w.move_dir * speed * w.dt, w.bounds.x, w.bounds.y)


## updateChargeMovement: CHARGE_SPEED_MULT x RUN_SPEED toward the target until
## within CHARGE_ARRIVE_RANGE (melee range - 1); a dead target, a root or the time
## budget ends it short. Arriving at a hostile starts the auto attack.
static func _advance_charge(w: RpgEncounter, p: Dictionary) -> bool:
	if int(p.get("charge_target", -1)) < 0:
		return false
	var target := w.unit(int(p["charge_target"]))
	p["charge_time"] = float(p["charge_time"]) - w.dt
	var c: Dictionary = w.pack["constants"]
	var arrive := float(c["melee_range"]) - 1.0
	if (
		target.is_empty()
		or target["dead"]
		or float(p["charge_time"]) <= 0.0
		or RpgCombat.is_rooted(p)
	):
		_finish_charge(w, p, target, false)
		return true
	var gap := float(target["x"]) - float(p["x"])
	if absf(gap) <= arrive:
		_finish_charge(w, p, target, true)
		return true
	p["facing"] = signf(gap)
	var step := minf(
		float(c["run_speed"]) * float(c["charge_speed_mult"]) * w.dt, maxf(0.01, absf(gap))
	)
	p["x"] = clampf(float(p["x"]) + signf(gap) * step, w.bounds.x, w.bounds.y)
	return true


static func _finish_charge(
	w: RpgEncounter, p: Dictionary, target: Dictionary, arrived: bool
) -> void:
	RpgClassMotion.finish_charge_arrival(w, p, target, arrived)
	p["charge_target"] = -1
	if not target.is_empty():
		RpgWorld.face(w, target)
	if arrived and not target.is_empty() and target["kind"] == "mob":
		w.command({"op": "attack"})


## armHeroicLeap: a 0.6 s flight to the aim point (the street has no terrain to
## stop it short, only its ends), with an area strike on landing.
static func arm_leap(
	_w: RpgEncounter, p: Dictionary, aim: float, landing: Dictionary, def: Dictionary
) -> void:
	p["charge_target"] = -1
	(
		p
		. merge(
			{
				"leap":
				{
					"from": float(p["x"]),
					"to": aim,
					"elapsed": 0.0,
					"landing": landing.duplicate(),
					"ability_id": def["id"],
					"ability_name": def["name"],
					"school": def["school"],
				}
			},
			true
		)
	)


static func _advance_leap(w: RpgEncounter, p: Dictionary) -> bool:
	var flight: Variant = p.get("leap")
	if not (flight is Dictionary):
		return false
	if p["dead"]:
		p["leap"] = null
		return false
	flight["elapsed"] = float(flight["elapsed"]) + w.dt
	var progress := minf(1.0, float(flight["elapsed"]) / LEAP_FLIGHT_DURATION)
	var to := clampf(float(flight["to"]), w.bounds.x, w.bounds.y)
	p["x"] = float(flight["from"]) + (to - float(flight["from"])) * progress
	if float(flight["elapsed"]) < LEAP_FLIGHT_DURATION:
		return true
	p["x"] = to
	p["leap"] = null
	var land: Dictionary = flight["landing"]
	if float(land["radius"]) > 0.0:
		for t: Dictionary in RpgAbilityRules.hostiles_in_radius(w, p, to, float(land["radius"])):
			var dmg := int(
				RpgTalents.js_round(w.rng.range_f(float(land["min"]), float(land["max"])))
			)
			RpgCombat.deal_damage(
				w, p, t, dmg, false, str(flight["school"]), str(flight["ability_name"])
			)
	return true


## A controlled monster's tick (locomotion.ts's stunned arm): a feared one flees on
## its heading at flee speed (unless rooted); a polymorphed one wanders.
static func controlled_mob(w: RpgEncounter, m: Dictionary) -> void:
	var c: Dictionary = w.pack["constants"]
	for a: Dictionary in m["auras"]:
		if a["id"] == "fear_incap" and a["kind"] == "incapacitate":
			if RpgAbilityRules.has_kind(m, "root") or a.get("unbreakable_control", false):
				break
			var speed := minf(
				float(m["move_speed"]) * float(c["flee_speed_mult"]) * RpgCombat.move_speed_mult(m),
				float(c["flee_max_speed"])
			)
			var dx := sin(float(a["value"]))
			m["facing"] = signf(dx) if dx != 0.0 else float(m.get("facing", -1.0))
			m["x"] = float(m["x"]) + dx * speed * w.dt
			return
	var poly := RpgAbilityRules.find_kind(m, "polymorph")
	if poly.is_empty() or poly.get("unbreakable_control", false):
		return
	m["wander_timer"] = float(m.get("wander_timer", 0.0)) - w.dt
	if float(m["wander_timer"]) <= 0.0:
		m["wander_timer"] = w.rng.range_f(0.8, 2.0)
		m["wander_heading"] = w.rng.range_f(-PI, PI)
	m["x"] = (
		float(m["x"]) + sin(float(m.get("wander_heading", 0.0))) * POLYMORPH_WANDER_SPEED * w.dt
	)
