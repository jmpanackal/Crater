extends SceneTree
## Dig-site sheet is SpriteFusion veins upscaled to 64px (4x3 atlas); dig still works.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var tex: Texture2D = load("res://sprites/dig_site_tiles.png")
	if tex == null:
		push_error("FAIL dig_site_tiles.png missing")
		quit(1)
		return
	if tex.get_width() != 256 or tex.get_height() != 192:
		push_error("FAIL sheet size %dx%d (expected 256x192)" % [tex.get_width(), tex.get_height()])
		quit(1)
		return
	if tex.get_width() % 64 != 0 or tex.get_height() % 64 != 0:
		push_error("FAIL sheet not divisible by 64")
		quit(1)
		return
	print("PASS sheet 256x192 / 64 cell (12 SpriteFusion tiles)")

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
	if terrain.tile_set.tile_size != Vector2i(64, 64):
		push_error("FAIL tile_size %s" % terrain.tile_set.tile_size)
		quit(1)
		return

	var source: TileSetAtlasSource = terrain.tile_set.get_source(0) as TileSetAtlasSource
	if source == null:
		push_error("FAIL no atlas source")
		quit(1)
		return
	var expected := 0
	for y in range(3):
		for x in range(4):
			var coord := Vector2i(x, y)
			if not source.has_tile(coord):
				push_error("FAIL missing atlas tile %s" % coord)
				quit(1)
				return
			expected += 1
	print("PASS all %d atlas tiles exist" % expected)

	# Dig still removes adjacent cells at 64px spacing.
	terrain.clear()
	var center := Vector2i(8, 8)
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
	print("PASS dig removes 64px neighbors")

	# Scene terrain filled with real atlas variants (not empty).
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var layer: TerrainLayer = scene.get_node("Terrain")
	var found := false
	var hollow_bleed := false
	for x in range(0, TerrainLayer.DIG_END_X + 2):
		for y in range(0, 16):
			if not layer.has_tile(Vector2i(x, y)):
				continue
			if x < TerrainLayer.DIG_START_X:
				hollow_bleed = true
			found = true
			var atlas: Vector2i = layer.get_cell_atlas_coords(Vector2i(x, y))
			if atlas.x < 0 or atlas.y < 0 or atlas.x > 3 or atlas.y > 2:
				push_error("FAIL unexpected atlas %s" % atlas)
				quit(1)
				return
	if hollow_bleed:
		push_error("FAIL dig tiles bleed into Hollow/approach (x < %d)" % TerrainLayer.DIG_START_X)
		quit(1)
		return
	if not found:
		push_error("FAIL dig site empty")
		quit(1)
		return
	print("PASS dig site filled past chasm (x>=%d), no Hollow bleed" % TerrainLayer.DIG_START_X)

	print("DIG_SITE_TILES_TESTS_PASSED")
	quit(0)
