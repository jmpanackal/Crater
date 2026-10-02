extends SceneTree
## Dev probe: how long main.tscn takes to build and how heavy the dig envelope is.
## Run: godot --headless --path . --script res://tools/measure_load.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var t1 := Time.get_ticks_msec()
	var terrain: TileMapLayer = scene.get_node("Terrain") as TileMapLayer
	print("build ms: ", t1 - t0)
	print("dig cells: ", terrain.get_used_cells().size())
	print("static mem MB: ", OS.get_static_memory_usage() / 1048576.0)
	var ts := Time.get_ticks_msec()
	var state: Dictionary = terrain.save_state()
	print("save_state ms: ", Time.get_ticks_msec() - ts, " dug entries: ", (state["dug_cells"] as Array).size())
	quit(0)
