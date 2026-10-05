extends Node2D
## The Mother Culture: Glowbeds' central feature (USER 2026-10-04: the district needs a related central feature). The
## living culture every bed in the district is seeded from, standing in a glass column on the hang's basin and rising
## through the whole garden cavern to its ceiling, where it spreads into a canopy of luminous caps and tendrils. Root
## pipes run from its base along the hang to the culture vats and the press, carrying a slow flow of glowing sap, so it
## reads as the heart the rest of the district grows from. Its glow follows Glowbeds' condition (bright and full when
## healthy, dim and slow when strained). Drawn behind the bridges (they cross in front of it). Greybox, visual only.

const BASE_X := 6900.0 ## the `mother_culture_base` prop on the hang
const BASE_LEVEL := 6.0
const COLUMN_W := 72.0
const SAP := Color(0.45, 0.95, 0.75)
const GLASS := Color(0.55, 0.85, 0.8)
const BARK := Color(0.2, 0.16, 0.12)

var _t := 0.0
var _health := 0.8
var _top := 0.0
var _deck := 0.0


func _ready() -> void:
	z_index = -1
	for h in HollowMap.halls():
		if h["id"] == &"H_GB":
			_top = HollowMap.lvl(float(h["k_top"])) - HollowMap.ROOM_HEIGHT
	_deck = HollowMap.lvl(BASE_LEVEL)
	var district := get_node_or_null("/root/District")
	if district != null and district.has_method("get_condition"):
		_health = _health_for(district.get_condition(&"glowbeds"))
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("district_changed"):
		bus.district_changed.connect(func(id: StringName, c: StringName) -> void:
			if id == &"glowbeds":
				_health = _health_for(c))


static func _health_for(condition: StringName) -> float:
	match condition:
		&"comfortable":
			return 1.0
		&"stable":
			return 0.8
		&"strained":
			return 0.55
		&"shortage":
			return 0.35
		&"critical":
			return 0.2
	return 0.8


func _process(delta: float) -> void:
	_t += delta * (0.4 + 0.6 * _health)
	queue_redraw()


func _on_screen() -> bool:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var view := inv * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	return view.intersects(Rect2(BASE_X - 520.0, _top, 1040.0, _deck - _top + 80.0))


func _draw() -> void:
	if not _on_screen():
		return
	var x := BASE_X
	var base_y := _deck - 36.0
	# canopy first (behind the column): a wide spread of branches along the ceiling with luminous caps
	_canopy(x, _top)
	# the glass column
	var col := Rect2(x - COLUMN_W * 0.5, _top + 40.0, COLUMN_W, base_y - _top - 40.0)
	draw_rect(col, Color(GLASS.r, GLASS.g, GLASS.b, 0.13))
	draw_rect(Rect2(col.position.x, col.position.y, 5.0, col.size.y), Color(1, 1, 1, 0.18))
	draw_rect(col, Color(GLASS.r, GLASS.g, GLASS.b, 0.55), false, 2.0)
	# the trunk inside: a twisting living stem, with glowing sap pulsing up it
	var pts := PackedVector2Array()
	var steps := int(col.size.y / 16.0)
	for i in range(steps + 1):
		var f := float(i) / float(steps)
		var yy := col.end.y - f * col.size.y
		pts.append(Vector2(x + sin(f * 14.0 + _t * 0.2) * 12.0, yy))
	draw_polyline(pts, BARK, 14.0)
	draw_polyline(pts, Color(SAP.r, SAP.g, SAP.b, 0.25 + 0.3 * _health), 5.0)
	for i in range(14):
		var f := fposmod(_t * 0.18 + float(i) / 14.0, 1.0)
		var yy := col.end.y - f * col.size.y
		var p := Vector2(x + sin(f * 14.0 + _t * 0.2) * 12.0, yy)
		draw_circle(p, 3.5, Color(SAP.r, SAP.g, SAP.b, 0.9 * _health))
		draw_circle(p, 12.0, Color(SAP.r, SAP.g, SAP.b, 0.07 * _health))
	# glow around the whole column
	draw_circle(Vector2(x, (col.position.y + col.end.y) * 0.5), 150.0 + 20.0 * sin(_t), Color(SAP.r, SAP.g, SAP.b, 0.04 * _health))
	# collars at the bridge crossings and the base
	for k in [4.0, 5.0]:
		var cy := HollowMap.lvl(k)
		draw_rect(Rect2(x - COLUMN_W * 0.5 - 6.0, cy - 6.0, COLUMN_W + 12.0, 12.0), Color(0.5, 0.36, 0.2))
	draw_rect(Rect2(x - COLUMN_W * 0.5 - 8.0, base_y - 8.0, COLUMN_W + 16.0, 12.0), Color(0.5, 0.36, 0.2))
	_roots(x, base_y)
	_plaque(x, _deck - 150.0, "THE MOTHER CULTURE")


## The canopy: branches along the ceiling to both sides, each ending in a luminous cap that breathes.
func _canopy(x: float, top: float) -> void:
	for i in range(-6, 7):
		var bx := x + float(i) * 70.0
		var droop := 40.0 + float(absi(i) * 9) + float((absi(i) * 37) % 30)
		var sway := sin(_t * 0.5 + float(i)) * 4.0
		var from := Vector2(x + float(i) * 14.0, top + 44.0)
		var to := Vector2(bx + sway, top + droop + 28.0)
		draw_line(from, to, BARK, 5.0 - float(absi(i)) * 0.3)
		var breathe := 0.55 + 0.45 * sin(_t * 0.9 + float(i) * 0.8)
		draw_circle(to, 10.0, Color(SAP.r, SAP.g, SAP.b, 0.35 + 0.4 * breathe * _health))
		draw_circle(to, 28.0, Color(SAP.r, SAP.g, SAP.b, 0.06 * breathe * _health))
		draw_line(to, to + Vector2(sway, 30.0 + float((absi(i) * 53) % 40)), Color(0.3, 0.7, 0.5, 0.8), 2.0)


## Root pipes from the basin along the hang to the vats (west) and the press (east), with sap flowing along them.
func _roots(x: float, base_y: float) -> void:
	var y := base_y + 12.0
	for target in [5860.0, 7480.0]:
		var dir := signf(target - x)
		var pts := PackedVector2Array()
		var n := int(absf(target - x) / 20.0)
		for i in range(n + 1):
			pts.append(Vector2(x + dir * float(i) * 20.0, y - 52.0 + sin(float(i) * 0.5) * 3.0))
		draw_polyline(pts, Color(0.45, 0.3, 0.2), 6.0)
		draw_polyline(pts, Color(SAP.r, SAP.g, SAP.b, 0.35 * _health), 2.0)
		for j in range(8):
			var f := fposmod(_t * 0.22 + float(j) / 8.0, 1.0)
			var idx := mini(int(f * float(n)), n)
			draw_circle(pts[idx], 3.0, Color(SAP.r, SAP.g, SAP.b, 0.85 * _health))
		draw_line(Vector2(x, base_y), pts[0], Color(0.45, 0.3, 0.2), 6.0)


func _plaque(x: float, y: float, text: String) -> void:
	draw_rect(Rect2(x - 70.0, y - 12.0, 140.0, 18.0), Color(0.06, 0.09, 0.08, 0.88))
	draw_rect(Rect2(x - 70.0, y - 12.0, 140.0, 18.0), Color(0.45, 0.8, 0.65, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(x - 64.0, y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.65, 1.0, 0.85, 0.95))
