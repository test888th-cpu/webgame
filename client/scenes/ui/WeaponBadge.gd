class_name WeaponBadge
extends Control
## The weapon in the hero's hands, under the hero card: its sprite, its name
## and a row of pips for the blows it has left (red when about to break).
## Hidden while the hero fights bare-handed. Draws itself.

const SIZE := Vector2(110, 22)
const MAX_PIPS := 14

var _texture: Texture2D
var _name := ""
var _uses := 0
var _durability := 1
var _weapon := ""


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_weapon(content: ContentDB, weapon_id: String, uses: int) -> void:
	visible = weapon_id != ""
	if weapon_id != _weapon:
		_weapon = weapon_id
		var weapon: Dictionary = content.weapons.get(weapon_id, {})
		_texture = UiKit.icon(content, str(weapon.get("sprite", ""))) if visible else null
		_name = str(weapon.get("name", ""))
		_durability = maxi(1, int(weapon.get("durability", 1)))
		queue_redraw()
	if uses != _uses:
		_uses = uses
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(Vector2.ZERO, SIZE).grow(-0.5), Color(UiTheme.GOLD, 0.6), false, 1.0)
	if _texture:
		# The sprite stands upright; lay it diagonally in a 20px square (big
		# weapons such as the chair are shrunk to fit like the rest).
		var fit := 0.6 * 32.0 / maxf(32.0, _texture.get_size().y)
		draw_set_transform(Vector2(11, 11), deg_to_rad(45.0), Vector2(fit, fit))
		draw_texture(_texture, -_texture.get_size() / 2.0)
		draw_set_transform(Vector2.ZERO)
	var font := get_theme_default_font()
	draw_string_outline(
		font, Vector2(24, 10), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color.BLACK
	)
	draw_string(font, Vector2(24, 10), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UiTheme.GOLD)
	# One pip per blow left, scaled down for long-lasting weapons.
	var pips := mini(_durability, MAX_PIPS)
	var lit := ceili(float(_uses) / _durability * pips)
	var low := _uses <= maxi(1, _durability / 4)
	for i in pips:
		var color := UiTheme.DANGER if low else UiTheme.TEXT
		draw_rect(Rect2(24 + i * 6, 14, 4, 4), color if i < lit else Color(1, 1, 1, 0.15))
