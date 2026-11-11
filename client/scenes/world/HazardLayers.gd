class_name HazardLayers
extends RefCounted
## A warning's unchanging parts (HazardView: fill, light bands, seam,
## brackets), each recorded once into a canvas item of its own under the
## warning's, drawn in white, so a frame only sets its colour (modulate)
## instead of re-building hundreds of seam points. Presentation only.

## name -> RID, in the order added (the order they draw in).
var _items := {}


func is_empty() -> bool:
	return _items.is_empty()


## A layer under `parent` (a canvas item RID): `points` as a filled shape
## (`width` 0) or a line, drawn before the parent's own drawing when `under`,
## after it otherwise.
func add(parent: RID, layer: String, points: PackedVector2Array, width: float, under: bool) -> void:
	var rid := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(rid, parent)
	RenderingServer.canvas_item_set_draw_behind_parent(rid, under)
	RenderingServer.canvas_item_set_visible(rid, false)
	_items[layer] = rid
	record(layer, points, width)


## Records `layer` again: `points` as one shape, or as a line strip (width >
## 0), or as separate segments (pairs of points, `segments`).
func record(layer: String, points: PackedVector2Array, width: float, segments := false) -> void:
	var rid: RID = _items[layer]
	var white := PackedColorArray([Color.WHITE])
	RenderingServer.canvas_item_clear(rid)
	if segments:
		for i in range(0, points.size() - 1, 2):
			RenderingServer.canvas_item_add_line(rid, points[i], points[i + 1], Color.WHITE, width)
	elif points.size() > 2 and width <= 0.0:
		RenderingServer.canvas_item_add_polygon(rid, points, white)
	elif points.size() > 1:
		RenderingServer.canvas_item_add_polyline(rid, points, white, width)


## Shows `layer` this frame in `colour`.
func show(layer: String, colour: Color) -> void:
	var rid: RID = _items[layer]
	RenderingServer.canvas_item_set_modulate(rid, colour)
	RenderingServer.canvas_item_set_visible(rid, true)


## Hides every layer (each frame, before the ones still wanted are shown).
func hide_all() -> void:
	for rid: RID in _items.values():
		RenderingServer.canvas_item_set_visible(rid, false)


func free_all() -> void:
	for rid: RID in _items.values():
		RenderingServer.free_rid(rid)
	_items.clear()


func _notification(what: int) -> void:
	# A RefCounted cannot call its own methods while it is being deleted.
	if what == NOTIFICATION_PREDELETE:
		for rid: RID in _items.values():
			RenderingServer.free_rid(rid)
