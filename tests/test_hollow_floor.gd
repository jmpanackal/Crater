extends SceneTree
## Smoke: Hollow floor tileset paints terrace spans; collision remains.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_tex: Texture2D = load("res://sprites/hollow_floor/hollow_floor_tiles_64.png")
	if floor_tex == null:
		push_error("FAIL hollow_floor_tiles_64.png missing")
		quit(1)
		return
	if floor_tex.get_width() != 256 or floor_tex.get_height() != 256:
		push_error("FAIL unexpected floor atlas size %dx%d" % [floor_tex.get_width(), floor_tex.get_height()])
		quit(1)
		return
	print("PASS hollow floor 64 atlas 256x256")

	for path in [
		"res://sprites/hollow_bridge/hollow_bridge_tiles_64.png",
		"res://sprites/hollow_ledge/hollow_ledge_tiles_64.png",
	]:
		var tex: Texture2D = load(path)
		if tex == null:
			push_error("FAIL missing %s" % path)
			quit(1)
			return
		if tex.get_width() != 256 or tex.get_height() != 256:
			push_error("FAIL unexpected atlas size for %s: %dx%d" % [path, tex.get_width(), tex.get_height()])
			quit(1)
			return
	print("PASS hollow_bridge + hollow_ledge 64 atlases")

	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var visual: Node = scene.get_node_or_null("Hollow/FloorVisual")
	if visual == null:
		push_error("FAIL Hollow/FloorVisual missing")
		quit(1)
		return
	if not (visual is TileMapLayer):
		push_error("FAIL FloorVisual is %s" % visual.get_class())
		quit(1)
		return
	var layer := visual as TileMapLayer
	if layer.tile_set == null:
		push_error("FAIL FloorVisual has no TileSet")
		quit(1)
		return
	if layer.tile_set.get_source_count() < 2:
		push_error("FAIL FloorVisual expected ledge+bridge sources, got %d" % layer.tile_set.get_source_count())
		quit(1)
		return

	var painted := 0
	if layer.has_method("painted_cell_count"):
		painted = int(layer.call("painted_cell_count"))
	else:
		for cell in layer.get_used_cells():
			if layer.get_cell_source_id(cell) != -1:
				painted += 1
	if painted < 20:
		push_error("FAIL painted %d terrace cells (expected multi-deck span)" % painted)
		quit(1)
		return
	print("PASS FloorVisual painted %d terrace cells" % painted)

	# Mid-bridge cells must use bridge source (1); terrace lip uses ledge (0).
	var pit_l := int(HollowLayout.PIT_LEFT / 64)
	var pit_r := int(HollowLayout.PIT_RIGHT / 64)
	var wick_y := int(HollowLayout.WICK_Y / 64)
	var mid_x := int((pit_l + pit_r) * 0.5)
	if layer.get_cell_source_id(Vector2i(mid_x, wick_y)) != 1:
		push_error("FAIL mid-bridge cell not using bridge source")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(0, wick_y)) != 0:
		push_error("FAIL wick terrace cell not using ledge source")
		quit(1)
		return
	print("PASS FloorVisual ledge/bridge source split")

	# Ledge atlas art is inset TILE/2; layer must shift up so rock meets deck collision tops.
	if absf(layer.position.y + HollowLayout.FLOOR_VISUAL_INSET) > 0.5:
		push_error(
			"FAIL FloorVisual Y inset expected %s got %s"
			% [-HollowLayout.FLOOR_VISUAL_INSET, layer.position.y]
		)
		quit(1)
		return
	if absf(HollowLayout.FLOOR_VISUAL_INSET - 32.0) > 0.01:
		push_error("FAIL FLOOR_VISUAL_INSET changed unexpectedly: %s" % HollowLayout.FLOOR_VISUAL_INSET)
		quit(1)
		return
	print("PASS FloorVisual aligned to deck tops (inset %s)" % HollowLayout.FLOOR_VISUAL_INSET)

	# Pit columns must not be a solid ground fill below the bridge row.
	var farms_y := int(HollowLayout.FARMS_Y / 64)
	var cistern_y := int(HollowLayout.CISTERN_Y / 64)
	for x in range(pit_l, pit_r):
		if layer.get_cell_source_id(Vector2i(x, farms_y)) != -1:
			push_error("FAIL pit has Farms-level floor at x=%d" % x)
			quit(1)
			return
		if layer.get_cell_source_id(Vector2i(x, cistern_y)) != -1:
			push_error("FAIL pit has Cistern-level floor at x=%d" % x)
			quit(1)
			return
	print("PASS pit columns empty at Farms/Cistern bands")

	# Upper-deck ladder openings empty; lower landings stay painted under the shaft.
	var farms_open := int(HollowLayout.LADDER_FARMS_OPEN_X / 64)
	var cistern_open := int(HollowLayout.LADDER_CISTERN_OPEN_X / 64)
	if layer.get_cell_source_id(Vector2i(farms_open, farms_y)) != -1:
		push_error("FAIL Farms ladder opening still has floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(farms_open, wick_y)) == -1:
		push_error("FAIL Wick landing under Farms ladder missing floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(cistern_open, wick_y)) != -1:
		push_error("FAIL Wick/Cistern ladder opening still has floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(cistern_open, cistern_y)) == -1:
		push_error("FAIL Cistern landing under ladder missing floor tile")
		quit(1)
		return
	print("PASS ladder openings empty of FloorVisual tiles")

	if scene.get_node_or_null("Hollow/Floor/CollisionShape2D") == null:
		push_error("FAIL floor collision missing")
		quit(1)
		return
	print("PASS floor collision still present")
	print("HOLLOW_FLOOR_TESTS_PASSED")
	quit(0)
