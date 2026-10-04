extends StyleBox
## A riveted iron plate with a brass or oxidized-teal trim, the shape every Krater panel and button wears
## (USER 2026-10-04: the UI should match the game's look: salvaged, riveted, lantern-lit; tactile like the Pulse's
## housings and the lift frames, never a pristine sci-fi panel). Drawn with the canvas item API so it scales to any
## control. Built by UiStyle; nothing here is gameplay.

var fill := Color(0.085, 0.08, 0.075, 0.9)
var inner := Color(0.045, 0.045, 0.045, 0.55)
var trim := Color(0.64, 0.48, 0.27, 0.9)
var highlight := Color(1.0, 0.86, 0.6, 0.16)
var rivet := Color(0.78, 0.6, 0.36, 0.85)
var glow := Color(0.0, 0.0, 0.0, 0.0) ## an inner lamp-glow along the edge (hover, alerts)
var chamfer := 4.0
var trim_width := 1.5
var rivets := true
var shadow := true


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var r := rect
	if shadow:
		_poly(to_canvas_item, _shape(Rect2(r.position + Vector2(1.0, 2.0), r.size), chamfer), Color(0, 0, 0, 0.28))
	var outer := _shape(r, chamfer)
	_poly(to_canvas_item, outer, fill)
	var pad := trim_width + 1.5
	if r.size.x > pad * 4.0 and r.size.y > pad * 4.0:
		_poly(to_canvas_item, _shape(r.grow(-pad), maxf(chamfer - 2.0, 0.0)), inner)
	if glow.a > 0.0:
		_poly(to_canvas_item, _shape(r.grow(-pad - 1.0), maxf(chamfer - 3.0, 0.0)), Color(glow.r, glow.g, glow.b, glow.a * 0.5))
	var line := outer.duplicate()
	line.append(outer[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, line, PackedColorArray([trim]), trim_width, false)
	# a bright top edge, like a catch of lantern light on the iron
	RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(r.position.x + chamfer + 2.0, r.position.y + trim_width + 1.0), Vector2(r.end.x - chamfer - 2.0, r.position.y + trim_width + 1.0), highlight, 1.0, false)
	if rivets and r.size.x > 28.0 and r.size.y > 18.0:
		var inset := chamfer + 3.0
		for c in [Vector2(r.position.x + inset, r.position.y + inset), Vector2(r.end.x - inset, r.position.y + inset), Vector2(r.position.x + inset, r.end.y - inset), Vector2(r.end.x - inset, r.end.y - inset)]:
			RenderingServer.canvas_item_add_circle(to_canvas_item, c, 1.7, rivet)
			RenderingServer.canvas_item_add_circle(to_canvas_item, c + Vector2(-0.5, -0.5), 0.6, Color(1, 1, 1, 0.45))


func _shape(r: Rect2, c: float) -> PackedVector2Array:
	var k := minf(c, minf(r.size.x, r.size.y) * 0.4)
	return PackedVector2Array([
		Vector2(r.position.x + k, r.position.y), Vector2(r.end.x - k, r.position.y), Vector2(r.end.x, r.position.y + k),
		Vector2(r.end.x, r.end.y - k), Vector2(r.end.x - k, r.end.y), Vector2(r.position.x + k, r.end.y),
		Vector2(r.position.x, r.end.y - k), Vector2(r.position.x, r.position.y + k),
	])


func _poly(canvas_item: RID, points: PackedVector2Array, color: Color) -> void:
	RenderingServer.canvas_item_add_polygon(canvas_item, points, PackedColorArray([color]))
