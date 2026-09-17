extends SceneTree
## Smoke: Hollow floor tileset paints terrace spans; collision remains.
##
## Scale correction (2026-09-17): hollow_floor/hollow_bridge/hollow_ledge
## dropped their real PixelLab sheets for flat-color placeholders on a 16px
## grid (was 64px) — see each file's own comment. RENDER_TILE below mirrors
## their TILE_SIZE for converting HollowLayout's fixed world-pixel
## constants into the cell coordinates this test expects.
const RENDER_TILE := 16


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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
	if layer.tile_set.tile_size != Vector2i(RENDER_TILE, RENDER_TILE):
		push_error("FAIL FloorVisual tile_size %s (expected %dx%d)" % [layer.tile_set.tile_size, RENDER_TILE, RENDER_TILE])
		quit(1)
		return
	if layer.tile_set.get_source_count() < 2:
		push_error("FAIL FloorVisual expected ledge+bridge sources, got %d" % layer.tile_set.get_source_count())
		quit(1)
		return
	print("PASS FloorVisual placeholder tileset (16px, ledge+bridge sources)")

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

	var pit_l := int(HollowLayout.PIT_LEFT / RENDER_TILE)
	var pit_r := int(HollowLayout.PIT_RIGHT / RENDER_TILE)
	var wick_y := int(HollowLayout.WICK_Y / RENDER_TILE)
	var left_x := int(HollowLayout.HOLLOW_LEFT / RENDER_TILE)
	var mid_heart_x := int((HollowLayout.HEART_MID.x + HollowLayout.HEART_MID.y) * 0.5 / float(RENDER_TILE))
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
	# HollowLayout.TILE (64) is the world-design alignment unit — unrelated
	# to FloorVisual's own render grid, and deliberately not touched by the
	# scale correction (see hollow_layout.gd's own header comment).
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


	var farms_y := int(HollowLayout.FARMS_Y / RENDER_TILE)
	var cistern_y := int(HollowLayout.CISTERN_Y / RENDER_TILE)
	for x in range(pit_l, pit_r):
		if layer.get_cell_source_id(Vector2i(x, farms_y)) != -1:
			push_error("FAIL pit has Farms-level floor at x=%d" % x)
			quit(1)
			return
	# Lower freight span may paint cistern_y across the Mouth — that is intentional.
	# Farms band in the void must stay empty.
	print("PASS pit columns empty at Farms band")

	var lift_open := int(HollowLayout.LIFT_OPEN_X / RENDER_TILE)
	var cistern_open := int(HollowLayout.LADDER_CISTERN_OPEN_X / RENDER_TILE)
	var upper_open := int(HollowLayout.LADDER_UPPER_OPEN_X / RENDER_TILE)
	var upper_res_y := int(HollowLayout.UPPER_RES_Y / RENDER_TILE)
	var lower_y := int(HollowLayout.LOWER_WORK_Y / RENDER_TILE)
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
