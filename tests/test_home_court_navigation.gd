extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _walk_to(player: CharacterBody2D, target: Vector2, action: String, x_slop: float = 24.0) -> void:
	Input.action_press(action)
	var arrived := false
	for frame in range(600):
		await physics_frame
		var close := player.global_position.distance_to(target) < 16.0
		if action == "ui_left" or action == "ui_right":
			close = (
				absf(player.global_position.x - target.x) < x_slop
				and absf(player.global_position.y - target.y) < 48.0
				and player.is_on_floor()
			)
		elif action == "ui_up" or action == "ui_down":
			close = (
				absf(player.global_position.x - target.x) < 56.0
				and absf(player.global_position.y - target.y) < 24.0
			)
		if close:
			arrived = true
			break
	Input.action_release(action)
	for frame in range(16):
		await physics_frame
	if not arrived:
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

	# Worker return spur (ladder from Switchback).
	await _walk_to(player, Vector2(HollowLayout.LADDER_RETURN_X, HollowLayout.LOWER_WORK_Y - 32), "ui_left")
	if _failed:
		quit(1)
		return
	await _walk_to(player, Vector2(-160, HollowLayout.HEART_Y - 32), "ui_up")
	if _failed:
		quit(1)
		return
	await _walk_to(player, Vector2(-304, HollowLayout.HEART_Y - 32), "ui_left")
	# Stay on the west pad — walking past the ladder shaft falls to the corridor.
	await _walk_to(player, Vector2(-220, HollowLayout.HEART_Y - 32), "ui_right", 12.0)
	await _walk_to(player, Vector2(HollowLayout.LADDER_RETURN_X, HollowLayout.LOWER_WORK_Y - 32), "ui_down")
	await _walk_to(player, HollowLayout.player_spawn_point(), "ui_right")
	if _failed:
		quit(1)
		return

	# Mid Heart + Mid-East via Home landing stairs.
	await _walk_to(player, Vector2(192, landing.z - 32), "ui_right")
	if _failed:
		quit(1)
		return
	await _walk_to(player, Vector2(536, HollowLayout.HEART_Y - 32), "ui_right")
	await _walk_to(player, Vector2(944, HollowLayout.HEART_Y - 32), "ui_right")
	await _walk_to(player, Vector2(536, HollowLayout.HEART_Y - 32), "ui_left")
	await _walk_to(player, Vector2(200, landing.z - 32), "ui_left", 56.0)
	await _walk_to(player, HollowLayout.player_spawn_point(), "ui_left")
	if _failed:
		quit(1)
		return

	# Flat opening corridor to Gallery + side chamber.
	await _walk_to(player, Vector2(-112, HollowLayout.LOWER_WORK_Y - 32), "ui_left")
	await _walk_to(player, Vector2(-264, HollowLayout.LOWER_WORK_Y - 32), "ui_left")
	await _walk_to(player, Vector2(-960, HollowLayout.BOTTOM_WEST_Y - 32), "ui_left")
	Input.action_press("ui_left")
	for frame in range(120):
		await physics_frame
		if player.position.x <= HollowLayout.LADDER_CHAMBER_X + 16:
			break
	Input.action_release("ui_left")
	# Climb down the chamber shaft — airborne auto-grab at the gallery lip
	# is intentional, so free-fall alone no longer drops into the alcove.
	Input.action_press("ui_down")
	var entered_chamber := false
	for frame in range(180):
		await physics_frame
		if (
			player.is_on_floor()
			and absf(player.position.y - (HollowLayout.CHAMBER_ALCOVE_Y - 32)) <= 2.0
		):
			entered_chamber = true
			break
	Input.action_release("ui_down")
	for frame in range(16):
		await physics_frame
	if not entered_chamber:
		_failed = true
		push_error("FAIL side chamber cannot be entered safely: %s" % player.position)
	else:
		print("PASS entered side chamber")
	await _walk_to(player, Vector2(HollowLayout.LADDER_CHAMBER_X + 8, HollowLayout.CHAMBER_ALCOVE_Y - 32), "ui_right", 10.0)
	if _failed:
		quit(1)
		return
	Input.action_press("ui_up")
	var climbed := false
	for frame in range(240):
		await physics_frame
		if (
			absf(player.global_position.y - (HollowLayout.BOTTOM_WEST_Y - 32)) < 20.0
			and player.is_on_floor()
		):
			climbed = true
			break
	Input.action_release("ui_up")
	for frame in range(16):
		await physics_frame
	if not climbed:
		_failed = true
		push_error("FAIL climbing out of side chamber stopped at %s" % player.global_position)
	else:
		print("PASS climbed out of side chamber to Gallery")
	if _failed:
		quit(1)
		return
	await _walk_to(player, HollowLayout.player_spawn_point(), "ui_right")
	await _walk_to(player, Vector2(192, landing.z - 32), "ui_right")
	var zones: Node = root.get_node("Zones")
	var camera: Camera2D = player.get_node("Camera2D")
	if not camera.zoom.is_equal_approx(Vector2.ONE):
		_failed = true
		push_error("FAIL camera changes the original zoom")
	if not zones.validate_seams().is_empty():
		_failed = true
		push_error("FAIL route seams are not reciprocal: %s" % [zones.validate_seams()])
	scene.queue_free()
	await process_frame
	quit(1 if _failed else 0)
