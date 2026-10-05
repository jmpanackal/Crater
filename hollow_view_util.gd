extends RefCounted
## Shared helpers for the code-drawn district views (visual only).

const WARM := Color(1.0, 0.7, 0.4)
const TIN := Color(0.4, 0.42, 0.42)
const TIN_HI := Color(0.58, 0.6, 0.58)
const TIMBER := Color(0.34, 0.23, 0.15)
const IRON := Color(0.16, 0.17, 0.19)
const COPPER := Color(0.62, 0.4, 0.22)
const MARKS := [Color(0.75, 0.32, 0.25), Color(0.3, 0.55, 0.6), Color(0.8, 0.62, 0.28), Color(0.45, 0.6, 0.35), Color(0.6, 0.4, 0.6)]
const TARPS := [Color(0.5, 0.36, 0.2), Color(0.32, 0.42, 0.48), Color(0.55, 0.3, 0.24), Color(0.42, 0.4, 0.3)]


## Is the span a..b on the street of band k at deck y free of flights, ladders, lifts, gates, doors, domes' bowls and
## generated buildings, so a view may stand something there?
static func span_free(a: float, b: float, k: float, y: float) -> bool:
	for st in HollowMap.stairs():
		if absf(float(st["foot_y"]) - y) < 40.0 or absf(float(st["top_y"]) - y) < 40.0:
			var lo := minf(float(st["foot_x"]), float(st["top_x"])) - 40.0
			var hi := maxf(float(st["foot_x"]), float(st["top_x"])) + 40.0
			if b > lo and a < hi:
				return false
	for l in HollowMap.ladders():
		if absf(float(l["open_x"]) - (a + b) * 0.5) < (b - a) * 0.5 + 40.0 and (absf(float(l["top_y"]) - y) < 40.0 or absf(float(l["bottom_y"]) - y) < 40.0):
			return false
	for l in HollowMap.lifts():
		if absf(float(l["open_x"]) - (a + b) * 0.5) < (b - a) * 0.5 + 150.0:
			return false
	for g in HollowMap.gates():
		if absf(float(g["x"]) - (a + b) * 0.5) < (b - a) * 0.5 + 150.0:
			return false
	for dr in HollowMap.doors():
		if absf(float(dr["x"]) - (a + b) * 0.5) < (b - a) * 0.5 + 60.0:
			return false
	for d in HollowMap.domes():
		if absf(float(d["k"]) - k) < 0.01 and b > float(d["x0"]) - 30.0 and a < float(d["x1"]) + 30.0 and k > 3.5:
			return false
	for bd in HollowDressing.buildings():
		if absf(HollowMap.deck_y_at(float(bd["x0"]), float(bd["k"])) - y) < 40.0 and b > float(bd["x0"]) - 20.0 and a < float(bd["x1"]) + 20.0:
			return false
	return true


## A lean-to home: a plank-and-tin box with a ribbed tin roof, a patched tarp, a stoop of stacked crates, a household colour
## painted on the door frame, a number plate and a hanging pot. Drawn on `ci` standing on deck y at x.
static func lean_to(ci: CanvasItem, x: float, y: float, i: int, t: float) -> void:
	var w := 120.0 + float((i * 23) % 3) * 20.0
	var h := 96.0 + float((i * 17) % 3) * 16.0
	ci.draw_rect(Rect2(x, y - h, w, h), Color(0.3, 0.22, 0.16))
	for j in range(int(w / 12.0)):
		ci.draw_rect(Rect2(x + 3.0 + float(j) * 12.0, y - h + 6.0, 2.0, h - 10.0), Color(0.22, 0.16, 0.11))
	# a sloped ribbed tin roof
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 10.0, y - h + 4.0), Vector2(x + w + 10.0, y - h - 14.0), Vector2(x + w + 10.0, y - h - 6.0), Vector2(x - 10.0, y - h + 12.0)]), TIN)
	for j in range(int(w / 14.0) + 1):
		var rx := x - 8.0 + float(j) * 14.0
		ci.draw_line(Vector2(rx, y - h + 5.0 - (rx - x) * 0.14), Vector2(rx, y - h + 11.0 - (rx - x) * 0.14), TIN_HI, 1.5)
	# a patched tarp hung over one side
	var tarp: Color = TARPS[i % TARPS.size()]
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.5, y - h + 10.0), Vector2(x + w + 12.0, y - h + 2.0), Vector2(x + w + 16.0, y - h + 50.0), Vector2(x + w * 0.5 + 8.0, y - h + 44.0)]), tarp)
	ci.draw_rect(Rect2(x + w * 0.6, y - h + 20.0, 14.0, 10.0), tarp.lightened(0.18)) # the patch
	# the door and its household mark
	var dx := x + w * 0.3
	var mark: Color = MARKS[i % MARKS.size()]
	ci.draw_rect(Rect2(dx - 18.0, y - 62.0, 36.0, 62.0), mark.darkened(0.35))
	ci.draw_rect(Rect2(dx - 14.0, y - 58.0, 28.0, 58.0), Color(0.14, 0.1, 0.07))
	ci.draw_rect(Rect2(dx - 20.0, y - 64.0, 4.0, 64.0), mark)
	ci.draw_rect(Rect2(dx + 16.0, y - 64.0, 4.0, 64.0), mark)
	ci.draw_rect(Rect2(dx - 8.0, y - 76.0, 16.0, 9.0), Color(0.82, 0.78, 0.66))
	ci.draw_string(ThemeDB.fallback_font, Vector2(dx - 5.0, y - 68.0), str(11 + i * 3), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, Color(0.15, 0.1, 0.08))
	# the stoop: two stacked crates for steps
	ci.draw_rect(Rect2(dx - 26.0, y - 10.0, 22.0, 10.0), TIMBER)
	ci.draw_rect(Rect2(dx - 14.0, y - 20.0, 22.0, 10.0), TIMBER.lightened(0.08))
	# a hanging pot and a washing basket on the other side
	ci.draw_line(Vector2(x + w * 0.78, y - h + 14.0), Vector2(x + w * 0.78, y - 70.0), IRON, 1.5)
	ci.draw_circle(Vector2(x + w * 0.78, y - 64.0), 7.0, COPPER.darkened(0.2))
	ci.draw_rect(Rect2(x + w * 0.66, y - 22.0, 24.0, 22.0), Color(0.5, 0.38, 0.22))
	ci.draw_rect(Rect2(x + w * 0.66, y - 22.0, 24.0, 4.0), Color(0.62, 0.5, 0.3))
	# a lit window slit
	ci.draw_rect(Rect2(x + w * 0.62, y - h + 26.0, 12.0, 8.0), Color(WARM.r, WARM.g, WARM.b, 0.5 + 0.1 * sin(t * 2.0 + float(i))))


