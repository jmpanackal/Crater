class_name HollowRockView
extends Node2D
## The rock the rooms are carved from, drawn behind the player: the floor slab under every deck
## (the 112 px between one level and the next), the roof over civic rooms with no floor above them,
## and the dim cobble back wall of the dug galleries. Edges are jagged polygons with stalactite
## spikes, filled from the same stone texture as the dig rock (RockTextures), through the
## world-space rock shader, so it is all one material. One instance per chunk (a level band and a
## 1024 px slice) so the engine can skip what is off screen.

@export var chunk_k := -999
@export var chunk_x0 := -1.0e9
@export var chunk_x1 := 1.0e9

const SLAB := HollowMap.LEVEL_GAP - HollowMap.ROOM_HEIGHT - 16.0 ## 112
const SLOT := 12.0
const EDGE_DARK := Color(0.02, 0.03, 0.06, 0.55)
## Back-wall tint: dim, so the lit foreground reads in front (HollowStairwellView matches it).
const BACK_TONE := Color(0.45, 0.45, 0.55)


func _ready() -> void:
	z_index = -2
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = RockTextures.rock_material()
	queue_redraw()


static func hash01(a: float, b: float, salt: int) -> float:
	var h := int(a * 73.0) * 374761393 + int(b * 31.0) * 668265263 + salt * 2147483647
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


func _in_chunk(x0: float, x1: float) -> Vector2:
	return Vector2(maxf(x0, chunk_x0), minf(x1, chunk_x1))


func _draw() -> void:
	for r in HollowMap.runs():
		if absf(float(r["k"]) - float(chunk_k)) > 0.01 and chunk_k != -999:
			continue
		_gallery_back(r)
		_slab(r)
	for b in HollowDressing.buildings():
		if int(b["k"]) == chunk_k:
			_roof(b)


## Cobble over a world-aligned rect (neighbouring pieces continue the same stones).
func _rock_rect(rect: Rect2, tone: Color = Color.WHITE) -> void:
	var tex := RockTextures.cobble()
	var size := float(RockTextures.ROCK_SIZE)
	var bx := floorf(rect.position.x / size) * size
	while bx < rect.end.x:
		var by := floorf(rect.position.y / size) * size
		while by < rect.end.y:
			var x0 := maxf(rect.position.x, bx)
			var y0 := maxf(rect.position.y, by)
			var x1 := minf(rect.end.x, bx + size)
			var y1 := minf(rect.end.y, by + size)
			if x1 > x0 and y1 > y0:
				draw_texture_rect_region(tex, Rect2(x0, y0, x1 - x0, y1 - y0), Rect2(x0 - bx, y0 - by, x1 - x0, y1 - y0), tone)
			by += size
		bx += size


## A stone-textured polygon: UVs are world coordinates over the tile, so it matches the rect fill.
func _rock_poly(pts: PackedVector2Array) -> void:
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(p / float(RockTextures.ROCK_SIZE))
	draw_colored_polygon(pts, Color.WHITE, uvs, RockTextures.cobble())


## A jagged edge along y = base from xa to xb, spikes reaching `dir` (+1 down, -1 up). Slots are
## fixed in world space, so adjoining chunks agree.
func _jagged(xa: float, xb: float, base: float, dir: float, salt: int) -> void:
	var first := int(floorf(xa / SLOT))
	var last := int(ceilf(xb / SLOT))
	var top := PackedVector2Array([Vector2(xa, base - dir * 8.0), Vector2(xb, base - dir * 8.0)])
	var edge := PackedVector2Array()
	for i in range(first, last + 1):
		var x := clampf(float(i) * SLOT + hash01(float(i), base, salt) * 6.0, xa, xb)
		var roll := hash01(float(i), base, salt + 1)
		var d := 4.0 + hash01(float(i), base, salt + 2) * 12.0
		if roll > 0.86:
			d = 26.0 + hash01(float(i), base, salt + 3) * 30.0 # a stalactite
		edge.append(Vector2(x, base + dir * d))
	# polygon: top-left, top-right, then the edge back from right to left
	var pts := PackedVector2Array([top[0], top[1]])
	for k in range(edge.size() - 1, -1, -1):
		pts.append(edge[k])
	if pts.size() >= 3:
		_rock_poly(pts)
		# darken the underside so it reads as shadow
		var line := PackedVector2Array()
		for e in edge:
			line.append(e)
		if line.size() >= 2:
			draw_polyline(line, EDGE_DARK, 2.0)


## A jagged vertical end of a rock mass: the rock bulges out to the side `side` (-1 left, +1 right).
func _jagged_end(x: float, y0: float, y1: float, side: float, salt: int) -> void:
	var pts := PackedVector2Array([Vector2(x, y0), Vector2(x, y1)])
	var y := y1
	while y > y0:
		var out := 6.0 + hash01(x, y, salt) * 14.0
		pts.append(Vector2(x + side * out, y))
		y -= 12.0
	if pts.size() >= 3:
		_rock_poly(pts)


func _slab(r: Dictionary) -> void:
	if HollowMap.is_heart_zone(r["zone"]):
		return
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	if HollowMap.in_flank(x0) and HollowMap.in_flank(x1):
		return
	if HollowMap.in_flank(x0):
		x0 = HollowMap.WEST_WALL
	if HollowMap.in_flank(x1):
		x1 = HollowMap.EAST_WALL
	var deck: float = r["y"]
	# inside a stepped hall the street is a bridge over open air: no slab under it (hollow_hall_view.gd hangs its girders)
	var parts: Array[Vector2] = [Vector2(x0, x1)]
	for h in HollowMap.halls():
		if float(r["k"]) < float(h["k_top"]) - 0.01 or float(r["k"]) >= float(h["k_bottom"]) - 0.01:
			continue
		var next: Array[Vector2] = []
		for p in parts:
			if float(h["x1"]) <= p.x or float(h["x0"]) >= p.y:
				next.append(p)
				continue
			if float(h["x0"]) > p.x:
				next.append(Vector2(p.x, float(h["x0"])))
			if float(h["x1"]) < p.y:
				next.append(Vector2(float(h["x1"]), p.y))
		parts = next
	for p in parts:
		if p.y - p.x >= 32.0:
			_slab_part(r, p.x, p.y)


func _slab_part(r: Dictionary, x0: float, x1: float) -> void:
	var deck: float = r["y"]
	var top := deck + 16.0
	var seg := _in_chunk(x0 - 12.0, x1 + 12.0)
	if seg.y <= seg.x:
		return
	_rock_rect(Rect2(seg.x, top, seg.y - seg.x, SLAB))
	_jagged(seg.x, seg.y, top + SLAB, 1.0, 1)
	# the underside fades dark, like the rock beyond the lamplight
	for i in 3:
		draw_rect(Rect2(seg.x, top + SLAB - 34.0 + float(i) * 10.0, seg.y - seg.x, 10.0), Color(0.0, 0.01, 0.04, 0.06 + 0.05 * float(i)))
	if x0 - 12.0 >= chunk_x0 and x0 - 12.0 < chunk_x1:
		_jagged_end(x0, top, top + SLAB, -1.0, 4)
	if x1 + 12.0 > chunk_x0 and x1 + 12.0 <= chunk_x1:
		_jagged_end(x1, top, top + SLAB, 1.0, 5)


## The dim cobble back wall of the dug galleries (FLANK_CLEAR tall). The civic cavity has its own
## (HollowBackdropView).
func _gallery_back(r: Dictionary) -> void:
	if HollowMap.is_heart_zone(r["zone"]):
		return
	var deck: float = r["y"]
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var parts: Array[Vector3] = [] # x0, x1, height
	if x0 < HollowMap.WEST_WALL:
		parts.append(Vector3(x0, minf(x1, HollowMap.WEST_WALL), HollowMap.FLANK_CLEAR))
	if x1 > HollowMap.EAST_WALL:
		parts.append(Vector3(maxf(x0, HollowMap.EAST_WALL), x1, HollowMap.FLANK_CLEAR))
	for part in parts:
		var seg := _in_chunk(part.x, part.y)
		if seg.y > seg.x:
			_rock_rect(Rect2(seg.x, deck - part.z, seg.y - seg.x, part.z), BACK_TONE)


## A civic room needs a rock roof: where no floor above supplies one, draw the slab here.
func _roof(b: Dictionary) -> void:
	if bool(b.get("overlay", false)) or b["kind"] == &"nook":
		return
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	if HollowMap.in_flank(x0) or HollowMap.in_flank(x1):
		return
	var deck := HollowMap.deck_y_at((x0 + x1) * 0.5, float(b["k"]))
	var above := deck - HollowMap.LEVEL_GAP
	for r in HollowMap.runs():
		if absf(float(r["y"]) - above) < 1.0 and float(r["x0"]) <= x1 and float(r["x1"]) >= x0 and not HollowMap.is_heart_zone(r["zone"]):
			return
	var seg := _in_chunk(x0 - 12.0, x1 + 12.0)
	if seg.y <= seg.x:
		return
	var top := above + 16.0
	_rock_rect(Rect2(seg.x, top, seg.y - seg.x, SLAB))
	_jagged(seg.x, seg.y, top, -1.0, 6)
	for i in 3:
		draw_rect(Rect2(seg.x, top + SLAB - 20.0 + float(i) * 7.0, seg.y - seg.x, 7.0), Color(0.0, 0.01, 0.04, 0.1 + 0.07 * float(i)))
	if x0 - 12.0 >= chunk_x0 and x0 - 12.0 < chunk_x1:
		_jagged_end(x0, top, top + SLAB, -1.0, 7)
	if x1 + 12.0 > chunk_x0 and x1 + 12.0 <= chunk_x1:
		_jagged_end(x1, top, top + SLAB, 1.0, 8)
