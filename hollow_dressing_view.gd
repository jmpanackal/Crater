extends Node2D
## Draws HollowDressing: building interiors and facades, props, lamps. Greybox: flat coloured
## shapes that read at player scale. One instance draws the BACK layer (behind the player:
## interiors, furniture, lamp glow) and one the FRONT layer (railings, brace posts, hanging cloth).
## Nothing here collides, so it never changes where the player can walk.

const PLASTER := Color(0.62, 0.52, 0.41)
const PLASTER_DIM := Color(0.36, 0.31, 0.27)
const WALL_COOL := Color(0.27, 0.3, 0.3)
const WAINSCOT := Color(0.25, 0.21, 0.18)
const TIMBER := Color(0.46, 0.33, 0.21)
const TIMBER_DARK := Color(0.3, 0.22, 0.15)
const IRON := Color(0.3, 0.32, 0.33)
const IRON_LIGHT := Color(0.5, 0.52, 0.52)
const COPPER := Color(0.72, 0.45, 0.28)
const SLATE := Color(0.2, 0.22, 0.23)
const SLATE_LIGHT := Color(0.32, 0.34, 0.34)
const FUNGUS := Color(0.42, 0.5, 0.3)
const DOOR := Color(0.2, 0.15, 0.12)
const GLOW := {
	&"warm": Color(1.0, 0.78, 0.45),
	&"cool": Color(0.55, 0.85, 0.88),
	&"amber": Color(1.0, 0.62, 0.2),
	&"red": Color(0.95, 0.28, 0.24),
}
const ORE := {&"ravel": Color(0.5, 0.56, 0.64), &"sutral": Color(0.58, 0.66, 0.38), &"wreck": Color(0.4, 0.36, 0.32)}

@export var layer: StringName = HollowDressing.LAYER_BACK
## One instance per chunk (a level band and a 1024 px slice) so the engine skips what is off
## screen: -999 / +-1e9 mean "everything".
@export var chunk_k := -999
@export var chunk_x0 := -1.0e9
@export var chunk_x1 := 1.0e9

const MOSS_COLOR := Color(0.1, 0.36, 0.3)
const CRYSTAL_TONES: Array[Color] = [Color(0.3, 0.85, 0.82), Color(0.35, 0.55, 1.0), Color(0.68, 0.45, 0.95), Color(1.0, 0.72, 0.32)]


func _ready() -> void:
	z_index = -1 if layer == HollowDressing.LAYER_BACK else 3
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var journal := get_tree().root.get_node_or_null("Journal")
	if journal != null and journal.has_signal("records_changed"):
		journal.records_changed.connect(queue_redraw)
	queue_redraw()


func _band(k: int) -> bool:
	return chunk_k == -999 or k == chunk_k


func _mine(x: float) -> bool:
	return x >= chunk_x0 and x < chunk_x1


func _draw() -> void:
	if layer == HollowDressing.LAYER_BACK:
		for r in HollowMap.runs():
			if absf(float(r["k"]) - float(chunk_k)) < 0.01 or chunk_k == -999:
				_decor_for_run(r)
		for b in HollowDressing.buildings():
			if _band(int(b["k"])) and float(b["x1"]) > chunk_x0 and float(b["x0"]) < chunk_x1:
				_draw_building(b)
	for p in HollowDressing.props():
		if p["layer"] == layer and _band(int(p["k"])) and _mine(float(p["x"])):
			_draw_prop(p)
	if layer == HollowDressing.LAYER_BACK:
		for l in HollowDressing.lamps():
			if _band(int(l["k"])) and _mine(float(l["x"])):
				_draw_lamp(l)


func _rnd(a: float, b: float, salt: int) -> float:
	return HollowRockView.hash01(a, b, salt)


## Moss, hanging strands and glow crystals on the rock under a floor: the living detail on the
## stone (the rock itself is hollow_rock_view.gd). Slots are fixed in world space.
func _decor_for_run(r: Dictionary) -> void:
	if HollowMap.is_heart_zone(r["zone"]):
		return
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	if HollowMap.in_flank(x0) and HollowMap.in_flank(x1):
		return
	x0 = maxf(x0, HollowMap.WEST_WALL) if HollowMap.in_flank(x0) else x0
	x1 = minf(x1, HollowMap.EAST_WALL) if HollowMap.in_flank(x1) else x1
	var deck: float = r["y"]
	var bottom := deck + 16.0 + HollowRockView.SLAB
	var lo := maxf(x0, chunk_x0)
	var hi := minf(x1, chunk_x1)
	var i := int(floorf(lo / 24.0))
	while float(i) * 24.0 < hi:
		var x := float(i) * 24.0 + _rnd(float(i), deck, 31) * 16.0
		var roll := _rnd(float(i), deck, 32)
		if x >= lo and x < hi:
			if roll < 0.2:
				# a hanging strand of moss with a glowing tip
				var len := 12.0 + _rnd(float(i), deck, 33) * 30.0
				var kink := (_rnd(float(i), deck, 34) - 0.5) * 6.0
				draw_polyline(PackedVector2Array([Vector2(x, bottom + 4.0), Vector2(x + kink, bottom + len * 0.55), Vector2(x - kink * 0.5, bottom + len)]), Color(MOSS_COLOR.r, MOSS_COLOR.g, MOSS_COLOR.b, 0.9), 1.5)
				draw_rect(Rect2(x - kink * 0.5 - 1.0, bottom + len - 1.0, 2.0, 2.0), Color(0.5, 1.0, 0.85, 0.9))
			elif roll < 0.3:
				_moss_blob(Vector2(x, deck + 18.0), 10.0 + _rnd(float(i), deck, 35) * 12.0)
			elif roll > 0.94:
				_crystal_cluster(Vector2(x, bottom + 2.0), -1.0, int(_rnd(float(i), deck, 36) * 4.0))
		i += 1


## An irregular patch of moss on a ledge (no circles): a ragged blob, a darker underside, bright dots.
func _moss_blob(c: Vector2, w: float) -> void:
	var pts := PackedVector2Array()
	var n := 7
	for k in n:
		var t := float(k) / float(n) * PI
		pts.append(Vector2(c.x - w * 0.5 + w * (1.0 - cos(t)) * 0.5, c.y - sin(t) * (3.0 + _rnd(c.x, float(k), 41) * 5.0)))
	pts.append(Vector2(c.x + w * 0.5, c.y))
	pts.append(Vector2(c.x - w * 0.5, c.y))
	draw_colored_polygon(pts, Color(MOSS_COLOR.r, MOSS_COLOR.g, MOSS_COLOR.b, 0.85))
	draw_rect(Rect2(c.x - w * 0.5, c.y - 1.0, w, 2.0), Color(0.04, 0.16, 0.13, 0.9))
	for k in 3:
		draw_rect(Rect2(c.x - w * 0.35 + float(k) * w * 0.32, c.y - 4.0 - _rnd(c.x, float(k), 42) * 3.0, 1.5, 1.5), Color(0.5, 1.0, 0.8, 0.85))


## A cluster of angular crystal shards in one colour, each lit on one face. dir -1 hangs down, +1 grows up.
func _crystal_cluster(p: Vector2, dir: float, tone_index: int = 0) -> void:
	var tone: Color = CRYSTAL_TONES[tone_index % CRYSTAL_TONES.size()]
	for g in 3:
		draw_circle(p + Vector2(0.0, -dir * 7.0), 26.0 - float(g) * 8.0, Color(tone.r, tone.g, tone.b, 0.05))
	var shards := 4
	for k in shards:
		var h := (10.0 + _rnd(p.x, float(k), 51) * 14.0) * dir
		var ox := (float(k) - 1.5) * 4.2
		var lean := (_rnd(p.x, float(k), 52) - 0.5) * 6.0
		var base_l := Vector2(p.x + ox - 2.6, p.y)
		var base_r := Vector2(p.x + ox + 2.6, p.y)
		var tip := Vector2(p.x + ox + lean, p.y - h)
		draw_colored_polygon(PackedVector2Array([base_l, tip, base_r]), tone.darkened(0.25))
		draw_colored_polygon(PackedVector2Array([base_l, tip, Vector2(p.x + ox, p.y)]), tone.lightened(0.18))
		draw_line(tip, Vector2(p.x + ox + lean * 0.2, p.y - h * 0.2), Color(1, 1, 1, 0.55), 1.0)


## Rect standing on the deck: x centre, offset from the deck upward, size.
func _box(deck: float, cx: float, up: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(cx - w * 0.5, deck - up - h, w, h), color)


func _line_up(deck: float, x0: float, up0: float, x1: float, up1: float, color: Color, width: float = 2.0) -> void:
	draw_line(Vector2(x0, deck - up0), Vector2(x1, deck - up1), color, width)


func _poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)


## ---------------------------------------------------------------- buildings

func _draw_building(b: Dictionary) -> void:
	var deck := HollowMap.deck_y_at((float(b["x0"]) + float(b["x1"])) * 0.5, float(b["k"])) - float(b["y_off"])
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var h: float = b["height"]
	var w := x1 - x0
	var kind: StringName = b["kind"]
	if kind == &"nook":
		draw_rect(Rect2(x0, deck - h, w, h), Color(0.12, 0.1, 0.09))
		draw_rect(Rect2(x0, deck - h, w, 4.0), Color(0.07, 0.06, 0.05))
		draw_rect(Rect2(x0 + 6.0, deck - h * 0.45, w - 12.0, 3.0), TIMBER_DARK)
		return
	# Warm dressed stone for homes, cooler for the working yards, both dimmed so props read.
	var warm := (kind == &"unit" and float(b.get("warm", 0.0)) > 0.0) or (kind == &"facade" and bool(b.get("homely", false)))
	var stone := Color(0.5, 0.4, 0.29) if warm else Color(0.36, 0.34, 0.3)
	var wall_tex := RockTextures.brick(96, 96, stone)
	var dim := Color(0.78, 0.78, 0.8)
	var lo := maxf(x0, chunk_x0)
	var hi := minf(x1, chunk_x1)
	var bx := floorf(lo / 96.0) * 96.0
	while bx < hi:
		var by := floorf((deck - h) / 96.0) * 96.0
		while by < deck:
			var rx0 := maxf(lo, bx)
			var ry0 := maxf(deck - h, by)
			var rx1 := minf(hi, bx + 96.0)
			var ry1 := minf(deck, by + 96.0)
			if rx1 > rx0 and ry1 > ry0:
				draw_texture_rect_region(wall_tex, Rect2(rx0, ry0, rx1 - rx0, ry1 - ry0), Rect2(rx0 - bx, ry0 - by, rx1 - rx0, ry1 - ry0), dim)
			by += 96.0
		bx += 96.0
	# a dark band where the wall meets the floor, and the ceiling's shadow
	draw_rect(Rect2(lo, deck - 22.0, hi - lo, 22.0), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(lo, deck - h, hi - lo, 26.0), Color(0.0, 0.0, 0.0, 0.3))
	# dressed stone piers at the ends, with copper plates
	for px in [x0, x1 - 14.0]:
		if not _mine(px):
			continue
		draw_rect(Rect2(px, deck - h, 14.0, h), Color(0.3, 0.27, 0.24))
		draw_rect(Rect2(px + 1.0, deck - h, 3.0, h), Color(0.42, 0.38, 0.33))
		draw_rect(Rect2(px - 2.0, deck - h + 40.0, 18.0, 14.0), Color(0.34, 0.5, 0.45))
		draw_rect(Rect2(px - 2.0, deck - 60.0, 18.0, 14.0), Color(0.34, 0.5, 0.45))
		draw_circle(Vector2(px + 7.0, deck - h + 47.0), 1.6, COPPER)
	for dx in b["doors"]:
		if _mine(float(dx)):
			_draw_door(deck, float(dx), 56.0)
	for wx in b["windows"]:
		if _mine(float(wx)):
			_draw_window(deck, float(wx), minf(h * 0.55, 96.0))


func _draw_door(deck: float, x: float, h: float) -> void:
	# a stone arch round a plank door
	var hh := h + 6.0
	draw_rect(Rect2(x - 22.0, deck - hh + 16.0, 44.0, hh - 16.0), Color(0.32, 0.28, 0.24))
	draw_circle(Vector2(x, deck - hh + 22.0), 22.0, Color(0.32, 0.28, 0.24))
	draw_rect(Rect2(x - 17.0, deck - h + 14.0, 34.0, h - 14.0), Color(0.3, 0.2, 0.12))
	draw_circle(Vector2(x, deck - h + 20.0), 17.0, Color(0.3, 0.2, 0.12))
	for i in 5:
		draw_line(Vector2(x - 12.0 + float(i) * 6.0, deck - h + 8.0 + absf(float(i) - 2.0) * 3.0), Vector2(x - 12.0 + float(i) * 6.0, deck - 2.0), Color(0.18, 0.12, 0.08), 1.0)
	draw_rect(Rect2(x - 17.0, deck - h * 0.62, 34.0, 3.0), IRON)
	draw_rect(Rect2(x - 17.0, deck - h * 0.25, 34.0, 3.0), IRON)
	draw_circle(Vector2(x + 10.0, deck - h * 0.45), 1.8, COPPER)
	draw_rect(Rect2(x - 22.0, deck - 4.0, 44.0, 4.0), Color(0.45, 0.4, 0.34))


func _draw_window(deck: float, x: float, up: float) -> void:
	# an arched niche with a glowing pane
	draw_rect(Rect2(x - 12.0, deck - up - 16.0, 24.0, 16.0), Color(0.3, 0.26, 0.22))
	draw_circle(Vector2(x, deck - up - 16.0), 12.0, Color(0.3, 0.26, 0.22))
	draw_rect(Rect2(x - 9.0, deck - up - 15.0, 18.0, 13.0), Color(1.0, 0.72, 0.38, 0.55))
	draw_circle(Vector2(x, deck - up - 15.0), 9.0, Color(1.0, 0.72, 0.38, 0.55))
	draw_line(Vector2(x, deck - up - 24.0), Vector2(x, deck - up - 2.0), Color(0.3, 0.26, 0.22), 1.5)


## ---------------------------------------------------------------- lamps

func _draw_lamp(l: Dictionary) -> void:
	var deck := HollowMap.deck_y_at(float(l["x"]), float(l["k"]))
	var c: Color = GLOW[l["tone"]]
	var p := Vector2(float(l["x"]), deck - float(l["y_off"]))
	draw_circle(p, 56.0, Color(c.r, c.g, c.b, 0.04))
	draw_circle(p, 30.0, Color(c.r, c.g, c.b, 0.07))
	draw_circle(p, 12.0, Color(c.r, c.g, c.b, 0.12))
	# a lantern on a chain from the ceiling (a short bracket for the warm wall lamps)
	var ceiling := deck - (HollowMap.FLANK_CLEAR if HollowMap.in_flank(p.x) else HollowMap.ROOM_HEIGHT)
	if l["tone"] != &"warm":
		draw_line(Vector2(p.x, ceiling), Vector2(p.x, p.y - 9.0), Color(0.45, 0.34, 0.24), 1.5)
	else:
		draw_line(Vector2(p.x - 9.0, p.y - 4.0), Vector2(p.x, p.y - 4.0), COPPER, 2.0)
	draw_rect(Rect2(p.x - 4.0, p.y - 11.0, 8.0, 3.0), COPPER)
	_poly(PackedVector2Array([Vector2(p.x - 6.0, p.y - 8.0), Vector2(p.x + 6.0, p.y - 8.0), Vector2(p.x + 7.0, p.y + 4.0), Vector2(p.x + 3.0, p.y + 9.0), Vector2(p.x - 3.0, p.y + 9.0), Vector2(p.x - 7.0, p.y + 4.0)]), Color(c.r, c.g, c.b, 0.92))
	draw_line(Vector2(p.x - 3.0, p.y - 6.0), Vector2(p.x - 3.0, p.y + 4.0), Color(1.0, 1.0, 1.0, 0.35), 1.0)
	draw_rect(Rect2(p.x - 4.0, p.y + 8.0, 8.0, 3.0), COPPER)


## ---------------------------------------------------------------- props

func _draw_prop(p: Dictionary) -> void:
	var deck := HollowMap.deck_y_at(float(p["x"]), float(p["k"])) - float(p["y_off"])
	var x: float = p["x"]
	var w: float = p["w"]
	var h: float = p["h"]
	var tone: StringName = p.get("tone", &"")
	match p["kind"]:
		&"bed":
			_box(deck, x, 0.0, w, 10.0, TIMBER)
			_box(deck, x, 10.0, w - 6.0, 9.0, Color(0.62, 0.56, 0.46))
			_box(deck, x - w * 0.5 + 12.0, 19.0, 15.0, 6.0, Color(0.82, 0.78, 0.68))
			_box(deck, x + 10.0, 19.0, w * 0.55, 4.0, Color(0.36, 0.45, 0.4))
			_box(deck, x - w * 0.5 + 2.0, 0.0, 3.0, 22.0, TIMBER_DARK)
		&"lockbox":
			_box(deck, x, 0.0, w, h, Color(0.38, 0.28, 0.2))
			_box(deck, x, h - 5.0, w, 5.0, TIMBER_DARK)
			draw_circle(Vector2(x, deck - h * 0.45), 2.4, COPPER)
		&"workbench":
			_box(deck, x, h - 6.0, w, 6.0, TIMBER)
			_box(deck, x - w * 0.5 + 4.0, 0.0, 5.0, h - 6.0, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 4.0, 0.0, 5.0, h - 6.0, TIMBER_DARK)
			_box(deck, x - 14.0, h, 14.0, 3.0, IRON_LIGHT)
			_box(deck, x + 8.0, h, 18.0, 4.0, Color(0.55, 0.4, 0.26))
			_box(deck, x + 20.0, h, 6.0, 8.0, COPPER)
		&"hook":
			_box(deck, x, 0.0, 4.0, h, IRON)
			_line_up(deck, x, h - 8.0, x + 9.0, h - 14.0, COPPER, 2.0)
			_box(deck, x + 9.0, h - 28.0, 11.0, 14.0, Color(0.55, 0.45, 0.32))
		&"pot":
			_poly(PackedVector2Array([Vector2(x - w * 0.4, deck), Vector2(x + w * 0.4, deck), Vector2(x + w * 0.5, deck - h * 0.6), Vector2(x + w * 0.25, deck - h), Vector2(x - w * 0.25, deck - h), Vector2(x - w * 0.5, deck - h * 0.6)]), Color(0.55, 0.38, 0.26))
			_box(deck, x, h * 0.45, w * 0.8, 2.0, Color(0.72, 0.6, 0.4))
		&"rug":
			_box(deck, x, 0.0, w, h, Color(0.55, 0.32, 0.26))
			_box(deck, x, 1.0, w - 10.0, 2.0, Color(0.78, 0.6, 0.36))
		&"fungal_mat":
			_poly(PackedVector2Array([Vector2(x - w * 0.5, deck), Vector2(x - w * 0.3, deck - h), Vector2(x + w * 0.3, deck - h * 0.9), Vector2(x + w * 0.5, deck)]), FUNGUS)
			draw_circle(Vector2(x - 4.0, deck - h * 0.55), 1.6, Color(0.7, 0.8, 0.55))
			draw_circle(Vector2(x + 5.0, deck - h * 0.4), 1.4, Color(0.7, 0.8, 0.55))
		&"stove":
			var pipe_top := deck - (HollowMap.ROOM_HEIGHT - 20.0)
			_box(deck, x, h - 4.0, 8.0, HollowMap.ROOM_HEIGHT - 20.0 - h + 4.0, IRON)
			draw_rect(Rect2(x - 4.0, pipe_top, 8.0, 4.0), IRON_LIGHT)
			_box(deck, x, 0.0, w, h * 0.72, Color(0.26, 0.24, 0.23))
			_box(deck, x, 6.0, w * 0.5, 14.0, Color(1.0, 0.62, 0.25, 0.85))
			_box(deck, x, h * 0.72, w + 6.0, 4.0, IRON)
		&"basin":
			_box(deck, x - 6.0, 0.0, 10.0, h - 12.0, Color(0.5, 0.47, 0.42))
			_poly(PackedVector2Array([Vector2(x - w * 0.5, deck - h + 12.0), Vector2(x + w * 0.5, deck - h + 12.0), Vector2(x + w * 0.35, deck - h + 24.0), Vector2(x - w * 0.35, deck - h + 24.0)]), Color(0.6, 0.56, 0.5))
			_box(deck, x + w * 0.5 - 4.0, h - 6.0, 4.0, 60.0, COPPER)
			_box(deck, x + w * 0.35, h - 6.0, 14.0, 3.0, COPPER)
		&"laundry":
			var top := deck - h
			draw_line(Vector2(x - w * 0.5, top), Vector2(x + w * 0.5, top + 6.0), Color(0.3, 0.25, 0.2), 1.5)
			var cloth := [Color(0.82, 0.78, 0.68, 0.92), Color(0.55, 0.62, 0.7, 0.92), Color(0.78, 0.5, 0.38, 0.92), Color(0.7, 0.68, 0.5, 0.92)]
			for i in 4:
				var cx := x - w * 0.5 + 14.0 + float(i) * (w - 28.0) / 3.0
				draw_rect(Rect2(cx - 8.0, top + 3.0, 16.0, 26.0 + float(i % 2) * 8.0), cloth[i])
		&"crate":
			_box(deck, x, 0.0, w, h, TIMBER)
			draw_rect(Rect2(x - w * 0.5, deck - h, w, h), TIMBER_DARK, false, 1.0)
			draw_line(Vector2(x - w * 0.5, deck - h), Vector2(x + w * 0.5, deck), TIMBER_DARK, 1.0)
		&"barrel":
			_box(deck, x, 0.0, w, h, Color(0.4, 0.3, 0.2))
			_box(deck, x, 6.0, w + 2.0, 2.0, IRON)
			_box(deck, x, h - 8.0, w + 2.0, 2.0, IRON)
		&"rack":
			_box(deck, x - w * 0.5 + 3.0, 0.0, 4.0, h, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 3.0, 0.0, 4.0, h, TIMBER_DARK)
			for i in 3:
				_box(deck, x, 12.0 + float(i) * 16.0, w, 3.0, TIMBER)
			_line_up(deck, x - 18.0, 4.0, x - 12.0, 46.0, IRON_LIGHT, 2.0)
			_line_up(deck, x, 4.0, x + 4.0, 40.0, Color(0.55, 0.4, 0.26), 2.0)
			_box(deck, x + 4.0, 38.0, 14.0, 5.0, IRON_LIGHT)
			_line_up(deck, x + 18.0, 4.0, x + 16.0, 44.0, IRON_LIGHT, 2.0)
		&"shift_board":
			_box(deck, x - w * 0.5 + 2.0, 0.0, 4.0, 14.0, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 2.0, 0.0, 4.0, 14.0, TIMBER_DARK)
			_box(deck, x, 14.0, w, h - 14.0, Color(0.2, 0.18, 0.16))
			_box(deck, x, h - 8.0, w, 8.0, Color(0.78, 0.6, 0.28))
			for i in 4:
				_box(deck, x - w * 0.5 + 8.0 + float(i) * 15.0, 20.0, 10.0, 8.0 + float(i % 3) * 8.0, Color(0.72, 0.68, 0.58))
		&"scale":
			_box(deck, x, 0.0, 6.0, h - 8.0, IRON)
			_box(deck, x, h - 10.0, w, 3.0, IRON_LIGHT)
			_box(deck, x - w * 0.4, h - 18.0, 12.0, 4.0, COPPER)
			_box(deck, x + w * 0.4, h - 22.0, 12.0, 4.0, COPPER)
			_box(deck, x, 0.0, 22.0, 5.0, IRON)
		&"beam_stack":
			var rows := int(h / 10.0)
			for i in rows:
				_box(deck, x + float(i % 2) * 4.0 - 2.0, float(i) * 10.0, w - float(i % 2) * 6.0, 9.0, TIMBER if i % 2 == 0 else Color(0.52, 0.38, 0.24))
		&"turntable":
			draw_set_transform(Vector2(x, deck - 2.0), 0.0, Vector2(1.0, 0.1))
			draw_circle(Vector2.ZERO, w * 0.5, IRON)
			draw_circle(Vector2.ZERO, w * 0.18, IRON_LIGHT)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		&"cart":
			var ore: Color = ORE.get(tone, Color(0.5, 0.45, 0.38))
			var flip: float = p["flip"]
			if tone == &"wreck":
				draw_set_transform(Vector2(x, deck), 0.5 * flip, Vector2.ONE)
				draw_rect(Rect2(-w * 0.5, -h, w, h * 0.8), TIMBER_DARK)
				draw_circle(Vector2(-w * 0.3, -2.0), 6.0, IRON)
				draw_circle(Vector2(w * 0.3, -2.0), 6.0, IRON)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				_poly(PackedVector2Array([Vector2(x - w * 0.5, deck - 10.0), Vector2(x + w * 0.5, deck - 10.0), Vector2(x + w * 0.4, deck - h), Vector2(x - w * 0.4, deck - h)]), TIMBER)
				_poly(PackedVector2Array([Vector2(x - w * 0.36, deck - h), Vector2(x + w * 0.36, deck - h), Vector2(x + w * 0.2, deck - h - 9.0), Vector2(x - w * 0.2, deck - h - 9.0)]), ore)
				draw_circle(Vector2(x - w * 0.3, deck - 6.0), 6.0, IRON)
				draw_circle(Vector2(x + w * 0.3, deck - 6.0), 6.0, IRON)
		&"dais":
			_box(deck, x, 0.0, w, h, Color(0.4, 0.33, 0.27))
			_box(deck, x, h - 4.0, w, 4.0, Color(0.56, 0.46, 0.34))
		&"arch":
			_box(deck, x - w * 0.5 + 6.0, 0.0, 12.0, h, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 6.0, 0.0, 12.0, h, TIMBER_DARK)
			_box(deck, x, h - 14.0, w, 14.0, TIMBER)
			_line_up(deck, x - w * 0.5 + 12.0, h - 40.0, x - w * 0.5 + 40.0, h - 14.0, TIMBER, 5.0)
			_line_up(deck, x + w * 0.5 - 12.0, h - 40.0, x + w * 0.5 - 40.0, h - 14.0, TIMBER, 5.0)
		&"brace":
			_box(deck, x - w * 0.5 + 3.0, 0.0, 6.0, h, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 3.0, 0.0, 6.0, h, TIMBER_DARK)
			_box(deck, x, h - 8.0, w, 8.0, TIMBER)
			_line_up(deck, x - w * 0.5, h - 28.0, x - w * 0.5 + 18.0, h - 8.0, TIMBER, 3.0)
			_line_up(deck, x + w * 0.5, h - 28.0, x + w * 0.5 - 18.0, h - 8.0, TIMBER, 3.0)
		&"rail":
			var n := 4
			for i in n + 1:
				_box(deck, x - w * 0.5 + float(i) * w / float(n), 0.0, 3.0, h, IRON)
			_box(deck, x, h - 3.0, w, 3.0, IRON_LIGHT)
			_box(deck, x, h * 0.45, w, 2.0, IRON)
		&"pillar":
			# carved support mass: a cobble boulder column with lumpy edges
			var pts := PackedVector2Array([Vector2(x - w * 0.5, deck), Vector2(x - w * 0.42, deck - h * 0.7), Vector2(x - w * 0.2, deck - h), Vector2(x + w * 0.25, deck - h), Vector2(x + w * 0.5, deck - h * 0.6), Vector2(x + w * 0.5, deck)])
			var uvs := PackedVector2Array()
			for pt in pts:
				uvs.append(pt / float(RockTextures.ROCK_SIZE))
			draw_colored_polygon(pts, Color.WHITE, uvs, RockTextures.cobble())
			for i in 5:
				var cy := deck - 18.0 - float(i) * h / 5.4
				draw_line(Vector2(x - w * 0.4 + _rnd(x, float(i), 61) * 10.0, cy), Vector2(x + w * 0.2 + _rnd(x, float(i), 62) * 14.0, cy - 8.0 + _rnd(x, float(i), 63) * 16.0), Color(0.02, 0.03, 0.06, 0.6), 1.5)
			_crystal_cluster(Vector2(x + w * 0.1, deck - h * 0.45), 1.0, 2)
		&"overhang":
			_box(deck, x, 0.0, w, h, Color(0.4, 0.34, 0.28))
			_box(deck, x, h - 6.0, w + 8.0, 6.0, TIMBER_DARK)
			_box(deck, x, 0.0, w + 8.0, 5.0, TIMBER_DARK)
			_box(deck, x - w * 0.25, h * 0.35, 16.0, 16.0, Color(1.0, 0.78, 0.45, 0.55))
			_line_up(deck, x - w * 0.5, 0.0, x - w * 0.5 - 14.0, -(p["y_off"] as float) + 6.0, TIMBER, 4.0)
			_line_up(deck, x + w * 0.5, 0.0, x + w * 0.5 + 14.0, -(p["y_off"] as float) + 6.0, TIMBER, 4.0)
		&"fracture":
			_poly(PackedVector2Array([Vector2(x - 3.0, deck), Vector2(x - 1.0, deck - h * 0.35), Vector2(x - 4.0, deck - h * 0.6), Vector2(x, deck - h), Vector2(x + 4.0, deck - h * 0.6), Vector2(x + 2.0, deck - h * 0.35), Vector2(x + 3.0, deck)]), Color(0.06, 0.1, 0.12))
			draw_line(Vector2(x + 1.0, deck - h * 0.2), Vector2(x + 1.0, deck - h * 0.8), Color(0.45, 0.7, 0.8, 0.25), 1.0)
		&"rubble":
			_poly(PackedVector2Array([Vector2(x - w * 0.5, deck), Vector2(x - w * 0.3, deck - h * 0.8), Vector2(x, deck - h), Vector2(x + w * 0.3, deck - h * 0.6), Vector2(x + w * 0.5, deck)]), SLATE_LIGHT)
			draw_circle(Vector2(x - w * 0.18, deck - h * 0.55), 3.0, SLATE)
		&"fallen_beam":
			draw_line(Vector2(x - w * 0.5, deck), Vector2(x + w * 0.45, deck - h), TIMBER_DARK, 8.0)
			draw_line(Vector2(x - w * 0.5, deck - 2.0), Vector2(x + w * 0.45, deck - h - 2.0), TIMBER, 3.0)
			_box(deck, x - w * 0.3, 0.0, 22.0, 10.0, SLATE_LIGHT)
		&"warning_sign":
			_box(deck, x, 0.0, 3.0, h - 12.0, IRON)
			_poly(PackedVector2Array([Vector2(x, deck - h), Vector2(x + w * 0.5, deck - h + 14.0), Vector2(x, deck - h + 28.0), Vector2(x - w * 0.5, deck - h + 14.0)]), Color(0.95, 0.7, 0.2))
			draw_line(Vector2(x, deck - h + 8.0), Vector2(x, deck - h + 17.0), Color(0.12, 0.1, 0.08), 2.0)
			draw_circle(Vector2(x, deck - h + 21.0), 1.4, Color(0.12, 0.1, 0.08))
		&"ore_pile":
			var oc: Color = ORE.get(tone, Color(0.5, 0.45, 0.38))
			_poly(PackedVector2Array([Vector2(x - w * 0.5, deck), Vector2(x - w * 0.25, deck - h), Vector2(x + w * 0.2, deck - h * 0.85), Vector2(x + w * 0.5, deck)]), oc)
			draw_circle(Vector2(x - 4.0, deck - h * 0.5), 2.0, oc.lightened(0.25))
		&"fragment":
			var journal := get_tree().root.get_node_or_null("Journal")
			if journal != null and journal.has_record(&"slate_shard"):
				return
			var glint := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
			_poly(PackedVector2Array([Vector2(x - 6.0, deck), Vector2(x - 2.0, deck - h), Vector2(x + 6.0, deck - h * 0.6), Vector2(x + 7.0, deck)]), Color(0.45, 0.5, 0.52))
			draw_line(Vector2(x - 2.0, deck - h), Vector2(x + 1.0, deck - 2.0), Color(0.8, 0.9, 0.95, 0.4 + 0.4 * glint), 1.0)
		&"supply_rack":
			_box(deck, x - w * 0.5 + 2.0, 0.0, 4.0, h, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 2.0, 0.0, 4.0, h, TIMBER_DARK)
			for i in 3:
				_box(deck, x, 4.0 + float(i) * (h - 8.0) / 3.0, w, 3.0, TIMBER)
				_box(deck, x - w * 0.22, 7.0 + float(i) * (h - 8.0) / 3.0, 16.0, 12.0, Color(0.55, 0.43, 0.3))
				_box(deck, x + w * 0.18, 7.0 + float(i) * (h - 8.0) / 3.0, 12.0, 9.0, Color(0.4, 0.46, 0.5))
		&"gauge":
			draw_circle(Vector2(x, deck - h * 0.5), h * 0.5, IRON)
			draw_circle(Vector2(x, deck - h * 0.5), h * 0.4, Color(0.8, 0.76, 0.66))
			draw_line(Vector2(x, deck - h * 0.5), Vector2(x + 8.0, deck - h * 0.5 - 11.0), Color(0.55, 0.15, 0.1), 2.0)
			_poly(PackedVector2Array([Vector2(x + 26.0, deck - 8.0), Vector2(x + 44.0, deck - 8.0), Vector2(x + 41.0, deck - 28.0), Vector2(x + 29.0, deck - 28.0)]), COPPER)
			draw_circle(Vector2(x + 35.0, deck - 6.0), 2.5, IRON)
		&"pipe":
			# a thick copper pipe run along the wall, flanged, dropping to the floor at one end
			var ph := 11.0
			draw_rect(Rect2(x - w * 0.5, deck - ph, w, ph), Color(0.5, 0.3, 0.18))
			draw_rect(Rect2(x - w * 0.5, deck - ph, w, 3.0), Color(0.78, 0.5, 0.3))
			draw_rect(Rect2(x - w * 0.5, deck - 2.0, w, 2.0), Color(0.25, 0.14, 0.08))
			for i in 5:
				var fx := x - w * 0.5 + float(i + 1) * w / 6.0
				draw_rect(Rect2(fx - 3.0, deck - ph - 3.0, 6.0, ph + 6.0), Color(0.4, 0.24, 0.14))
			var drop_x := x - w * 0.5 + 12.0
			draw_rect(Rect2(drop_x - ph * 0.5, deck, ph, maxf(float(p["y_off"]) - 44.0, 8.0)), Color(0.5, 0.3, 0.18))
			draw_circle(Vector2(drop_x, deck + ph * 0.1), ph * 0.9, Color(0.5, 0.3, 0.18))
		&"pump":
			# a pressure pump: squat base, tall cylinder, a piston rod and a flanged outlet
			_box(deck, x, 0.0, w, 14.0, IRON)
			_box(deck, x, 14.0, w * 0.62, h - 30.0, Color(0.3, 0.36, 0.4))
			_box(deck, x - w * 0.18, 14.0, 6.0, h - 30.0, Color(0.46, 0.54, 0.58))
			_box(deck, x, h - 16.0, w * 0.74, 8.0, IRON)
			_box(deck, x, h - 8.0, 6.0, 16.0, Color(0.7, 0.72, 0.72))
			_box(deck, x + w * 0.5, 30.0, 14.0, 8.0, COPPER)
		&"valve_wheel":
			# a wall valve: spoked wheel on a stem and bracket
			draw_circle(Vector2(x, deck - h * 0.5), h * 0.5, IRON)
			draw_circle(Vector2(x, deck - h * 0.5), h * 0.38, Color(0.2, 0.16, 0.13))
			draw_line(Vector2(x - h * 0.45, deck - h * 0.5), Vector2(x + h * 0.45, deck - h * 0.5), COPPER, 3.0)
			draw_line(Vector2(x, deck - h * 0.95), Vector2(x, deck - h * 0.05), COPPER, 3.0)
			draw_circle(Vector2(x, deck - h * 0.5), 4.0, COPPER)
		&"awning":
			# draped canvas on a pole frame
			_poly(PackedVector2Array([Vector2(x - w * 0.5, deck - h), Vector2(x + w * 0.5, deck - h), Vector2(x + w * 0.5, deck - h * 0.25), Vector2(x + w * 0.2, deck - h * 0.05), Vector2(x - w * 0.1, deck - h * 0.3), Vector2(x - w * 0.5, deck - h * 0.15)]), Color(0.26, 0.34, 0.36))
			draw_line(Vector2(x - w * 0.5, deck - h), Vector2(x + w * 0.5, deck - h), TIMBER_DARK, 3.0)
			for i in 3:
				draw_line(Vector2(x - w * 0.3 + float(i) * w * 0.3, deck - h), Vector2(x - w * 0.3 + float(i) * w * 0.3, deck - h * 0.35), Color(0.16, 0.22, 0.24), 1.0)
			draw_line(Vector2(x - w * 0.5, deck - h + 4.0), Vector2(x - w * 0.5, deck - h - 50.0), IRON, 1.5)
		&"niche":
			# an arched recess in the wall with bottles and a candle
			draw_rect(Rect2(x - w * 0.5, deck - h * 0.7, w, h * 0.7), Color(0.12, 0.09, 0.07))
			draw_circle(Vector2(x, deck - h * 0.7), w * 0.5, Color(0.12, 0.09, 0.07))
			_box(deck, x, 0.0, w + 6.0, 3.0, Color(0.4, 0.36, 0.3))
			_box(deck, x - 7.0, 3.0, 5.0, 11.0, Color(0.4, 0.62, 0.55))
			_box(deck, x + 2.0, 3.0, 6.0, 8.0, Color(0.7, 0.5, 0.3))
			draw_circle(Vector2(x + 10.0, deck - 14.0), 2.4, Color(1.0, 0.8, 0.4, 0.9))
			draw_circle(Vector2(x + 10.0, deck - 14.0), 9.0, Color(1.0, 0.7, 0.3, 0.12))
		&"herbs":
			# strings of dried herbs and peppers
			for i in 4:
				var hx := x - 18.0 + float(i) * 12.0
				draw_line(Vector2(hx, deck - h), Vector2(hx, deck - h + 8.0), Color(0.3, 0.22, 0.16), 1.0)
				_box(deck, hx, h - 8.0 - 16.0 - float(i % 2) * 6.0, 7.0, 18.0 + float(i % 2) * 6.0, Color(0.62, 0.22, 0.14) if i % 2 == 0 else Color(0.55, 0.4, 0.2))
		&"crystal":
			_crystal_cluster(Vector2(x, deck), 1.0)
		&"bench":
			_box(deck, x, 12.0, w, 4.0, TIMBER)
			_box(deck, x - w * 0.5 + 6.0, 0.0, 4.0, 12.0, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 6.0, 0.0, 4.0, 12.0, TIMBER_DARK)
		&"sort_table":
			_box(deck, x, h - 5.0, w, 5.0, TIMBER)
			_box(deck, x - w * 0.5 + 4.0, 0.0, 5.0, h - 5.0, TIMBER_DARK)
			_box(deck, x + w * 0.5 - 4.0, 0.0, 5.0, h - 5.0, TIMBER_DARK)
			_box(deck, x - 12.0, h, 14.0, 5.0, ORE[&"ravel"])
			_box(deck, x + 10.0, h, 14.0, 6.0, ORE[&"sutral"])
		&"sealed_hatch":
			_box(deck, x, 0.0, w, h, IRON)
			draw_rect(Rect2(x - w * 0.5, deck - h, w, h), TIMBER_DARK, false, 2.0)
			_box(deck, x, h * 0.5, w - 6.0, 5.0, Color(0.7, 0.22, 0.18))
			for i in 4:
				draw_circle(Vector2(x - w * 0.5 + 8.0, deck - 14.0 - float(i) * 22.0), 1.5, IRON_LIGHT)
		&"observation_window":
			_box(deck, x, 0.0, w, h, TIMBER_DARK)
			_box(deck, x, 3.0, w - 8.0, h - 6.0, Color(0.55, 0.78, 0.8, 0.5))
			draw_line(Vector2(x, deck - h + 3.0), Vector2(x, deck - 3.0), TIMBER_DARK, 2.0)
		&"notice":
			_box(deck, x, 0.0, w, h, Color(0.22, 0.19, 0.16))
			_box(deck, x - 6.0, 6.0, 10.0, 12.0, Color(0.8, 0.76, 0.66))
			_box(deck, x + 6.0, 10.0, 9.0, 14.0, Color(0.72, 0.68, 0.58))
		&"step":
			_box(deck, x, 0.0, w, h, Color(0.45, 0.38, 0.32))
		_:
			_box(deck, x, 0.0, w, h, Color(0.6, 0.2, 0.6, 0.6))
