class_name HollowStairwellView
extends Node2D
## The carved space around one stair flight: a dim cobble back wall behind the treads and a darker rock
## ceiling lip above them, so a flight reads as a stairwell cut into the rock and not a wedge in the
## void. Visual only: the street still passes over the flight (HollowMap one-way decks), nothing here
## has collision. Drawn from the same cave-rock texture and shader as everything else, in world-aligned
## UVs. One instance per stair, added after the rock views so it paints over the floor slab it crosses.

## `HollowMap.stairs()` entry this view dresses.
var stair: Dictionary = {}

## Air above a tread: the 96 px the player needs, plus a margin of wall.
const AIR := 112.0
## Thickness of the ceiling lip.
const LIP := 14.0
const STEP := 16.0
const BACK_TONE := HollowBackdropView.TONE
const LIP_TONE := Color(0.3, 0.3, 0.38)
const EDGE_DARK := Color(0.02, 0.03, 0.06, 0.6)


func _ready() -> void:
	z_index = -2
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = RockTextures.rock_material()
	queue_redraw()


## The stairwell outline along the flight: tread line, the ceiling line over it (never above the
## underside of the street slab at the top), and the lip's upper line.
static func edges(st: Dictionary) -> Dictionary:
	var dir := float(st["dir"])
	var foot_x: float = st["foot_x"]
	var foot_y: float = st["foot_y"]
	var top_y: float = st["top_y"]
	var n := int(roundf(absf(float(st["top_x"]) - foot_x) / STEP))
	var tread := PackedVector2Array()
	var ceiling := PackedVector2Array()
	var lip := PackedVector2Array()
	for i in range(n + 1):
		var x := foot_x + dir * float(i) * STEP
		var low := lerpf(foot_y, top_y, float(i) / float(maxi(n, 1)))
		var up := minf(maxf(low - float(st.get("air", AIR)), top_y + 16.0), low)
		tread.append(Vector2(x, low))
		ceiling.append(Vector2(x, up))
		lip.append(Vector2(x, up - LIP))
	return {"tread": tread, "ceiling": ceiling, "lip": lip}


func _draw() -> void:
	if stair.is_empty():
		return
	var e := edges(stair)
	var tread: PackedVector2Array = e["tread"]
	var ceiling: PackedVector2Array = e["ceiling"]
	var lip: PackedVector2Array = e["lip"]
	_poly(tread, ceiling, BACK_TONE)
	_poly(ceiling, lip, LIP_TONE)
	draw_polyline(ceiling, EDGE_DARK, 2.0)


## Fill the band between two equally long polylines. Columns where the band has pinched shut (the
## ceiling meets the tread at the top of a flight) are left out: they break triangulation.
func _poly(a: PackedVector2Array, b: PackedVector2Array, tone: Color) -> void:
	var keep: Array[int] = []
	for i in range(a.size()):
		if a[i].distance_to(b[i]) > 0.5:
			keep.append(i)
	if keep.size() < 2:
		return
	var pts := PackedVector2Array()
	for i in keep:
		pts.append(a[i])
	for j in range(keep.size() - 1, -1, -1):
		pts.append(b[keep[j]])
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(p / float(RockTextures.ROCK_SIZE))
	draw_colored_polygon(pts, tone, uvs, RockTextures.cobble())
