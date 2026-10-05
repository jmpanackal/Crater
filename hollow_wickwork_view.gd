extends Node2D
## Wickwork as one district (USER 2026-10-04): practical, flexible fabrication, "not merely a blacksmith". The hall H_WK
## is its working floor, tied together by one system and one identity:
##   power     an overhead line shaft along the hall's ceiling turns a row of pulleys, and belts drop from it to the
##             machines, so every bench is visibly driven from the same shaft;
##   cable     the Great Drum, the district's central machine: a big drum wound with cable that turns slowly, feeding a
##             cable up to a ceiling pulley and out east toward Mid Heart (Wickwork's cable is what moors it), with a
##             hoist that carries crates between the repair bay and the street;
##   stores    racks of finished cable, harness and lamps that follow Wickwork's condition (full when healthy, patched
##             and bare when strained, canon section 44);
##   light     a warm amber wash with the forge glow and sparks from the anvils, so it reads as one lit workshop and the
##             only orange-lit space on the west side;
##   signs     a plaque over each working area and an arch with the district's name at each end of the hall.
## Greybox, drawn in code, replaced by real art later. Visual only. Only what is on screen is drawn.

const HALL_ID := &"H_WK"
const DRUM_X := -250.0
const AMBER := Color(1.0, 0.62, 0.25)
const STEEL := Color(0.22, 0.24, 0.27)
const STEEL_HI := Color(0.4, 0.43, 0.47)
const CABLE := Color(0.72, 0.58, 0.38)
const BRASS := Color(0.72, 0.5, 0.26)

var _t := 0.0
var _rect := Rect2()
var _ceiling := 0.0
var _floor := 0.0


func _ready() -> void:
	z_index = 0
	for h in HollowMap.halls():
		if h["id"] != HALL_ID:
			continue
		_ceiling = HollowMap.lvl(float(h["k_top"])) - HollowMap.ROOM_HEIGHT
		_floor = HollowMap.lvl(float(h["k_bottom"]))
		_rect = Rect2(float(h["x0"]), _ceiling, float(h["x1"]) - float(h["x0"]), _floor - _ceiling)


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
	_line_shaft()
	_gear_wall()
	_great_drum()
	_tower()
	_production()
	_sparks()
	_arch(_rect.position.x + 70.0, HollowMap.lvl(8.0))
	_arch(_rect.end.x - 70.0, HollowMap.lvl(8.0))


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
			draw_rect(Rect2(cx, y, 65.0, _rect.size.y / float(bands) + 1.0), Color(AMBER.r, AMBER.g, AMBER.b, (0.01 + 0.04 * f) * edge))


## The overhead line shaft: an axle along the ceiling with pulleys that turn, and belts hanging down to the machines.
func _line_shaft() -> void:
	_shaft(HollowMap.lvl(8.0) - HollowMap.ROOM_HEIGHT - 330.0, 0.6)
	_shaft(_ceiling + 52.0, 1.0)


func _shaft(y: float, speed: float) -> void:
	draw_rect(Rect2(_rect.position.x + 20.0, y - 3.0, _rect.size.x - 40.0, 6.0), STEEL)
	draw_rect(Rect2(_rect.position.x + 20.0, y - 3.0, _rect.size.x - 40.0, 2.0), STEEL_HI)
	var x := _rect.position.x + 60.0
	var i := 0
	while x < _rect.end.x - 40.0:
		draw_rect(Rect2(x - 3.0, y - 60.0, 6.0, 60.0), STEEL) # a hanger
		var r := 15.0 + float((i * 7) % 3) * 4.0
		draw_arc(Vector2(x, y), r, 0.0, TAU, 20, BRASS, 3.0)
		for s in range(4):
			var a := _t * speed * (2.0 if i % 2 == 0 else -2.0) + float(s) * PI * 0.5
			draw_line(Vector2(x, y), Vector2(x, y) + Vector2(cos(a), sin(a)) * (r - 2.0), BRASS.darkened(0.2), 2.0)
		# a belt drops from some pulleys to the floor-level machines
		if i % 3 == 1:
			var drop := 150.0 + float((i * 31) % 90)
			var sway := sin(_t * 1.5 + float(i)) * 2.0
			draw_line(Vector2(x - r, y), Vector2(x - r + sway, y + drop), Color(0.18, 0.13, 0.1), 4.0)
			draw_line(Vector2(x + r, y), Vector2(x + r + sway, y + drop), Color(0.18, 0.13, 0.1), 4.0)
			draw_circle(Vector2(x + sway, y + drop), 9.0, STEEL)
		x += 150.0
		i += 1


## The Great Drum: a big drum wound with cable that turns slowly; a cable leaves it up to a ceiling pulley and east toward
## Mid Heart; a hoist runs crates between the repair bay and the street.
func _great_drum() -> void:
	var c := Vector2(DRUM_X, HollowMap.lvl(9.0) - 174.0)
	var r := 64.0
	draw_circle(c, r + 10.0, STEEL)
	draw_circle(c, r, Color(0.14, 0.12, 0.1))
	for k in range(5):
		draw_arc(c, 18.0 + float(k) * 9.5, 0.0, TAU, 22, CABLE, 5.0) # the wound cable
	var spin := _t * 0.35
	for s in range(8):
		var a := spin + float(s) * TAU / 8.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * (r + 4.0), Color(0.5, 0.34, 0.2), 4.0)
	draw_circle(c, 9.0, BRASS)
	# the cable leaves the drum, up over a pulley at the ceiling, and east toward Mid Heart
	var pulley := Vector2(DRUM_X + 120.0, _ceiling + 44.0)
	draw_line(c + Vector2(r * 0.7, -r * 0.7), pulley + Vector2(-8.0, 8.0), CABLE, 3.0)
	draw_circle(pulley, 14.0, STEEL)
	draw_arc(pulley, 14.0, 0.0, TAU, 16, BRASS, 3.0)
	var east := Vector2(_rect.end.x, HollowMap.lvl(7.0))
	var prev := pulley
	for i in range(1, 21):
		var f := float(i) / 20.0
		var p := pulley.lerp(east, f) + Vector2(0.0, sin(f * PI) * 26.0)
		draw_line(prev, p, CABLE, 3.0)
		prev = p
	# the hoist: a trolley on that cable lowers a crate to the bay, lifts it, carries it east, and returns
	var cyc := fposmod(_t, 18.0) / 18.0
	var hx := pulley.x + 200.0
	var drop := 60.0
	var load := false
	if cyc < 0.2:
		drop = lerpf(60.0, 330.0, cyc / 0.2)
	elif cyc < 0.4:
		drop = lerpf(330.0, 60.0, (cyc - 0.2) / 0.2)
		load = true
	elif cyc < 0.7:
		hx = lerpf(pulley.x + 200.0, pulley.x + 760.0, (cyc - 0.4) / 0.3)
		load = true
		drop = 60.0
	else:
		hx = lerpf(pulley.x + 760.0, pulley.x + 200.0, (cyc - 0.7) / 0.3)
		drop = 60.0
	var t := (hx - pulley.x) / (east.x - pulley.x)
	var trolley := pulley.lerp(east, clampf(t, 0.0, 1.0)) + Vector2(0.0, sin(clampf(t, 0.0, 1.0) * PI) * 26.0)
	draw_rect(Rect2(trolley.x - 12.0, trolley.y - 6.0, 24.0, 12.0), BRASS)
	var hook := trolley + Vector2(0.0, drop)
	draw_line(trolley, hook, STEEL_HI, 2.0)
	draw_rect(Rect2(hook.x - 5.0, hook.y, 10.0, 7.0), BRASS)
	if load:
		draw_rect(Rect2(hook.x - 16.0, hook.y + 7.0, 32.0, 24.0), Color(0.4, 0.3, 0.2))
		draw_rect(Rect2(hook.x - 16.0, hook.y + 7.0, 32.0, 3.0), Color(0, 0, 0, 0.3))
	_sign(Vector2(DRUM_X, c.y - 96.0), "THE GREAT DRUM")


func _production() -> void:
	var fill := _stock_fill()
	var signs: Dictionary = {}
	for p in HollowDressing.props():
		if p["zone"] != &"wickwork":
			continue
		var x: float = p["x"]
		var deck := HollowMap.deck_y_at(x, float(p["k"])) - float(p["y_off"])
		match p["kind"]:
			&"harness_rack":
				if float(p["k"]) == 8.0 and x < -1300.0:
					signs["harness"] = Vector2(x + 40.0, deck - 130.0)
				elif float(p["k"]) == 9.0:
					signs["rig"] = Vector2(x - 40.0, deck - 130.0)
			&"spool_rack":
				if x < -900.0:
					signs["cable"] = Vector2(x + 40.0, deck - 120.0)
			&"stock_rack":
				_stock(x, deck, float(p["w"]), float(p["h"]), fill, int(x))
				signs["stores"] = Vector2(x + 40.0, deck - 130.0)
			&"repair_counter":
				signs["repair"] = Vector2(x, deck - 120.0)
			&"anvil":
				if x < -900.0:
					signs["lamps"] = Vector2(x, deck - 110.0)
			&"furnace":
				signs["forge"] = Vector2(x, deck - 126.0)
	var labels := {"harness": "HARNESS AND BINDING", "cable": "CABLE WORKS", "lamps": "LAMPS AND SEALS", "stores": "STORES", "forge": "FORGE AND FITTINGS", "repair": "REPAIR INTAKE", "rig": "RIG AND TETHERS"}
	for key in signs.keys():
		_sign(signs[key], labels[key])


func _stock_fill() -> float:
	var d := get_node_or_null("/root/District")
	var c: StringName = &"stable"
	if d != null and d.has_method("get_condition"):
		c = d.get_condition(&"wickwork")
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


## Finished goods on a stock rack: coils of cable, harness bundles and lamp housings. How many shows how well stocked
## Wickwork is.
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
			draw_arc(Vector2(sx, sy - 7.0), 7.0, 0.0, TAU, 12, CABLE, 3.0)
		elif kind == 1:
			draw_rect(Rect2(sx - 6.0, sy - 12.0, 12.0, 12.0), Color(0.5, 0.34, 0.2))
			draw_line(Vector2(sx - 6.0, sy - 6.0), Vector2(sx + 6.0, sy - 6.0), IRON_BAND, 1.5)
		else:
			draw_rect(Rect2(sx - 5.0, sy - 14.0, 10.0, 14.0), Color(0.72, 0.5, 0.26))
			draw_circle(Vector2(sx, sy - 7.0), 3.0, Color(1.0, 0.82, 0.45))


const IRON_BAND := Color(0.25, 0.25, 0.27)


## Sparks off the anvils and furnaces: short bright streaks that arc out and fall, a few at a time.
func _sparks() -> void:
	for p in HollowDressing.props():
		if p["zone"] != &"wickwork" or (p["kind"] != &"anvil" and p["kind"] != &"furnace"):
			continue
		var x: float = p["x"]
		var deck := HollowMap.deck_y_at(x, float(p["k"]))
		for i in range(6):
			var f := fposmod(_t * 1.1 + float(i) * 0.17 + x * 0.003, 1.0)
			var ang := -PI * 0.5 + (float((i * 37) % 11) - 5.0) * 0.1
			var v := 46.0 + float((i * 13) % 30)
			var p0 := Vector2(x, deck - 24.0)
			var pos := p0 + Vector2(cos(ang), sin(ang)) * v * f + Vector2(0.0, 70.0 * f * f)
			draw_circle(pos, 1.8, Color(1.0, 0.8 - 0.3 * f, 0.3, 1.0 - f))


func _sign(at: Vector2, text: String) -> void:
	var w := 9.0 * float(text.length()) + 14.0
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.1, 0.07, 0.05, 0.9))
	draw_rect(Rect2(at.x - w * 0.5, at.y - 12.0, w, 18.0), Color(0.9, 0.6, 0.3, 0.7), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(at.x - w * 0.5 + 7.0, at.y + 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 0.82, 0.55, 0.95))


## An arch of riveted iron over the street with the district's name, so you know you have arrived.
func _arch(x: float, y: float) -> void:
	var w := 120.0
	var h := 150.0
	draw_rect(Rect2(x - w * 0.5, y - h, 12.0, h), STEEL)
	draw_rect(Rect2(x + w * 0.5 - 12.0, y - h, 12.0, h), STEEL)
	draw_rect(Rect2(x - w * 0.5 - 6.0, y - h - 12.0, w + 12.0, 14.0), STEEL)
	for rx in [x - w * 0.5 + 6.0, x + w * 0.5 - 6.0]:
		for ry in range(4):
			draw_circle(Vector2(rx, y - h + 16.0 + float(ry) * 34.0), 2.0, BRASS)
	draw_rect(Rect2(x - 46.0, y - h - 10.0, 92.0, 16.0), Color(0.1, 0.07, 0.05, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(x - 40.0, y - h + 2.0), "WICKWORK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(1.0, 0.8, 0.5, 0.95))
	# a hung lantern from the arch
	draw_line(Vector2(x, y - h + 6.0), Vector2(x, y - h + 28.0), Color(0.3, 0.22, 0.14), 1.5)
	draw_circle(Vector2(x, y - h + 34.0), 5.0, Color(1.0, 0.75, 0.4, 0.95))
	draw_circle(Vector2(x, y - h + 34.0), 24.0, Color(AMBER.r, AMBER.g, AMBER.b, 0.07))


## A wall of meshing gears on the hall's back wall between the street and the bay: a train of wheels, each driving the next,
## so the whole thing turns together (neighbours turn opposite ways, a small wheel faster than a large one).
const GEARS := [
	[-720.0, 90.0, 11], [-575.0, 60.0, 8], [-455.0, 100.0, 12], [-300.0, 52.0, 7], [-190.0, 70.0, 9], [-55.0, 96.0, 12],
]


func _gear_wall() -> void:
	var cy := HollowMap.lvl(8.0) + 150.0
	var base_speed := 0.5
	var dir := 1.0
	for i in range(GEARS.size()):
		var g: Array = GEARS[i]
		var r: float = g[1]
		var teeth: int = g[2] * 2
		var ang := _t * base_speed * (90.0 / r) * dir
		_gear(Vector2(g[0], cy + (float((i * 53) % 40) - 20.0)), r, teeth, ang, i)
		dir = -dir


func _gear(c: Vector2, r: float, teeth: int, ang: float, seed_v: int) -> void:
	var tone := Color(0.46, 0.3, 0.2).lerp(Color(0.6, 0.42, 0.26), float(seed_v % 3) / 3.0)
	draw_circle(c, r, Color(0.12, 0.09, 0.07, 0.92))
	for t in range(teeth):
		var a := ang + float(t) * TAU / float(teeth)
		var p0 := c + Vector2(cos(a), sin(a)) * (r - 3.0)
		var p1 := c + Vector2(cos(a), sin(a)) * (r + 11.0)
		draw_line(p0, p1, tone, 9.0)
	draw_arc(c, r, 0.0, TAU, 40, tone, 5.0)
	for s in range(5):
		var a2 := ang + float(s) * TAU / 5.0
		draw_line(c, c + Vector2(cos(a2), sin(a2)) * (r - 6.0), tone.darkened(0.15), 6.0)
	draw_circle(c, r * 0.2, BRASS)
	draw_circle(c, r * 0.07, Color(0.12, 0.09, 0.07))


## The Foundry Tower: Wickwork's landmark at the forge end. A tall brick works that rises through the hall into the
## vault, with a furnace mouth glowing at its foot, a great turning wheel on its face, lit windows, two chimneys that
## pierce the vault and smoke, and a gantry. Everything the forge makes (fittings, rivets, lamp frames) comes from here.
func _tower() -> void:
	var x0 := 580.0
	var x1 := 1100.0
	var deck := HollowMap.lvl(8.0)
	var h := 560.0
	var top := deck - h
	# body
	draw_rect(Rect2(x0, top, x1 - x0, h), Color(0.3, 0.2, 0.15))
	for row in range(int(h / 24.0)):
		var by := top + float(row) * 24.0
		draw_line(Vector2(x0, by), Vector2(x1, by), Color(0.2, 0.13, 0.1, 0.7), 1.5)
		var off := 18.0 if row % 2 == 0 else 0.0
		var bx := x0 + off
		while bx < x1:
			draw_line(Vector2(bx, by), Vector2(bx, by + 24.0), Color(0.2, 0.13, 0.1, 0.5), 1.0)
			bx += 36.0
	draw_rect(Rect2(x0 - 10.0, top - 12.0, x1 - x0 + 20.0, 16.0), Color(0.18, 0.12, 0.1))
	draw_rect(Rect2(x0 - 6.0, deck - 18.0, x1 - x0 + 12.0, 18.0), Color(0.18, 0.12, 0.1))
	# lit windows in two tiers
	for tier in range(3):
		for i in range(4):
			var wx := x0 + 40.0 + float(i) * 118.0
			var wy := top + 40.0 + float(tier) * 90.0
			var flick := 0.7 + 0.3 * sin(_t * 3.0 + float(i + tier * 4))
			draw_rect(Rect2(wx, wy, 34.0, 46.0), Color(0.1, 0.07, 0.05))
			draw_rect(Rect2(wx + 3.0, wy + 3.0, 28.0, 40.0), Color(1.0, 0.62, 0.25, 0.8 * flick))
			draw_circle(Vector2(wx + 17.0, wy + 23.0), 40.0, Color(1.0, 0.6, 0.2, 0.05 * flick))
	# the great wheel on the face, turning
	var wc := Vector2((x0 + x1) * 0.5, top + 330.0)
	_gear(wc, 96.0, 28, _t * 0.28, 1)
	draw_circle(wc, 140.0, Color(1.0, 0.55, 0.2, 0.04))
	# the furnace mouth at the foot: a big arch with a roaring fire
	var fx := (x0 + x1) * 0.5
	var flick2 := 0.75 + 0.25 * sin(_t * 6.0) * sin(_t * 2.1)
	draw_rect(Rect2(fx - 62.0, deck - 96.0, 124.0, 96.0), Color(0.06, 0.04, 0.03))
	draw_rect(Rect2(fx - 52.0, deck - 86.0, 104.0, 86.0), Color(1.0, 0.45, 0.12, 0.85 * flick2))
	draw_rect(Rect2(fx - 36.0, deck - 70.0, 72.0, 70.0), Color(1.0, 0.82, 0.38, 0.9 * flick2))
	draw_circle(Vector2(fx, deck - 50.0), 150.0, Color(1.0, 0.5, 0.15, 0.09 * flick2))
	draw_circle(Vector2(fx, deck - 50.0), 80.0, Color(1.0, 0.6, 0.2, 0.1 * flick2))
	# a door either side of the mouth, and sparks from the mouth
	for dx in [x0 + 40.0, x1 - 76.0]:
		draw_rect(Rect2(dx, deck - 70.0, 36.0, 70.0), Color(0.1, 0.07, 0.05))
		draw_rect(Rect2(dx + 3.0, deck - 66.0, 30.0, 66.0), Color(0.34, 0.22, 0.14))
	for i in range(8):
		var f := fposmod(_t * 0.9 + float(i) * 0.125, 1.0)
		var ang := -PI * 0.5 + (float((i * 37) % 13) - 6.0) * 0.12
		draw_circle(Vector2(fx, deck - 40.0) + Vector2(cos(ang), sin(ang)) * 90.0 * f + Vector2(0.0, 60.0 * f * f), 2.0, Color(1.0, 0.8 - 0.3 * f, 0.3, 1.0 - f))
	# two chimneys that pierce the vault, with smoke
	for cx in [x0 + 120.0, x1 - 120.0]:
		draw_rect(Rect2(cx - 22.0, top - 70.0, 44.0, 70.0), Color(0.36, 0.22, 0.14))
		draw_rect(Rect2(cx - 28.0, top - 78.0, 56.0, 14.0), Color(0.2, 0.13, 0.1))
		for i in range(5):
			var f := fposmod(_t * 0.25 + float(i) * 0.2 + cx * 0.001, 1.0)
			draw_circle(Vector2(cx + sin(f * 6.0 + float(i)) * 14.0, top - 90.0 - f * 70.0), 14.0 + 18.0 * f, Color(0.5, 0.5, 0.52, 0.22 * (1.0 - f)))
	# a gantry on the left face, with a small turning wheel
	draw_rect(Rect2(x0 - 70.0, top + 200.0, 70.0, 8.0), STEEL)
	draw_line(Vector2(x0 - 66.0, top + 208.0), Vector2(x0 - 6.0, top + 280.0), STEEL, 3.0)
	_gear(Vector2(x0 - 34.0, top + 170.0), 30.0, 10, -_t * 0.7, 3)
	_sign(Vector2(fx, top - 100.0), "THE FOUNDRY")
