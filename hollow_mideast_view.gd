extends Node2D
## Mid-East as one district (USER 2026-10-04: do Mid-East). Story: the middle-height trade and service band of the east wall,
## recessed lift landings (the east passenger lift up to Glowbeds and the Ashram, the heavy freight lift down to the Cistern),
## a long inhabited approach with a dispatch and checkpoint, and beyond it the Mid-East dig front: a wet, pressurized
## shock-fault and service layer. The hall H_CI now runs from this street all the way down to the Cistern floor, one
## great shaft with the freight lift in it, and this view makes the whole thing one place:
##   cold wet  a cold blue-grey wash (the only cold light on the east wall above the Cistern), seeps down the walls, drips
##             from the vault into puddles, and condensation beading on the pipes;
##   the line  fat pressure pipes along the shaft's walls with flanges, valve wheels and steam leaks, and a wall of three
##             big pressure gauges (their needles bob), a manifold fed from the Cistern tanks below;
##   the fall  a fall of seep water that drops through a drain in every bridge into the Cistern's tanks, so the two
##             districts visibly share one water cycle (Presswater);
##   Dispatch  the landmark: a tall riveted tower at the dig-front end with lit windows, a roster board, a crew queue rail and a
##             gantry hoist that carries crates to the freight lift; and a checkpoint arch at each end of the approach.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const HALL_ID := &"H_CI"
const COLD := Color(0.5, 0.68, 0.85)
const WARM := Color(1.0, 0.72, 0.4)
const WATER := Color(0.55, 0.85, 0.95)
const PIPE := Color(0.6, 0.38, 0.2) ## copper
const PIPE_HI := Color(0.88, 0.62, 0.36)
const VERDIGRIS := Color(0.32, 0.62, 0.54)
const RUST := Color(0.55, 0.3, 0.18)
const STEEL := Color(0.2, 0.23, 0.27)
const BRASS := Color(0.75, 0.58, 0.3)

const FALL_X := 9190.0
const TOWER_X0 := 8930.0
const TOWER_X1 := 9150.0

var _t := 0.0
var _rect := Rect2()
var _deck := 0.0 ## the Mid-East street (level 8)


func _ready() -> void:
	z_index = 0
	_deck = HollowMap.lvl(8.0)
	for h in HollowMap.halls():
		if h["id"] == HALL_ID:
			var top := HollowMap.lvl(float(h["k_top"])) - HollowMap.ROOM_HEIGHT
			_rect = Rect2(float(h["x0"]), top, float(h["x1"]) - float(h["x0"]), HollowMap.lvl(float(h["k_bottom"])) - top)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_screen() -> bool:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var view := inv * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	return view.grow(400.0).intersects(_rect.grow(500.0))


func _draw() -> void:
	if _rect.size == Vector2.ZERO or not _on_screen():
		return
	_wash()
	_pipes()
	_gauge_wall()
	_seeps()
	_fall()
	_catwalks()
	_tower()
	_sign(Vector2(5600.0, _deck - 170.0), "TRADE ROW")
	_sign(Vector2(6000.0, HollowMap.lvl(9.0) - 150.0), "SERVICE COURT")
	_arch(7080.0, _deck, "DISPATCH LANE")
	_arch(9230.0, _deck, "SURVEY GATE")


func _wash() -> void:
	var cols := int(ceilf(_rect.size.x / 64.0))
	var bands := 22
	for c in range(cols):
		var cx := _rect.position.x + float(c) * 64.0
		var u := (float(c) + 0.5) / float(cols)
		var edge := pow(sin(PI * u), 0.5)
		for i in range(bands):
			var f := float(i) / float(bands - 1)
			var y := _rect.position.y + _rect.size.y * float(i) / float(bands)
			# warm lantern amber through the Mid-East part, a little teal toward the water below
			var col := WARM.lerp(WATER, clampf((f - 0.5) * 2.0, 0.0, 1.0))
			draw_rect(Rect2(cx, y, 65.0, _rect.size.y / float(bands) + 1.0), Color(col.r, col.g, col.b, (0.028 + 0.02 * f) * edge))


## One pipe: a run of points drawn as a thick polyline with a lit top edge, rounded elbows and flange collars on the straights.
func _pipe(points: PackedVector2Array, w: float, col: Color = PIPE) -> void:
	draw_polyline(points, col, w)
	draw_polyline(points, Color(PIPE_HI.r, PIPE_HI.g, PIPE_HI.b, 0.35), maxf(2.0, w * 0.16))
	for i in range(points.size()):
		draw_circle(points[i], w * 0.5, col)
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var seg_len := a.distance_to(b)
		var n := int(seg_len / 170.0)
		var dir := (b - a).normalized()
		var nor := Vector2(-dir.y, dir.x)
		for k in range(1, n + 1):
			var c := a + dir * (seg_len * float(k) / float(n + 1))
			draw_line(c - nor * (w * 0.5 + 4.0), c + nor * (w * 0.5 + 4.0), VERDIGRIS.darkened(0.2), maxf(6.0, w * 0.22))
			draw_line(c - nor * (w * 0.5 + 4.0), c + nor * (w * 0.5 + 4.0), Color(VERDIGRIS.r, VERDIGRIS.g, VERDIGRIS.b, 0.6), 2.0)


func _pipes() -> void:
	var left := _rect.position.x
	var right := _rect.end.x
	var y9 := HollowMap.lvl(9.0)
	var y10 := HollowMap.lvl(10.0)
	# the main (fat) from the west wall to the lift, reducing past it to a medium pipe to the east wall
	_pipe(PackedVector2Array([Vector2(left, y9 + 60.0), Vector2(8640.0, y9 + 60.0)]), 44.0)
	draw_circle(Vector2(8648.0, y9 + 60.0), 28.0, VERDIGRIS.darkened(0.25)) # the reducer
	_pipe(PackedVector2Array([Vector2(8660.0, y9 + 60.0), Vector2(8700.0, y9 + 60.0)]), 14.0)
	_pipe(PackedVector2Array([Vector2(8880.0, y9 + 60.0), Vector2(right - 120.0, y9 + 60.0), Vector2(right - 120.0, y10 - 20.0), Vector2(right, y10 - 20.0)]), 28.0)
	# a medium pipe dropping from the main with elbows to a second run, and a thin pipe bundle along the top
	_pipe(PackedVector2Array([Vector2(8320.0, y9 + 60.0), Vector2(8320.0, y10 - 40.0), Vector2(left, y10 - 40.0)]), 24.0)
	_pipe(PackedVector2Array([Vector2(8460.0, y9 + 60.0), Vector2(8460.0, y10 + 110.0), Vector2(8640.0, y10 + 110.0)]), 18.0)
	for i in range(3):
		_pipe(PackedVector2Array([Vector2(left, _deck + 40.0 + float(i) * 12.0), Vector2(8600.0 + float(i) * 20.0, _deck + 40.0 + float(i) * 12.0), Vector2(8600.0 + float(i) * 20.0, y10 - 150.0)]), 8.0, VERDIGRIS.darkened(0.15))
	# risers up the shaft's two walls, in different sizes
	_pipe(PackedVector2Array([Vector2(left + 24.0, _deck - 30.0), Vector2(left + 24.0, HollowMap.lvl(11.0))]), 26.0)
	_pipe(PackedVector2Array([Vector2(left + 56.0, _deck + 20.0), Vector2(left + 56.0, HollowMap.lvl(11.0))]), 10.0, VERDIGRIS.darkened(0.15))
	_pipe(PackedVector2Array([Vector2(right - 24.0, _deck - 30.0), Vector2(right - 24.0, HollowMap.lvl(11.0))]), 18.0)
	_pipe(PackedVector2Array([Vector2(right - 50.0, _deck + 40.0), Vector2(right - 50.0, HollowMap.lvl(11.0))]), 8.0, VERDIGRIS.darkened(0.15))
	# valve wheels on the main, turning slowly back and forth
	for vx in [left + 300.0, left + 760.0]:
		var c := Vector2(vx, y9 + 60.0 - 40.0)
		var a := sin(_t * 0.4 + vx * 0.01) * 0.9
		draw_line(c + Vector2(0.0, 24.0), c, PIPE_HI, 5.0)
		for sp in range(4):
			var ang := a + float(sp) * PI * 0.5
			draw_line(c, c + Vector2(cos(ang), sin(ang)) * 18.0, RUST.lightened(0.2), 3.0)
		draw_circle(c, 4.0, BRASS)
	# steam leaks at three flanges: a short hiss of white puffs
	for sx in [left + 380.0, left + 840.0, right - 180.0]:
		var base := Vector2(sx, y9 + 40.0)
		for i in range(4):
			var f := fposmod(_t * 0.7 + float(i) * 0.25 + sx * 0.001, 1.0)
			draw_circle(base + Vector2(f * 26.0 * (1.0 if int(sx) % 2 == 0 else -1.0), -f * 44.0), 4.0 + 8.0 * f, Color(0.85, 0.9, 0.95, 0.22 * (1.0 - f)))
	# warm lantern posts along the hall's streets
	for lx in [8200.0, 8480.0, 9060.0]:
		var ly := HollowMap.deck_y_at(lx, 8.0)
		draw_line(Vector2(lx, ly), Vector2(lx, ly - 64.0), STEEL, 3.0)
		draw_rect(Rect2(lx - 5.0, ly - 82.0, 10.0, 16.0), Color(WARM.r, WARM.g, WARM.b, 0.95 * (0.85 + 0.15 * sin(_t * 3.0 + lx))))
		draw_circle(Vector2(lx, ly - 74.0), 46.0, Color(WARM.r, WARM.g, WARM.b, 0.07))


## A gauge cluster on a steel panel, plumbed in: a thin pipe from the bundle feeds the top of each gauge, and a stub with a
## valve under each runs down to a brass manifold that ties into the medium pipe, so the gauges read lines that really exist.
func _gauge_wall() -> void:
	var y10 := HollowMap.lvl(10.0)
	var panel := Rect2(8196.0, y10 - 230.0, 400.0, 130.0)
	draw_rect(panel, Color(0.12, 0.13, 0.15))
	draw_rect(panel, BRASS.darkened(0.3), false, 3.0)
	for bx in [panel.position.x + 8.0, panel.end.x - 8.0]:
		for by in [panel.position.y + 8.0, panel.end.y - 8.0]:
			draw_circle(Vector2(bx, by), 3.0, BRASS)
	var xs := [8260.0, 8396.0, 8532.0]
	var manifold_y := panel.end.y + 28.0
	draw_rect(Rect2(panel.position.x - 20.0, manifold_y - 8.0, panel.size.x + 40.0, 16.0), BRASS.darkened(0.15))
	draw_rect(Rect2(panel.position.x - 20.0, manifold_y - 8.0, panel.size.x + 40.0, 3.0), PIPE_HI)
	_pipe(PackedVector2Array([Vector2(8460.0, manifold_y), Vector2(8460.0, y10 - 40.0)]), 14.0)
	for i in range(3):
		var c := Vector2(xs[i], panel.position.y + 64.0)
		draw_line(Vector2(c.x, panel.position.y - 30.0), Vector2(c.x, c.y - 44.0), VERDIGRIS, 5.0)
		draw_line(Vector2(c.x, c.y + 46.0), Vector2(c.x, manifold_y), PIPE_HI, 6.0)
		draw_rect(Rect2(c.x - 9.0, c.y + 54.0, 18.0, 10.0), BRASS)
		draw_circle(c, 46.0, BRASS.darkened(0.3))
		draw_circle(c, 41.0, Color(0.8, 0.82, 0.74))
		for t in range(11):
			var a := PI * 0.8 + float(t) * (PI * 1.4 / 10.0)
			draw_line(c + Vector2(cos(a), sin(a)) * 33.0, c + Vector2(cos(a), sin(a)) * 39.0, Color(0.2, 0.2, 0.2), 2.0)
		var needle := PI * 0.8 + (0.5 + 0.35 * sin(_t * 0.7 + float(i) * 1.9)) * PI * 1.4
		draw_line(c, c + Vector2(cos(needle), sin(needle)) * 32.0, Color(0.7, 0.15, 0.12), 3.0)
		draw_circle(c, 4.0, BRASS)
		draw_circle(c + Vector2(-13.0, -15.0), 10.0, Color(1, 1, 1, 0.12))
	_pipe(PackedVector2Array([Vector2(panel.position.x - 40.0, panel.position.y - 30.0), Vector2(panel.end.x + 20.0, panel.position.y - 30.0)]), 8.0, VERDIGRIS.darkened(0.15))
	_sign(Vector2(xs[1], panel.position.y - 52.0), "PRESSURE LINE")


## Wet streaks down the shaft's walls and drips falling from the vault onto the street.
func _seeps() -> void:
	var vault_y := _rect.position.y - 120.0
	for i in range(11):
		var x := 8120.0 + float(i) * 100.0 + float((i * 37) % 40)
		draw_rect(Rect2(x, _rect.position.y + 20.0, 3.0, 200.0 + float((i * 53) % 220)), Color(WATER.r, WATER.g, WATER.b, 0.1))
	for i in range(8):
		var dx := 8200.0 + float(i) * 150.0 + float((i * 29) % 50)
		if dx > TOWER_X0 - 20.0 and dx < FALL_X + 30.0:
			continue
		var f := fposmod(_t * 0.5 + float(i) * 0.137, 1.0)
		var ground := HollowMap.deck_y_at(dx, 8.0)
		var y := vault_y + f * (ground - vault_y)
		draw_circle(Vector2(dx, y), 2.2, Color(WATER.r, WATER.g, WATER.b, 0.75))
		if f > 0.9:
			draw_arc(Vector2(dx, ground - 2.0), 3.0 + 14.0 * (f - 0.9) * 10.0, PI, TAU, 10, Color(WATER.r, WATER.g, WATER.b, 0.5 * (1.0 - (f - 0.9) * 10.0)), 1.5)


## The fall: seep water collects at the vault, drops down the shaft through a drain in every bridge, and lands in the Cistern.
func _fall() -> void:
	var top := _rect.position.y - 120.0
	var bottom := HollowMap.lvl(14.0)
	draw_rect(Rect2(FALL_X - 14.0, top, 28.0, 14.0), Color(0.4, 0.3, 0.24))
	draw_rect(Rect2(FALL_X - 6.0, top, 12.0, bottom - top), Color(WATER.r, WATER.g, WATER.b, 0.12))
	for i in range(12):
		var f := fposmod(_t * 0.55 + float(i) * 0.083 + 0.31, 1.0)
		var lane := (float(i % 3) - 1.0) * 3.0
		draw_rect(Rect2(FALL_X + lane - 1.0, top + 14.0 + f * (bottom - top - 14.0), 2.0, 18.0), Color(WATER.r, WATER.g, WATER.b, 0.55))
	for k in [8.0, 11.0, 12.0]:
		var y := HollowMap.deck_y_at(FALL_X, k)
		draw_rect(Rect2(FALL_X - 14.0, y - 2.0, 28.0, 5.0), Color(0.06, 0.07, 0.07))
		for j in range(4):
			draw_line(Vector2(FALL_X - 12.0 + float(j) * 8.0, y - 2.0), Vector2(FALL_X - 12.0 + float(j) * 8.0, y + 3.0), Color(0.4, 0.45, 0.45), 1.0)
		for r in range(2):
			var ph := fposmod(_t * 0.8 + float(r) * 0.5, 1.0)
			draw_arc(Vector2(FALL_X, y - 3.0), 6.0 + 16.0 * ph, PI, TAU, 12, Color(WATER.r, WATER.g, WATER.b, 0.5 * (1.0 - ph)), 1.5)
	for m in range(5):
		var ph2 := fposmod(_t * 0.35 + float(m) * 0.2, 1.0)
		draw_circle(Vector2(FALL_X + (float(m) - 2.0) * 8.0, bottom - 8.0 - ph2 * 24.0), 6.0 + 9.0 * ph2, Color(WATER.r, WATER.g, WATER.b, 0.1 * (1.0 - ph2)))


## Dispatch: the landmark. A tall riveted tower where the approach meets the dig front, with a crew queue rail, a roster
## board, lit windows, a vent stack and a gantry hoist that carries crates out to the freight lift.
func _tower() -> void:
	var x0 := TOWER_X0
	var x1 := TOWER_X1
	var h := 440.0
	var top := _deck - h
	draw_rect(Rect2(x0, top, x1 - x0, h), Color(0.2, 0.24, 0.29))
	draw_rect(Rect2(x0 - 8.0, top - 12.0, x1 - x0 + 16.0, 16.0), STEEL)
	for row in range(int(h / 40.0)):
		var by := top + float(row) * 40.0
		draw_line(Vector2(x0, by), Vector2(x1, by), Color(0.1, 0.12, 0.15, 0.7), 1.5)
	for col in range(int((x1 - x0) / 44.0)):
		for row in range(1, int(h / 40.0) - 1, 2):
			draw_circle(Vector2(x0 + 22.0 + float(col) * 44.0, top + float(row) * 40.0 + 2.0), 1.6, Color(0.5, 0.55, 0.6, 0.8))
	# windows in three tiers, cold white with a few amber
	for tier in range(3):
		for i in range(3):
			var wx := x0 + 24.0 + float(i) * 68.0
			var wy := top + 50.0 + float(tier) * 110.0
			var flick := 0.8 + 0.2 * sin(_t * 2.6 + float(i + tier * 3))
			var warm := (i + tier) % 4 == 0
			var col := Color(1.0, 0.75, 0.4) if warm else Color(0.8, 0.92, 1.0)
			draw_rect(Rect2(wx, wy, 36.0, 52.0), Color(0.05, 0.07, 0.09))
			draw_rect(Rect2(wx + 3.0, wy + 3.0, 30.0, 46.0), Color(col.r, col.g, col.b, 0.75 * flick))
			draw_circle(Vector2(wx + 18.0, wy + 26.0), 38.0, Color(col.r, col.g, col.b, 0.04 * flick))
	# the roster board and the crew queue rail at the foot
	draw_rect(Rect2(x0 + 18.0, _deck - 140.0, 100.0, 70.0), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(x0 + 22.0, _deck - 136.0, 92.0, 62.0), Color(0.32, 0.28, 0.2))
	for i in range(6):
		draw_rect(Rect2(x0 + 28.0 + float(i % 3) * 28.0, _deck - 128.0 + float(i / 3) * 28.0, 22.0, 20.0), Color(0.8, 0.74, 0.58))
	draw_rect(Rect2(x0 - 130.0, _deck - 30.0, 124.0, 4.0), STEEL)
	for rx in [x0 - 126.0, x0 - 70.0, x0 - 12.0]:
		draw_rect(Rect2(rx, _deck - 30.0, 4.0, 30.0), STEEL)
	# a door and a vent stack with a plume
	draw_rect(Rect2(x1 - 66.0, _deck - 72.0, 40.0, 72.0), Color(0.08, 0.09, 0.1))
	draw_rect(Rect2(x0 + 150.0, top - 56.0, 30.0, 56.0), PIPE)
	for i in range(4):
		var f := fposmod(_t * 0.25 + float(i) * 0.25, 1.0)
		draw_circle(Vector2(x0 + 165.0 + sin(f * 6.0 + float(i)) * 10.0, top - 64.0 - f * 50.0), 8.0 + 12.0 * f, Color(0.8, 0.85, 0.9, 0.2 * (1.0 - f)))
	# the gantry hoist: a beam out toward the freight lift (x 8704..8864), a trolley and a crate on a cycle
	var beam_y := top + 230.0
	draw_rect(Rect2(8740.0, beam_y, x0 - 8740.0 + 20.0, 8.0), STEEL)
	draw_line(Vector2(8760.0, beam_y + 8.0), Vector2(8800.0, beam_y + 60.0), STEEL, 3.0)
	var cyc := fposmod(_t, 14.0) / 14.0
	var tx := lerpf(x0 - 20.0, 8780.0, 0.5 - 0.5 * cos(cyc * TAU))
	var drop := 40.0 + 60.0 * (0.5 - 0.5 * cos(cyc * TAU * 2.0))
	draw_rect(Rect2(tx - 12.0, beam_y - 6.0, 24.0, 12.0), BRASS)
	draw_line(Vector2(tx, beam_y + 6.0), Vector2(tx, beam_y + 6.0 + drop), PIPE_HI, 2.0)
	draw_rect(Rect2(tx - 15.0, beam_y + 6.0 + drop, 30.0, 22.0), Color(0.4, 0.3, 0.22))
	_sign(Vector2((x0 + x1) * 0.5, top - 30.0), "DISPATCH")


## Railed catwalks on every bridge in the shaft, with lantern posts, crate stacks and gas cylinders (the Cistern reference look).
## Skips the lift shaft and the fall; only ever draws over the bridge's own deck.
func _catwalks() -> void:
	var hx0 := _rect.position.x
	var hx1 := _rect.end.x
	var n := 0
	for r in HollowMap.runs():
		var k := float(r["k"])
		if k < 8.0 - 0.01 or k >= 14.0 - 0.01 or HollowMap.is_heart_zone(r["zone"]):
			continue
		var x0 := maxf(float(r["x0"]), hx0 + 24.0)
		var x1 := minf(float(r["x1"]), hx1 - 24.0)
		if x1 - x0 < 128.0:
			continue
		var y := float(r["y"])
		var x := x0
		while x < x1:
			var gap := (x > 8600.0 and x < 8810.0) or absf(x - FALL_X) < 40.0
			if not gap:
				draw_rect(Rect2(x - 2.0, y - 34.0, 4.0, 34.0), STEEL)
				if x + 32.0 < x1 and not ((x + 32.0 > 8600.0 and x + 32.0 < 8810.0) or absf(x + 32.0 - FALL_X) < 40.0):
					draw_line(Vector2(x, y - 34.0), Vector2(x + 32.0, y - 34.0), PIPE_HI, 3.0)
					draw_line(Vector2(x, y - 17.0), Vector2(x + 32.0, y - 17.0), STEEL, 2.0)
			x += 32.0
		# lantern posts and stacked cargo, spaced by run so no two decks match
		var px := x0 + 90.0 + float((n * 131) % 160)
		while px < x1 - 120.0:
			var blocked := (px > 8560.0 and px < 8850.0) or absf(px - FALL_X) < 90.0 or (px > TOWER_X0 - 40.0 and px < TOWER_X1 + 40.0 and absf(y - _deck) < 2.0)
			if not blocked:
				var kind := int(floorf(px / 97.0)) % 3
				if kind == 0:
					_crates(px, y)
				elif kind == 1:
					_cylinders(px, y)
				else:
					_lantern(px, y)
			px += 260.0 + float((int(px) * 7) % 140)
		n += 1


func _crates(x: float, y: float) -> void:
	draw_rect(Rect2(x, y - 30.0, 34.0, 30.0), RUST.darkened(0.3))
	draw_rect(Rect2(x, y - 30.0, 34.0, 4.0), RUST)
	draw_line(Vector2(x, y - 30.0), Vector2(x + 34.0, y), RUST.darkened(0.5), 2.0)
	draw_rect(Rect2(x + 6.0, y - 58.0, 26.0, 28.0), RUST.darkened(0.15))
	draw_rect(Rect2(x + 6.0, y - 58.0, 26.0, 4.0), RUST.lightened(0.1))
	draw_rect(Rect2(x + 36.0, y - 22.0, 22.0, 22.0), RUST.darkened(0.4))


func _cylinders(x: float, y: float) -> void:
	for i in range(3):
		var cx := x + float(i) * 16.0
		var col := VERDIGRIS.darkened(0.25 + 0.1 * float(i % 2))
		draw_rect(Rect2(cx, y - 42.0, 12.0, 42.0), col)
		draw_circle(Vector2(cx + 6.0, y - 42.0), 6.0, col)
		draw_rect(Rect2(cx + 4.0, y - 52.0, 4.0, 6.0), BRASS)
		draw_rect(Rect2(cx, y - 24.0, 12.0, 3.0), BRASS.darkened(0.3))
	draw_line(Vector2(x - 2.0, y - 14.0), Vector2(x + 50.0, y - 14.0), STEEL, 2.0)


func _lantern(x: float, y: float) -> void:
	draw_rect(Rect2(x - 2.0, y - 96.0, 4.0, 96.0), STEEL)
	draw_line(Vector2(x, y - 96.0), Vector2(x + 16.0, y - 96.0), STEEL, 3.0)
	var flick := 0.8 + 0.2 * sin(_t * 5.0 + x)
	draw_circle(Vector2(x + 16.0, y - 88.0), 26.0, Color(WARM.r, WARM.g, WARM.b, 0.07 * flick))
	draw_rect(Rect2(x + 12.0, y - 94.0, 8.0, 12.0), Color(WARM.r, WARM.g, WARM.b, 0.95))


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.07, 0.09, 0.11, 0.9))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.55, 0.78, 0.9, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.8, 0.95, 1.0, 0.95))


func _arch(x: float, y: float, text: String) -> void:
	var w := 110.0
	var h := 150.0
	draw_rect(Rect2(x - w * 0.5, y - h, 12.0, h), STEEL)
	draw_rect(Rect2(x + w * 0.5 - 12.0, y - h, 12.0, h), STEEL)
	draw_rect(Rect2(x - w * 0.5 - 6.0, y - h - 12.0, w + 12.0, 14.0), STEEL)
	for rx in [x - w * 0.5 + 6.0, x + w * 0.5 - 6.0]:
		for ry in range(4):
			draw_circle(Vector2(rx, y - h + 16.0 + float(ry) * 34.0), 2.0, VERDIGRIS)
	var tw := 9.0 * float(text.length()) + 16.0
	draw_rect(Rect2(x - tw * 0.5, y - h - 10.0, tw, 16.0), Color(0.07, 0.09, 0.11, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(x - tw * 0.5 + 8.0, y - h + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.8, 0.95, 1.0, 0.95))
	draw_circle(Vector2(x, y - h + 28.0), 5.0, Color(0.85, 0.95, 1.0, 0.95))
	draw_circle(Vector2(x, y - h + 28.0), 24.0, Color(COLD.r, COLD.g, COLD.b, 0.07))
