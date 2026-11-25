class_name RpgKillCredit
extends RefCounted
## The killer's kill-credit windows (combat/damage.ts handleDeath, solo): Pursuit's
## speed, Kill Chain's combo refill and Smokefade reset, Bloodbath's stacking crit and
## damage, then the warrior's Victor's Surge window.


static func on_kill(w: RpgEncounter, p: Dictionary) -> void:
	var g: Dictionary = p["mods"]["global"]
	var c: Dictionary = w.pack["constants"]
	if float(g["onKillSpeedPct"]) > 0.0:
		var dur := float(c["pursuit_speed_duration"])
		(
			RpgCombat
			. apply_aura(
				w,
				p,
				{
					"id": "pursuit",
					"kind": "buff_speed",
					"value": 1.0 + float(g["onKillSpeedPct"]),
					"remaining": dur,
					"duration": dur,
					"source_id": p["id"],
					"school": "physical",
				}
			)
		)
	if float(g["onKillCombo"]) > 0.0:
		p["combo_points"] = mini(
			5, int(p.get("combo_points", 0)) + int(RpgTalents.js_round(float(g["onKillCombo"])))
		)
	if float(g["onKillVanishReset"]) > 0.0:
		p["cooldowns"].erase("vanish")
	if float(g["bloodbathPct"]) > 0.0:
		var dur := float(c["bloodbath_duration"])
		var existing := RpgAbilityRules.find_kind(p, "bloodbath")
		if not existing.is_empty():
			existing["stacks"] = mini(
				int(c["bloodbath_max_stacks"]), int(existing.get("stacks", 1)) + 1
			)
			existing["value"] = float(g["bloodbathPct"]) * int(existing["stacks"])
			existing["remaining"] = dur
			existing["duration"] = dur
		else:
			(
				RpgCombat
				. apply_aura(
					w,
					p,
					{
						"id": "bloodbath",
						"kind": "bloodbath",
						"value": float(g["bloodbathPct"]),
						"remaining": dur,
						"duration": dur,
						"source_id": p["id"],
						"school": "physical",
						"stacks": 1,
					}
				)
			)
		w.recalc_player()
	RpgWarrior.on_kill(w, p)
