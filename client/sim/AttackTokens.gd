class_name AttackTokens
extends RefCounted
## Which enemies may start an attack this tick: bosses always, the rest up to
## ZoneSim.MAX_ATTACKERS at once, nearest the hero first, so a crowd takes
## turns instead of piling in. Pure rules, shared with the server.


static func allowed(zone: ZoneSim) -> Dictionary:
	var allowed := {}
	var attacking := 0
	var ready: Array[Fighter] = []
	for enemy in zone.enemies():
		if enemy.is_ko() or not zone.brains.has(enemy.id):
			continue
		if enemy.state == Fighter.State.ATTACK:
			attacking += 1
		elif zone.content.enemy(enemy.kind).get("boss", false):
			allowed[enemy.id] = true
		elif zone.brains[enemy.id].wants_attack():
			ready.append(enemy)
	ready.sort_custom(
		func(a: Fighter, b: Fighter) -> bool:
			var da := absf(a.position.x - zone.hero.position.x)
			var db := absf(b.position.x - zone.hero.position.x)
			return da < db if da != db else a.id < b.id
	)
	for enemy in ready:
		if attacking >= ZoneSim.MAX_ATTACKERS:
			break
		allowed[enemy.id] = true
		attacking += 1
	return allowed
