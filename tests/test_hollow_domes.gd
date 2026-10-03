extends SceneTree
## Domes (HollowMap.domes()) are carved air in the civic rock: open across every band up to its height and
## solid rock one tile above it.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var terrain := scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var bands := 0
	for dome in HollowMap.domes():
		var tallest := 0.0
		for b in HollowMap.dome_blocks(dome):
			var cx := int((b.position.x + b.size.x * 0.5) / 16.0)
			var top_row := int(b.position.y / 16.0)
			if terrain.get_cell_source_id(Vector2i(cx, top_row)) != -1:
				_fail("%s: dome air at (%d, %d) is still rock" % [dome["id"], cx, top_row])
				return
			# a dome under the Firmament rises into the diggable shell, any other into the civic rock
			var above := Vector2i(cx, top_row - 1)
			var has_rock: bool = terrain.get_cell_source_id(above) != -1 or (scene.get_node("Terrain") as TileMapLayer).get_cell_source_id(above) != -1
			if not has_rock:
				_fail("%s: no rock over the dome at (%d, %d)" % [dome["id"], cx, top_row - 1])
				return
			tallest = maxf(tallest, b.size.y)
			bands += 1
		if not is_equal_approx(tallest, float(dome["height"])):
			_fail("%s: tallest band %s, declared %s" % [dome["id"], tallest, dome["height"]])
			return
	print("PASS %d dome bands carved into the Firmament with rock over them" % bands)
	quit(0)
