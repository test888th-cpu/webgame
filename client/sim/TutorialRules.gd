class_name TutorialRules
extends RefCounted
## The first-time tutorial: steps from tutorial.json, each finished by doing
## the thing it teaches (a "signal") enough times. Progress is the index of
## the next step on the PlayerProfile; finished or skipped means past the
## last step. This code never names a specific step.

## What the hero can be seen doing, as the steps count it.
const SIGNALS := ["move", "hit", "heavy", "skill", "dodge", "guard", "pickup", "throw", "talk"]


## The step being taught, or {} when the tutorial is over.
static func current(profile: PlayerProfile, content: ContentDB) -> Dictionary:
	if profile.tutorial >= content.tutorial.size():
		return {}
	return content.tutorial[profile.tutorial]


static func is_done(profile: PlayerProfile, content: ContentDB) -> bool:
	return current(profile, content).is_empty()


## Counts `action` (one of SIGNALS) towards the current step. Returns true when that finished
## the step (the profile has moved on to the next one).
static func notify(profile: PlayerProfile, action: String, content: ContentDB) -> bool:
	var step := current(profile, content)
	if step.is_empty() or step["signal"] != action:
		return false
	profile.tutorial_progress += 1
	if profile.tutorial_progress < int(step.get("count", 1)):
		return false
	profile.tutorial += 1
	profile.tutorial_progress = 0
	return true


static func skip(profile: PlayerProfile, content: ContentDB) -> void:
	profile.tutorial = content.tutorial.size()
	profile.tutorial_progress = 0


## The signals in one tick: the hero's input and what the zone reported.
static func signals_for(
	events: Array[ZoneEvent], hero: Fighter, input: FighterInput, library: MoveLibrary
) -> Array[String]:
	var found: Array[String] = []
	if input.move != Vector2.ZERO:
		found.append("move")
	if hero.state == Fighter.State.GUARD:
		found.append("guard")
	for event in events:
		match event.type:
			"hit":
				if event.hit.attacker_id == hero.id and not event.hit.blocked:
					found.append("hit")
			"swing":
				if event.data["id"] != hero.id:
					continue
				if event.data["skill"]:
					found.append("skill")
				elif event.data["move"] == CombatRules.starter(hero, library, "heavy"):
					found.append("heavy")
			"dodge", "weapon_pickup", "weapon_throw":
				if event.data["id"] == hero.id:
					found.append(
						{"dodge": "dodge", "weapon_pickup": "pickup", "weapon_throw": "throw"}[
							event.type
						]
					)
	return found
