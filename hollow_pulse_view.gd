extends Node2D
## The Pulse (USER-locked canon, mechanics-canon section 11): a large surviving component of the crashed colony
## ship, standing on the Ritual Raft at Mid Heart. Visibly degraded technology, never occult: metal housings,
## conduits, vents, gauges and indicators, mismatched repair plates, grime and fungal growth. It is the civic
## timekeeper, so its indicator lamps follow the civic phase (Rousing, Working, Gathering, Ritual). Its original
## ship function is OPEN: nothing here says what it did. Back layer, no collision (the crossing passes in front).

const CHUNK := 128.0
const CENTER_X := 3200.0
const HOUSING := Color(0.2, 0.22, 0.25)
const HOUSING_HI := Color(0.33, 0.36, 0.4)
const HOUSING_LO := Color(0.1, 0.11, 0.13)
const PLATE_A := Color(0.36, 0.28, 0.2)
const PLATE_B := Color(0.26, 0.31, 0.3)
const CONDUIT := Color(0.28, 0.24, 0.2)
const GRIME := Color(0.05, 0.05, 0.04, 0.45)
const FUNGUS := Color(0.22, 0.4, 0.3, 0.5)
const LAMP_OFF := Color(0.08, 0.09, 0.1)
const LAMP_COUNT := 8

var _phase: StringName = &"rousing"


## Lit lamps and their colour for a civic phase (display only).
static func lamps_for(phase: StringName) -> Dictionary:
	match phase:
		&"rousing":
			return {"lit": 2, "color": Color(0.95, 0.7, 0.3)}
		&"working":
			return {"lit": 6, "color": Color(0.45, 0.85, 0.78)}
		&"gathering":
			return {"lit": 8, "color": Color(0.98, 0.8, 0.45)}
		&"ritual":
			return {"lit": 8, "color": Color(1.0, 0.95, 0.75)}
	return {"lit": 3, "color": Color(0.7, 0.7, 0.7)}


func current_lamps() -> Dictionary:
	return lamps_for(_phase)


func _ready() -> void:
	z_index = -1
	var clock := get_node_or_null("/root/Clock")
	if clock != null and clock.has_method("get_phase"):
		_phase = clock.get_phase()
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("phase_changed"):
		bus.phase_changed.connect(_on_phase_changed)
	queue_redraw()


func _on_phase_changed(_old: StringName, new_phase: StringName) -> void:
	if new_phase != _phase:
		_phase = new_phase
		queue_redraw()


func _draw() -> void:
	var deck := HollowMap.lvl(7.5)
	var x := CENTER_X
	# plinth and base conduits running out along the deck to the raft's edges
	_chunked(Rect2(x - 260.0, deck - 36.0, 520.0, 36.0), HOUSING_LO)
	_chunked(Rect2(x - 260.0, deck - 36.0, 520.0, 5.0), HOUSING_HI)
	for side in [-1.0, 1.0]:
		var pipe_x: float = x + 260.0 if side > 0.0 else x - 480.0 # along the raft only, never past its edge
		_chunked(Rect2(pipe_x, deck - 26.0, 220.0, 14.0), CONDUIT)
		_chunked(Rect2(pipe_x, deck - 26.0, 220.0, 3.0), HOUSING_HI)
	# main drum
	var body := Rect2(x - 150.0, deck - 420.0, 300.0, 384.0)
	_chunked(body, HOUSING)
	_chunked(Rect2(body.position.x + 12.0, body.position.y, 22.0, body.size.y), HOUSING_HI)
	_chunked(Rect2(body.end.x - 26.0, body.position.y, 26.0, body.size.y), HOUSING_LO)
	var by := body.position.y + 40.0
	while by < body.end.y - 20.0:
		draw_rect(Rect2(body.position.x - 8.0, by, body.size.x + 16.0, 10.0), HOUSING_LO)
		draw_rect(Rect2(body.position.x - 8.0, by, body.size.x + 16.0, 2.0), HOUSING_HI)
		by += 88.0
	# domed cap and a stack with vents
	draw_rect(Rect2(x - 120.0, body.position.y - 22.0, 240.0, 22.0), HOUSING)
	draw_rect(Rect2(x - 80.0, body.position.y - 40.0, 160.0, 18.0), HOUSING_HI)
	draw_rect(Rect2(x - 28.0, body.position.y - 96.0, 56.0, 56.0), HOUSING_LO)
	for i in range(4):
		draw_rect(Rect2(x - 22.0, body.position.y - 90.0 + float(i) * 12.0, 44.0, 5.0), Color(0.02, 0.02, 0.03))
	# flanking conduits up the sides, with a mismatched repair clamp
	for sx in [x - 200.0, x + 184.0]:
		_chunked(Rect2(sx, deck - 360.0, 16.0, 324.0), CONDUIT)
		draw_rect(Rect2(sx - 4.0, deck - 220.0, 24.0, 28.0), PLATE_B)
	# repair plates in odd colours bolted over the housing
	draw_rect(Rect2(x - 118.0, body.position.y + 120.0, 96.0, 64.0), PLATE_A)
	draw_rect(Rect2(x + 30.0, body.position.y + 230.0, 84.0, 72.0), PLATE_B)
	draw_rect(Rect2(x - 100.0, body.position.y + 290.0, 70.0, 40.0), PLATE_A)
	for p in [Vector2(-114.0, 124.0), Vector2(-30.0, 124.0), Vector2(34.0, 234.0), Vector2(106.0, 234.0)]:
		draw_rect(Rect2(x + p.x, body.position.y + p.y, 4.0, 4.0), HOUSING_HI)
	# gauges: round dials with a needle each
	for g in [Vector2(-60.0, 70.0), Vector2(60.0, 70.0)]:
		var c := Vector2(x + g.x, body.position.y + g.y)
		draw_circle(c, 22.0, HOUSING_LO)
		draw_circle(c, 18.0, Color(0.72, 0.7, 0.6))
		draw_line(c, c + Vector2(9.0, -11.0) if g.x < 0.0 else c + Vector2(-7.0, -13.0), Color(0.55, 0.12, 0.1), 2.0)
	# indicator lamps, lit by the civic phase
	var lamps := current_lamps()
	var lit: int = lamps["lit"]
	var lit_color: Color = lamps["color"]
	var lamp_y := body.position.y + 96.0
	for i in range(LAMP_COUNT):
		var lx := x - 112.0 + float(i) * 32.0
		var on := i < lit
		draw_rect(Rect2(lx - 7.0, lamp_y - 7.0, 18.0, 18.0), HOUSING_LO)
		draw_rect(Rect2(lx - 4.0, lamp_y - 4.0, 12.0, 12.0), lit_color if on else LAMP_OFF)
		if on:
			draw_circle(Vector2(lx + 2.0, lamp_y + 2.0), 14.0, Color(lit_color.r, lit_color.g, lit_color.b, 0.14))
	# grime streaks and fungal growth at the foot
	for gx in [-120.0, -40.0, 50.0, 110.0]:
		draw_rect(Rect2(x + gx, body.position.y + 40.0, 10.0, 300.0), GRIME)
	for f in [Vector2(-132.0, -44.0), Vector2(-118.0, -52.0), Vector2(120.0, -40.0), Vector2(134.0, -50.0), Vector2(-60.0, -34.0)]:
		draw_circle(Vector2(x + f.x, deck + f.y), 12.0, FUNGUS)


func _chunked(r: Rect2, color: Color) -> void:
	var y := r.position.y
	while y < r.end.y:
		var h := minf(CHUNK, r.end.y - y)
		draw_rect(Rect2(r.position.x, y, r.size.x, h), color)
		y += h
