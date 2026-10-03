extends AnimatableBody2D
## A Presswater elevator (USER 2026-10-02; LOCKED canon: the Cistern's pressurized water drives lifts, and
## Cistern strain slows or parks them). Two classes, both declared in HollowMap.lifts():
##   freight  a large, slower cab that carries you through several districts (160 px wide);
##   premium  a small, quick cab, the only way up to Ashram Heights (96 px wide).
## Stand on the cab and press W (up) or S (down) to ride to the next stop; at any stop's landing press Interact
## to call the cab. It is a slow physical platform, never fast travel. An `essential` lift never parks (it
## slows when the Cistern is strained); the others park when the Cistern is critical, finishing any trip at a
## crawl so nobody is stranded between decks. An Access gate can lock a lift (locked: parked and says so).

const SoftWorldLabel := preload("res://soft_world_label.gd")
const CallScript := preload("res://elevator_call.gd")

@export var lift_id: StringName = &""
@export var snap_epsilon := 2.5
@export var thin_speed_mult := 0.35

var kind: StringName = &"freight"
var width := 160.0
var essential := false
var access_gate_id: StringName = &""
var move_speed := 140.0

var _stops: Array[float] = []
var _stop_index := 0
var _target_y := 0.0
var _moving := false
var _riders := 0
var _hint: Label
var _gauge: ColorRect
var _cable: ColorRect
var _cable_top_offset := 0.0
var _parked := false
var _prev_w := false
var _prev_s := false
var _district_cache: Node = null


func _ready() -> void:
	var data := HollowLayout.lift_data(lift_id)
	assert(not data.is_empty(), "no lift %s in HollowMap.lifts()" % str(lift_id))
	kind = data["kind"]
	width = float(data["width"])
	essential = bool(data["essential"])
	access_gate_id = data["gate"]
	move_speed = 220.0 if kind == &"premium" else 140.0
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 3
	_stops = HollowLayout.stop_ys_for_lift(lift_id)
	# Park at the bottom stop: a rider arriving from below finds the cab waiting.
	_stop_index = _stops.size() - 1
	_target_y = _stops[_stop_index]
	position = Vector2(HollowLayout.lift_x_for(lift_id), _target_y)
	_build_collision()
	_build_visuals()
	_build_rider_sensor()
	_build_hint()
	_build_call_points()
	_refresh_service_state()


func current_stop_index() -> int:
	return _stop_index


func stop_count() -> int:
	return _stops.size()


func is_moving() -> bool:
	return _moving


func is_parked() -> bool:
	return _parked


func is_essential() -> bool:
	return essential


func is_locked() -> bool:
	if access_gate_id == &"" or not is_inside_tree():
		return false
	var access := get_tree().root.get_node_or_null("Access")
	return access != null and not bool(access.is_open(access_gate_id))


## The Cistern's condition drives the Presswater: healthy 1.0, strained or short 0.35, critical 0 (essential
## lifts never go below the slow speed).
func service_speed_mult() -> float:
	if is_locked():
		return 0.0
	var condition := _cistern_condition()
	var mult := 1.0
	if condition == &"critical":
		mult = 0.0
	elif condition == &"shortage" or condition == &"strained":
		mult = thin_speed_mult
	if essential:
		return maxf(mult, thin_speed_mult)
	return mult


func _cistern_condition() -> StringName:
	if _district_cache == null and is_inside_tree():
		_district_cache = get_tree().root.get_node_or_null("District")
	if _district_cache == null or not _district_cache.has_method("get_condition"):
		return &"stable"
	return _district_cache.get_condition(&"cistern")


## Bring the cab to a stop (the call button on the landing). No effect while it is moving, locked or parked.
func call_to(index: int) -> bool:
	if _moving or _parked or index < 0 or index >= _stops.size() or index == _stop_index:
		return false
	_stop_index = index
	_target_y = _stops[index]
	_moving = true
	return true


func stop_for_y(deck_y: float) -> int:
	for i in range(_stops.size()):
		if absf(_stops[i] - deck_y) < 1.0:
			return i
	return -1


func _refresh_service_state() -> void:
	_parked = service_speed_mult() <= 0.0
	if _hint != null:
		if is_locked():
			_hint.text = "Warden-run: not cleared yet"
		elif _parked:
			_hint.text = "Presswater out: lift parked"
		elif service_speed_mult() < 1.0:
			_hint.text = "Presswater thin: lift slow  [W/S] ride"
		else:
			_hint.text = "[W/S] ride  [E] call"
	if _gauge != null:
		var m := service_speed_mult()
		_gauge.color = Color(0.45, 0.78, 0.7, 0.9) if m >= 1.0 else (Color(0.85, 0.66, 0.3, 0.9) if m > 0.0 else Color(0.8, 0.3, 0.25, 0.9))


func _build_collision() -> void:
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 12.0)
	col.shape = shape
	col.position = Vector2(width * 0.5, 6.0)
	add_child(col)


func _rect(parent: Node, name: String, pos: Vector2, size_px: Vector2, color: Color, z := 0) -> ColorRect:
	var r := ColorRect.new()
	r.name = name
	r.position = pos
	r.size = size_px
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = z
	parent.add_child(r)
	return r


func _build_visuals() -> void:
	var cab := Node2D.new()
	cab.name = "Cab"
	add_child(cab)
	var premium := kind == &"premium"
	var frame := Color(0.72, 0.58, 0.34, 0.95) if premium else Color(0.34, 0.38, 0.4, 0.95)
	var floor_col := Color(0.82, 0.76, 0.62, 0.95) if premium else Color(0.3, 0.33, 0.35, 0.95)
	var h := 76.0 if premium else 92.0
	_rect(cab, "Floor", Vector2(0.0, 0.0), Vector2(width, 10.0), floor_col)
	_rect(cab, "RailL", Vector2(2.0, -h), Vector2(4.0, h), frame)
	_rect(cab, "RailR", Vector2(width - 6.0, -h), Vector2(4.0, h), frame)
	_rect(cab, "Canopy", Vector2(0.0, -h - 4.0), Vector2(width, 6.0), frame)
	if premium:
		# warm glass panels and a brass lamp
		_rect(cab, "GlassL", Vector2(6.0, -h + 6.0), Vector2(width * 0.5 - 10.0, h - 16.0), Color(0.75, 0.88, 0.9, 0.18), -1)
		_rect(cab, "GlassR", Vector2(width * 0.5 + 4.0, -h + 6.0), Vector2(width * 0.5 - 10.0, h - 16.0), Color(0.75, 0.88, 0.9, 0.18), -1)
		_rect(cab, "Lamp", Vector2(width * 0.5 - 4.0, -h + 2.0), Vector2(8.0, 6.0), Color(1.0, 0.82, 0.45, 0.95))
	else:
		# heavy: hazard bands, a chain bar and a pressure pipe up the side
		for i in range(int(width / 20.0)):
			_rect(cab, "Hazard%d" % i, Vector2(float(i) * 20.0, 0.0), Vector2(10.0, 4.0), Color(0.82, 0.66, 0.2, 0.9), 1)
		_rect(cab, "Chain", Vector2(width * 0.5 - 2.0, -h - 90.0), Vector2(4.0, 90.0), Color(0.3, 0.3, 0.3, 0.8), -1)
		_rect(cab, "Pipe", Vector2(width - 14.0, -h), Vector2(6.0, h), Color(0.38, 0.55, 0.58, 0.85), 1)
	_gauge = _rect(cab, "PressureGauge", Vector2(10.0, -h + 8.0), Vector2(14.0, 8.0), Color(0.45, 0.78, 0.7, 0.9), 2)
	_cable_top_offset = -h - 4.0
	_cable = _rect(cab, "GuideCable", Vector2(width * 0.5 - 1.0, 0.0), Vector2(2.0, 0.0), Color(0.35, 0.32, 0.28, 0.5), -2)
	_update_cable()


func _build_rider_sensor() -> void:
	var sensor := Area2D.new()
	sensor.name = "RiderSensor"
	sensor.collision_layer = 0
	sensor.collision_mask = 1
	sensor.monitoring = true
	sensor.monitorable = false
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width - 8.0, 52.0)
	col.shape = shape
	col.position = Vector2(width * 0.5, -20.0)
	sensor.add_child(col)
	add_child(sensor)


func _build_hint() -> void:
	_hint = Label.new()
	_hint.name = "LiftHint"
	_hint.position = Vector2(-4.0, -118.0)
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.set_script(SoftWorldLabel)
	_hint.set("show_radius", 420.0)
	_hint.set("far_alpha", 0.05)
	_hint.set("near_alpha", 0.85)
	_hint.modulate = Color(0.85, 0.78, 0.6, 0.75)
	_hint.z_index = 4
	add_child(_hint)


## One call point per stop, standing at the shaft on that deck.
func _build_call_points() -> void:
	for i in range(_stops.size()):
		var call := Area2D.new()
		call.name = "Call_%d" % i
		call.set_script(CallScript)
		call.set("elevator_path", get_path())
		call.set("stop_index", i)
		call.set("shaft_width", width)
		# Not a child: the cab moves, the landing does not.
		get_parent().add_child.call_deferred(call)
		call.position = Vector2(HollowLayout.lift_x_for(lift_id) + width * 0.5, _stops[i] - 16.0)


func _physics_process(delta: float) -> void:
	_refresh_service_state()
	_resync_riders()
	var speed_mult := service_speed_mult()
	if _riders > 0 and not _moving and not _parked and speed_mult > 0.0:
		var up := _key_just(KEY_W) or Input.is_action_just_pressed("ui_up")
		var down := _key_just(KEY_S) or Input.is_action_just_pressed("ui_down")
		if not up and not down and absf(position.y - _stops[_stop_index]) <= snap_epsilon:
			if Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
				up = true
			elif Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
				down = true
		if up and _stop_index > 0:
			_stop_index -= 1
			_target_y = _stops[_stop_index]
			_moving = true
		elif down and _stop_index < _stops.size() - 1:
			_stop_index += 1
			_target_y = _stops[_stop_index]
			_moving = true
	if not _moving:
		position.y = _stops[_stop_index]
		_update_cable()
		_store_key_edges()
		return
	# Trips in progress finish at no less than a crawl, so a parked cab never strands its riders.
	var step := move_speed * maxf(speed_mult, thin_speed_mult) * delta
	var dy := _target_y - position.y
	if absf(dy) <= step:
		position.y = _target_y
		_moving = false
	else:
		position.y += signf(dy) * step
	_update_cable()
	_store_key_edges()


## The landing plates (hollow_structures.gd) register their collision shapes here. A plate is disabled while the
## cab is flush with its stop, so the cab floor, not the plate, carries a rider; otherwise it holds walkers up.
var _landing_shapes: Dictionary = {}


func register_landing(index: int, shape: CollisionShape2D) -> void:
	_landing_shapes[index] = shape
	_update_landings()


func _update_landings() -> void:
	for i in _landing_shapes.keys():
		var shape := _landing_shapes[i] as CollisionShape2D
		if shape != null and is_instance_valid(shape):
			shape.set_deferred("disabled", absf(position.y - _stops[int(i)]) < 10.0)


## The guide cable hangs only inside the shaft: from the top stop's deck down to the cab, never above it.
func _update_cable() -> void:
	if _cable == null or _stops.is_empty():
		return
	var top_local := _stops[0] - position.y
	_cable.position.y = top_local
	_cable.size.y = maxf(0.0, _cable_top_offset - top_local)
	_update_landings()


func _resync_riders() -> void:
	var sensor := get_node_or_null("RiderSensor") as Area2D
	if sensor == null:
		return
	var count := 0
	for body in sensor.get_overlapping_bodies():
		if body is Node and (body as Node).is_in_group("player"):
			count += 1
	_riders = count


func _key_just(keycode: Key) -> bool:
	var pressed := Input.is_physical_key_pressed(keycode)
	if keycode == KEY_W:
		return pressed and not _prev_w
	return pressed and not _prev_s


func _store_key_edges() -> void:
	_prev_w = Input.is_physical_key_pressed(KEY_W)
	_prev_s = Input.is_physical_key_pressed(KEY_S)
