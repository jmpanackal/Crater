extends Control
## The title screen's picture, drawn in code (greybox, replaced by real art later): the Hollow as the concept art shows
## it, a deep blue-black drop with the two crater walls on either side stacked with lit homes and workshops, the Mid
## Heart cluster hung across the middle on its trusses, hanging lanterns, and the Pulse's four lamps breathing
## quietly. Deterministic and cheap: one pass of polygons and rectangles.

const SKY_TOP := Color(0.02, 0.035, 0.06)
const SKY_BOTTOM := Color(0.045, 0.075, 0.12)
const ROCK := Color(0.07, 0.07, 0.09)
const ROCK_LIGHT := Color(0.1, 0.1, 0.125)
const TRUSS := Color(0.1, 0.09, 0.08)
const AMBER := Color(1.0, 0.74, 0.38)
const TEAL := Color(0.4, 0.85, 0.8)

var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	# the drop: a vertical gradient in strips
	var strips := 24
	for i in range(strips):
		var f := float(i) / float(strips - 1)
		draw_rect(Rect2(0.0, h * float(i) / float(strips), w, h / float(strips) + 1.0), SKY_TOP.lerp(SKY_BOTTOM, f))
	# faint far walls and the wreck far below, so the dark has depth
	for i in range(5):
		var fx := w * (0.34 + 0.08 * float(i))
		draw_rect(Rect2(fx, h * 0.18, w * 0.03, h * 0.7), Color(0.05, 0.075, 0.115, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.42, h * 0.97), Vector2(w * 0.47, h * 0.84), Vector2(w * 0.52, h * 0.9), Vector2(w * 0.58, h * 0.86), Vector2(w * 0.63, h * 0.97)]), Color(0.06, 0.08, 0.11))
	_wall(true, w, h)
	_wall(false, w, h)
	_heart(w, h)
	_lanterns(w, h)


## One crater wall: a jagged cliff with stacked terraces, each carrying a row of lit windows and a lantern.
func _wall(left: bool, w: float, h: float) -> void:
	var edge := w * 0.24
	_rng.seed = 11 if left else 29
	var pts := PackedVector2Array()
	var sx := 0.0 if left else w
	var dir := 1.0 if left else -1.0
	pts.append(Vector2(sx, 0.0))
	var steps := 16
	for i in range(steps + 1):
		var y := h * float(i) / float(steps)
		var reach := edge + _rng.randf_range(-w * 0.025, w * 0.03) + (w * 0.03 if i % 3 == 0 else 0.0)
		pts.append(Vector2(sx + dir * reach, y))
	pts.append(Vector2(sx, h))
	draw_colored_polygon(pts, ROCK)
	# terraces
	var rows := 9
	for r in range(rows):
		var y := h * (0.1 + 0.095 * float(r))
		var reach := edge * (0.62 + 0.38 * _rng.randf())
		var x0 := sx if left else sx - reach
		draw_rect(Rect2(x0, y, reach, 5.0), ROCK_LIGHT)
		draw_rect(Rect2(x0, y + 5.0, reach, 1.0), Color(0.5, 0.36, 0.2, 0.35))
		var cols := int(reach / 34.0)
		for c in range(cols):
			if _rng.randf() < 0.28:
				continue
			var wx := x0 + 10.0 + float(c) * 34.0
			var flick := 0.8 + 0.2 * sin(_t * 1.4 + float(r * 7 + c))
			var tone := AMBER if _rng.randf() < 0.82 else TEAL
			draw_rect(Rect2(wx, y - 20.0, 12.0, 15.0), Color(tone.r, tone.g, tone.b, 0.78 * flick))
			draw_circle(Vector2(wx + 6.0, y - 12.0), 20.0, Color(tone.r, tone.g, tone.b, 0.05 * flick))
			draw_rect(Rect2(wx - 3.0, y - 24.0, 18.0, 4.0), Color(0.06, 0.05, 0.05))
	# a caged shaft on the wall's inner face, as the concept art has
	var shaft_x := (w * 0.045) if left else (w * 0.955)
	draw_rect(Rect2(shaft_x - 14.0, 0.0, 28.0, h), Color(0.05, 0.045, 0.04))
	var ly := 0.0
	while ly < h:
		draw_rect(Rect2(shaft_x - 14.0, ly, 28.0, 2.0), Color(0.3, 0.22, 0.12, 0.7))
		ly += 36.0


## Mid Heart: a stepped cluster of rafts on dark truss legs across the middle, lit shops, banners, the Pulse.
func _heart(w: float, h: float) -> void:
	var cx := w * 0.5
	var decks := [
		[cx - w * 0.2, cx + w * 0.2, h * 0.92],
		[cx - w * 0.14, cx + w * 0.14, h * 0.84],
		[cx - w * 0.07, cx + w * 0.07, h * 0.76],
	]
	for d in decks:
		var x0: float = d[0]
		var x1: float = d[1]
		var y: float = d[2]
		draw_rect(Rect2(x0, y, x1 - x0, 6.0), Color(0.16, 0.12, 0.09))
		var x := x0
		var up := true
		while x + 22.0 <= x1:
			draw_line(Vector2(x, y + (6.0 if up else 26.0)), Vector2(x + 22.0, y + (26.0 if up else 6.0)), TRUSS, 2.0)
			x += 22.0
			up = not up
		draw_rect(Rect2(x0, y + 26.0, x1 - x0, 3.0), TRUSS)
		var n := int((x1 - x0) / 54.0)
		for i in range(n):
			var bx := x0 + 14.0 + float(i) * 54.0
			var lit := 0.8 + 0.2 * sin(_t * 1.1 + bx * 0.05)
			draw_rect(Rect2(bx, y - 30.0, 34.0, 30.0), Color(0.09, 0.075, 0.06))
			draw_rect(Rect2(bx + 6.0, y - 22.0, 9.0, 11.0), Color(AMBER.r, AMBER.g, AMBER.b, 0.75 * lit))
			draw_rect(Rect2(bx + 19.0, y - 22.0, 9.0, 11.0), Color(AMBER.r, AMBER.g, AMBER.b, 0.6 * lit))
			draw_circle(Vector2(bx + 17.0, y - 16.0), 26.0, Color(AMBER.r, AMBER.g, AMBER.b, 0.045 * lit))
	# legs to the cliffs and a banner over the central hall
	for lx in [cx - w * 0.2, cx + w * 0.2]:
		draw_line(Vector2(lx, h * 0.92 + 6.0), Vector2(lx + (-w * 0.04 if lx < cx else w * 0.04), h * 0.99), TRUSS, 3.0)
	draw_rect(Rect2(cx - 22.0, h * 0.76 - 78.0, 44.0, 40.0), Color(0.5, 0.2, 0.16))
	draw_circle(Vector2(cx, h * 0.76 - 58.0), 8.0, Color(0.85, 0.65, 0.35))
	# the Pulse: a squat machine on the middle deck with its four lamps
	var px := cx
	var py := h * 0.84
	draw_rect(Rect2(px - 22.0, py - 46.0, 44.0, 46.0), Color(0.12, 0.13, 0.15))
	var phase := int(fmod(_t * 0.25, 4.0))
	for i in range(4):
		var on := i <= phase
		var col := Color(1.0, 0.78, 0.42, 0.95 if i == phase else 0.45) if on else Color(0.1, 0.1, 0.1)
		draw_rect(Rect2(px - 18.0 + float(i) * 10.0, py - 38.0, 7.0, 7.0), col)
	draw_circle(Vector2(px, py - 34.0), 34.0, Color(AMBER.r, AMBER.g, AMBER.b, 0.05))


func _lanterns(w: float, h: float) -> void:
	_rng.seed = 7
	for i in range(14):
		var x := _rng.randf_range(w * 0.28, w * 0.72)
		var y := _rng.randf_range(h * 0.12, h * 0.8)
		var flick := 0.75 + 0.25 * sin(_t * 1.7 + float(i))
		draw_line(Vector2(x, y - 26.0), Vector2(x, y - 6.0), Color(0.2, 0.17, 0.12, 0.6), 1.0)
		draw_rect(Rect2(x - 3.0, y - 6.0, 6.0, 9.0), Color(AMBER.r, AMBER.g, AMBER.b, 0.85 * flick))
		draw_circle(Vector2(x, y - 2.0), 22.0, Color(AMBER.r, AMBER.g, AMBER.b, 0.06 * flick))
