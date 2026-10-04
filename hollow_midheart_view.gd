extends Node2D
## Mid Heart's structure (AI, 2026-10-03; Mid Heart is the one cluster over the Mouth, canon: exchange, ritual,
## services, freight): girders and trusses under every deck so the rafts read as built things hanging over the
## drop, rails along the edges, and a character for each part: the West Exchange (Joss's counter and stalls),
## the Ritual Raft (pillars and pennants either side of the Pulse), the East Service raft (notice boards and
## offices), the two galleries (canopies) and the lower freight tier (a gantry crane and cargo). Visual only: it
## is drawn from the Mid Heart runs, so it follows the map, and has no collision. Back layer.

const STEEL := Color(0.2, 0.22, 0.25)
const STEEL_HI := Color(0.34, 0.37, 0.41)
const STEEL_LO := Color(0.09, 0.1, 0.12)
const TIMBER := Color(0.36, 0.27, 0.19)
const CLOTH_A := Color(0.55, 0.3, 0.24)
const CLOTH_B := Color(0.28, 0.4, 0.42)
const CLOTH_C := Color(0.62, 0.5, 0.3)
const COPPER := Color(0.72, 0.46, 0.26)
const GLOW_WARM := Color(1.0, 0.78, 0.45)
const GLOW_COOL := Color(0.55, 0.85, 0.88)

const EXCHANGE := [&"HM_W", &"HM_W2"]
const SERVICE := [&"HM_E", &"HM_E2"]
const GALLERIES := [&"HM_WG", &"HM_EG"]
const FRONT_SCRIPT := preload("res://hollow_midheart_front.gd")


func _ready() -> void:
	z_index = -1
	var front := Node2D.new()
	front.name = "Bulkheads"
	front.set_script(FRONT_SCRIPT)
	add_child(front)
	queue_redraw()


func _draw() -> void:
	for r in HollowMap.runs():
		if not HollowMap.is_heart_zone(r["zone"]):
			continue
		var id: StringName = r["id"]
		var x0: float = r["x0"]
		var x1: float = r["x1"]
		var y: float = r["y"]
		_underside(x0, x1, y)
		_rails(x0, x1, y, id in GALLERIES)
		if id in EXCHANGE:
			_exchange(x0, x1, y)
		elif id in SERVICE:
			_service(x0, x1, y)
		elif id == &"HM_R":
			_ritual(x0, x1, y)
		elif id in GALLERIES:
			_gallery(x0, x1, y)
		elif id == &"HM_F" or id == &"HM_F2":
			_freight(x0, x1, y)
		elif id == &"HM_LH":
			_dock(x0, x1, y)
		elif id == &"HM_UC":
			_terrace(x0, x1, y)
	_moorings()


## A girder under the deck and a zigzag truss below it, with lit rivets: the raft is a built thing.
func _underside(x0: float, x1: float, y: float) -> void:
	var top := y + HollowMap.FLOOR_THICK
	draw_rect(Rect2(x0, top, x1 - x0, 10.0), STEEL)
	draw_rect(Rect2(x0, top, x1 - x0, 2.0), STEEL_HI)
	draw_rect(Rect2(x0, top + 38.0, x1 - x0, 6.0), STEEL_LO)
	var x := x0
	var up := true
	while x + 48.0 <= x1:
		var a := Vector2(x, top + 10.0 if up else top + 38.0)
		var b := Vector2(x + 48.0, top + 38.0 if up else top + 10.0)
		draw_line(a, b, STEEL, 4.0)
		draw_rect(Rect2(x - 3.0, top + 8.0, 6.0, 38.0), STEEL_LO)
		x += 48.0
		up = not up


func _rails(x0: float, x1: float, y: float, canopy: bool) -> void:
	var x := x0 + 8.0
	while x < x1 - 4.0:
		draw_rect(Rect2(x, y - 30.0, 4.0, 30.0), STEEL)
		x += 48.0
	draw_rect(Rect2(x0, y - 32.0, x1 - x0, 4.0), STEEL_HI)
	draw_rect(Rect2(x0, y - 16.0, x1 - x0, 2.0), STEEL)


func _lamp(x: float, y: float, c: Color) -> void:
	draw_circle(Vector2(x, y), 40.0, Color(c.r, c.g, c.b, 0.05))
	draw_circle(Vector2(x, y), 18.0, Color(c.r, c.g, c.b, 0.1))
	draw_rect(Rect2(x - 5.0, y - 7.0, 10.0, 14.0), Color(c.r, c.g, c.b, 0.95))
	draw_line(Vector2(x, y - 7.0), Vector2(x, y - 40.0), STEEL, 2.0)


## West Exchange: a long counter with an awning (Joss's), stalls and a rate board.
func _exchange(x0: float, x1: float, y: float) -> void:
	var width := x1 - x0
	if width >= 180.0:
		var cx := x0 + 28.0
		draw_rect(Rect2(cx, y - 44.0, minf(width - 56.0, 150.0), 44.0), TIMBER)
		draw_rect(Rect2(cx, y - 48.0, minf(width - 56.0, 150.0), 5.0), COPPER)
		draw_rect(Rect2(cx + 6.0, y - 112.0, 4.0, 64.0), STEEL)
		draw_rect(Rect2(cx + minf(width - 56.0, 150.0) - 10.0, y - 112.0, 4.0, 64.0), STEEL)
		draw_rect(Rect2(cx - 4.0, y - 116.0, minf(width - 56.0, 150.0) + 8.0, 14.0), CLOTH_A)
		draw_rect(Rect2(cx - 4.0, y - 104.0, minf(width - 56.0, 150.0) + 8.0, 3.0), CLOTH_C)
		_lamp(cx + 70.0, y - 150.0, GLOW_WARM)
	if width >= 400.0:
		# a rate board and two stalls
		draw_rect(Rect2(x1 - 120.0, y - 120.0, 72.0, 52.0), STEEL_LO)
		draw_rect(Rect2(x1 - 116.0, y - 116.0, 64.0, 44.0), Color(0.16, 0.2, 0.18))
		for i in range(4):
			draw_rect(Rect2(x1 - 108.0, y - 108.0 + float(i) * 10.0, 44.0 - float(i) * 6.0, 3.0), CLOTH_C)
		draw_rect(Rect2(x0 + 230.0, y - 36.0, 44.0, 36.0), TIMBER)
		draw_rect(Rect2(x0 + 224.0, y - 78.0, 56.0, 14.0), CLOTH_B)
		draw_rect(Rect2(x0 + 228.0, y - 64.0, 4.0, 28.0), STEEL)
		draw_rect(Rect2(x0 + 272.0, y - 64.0, 4.0, 28.0), STEEL)


## East Service: notice boards, a bench and a lit office door in a frame.
func _service(x0: float, x1: float, y: float) -> void:
	var width := x1 - x0
	if width >= 180.0:
		draw_rect(Rect2(x0 + 24.0, y - 150.0, 80.0, 150.0), STEEL_LO)
		draw_rect(Rect2(x0 + 32.0, y - 140.0, 64.0, 140.0), Color(0.18, 0.15, 0.12))
		draw_rect(Rect2(x0 + 44.0, y - 100.0, 40.0, 100.0), Color(0.3, 0.22, 0.14))
		draw_circle(Vector2(x0 + 78.0, y - 50.0), 3.0, COPPER)
		_lamp(x0 + 64.0, y - 170.0, GLOW_WARM)
	if width >= 300.0:
		for i in range(3):
			var nx := x0 + 150.0 + float(i) * 46.0
			draw_rect(Rect2(nx, y - 120.0, 34.0, 44.0), TIMBER)
			draw_rect(Rect2(nx + 4.0, y - 116.0, 26.0, 36.0), CLOTH_C if i != 1 else CLOTH_B)
		draw_rect(Rect2(x1 - 140.0, y - 20.0, 72.0, 8.0), TIMBER)
		draw_rect(Rect2(x1 - 134.0, y - 12.0, 4.0, 12.0), STEEL)
		draw_rect(Rect2(x1 - 78.0, y - 12.0, 4.0, 12.0), STEEL)


## Ritual Raft: tall pillars at both ends with pennants, and braziers (the Pulse stands between them).
func _ritual(x0: float, x1: float, y: float) -> void:
	for px in [x0 + 236.0, x1 - 260.0]:
		draw_rect(Rect2(px, y - 300.0, 24.0, 300.0), STEEL)
		draw_rect(Rect2(px - 6.0, y - 300.0, 36.0, 14.0), STEEL_HI)
		draw_rect(Rect2(px - 6.0, y - 24.0, 36.0, 24.0), STEEL_LO)
		# (the pennant flaps, so hollow_motion_view.gd draws it)
	for bx in [x0 + 190.0, x1 - 210.0]:
		draw_rect(Rect2(bx - 18.0, y - 40.0, 36.0, 12.0), STEEL_LO)
		draw_rect(Rect2(bx - 4.0, y - 28.0, 8.0, 28.0), STEEL)
		draw_circle(Vector2(bx, y - 48.0), 14.0, Color(1.0, 0.6, 0.25, 0.9))
		draw_circle(Vector2(bx, y - 48.0), 34.0, Color(1.0, 0.6, 0.25, 0.08))


## The galleries: a canopy on posts and a hung lamp, so they read as covered balconies.
func _gallery(x0: float, x1: float, y: float) -> void:
	draw_rect(Rect2(x0 + 8.0, y - 150.0, 6.0, 120.0), STEEL)
	draw_rect(Rect2(x1 - 14.0, y - 150.0, 6.0, 120.0), STEEL)
	draw_rect(Rect2(x0, y - 156.0, x1 - x0, 10.0), STEEL_LO)
	draw_rect(Rect2(x0, y - 156.0, x1 - x0, 3.0), STEEL_HI)
	draw_rect(Rect2(x0 + 14.0, y - 146.0, x1 - x0 - 28.0, 14.0), CLOTH_B)
	_lamp((x0 + x1) * 0.5, y - 120.0, GLOW_COOL)


## The freight tier: cargo stacked along it and work lamps (the gantry crane stands on the lowered dock).
func _freight(x0: float, x1: float, y: float) -> void:
	var mid := (x0 + x1) * 0.5
	# cargo along the tier: crates and barrels in groups, spaced clear of the gantry
	var groups := [x0 + 140.0, mid - 120.0, x1 - 300.0]
	for gx in groups:
		draw_rect(Rect2(gx, y - 34.0, 38.0, 34.0), TIMBER)
		draw_rect(Rect2(gx + 42.0, y - 28.0, 30.0, 28.0), TIMBER.darkened(0.15))
		draw_rect(Rect2(gx + 6.0, y - 62.0, 30.0, 28.0), TIMBER.lightened(0.08))
		draw_rect(Rect2(gx + 78.0, y - 26.0, 22.0, 26.0), Color(0.3, 0.32, 0.36))
	for lx in [x0 + 420.0, x1 - 420.0]:
		_lamp(lx, y - 140.0, GLOW_COOL)


## The lowered freight dock: a gantry crane, a dispatch booth with a sign, and cargo waiting to be moved.
func _dock(x0: float, x1: float, y: float) -> void:
	var mid := (x0 + x1) * 0.5
	draw_rect(Rect2(mid - 190.0, y - 190.0, 10.0, 190.0), STEEL)
	draw_rect(Rect2(mid + 180.0, y - 190.0, 10.0, 190.0), STEEL)
	draw_rect(Rect2(mid - 200.0, y - 200.0, 400.0, 14.0), STEEL_HI)
	draw_rect(Rect2(mid - 200.0, y - 186.0, 400.0, 4.0), STEEL_LO)
	# (the trolley, hook and the crate it carries move, so hollow_motion_view.gd draws them)
	# dispatch booth at the west end
	draw_rect(Rect2(x0 + 30.0, y - 100.0, 90.0, 100.0), STEEL_LO)
	draw_rect(Rect2(x0 + 36.0, y - 94.0, 78.0, 70.0), Color(0.16, 0.14, 0.11))
	draw_rect(Rect2(x0 + 46.0, y - 86.0, 58.0, 24.0), Color(0.55, 0.5, 0.36, 0.9))
	draw_rect(Rect2(x0 + 24.0, y - 108.0, 102.0, 10.0), CLOTH_A)
	_lamp(x0 + 75.0, y - 140.0, GLOW_WARM)
	# cargo and a stack of pressure canisters at the east end
	for i in range(3):
		draw_rect(Rect2(x1 - 150.0 + float(i) * 38.0, y - 44.0, 30.0, 44.0), Color(0.3, 0.36, 0.4))
		draw_rect(Rect2(x1 - 150.0 + float(i) * 38.0, y - 48.0, 30.0, 6.0), COPPER)
	draw_rect(Rect2(x1 - 260.0, y - 36.0, 60.0, 36.0), TIMBER)
	draw_rect(Rect2(x1 - 250.0, y - 66.0, 40.0, 30.0), TIMBER.lightened(0.08))


## The Council Terrace over the Ritual hall (Upper Heart, the larger civic level): a lit council hall in the middle
## behind the Pulse, banners, and benches and notice boards on both wings.
func _terrace(x0: float, x1: float, y: float) -> void:
	var mid := (x0 + x1) * 0.5
	# the council hall: a lit frontage with a banner and a tall door
	draw_rect(Rect2(mid - 330.0, y - 170.0, 660.0, 170.0), STEEL_LO)
	draw_rect(Rect2(mid - 322.0, y - 162.0, 644.0, 162.0), Color(0.17, 0.14, 0.11))
	for i in range(7):
		var wx := mid - 290.0 + float(i) * 88.0
		if absf(wx - mid) < 40.0:
			continue
		draw_rect(Rect2(wx, y - 120.0, 36.0, 50.0), Color(0.95, 0.74, 0.42, 0.55))
		draw_rect(Rect2(wx, y - 120.0, 36.0, 4.0), STEEL)
	draw_rect(Rect2(mid - 34.0, y - 130.0, 68.0, 130.0), Color(0.3, 0.22, 0.14))
	draw_rect(Rect2(mid - 26.0, y - 122.0, 52.0, 122.0), Color(0.1, 0.08, 0.06))
	draw_rect(Rect2(mid - 340.0, y - 180.0, 680.0, 12.0), CLOTH_C.darkened(0.2))
	draw_rect(Rect2(mid - 70.0, y - 260.0, 140.0, 80.0), CLOTH_A)
	draw_rect(Rect2(mid - 70.0, y - 260.0, 140.0, 8.0), CLOTH_C)
	draw_circle(Vector2(mid, y - 222.0), 18.0, CLOTH_C)
	# wings: benches, notice boards, banners on poles
	for side in [-1.0, 1.0]:
		var wx0: float = mid + side * 420.0
		for i in range(3):
			var bx: float = wx0 + side * float(i) * 110.0 - 35.0
			draw_rect(Rect2(bx, y - 22.0, 70.0, 8.0), TIMBER)
			draw_rect(Rect2(bx + 6.0, y - 14.0, 4.0, 14.0), STEEL)
			draw_rect(Rect2(bx + 60.0, y - 14.0, 4.0, 14.0), STEEL)
		var px: float = mid + side * 640.0
		draw_rect(Rect2(px - 3.0, y - 240.0, 6.0, 240.0), STEEL)
		draw_rect(Rect2(px - (46.0 if side > 0.0 else 0.0), y - 230.0, 46.0, 96.0), CLOTH_B)
		_lamp(mid + side * 520.0, y - 190.0, GLOW_WARM)
	_lamp(mid - 200.0, y - 215.0, GLOW_WARM)
	_lamp(mid + 200.0, y - 215.0, GLOW_WARM)


## Moorings: the cluster is a wreck fragment caught across the Mouth and held by catch-cables to the cliffs.
func _moorings() -> void:
	var anchors := [
		[Vector2(2448.0, HollowMap.lvl(6)), Vector2(HollowMap.MOUTH_L, HollowMap.lvl(5.5))],
		[Vector2(3952.0, HollowMap.lvl(6)), Vector2(HollowMap.MOUTH_R, HollowMap.lvl(5.5))],
		[Vector2(2160.0, HollowMap.lvl(7.5)), Vector2(HollowMap.MOUTH_L, HollowMap.lvl(7.0))],
		[Vector2(4240.0, HollowMap.lvl(7.5)), Vector2(HollowMap.MOUTH_R, HollowMap.lvl(7.0))],
	]
	for pair in anchors:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		draw_line(a, b, STEEL, 4.0)
		draw_line(a, b, STEEL_HI, 1.0)
		draw_rect(Rect2(b.x - (14.0 if b.x < 3200.0 else 0.0), b.y - 12.0, 14.0, 24.0), STEEL_LO)
