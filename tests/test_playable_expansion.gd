extends SceneTree
## Playable expansion: uniform west stack + Mid Heart + east stack.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var terrain: TileMapLayer = scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var tile := 16.0

	if HollowLayout.SWITCHBACK_FLOOR.z != HollowLayout.WEST_LW_UPPER_Y:
		push_error("FAIL Switchback must sit on Lower Worker upper")
		quit(1)
		return
	if HollowLayout.WEST_DISPATCH_YARD.z != HollowLayout.WEST_LW_UPPER_Y:
		push_error("FAIL West Dispatch must sit on Lower Worker upper")
		quit(1)
		return
	print("PASS opening corridor Switchback/Dispatch sit on Lower Worker")

	for rect in HollowLayout.expansion_deck_rects():
		var mid_x := int(round((rect.x + rect.y) * 0.5 / tile))
		var open0 := int(round(HollowLayout.LADDER_WEST_OPEN_X / tile))
		var open1 := int(round(HollowLayout.ladder_west_open_end() / tile))
		if mid_x >= open0 and mid_x < open1:
			mid_x = open1 + 2
		var y := int(round(rect.z / tile))
		if terrain.get_cell_source_id(Vector2i(mid_x, y)) == -1:
			push_error("FAIL expansion deck %s is not painted" % [rect])
			quit(1)
			return
	print("PASS west stack / Mid Heart / Mid-East / east stack decks are painted")

	if HollowLayout.expansion_stair_rects().size() != 0:
		push_error("FAIL expansion stairs should be empty (west stack uses LadderWestStack)")
		quit(1)
		return
	if not scene.has_node("Hollow/LadderWestStack"):
		push_error("FAIL LadderWestStack missing from main.tscn")
		quit(1)
		return
	var west_ladder: Node = scene.get_node("Hollow/LadderWestStack")
	if absf(float(west_ladder.position.x) - HollowLayout.LADDER_WEST_X) > 1.0:
		push_error("FAIL LadderWestStack X drifted from layout")
		quit(1)
		return
	if absf(float(west_ladder.position.y) - HollowLayout.WEST_ASHRAM_UPPER_Y) > 1.0:
		push_error("FAIL LadderWestStack top is not at Ashram upper")
		quit(1)
		return
	print("PASS LadderWestStack wired for uniform west stack")

	var wick_pad := Vector2i(int(round(-1600.0 / tile)), int(round(HollowLayout.HEART_Y / tile)))
	var heart_pad := Vector2i(int(round(HollowLayout.HEART_MID_X / tile)), int(round(HollowLayout.HEART_Y / tile)))
	if terrain.get_cell_source_id(wick_pad) == -1 or terrain.get_cell_source_id(heart_pad) == -1:
		push_error("FAIL Wickwork / Mid Heart must be continuous at Heart height")
		quit(1)
		return
	print("PASS Wickwork meets Mid Heart at Mouth west lip")

	var zones: Node = root.get_node("Zones")
	if zones.get_zone_at(Vector2(-1520, HollowLayout.MID_ALLOT_Y)) != "worker_return_ascent" \
			and zones.get_zone_at(Vector2(-1520, HollowLayout.MID_ALLOT_Y)) != "mid_allotments":
		# Worker return covers the lower mid-allot band; mid_allotments covers upper.
		pass
	if zones.get_zone_at(Vector2(-2160, HollowLayout.WICK_Y)) != "wickwork":
		push_error("FAIL wickwork does not cover the west terrace")
		quit(1)
		return
	if zones.get_zone_at(Vector2(-1000, HollowLayout.MID_ALLOT_Y)) != "mid_allotments":
		push_error("FAIL mid_allotments does not cover the allotment street")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.HEART_MID_X, HollowLayout.HEART_Y)) != "mid_heart":
		push_error("FAIL mid_heart does not cover the Heart decks")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.PIT_RIGHT + 400.0, HollowLayout.HEART_Y)) != "mid_east_landing":
		push_error("FAIL mid_east_landing does not cover the east landing")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.MID_EAST_APPROACH.x + 320.0, HollowLayout.HEART_Y)) != "mid_east_approach":
		push_error("FAIL mid_east_approach does not cover the east approach")
		quit(1)
		return
	if zones.get_zone_at(Vector2((HollowLayout.MID_EAST_DIG_FRONT.x + HollowLayout.MID_EAST_DIG_FRONT.y) * 0.5, HollowLayout.HEART_Y)) != "mid_east_dig_front":
		push_error("FAIL mid_east_dig_front does not cover the dig terrace")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.PIT_RIGHT + 240.0, HollowLayout.UPPER_RES_Y)) != "ashram_east":
		push_error("FAIL ashram_east does not cover the east Ashram terrace")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.PIT_RIGHT + 240.0, HollowLayout.FARMS_Y)) != "glowbeds":
		push_error("FAIL glowbeds does not cover the east Glowbeds terrace")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.LADDER_EAST_OPEN_X + 480.0, HollowLayout.GLOW_SUB_Y)) != "glowbeds_hang":
		push_error("FAIL glowbeds_hang does not cover the hang deck")
		quit(1)
		return
	if zones.get_zone_at(Vector2(HollowLayout.PIT_RIGHT + 240.0, HollowLayout.LOWER_WORK_Y)) != "lower_east_services":
		push_error("FAIL lower_east_services does not cover Lower-East")
		quit(1)
		return
	if zones.get_zone_at(Vector2((HollowLayout.CISTERN_CHAMBER.x + HollowLayout.CISTERN_CHAMBER.y) * 0.5, HollowLayout.CISTERN_Y)) != "cistern":
		push_error("FAIL cistern does not cover the Cistern chamber")
		quit(1)
		return
	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL expansion seams invalid: %s" % [problems])
		quit(1)
		return
	print("PASS expansion zones cover west stack + east stack")

	if not scene.has_node("Hollow/LadderEastStack"):
		push_error("FAIL LadderEastStack missing from main.tscn")
		quit(1)
		return
	if scene.has_node("Hollow/LadderWorkerReturn") or scene.has_node("Hollow/LadderHomeToHeart"):
		push_error("FAIL redundant west ladders must be removed")
		quit(1)
		return
	var climb_count := 0
	for child in scene.get_node("Hollow").get_children():
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("hollow_climb.gd"):
			climb_count += 1
	if climb_count != 3:
		push_error("FAIL expected Chamber + WestStack + EastStack, got %s climb zones" % climb_count)
		quit(1)
		return
	var ladder: Area2D = scene.get_node("Hollow/LadderWestStack") as Area2D
	if absf(ladder.deck_top_y() - HollowLayout.WEST_ASHRAM_UPPER_Y) > 1.0:
		push_error("FAIL west stack ladder top is not Ashram upper")
		quit(1)
		return
	if absf(ladder.deck_bottom_y() - HollowLayout.BOTTOM_WEST_LOWER_Y) > 1.0:
		push_error("FAIL west stack ladder bottom is not Bottom-West lower")
		quit(1)
		return
	print("PASS LadderWestStack spans Ashram → Bottom-West")

	var east: Area2D = scene.get_node("Hollow/LadderEastStack") as Area2D
	if absf(east.deck_top_y() - HollowLayout.UPPER_RES_Y) > 1.0:
		push_error("FAIL east stack ladder top is not at Ashram height")
		quit(1)
		return
	if absf(east.deck_bottom_y() - HollowLayout.CISTERN_Y) > 1.0:
		push_error("FAIL east stack ladder bottom is not at Cistern height")
		quit(1)
		return
	print("PASS single east ladder spans Ashram to Cistern")

	var open0 := HollowLayout.LADDER_WEST_OPEN_X
	var heart_row := int(round(HollowLayout.HEART_Y / tile))
	var mid_row := int(round(HollowLayout.MID_ALLOT_Y / tile))
	for x_px in [open0 + 16.0, open0 + 48.0]:
		var col := int(round(x_px / tile))
		if terrain.get_cell_source_id(Vector2i(col, heart_row)) != -1:
			push_error("FAIL Heart deck still covers west shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, mid_row)) != -1:
			push_error("FAIL Mid Allotments still covers the west shaft at x=%s" % x_px)
			quit(1)
			return
	print("PASS west shaft opens Heart + Mid decks")

	var east_open := HollowLayout.LADDER_EAST_OPEN_X
	var ashram_row := int(round(HollowLayout.UPPER_RES_Y / tile))
	var farms_row := int(round(HollowLayout.FARMS_Y / tile))
	var hang_row := int(round(HollowLayout.GLOW_SUB_Y / tile))
	var lower_row := int(round(HollowLayout.LOWER_WORK_Y / tile))
	var cistern_row := int(round(HollowLayout.CISTERN_Y / tile))
	for x_px in [east_open + 16.0, east_open + 48.0]:
		var col := int(round(x_px / tile))
		if terrain.get_cell_source_id(Vector2i(col, ashram_row)) != -1:
			push_error("FAIL Ashram still covers east shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, farms_row)) != -1:
			push_error("FAIL Glowbeds still covers east shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, hang_row)) != -1:
			push_error("FAIL Glowbeds hang still covers east shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, heart_row)) != -1:
			push_error("FAIL Mid-East still covers east shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, lower_row)) != -1:
			push_error("FAIL Lower-East still covers east shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, cistern_row)) == -1:
			push_error("FAIL Cistern approach must stay solid under east shaft at x=%s" % x_px)
			quit(1)
			return
	print("PASS east shaft gaps; Dig Front / hang / Ashram / Cistern chamber painted")

	if not HollowLayout.mid_heart_spans_mouth():
		push_error("FAIL Mid Heart decks must span Mouth west lip → east lip")
		quit(1)
		return
	var mouth_w := HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT
	if absf(mouth_w - 3520.0) > 0.5:
		push_error("FAIL Mouth width must be 3520 (1440..4960), got %s" % mouth_w)
		quit(1)
		return
	print("PASS Mid Heart spans Mouth; Mouth width locked at 3520")

	var dig: TileMapLayer = scene.get_node("Terrain") as TileMapLayer
	var west_dig := Vector2i(
		int(round((HollowLayout.HIGH_WEST_DIG_LEFT + 320.0) / tile)),
		int(round((HollowLayout.WEST_HIGH_UPPER_Y - 160.0) / tile))
	)
	if dig.get_cell_source_id(west_dig) == -1:
		push_error("FAIL High-West Dig Front must have diggable rock outside Mouth")
		quit(1)
		return
	var bottom_dig := Vector2i(
		int(round((HollowLayout.HIGH_WEST_DIG_LEFT + 320.0) / tile)),
		int(round((HollowLayout.BOTTOM_WEST_UPPER_Y - 160.0) / tile))
	)
	if dig.get_cell_source_id(bottom_dig) == -1:
		push_error("FAIL Bottom-West Dig Front must have diggable rock outside Mouth")
		quit(1)
		return
	print("PASS dig flanks exist at High-West + Bottom-West")

	print("PLAYABLE_EXPANSION_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
