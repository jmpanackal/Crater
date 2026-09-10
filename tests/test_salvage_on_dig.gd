extends SceneTree
## Dig still grants Salvage; empty dig grants nothing.


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	if wallet == null:
		push_error("FAIL Resources missing")
		quit(1)
		return

	if upgrades:
		upgrades.set_level(upgrades.DIG_YIELD, 0)
		upgrades.set_siphon_station_open(false)

	wallet.set_amount(wallet.SALVAGE, 0)
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
	var per_tile: int = 1
	if upgrades:
		per_tile = upgrades.get_dig_salvage_yield()

	for dig_dir in digs:
		var before: int = wallet.get_amount(wallet.SALVAGE)
		var ok := terrain.dig_in_direction(origin_world, dig_dir)
		if not ok:
			push_error("FAIL dig %s" % dig_dir)
			quit(1)
			return
		expected += per_tile
		var after: int = wallet.get_amount(wallet.SALVAGE)
		if after != before + per_tile:
			push_error("FAIL salvage %d -> %d" % [before, after])
			quit(1)
			return
		print("PASS dig ", dig_dir, " salvage ", before, " -> ", after)

	var stuck: int = wallet.get_amount(wallet.SALVAGE)
	if terrain.dig_in_direction(origin_world, Vector2i.UP) or wallet.get_amount(wallet.SALVAGE) != stuck:
		push_error("FAIL empty dig granted salvage")
		quit(1)
		return

	print("SALVAGE_DIG_TESTS_PASSED final=", wallet.get_amount(wallet.SALVAGE))
	quit(0)
