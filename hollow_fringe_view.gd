class_name HollowFringeView
extends Node2D
## Ragged rock along the edges the tile grid leaves dead straight: the ceilings of civic rooms, the
## ceilings and the unfinished ends of dug galleries, and the Firmament over the whole cavity. Jagged
## stone hangs from them (spikes and stalactites), filled from the same cave-rock texture and shader as the
## dig rock, with world-aligned UVs, so it grows out of the tiles with no seam. Lives under Terrain so it is
## drawn after the tiles and behind the player. One instance per chunk, like HollowRockView.

@export var chunk_k := -999
@export var chunk_x0 := -1.0e9
@export var chunk_x1 := 1.0e9

const SLOT := 12.0
const EDGE_DARK := Color(0.02, 0.03, 0.06, 0.6)


func _ready() -> void:
	z_index = 0
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = RockTextures.rock_material()
	queue_redraw()


func _draw() -> void:
	for b in HollowDressing.buildings():
		if int(b["k"]) != chunk_k or bool(b.get("overlay", false)) or b["kind"] == &"nook":
			continue
		if HollowMap.in_flank(float(b["x0"])) or HollowMap.in_flank(float(b["x1"])):
			continue
		var seg := _clip(float(b["x0"]), float(b["x1"]))
		if seg.y > seg.x:
			_hang(seg.x, seg.y, HollowMap.deck_y_at((float(b["x0"]) + float(b["x1"])) * 0.5, float(b["k"])) - float(b["height"]), 10)
	for r in HollowMap.runs():
		if absf(float(r["k"]) - float(chunk_k)) > 0.01:
			continue
		var deck: float = r["y"]
		for s in _flank_segments(r):
			var seg := _clip(s.x, s.y)
			if seg.y > seg.x:
				_hang(seg.x, seg.y, deck - HollowMap.FLANK_CLEAR, 20)
		# a civic room with nothing built above it has the solid rock for a ceiling: ragged like the rest
		var room_x0 := maxf(float(r["x0"]), HollowMap.WEST_WALL)
		var room_x1 := minf(float(r["x1"]), HollowMap.EAST_WALL)
		if r["zone"] != &"mid_heart" and not bool(r["landing"]) and room_x1 > room_x0 and HollowMap.nothing_above(float(r["k"]), room_x0, room_x1):
			var room_seg := _clip(room_x0, room_x1)
			if room_seg.y > room_seg.x:
				for part in HollowMap.ceiling_segments(room_seg.x, room_seg.y, float(r["k"])):
					_hang(part.x, part.y, part.z, 1)
		if r["l"] == HollowMap.END_ROCK and float(r["x0"]) >= chunk_x0 and float(r["x0"]) < chunk_x1:
			_end(float(r["x0"]), deck - HollowMap.FLANK_CLEAR, deck, 1.0, 30)
		if r["r"] == HollowMap.END_ROCK and float(r["x1"]) > chunk_x0 and float(r["x1"]) <= chunk_x1:
			_end(float(r["x1"]), deck - HollowMap.FLANK_CLEAR, deck, -1.0, 40)


func _clip(a: float, b: float) -> Vector2:
	return Vector2(maxf(a, chunk_x0), minf(b, chunk_x1))


## The parts of a run that sit in a dug flank (its carved gallery).
func _flank_segments(r: Dictionary) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if float(r["x0"]) < HollowMap.WEST_WALL:
		out.append(Vector2(float(r["x0"]), minf(float(r["x1"]), HollowMap.WEST_WALL)))
	if float(r["x1"]) > HollowMap.EAST_WALL:
		out.append(Vector2(maxf(float(r["x0"]), HollowMap.EAST_WALL), float(r["x1"])))
	return out


func _poly(pts: PackedVector2Array) -> void:
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(p / float(RockTextures.ROCK_SIZE))
	draw_colored_polygon(pts, Color.WHITE, uvs, RockTextures.cobble())


## Jagged rock hanging below the line y = base from xa to xb: small teeth, the odd long stalactite. Slots
## sit in world space, so neighbouring chunks agree.
func _hang(xa: float, xb: float, base: float, salt: int) -> void:
	var edge := PackedVector2Array()
	for i in range(int(floorf(xa / SLOT)), int(ceilf(xb / SLOT)) + 1):
		var x := clampf(float(i) * SLOT + HollowRockView.hash01(float(i), base, salt) * 6.0, xa, xb)
		var d := 5.0 + HollowRockView.hash01(float(i), base, salt + 1) * 13.0
		if HollowRockView.hash01(float(i), base, salt + 2) > 0.87:
			d = 24.0 + HollowRockView.hash01(float(i), base, salt + 3) * 30.0
		edge.append(Vector2(x, base + d))
	var pts := PackedVector2Array([Vector2(xa, base - 6.0), Vector2(xb, base - 6.0)])
	for k in range(edge.size() - 1, -1, -1):
		pts.append(edge[k])
	if pts.size() >= 3:
		_poly(pts)
		draw_polyline(edge, EDGE_DARK, 2.0)


## The unfinished end of a gallery: rock bulging into it. side +1 bulges to the right.
func _end(x: float, y0: float, y1: float, side: float, salt: int) -> void:
	var pts := PackedVector2Array([Vector2(x - side * 6.0, y0), Vector2(x - side * 6.0, y1)])
	var y := y1
	while y > y0:
		pts.append(Vector2(x + side * (4.0 + HollowRockView.hash01(x, y, salt) * 12.0), y))
		y -= 12.0
	if pts.size() >= 3:
		_poly(pts)
