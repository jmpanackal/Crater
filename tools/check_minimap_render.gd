extends SceneTree
## Manual diagnostic: renders main.tscn and saves a screenshot so the
## HollowMinimap overlay (and optionally the MacroBackground planning guides)
## can be inspected visually. Not a headless test — needs a real window.
## Run: godot --path . --windowed --script res://tools/check_minimap_render.gd -- output=tmp

var _output_dir := "res://tmp"


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
	var show_guides := arguments.has("guides")
	root.size = Vector2i(1280, 720)
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	if show_guides:
		var macro: Node2D = scene.get_node("Hollow/MacroBackground")
		macro.show_guides_in_game = true
	for tick in range(20):
		await physics_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	var name := "minimap-guides.png" if show_guides else "minimap-play.png"
	rendered.save_png(_output_dir.path_join(name))
	print("Saved %s size=%s" % [name, rendered.get_size()])
	if not show_guides:
		var minimap: Control = scene.get_node("UI/HollowMinimap")
		var panel_rect := Rect2i(minimap.global_position, minimap.size)
		var closeup := rendered.get_region(panel_rect.grow(20))
		closeup.save_png(_output_dir.path_join("minimap-closeup.png"))
		print("Saved minimap-closeup.png size=%s at %s" % [closeup.get_size(), panel_rect])
	scene.queue_free()
	await process_frame
	quit(0)
