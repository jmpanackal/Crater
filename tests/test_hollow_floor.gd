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
	if painted < 30:
		push_error("FAIL painted %d terrace cells (expected expanded multi-deck span)" % painted)
		quit(1)
		return
	print("PASS FloorVisual painted %d terrace cells" % painted)

	var pit_l := int(HollowLayout.PIT_LEFT / 64)
	var pit_r := int(HollowLayout.PIT_RIGHT / 64)
	var wick_y := int(HollowLayout.WICK_Y / 64)
	var left_x := int(HollowLayout.HOLLOW_LEFT / 64)
	var mid_heart_x := int((HollowLayout.HEART_MID.x + HollowLayout.HEART_MID.y) * 0.5 / 64.0)
	if layer.get_cell_source_id(Vector2i(mid_heart_x, wick_y)) != 1:
		push_error("FAIL Mid Heart cell not using bridge source")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(0, wick_y)) != 0:
		push_error("FAIL wick terrace cell not using ledge source")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(left_x, wick_y)) != 0:
		push_error("FAIL carved Wick bay cell missing at HOLLOW_LEFT")
		quit(1)
		return
	print("PASS FloorVisual ledge/bridge source split")

	if absf(layer.position.y + HollowLayout.FLOOR_VISUAL_INSET) > 0.5:
		push_error(
			"FAIL FloorVisual Y inset expected %s got %s"
			% [-HollowLayout.FLOOR_VISUAL_INSET, layer.position.y]
		)
		quit(1)
		return
	# Collision tops must match tile lip after inset (especially spawn band).
	for deck_y in [HollowLayout.FARMS_Y, HollowLayout.WICK_Y, HollowLayout.LOWER_WORK_Y, HollowLayout.CISTERN_Y]:
		if absf(HollowLayout.floor_visual_lip_y(deck_y) - deck_y) > 0.01:
			push_error("FAIL footing lip mismatch at deck %s" % deck_y)
			quit(1)
			return
		if int(round(deck_y)) % HollowLayout.TILE != 0:
			push_error("FAIL deck %s not tile-aligned for FloorVisual" % deck_y)
			quit(1)
			return
	print("PASS FloorVisual aligned to deck tops (inset %s)" % HollowLayout.FLOOR_VISUAL_INSET)


	var farms_y := int(HollowLayout.FARMS_Y / 64)
	var cistern_y := int(HollowLayout.CISTERN_Y / 64)
	for x in range(pit_l, pit_r):
		if layer.get_cell_source_id(Vector2i(x, farms_y)) != -1:
			push_error("FAIL pit has Farms-level floor at x=%d" % x)
			quit(1)
			return
	# Lower freight span may paint cistern_y across the Mouth — that is intentional.
	# Farms band in the void must stay empty.
	print("PASS pit columns empty at Farms band")

	var lift_open := int(HollowLayout.LIFT_OPEN_X / 64)
	var cistern_open := int(HollowLayout.LADDER_CISTERN_OPEN_X / 64)
	var upper_open := int(HollowLayout.LADDER_UPPER_OPEN_X / 64)
	var upper_res_y := int(HollowLayout.UPPER_RES_Y / 64)
	var lower_y := int(HollowLayout.LOWER_WORK_Y / 64)
	if layer.get_cell_source_id(Vector2i(lift_open, farms_y)) != -1:
		push_error("FAIL lift shaft still has Farms floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(lift_open, wick_y)) != -1:
		push_error("FAIL lift shaft still has Wick floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(cistern_open, lower_y)) != -1:
		push_error("FAIL lower-work ladder opening still has floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(upper_open, upper_res_y)) != -1:
		push_error("FAIL upper residence ladder opening still has floor tile")
		quit(1)
		return
	if layer.get_cell_source_id(Vector2i(cistern_open, cistern_y)) != -1:
		# Landing under ladder should be solid on Cistern — opening only on upper deck.
		pass
	if layer.get_cell_source_id(Vector2i(cistern_open, cistern_y)) == -1:
		push_error("FAIL Cistern landing under ladder missing floor tile")
		quit(1)
		return
	print("PASS lift + ladder openings empty on upper decks")

	if scene.get_node_or_null("Hollow/Floor/FarmsDeckMid") == null \
			and scene.get_node_or_null("Hollow/Floor/WickLeftEast") == null:
		push_error("FAIL floor collision missing")
		quit(1)
		return
	print("PASS floor collision still present")
	print("HOLLOW_FLOOR_TESTS_PASSED")
	quit(0)
