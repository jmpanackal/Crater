extends SceneTree
## Dig-site tileset acceptance: flat-color placeholder tiles at 16px (the
## scale-corrected TILE_SIZE — see terrain.gd's own comment on why the real
## 64px SpriteFusion sheet isn't loaded until a 16px sheet is generated).


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var community: Node = root.get_node_or_null("Community")
	if community:
		community.set_paused(true)

	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame

	if terrain.tile_set == null:
		push_error("FAIL no tileset")
		quit(1)
		return
	if terrain.tile_set.tile_size != Vector2i(16, 16):
		push_error("FAIL tile_size %s (expected 16x16)" % terrain.tile_set.tile_size)
		quit(1)
		return

	var source: TileSetAtlasSource = terrain.tile_set.get_source(0) as TileSetAtlasSource
	if source == null or not source.has_tile(TerrainLayer.PLACEHOLDER_ATLAS):
		push_error("FAIL missing placeholder atlas tile")
		quit(1)
		return
	print("PASS 16px placeholder tileset built with the fallback atlas tile")

	# Dig still removes adjacent cells at 16px spacing.
	terrain.clear()
	var center := Vector2i(80, 80)
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		terrain.set_cell(center + d, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	var origin := terrain.to_global(terrain.map_to_local(center))
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not terrain.dig_in_direction(origin, d):
			push_error("FAIL dig %s" % d)
			quit(1)
			return
		if terrain.has_tile(center + d):
			push_error("FAIL tile still present after dig %s" % d)
			quit(1)
			return
	print("PASS dig removes 16px neighbors")

	# Scene terrain filled with real placeholder tiles (not empty), confined
	# to the authored envelope: no rock in the civic cavity and none in the pit.
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var layer: TerrainLayer = scene.get_node("Terrain")
	var found := false
	var hollow_bleed := false
	for x in range(TerrainLayer.WEST_DIG_START_X - 2, TerrainLayer.DIG_END_X + 2):
		for y in range(0, TerrainLayer.ENVELOPE_ROWS):
			if not layer.has_tile(Vector2i(x, y)):
				continue
			if not layer.is_within_dig_envelope(Vector2i(x, y)):
				hollow_bleed = true
			found = true
	if hollow_bleed:
		push_error("FAIL dig tiles outside the envelope (civic cavity, pit or past the shell)")
		quit(1)
		return
	if not found:
		push_error("FAIL dig site empty")
		quit(1)
		return
	for edge in [Vector2i(TerrainLayer.WEST_DIG_START_X, 50), Vector2i(TerrainLayer.DIG_END_X - 1, 50), Vector2i(0, 5), Vector2i(TerrainLayer.DIG_START_X + 40, TerrainLayer.ENVELOPE_ROWS - 1), Vector2i(TerrainLayer.WEST_DIG_START_X + 40, TerrainLayer.ENVELOPE_ROWS - 1)]:
		if not layer.has_tile(edge):
			push_error("FAIL the shell has a gap at %s" % edge)
			quit(1)
			return
	if layer.has_tile(Vector2i(0, 200)) or layer.has_tile(Vector2i(TerrainLayer.PIT_START_X + 20, TerrainLayer.ENVELOPE_ROWS - 1)):
		push_error("FAIL the civic cavity or the pit has rock in it")
		quit(1)
		return
	print("PASS the shell is rock on every side (Firmament, both flanks, floor slab) and the cavity and pit are open")

	print("DIG_SITE_TILES_TESTS_PASSED")
	quit(0)
