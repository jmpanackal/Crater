extends Node2D
## The lower west: the Lower Mouth Rows (L13-L17, the lowest housing tier's overflow on the west cliff) and Bottom-West (L13-L17
## flank galleries, where public lateral mining is taught). USER 2026-10-04 asked for every district to be a cohesive place with
## working areas and a landmark; AI-built from canon (lowest tier: crowded, practical, shared courts; Bottom-West: the public
## teaching dig, timber-shored galleries, cart rails, assay and permits, deeper galleries behind a gate).
##   the Rows       lean-to homes along every row (the shared lean-to drawing in hollow_view_util.gd), laundry strung across,
##                  a stoop-and-awning feel; the landmark is the **Well Rope**: a timber gantry over the Mouth edge on the
##                  first row with a windlass and a bucket on a long rope that runs down toward the pool;
##   Bottom-West    timber shoring frames every few bays with braces and lintels, a sagging cable of work lamps between them,
##                  rails and ore carts on the floor, sack stacks and pick racks, a fresh dig face at each gallery's end with
##                  ore flecks glinting in the rock, and a "TEACHING FACE" sign at the first gallery; the deeper galleries
##                  (gated) get colder, sparser lamps.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const Util := preload("res://hollow_view_util.gd")
const WARM := Color(1.0, 0.7, 0.4)
const COOL := Color(0.5, 0.8, 0.85)
const TIMBER := Color(0.36, 0.25, 0.16)
const TIMBER_HI := Color(0.52, 0.38, 0.24)
const IRON := Color(0.16, 0.17, 0.19)
const TIN_HI := Color(0.58, 0.6, 0.58)
const ORE := Color(0.85, 0.7, 0.35)
const MARKS := [Color(0.75, 0.32, 0.25), Color(0.3, 0.55, 0.6), Color(0.8, 0.62, 0.28), Color(0.45, 0.6, 0.35), Color(0.6, 0.4, 0.6)]

var _t := 0.0
var _view := Rect2()
var _homes: Array[Dictionary] = []
var _frames: Array[Dictionary] = []


func _ready() -> void:
	z_index = 0
	_plan()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Planned once: where every lean-to and every shoring frame stands.
func _plan() -> void:
	for r in HollowMap.runs():
		var zone := str(r["zone"])
		var x0: float = r["x0"]
		var x1: float = r["x1"]
		var y: float = r["y"]
		var k: float = r["k"]
		if bool(r["landing"]) or x1 - x0 < 240.0:
			continue
		if zone.begins_with("lower_rows"):
			var x := x0 + 70.0 + float(int(absf(x0)) % 60)
			var i := 0
			while x + 150.0 < x1 - 40.0:
				if Util.span_free(x - 20.0, x + 170.0, k, y):
					_homes.append({"x": x, "y": y, "i": i + int(absf(x0) / 16.0)})
					x += 230.0 + float((i * 41) % 90)
				else:
					x += 50.0
				i += 1
		elif zone.begins_with("bottom_west"):
			var fx := x0 + 96.0
			var j := 0
			while fx < x1 - 60.0:
				if Util.span_free(fx - 30.0, fx + 30.0, k, y):
					_frames.append({"x": fx, "y": y, "k": k, "j": j, "deep": zone.begins_with("bottom_west_de") or zone == "bottom_west_lowest", "first": fx < x0 + 100.0, "x0": x0, "x1": x1})
				fx += 176.0
				j += 1


func _draw() -> void:
	var vp := get_viewport()
	_view = (vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)).grow(300.0)
	if _view.position.y > HollowMap.lvl(18.0):
		return
	if _view.end.y < HollowMap.lvl(12.5):
		return
	for h in _homes:
		if _view.intersects(Rect2(h["x"] - 10.0, h["y"] - 190.0, 200.0, 200.0)):
			Util.lean_to(self, h["x"], h["y"], h["i"], _t)
	_laundry()
	_well_rope()
	for f in _frames:
		if _view.intersects(Rect2(f["x"] - 100.0, f["y"] - 260.0, 200.0, 270.0)):
			_frame(f)
	_gallery_extras()
	for r in HollowMap.runs():
		if str(r["zone"]).begins_with("bottom_west") and not bool(r["landing"]):
			_dig_face(r)
			_rails(r)
	_sign_first_gallery()


## ---------------------------------------------------------------- the Rows

## Washing across each row between the lean-tos, in household colours, swaying.
func _laundry() -> void:
	for h in _homes:
		if int(h["i"]) % 3 != 0:
			continue
		var y: float = h["y"]
		var a := Vector2(float(h["x"]) + 150.0, y - 150.0)
		var b := Vector2(float(h["x"]) + 330.0, y - 160.0)
		if not _view.intersects(Rect2(a.x, a.y - 30.0, 200.0, 90.0)):
			continue
		var prev := a
		for s in range(1, 8):
			var f := float(s) / 7.0
			var p := a.lerp(b, f) + Vector2(0.0, sin(f * PI) * 18.0)
			draw_line(prev, p, Color(0.25, 0.2, 0.14, 0.9), 1.5)
			if s % 2 == 0 and s < 7:
				var sway := sin(_t * 1.1 + f * 7.0) * 2.5
				var c: Color = MARKS[(s + int(h["i"])) % MARKS.size()].lightened(0.1)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-6.0, 0.0), p + Vector2(6.0, 0.0), p + Vector2(6.0 + sway, 26.0), p + Vector2(-6.0 + sway, 26.0)]), c)
			prev = p


## The Well Rope: a timber gantry over the Mouth edge of the first row, a windlass drum with a crank, and a bucket on a long
## rope that runs down toward the pool the Cistern draws from (the lowest households' water still comes from the pit).
func _well_rope() -> void:
	var r: Dictionary = {}
	for rr in HollowMap.runs():
		if rr["id"] == &"LP13" or str(rr["id"]).begins_with("LP13"):
			if r.is_empty() or float(rr["x1"]) > float(r["x1"]):
				r = rr
	if r.is_empty():
		return
	var ex: float = float(r["x1"]) - 36.0
	var y: float = r["y"]
	if not _view.intersects(Rect2(ex - 200.0, y - 160.0, 300.0, 1400.0)):
		return
	# two posts, a crossbeam and a cantilevered arm out over the edge
	draw_rect(Rect2(ex - 70.0, y - 130.0, 8.0, 130.0), TIMBER)
	draw_rect(Rect2(ex - 6.0, y - 130.0, 8.0, 130.0), TIMBER)
	draw_rect(Rect2(ex - 78.0, y - 138.0, 96.0, 8.0), TIMBER_HI)
	draw_line(Vector2(ex - 66.0, y - 100.0), Vector2(ex - 2.0, y - 134.0), TIMBER, 4.0)
	draw_rect(Rect2(ex + 2.0, y - 124.0, 70.0, 6.0), TIMBER_HI)
	# the windlass drum with a crank
	var dc := Vector2(ex - 34.0, y - 100.0)
	draw_rect(Rect2(dc.x - 22.0, dc.y - 9.0, 44.0, 18.0), TIMBER.darkened(0.15))
	for s in range(5):
		draw_line(Vector2(dc.x - 22.0 + float(s) * 11.0, dc.y - 9.0), Vector2(dc.x - 22.0 + float(s) * 11.0, dc.y + 9.0), TIMBER.darkened(0.4), 1.5)
	draw_line(Vector2(dc.x + 22.0, dc.y), Vector2(dc.x + 36.0, dc.y + 10.0), IRON, 3.0)
	draw_circle(Vector2(dc.x + 38.0, dc.y + 12.0), 3.0, TIN_HI)
	# the rope out along the arm and down, fading with depth, the bucket swaying on its end
	var tip := Vector2(ex + 62.0, y - 121.0)
	draw_line(Vector2(dc.x, dc.y - 9.0), tip, Color(0.55, 0.45, 0.3), 1.5)
	var sway := sin(_t * 0.7) * 6.0
	var bottom := y + 560.0
	for s in range(14):
		var f0 := float(s) / 14.0
		var f1 := float(s + 1) / 14.0
		draw_line(Vector2(tip.x + sway * f0, tip.y + (bottom - tip.y) * f0), Vector2(tip.x + sway * f1, tip.y + (bottom - tip.y) * f1), Color(0.55, 0.45, 0.3, 0.9 * (1.0 - f0 * 0.8)), 1.5)
	var bp := Vector2(tip.x + sway, bottom)
	draw_rect(Rect2(bp.x - 8.0, bp.y, 16.0, 14.0), TIMBER.darkened(0.2))
	draw_rect(Rect2(bp.x - 8.0, bp.y, 16.0, 3.0), TIN_HI)
	_lamp(Vector2(ex - 30.0, y - 150.0))
	_sign(Vector2(ex - 30.0, y - 170.0), "THE WELL ROPE")


## ---------------------------------------------------------------- Bottom-West

## One timber shoring frame: two posts, a cap beam, braces, a lintel plank and a work lamp on a bracket.
func _frame(f: Dictionary) -> void:
	var x: float = f["x"]
	var y: float = f["y"]
	var deep: bool = f["deep"]
	var h := 212.0
	var w := 120.0
	var wood := TIMBER.darkened(0.15) if not deep else TIMBER.darkened(0.35)
	draw_rect(Rect2(x - w * 0.5, y - h, 9.0, h), wood)
	draw_rect(Rect2(x + w * 0.5 - 9.0, y - h, 9.0, h), wood)
	draw_rect(Rect2(x - w * 0.5 - 8.0, y - h - 8.0, w + 16.0, 12.0), wood.lightened(0.06))
	draw_line(Vector2(x - w * 0.5 + 9.0, y - h + 40.0), Vector2(x - w * 0.5 + 40.0, y - h + 6.0), wood, 5.0)
	draw_line(Vector2(x + w * 0.5 - 9.0, y - h + 40.0), Vector2(x + w * 0.5 - 40.0, y - h + 6.0), wood, 5.0)
	draw_rect(Rect2(x - w * 0.5, y - 8.0, w, 8.0), wood.darkened(0.2)) # the sill timber
	# the lamp: warm in the public galleries, a cold teal in the deep ones
	var col := COOL if deep else WARM
	var p := Vector2(x + w * 0.5 - 4.0, y - h + 56.0)
	var fl := 0.85 + 0.15 * sin(_t * 5.0 + x * 0.05)
	draw_line(Vector2(p.x, p.y - 12.0), p, IRON, 2.0)
	draw_circle(p + Vector2(0.0, 8.0), 30.0, Color(col.r, col.g, col.b, 0.07 * fl))
	draw_rect(Rect2(p.x - 4.0, p.y, 8.0, 12.0), Color(col.r, col.g, col.b, 0.95))
	# every third bay: a sack stack and a pick rack
	if int(f["j"]) % 3 == 1:
		for s in range(3):
			draw_circle(Vector2(x - 36.0 + float(s) * 16.0, y - 8.0), 8.0, Color(0.5, 0.42, 0.3))
		draw_circle(Vector2(x - 28.0, y - 22.0), 8.0, Color(0.46, 0.38, 0.28))
		draw_rect(Rect2(x + 20.0, y - 70.0, 4.0, 70.0), wood)
		for s in range(3):
			var py := y - 56.0 + float(s) * 16.0
			draw_line(Vector2(x + 22.0, py), Vector2(x + 52.0, py - 8.0), TIN_HI, 2.0)
			draw_line(Vector2(x + 50.0, py - 14.0), Vector2(x + 56.0, py - 4.0), TIN_HI, 2.0)


## The cable of work lamps along each gallery: a sagging line between the frames, so a gallery reads as one worked space.
func _gallery_extras() -> void:
	var by_run: Dictionary = {}
	for f in _frames:
		var key := str(int(f["y"])) + ":" + str(int(f["x0"]))
		if not by_run.has(key):
			by_run[key] = []
		by_run[key].append(f)
	for key in by_run.keys():
		var fs: Array = by_run[key]
		for i in range(fs.size() - 1):
			var a: Dictionary = fs[i]
			var b: Dictionary = fs[i + 1]
			if absf(float(b["x"]) - float(a["x"]) - 176.0) > 1.0:
				continue
			if not _view.intersects(Rect2(float(a["x"]), float(a["y"]) - 220.0, 176.0, 60.0)):
				continue
			var y := float(a["y"]) - 160.0
			var prev := Vector2(float(a["x"]) + 56.0, y)
			for s in range(1, 7):
				var f := float(s) / 6.0
				var p := Vector2(float(a["x"]) + 56.0 + f * 176.0, y + sin(f * PI) * 14.0)
				draw_line(prev, p, Color(0.12, 0.1, 0.09, 0.9), 1.5)
				prev = p


## A fresh dig face at the gallery's far end: pale ore flecks and glints in the rock beyond the wall, and a lit bracket.
func _dig_face(r: Dictionary) -> void:
	var y: float = r["y"]
	var x: float = r["x0"] + 4.0
	if not _view.intersects(Rect2(x - 40.0, y - 230.0, 240.0, 240.0)):
		return
	# a half-dug face: scattered flecks, a bright seam running up the wall
	for i in range(22):
		var fx := x + float((i * 37) % 70)
		var fy := y - 20.0 - float((i * 53) % 190)
		var tw := 0.5 + 0.5 * sin(_t * 1.6 + float(i))
		draw_rect(Rect2(fx, fy, 3.0 + float(i % 3), 3.0), Color(ORE.r, ORE.g, ORE.b, 0.45 + 0.4 * tw))
	draw_line(Vector2(x + 18.0, y), Vector2(x + 40.0, y - 110.0), Color(ORE.r, ORE.g, ORE.b, 0.35), 3.0)
	draw_line(Vector2(x + 40.0, y - 110.0), Vector2(x + 30.0, y - 210.0), Color(ORE.r, ORE.g, ORE.b, 0.25), 3.0)
	# loose spoil at the foot of the face
	for i in range(6):
		draw_circle(Vector2(x + 24.0 + float(i) * 11.0, y - 5.0 - float((i * 3) % 4)), 6.0, Color(0.3, 0.28, 0.27))


## Two rails along each gallery floor (in the free stretches) with ties, and an ore cart parked near the face.
func _rails(r: Dictionary) -> void:
	var y: float = r["y"]
	var x0: float = r["x0"] + 120.0
	var x1: float = r["x1"] - 60.0
	if x1 - x0 < 64.0 or not _view.intersects(Rect2(x0, y - 60.0, x1 - x0, 70.0)):
		return
	var k: float = r["k"]
	var x := maxf(x0, _view.position.x)
	x = floorf(x / 32.0) * 32.0
	while x < minf(x1, _view.end.x):
		if Util.span_free(x, x + 32.0, k, y):
			draw_line(Vector2(x, y - 6.0), Vector2(x + 32.0, y - 6.0), TIN_HI, 2.0)
			draw_line(Vector2(x, y - 11.0), Vector2(x + 32.0, y - 11.0), IRON, 2.0)
			if int(x / 32.0) % 2 == 0:
				draw_rect(Rect2(x + 4.0, y - 6.0, 10.0, 6.0), TIMBER.darkened(0.3))
		x += 32.0
	var cx: float = r["x0"] + 160.0 + float(int(absf(float(r["x0"]))) % 140)
	if Util.span_free(cx, cx + 70.0, k, y):
		draw_rect(Rect2(cx, y - 40.0, 64.0, 26.0), Color(0.34, 0.26, 0.2))
		draw_rect(Rect2(cx - 3.0, y - 44.0, 70.0, 5.0), Color(0.46, 0.36, 0.26))
		draw_circle(Vector2(cx + 14.0, y - 8.0), 6.0, IRON)
		draw_circle(Vector2(cx + 50.0, y - 8.0), 6.0, IRON)
		for j in range(3):
			draw_circle(Vector2(cx + 14.0 + float(j) * 18.0, y - 46.0), 8.0, Color(0.32, 0.26, 0.22))
			draw_circle(Vector2(cx + 14.0 + float(j) * 18.0 + 3.0, y - 49.0), 2.0, Color(ORE.r, ORE.g, ORE.b, 0.8))


func _sign_first_gallery() -> void:
	for r in HollowMap.runs():
		if r["id"] == &"BW10":
			var x: float = float(r["x0"]) + 300.0
			if _view.intersects(Rect2(x - 100.0, float(r["y"]) - 260.0, 200.0, 100.0)):
				_sign(Vector2(x, float(r["y"]) - 234.0), "TEACHING FACE")
		if r["id"] == &"BW11":
			var x2: float = float(r["x0"]) + 300.0
			if _view.intersects(Rect2(x2 - 100.0, float(r["y"]) - 260.0, 200.0, 100.0)):
				_sign(Vector2(x2, float(r["y"]) - 234.0), "SERVICE RUN")


## ---------------------------------------------------------------- bits

func _lamp(p: Vector2) -> void:
	var f := 0.85 + 0.15 * sin(_t * 6.0 + p.x * 0.1)
	draw_circle(p, 28.0, Color(WARM.r, WARM.g, WARM.b, 0.07 * f))
	draw_rect(Rect2(p.x - 4.0, p.y - 10.0, 8.0, 4.0), IRON)
	draw_rect(Rect2(p.x - 4.0, p.y - 6.0, 8.0, 12.0), Color(WARM.r, WARM.g, WARM.b, 0.95))


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.1, 0.08, 0.07, 0.92))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.8, 0.62, 0.35, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 0.85, 0.65, 0.95))
