extends SceneTree
## Dev probe (needs a real window): average frame time and draw calls at a spot, vsync off.
## Run: godot --path . --windowed --resolution 1600x900 --script res://tools/measure_frame.gd -- at=-80,6400


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("needs a window")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var at := Vector2(-80.0, 6400.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("at="):
			var p := a.trim_prefix("at=").split(",")
			at = Vector2(float(p[0]), float(p[1]))
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	player.global_position = at - Vector2(0.0, 32.0)
	for i in 60:
		await process_frame
	var t0 := Time.get_ticks_usec()
	var frames := 180
	for i in frames:
		await process_frame
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
	print("avg frame ms: %.2f (%.0f fps)" % [ms, 1000.0 / ms])
	print("draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("objects in frame: ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	print("primitives: ", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("process ms: %.2f physics ms: %.2f" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
	quit(0)
