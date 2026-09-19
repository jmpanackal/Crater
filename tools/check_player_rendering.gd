extends SceneTree

var _output_dir := "user://"


func _init() -> void:
	call_deferred("_run")


func _body_center(frame: Image, player: Node2D) -> float:
	var expected := (root.get_final_transform() * player.get_global_transform_with_canvas()) * Vector2(16, 16)
	var left := maxi(0, int(expected.x) - 40)
	var right := mini(frame.get_width(), int(expected.x) + 40)
	var top := maxi(0, int(expected.y) - 32)
	var bottom := mini(frame.get_height(), int(expected.y) + 32)
	var total := 0.0
	var count := 0
	for pixel_y in range(top, bottom):
		for pixel_x in range(left, right):
			var color := frame.get_pixel(pixel_x, pixel_y)
			if color.r > 0.58 and color.r < 0.68 and color.g > 0.43 and color.g < 0.55 and color.b > 0.28 and color.b < 0.39:
				total += pixel_x
				count += 1
	return total / count if count > 0 else NAN


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This check needs a rendered window, not --headless")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	for argument in arguments:
		if argument.begins_with("output="):
			_output_dir = argument.trim_prefix("output=")
	var baseline := arguments.has("baseline")
	root.size = Vector2i(1280, 720)
	for argument in arguments:
		if argument.begins_with("size="):
			var dimensions := argument.trim_prefix("size=").split("x")
			root.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	root.snap_2d_transforms_to_pixel = baseline
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("UI").hide()
	var player: CharacterBody2D = scene.get_node("Player")
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF if baseline else Node.PHYSICS_INTERPOLATION_MODE_ON
	var terrain: TileMapLayer = scene.get_node("Hollow/HollowTerrain")
	terrain.paint_floor(-1000, 1000, 96)
	player.position = Vector2(-500, 64)
	player.reset_physics_interpolation()
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()
	for tick in range(30):
		await physics_frame
	var reports: Array[Dictionary] = []
	for direction in ["ui_right", "ui_left"]:
		Input.action_press(direction)
		for tick in range(120):
			await physics_frame
		var previous := NAN
		var last_sign := 0
		var reversals := 0
		var missing := 0
		var positions: Array[float] = []
		for frame in range(120):
			await RenderingServer.frame_post_draw
			var rendered := root.get_texture().get_image()
			if frame == 0:
				rendered.save_png(_output_dir.path_join("render-%s-%s.png" % ["baseline" if baseline else "fixed", direction]))
				print("Raster size=%s player canvas=%s" % [rendered.get_size(), player.get_global_transform_with_canvas().origin])
			var center := _body_center(rendered, player)
			if is_nan(center):
				missing += 1
				continue
			positions.append(center)
			if not is_nan(previous) and absf(center - previous) > 0.05:
				var movement_sign := int(signf(center - previous))
				if last_sign != 0 and last_sign != movement_sign:
					reversals += 1
				last_sign = movement_sign
			previous = center
		Input.action_release(direction)
		reports.append({"direction": direction, "raster_reversals": reversals, "missing_frames": missing, "pixel_centers": positions})
	var mode := "baseline" if baseline else "fixed"
	var report := {"mode": mode, "render_limit": Engine.max_fps, "physics_tps": Engine.physics_ticks_per_second, "samples": reports}
	var output := FileAccess.open(_output_dir.path_join("player-render-%s-%d.json" % [mode, Engine.max_fps]), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	for sample in reports:
		print("%s %s: %d raster reversals, %d missing frames" % [mode, sample.direction, sample.raster_reversals, sample.missing_frames])
	scene.queue_free()
	await process_frame
	var missed := false
	for sample in reports:
		missed = missed or sample.missing_frames > 0
	quit(1 if missed else 0)
