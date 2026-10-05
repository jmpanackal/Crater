extends Node2D
## The Lower-East Homes as one district (USER 2026-10-04: do the Lower-East homes). Canon: the lowest housing tier, crowded and
## practical, compact improvised homes with stoops, painted marks and shared courts; open terraces host the wash court, repair
## queue and freight staging; the services band below is a rail-cart freight yard with clinic and repair alcoves; the water is
## the Cistern's, so the standpipe is the heart of the street. Wicklamp amber with a little cool Cistern light.
##   Standpipe Court  the landmark, on the L10 street: a public standpipe fed by a copper pipe from the ceiling, a valve wheel,
##                    a trough, a queue rail with painted queue marks, a long shared table and a tarp shelter; laundry strung
##                    across the street, steam from a shared cookstove;
##   the Rows         lean-to homes in the gaps: tin-ribbed roofs, patched tarps, stacked crates for steps, painted door
##                    marks (each household's colour), a number plate and a hanging pot;
##   the balcony      the Mouth balcony gets a rail, a plant box, a bench and a lantern;
##   Freight Yard     L11: two rails with ties along the deck (following the terraces), parked carts, a loading platform and
##                    a hoist arm, a clinic alcove with a cool lamp, a repair alcove with a bench and tools.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const WARM := Color(1.0, 0.7, 0.4)
const COOL := Color(0.5, 0.8, 0.85)
const TIN := Color(0.4, 0.42, 0.42)
const TIN_HI := Color(0.58, 0.6, 0.58)
const TIMBER := Color(0.34, 0.23, 0.15)
const STONE := Color(0.34, 0.32, 0.3)
const COPPER := Color(0.62, 0.4, 0.22)
const COPPER_HI := Color(0.88, 0.62, 0.36)
const IRON := Color(0.16, 0.17, 0.19)
const MARKS := [Color(0.75, 0.32, 0.25), Color(0.3, 0.55, 0.6), Color(0.8, 0.62, 0.28), Color(0.45, 0.6, 0.35), Color(0.6, 0.4, 0.6)]
const TARPS := [Color(0.5, 0.36, 0.2), Color(0.32, 0.42, 0.48), Color(0.55, 0.3, 0.24), Color(0.42, 0.4, 0.3)]

const COURT_X := 6440.0 ## Standpipe Court spans COURT_X .. COURT_X + 460 on the L10 street
const K_HOMES := 10.0
const K_YARD := 11.0

var _t := 0.0
var _view := Rect2()
var _lean_tos: Array[float] = [6190.0, 6930.0, 7330.0, 7760.0]


func _ready() -> void:
	z_index = 0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport()
	_view = (vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)).grow(300.0)
	if not _view.intersects(Rect2(4600.0, HollowMap.lvl(9.5), 4800.0, HollowMap.lvl(12.0) - HollowMap.lvl(9.5))):
		return
	_court()
	for i in range(_lean_tos.size()):
		_lean_to(_lean_tos[i], i)
	_balcony()
	_laundry_lines()
	_yard()
	_sign(Vector2(5840.0, HollowMap.deck_y_at(5840.0, K_HOMES) - 200.0), "LOWER-EAST ROWS")
	_sign(Vector2(COURT_X + 230.0, HollowMap.deck_y_at(COURT_X + 230.0, K_HOMES) - 214.0), "STANDPIPE COURT")
	_sign(Vector2(7300.0, HollowMap.deck_y_at(7300.0, K_YARD) - 210.0), "FREIGHT YARD")


## ---------------------------------------------------------------- Standpipe Court

func _court() -> void:
	var y := HollowMap.deck_y_at(COURT_X + 200.0, K_HOMES)
	if not _view.intersects(Rect2(COURT_X - 40.0, y - 260.0, 540.0, 270.0)):
		return
	var cx := COURT_X + 230.0
	# the copper feed pipe down from the ceiling, a valve wheel, and the standpipe with its spout and trough
	var ceiling := y - HollowMap.ROOM_HEIGHT
	draw_rect(Rect2(cx - 9.0, ceiling, 18.0, y - 70.0 - ceiling), COPPER)
	draw_rect(Rect2(cx - 9.0, ceiling, 4.0, y - 70.0 - ceiling), COPPER_HI)
	for cy in [ceiling + 40.0, ceiling + 120.0]:
		draw_rect(Rect2(cx - 13.0, cy, 26.0, 8.0), Color(0.32, 0.62, 0.54).darkened(0.2))
	draw_rect(Rect2(cx - 14.0, y - 70.0, 28.0, 56.0), COPPER.darkened(0.15))
	draw_rect(Rect2(cx - 14.0, y - 70.0, 5.0, 56.0), COPPER_HI)
	draw_rect(Rect2(cx - 4.0, y - 52.0, 40.0, 8.0), COPPER) # the spout
	draw_rect(Rect2(cx + 32.0, y - 52.0, 6.0, 14.0), COPPER_HI)
	var wheel := Vector2(cx - 26.0, y - 104.0)
	draw_circle(wheel, 11.0, IRON)
	draw_circle(wheel, 8.0, Color(0, 0, 0, 0))
	for s in range(4):
		var a := float(s) * PI * 0.25 + _t * 0.0
		draw_line(wheel - Vector2(cos(a), sin(a)) * 11.0, wheel + Vector2(cos(a), sin(a)) * 11.0, COPPER_HI, 2.0)
	draw_line(wheel, Vector2(cx - 9.0, y - 104.0), COPPER, 3.0)
	# water from the spout into the trough, a thin falling thread and ripples
	draw_line(Vector2(cx + 35.0, y - 38.0), Vector2(cx + 35.0, y - 22.0), Color(0.6, 0.88, 0.95, 0.8), 2.0)
	draw_rect(Rect2(cx - 10.0, y - 22.0, 90.0, 22.0), TIMBER.darkened(0.2))
	draw_rect(Rect2(cx - 6.0, y - 22.0, 82.0, 6.0), Color(0.4, 0.72, 0.8, 0.85))
	for i in range(3):
		var f := fposmod(_t * 0.8 + float(i) * 0.33, 1.0)
		draw_rect(Rect2(cx + 34.0 + (f - 0.5) * 30.0, y - 20.0, 6.0 + f * 8.0, 1.5), Color(0.85, 0.97, 1.0, 0.6 * (1.0 - f)))
	# the queue rail with painted queue marks, and the people-shaped gaps they leave
	var qx0 := cx - 190.0
	for i in range(7):
		var px := qx0 + float(i) * 22.0
		draw_rect(Rect2(px, y - 38.0, 3.0, 38.0), IRON)
		draw_circle(Vector2(px + 1.5, y - 4.0), 5.0, Color(0.8, 0.62, 0.28, 0.35))
	draw_line(Vector2(qx0, y - 36.0), Vector2(qx0 + 132.0, y - 36.0), TIN_HI, 3.0)
	draw_line(Vector2(qx0, y - 22.0), Vector2(qx0 + 132.0, y - 22.0), IRON, 2.0)
	# a long shared table with benches and mugs
	var tx := cx + 110.0
	draw_rect(Rect2(tx, y - 38.0, 150.0, 6.0), TIMBER)
	draw_rect(Rect2(tx + 8.0, y - 32.0, 6.0, 32.0), TIMBER)
	draw_rect(Rect2(tx + 136.0, y - 32.0, 6.0, 32.0), TIMBER)
	draw_rect(Rect2(tx, y - 18.0, 150.0, 5.0), TIMBER.darkened(0.2))
	for i in range(5):
		draw_rect(Rect2(tx + 14.0 + float(i) * 26.0, y - 47.0, 8.0, 9.0), MARKS[i % MARKS.size()].darkened(0.1))
	# a tarp shelter over the table, with a lantern
	var tarp: Color = TARPS[1]
	draw_colored_polygon(PackedVector2Array([Vector2(tx - 12.0, y - 110.0), Vector2(tx + 162.0, y - 110.0), Vector2(tx + 176.0, y - 88.0), Vector2(tx - 26.0, y - 88.0)]), tarp)
	for px in [tx - 10.0, tx + 160.0]:
		draw_rect(Rect2(px - 2.0, y - 110.0, 4.0, 110.0), TIMBER)
	_lantern(Vector2(tx + 75.0, y - 74.0))
	# the shared cookstove with a stovepipe and steam
	var sx := cx - 280.0
	draw_rect(Rect2(sx, y - 46.0, 40.0, 46.0), IRON)
	draw_rect(Rect2(sx + 4.0, y - 30.0, 32.0, 14.0), Color(1.0, 0.55, 0.2, 0.7 + 0.2 * sin(_t * 7.0)))
	draw_rect(Rect2(sx + 28.0, y - 150.0, 8.0, 104.0), IRON.lightened(0.1))
	for i in range(4):
		var f := fposmod(_t * 0.35 + float(i) * 0.25, 1.0)
		draw_circle(Vector2(sx + 32.0 + sin(f * 7.0 + float(i)) * 8.0, y - 150.0 - f * 70.0), 5.0 + 9.0 * f, Color(0.8, 0.82, 0.85, 0.22 * (1.0 - f)))
	# a soft pool of amber on the court
	draw_circle(Vector2(cx, y - 60.0), 150.0, Color(WARM.r, WARM.g, WARM.b, 0.04))


## ---------------------------------------------------------------- the Rows

## A lean-to home squeezed into a gap: a plank-and-tin box with a ribbed tin roof, a patched tarp, a stoop of stacked crates,
## a household colour painted on the door frame, a number plate and a hanging pot.
func _lean_to(x: float, i: int) -> void:
	var y := HollowMap.deck_y_at(x + 70.0, K_HOMES)
	if not _view.intersects(Rect2(x - 10.0, y - 190.0, 200.0, 200.0)):
		return
	var w := 120.0 + float((i * 23) % 3) * 20.0
	var h := 96.0 + float((i * 17) % 3) * 16.0
	draw_rect(Rect2(x, y - h, w, h), Color(0.3, 0.22, 0.16))
	for j in range(int(w / 12.0)):
		draw_rect(Rect2(x + 3.0 + float(j) * 12.0, y - h + 6.0, 2.0, h - 10.0), Color(0.22, 0.16, 0.11))
	# a sloped ribbed tin roof
	draw_colored_polygon(PackedVector2Array([Vector2(x - 10.0, y - h + 4.0), Vector2(x + w + 10.0, y - h - 14.0), Vector2(x + w + 10.0, y - h - 6.0), Vector2(x - 10.0, y - h + 12.0)]), TIN)
	for j in range(int(w / 14.0) + 1):
		var rx := x - 8.0 + float(j) * 14.0
		draw_line(Vector2(rx, y - h + 5.0 - (rx - x) * 0.14), Vector2(rx, y - h + 11.0 - (rx - x) * 0.14), TIN_HI, 1.5)
	# a patched tarp hung over one side
	var tarp: Color = TARPS[i % TARPS.size()]
	draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.5, y - h + 10.0), Vector2(x + w + 12.0, y - h + 2.0), Vector2(x + w + 16.0, y - h + 50.0), Vector2(x + w * 0.5 + 8.0, y - h + 44.0)]), tarp)
	draw_rect(Rect2(x + w * 0.6, y - h + 20.0, 14.0, 10.0), tarp.lightened(0.18)) # the patch
	# the door and its household mark
	var dx := x + w * 0.3
	var mark: Color = MARKS[i % MARKS.size()]
	draw_rect(Rect2(dx - 18.0, y - 62.0, 36.0, 62.0), mark.darkened(0.35))
	draw_rect(Rect2(dx - 14.0, y - 58.0, 28.0, 58.0), Color(0.14, 0.1, 0.07))
	draw_rect(Rect2(dx - 20.0, y - 64.0, 4.0, 64.0), mark)
	draw_rect(Rect2(dx + 16.0, y - 64.0, 4.0, 64.0), mark)
	draw_rect(Rect2(dx - 8.0, y - 76.0, 16.0, 9.0), Color(0.82, 0.78, 0.66))
	draw_string(ThemeDB.fallback_font, Vector2(dx - 5.0, y - 68.0), str(11 + i * 3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, Color(0.15, 0.1, 0.08))
	# the stoop: two stacked crates for steps
	draw_rect(Rect2(dx - 26.0, y - 10.0, 22.0, 10.0), TIMBER)
	draw_rect(Rect2(dx - 14.0, y - 20.0, 22.0, 10.0), TIMBER.lightened(0.08))
	# a hanging pot and a washing basket on the other side
	draw_line(Vector2(x + w * 0.78, y - h + 14.0), Vector2(x + w * 0.78, y - 70.0), IRON, 1.5)
	draw_circle(Vector2(x + w * 0.78, y - 64.0), 7.0, COPPER.darkened(0.2))
	draw_rect(Rect2(x + w * 0.66, y - 22.0, 24.0, 22.0), Color(0.5, 0.38, 0.22))
	draw_rect(Rect2(x + w * 0.66, y - 22.0, 24.0, 4.0), Color(0.62, 0.5, 0.3))
	# a lit window slit
	draw_rect(Rect2(x + w * 0.62, y - h + 26.0, 12.0, 8.0), Color(WARM.r, WARM.g, WARM.b, 0.5 + 0.1 * sin(_t * 2.0 + float(i))))


## ---------------------------------------------------------------- the balcony

func _balcony() -> void:
	var x0 := 4704.0
	var x1 := 5136.0
	var y := HollowMap.deck_y_at(4900.0, K_HOMES)
	if not _view.intersects(Rect2(x0, y - 120.0, x1 - x0, 130.0)):
		return
	var x := x0 + 4.0
	while x <= x1 - 40.0:
		draw_rect(Rect2(x, y - 34.0, 3.0, 34.0), IRON)
		x += 24.0
	draw_line(Vector2(x0, y - 34.0), Vector2(x1 - 40.0, y - 34.0), TIN_HI, 3.0)
	draw_line(Vector2(x0, y - 18.0), Vector2(x1 - 40.0, y - 18.0), IRON, 2.0)
	# a plant box of fungal herbs and a bench to look out from
	draw_rect(Rect2(x0 + 40.0, y - 18.0, 56.0, 18.0), TIMBER.darkened(0.15))
	for i in range(6):
		draw_circle(Vector2(x0 + 48.0 + float(i) * 9.0, y - 24.0 - float((i * 5) % 7)), 5.0, Color(0.3, 0.6, 0.4))
	draw_rect(Rect2(x0 + 190.0, y - 22.0, 70.0, 6.0), TIMBER)
	draw_rect(Rect2(x0 + 196.0, y - 16.0, 5.0, 16.0), TIMBER)
	draw_rect(Rect2(x0 + 250.0, y - 16.0, 5.0, 16.0), TIMBER)
	_lantern(Vector2(x0 + 150.0, y - 96.0))
	draw_line(Vector2(x0 + 150.0, y - 96.0), Vector2(x0 + 150.0, y - 110.0), IRON, 1.5)


## ---------------------------------------------------------------- laundry

## Washing strung across the Rows between posts, swaying, in the households' colours.
func _laundry_lines() -> void:
	for seg in [[5900.0, 6180.0], [6920.0, 7340.0], [7400.0, 7740.0]]:
		var y := HollowMap.deck_y_at(float(seg[0]), K_HOMES)
		if not _view.intersects(Rect2(float(seg[0]), y - 220.0, float(seg[1]) - float(seg[0]), 120.0)):
			continue
		var a := Vector2(float(seg[0]), y - 176.0)
		var b := Vector2(float(seg[1]), y - 190.0)
		var prev := a
		for s in range(1, 11):
			var f := float(s) / 10.0
			var p := a.lerp(b, f) + Vector2(0.0, sin(f * PI) * 22.0)
			draw_line(prev, p, Color(0.25, 0.2, 0.14, 0.9), 1.5)
			if s % 2 == 0 and s < 10:
				var c: Color = MARKS[(s + int(float(seg[0]) / 16.0)) % MARKS.size()].lightened(0.1)
				var sway := sin(_t * 1.1 + f * 7.0) * 2.5
				draw_colored_polygon(PackedVector2Array([p + Vector2(-7.0, 0.0), p + Vector2(7.0, 0.0), p + Vector2(7.0 + sway, 30.0), p + Vector2(-7.0 + sway, 30.0)]), c)
			prev = p


## ---------------------------------------------------------------- Freight Yard (L11)

func _yard() -> void:
	var x0 := 6960.0
	var x1 := 9040.0
	var y0 := HollowMap.deck_y_at(7200.0, K_YARD)
	if not _view.intersects(Rect2(x0, y0 - 230.0, x1 - x0, 260.0)):
		return
	# two rails following the deck, with ties
	for rail in range(2):
		var x := x0
		while x < x1:
			var ya := HollowMap.deck_y_at(x, K_YARD)
			var yb := HollowMap.deck_y_at(x + 32.0, K_YARD)
			var shaft := x + 32.0 > 8600.0 and x < 8810.0
			if absf(ya - yb) < 0.5 and not shaft:
				draw_line(Vector2(x, ya - 6.0 - float(rail) * 5.0), Vector2(x + 32.0, yb - 6.0 - float(rail) * 5.0), TIN_HI if rail == 0 else IRON, 2.0)
			x += 32.0
	var tx := x0
	while tx < x1:
		if not (tx > 8600.0 and tx < 8810.0):
			var ty := HollowMap.deck_y_at(tx, K_YARD)
			draw_rect(Rect2(tx, ty - 6.0, 10.0, 6.0), TIMBER.darkened(0.3))
		tx += 44.0
	# a short train of parked carts
	for cx in [7000.0, 7080.0, 7160.0, 8000.0, 8084.0]:
		_cart(cx)
	# the loading platform with a hoist arm and a hanging crate
	var px := 8300.0
	var py := HollowMap.deck_y_at(px, K_YARD)
	draw_rect(Rect2(px, py - 36.0, 190.0, 8.0), TIMBER)
	draw_rect(Rect2(px + 8.0, py - 28.0, 8.0, 28.0), TIMBER)
	draw_rect(Rect2(px + 172.0, py - 28.0, 8.0, 28.0), TIMBER)
	draw_rect(Rect2(px + 150.0, py - 190.0, 8.0, 154.0), IRON)
	var arm_end := Vector2(px + 40.0 + sin(_t * 0.4) * 6.0, py - 176.0)
	draw_line(Vector2(px + 154.0, py - 190.0), arm_end, IRON.lightened(0.1), 6.0)
	draw_line(arm_end, arm_end + Vector2(0.0, 40.0), COPPER, 2.0)
	draw_rect(Rect2(arm_end.x - 14.0, arm_end.y + 40.0, 28.0, 24.0), Color(0.4, 0.28, 0.18))
	# a clinic alcove: a cool lamp over a pale door, with a bench and a stretcher
	var cx := 7020.0
	var cy := HollowMap.deck_y_at(cx, K_YARD)
	draw_rect(Rect2(cx - 30.0, cy - 118.0, 120.0, 118.0), Color(0.2, 0.24, 0.26))
	draw_rect(Rect2(cx - 4.0, cy - 66.0, 36.0, 66.0), Color(0.55, 0.62, 0.6))
	draw_circle(Vector2(cx + 14.0, cy - 66.0), 18.0, Color(0.55, 0.62, 0.6))
	draw_circle(Vector2(cx + 14.0, cy - 100.0), 20.0, Color(COOL.r, COOL.g, COOL.b, 0.1))
	draw_circle(Vector2(cx + 14.0, cy - 100.0), 6.0, COOL)
	draw_rect(Rect2(cx + 44.0, cy - 20.0, 40.0, 5.0), TIMBER)
	draw_rect(Rect2(cx + 46.0, cy - 15.0, 4.0, 15.0), TIMBER)
	draw_rect(Rect2(cx + 78.0, cy - 15.0, 4.0, 15.0), TIMBER)
	# a repair alcove: a bench, hanging tools and a vise
	var rx := 8620.0
	var ry := HollowMap.deck_y_at(rx, K_YARD)
	if rx > 8600.0 and rx < 8810.0:
		rx = 8830.0
	draw_rect(Rect2(rx, ry - 34.0, 90.0, 6.0), TIMBER)
	draw_rect(Rect2(rx + 6.0, ry - 28.0, 6.0, 28.0), TIMBER)
	draw_rect(Rect2(rx + 78.0, ry - 28.0, 6.0, 28.0), TIMBER)
	draw_rect(Rect2(rx + 60.0, ry - 46.0, 16.0, 12.0), IRON)
	for i in range(4):
		draw_line(Vector2(rx + 8.0 + float(i) * 18.0, ry - 118.0), Vector2(rx + 8.0 + float(i) * 18.0, ry - 92.0 - float(i % 2) * 8.0), TIN_HI, 2.0)
	draw_rect(Rect2(rx - 4.0, ry - 122.0, 100.0, 4.0), TIMBER)
	_lantern(Vector2(rx + 45.0, ry - 150.0))


func _cart(x: float) -> void:
	var y := HollowMap.deck_y_at(x, K_YARD) - 10.0
	draw_rect(Rect2(x, y - 30.0, 64.0, 24.0), Color(0.34, 0.24, 0.16))
	draw_rect(Rect2(x, y - 34.0, 64.0, 5.0), Color(0.46, 0.34, 0.22))
	draw_circle(Vector2(x + 14.0, y - 2.0), 6.0, IRON)
	draw_circle(Vector2(x + 50.0, y - 2.0), 6.0, IRON)
	for j in range(3):
		draw_circle(Vector2(x + 14.0 + float(j) * 18.0, y - 38.0), 7.0, Color(0.3, 0.24, 0.2))


## ---------------------------------------------------------------- bits

func _lantern(p: Vector2) -> void:
	var f := 0.85 + 0.15 * sin(_t * 6.0 + p.x * 0.1)
	draw_circle(p, 28.0, Color(WARM.r, WARM.g, WARM.b, 0.07 * f))
	draw_rect(Rect2(p.x - 4.0, p.y - 10.0, 8.0, 4.0), IRON)
	draw_rect(Rect2(p.x - 4.0, p.y - 6.0, 8.0, 12.0), Color(WARM.r, WARM.g, WARM.b, 0.95))
	draw_rect(Rect2(p.x - 5.0, p.y + 6.0, 10.0, 3.0), IRON)


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.1, 0.08, 0.07, 0.92))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.8, 0.62, 0.35, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 0.85, 0.65, 0.95))
