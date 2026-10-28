class_name DamageNumber
extends Label
## Floating damage number. Rises, fades and frees itself.

const RISE := 18.0
const SECONDS := 0.6


func show_hit(event: CombatEvent) -> void:
	text = str(event.damage)
	if event.parried:
		text = "PARRY"
		modulate = Color(0.55, 0.95, 1.0)
	elif event.critical:
		text = "CRIT " + text
		modulate = Color(1.0, 0.85, 0.3)
	elif event.counter:
		text = "COUNTER " + text
		modulate = Color(1.0, 0.6, 0.25)
	elif event.armored or event.staggered:
		# Landed, but they did not flinch: a steel-grey number says "dodge now".
		modulate = Color(0.75, 0.8, 0.9)
	elif event.blocked:
		modulate = Color(0.6, 0.8, 1.0)
	elif event.ko:
		text += " KO"
		modulate = Color(1.0, 0.85, 0.3)
	position = event.position + Vector2(-size.x / 2, -54)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, SECONDS)
	tween.tween_property(self, "modulate:a", 0.0, SECONDS).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
