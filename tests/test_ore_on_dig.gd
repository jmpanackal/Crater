extends SceneTree
## Headless check: successful digs grant Ore through Resources (+1 each).


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	if wallet == null:
		push_error("FAIL Resources autoload missing at /root/Resources")
		quit(1)
		return

	wallet.set_amount(wallet.ORE, 0)
	terrain.clear()

	var center := Vector2i(10, 10)
	var targets := [
		center + Vector2i.LEFT,
		center + Vector2i.RIGHT,
		center + Vector2i.DOWN,
	]
	for cell in targets:
		terrain.set_cell(cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)

	var origin_world := terrain.to_global(terrain.map_to_local(center))
	var digs := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
	var expected := 0
	var per_tile: int = wallet.ORE_PER_TILE

	for dig_dir in digs:
		var before: int = wallet.get_amount(wallet.ORE)
		var ok := terrain.dig_in_direction(origin_world, dig_dir)
		if not ok:
			push_error("FAIL dig %s did not destroy a tile" % dig_dir)
			quit(1)
			return
		expected += per_tile
		var after: int = wallet.get_amount(wallet.ORE)
		if after != before + per_tile:
			push_error("FAIL ore did not increase by %d (before=%d after=%d)" % [per_tile, before, after])
			quit(1)
			return
		print("PASS dig ", dig_dir, " ore ", before, " -> ", after)

	if wallet.get_amount(wallet.ORE) != expected:
		push_error("FAIL final ore=%d expected=%d" % [wallet.get_amount(wallet.ORE), expected])
		quit(1)
		return

	# Empty dig should not grant ore.
	var stuck: int = wallet.get_amount(wallet.ORE)
	var empty_ok := terrain.dig_in_direction(origin_world, Vector2i.UP)
	if empty_ok or wallet.get_amount(wallet.ORE) != stuck:
		push_error("FAIL empty dig should not grant ore")
		quit(1)
		return

	print("ORE_DIG_TESTS_PASSED final_ore=", wallet.get_amount(wallet.ORE))
	quit(0)
