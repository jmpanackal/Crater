extends Node2D
## Inside a stepped hall (HollowMap.halls) the streets that cross it are bridges over open air, with nothing under them.
## This hangs a girder and a zigzag truss under every such street so it reads as built, as Mid Heart's rafts do, with a
## post down to the next deck every so often, and drips a few vines and lamps from the hall's ceiling so the open space
## feels tall and lived-in. Visual only, back layer, no collision.

const STEEL := Color(0.18, 0.2, 0.22)
const STEEL_HI := Color(0.3, 0.33, 0.36)
const STEEL_LO := Color(0.08, 0.09, 0.1)
const VINE := Color(0.22, 0.42, 0.3, 0.8)


func _ready() -> void:
	z_index = -1
	queue_redraw()


func _draw() -> void:
	for h in HollowMap.halls():
		var kt: float = h["k_top"]
		var kb: float = h["k_bottom"]
		var hx0: float = h["x0"]
		var hx1: float = h["x1"]
		var floor_y := HollowMap.lvl(kb)
		for r in HollowMap.runs():
			var k := float(r["k"])
			if k < kt - 0.01 or k >= kb - 0.01 or HollowMap.is_heart_zone(r["zone"]):
				continue
			var x0 := maxf(float(r["x0"]), hx0)
			var x1 := minf(float(r["x1"]), hx1)
			if x1 - x0 < 64.0:
				continue
			_bridge(x0, x1, float(r["y"]), floor_y)
		_ceiling_vines(hx0, hx1, HollowMap.lvl(kt) - HollowMap.ROOM_HEIGHT)


func _bridge(x0: float, x1: float, y: float, floor_y: float) -> void:
	var top := y + HollowMap.FLOOR_THICK
	draw_rect(Rect2(x0, top, x1 - x0, 8.0), STEEL)
	draw_rect(Rect2(x0, top, x1 - x0, 2.0), STEEL_HI)
	draw_rect(Rect2(x0, top + 30.0, x1 - x0, 5.0), STEEL_LO)
	var x := x0
	var up := true
	while x + 40.0 <= x1:
		draw_line(Vector2(x, top + (8.0 if up else 30.0)), Vector2(x + 40.0, top + (30.0 if up else 8.0)), STEEL, 3.0)
		x += 40.0
		up = not up
	# a support post to the deck below every 320 px
	var px := ceilf(x0 / 320.0) * 320.0
	while px < x1:
		draw_rect(Rect2(px - 3.0, top, 6.0, minf(floor_y - top, HollowMap.LEVEL_GAP - HollowMap.FLOOR_THICK)), STEEL_LO)
		px += 320.0


func _ceiling_vines(x0: float, x1: float, ceiling_y: float) -> void:
	var x := x0 + 40.0
	var i := 0
	while x < x1 - 40.0:
		var len := 40.0 + float((i * 37) % 90)
		draw_line(Vector2(x, ceiling_y), Vector2(x + float((i % 3) - 1) * 4.0, ceiling_y + len), VINE, 2.0)
		draw_circle(Vector2(x, ceiling_y + len), 3.0, Color(0.4, 0.8, 0.6, 0.7))
		x += 90.0 + float((i * 53) % 140)
		i += 1
