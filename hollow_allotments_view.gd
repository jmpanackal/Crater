extends Node2D
## The Mid Allotments as one district (USER 2026-10-04): the families' small garden plots and homes, in a tall shared cavern
## (hall H_AL, vault D_AL) with the street a bridge across it. Canon: the lower terraces are crowded and practical; the
## Mid Reach residence is a better-kept two-room apartment near the allotments with a shared balcony (story.md).
##   the Commons   the landmark: a communal cookhouse and wash on the garden floor, a big chimney that climbs the cavern to
##                 the vault, a long shared table under strung lamps, steam and cooking smoke;
##   plots         fenced garden plots (props) with numbered posts and rain barrels fed by drips from the vault;
##   laundry       lines of washing strung across the cavern from the bridge to posts on the floor, swaying;
##   lanterns      strings of lanterns across the whole space, so it reads as one warm, lived-in place;
##   Mid Reach     the apartment block on the bridge gets a balcony with railings, plant boxes and its own sign;
##   light         a warm rose-amber wash, the only pink-amber glow on the west side, so the district has its own colour.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const HALL_ID := &"H_AL"
const WARM := Color(1.0, 0.72, 0.45)
const ROSE := Color(0.95, 0.5, 0.45)
const STONE := Color(0.34, 0.32, 0.32)
const STONE_HI := Color(0.5, 0.47, 0.45)
const TIMBER := Color(0.4, 0.28, 0.18)
const CLOTHS := [Color(0.82, 0.78, 0.66), Color(0.55, 0.32, 0.28), Color(0.3, 0.45, 0.5), Color(0.78, 0.62, 0.34), Color(0.62, 0.6, 0.7)]

const COMMONS_X0 := -2270.0
const COMMONS_X1 := -1960.0

var _t := 0.0
var _rect := Rect2()
var _floor := 0.0
var _bridge := 0.0


func _ready() -> void:
	z_index = 0
	for h in HollowMap.halls():
		if h["id"] == HALL_ID:
			var top := HollowMap.lvl(float(h["k_top"])) - HollowMap.ROOM_HEIGHT
			_floor = HollowMap.lvl(float(h["k_bottom"]))
			_bridge = HollowMap.lvl(float(h["k_top"]))
			_rect = Rect2(float(h["x0"]), top, float(h["x1"]) - float(h["x0"]), _floor - top)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_screen() -> bool:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var view := inv * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	return view.grow(300.0).intersects(_rect)


func _draw() -> void:
	if _rect.size == Vector2.ZERO or not _on_screen():
		return
	_wash()
	_lanterns()
	_laundry()
	_commons()
	_barrels_and_drips()
	_balcony()
	_sign(Vector2(-2540.0, _bridge - 270.0), "MID REACH")
	_sign(Vector2(-2625.0, _floor - 130.0), "PLOTS")
	_arch(_rect.position.x + 70.0, _floor)
	_arch(_rect.end.x - 70.0, _floor)


func _wash() -> void:
	var cols := int(ceilf(_rect.size.x / 64.0))
	var bands := 12
	for c in range(cols):
		var cx := _rect.position.x + float(c) * 64.0
		var u := (float(c) + 0.5) / float(cols)
		var edge := pow(sin(PI * u), 0.6)
		for i in range(bands):
			var f := float(i) / float(bands - 1)
			var y := _rect.position.y + _rect.size.y * float(i) / float(bands)
			draw_rect(Rect2(cx, y, 65.0, _rect.size.y / float(bands) + 1.0), Color(WARM.r, ROSE.g, ROSE.b, (0.01 + 0.045 * f) * edge))


## Strings of lanterns across the cavern, in three tiers, swaying a little.
func _lanterns() -> void:
	for tier in range(3):
		var y0 := _rect.position.y + 150.0 + float(tier) * 190.0
		var prev := Vector2(_rect.position.x + 40.0, y0)
		var n := 14
		for i in range(1, n + 1):
			var f := float(i) / float(n)
			var p := Vector2(_rect.position.x + 40.0 + f * (_rect.size.x - 80.0), y0 + sin(f * PI) * 46.0 + sin(_t * 0.6 + f * 6.0 + float(tier)) * 3.0)
			draw_line(prev, p, Color(0.25, 0.18, 0.12, 0.8), 1.5)
			if i % 2 == 0:
				var flick := 0.75 + 0.25 * sin(_t * 3.2 + float(i + tier * 5))
				draw_rect(Rect2(p.x - 3.0, p.y, 6.0, 9.0), Color(WARM.r, WARM.g, WARM.b, 0.95 * flick))
				draw_circle(p + Vector2(0.0, 5.0), 26.0, Color(WARM.r, WARM.g, WARM.b, 0.06 * flick))
			prev = p


## Washing lines from the bridge's underside to posts on the garden floor.
func _laundry() -> void:
	var lines := [[-2640.0, -2360.0, 120.0], [-2230.0, -1940.0, 160.0], [-1960.0, -1790.0, 150.0]]
	for ln in lines:
		var a := Vector2(ln[0], _bridge + 40.0)
		var b := Vector2(ln[1], _floor - float(ln[2]))
		draw_line(Vector2(ln[0], _bridge + 32.0), a, Color(0.25, 0.18, 0.12), 2.0)
		draw_rect(Rect2(b.x - 3.0, b.y, 6.0, float(ln[2])), TIMBER)
		var n := 8
		var prev := a
		for i in range(1, n + 1):
			var f := float(i) / float(n)
			var p := a.lerp(b, f) + Vector2(0.0, sin(f * PI) * 30.0)
			draw_line(prev, p, Color(0.3, 0.22, 0.16), 1.5)
			if i < n:
				var sway := sin(_t * 1.4 + f * 7.0 + a.x * 0.01) * 4.0
				var c: Color = CLOTHS[(i + int(absf(a.x)) / 40) % CLOTHS.size()]
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(18.0, 0.0), p + Vector2(15.0 + sway, 44.0), p + Vector2(3.0 + sway, 44.0)]), c)
			prev = p


## The Commons: a communal cookhouse with a long chimney up to the vault, a shared table under lamps, steam and smoke.
func _commons() -> void:
	var x0 := COMMONS_X0
	var x1 := COMMONS_X1
	var deck := _floor
	var h := 300.0
	var top := deck - h
	# the cookhouse body: stone with timber framing
	draw_rect(Rect2(x0, top, x1 - x0, h), STONE)
	for r in range(int(h / 22.0)):
		draw_line(Vector2(x0, top + float(r) * 22.0), Vector2(x1, top + float(r) * 22.0), Color(0.2, 0.19, 0.19, 0.8), 1.5)
	for fx in [x0, (x0 + x1) * 0.5, x1 - 10.0]:
		draw_rect(Rect2(fx, top, 10.0, h), TIMBER)
	draw_rect(Rect2(x0 - 12.0, top - 14.0, x1 - x0 + 24.0, 16.0), TIMBER)
	# a big arched hearth with a cooking fire
	var hx := (x0 + x1) * 0.5
	var flick := 0.75 + 0.25 * sin(_t * 5.0) * sin(_t * 1.7)
	draw_rect(Rect2(hx - 70.0, deck - 120.0, 140.0, 120.0), Color(0.06, 0.04, 0.03))
	draw_rect(Rect2(hx - 58.0, deck - 108.0, 116.0, 108.0), Color(1.0, 0.5, 0.15, 0.8 * flick))
	draw_rect(Rect2(hx - 38.0, deck - 86.0, 76.0, 86.0), Color(1.0, 0.8, 0.4, 0.85 * flick))
	draw_circle(Vector2(hx, deck - 60.0), 150.0, Color(1.0, 0.55, 0.2, 0.08 * flick))
	# a pot on a hook and a spit
	draw_line(Vector2(hx, deck - 124.0), Vector2(hx, deck - 98.0), STONE_HI, 2.0)
	draw_rect(Rect2(hx - 16.0, deck - 98.0, 32.0, 22.0), Color(0.12, 0.12, 0.13))
	# windows
	for wx in [x0 + 30.0, x1 - 64.0]:
		draw_rect(Rect2(wx, top + 60.0, 34.0, 44.0), Color(0.1, 0.07, 0.05))
		draw_rect(Rect2(wx + 3.0, top + 63.0, 28.0, 38.0), Color(1.0, 0.7, 0.35, 0.8))
	# the chimney: a big flue that climbs the whole cavern to the vault, with smoke curling out of its top
	var cx := x1 - 40.0
	var chim_top := _rect.position.y - 330.0 + 70.0
	draw_rect(Rect2(cx - 20.0, chim_top, 40.0, top - chim_top), Color(0.3, 0.22, 0.18))
	for by in range(int((top - chim_top) / 60.0)):
		draw_rect(Rect2(cx - 24.0, chim_top + float(by) * 60.0, 48.0, 6.0), Color(0.18, 0.13, 0.11))
	for i in range(6):
		var f := fposmod(_t * 0.22 + float(i) / 6.0, 1.0)
		draw_circle(Vector2(cx + sin(f * 6.0 + float(i)) * 12.0, chim_top - f * 80.0), 12.0 + 22.0 * f, Color(0.55, 0.55, 0.57, 0.2 * (1.0 - f)))
	# steam off the pot
	for i in range(4):
		var f2 := fposmod(_t * 0.5 + float(i) * 0.25, 1.0)
		draw_circle(Vector2(hx + sin(f2 * 7.0) * 8.0, deck - 112.0 - f2 * 60.0), 5.0 + 10.0 * f2, Color(0.85, 0.85, 0.85, 0.25 * (1.0 - f2)))
	# a long shared table with benches, in front of the hearth's east side
	var tx := COMMONS_X1 + 20.0
	draw_rect(Rect2(tx, deck - 34.0, 150.0, 6.0), TIMBER)
	draw_rect(Rect2(tx + 8.0, deck - 28.0, 6.0, 28.0), TIMBER)
	draw_rect(Rect2(tx + 136.0, deck - 28.0, 6.0, 28.0), TIMBER)
	for i in range(5):
		draw_rect(Rect2(tx + 14.0 + float(i) * 26.0, deck - 44.0, 12.0, 10.0), Color(0.7, 0.55, 0.35) if i % 2 == 0 else Color(0.45, 0.6, 0.55))
	_sign(Vector2(hx, top - 36.0), "THE COMMONS")


## Rain barrels under the vault's drips: slow drops fall from the ceiling into them.
func _barrels_and_drips() -> void:
	for dx in [-2420.0, -2105.0, -1820.0]:
		var top := _rect.position.y - 330.0 + 14.0
		for i in range(3):
			var f := fposmod(_t * 0.45 + float(i) / 3.0 + dx * 0.001, 1.0)
			draw_circle(Vector2(dx, top + 40.0 + f * (_floor - 28.0 - top - 40.0)), 2.2, Color(0.7, 0.9, 1.0, 0.7))
		draw_rect(Rect2(dx - 14.0, _floor - 30.0, 28.0, 30.0), Color(0.36, 0.26, 0.17))
		draw_rect(Rect2(dx - 14.0, _floor - 20.0, 28.0, 3.0), Color(0.2, 0.15, 0.1))
		draw_rect(Rect2(dx - 12.0, _floor - 30.0, 24.0, 4.0), Color(0.28, 0.5, 0.56, 0.8))


## The Mid Reach block's shared balcony: a railing along the bridge in front of the apartments, with plant boxes.
func _balcony() -> void:
	var y := _bridge
	var x0 := -2700.0
	var x1 := -2384.0
	draw_rect(Rect2(x0 - 10.0, y - 6.0, x1 - x0 + 20.0, 6.0), Color(0.3, 0.22, 0.16))
	var x := x0
	while x <= x1:
		draw_rect(Rect2(x, y - 34.0, 3.0, 28.0), Color(0.34, 0.24, 0.16))
		x += 24.0
	draw_rect(Rect2(x0 - 10.0, y - 36.0, x1 - x0 + 20.0, 4.0), Color(0.38, 0.28, 0.2))
	for px in [x0 + 30.0, x0 + 150.0, x1 - 60.0]:
		draw_rect(Rect2(px, y - 52.0, 44.0, 16.0), Color(0.3, 0.2, 0.13))
		for i in range(5):
			draw_circle(Vector2(px + 6.0 + float(i) * 8.0, y - 58.0 - float((i * 5) % 7)), 4.5, Color(0.4, 0.75, 0.5))
	for i in range(3):
		draw_circle(Vector2(x0 + 60.0 + float(i) * 110.0, y - 20.0), 14.0, Color(WARM.r, WARM.g, WARM.b, 0.05))


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.1, 0.07, 0.06, 0.9))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.9, 0.6, 0.45, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 0.82, 0.65, 0.95))


func _arch(x: float, y: float) -> void:
	var w := 110.0
	var h := 150.0
	draw_rect(Rect2(x - w * 0.5, y - h, 12.0, h), TIMBER)
	draw_rect(Rect2(x + w * 0.5 - 12.0, y - h, 12.0, h), TIMBER)
	draw_rect(Rect2(x - w * 0.5 - 6.0, y - h - 12.0, w + 12.0, 14.0), TIMBER)
	draw_rect(Rect2(x - 52.0, y - h - 10.0, 104.0, 16.0), Color(0.1, 0.07, 0.06, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(x - 46.0, y - h + 2.0), "ALLOTMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(1.0, 0.82, 0.65, 0.95))
	draw_line(Vector2(x, y - h + 6.0), Vector2(x, y - h + 28.0), Color(0.3, 0.22, 0.14), 1.5)
	draw_circle(Vector2(x, y - h + 34.0), 5.0, Color(1.0, 0.75, 0.4, 0.95))
