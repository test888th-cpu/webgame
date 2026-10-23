class_name SpriteView
extends Control
## A character's animated sprite inside a UI layout: the sprite (on its
## shadow) stands at the bottom centre of this control and follows it when
## the layout changes.

var sprite: AnimatedSprite2D
var _holder: Node2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)


## Shows `art_id` scaled by `size`. Returns false if it has no art.
func show_art(content: ContentDB, art_id: String, size := 2.0) -> bool:
	if _holder:
		_holder.queue_free()
	_holder = Node2D.new()
	add_child(_holder)
	sprite = Showcase.add(_holder, content, art_id, Vector2.ZERO, size)
	_place()
	return sprite != null


## Turns the character to face the other way.
func turn() -> void:
	if sprite:
		sprite.flip_h = not sprite.flip_h


func _place() -> void:
	if _holder:
		_holder.position = Vector2(size.x / 2.0, size.y - 4.0)
