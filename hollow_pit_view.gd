extends Node2D
## The pit pool: the Cistern's water (USER 2026-10-04: "I thought the Cistern was supposed to have water"). Canon (lore): the
## Heavenfall flood drained down through fractures over generations and pooled at the bottom of the Devil's Mouth, drowning
## part of the wreck; the Cistern's water is siphoned UP from that pool, not seeped. So the pool is real and visible:
##   the pool   a deep teal body of water across the whole floor of the Mouth, light shafts falling into it from the
##              lamps of the districts above, ripples, rising bubbles, a faint pale shimmer on the surface;
##   the wreck  the dark ribs of a vast hull curving up out of the water (a hint only: the wreck is Act 3);
##   the siphon a big copper pipe rising out of the water along the east cliff to the Cistern's intake ledge, with
##              collars, a pump housing at the ledge, a glass section showing water climbing it, and steam at the pump.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const WATER := Color(0.25, 0.7, 0.75)
const WATER_DEEP := Color(0.06, 0.2, 0.26)
const PALE := Color(0.7, 0.95, 0.95)
const COPPER := Color(0.62, 0.4, 0.22)
const COPPER_HI := Color(0.88, 0.62, 0.36)
const PATINA := Color(0.32, 0.62, 0.54)
const STEEL := Color(0.22, 0.25, 0.28)

var _t := 0.0
var _surface := 0.0
var _rect := Rect2()


func _ready() -> void:
	z_index = -1
	_surface = HollowMap.CAVITY_BOTTOM + 380.0
	_rect = Rect2(HollowMap.MOUTH_L, _surface, HollowMap.MOUTH_R - HollowMap.MOUTH_L, HollowMap.ENV_BOTTOM - _surface)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_screen() -> bool:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var view := inv * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	return view.grow(200.0).intersects(Rect2(_rect.position.x, HollowMap.lvl(12.0), _rect.size.x, HollowMap.ENV_BOTTOM - HollowMap.lvl(12.0)))


func _draw() -> void:
	if not _on_screen():
		return
	_water()
	_wreck()
	_siphon()


func _water() -> void:
	var bands := 16
	for i in range(bands):
		var f := float(i) / float(bands - 1)
		var y := _rect.position.y + _rect.size.y * float(i) / float(bands)
		var c := WATER.lerp(WATER_DEEP, minf(1.0, f * 1.25))
		draw_rect(Rect2(_rect.position.x, y, _rect.size.x, _rect.size.y / float(bands) + 1.0), Color(c.r, c.g, c.b, 0.78 + 0.2 * f))
	# the surface: a bright line with a travelling ripple, and glints
	var pts := PackedVector2Array()
	var x := _rect.position.x
	while x <= _rect.end.x:
		pts.append(Vector2(x, _surface + sin(x * 0.02 + _t * 1.4) * 3.0 + sin(x * 0.007 - _t * 0.8) * 4.0))
		x += 40.0
	draw_polyline(pts, Color(PALE.r, PALE.g, PALE.b, 0.8), 3.0)
	for i in range(26):
		var gx := _rect.position.x + float((i * 137) % 3500)
		var tw := 0.5 + 0.5 * sin(_t * 1.7 + float(i))
		draw_rect(Rect2(gx, _surface + 6.0 + float((i * 29) % 60), 26.0, 2.0), Color(PALE.r, PALE.g, PALE.b, 0.25 * tw))
	# light shafts: soft slanted columns of pale light from the lamps above, fading with depth
	for i in range(7):
		var sx := _rect.position.x + 260.0 + float(i) * 480.0
		var sway := sin(_t * 0.3 + float(i)) * 20.0
		for s in range(6):
			var f := float(s) / 5.0
			draw_colored_polygon(PackedVector2Array([Vector2(sx + sway, _surface), Vector2(sx + 70.0 + sway, _surface), Vector2(sx + 140.0 + sway * 1.5 + f * 40.0, _surface + 360.0 * (0.5 + f * 0.5)), Vector2(sx + 30.0 + sway * 1.5 + f * 40.0, _surface + 360.0 * (0.5 + f * 0.5))]), Color(PALE.r, PALE.g, PALE.b, 0.012))
	# rising bubbles
	for i in range(30):
		var f2 := fposmod(_t * 0.08 + float(i) * 0.0337, 1.0)
		var bx := _rect.position.x + float((i * 211) % 3500) + sin(_t + float(i)) * 6.0
		draw_circle(Vector2(bx, _rect.end.y - f2 * (_rect.size.y - 10.0)), 1.5 + float(i % 3), Color(PALE.r, PALE.g, PALE.b, 0.3 * (1.0 - f2)))


## A hint of the wreck: the dark ribs of a vast hull, arching up out of the water, with weed and a few dim lights.
func _wreck() -> void:
	var cx := 3050.0
	var base := _rect.end.y
	for i in range(9):
		var x := cx - 520.0 + float(i) * 130.0
		var h := 180.0 + 110.0 * sin(float(i) * 0.7 + 0.4)
		var top := Vector2(x, base - h)
		var pts := PackedVector2Array()
		for s in range(9):
			var f := float(s) / 8.0
			pts.append(Vector2(x + sin(f * PI) * 28.0 * (1.0 if i % 2 == 0 else -1.0), base - f * h))
		draw_polyline(pts, Color(0.03, 0.06, 0.08, 0.95), 14.0)
		draw_polyline(pts, Color(0.1, 0.2, 0.24, 0.5), 3.0)
		if i % 3 == 0:
			draw_circle(top + Vector2(0.0, 12.0), 3.0, Color(0.5, 0.95, 0.9, 0.4 + 0.3 * sin(_t * 2.0 + float(i))))
	draw_line(Vector2(cx - 560.0, base - 22.0), Vector2(cx + 560.0, base - 22.0), Color(0.03, 0.06, 0.08, 0.9), 10.0)


## The siphon: a big copper pipe rising out of the pool along the east cliff to the Cistern's intake ledge.
func _siphon() -> void:
	var x := HollowMap.MOUTH_R - 70.0
	var y1 := _surface + 90.0
	var y0 := HollowMap.lvl(13.0) - 20.0
	# the main pipe
	draw_rect(Rect2(x - 22.0, y0, 44.0, y1 - y0), COPPER)
	draw_rect(Rect2(x - 22.0, y0, 6.0, y1 - y0), COPPER_HI)
	draw_rect(Rect2(x + 16.0, y0, 6.0, y1 - y0), Color(0, 0, 0, 0.3))
	var cy := y0 + 60.0
	while cy < y1:
		draw_rect(Rect2(x - 30.0, cy, 60.0, 12.0), PATINA.darkened(0.2))
		draw_rect(Rect2(x - 30.0, cy, 60.0, 3.0), PATINA)
		cy += 180.0
	# a glass section where the water can be seen climbing
	var gy := y0 + 340.0
	draw_rect(Rect2(x - 20.0, gy, 40.0, 120.0), Color(0.15, 0.3, 0.34, 0.9))
	for i in range(8):
		var f := fposmod(_t * 0.7 + float(i) * 0.125, 1.0)
		draw_circle(Vector2(x + sin(f * 9.0 + float(i)) * 8.0, gy + 120.0 - f * 120.0), 3.0, Color(PALE.r, PALE.g, PALE.b, 0.7))
	# a thinner branch and a pump housing at the intake ledge
	draw_rect(Rect2(x, y0 - 16.0, 70.0, 14.0), COPPER)
	draw_rect(Rect2(x + 60.0, y0 - 80.0, 70.0, 80.0), STEEL)
	draw_rect(Rect2(x + 60.0, y0 - 80.0, 70.0, 6.0), COPPER_HI)
	draw_circle(Vector2(x + 95.0, y0 - 44.0), 20.0, COPPER.darkened(0.2))
	for s in range(4):
		var a := _t * 2.2 + float(s) * PI * 0.5
		draw_line(Vector2(x + 95.0, y0 - 44.0), Vector2(x + 95.0, y0 - 44.0) + Vector2(cos(a), sin(a)) * 17.0, COPPER_HI, 3.0)
	for i in range(4):
		var f2 := fposmod(_t * 0.5 + float(i) * 0.25, 1.0)
		draw_circle(Vector2(x + 110.0 + sin(f2 * 6.0) * 8.0, y0 - 90.0 - f2 * 50.0), 6.0 + 10.0 * f2, Color(0.85, 0.9, 0.92, 0.22 * (1.0 - f2)))
	# intake mouth under the water: a flared inlet with a grate
	draw_rect(Rect2(x - 36.0, y1, 72.0, 22.0), STEEL)
	for i in range(5):
		draw_line(Vector2(x - 30.0 + float(i) * 15.0, y1 + 2.0), Vector2(x - 30.0 + float(i) * 15.0, y1 + 20.0), Color(0.05, 0.08, 0.1), 3.0)
