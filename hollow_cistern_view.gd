extends Node2D
## The Cistern's pressure basin (USER 2026-10-03: one tall chamber, seen whole from the galleries): three
## riveted pressure tanks standing the full height of hall H_CI, sight glasses showing how full they are, risers
## and manifolds between them. The fill follows the Cistern's condition (District), so a strained Cistern
## visibly runs low. Back layer, no collision: the streets, the pier and the freight elevator stay in front.

const HALL_ID := &"H_CI"
const CHUNK := 128.0
const TANK_W := 176.0
const BODY := Color(0.15, 0.19, 0.22)
const BODY_HI := Color(0.24, 0.3, 0.34)
const BAND := Color(0.09, 0.11, 0.13)
const PIPE := Color(0.2, 0.3, 0.33)
const WATER := Color(0.22, 0.55, 0.64, 0.6)
const WATER_LINE := Color(0.55, 0.85, 0.9, 0.85)

## Tank left edges, clear of the freight elevator's shaft (x 8688..8880) and the pier.
const TANK_X := [8128.0, 8352.0, 8960.0]

var _rect := Rect2()
var _condition: StringName = &"stable"


## How full the tanks look for a Cistern condition (display only, not a simulation value).
static func fill_for(condition: StringName) -> float:
	match condition:
		&"comfortable":
			return 0.9
		&"stable":
			return 0.75
		&"strained":
			return 0.5
		&"shortage":
			return 0.3
		&"critical":
			return 0.12
	return 0.75


func _ready() -> void:
	z_index = -1
	for h in HollowMap.halls():
		if h["id"] == HALL_ID:
			var top := HollowMap.lvl(11.0) - HollowMap.ROOM_HEIGHT # the tanks stand in the basin chamber, not up the whole Mid-East shaft
			_rect = Rect2(float(h["x0"]), top, float(h["x1"]) - float(h["x0"]), HollowMap.lvl(float(h["k_bottom"])) - top)
	var district := get_node_or_null("/root/District")
	if district != null and district.has_method("get_condition"):
		_condition = district.get_condition(&"cistern")
	var bus := get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("district_changed"):
		bus.district_changed.connect(_on_district_changed)
	queue_redraw()


func _on_district_changed(district_id: StringName, condition: StringName) -> void:
	if district_id == &"cistern" and condition != _condition:
		_condition = condition
		queue_redraw()


func current_fill() -> float:
	return fill_for(_condition)


func _draw() -> void:
	if _rect.size == Vector2.ZERO:
		return
	var floor_y := _rect.end.y - 16.0
	var top_y := _rect.position.y + 48.0
	# manifold: a horizontal header pipe near the top and a lower one, tying the tanks together
	for header_y in [top_y + 64.0, floor_y - 200.0]:
		_chunked(Rect2(_rect.position.x + 16.0, header_y, _rect.size.x - 32.0, 14.0), PIPE)
		_chunked(Rect2(_rect.position.x + 16.0, header_y + 14.0, _rect.size.x - 32.0, 3.0), BAND)
	var fill := current_fill()
	for tx in TANK_X:
		_tank(float(tx), top_y, floor_y, fill)
	# a riser from each tank's foot down to the floor, with a coupling
	for tx in TANK_X:
		var rx := float(tx) + TANK_W * 0.5 - 7.0
		draw_rect(Rect2(rx, floor_y - 40.0, 14.0, 40.0), PIPE)
		draw_rect(Rect2(rx - 4.0, floor_y - 44.0, 22.0, 8.0), BAND)


func _tank(x: float, top_y: float, floor_y: float, fill: float) -> void:
	var h := floor_y - top_y
	# domed cap and foot
	draw_rect(Rect2(x + 12.0, top_y - 12.0, TANK_W - 24.0, 12.0), BODY)
	draw_rect(Rect2(x + 28.0, top_y - 22.0, TANK_W - 56.0, 10.0), BODY_HI)
	_chunked(Rect2(x, top_y, TANK_W, h), BODY)
	_chunked(Rect2(x + 10.0, top_y, 14.0, h), BODY_HI)
	# water behind a sight glass: a channel down the middle of the tank
	var glass := Rect2(x + TANK_W * 0.5 - 14.0, top_y + 32.0, 28.0, h - 72.0)
	_chunked(glass, Color(0.05, 0.07, 0.09))
	var water_h := glass.size.y * fill
	var water := Rect2(glass.position.x, glass.end.y - water_h, glass.size.x, water_h)
	_chunked(water, WATER)
	draw_rect(Rect2(water.position.x, water.position.y, water.size.x, 3.0), WATER_LINE)
	# riveted bands every 96 px
	var by := top_y + 48.0
	while by < floor_y - 24.0:
		draw_rect(Rect2(x - 3.0, by, TANK_W + 6.0, 8.0), BAND)
		for rx in [x + 10.0, x + TANK_W - 16.0]:
			draw_rect(Rect2(rx, by + 2.0, 4.0, 4.0), BODY_HI)
		by += 96.0


## Big fills are drawn in short pieces: one huge filled rect is far slower than the same area in strips.
func _chunked(r: Rect2, color: Color) -> void:
	var y := r.position.y
	while y < r.end.y:
		var h := minf(CHUNK, r.end.y - y)
		draw_rect(Rect2(r.position.x, y, r.size.x, h), color)
		y += h
