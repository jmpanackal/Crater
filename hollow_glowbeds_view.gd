extends Node2D
## Glowbeds as one district (USER 2026-10-04: bigger but "not one wholistic district"). The tall garden cavern (hall H_GB)
## is tied together by one visible system and one identity:
##   water   a spring head high in the cavern pours a fall that passes down through a drain in every bridge it crosses
##           (grate, ripples, splash), and each bridge carries an irrigation channel along its edge that runs to the next
##           drain and past the planters, so the water visibly feeds the cultivation on every level;
##   growth  vines hang from every bridge's underside and glowing moss clings to its girders;
##   light   a soft teal-green wash fills the whole cavern, brighter low down where the growth is thickest, so it reads
##           as one lit space and nothing else in the Hollow glows this colour;
##   gates   a vine-wrapped arch with the district's name at each end of the garden street, so you know you have arrived.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const HALL_ID := &"H_GB"
const FALLS := [5360.0, 6440.0, 7640.0] ## x of the water's three drains (each on flat deck on every level)
const WATER := Color(0.45, 0.88, 0.9)
const WATER_DEEP := Color(0.18, 0.55, 0.62)
const MOSS := Color(0.3, 0.75, 0.5)
const ARCH := Color(0.28, 0.24, 0.2)
const GLOW := Color(0.25, 0.85, 0.7)

var _t := 0.0
var _rect := Rect2()
var _bridges: Array[Dictionary] = [] ## {x0, x1, k}
var _kt := 0.0
var _kb := 0.0


func _ready() -> void:
	z_index = 0
	for h in HollowMap.halls():
		if h["id"] != HALL_ID:
			continue
		_kt = float(h["k_top"])
		_kb = float(h["k_bottom"])
		_rect = Rect2(float(h["x0"]), HollowMap.lvl(_kt) - HollowMap.ROOM_HEIGHT, float(h["x1"]) - float(h["x0"]), HollowMap.lvl(_kb) - (HollowMap.lvl(_kt) - HollowMap.ROOM_HEIGHT))
	for r in HollowMap.runs():
		var k := float(r["k"])
		if k >= _kt - 0.01 and k < _kb - 0.01 and absf(k - roundf(k)) < 0.01 and not HollowMap.is_heart_zone(r["zone"]):
			var x0 := maxf(float(r["x0"]), _rect.position.x)
			var x1 := minf(float(r["x1"]), _rect.end.x)
			if x1 - x0 > 32.0:
				_bridges.append({"x0": x0, "x1": x1, "k": k})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_screen() -> bool:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var view := inv * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	return view.intersects(_rect)


func _draw() -> void:
	if _rect.size == Vector2.ZERO or not _on_screen():
		return
	_wash()
	for b in _bridges:
		_channel(b)
		_underside_growth(b)
	for fx in FALLS:
		_fall(fx)
	_production()
	_arch(_rect.position.x + 96.0, HollowMap.lvl(5.0), 1.0)
	_arch(_rect.end.x - 96.0, HollowMap.lvl(5.0), -1.0)


## A soft teal-green wash over the whole cavern, thicker toward the bottom where the growth is, so it reads as one lit space.
func _wash() -> void:
	# soft at the sides (no hard box) and thicker toward the bottom, in 64 px columns and 14 bands
	var cols := int(ceilf(_rect.size.x / 64.0))
	var bands := 14
	for c in range(cols):
		var cx := _rect.position.x + float(c) * 64.0
		var u := (float(c) + 0.5) / float(cols)
		var edge := pow(sin(PI * u), 0.6)
		for i in range(bands):
			var f := float(i) / float(bands - 1)
			var y := _rect.position.y + _rect.size.y * float(i) / float(bands)
			draw_rect(Rect2(cx, y, 65.0, _rect.size.y / float(bands) + 1.0), Color(GLOW.r, GLOW.g, GLOW.b, (0.012 + 0.05 * f) * edge))
	for i in range(7):
		var gx := _rect.position.x + _rect.size.x * (float(i) + 0.5) / 7.0
		var pulse := 0.5 + 0.5 * sin(_t * 0.6 + float(i) * 1.7)
		draw_circle(Vector2(gx, _rect.end.y - 120.0), 190.0 + 30.0 * pulse, Color(GLOW.r, GLOW.g, GLOW.b, 0.03 + 0.02 * pulse))


## The irrigation channel along a bridge's edge: a thin shimmering strip that runs between the drains.
func _channel(b: Dictionary) -> void:
	var y := HollowMap.lvl(float(b["k"])) + 6.0
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	draw_rect(Rect2(x0, y, x1 - x0, 4.0), Color(WATER_DEEP.r, WATER_DEEP.g, WATER_DEEP.b, 0.75))
	var x := x0
	while x < x1:
		var shimmer := 0.5 + 0.5 * sin(_t * 2.4 + x * 0.04)
		draw_rect(Rect2(x, y, 14.0, 1.5), Color(WATER.r, WATER.g, WATER.b, 0.25 + 0.4 * shimmer))
		x += 22.0


## Vines and glowing moss hanging from a bridge's underside.
func _underside_growth(b: Dictionary) -> void:
	var y := HollowMap.lvl(float(b["k"])) + HollowMap.FLOOR_THICK
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var x := x0 + 30.0
	var i := 0
	while x < x1 - 20.0:
		var len := 30.0 + float((i * 41) % 110)
		var sway := sin(_t * 0.9 + float(i)) * 3.0
		draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + sway * 0.5, y + len * 0.5), Vector2(x + sway, y + len)]), Color(0.2, 0.5, 0.32, 0.85), 2.0)
		draw_circle(Vector2(x + sway, y + len), 3.0, Color(0.55, 0.95, 0.7, 0.8))
		if i % 3 == 0:
			draw_circle(Vector2(x + sway, y + len), 12.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.08))
		x += 54.0 + float((i * 29) % 70)
		i += 1


## The water: a spring head at the cavern's ceiling, a fall down through a drain in every bridge, ripples where it lands.
func _fall(fx: float) -> void:
	var top := _rect.position.y
	var bottom := HollowMap.lvl(_kb)
	# the spring head: a copper spout with a little pool
	draw_rect(Rect2(fx - 16.0, top, 32.0, 10.0), Color(0.5, 0.32, 0.2))
	draw_rect(Rect2(fx - 8.0, top + 10.0, 16.0, 8.0), Color(0.62, 0.4, 0.26))
	draw_rect(Rect2(fx - 6.0, top, 12.0, bottom - top), Color(WATER_DEEP.r, WATER_DEEP.g, WATER_DEEP.b, 0.14))
	for i in range(9):
		var f := fposmod(_t * 0.5 + float(i) * 0.111 + fx * 0.0007, 1.0)
		var lane := (float(i % 3) - 1.0) * 3.0
		draw_rect(Rect2(fx + lane - 1.0, top + 18.0 + f * (bottom - top - 18.0), 2.0, 16.0), Color(WATER.r, WATER.g, WATER.b, 0.55))
	for b in _bridges:
		if fx > float(b["x0"]) + 16.0 and fx < float(b["x1"]) - 16.0:
			var y := HollowMap.deck_y_at(fx, float(b["k"]))
			# a drain grate set into the deck, with ripples and a splash where the water meets it
			draw_rect(Rect2(fx - 14.0, y - 2.0, 28.0, 5.0), Color(0.06, 0.07, 0.07))
			for j in range(4):
				draw_line(Vector2(fx - 12.0 + float(j) * 8.0, y - 2.0), Vector2(fx - 12.0 + float(j) * 8.0, y + 3.0), Color(0.4, 0.45, 0.45), 1.0)
			for r in range(2):
				var ph := fposmod(_t * 0.8 + float(r) * 0.5, 1.0)
				draw_arc(Vector2(fx, y - 3.0), 6.0 + 18.0 * ph, PI, TAU, 14, Color(WATER.r, WATER.g, WATER.b, 0.5 * (1.0 - ph)), 1.5)
	# mist where the last fall lands on the hang
	for m in range(5):
		var ph2 := fposmod(_t * 0.35 + float(m) * 0.2, 1.0)
		draw_circle(Vector2(fx + (float(m) - 2.0) * 8.0, bottom - 6.0 - ph2 * 22.0), 6.0 + 9.0 * ph2, Color(WATER.r, WATER.g, WATER.b, 0.1 * (1.0 - ph2)))


## A vine-wrapped arch over the garden street with the district's name, so you know you have arrived.
func _arch(x: float, y: float, dir: float) -> void:
	var w := 120.0
	var h := 158.0
	draw_rect(Rect2(x - w * 0.5, y - h, 12.0, h), ARCH)
	draw_rect(Rect2(x + w * 0.5 - 12.0, y - h, 12.0, h), ARCH)
	draw_rect(Rect2(x - w * 0.5 - 6.0, y - h - 12.0, w + 12.0, 14.0), ARCH)
	var pts := PackedVector2Array()
	for i in range(13):
		var a := PI * float(i) / 12.0
		pts.append(Vector2(x - cos(a) * (w * 0.5 - 12.0), y - h + 2.0 - sin(a) * 26.0))
	draw_polyline(pts, Color(0.35, 0.55, 0.4), 3.0)
	for i in range(14):
		var vx := x - w * 0.5 + 6.0 + float(i) * (w - 12.0) / 13.0
		var vl := 18.0 + float((i * 37) % 54)
		draw_line(Vector2(vx, y - h - 8.0), Vector2(vx + sin(_t + float(i)) * 2.0, y - h - 8.0 + vl), Color(0.25, 0.6, 0.38, 0.9), 2.0)
		draw_circle(Vector2(vx, y - h - 8.0 + vl), 2.5, Color(0.6, 1.0, 0.75, 0.85))
	draw_rect(Rect2(x - 44.0, y - h - 10.0, 88.0, 16.0), Color(0.08, 0.1, 0.09, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(x - 38.0, y - h + 2.0), "GLOWBEDS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.6, 1.0, 0.8, 0.95))
	draw_circle(Vector2(x, y - h - 14.0), 30.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.06))


## Production, processing and stores (USER 2026-10-04: Glowbeds is the farming district). Walks the authored props so the
## things drawn here always stand where the dressing put them: bubbles rising in the culture vats, prepared goods on the
## stock racks (full when Glowbeds is healthy, bare when strained, as canon section 27 asks), and a small sign over each
## working area so you can read what it is for.
func _production() -> void:
	var fill := _stock_fill()
	var signs: Dictionary = {}
	for p in HollowDressing.props():
		var x: float = p["x"]
		var deck := HollowMap.deck_y_at(x, float(p["k"])) - float(p["y_off"])
		match p["kind"]:
			&"culture_vat":
				var phase := float(int(x) % 7)
				for i in range(4):
					var f := fposmod(_t * 0.5 + float(i) * 0.25 + phase * 0.13, 1.0)
					draw_circle(Vector2(x + sin(f * 9.0 + phase) * 8.0, deck - 14.0 - f * 78.0), 2.5, Color(0.75, 1.0, 0.9, 0.7 * (1.0 - f * 0.6)))
				draw_circle(Vector2(x, deck - 56.0), 34.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.07))
				signs["vats"] = Vector2(x - 12.0, deck - 150.0)
			&"stock_rack":
				if p["zone"] != &"glowbeds_lower":
					continue
				_stock(x, deck, float(p["w"]), float(p["h"]), fill, int(x))
				signs["stores"] = Vector2(x, deck - 134.0)
			&"press":
				signs["press"] = Vector2(x, deck - 120.0)
			&"ration_counter":
				signs["rations"] = Vector2(x, deck - 128.0)
	for key in signs.keys():
		var label: String = {"vats": "CULTURE VATS", "stores": "STORES", "press": "PRESS AND DRYING", "rations": "RATIONS"}[key]
		_sign(signs[key], label)
	_sign(Vector2(5370.0, HollowMap.lvl(5.0) - 126.0), "PLANTATION")


func _stock_fill() -> float:
	var d := get_node_or_null("/root/District")
	var c: StringName = &"stable"
	if d != null and d.has_method("get_condition"):
		c = d.get_condition(&"glowbeds")
	match c:
		&"comfortable":
			return 1.0
		&"stable":
			return 0.8
		&"strained":
			return 0.5
		&"shortage":
			return 0.25
		&"critical":
			return 0.0
	return 0.8


## Jars and sacks of prepared goods on a rack's three shelves: how many shows how well stocked Glowbeds is.
func _stock(x: float, deck: float, w: float, h: float, fill: float, seed_v: int) -> void:
	var slots := 12
	var shown := int(roundf(fill * float(slots)))
	for i in range(slots):
		if i >= shown:
			continue
		var shelf := i / 4
		var col := i % 4
		var sx := x - w * 0.5 + 10.0 + float(col) * (w - 20.0) / 3.0
		var sy := deck - (4.0 + float(shelf) * (h - 8.0) / 3.0) - 4.0
		var kind := (i + seed_v) % 3
		if kind == 0:
			draw_rect(Rect2(sx - 5.0, sy - 14.0, 10.0, 14.0), Color(0.3, 0.75, 0.6, 0.9))
			draw_rect(Rect2(sx - 5.0, sy - 14.0, 10.0, 3.0), Color(0.55, 0.4, 0.25))
		elif kind == 1:
			draw_rect(Rect2(sx - 6.0, sy - 12.0, 12.0, 12.0), Color(0.78, 0.66, 0.42))
		else:
			draw_rect(Rect2(sx - 5.0, sy - 15.0, 10.0, 15.0), Color(0.9, 0.7, 0.34, 0.9))
			draw_rect(Rect2(sx - 5.0, sy - 15.0, 10.0, 3.0), Color(0.5, 0.36, 0.2))


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.06, 0.09, 0.08, 0.88))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.45, 0.8, 0.65, 0.65), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.65, 1.0, 0.85, 0.95))
