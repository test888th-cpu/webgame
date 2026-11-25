class_name RpgClassMotion
extends RefCounted
## charge_route.ts finishChargeArrival: the class engines settled when a run ends
## (the hunter's Bloodhook, the druid's Lunge and Bruin Rush).


static func finish_charge_arrival(
	w: RpgEncounter, p: Dictionary, target: Dictionary, arrived: bool
) -> void:
	RpgDruidKit.finish_charge(w, p, target, arrived)
