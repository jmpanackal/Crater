extends SceneTree
## Manual diagnostic: renders main.tscn at the dev zoom steps (the whole map, a district-sized view)
## and at spawn, and saves screenshots so the Hollow's scale and rock shell can be judged by eye.
## Not a headless test: needs a real window.
## Run: godot --path . --windowed --resolution 1920x1080 --script res://tools/check_overview_render.gd -- output=tmp
## Add `at=x,y` to also shoot a normal-zoom frame with the player moved there (feet position).

var _output_dir := "res://tmp"


func _init() -> void:
	call_deferred("_run")


func _shoot(name: String) -> void:
	for tick in range(8):
		await physics_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_output_dir.path_join(name))
	print("Saved %s size=%s" % [name, img.get_size()])


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("This check needs a rendered window, not --headless")
		quit(1)
		return
	var at := Vector2.INF
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("output="):
			_output_dir = argument.trim_prefix("output=")
		elif argument.begins_with("at="):
			var parts := argument.trim_prefix("at=").split(",")
			at = Vector2(float(parts[0]), float(parts[1]))
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	var cam: Camera2D = player.get_node("Camera2D")
	if at != Vector2.INF:
		player.global_position = at - Vector2(0.0, 32.0)
		player.velocity = Vector2.ZERO
	await _shoot("view-normal.png")
	cam.set_dev_zoom(3)
	await _shoot("view-zoom-0.2.png")
	cam.set_dev_zoom(4)
	await _shoot("view-whole-map.png")
	scene.queue_free()
	await process_frame
	quit(0)
