extends Node2D
## The lower home, inside (USER 2026-10-04): a small, crude, lived-in room cut into the rock of a worker terrace. Floor line
## at y = 0, the room 672 px wide and 240 px tall (local coordinates, home_interior.gd parks it in the Mouth's void). What
## is drawn here lines up with the stations the room holds: the bed (x -216), the lockbox (x -130), the workbench (x 150)
## and the door (x -292). Plank floor, stone walls, a window onto the distant lamplit cavern, one hanging lamp, a cold stove,
## a wash stand, a shelf of jars, hooks by the door with a work coat and a harness. Warm and worn; nothing grand. The better
## residences (Mid Reach, Ashram Heights) will get their own, tidier rooms. Greybox, drawn in code, replaced by real art
## later. Visual only.

const W := 336.0
const H := 240.0
const STONE := Color(0.2, 0.17, 0.15)
const STONE_LO := Color(0.14, 0.12, 0.11)
const PLANK := Color(0.33, 0.24, 0.17)
const PLANK_DARK := Color(0.22, 0.16, 0.11)
const TIMBER := Color(0.4, 0.28, 0.18)
const IRON := Color(0.3, 0.31, 0.32)
const IRON_HI := Color(0.5, 0.52, 0.52)
const WARM := Color(1.0, 0.72, 0.42)

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# beyond the room: solid rock, so the screen is never empty
	draw_rect(Rect2(-4000.0, -3000.0, 8000.0, 6000.0), Color(0.04, 0.035, 0.035))
	_walls()
	_floor_and_ceiling()
	_window()
	_door()
	_bed()
	_lockbox()
	_workbench()
	_stove_and_wash()
	_shelf()
	_hooks()
	_lamp()


func _walls() -> void:
	draw_rect(Rect2(-W, -H, W * 2.0, H), STONE)
	# stone courses
	var row := 0
	var y := -H
	while y < 0.0:
		draw_line(Vector2(-W, y), Vector2(W, y), Color(0.1, 0.09, 0.08, 0.8), 1.5)
		var off := 28.0 if row % 2 == 0 else 0.0
		var x := -W + off
		while x < W:
			draw_line(Vector2(x, y), Vector2(x, y + 28.0), Color(0.1, 0.09, 0.08, 0.5), 1.0)
			x += 56.0
		y += 28.0
		row += 1
	# a plank wainscot on the lower wall
	draw_rect(Rect2(-W, -84.0, W * 2.0, 84.0), Color(PLANK_DARK.r, PLANK_DARK.g, PLANK_DARK.b, 0.95))
	var px := -W
	while px < W:
		draw_line(Vector2(px, -84.0), Vector2(px, 0.0), Color(0.12, 0.08, 0.05, 0.7), 1.5)
		px += 22.0
	draw_rect(Rect2(-W, -88.0, W * 2.0, 5.0), TIMBER)


func _floor_and_ceiling() -> void:
	draw_rect(Rect2(-W - 32.0, 0.0, W * 2.0 + 64.0, 32.0), PLANK)
	var x := -W - 32.0
	while x < W + 32.0:
		draw_line(Vector2(x, 0.0), Vector2(x, 32.0), Color(0.15, 0.1, 0.07, 0.7), 1.5)
		x += 34.0
	draw_rect(Rect2(-W - 32.0, 0.0, W * 2.0 + 64.0, 3.0), Color(0.5, 0.38, 0.26, 0.6))
	# the ceiling beam and rafters
	draw_rect(Rect2(-W - 32.0, -H - 32.0, W * 2.0 + 64.0, 32.0), STONE_LO)
	draw_rect(Rect2(-W, -H, W * 2.0, 22.0), PLANK_DARK)
	for rx in [-250.0, -90.0, 80.0, 240.0]:
		draw_rect(Rect2(rx - 8.0, -H, 16.0, 36.0), TIMBER)
	draw_rect(Rect2(-W - 32.0, -H - 32.0, 32.0, H + 64.0), STONE_LO)
	draw_rect(Rect2(W, -H - 32.0, 32.0, H + 64.0), STONE_LO)


## A small window onto the cavern: a dim blue night with the far lamps of other homes as warm dots, a curtain at one side.
func _window() -> void:
	var r := Rect2(-60.0, -190.0, 84.0, 66.0)
	draw_rect(r.grow(5.0), TIMBER)
	draw_rect(r, Color(0.05, 0.08, 0.14))
	for i in range(9):
		var lx := r.position.x + 8.0 + float((i * 37) % 70)
		var ly := r.position.y + 8.0 + float((i * 23) % 50)
		var tw := 0.6 + 0.4 * sin(_t * 1.3 + float(i))
		draw_circle(Vector2(lx, ly), 1.8, Color(1.0, 0.75, 0.4, 0.8 * tw))
	draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.end.y), TIMBER, 3.0)
	draw_line(Vector2(r.position.x, r.position.y + r.size.y * 0.5), Vector2(r.end.x, r.position.y + r.size.y * 0.5), TIMBER, 3.0)
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(-4.0, -4.0), r.position + Vector2(26.0, -4.0), r.position + Vector2(18.0, r.size.y + 6.0), r.position + Vector2(-4.0, r.size.y + 6.0)]), Color(0.5, 0.3, 0.26, 0.9))
	# a faint cool light from the window falling on the floor
	draw_colored_polygon(PackedVector2Array([Vector2(r.position.x, 0.0), Vector2(r.end.x, 0.0), Vector2(r.end.x + 40.0, 0.0), Vector2(r.position.x + 30.0, 0.0)]), Color(0.4, 0.55, 0.8, 0.0))


## The door out: a plank door in a frame with a warm seam of light from the terrace, and a small lantern beside it.
func _door() -> void:
	var x := -W + 12.0
	draw_rect(Rect2(x - 4.0, -108.0, 56.0, 108.0), TIMBER)
	draw_rect(Rect2(x, -104.0, 48.0, 104.0), Color(0.26, 0.18, 0.12))
	for i in range(3):
		draw_line(Vector2(x + 12.0 + float(i) * 12.0, -104.0), Vector2(x + 12.0 + float(i) * 12.0, 0.0), Color(0.12, 0.08, 0.05, 0.8), 1.5)
	draw_rect(Rect2(x + 46.0, -104.0, 3.0, 104.0), Color(1.0, 0.8, 0.5, 0.6))
	draw_circle(Vector2(x + 38.0, -50.0), 2.5, IRON_HI)
	# a lantern on a bracket
	draw_line(Vector2(x + 64.0, -150.0), Vector2(x + 64.0, -132.0), IRON, 2.0)
	draw_rect(Rect2(x + 59.0, -132.0, 10.0, 14.0), Color(WARM.r, WARM.g, WARM.b, 0.9))
	draw_circle(Vector2(x + 64.0, -125.0), 44.0, Color(WARM.r, WARM.g, WARM.b, 0.06))


## The bed: a low plank frame, a straw mattress, a patched grey blanket and a flat pillow, with a rug beside it.
func _bed() -> void:
	var x := -216.0
	draw_rect(Rect2(x - 88.0, -4.0, 176.0, 3.0), Color(0.3, 0.45, 0.4, 0.0))
	# rug
	draw_rect(Rect2(x - 70.0, -3.0, 140.0, 3.0), Color(0.45, 0.25, 0.2))
	draw_rect(Rect2(x - 62.0, -3.0, 124.0, 1.5), Color(0.7, 0.5, 0.3))
	# frame and legs
	draw_rect(Rect2(x - 76.0, -28.0, 152.0, 8.0), TIMBER)
	draw_rect(Rect2(x - 74.0, -20.0, 6.0, 20.0), PLANK_DARK)
	draw_rect(Rect2(x + 68.0, -20.0, 6.0, 20.0), PLANK_DARK)
	draw_rect(Rect2(x - 80.0, -62.0, 8.0, 42.0), TIMBER)
	# mattress, blanket and pillow
	draw_rect(Rect2(x - 70.0, -40.0, 140.0, 14.0), Color(0.72, 0.64, 0.46))
	draw_rect(Rect2(x - 22.0, -44.0, 92.0, 18.0), Color(0.42, 0.45, 0.48))
	for i in range(4):
		draw_rect(Rect2(x - 10.0 + float(i) * 22.0, -44.0, 3.0, 18.0), Color(0.3, 0.32, 0.36, 0.7))
	draw_rect(Rect2(x - 68.0, -50.0, 40.0, 11.0), Color(0.82, 0.78, 0.68))
	# a patch on the blanket
	draw_rect(Rect2(x + 30.0, -40.0, 20.0, 12.0), Color(0.55, 0.4, 0.3))


## The lockbox: a strapped timber chest with a hasp, at the foot of the bed.
func _lockbox() -> void:
	var x := -130.0
	draw_rect(Rect2(x - 22.0, -34.0, 44.0, 34.0), Color(0.36, 0.25, 0.17))
	draw_rect(Rect2(x - 22.0, -34.0, 44.0, 8.0), Color(0.42, 0.3, 0.2))
	for sx in [x - 14.0, x + 12.0]:
		draw_rect(Rect2(sx - 2.0, -34.0, 4.0, 34.0), IRON)
	draw_rect(Rect2(x - 5.0, -28.0, 10.0, 12.0), IRON_HI)
	draw_circle(Vector2(x, -20.0), 2.0, Color(0.1, 0.1, 0.1))


## The workbench: a heavy bench with a vise, tools laid out, a half-mended harness, and a pegboard of tools above it.
func _workbench() -> void:
	var x := 150.0
	draw_rect(Rect2(x - 62.0, -44.0, 124.0, 8.0), TIMBER)
	draw_rect(Rect2(x - 58.0, -36.0, 8.0, 36.0), PLANK_DARK)
	draw_rect(Rect2(x + 50.0, -36.0, 8.0, 36.0), PLANK_DARK)
	draw_rect(Rect2(x - 52.0, -20.0, 104.0, 4.0), PLANK_DARK)
	# a vise at the left end and tools on top
	draw_rect(Rect2(x - 56.0, -58.0, 14.0, 14.0), IRON)
	draw_rect(Rect2(x - 50.0, -64.0, 4.0, 8.0), IRON_HI)
	draw_rect(Rect2(x - 26.0, -48.0, 22.0, 4.0), IRON_HI)
	draw_rect(Rect2(x - 4.0, -50.0, 3.0, 6.0), TIMBER)
	draw_rect(Rect2(x + 14.0, -50.0, 22.0, 6.0), Color(0.55, 0.4, 0.28))
	draw_arc(Vector2(x + 46.0, -52.0), 7.0, 0.0, TAU, 12, Color(0.78, 0.66, 0.44), 3.0)
	# the pegboard
	draw_rect(Rect2(x - 62.0, -150.0, 124.0, 76.0), Color(0.24, 0.17, 0.12))
	draw_rect(Rect2(x - 62.0, -150.0, 124.0, 76.0), Color(0.12, 0.08, 0.05), false, 2.0)
	for i in range(5):
		var tx := x - 48.0 + float(i) * 24.0
		draw_line(Vector2(tx, -146.0), Vector2(tx, -120.0 - float((i * 11) % 18)), IRON_HI, 3.0)
		draw_rect(Rect2(tx - 5.0, -122.0 - float((i * 11) % 18), 10.0, 6.0), IRON)
	draw_arc(Vector2(x - 30.0, -92.0), 11.0, 0.0, TAU, 14, Color(0.7, 0.55, 0.36), 3.0)
	draw_rect(Rect2(x + 22.0, -104.0, 22.0, 18.0), Color(0.6, 0.42, 0.24))
	draw_circle(Vector2(x + 33.0, -95.0), 5.0, Color(1.0, 0.82, 0.45, 0.7))


## A small cold cast-iron stove with a kettle and a stovepipe up through the ceiling, and a wash stand with a jug.
func _stove_and_wash() -> void:
	var x := 260.0
	draw_rect(Rect2(x - 22.0, -48.0, 44.0, 48.0), Color(0.18, 0.18, 0.19))
	draw_rect(Rect2(x - 22.0, -50.0, 44.0, 4.0), IRON_HI)
	draw_rect(Rect2(x - 12.0, -38.0, 24.0, 18.0), Color(0.06, 0.05, 0.05))
	draw_rect(Rect2(x - 4.0, -H, 8.0, H - 50.0), Color(0.22, 0.22, 0.23))
	draw_rect(Rect2(x + 4.0, -66.0, 18.0, 16.0), Color(0.5, 0.36, 0.26))
	# the wash stand
	var wx := -20.0
	draw_rect(Rect2(wx - 20.0, -52.0, 40.0, 6.0), TIMBER)
	draw_rect(Rect2(wx - 18.0, -46.0, 5.0, 46.0), PLANK_DARK)
	draw_rect(Rect2(wx + 13.0, -46.0, 5.0, 46.0), PLANK_DARK)
	draw_rect(Rect2(wx - 14.0, -60.0, 28.0, 8.0), Color(0.5, 0.5, 0.5))
	draw_rect(Rect2(wx - 14.0, -60.0, 28.0, 3.0), Color(0.4, 0.55, 0.6))
	draw_rect(Rect2(wx + 22.0, -64.0, 12.0, 18.0), Color(0.45, 0.32, 0.22))


## A shelf with jars, a tin cup and a small wooden figure.
func _shelf() -> void:
	var x := -150.0
	draw_rect(Rect2(x - 40.0, -138.0, 80.0, 5.0), TIMBER)
	draw_line(Vector2(x - 34.0, -133.0), Vector2(x - 34.0, -122.0), TIMBER, 3.0)
	draw_line(Vector2(x + 34.0, -133.0), Vector2(x + 34.0, -122.0), TIMBER, 3.0)
	for i in range(4):
		var jx := x - 30.0 + float(i) * 18.0
		draw_rect(Rect2(jx - 5.0, -158.0, 10.0, 20.0), Color(0.3, 0.6, 0.5, 0.85) if i % 2 == 0 else Color(0.75, 0.55, 0.3, 0.85))
		draw_rect(Rect2(jx - 5.0, -160.0, 10.0, 3.0), Color(0.5, 0.36, 0.22))
	draw_rect(Rect2(x + 30.0, -148.0, 10.0, 10.0), Color(0.62, 0.62, 0.6))


## Hooks by the door: a work coat and a harness hung up.
func _hooks() -> void:
	var x := -258.0
	draw_rect(Rect2(x - 4.0, -150.0, 56.0, 4.0), TIMBER)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 2.0, -146.0), Vector2(x + 22.0, -146.0), Vector2(x + 26.0, -96.0), Vector2(x - 2.0, -96.0)]), Color(0.36, 0.3, 0.24))
	draw_line(Vector2(x + 36.0, -146.0), Vector2(x + 36.0, -104.0), Color(0.62, 0.42, 0.24), 4.0)
	draw_line(Vector2(x + 46.0, -146.0), Vector2(x + 46.0, -110.0), Color(0.62, 0.42, 0.24), 4.0)
	draw_arc(Vector2(x + 41.0, -102.0), 8.0, 0.0, PI, 10, IRON_HI, 3.0)


## The one hanging lamp: a chain, a shade and a warm flickering glow that lights the room.
func _lamp() -> void:
	var x := 62.0
	var flick := 0.85 + 0.15 * sin(_t * 3.1) * sin(_t * 1.3)
	draw_line(Vector2(x, -H), Vector2(x, -170.0), IRON, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 14.0, -170.0), Vector2(x + 14.0, -170.0), Vector2(x + 8.0, -182.0), Vector2(x - 8.0, -182.0)]), Color(0.3, 0.22, 0.14))
	draw_circle(Vector2(x, -166.0), 5.0, Color(1.0, 0.9, 0.6, flick))
	for r in [260.0, 190.0, 120.0]:
		draw_circle(Vector2(x, -150.0), r, Color(WARM.r, WARM.g, WARM.b, 0.045 * flick))
