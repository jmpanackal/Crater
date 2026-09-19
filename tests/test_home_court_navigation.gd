extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _walk_to(player: CharacterBody2D, target: Vector2, action: String) -> void:
	Input.action_press(action)
	var arrived := false
	for frame in range(360):
		await physics_frame
		if player.global_position.distance_to(target) < 7.0:
			arrived = true
			break
	Input.action_release(action)
	for frame in range(12):
		await physics_frame
	if not arrived or not player.is_on_floor():
		_failed = true
		push_error("FAIL walking to %s stopped at %s" % [target, player.global_position])
	else:
		print("PASS walked to %s without jumping or teleporting" % target)


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	for frame in range(12):
		await physics_frame
	if player.position.distance_to(HollowLayout.player_spawn_point()) > 2.0:
		push_error("FAIL Home Court spawn is obstructed")
		quit(1)
		return
	var landing := HollowLayout.HOME_LANDING
	await _walk_to(player, Vector2(landing.y - 48, landing.z - 32), "ui_right")
	Input.action_press("ui_right")
	for frame in range(30):
		await physics_frame
	Input.action_release("ui_right")
	if player.position.x > landing.y - 32 + 1 or not player.is_on_floor():
		_failed = true
		push_error("FAIL enclosed landing allows falling through the east wall")
	await _walk_to(player, HollowLayout.player_spawn_point(), "ui_left")
	await _walk_to(player, Vector2(-112, HollowLayout.LOWER_WORK_Y - 32), "ui_left")
	await _walk_to(player, Vector2(-264, HollowLayout.LOWER_WORK_Y - 32), "ui_left")
	await _walk_to(player, Vector2(-960, HollowLayout.BOTTOM_WEST_Y - 32), "ui_left")
	Input.action_press("ui_left")
	for frame in range(120):
		await physics_frame
		if player.position.x <= HollowLayout.LADDER_CHAMBER_X + 16:
			break
	Input.action_release("ui_left")
	for frame in range(30):
		await physics_frame
	if not player.is_on_floor() or absf(player.position.y - (HollowLayout.CHAMBER_ALCOVE_Y - 32)) > 2:
		_failed = true
		push_error("FAIL side chamber cannot be entered safely: %s" % player.position)
	await _walk_to(player, Vector2(HollowLayout.LADDER_CHAMBER_X + 8, HollowLayout.CHAMBER_ALCOVE_Y - 32), "ui_right")
	await _walk_to(player, Vector2(HollowLayout.GALLERY_FLOOR.x, HollowLayout.BOTTOM_WEST_Y - 32), "ui_up")
	await _walk_to(player, HollowLayout.player_spawn_point(), "ui_right")
	await _walk_to(player, Vector2(landing.y - 48, landing.z - 32), "ui_right")
	var zones: Node = root.get_node("Zones")
	var camera: Camera2D = player.get_node("Camera2D")
	if not camera.zoom.is_equal_approx(Vector2.ONE):
		_failed = true
		push_error("FAIL camera changes the original zoom")
	if not zones.validate_seams().is_empty():
		_failed = true
		push_error("FAIL route seams are not reciprocal")
	scene.queue_free()
	await process_frame
	quit(1 if _failed else 0)
