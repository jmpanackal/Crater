extends SceneTree
## Headless check: dig_in_direction removes the correct adjacent tile for all 4 cardinals.


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	# Run after TerrainLayer._ready has built the tileset.
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
	terrain.clear()

	var center := Vector2i(10, 10)
	var neighbors := {
		Vector2i.LEFT: center + Vector2i.LEFT,
		Vector2i.RIGHT: center + Vector2i.RIGHT,
		Vector2i.UP: center + Vector2i.UP,
		Vector2i.DOWN: center + Vector2i.DOWN,
	}

	var origin_world := terrain.to_global(terrain.map_to_local(center))
	var failed := false

	for dig_dir in neighbors.keys():
		for cell in neighbors.values():
			terrain.set_cell(cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)

		var ok := terrain.dig_in_direction(origin_world, dig_dir)
		var target: Vector2i = neighbors[dig_dir]
		if not ok or terrain.has_tile(target):
			push_error("FAIL dig %s — expected tile at %s removed" % [dig_dir, target])
			failed = true
			continue

		for other_dir in neighbors.keys():
			if other_dir == dig_dir:
				continue
			var other: Vector2i = neighbors[other_dir]
			if not terrain.has_tile(other):
				push_error("FAIL dig %s — wrongly removed %s tile at %s" % [dig_dir, other_dir, other])
				failed = true

		print("PASS dig ", dig_dir, " -> removed ", target)

	if failed:
		push_error("DIG_DIRECTION_TESTS_FAILED")
		quit(1)
	else:
		print("DIG_DIRECTION_TESTS_PASSED")
		quit(0)
