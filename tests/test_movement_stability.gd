extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	if not ProjectSettings.get_setting("physics/common/physics_interpolation", false) or not player.is_physics_interpolated_and_enabled():
		push_error("FAIL player render poses are not interpolated between physics ticks")
		quit(1)
		return
	if ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", false):
		push_error("FAIL independent transform snapping reintroduces camera/player jitter")
		quit(1)
		return
	if camera.process_callback != Camera2D.CAMERA2D_PROCESS_PHYSICS or camera.is_processing() or not camera.is_physics_processing():
		push_error("FAIL camera follow and smoothing do not share the player's physics clock")
		quit(1)
		return
	for window_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window_size
		await process_frame
		if not camera.zoom.is_equal_approx(Vector2.ONE):
			push_error("FAIL resizing the window changes the original zoom")
			quit(1)
			return
	player.position = Vector2(-320, HollowLayout.WEST_LW_UPPER_Y - 32)
	player.reset_physics_interpolation()
	for frame in range(45):
		await physics_frame
	var airborne_frames := 0
	var max_scale_error := 0.0
	Input.action_press("ui_right")
	for frame in range(45):
		await physics_frame
		if not player.is_on_floor():
			airborne_frames += 1
		max_scale_error = maxf(max_scale_error, player.debug_feel_scale().distance_to(Vector2.ONE))
	Input.action_release("ui_right")
	print("Flat walking: airborne frames=%d, scale error=%f" % [airborne_frames, max_scale_error])
	if airborne_frames > 0 or max_scale_error > 0.001:
		push_error("FAIL flat walking repeatedly loses floor contact or squashes the sprite")
		quit(1)
		return
	print("PASS flat walking stays grounded with a stable sprite scale")
	player.position = HollowLayout.player_spawn_point()
	player.reset_physics_interpolation()
	player.velocity = Vector2.ZERO
	for frame in range(45):
		await physics_frame
	airborne_frames = 0
	max_scale_error = 0.0
	Input.action_press("ui_right")
	for frame in range(90):
		await physics_frame
		if not player.is_on_floor():
			airborne_frames += 1
		max_scale_error = maxf(max_scale_error, player.debug_feel_scale().distance_to(Vector2.ONE))
	Input.action_release("ui_right")
	print("Stair walking: airborne frames=%d, scale error=%f" % [airborne_frames, max_scale_error])
	if max_scale_error > 0.001:
		push_error("FAIL stair walking repeatedly squashes the sprite")
		quit(1)
		return
	scene.queue_free()
	await process_frame
	quit(0)
