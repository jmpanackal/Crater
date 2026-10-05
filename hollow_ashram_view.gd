extends Node2D
## Ashram Heights as one ordered, ceremonial district (USER 2026-10-04: do the Ashram, with a terraced cliff-town concept
## image). Canon: the most ordered, guarded and ceremonial expression of Hollow culture, quiet tidy residences under the
## Firmament, formal entrances, visible Warden scrutiny, stepped terraces and processional stairs, lantern amber with a
## little cool fill, no neon and no sacred symbols. Reached only by the premium lifts and the Warden gates.
##   houses       whitewashed plaster homes on every tier, stepped heights, flat parapet roofs, striped cloth awnings over
##                arched doors, lit windows, lantern posts, potted trees; each tier is a street of them;
##   the gates    each Heights gate is framed by two tall pylons with hanging banners, brazier bowls and a pair of Wardens;
##   the rotunda  the landmark of each wing: the summit rotunda under the Firmament, a great hanging lamp, a ring of
##                radial banners, a dais and brazier, an inscribed floor ring and a sign;
##   procession   the L4 to L5 stair gets banner pylons and braziers at its head, and a "PROCESSION" sign;
##   light        a warm lantern-amber wash with a cool teal-grey fill high up.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const WARM := Color(1.0, 0.74, 0.42)
const COOL := Color(0.45, 0.75, 0.78)
const PLASTER := Color(0.6, 0.53, 0.43)
const PLASTER_LO := Color(0.42, 0.36, 0.3)
const STONE := Color(0.36, 0.33, 0.31)
const STONE_HI := Color(0.5, 0.46, 0.42)
const TIMBER := Color(0.32, 0.21, 0.13)
const BRONZE := Color(0.3, 0.5, 0.45)
const BRONZE_HI := Color(0.5, 0.75, 0.66)
const CLOTHS := [Color(0.62, 0.3, 0.2), Color(0.28, 0.5, 0.5), Color(0.72, 0.55, 0.28), Color(0.5, 0.36, 0.5)]
const LEAF := Color(0.3, 0.5, 0.28)

var _t := 0.0
var _view := Rect2()
var _houses: Array[Dictionary] = []


func _ready() -> void:
	z_index = 0
	_houses = _plan_houses()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport()
	_view = (vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)).grow(300.0)
	if _view.position.y > HollowMap.lvl(6.0) or _view.end.y < HollowMap.lvl(-1.0):
		return
	for h in _houses:
		if _view.intersects(Rect2(h["x"], h["y"] - 260.0, h["w"], 270.0)):
			_house(h)
	for g in HollowMap.gates():
		if str(g["id"]).begins_with("gate_ashram"):
			_gate(g)
	_rotunda(-48.0, HollowMap.lvl(0.0), "FIRMAMENT ROTUNDA")
	_rotunda(7568.0, HollowMap.lvl(0.0), "FIRMAMENT ROTUNDA")
	_procession()


## ---------------------------------------------------------------- planning

## Where every house stands: along each Ashram street, clear of flights, ladders, lifts, gates, domes' bowls and the
## generated units. Deterministic, planned once.
func _plan_houses() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in HollowMap.runs():
		if not str(r["zone"]).begins_with("ashram") or bool(r["landing"]):
			continue
		var x0: float = r["x0"]
		var x1: float = r["x1"]
		var k: float = r["k"]
		if x1 - x0 < 260.0:
			continue
		var x := x0 + 60.0 + float(int(absf(x0)) % 70)
		var i := 0
		while true:
			var w := 140.0 + float(((i * 3 + int(absf(x0) / 16.0)) % 4)) * 36.0
			if x + w > x1 - 50.0:
				break
			if _free(x - 28.0, x + w + 28.0, k, float(r["y"])):
				out.append({"x": x, "w": w, "y": r["y"], "k": k, "h": 112.0 + float((i * 5 + int(absf(x0) / 16.0)) % 4) * 24.0, "i": i + int(absf(x0))})
			x += w + 54.0 + float((i * 37) % 80)
			i += 1
	return out


func _free(a: float, b: float, k: float, y: float) -> bool:
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


## ---------------------------------------------------------------- houses

func _house(h: Dictionary) -> void:
	var x: float = h["x"]
	var w: float = h["w"]
	var y: float = h["y"]
	var ht: float = h["h"]
	var seed_i: int = h["i"]
	var top := y - ht
	# the plaster body, a darker base and a lit cap
	draw_rect(Rect2(x, top, w, ht), PLASTER.darkened(0.25))
	draw_rect(Rect2(x, y - 18.0, w, 18.0), PLASTER_LO.darkened(0.2))
	draw_rect(Rect2(x - 4.0, top - 8.0, w + 8.0, 10.0), STONE)
	draw_rect(Rect2(x - 4.0, top - 8.0, w + 8.0, 3.0), STONE_HI)
	# faint plaster mottling and cracks
	for j in range(5):
		var mx := x + 12.0 + float((seed_i * 31 + j * 47) % int(maxf(w - 30.0, 1.0)))
		var my := top + 18.0 + float((seed_i * 17 + j * 29) % int(maxf(ht - 50.0, 1.0)))
		draw_rect(Rect2(mx, my, 18.0, 6.0), Color(PLASTER_LO.r, PLASTER_LO.g, PLASTER_LO.b, 0.4))
	# an arched door with a stoop and a lantern
	var dx := x + w * (0.3 + 0.1 * float(seed_i % 3))
	draw_rect(Rect2(dx - 18.0, y - 62.0, 36.0, 62.0), Color(0.12, 0.08, 0.06))
	draw_circle(Vector2(dx, y - 62.0), 18.0, Color(0.12, 0.08, 0.06))
	draw_rect(Rect2(dx - 14.0, y - 58.0, 28.0, 58.0), TIMBER)
	draw_circle(Vector2(dx, y - 58.0), 14.0, TIMBER)
	draw_line(Vector2(dx, y - 72.0), Vector2(dx, y - 2.0), Color(0.15, 0.1, 0.07), 1.5)
	draw_rect(Rect2(dx - 24.0, y - 5.0, 48.0, 5.0), STONE_HI)
	_lantern(Vector2(dx + 30.0, y - 70.0), 0.9)
	# a window with a warm glow, on the other side of the door when there is room
	var wx := x + w * 0.78
	if absf(wx - dx) > 44.0 and ht > 120.0:
		draw_rect(Rect2(wx - 10.0, y - 96.0, 20.0, 26.0), Color(WARM.r, WARM.g, WARM.b, 0.55 + 0.1 * sin(_t * 2.0 + float(seed_i))))
		draw_rect(Rect2(wx - 12.0, y - 98.0, 24.0, 4.0), STONE)
		draw_rect(Rect2(wx - 12.0, y - 70.0, 24.0, 4.0), STONE)
	# a cloth awning over the door (the concept's stalls and shopfronts)
	if seed_i % 3 != 1:
		var c: Color = CLOTHS[seed_i % CLOTHS.size()]
		var ax := dx - 38.0
		draw_colored_polygon(PackedVector2Array([Vector2(ax, y - 92.0), Vector2(ax + 76.0, y - 92.0), Vector2(ax + 86.0, y - 74.0), Vector2(ax - 10.0, y - 74.0)]), c)
		for s in range(6):
			draw_circle(Vector2(ax - 6.0 + float(s) * 16.0 + 6.0, y - 74.0), 6.0, c.darkened(0.15))
	# a potted tree or shrub at the corner
	_tree(Vector2(x + w - 14.0, y), seed_i)
	# on the wider homes, a lit lantern post out front and a parapet pot
	if w > 200.0:
		draw_rect(Rect2(x + 8.0, top - 22.0, 12.0, 14.0), Color(0.42, 0.28, 0.2))
		draw_circle(Vector2(x + 14.0, top - 28.0), 7.0, LEAF.darkened(0.1))


func _tree(base: Vector2, seed_i: int) -> void:
	draw_rect(Rect2(base.x - 8.0, base.y - 14.0, 16.0, 14.0), Color(0.4, 0.27, 0.19))
	draw_rect(Rect2(base.x - 2.0, base.y - 40.0, 4.0, 26.0), Color(0.28, 0.2, 0.13))
	var sway := sin(_t * 0.8 + float(seed_i)) * 1.5
	for j in range(5):
		var a := float(j) * 1.25 + float(seed_i)
		draw_circle(Vector2(base.x + cos(a) * 12.0 + sway, base.y - 48.0 + sin(a) * 9.0), 8.0, LEAF.lerp(Color(0.5, 0.65, 0.3), float(j) / 5.0))


## A small hanging lantern: a bracket, a cap, a warm glass body and a soft halo.
func _lantern(p: Vector2, scale: float) -> void:
	var flick := 0.85 + 0.15 * sin(_t * 6.0 + p.x * 0.1)
	draw_circle(p, 26.0 * scale, Color(WARM.r, WARM.g, WARM.b, 0.07 * flick))
	draw_rect(Rect2(p.x - 4.0 * scale, p.y - 10.0 * scale, 8.0 * scale, 4.0 * scale), STONE)
	draw_rect(Rect2(p.x - 4.0 * scale, p.y - 6.0 * scale, 8.0 * scale, 12.0 * scale), Color(WARM.r, WARM.g, WARM.b, 0.95))
	draw_rect(Rect2(p.x - 5.0 * scale, p.y + 6.0 * scale, 10.0 * scale, 3.0 * scale), STONE)


## ---------------------------------------------------------------- gates and banners

func _gate(g: Dictionary) -> void:
	var x: float = g["x"]
	var y := 0.0
	for r in HollowMap.runs():
		if r["id"] == g["run"]:
			y = float(r["y"])
	if y == 0.0 or not _view.intersects(Rect2(x - 220.0, y - 260.0, 440.0, 270.0)):
		return
	# the great double gate behind the bar: tall, arched, teal-bronze with ribbing
	var gw := 120.0
	draw_rect(Rect2(x - gw * 0.5, y - 190.0, gw, 190.0), Color(0.08, 0.1, 0.1))
	draw_circle(Vector2(x, y - 190.0), gw * 0.5, Color(0.08, 0.1, 0.1))
	for side in [-1.0, 1.0]:
		var lx: float = x + (0.0 if side > 0.0 else -gw * 0.5 + 4.0)
		draw_rect(Rect2(lx, y - 186.0, gw * 0.5 - 4.0, 186.0), BRONZE.darkened(0.35))
		for j in range(6):
			draw_rect(Rect2(lx, y - 176.0 + float(j) * 30.0, gw * 0.5 - 4.0, 4.0), BRONZE)
			draw_rect(Rect2(lx, y - 176.0 + float(j) * 30.0, gw * 0.5 - 4.0, 1.0), BRONZE_HI)
		draw_rect(Rect2(lx + (gw * 0.25 - 6.0 if side < 0.0 else 4.0), y - 120.0, 4.0, 60.0), BRONZE_HI.darkened(0.2))
	draw_line(Vector2(x, y - 244.0), Vector2(x, y), Color(0.05, 0.07, 0.07), 3.0)
	# two pylons with banners and brazier bowls
	for side in [-1.0, 1.0]:
		var px: float = x + side * 100.0
		draw_rect(Rect2(px - 24.0, y - 230.0, 48.0, 230.0), STONE.darkened(0.15))
		draw_rect(Rect2(px - 24.0, y - 230.0, 6.0, 230.0), STONE_HI.darkened(0.15))
		draw_rect(Rect2(px - 30.0, y - 238.0, 60.0, 12.0), STONE)
		draw_rect(Rect2(px - 30.0, y - 22.0, 60.0, 22.0), STONE.darkened(0.1))
		_banner(Vector2(px, y - 218.0), 34.0, 130.0, BRONZE.darkened(0.25), float(g["x"]) * 0.01 + side)
		_brazier(Vector2(px + side * 44.0, y))
		_warden(Vector2(px + side * 84.0, y), -side)
	draw_rect(Rect2(x - 48.0, y - 250.0, 96.0, 16.0), STONE)
	_sign(Vector2(x, y - 262.0), "WARDEN GATE")


func _banner(top: Vector2, w: float, h: float, col: Color, ph: float) -> void:
	var sway := sin(_t * 0.9 + ph) * 3.0
	var pts := PackedVector2Array([top + Vector2(-w * 0.5, 0.0), top + Vector2(w * 0.5, 0.0), top + Vector2(w * 0.5 + sway, h), top + Vector2(sway, h - 14.0), top + Vector2(-w * 0.5 + sway, h)])
	draw_colored_polygon(pts, col)
	draw_rect(Rect2(top.x - w * 0.5 - 3.0, top.y - 4.0, w + 6.0, 5.0), TIMBER)
	# a plain stepped mark (geometric, no sacred symbol)
	var mx := top.x + sway * 0.5
	draw_rect(Rect2(mx - 6.0, top.y + 26.0, 12.0, 12.0), Color(0.82, 0.74, 0.55, 0.8))
	draw_rect(Rect2(mx - 10.0, top.y + 38.0, 20.0, 8.0), Color(0.82, 0.74, 0.55, 0.8))
	draw_rect(Rect2(mx - 14.0, top.y + 46.0, 28.0, 6.0), Color(0.82, 0.74, 0.55, 0.8))


func _brazier(base: Vector2) -> void:
	draw_rect(Rect2(base.x - 12.0, base.y - 44.0, 24.0, 44.0), STONE.darkened(0.2))
	draw_rect(Rect2(base.x - 16.0, base.y - 50.0, 32.0, 8.0), STONE_HI.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 12.0, base.y - 50.0), Vector2(base.x + 12.0, base.y - 50.0), Vector2(base.x + 8.0, base.y - 60.0), Vector2(base.x - 8.0, base.y - 60.0)]), Color(0.18, 0.12, 0.1))
	var f := 0.8 + 0.2 * sin(_t * 9.0 + base.x)
	draw_circle(base + Vector2(0.0, -76.0), 54.0, Color(WARM.r, WARM.g, WARM.b, 0.07 * f))
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 9.0, base.y - 60.0), Vector2(base.x + 9.0, base.y - 60.0), Vector2(base.x + 3.0 * sin(_t * 7.0 + base.x), base.y - 60.0 - 26.0 * f)]), Color(1.0, 0.7, 0.3, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 4.0, base.y - 60.0), Vector2(base.x + 4.0, base.y - 60.0), Vector2(base.x, base.y - 60.0 - 15.0 * f)]), Color(1.0, 0.92, 0.6, 0.95))


## A Warden at their post: a long coat, a helmet, a spear and a lamp at the belt. Standing, a slow breath.
func _warden(base: Vector2, facing: float) -> void:
	var b := sin(_t * 1.3 + base.x) * 1.0
	draw_rect(Rect2(base.x - 7.0, base.y - 42.0 + b, 14.0, 42.0 - b), Color(0.18, 0.2, 0.18))
	draw_rect(Rect2(base.x - 9.0, base.y - 34.0, 18.0, 8.0), Color(0.3, 0.3, 0.26))
	draw_circle(Vector2(base.x, base.y - 50.0 + b), 6.0, Color(0.34, 0.28, 0.24))
	draw_rect(Rect2(base.x - 7.0, base.y - 58.0 + b, 14.0, 6.0), Color(0.2, 0.22, 0.2))
	var sx := base.x + facing * 11.0
	draw_line(Vector2(sx, base.y), Vector2(sx, base.y - 84.0), TIMBER, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(sx - 3.0, base.y - 84.0), Vector2(sx + 3.0, base.y - 84.0), Vector2(sx, base.y - 96.0)]), BRONZE_HI)
	draw_rect(Rect2(base.x - facing * 7.0 - 2.0, base.y - 26.0, 4.0, 5.0), Color(WARM.r, WARM.g, WARM.b, 0.9))


## ---------------------------------------------------------------- the rotunda

## The landmark of a wing: the summit rotunda under the Firmament (domes D_AW0 / D_AE0 over the L0 street).
func _rotunda(cx: float, y: float, label: String) -> void:
	if not _view.intersects(Rect2(cx - 460.0, y - 460.0, 920.0, 470.0)):
		return
	var top := y - HollowMap.ROOM_HEIGHT - 150.0
	# a pale ring of light on the dome and the great hanging lamp on a chain
	draw_circle(Vector2(cx, top + 60.0), 150.0, Color(WARM.r, WARM.g, WARM.b, 0.05))
	draw_line(Vector2(cx, top), Vector2(cx, top + 96.0), Color(0.12, 0.1, 0.08), 3.0)
	for j in range(8):
		var a := float(j) * PI * 0.25 + _t * 0.15
		var tip := Vector2(cx + cos(a) * 54.0, top + 112.0 + sin(a) * 10.0)
		draw_line(Vector2(cx, top + 96.0), tip, BRONZE, 2.5)
		draw_circle(tip, 7.0, Color(WARM.r, WARM.g, WARM.b, 0.95))
		draw_circle(tip, 22.0, Color(WARM.r, WARM.g, WARM.b, 0.08))
	draw_circle(Vector2(cx, top + 96.0), 12.0, BRONZE_HI)
	# radial banners hung round the rotunda
	for j in range(7):
		var f := float(j) / 6.0
		var bx := cx - 360.0 + f * 720.0
		_banner(Vector2(bx, y - 232.0 + absf(f - 0.5) * 40.0), 30.0, 100.0, CLOTHS[j % CLOTHS.size()].darkened(0.2), float(j))
	# the dais: a stepped round platform with a bowl brazier and an inscribed floor ring
	draw_rect(Rect2(cx - 120.0, y - 10.0, 240.0, 10.0), STONE_HI.darkened(0.15))
	draw_rect(Rect2(cx - 90.0, y - 20.0, 180.0, 10.0), STONE.lightened(0.05))
	draw_rect(Rect2(cx - 60.0, y - 30.0, 120.0, 10.0), STONE_HI.darkened(0.1))
	for j in range(9):
		draw_rect(Rect2(cx - 112.0 + float(j) * 28.0, y - 6.0, 12.0, 2.0), Color(WARM.r, WARM.g, WARM.b, 0.45))
	draw_rect(Rect2(cx - 22.0, y - 56.0, 44.0, 26.0), STONE.darkened(0.2))
	draw_rect(Rect2(cx - 30.0, y - 62.0, 60.0, 8.0), STONE_HI.darkened(0.2))
	var f2 := 0.8 + 0.2 * sin(_t * 8.0)
	draw_circle(Vector2(cx, y - 90.0), 64.0, Color(WARM.r, WARM.g, WARM.b, 0.08 * f2))
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 14.0, y - 62.0), Vector2(cx + 14.0, y - 62.0), Vector2(cx + 4.0 * sin(_t * 6.0), y - 62.0 - 44.0 * f2)]), Color(1.0, 0.7, 0.3, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(cx - 6.0, y - 62.0), Vector2(cx + 6.0, y - 62.0), Vector2(cx, y - 62.0 - 26.0 * f2)]), Color(1.0, 0.92, 0.6, 0.95))
	_warden(Vector2(cx - 150.0, y), 1.0)
	_warden(Vector2(cx + 150.0, y), -1.0)
	_sign(Vector2(cx, y - 262.0), label)


## ---------------------------------------------------------------- the procession

## The L4 to L5 stair (S_A1): banner pylons and braziers at its head, and a sign.
func _procession() -> void:
	for st in HollowMap.stairs():
		if st["id"] != &"S_A1":
			continue
		var tx: float = st["top_x"]
		var ty: float = st["top_y"]
		if not _view.intersects(Rect2(tx - 200.0, ty - 300.0, 460.0, 310.0)):
			return
		for side in [-1.0, 1.0]:
			var px: float = tx + 90.0 + side * 70.0
			draw_rect(Rect2(px - 18.0, ty - 190.0, 36.0, 190.0), STONE.darkened(0.15))
			draw_rect(Rect2(px - 24.0, ty - 198.0, 48.0, 10.0), STONE)
			_banner(Vector2(px, ty - 180.0), 28.0, 110.0, CLOTHS[0 if side < 0.0 else 1].darkened(0.15), side)
			_brazier(Vector2(px + side * 40.0, ty))
		_sign(Vector2(tx + 90.0, ty - 214.0), "THE PROCESSION")


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.1, 0.08, 0.07, 0.92))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(BRONZE_HI.r, BRONZE_HI.g, BRONZE_HI.b, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.9, 0.95, 0.85, 0.95))
