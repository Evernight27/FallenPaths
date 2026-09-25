class_name BodyDiagramView
extends Control

## Fallout-style free human silhouette: each body region is tinted by that part's current health
## (0..1 ratio), replacing the six per-part progress bars. Front-view, patient-facing figure.
## Regions: head / chest / right_arm / left_arm / right_leg / left_leg (BodyPartConstants.BODY_PARTS).
## Colors reuse the canonical PartyRowFormatter.formation_health_bar_fill_color ramp (green -> red);
## a destroyed/severed part renders as near-black red. Row modulate (defeated/fled) still applies on
## top. Caller updates via `set_part_health(part, ratio)` from `BattleUIUpdater`.

const ART_W: float = 100.0
const ART_H: float = 160.0
const MIN_W: float = 78.0
const MIN_H: float = 126.0

const OUTLINE: Color = Color(0.02, 0.02, 0.04)
const BACKDROP: Color = Color(0.07, 0.08, 0.1)
const DESTROYED: Color = Color(0.16, 0.05, 0.05)

## Part -> health ratio 0..1 (1 = pristine).
var _health: Dictionary = {}
## Art-space->control transform (set per frame in `_draw`).
var _scale: float = 1.0
var _ox: float = 0.0
var _oy: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(MIN_W, MIN_H)


func set_part_health(part: String, ratio: float) -> void:
	_health[part] = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func clear() -> void:
	_health.clear()
	queue_redraw()


func _region_color(part: String) -> Color:
	var ratio: float = clampf(_health.get(part, 1.0), 0.0, 1.0)
	if ratio <= 0.001:
		return DESTROYED
	return PartyRowFormatter.formation_health_bar_fill_color(ratio)


func _art(x: float, y: float) -> Vector2:
	return Vector2(_ox + x * _scale, _oy + y * _scale)


func _draw() -> void:
	_scale = minf(size.x / ART_W, size.y / ART_H)
	if _scale <= 0.0 or not is_finite(_scale):
		_scale = 1.0
	_ox = (size.x - ART_W * _scale) / 2.0
	_oy = (size.y - ART_H * _scale) / 2.0
	draw_rect(Rect2(0, 0, size.x, size.y), BACKDROP)
	# Head sits in front of the torso top; torso drawn first so shoulders peek under the chest.
	_draw_polygon(_chest_pts(), "chest")
	_draw_polygon(_leg_pts(true), "right_leg")
	_draw_polygon(_leg_pts(false), "left_leg")
	_draw_arm(true)
	_draw_arm(false)
	# Head last so it reads as the topmost region.
	var head_c: Vector2 = _art(50.0, 18.0)
	var radius: float = 9.0 * _scale
	draw_circle(head_c, radius, _region_color("head"))
	draw_arc(head_c, radius, 0.0, TAU, 24, OUTLINE, 1.0 * _scale, true)


func _draw_polygon(poly: PackedVector2Array, part: String) -> void:
	if poly.size() < 3:
		return
	draw_colored_polygon(poly, _region_color(part))
	draw_polyline(_closed(poly), OUTLINE, 1.0, true)


func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var closed: PackedVector2Array = poly.duplicate()
	closed.append(closed[0])
	return closed


func _chest_pts() -> PackedVector2Array:
	return PackedVector2Array(
		[_art(40.0, 32.0), _art(60.0, 32.0), _art(64.0, 56.0), _art(36.0, 56.0)]
	)


func _leg_pts(is_right: bool) -> PackedVector2Array:
	if is_right:
		return PackedVector2Array(
			[_art(38.0, 54.0), _art(50.0, 54.0), _art(46.0, 120.0), _art(32.0, 118.0)]
		)
	return PackedVector2Array(
		[_art(50.0, 54.0), _art(62.0, 54.0), _art(68.0, 118.0), _art(54.0, 120.0)]
	)


func _draw_arm(is_right: bool) -> void:
	var part: String = "right_arm" if is_right else "left_arm"
	if is_right:
		_draw_polygon(
			PackedVector2Array([_art(57.0, 32.0), _art(69.0, 34.0), _art(74.0, 80.0), _art(61.0, 72.0)]), part
		)
	else:
		_draw_polygon(
			PackedVector2Array([_art(43.0, 32.0), _art(31.0, 34.0), _art(26.0, 80.0), _art(39.0, 72.0)]), part
		)