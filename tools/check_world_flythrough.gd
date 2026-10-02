extends SceneTree
## Manual diagnostic: teleports the camera across HollowLayout.safe_stand_points()
## (every named district) and saves a screenshot at each, zoomed out, so the
## world can be surveyed for stray backgrounds / holes / spacing issues without
## walking it by hand. Not a headless test — needs a real window.
## Run: godot --path . --windowed --script res://tools/check_world_flythrough.gd -- output=tmp/flythrough

var _output_dir := "res://tmp/flythrough"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This check needs a rendered window, not --headless")
		quit(1)
		return
	var arguments := OS.get_cmdline_user_args()
	for argument in arguments:
		if argument.begins_with("output="):
			_output_dir = argument.trim_prefix("output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.get_node("UI").hide()
	var player: CharacterBody2D = scene.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	camera.set_physics_process(false) ## camera_follow.gd's own _physics_process fights our forced positions/limits
	camera.position_smoothing_enabled = false
	camera.zoom = Vector2(0.45, 0.45)
	camera.limit_left = -100000
	camera.limit_right = 100000
	camera.limit_top = -100000
	camera.limit_bottom = 100000

	var points := HollowLayout.safe_stand_points()
	var index := 0
	for point in points:
		player.global_position = point
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
		camera.global_position = point
		camera.reset_physics_interpolation()
		for tick in range(6):
			await physics_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		rendered.save_png(_output_dir.path_join("point-%02d.png" % index))
		print("point-%02d.png world=%s" % [index, point])
		index += 1

	scene.queue_free()
	await process_frame
	quit(0)
