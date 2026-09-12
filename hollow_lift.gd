extends AnimatableBody2D
## Presswater freight/passenger cage — on-screen platform (not fast travel).
## Fiction: Cistern-powered. Essential Heart hoist always runs; secondary lifts
## slow or park when Presswater is thin / at protected reserve (never softlocks).

const SoftWorldLabel := preload("res://soft_world_label.gd")

@export var lift_id: StringName = HollowLayout.HEART_HOIST_ID
@export var move_speed: float = 72.0
@export var thin_speed_mult: float = 0.35
@export var hint_text: String = "[W/S] ride lift"
@export var parked_hint: String = "Presswater thin — lift parked"
@export var snap_epsilon: float = 2.5
@export var default_stop_index: int = 1

var _stops: Array[float] = []
var _stop_index: int = 1
var _target_y: float = 0.0
var _moving: bool = false
var _riders: int = 0
var _hint: Label
var _parked: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 3
	_stops = HollowLayout.stop_ys_for_lift(lift_id)
	_stop_index = clampi(default_stop_index, 0, maxi(0, _stops.size() - 1))
	_target_y = _stops[_stop_index]
	position = Vector2(HollowLayout.lift_x_for(lift_id), _target_y)
	_build_collision()
	_build_visuals()
	_build_rider_sensor()
	_build_hint()
	_refresh_service_state()


func current_stop_index() -> int:
	return _stop_index


func is_moving() -> bool:
	return _moving


func stop_count() -> int:
	return _stops.size()


func is_essential() -> bool:
	return HollowLayout.is_essential_lift(lift_id)


func is_parked() -> bool:
	return _parked


func service_speed_mult() -> float:
	## healthy: 1.0 — thin: slow secondary — reserve: secondary parked (0)
	if is_essential():
		return 1.0
	var districts := _districts()
	if districts == null:
		return 1.0
	var amount: int = int(districts.get_good_amount(districts.PRESSWATER))
	var reserve: int = int(districts.PROTECTED_RESERVE)
	if amount <= reserve:
		return 0.0
	if districts.has_method("is_production_thin") and districts.is_production_thin(districts.PRESSWATER):
		return thin_speed_mult
	if amount < int(districts.THIN_PRODUCTION_THRESHOLD):
		return thin_speed_mult
	return 1.0


func _districts() -> Node:
	return get_tree().root.get_node_or_null("Districts")


func _refresh_service_state() -> void:
	var mult := service_speed_mult()
	_parked = mult <= 0.0 and not is_essential()
	if _hint:
		_hint.text = parked_hint if _parked else hint_text


func _build_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(HollowLayout.LIFT_WIDTH, 12.0)
	col.shape = shape
	col.position = Vector2(HollowLayout.LIFT_WIDTH * 0.5, 6.0)


func _build_visuals() -> void:
	if get_node_or_null("Cage") != null:
		return
	var cage := Node2D.new()
	cage.name = "Cage"
	add_child(cage)

	var floor_plank := ColorRect.new()
	floor_plank.name = "Floor"
	floor_plank.position = Vector2(0.0, 0.0)
	floor_plank.size = Vector2(HollowLayout.LIFT_WIDTH, 10.0)
	floor_plank.color = Color(0.42, 0.32, 0.22, 0.95)
	floor_plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cage.add_child(floor_plank)

	var rail_l := ColorRect.new()
	rail_l.name = "RailL"
	rail_l.position = Vector2(2.0, -36.0)
	rail_l.size = Vector2(3.0, 36.0)
	rail_l.color = Color(0.65, 0.41, 0.28, 0.9)
	rail_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cage.add_child(rail_l)

	var rail_r := ColorRect.new()
	rail_r.name = "RailR"
	rail_r.position = Vector2(HollowLayout.LIFT_WIDTH - 5.0, -36.0)
	rail_r.size = Vector2(3.0, 36.0)
	rail_r.color = Color(0.65, 0.41, 0.28, 0.9)
	rail_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cage.add_child(rail_r)

	var bar := ColorRect.new()
	bar.name = "TopBar"
	bar.position = Vector2(2.0, -38.0)
	bar.size = Vector2(HollowLayout.LIFT_WIDTH - 4.0, 3.0)
	bar.color = Color(0.55, 0.4, 0.28, 0.85)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cage.add_child(bar)

	var cable := ColorRect.new()
	cable.name = "GuideCable"
	cable.position = Vector2(HollowLayout.LIFT_WIDTH * 0.5 - 1.0, -220.0)
	cable.size = Vector2(2.0, 220.0)
	cable.color = Color(0.35, 0.32, 0.28, 0.55)
	cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cable.z_index = -1
	cage.add_child(cable)

	var plate := ColorRect.new()
	plate.name = "PresswaterPlate"
	plate.position = Vector2(10.0, -18.0)
	plate.size = Vector2(28.0, 10.0)
	plate.color = Color(0.55, 0.71, 0.77, 0.55)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cage.add_child(plate)

	var truss := ColorRect.new()
	truss.name = "TrussMark"
	truss.position = Vector2(-6.0, -8.0)
	truss.size = Vector2(4.0, 16.0)
	truss.color = Color(0.3, 0.22, 0.16, 0.7)
	truss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cage.add_child(truss)

	# Secondary lifts get a slightly cooler / freight cue.
	if lift_id == HollowLayout.FREIGHT_LIFT_ID:
		floor_plank.color = Color(0.35, 0.4, 0.42, 0.95)
		plate.color = Color(0.55, 0.71, 0.77, 0.75)
	elif lift_id == HollowLayout.LEFT_SERVICE_ID:
		floor_plank.color = Color(0.38, 0.34, 0.26, 0.95)


func _build_rider_sensor() -> void:
	var sensor := get_node_or_null("RiderSensor") as Area2D
	if sensor == null:
		sensor = Area2D.new()
		sensor.name = "RiderSensor"
		add_child(sensor)
	sensor.collision_layer = 0
	sensor.collision_mask = 1
	sensor.monitoring = true
	sensor.monitorable = false
	var col := sensor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		sensor.add_child(col)
	var shape := RectangleShape2D.new()
	# Tall enough to catch a standing 32px body with feet on the cage floor.
	shape.size = Vector2(HollowLayout.LIFT_WIDTH - 4.0, 52.0)
	col.shape = shape
	col.position = Vector2(HollowLayout.LIFT_WIDTH * 0.5, -20.0)
	if not sensor.body_entered.is_connected(_on_rider_entered):
		sensor.body_entered.connect(_on_rider_entered)
	if not sensor.body_exited.is_connected(_on_rider_exited):
		sensor.body_exited.connect(_on_rider_exited)


func _build_hint() -> void:
	_hint = Label.new()
	_hint.name = "LiftHint"
	_hint.text = hint_text
	_hint.position = Vector2(-4.0, -58.0)
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.set_script(SoftWorldLabel)
	_hint.set("show_radius", 120.0)
	_hint.set("far_alpha", 0.05)
	_hint.set("near_alpha", 0.8)
	_hint.modulate = Color(0.85, 0.78, 0.6, 0.75)
	_hint.z_index = 4
	add_child(_hint)


func _on_rider_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_riders += 1
		_refresh_service_state()


func _on_rider_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_riders = maxi(0, _riders - 1)


func _physics_process(delta: float) -> void:
	_refresh_service_state()
	_resync_riders()
	var speed_mult := service_speed_mult()

	if _riders > 0 and not _moving and not _parked and speed_mult > 0.0:
		# Match player climb: W/S OR ui_up/ui_down (W/S are not always bound to ui_*).
		var climb_up := _just_up()
		var climb_down := _just_down()
		if not climb_up and not climb_down and absf(position.y - _stops[_stop_index]) <= snap_epsilon:
			if _held_up():
				climb_up = true
			elif _held_down():
				climb_down = true
		if climb_up and _stop_index > 0:
			_stop_index -= 1
			_target_y = _stops[_stop_index]
			_moving = true
		elif climb_down and _stop_index < _stops.size() - 1:
			_stop_index += 1
			_target_y = _stops[_stop_index]
			_moving = true

	if not _moving:
		position.y = _stops[_stop_index]
		_store_key_edges()
		return

	# If Presswater collapses mid-ride on a secondary, finish to nearest stop slowly
	# so the player is never stranded between decks.
	var step := move_speed * maxf(speed_mult, 0.2 if is_essential() else thin_speed_mult) * delta
	if is_essential():
		step = move_speed * delta
	elif _parked:
		# Complete current travel at crawl so riders reach a deck.
		step = move_speed * thin_speed_mult * delta

	var dy := _target_y - position.y
	if absf(dy) <= step:
		position.y = _target_y
		_moving = false
	else:
		position.y += signf(dy) * step
	_store_key_edges()


func _resync_riders() -> void:
	## Area enter/exit can miss briefly-masked bodies; recount overlapping players.
	var sensor := get_node_or_null("RiderSensor") as Area2D
	if sensor == null:
		return
	var count := 0
	for body in sensor.get_overlapping_bodies():
		if body is Node and (body as Node).is_in_group("player"):
			count += 1
	_riders = count


func _just_up() -> bool:
	return _just("ui_up") or _key_just(KEY_W)


func _just_down() -> bool:
	return _just("ui_down") or _key_just(KEY_S)


func _held_up() -> bool:
	return _held("ui_up") or Input.is_physical_key_pressed(KEY_W)


func _held_down() -> bool:
	return _held("ui_down") or Input.is_physical_key_pressed(KEY_S)


func _just(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)


func _held(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)


var _prev_w := false
var _prev_s := false


func _key_just(keycode: Key) -> bool:
	var pressed := Input.is_physical_key_pressed(keycode)
	if keycode == KEY_W:
		return pressed and not _prev_w
	if keycode == KEY_S:
		return pressed and not _prev_s
	return false


func _store_key_edges() -> void:
	_prev_w = Input.is_physical_key_pressed(KEY_W)
	_prev_s = Input.is_physical_key_pressed(KEY_S)
