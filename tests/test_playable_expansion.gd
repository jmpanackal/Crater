extends SceneTree
## Playable expansion off the opening corridor: Worker Return, Wickwork terrace,
## Mid Allotments, Mid Heart decks, Mid-East Landing + Approach + Dig Front,
## Ashram / Glowbeds / Hang / Lower-East / Cistern chamber on the shared east shaft.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var terrain: TileMapLayer = scene.get_node("Hollow/HollowTerrain") as TileMapLayer
	var tile := 16.0

	# Opening corridor must stay flat — no Switchback dip / Dispatch podium clutter.
	if HollowLayout.SWITCHBACK_FLOOR.z != HollowLayout.LOWER_WORK_Y:
		push_error("FAIL Switchback must remain a flat lower-work corridor")
		quit(1)
		return
	if HollowLayout.WEST_DISPATCH_YARD.z != HollowLayout.LOWER_WORK_Y:
		push_error("FAIL West Dispatch must remain a flat apron")
		quit(1)
		return
	if HollowLayout.SWITCHBACK_LEFT != -800.0:
		push_error("FAIL Switchback west seam drifted from the clean corridor width")
		quit(1)
		return
	print("PASS opening corridor Switchback/Dispatch stay flat")

	for rect in HollowLayout.expansion_deck_rects():
		var mid_x := int(round((rect.x + rect.y) * 0.5 / tile))
		var y := int(round(rect.z / tile))
		if terrain.get_cell_source_id(Vector2i(mid_x, y)) == -1:
			push_error("FAIL expansion deck %s is not painted" % [rect])
			quit(1)
			return
	print("PASS worker return / Wickwork / allotments / Mid Heart / Mid-East / east stack decks are painted")

	if HollowLayout.expansion_stair_rects().size() != 0:
		push_error("FAIL expansion stairs should be empty (Home→Mid Heart uses LadderHomeToHeart)")
		quit(1)
		return
	if not scene.has_node("Hollow/LadderHomeToHeart"):
		push_error("FAIL LadderHomeToHeart missing from main.tscn")
		quit(1)
		return
	var home_heart: Node = scene.get_node("Hollow/LadderHomeToHeart")
	if absf(float(home_heart.position.x) - HollowLayout.LADDER_HOME_HEART_X) > 1.0:
		push_error("FAIL LadderHomeToHeart X drifted from layout")
		quit(1)
		return
	if absf(float(home_heart.position.y) - HollowLayout.HEART_Y) > 1.0:
		push_error("FAIL LadderHomeToHeart top is not at Mid Heart height")
		quit(1)
		return
	var approach_w := Vector2i(
		int(round((HollowLayout.HEART_APPROACH_WEST.x + HollowLayout.HEART_APPROACH_WEST.y) * 0.5 / tile)),
		int(round(HollowLayout.HEART_Y / tile))
	)
	var approach_e := Vector2i(
		int(round((HollowLayout.HEART_APPROACH_EAST.x + HollowLayout.HEART_APPROACH_EAST.y) * 0.5 / tile)),
		int(round(HollowLayout.HEART_Y / tile))
	)
	if terrain.get_cell_source_id(approach_w) == -1 or terrain.get_cell_source_id(approach_e) == -1:
		push_error("FAIL Mid Heart west approach pads are not painted")
		quit(1)
		return
	print("PASS Home landing ladder into Mid Heart approach is wired")

	# Lower corridor under the west spur must stay walkable.
	var underpass := Vector2i(int(round(-560.0 / tile)), int(round(HollowLayout.LOWER_WORK_Y / tile)))
	if terrain.get_cell_source_id(underpass) == -1:
		push_error("FAIL Switchback floor under the west spur was erased")
		quit(1)
		return
	# Spur is Heart-height floor paint only — must not fill stair mass into the corridor.
	var spur_column := Vector2i(int(round(-1500.0 / tile)), int(round((HollowLayout.LOWER_WORK_Y - 48.0) / tile)))
	if terrain.get_cell_source_id(spur_column) != -1:
		push_error("FAIL west spur must not drop solid fill into the opening corridor")
		quit(1)
		return
	print("PASS flat Switchback remains clear under the Heart-height spur")

	var zones: Node = root.get_node("Zones")
	if zones.get_zone_at(Vector2(-1520, HollowLayout.HEART_Y)) != "worker_return_ascent":
		push_error("FAIL worker_return_ascent does not cover the west spur")
		quit(1)
		return
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
	if not scene.has_node("Hollow/Zones/WorkerReturnAscent"):
		push_error("FAIL WorkerReturnAscent zone anchor missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/Wickwork") or not scene.has_node("Hollow/Zones/MidAllotments"):
		push_error("FAIL Wickwork / MidAllotments zone anchors missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/MidHeart") or not scene.has_node("Hollow/Zones/MidEastLanding"):
		push_error("FAIL Mid Heart / Mid-East zone anchors missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/MidEastApproach"):
		push_error("FAIL MidEastApproach zone anchor missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/MidEastDigFront"):
		push_error("FAIL MidEastDigFront zone anchor missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/AshramEast") or not scene.has_node("Hollow/Zones/GlowbedsHang"):
		push_error("FAIL AshramEast / GlowbedsHang zone anchors missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/Glowbeds") or not scene.has_node("Hollow/Zones/LowerEastServices"):
		push_error("FAIL Glowbeds / LowerEastServices zone anchors missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/Zones/Cistern"):
		push_error("FAIL Cistern zone anchor missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/LadderWorkerReturn"):
		push_error("FAIL LadderWorkerReturn missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/LadderHomeToHeart"):
		push_error("FAIL LadderHomeToHeart missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/LadderEastStack"):
		push_error("FAIL LadderEastStack missing from main.tscn")
		quit(1)
		return
	if not scene.has_node("Hollow/FreightLift"):
		push_error("FAIL FreightLift missing from main.tscn")
		quit(1)
		return
	if scene.has_node("Hollow/LadderMid"):
		push_error("FAIL redundant LadderMid must be removed — one west-spur shaft only")
		quit(1)
		return
	var climb_count := 0
	for child in scene.get_node("Hollow").get_children():
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("hollow_climb.gd"):
			climb_count += 1
	if climb_count != 4:
		push_error(
			"FAIL expected Chamber + WorkerReturn + HomeToHeart + EastStack, got %s climb zones"
			% climb_count
		)
		quit(1)
		return
	var ladder: Area2D = scene.get_node("Hollow/LadderWorkerReturn") as Area2D
	if absf(ladder.deck_top_y() - HollowLayout.HEART_Y) > 1.0:
		push_error("FAIL worker return ladder top is not at Mid Heart height")
		quit(1)
		return
	if absf(ladder.deck_bottom_y() - HollowLayout.LOWER_WORK_Y) > 1.0:
		push_error("FAIL worker return ladder bottom is not at lower-work height")
		quit(1)
		return
	print("PASS single Worker Return ladder spans Switchback to the west spur")

	var east: Area2D = scene.get_node("Hollow/LadderEastStack") as Area2D
	if absf(east.deck_top_y() - HollowLayout.UPPER_RES_Y) > 1.0:
		push_error("FAIL east stack ladder top is not at Ashram height")
		quit(1)
		return
	if absf(east.deck_bottom_y() - HollowLayout.CISTERN_Y) > 1.0:
		push_error("FAIL east stack ladder bottom is not at Cistern height")
		quit(1)
		return
	if absf(float(east.get("deck_open_x")) - HollowLayout.LADDER_EAST_OPEN_X) > 1.0:
		push_error("FAIL east stack deck_open_x drifted from LADDER_EAST_OPEN_X")
		quit(1)
		return
	print("PASS single east ladder spans Ashram to Cistern")

	# One shaft serves Mid Allotments too — floor gap at the same X, no second ladder.
	var open0 := HollowLayout.LADDER_RETURN_OPEN_X
	var heart_row := int(round(HollowLayout.HEART_Y / tile))
	var mid_row := int(round(HollowLayout.MID_ALLOT_Y / tile))
	for x_px in [open0 + 16.0, open0 + 48.0]:
		var col := int(round(x_px / tile))
		if terrain.get_cell_source_id(Vector2i(col, heart_row)) != -1:
			push_error("FAIL Heart deck still covers Worker Return shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, mid_row)) != -1:
			push_error("FAIL Mid Allotments still covers the shared shaft at x=%s" % x_px)
			quit(1)
			return
	# Spur east of the shaft must be continuous (no second Mid opening stub).
	var spur_east := Vector2i(int(round(-480.0 / tile)), heart_row)
	if terrain.get_cell_source_id(spur_east) == -1:
		push_error("FAIL west spur must continue east of the single shaft toward Home Court")
		quit(1)
		return
	var mid_west := Vector2i(int(round(-1280.0 / tile)), mid_row)
	var mid_east := Vector2i(int(round(-480.0 / tile)), mid_row)
	if terrain.get_cell_source_id(mid_west) == -1 or terrain.get_cell_source_id(mid_east) == -1:
		push_error("FAIL Mid Allotments must remain walkable on both sides of the shared shaft")
		quit(1)
		return
	print("PASS shared shaft opens Heart + Mid decks; no redundant Mid ladder")

	# East shaft opens Ashram / Glowbeds / Hang / Mid-East / Lower-East; Cistern lip stays solid.
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
	# Freight shaft opens Mid / Lower / Cistern; gap matches cage width.
	var freight_x0 := HollowLayout.FREIGHT_LIFT_X
	for x_px in [freight_x0 + 8.0, freight_x0 + 40.0]:
		var col := int(round(x_px / tile))
		if terrain.get_cell_source_id(Vector2i(col, heart_row)) != -1:
			push_error("FAIL Mid-East still covers freight shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, lower_row)) != -1:
			push_error("FAIL Lower-East still covers freight shaft at x=%s" % x_px)
			quit(1)
			return
		if terrain.get_cell_source_id(Vector2i(col, cistern_row)) != -1:
			push_error("FAIL Cistern still covers freight shaft at x=%s" % x_px)
			quit(1)
			return
	var freight: Node = scene.get_node("Hollow/FreightLift")
	if absf(float(freight.get("default_stop_index")) - 0.0) > 0.5:
		push_error("FAIL FreightLift must park at Mid by default so the civic walk stays bridged")
		quit(1)
		return
	var landing_pad := Vector2i(int(round((HollowLayout.PIT_RIGHT + 240.0) / tile)), heart_row)
	var approach_pad := Vector2i(int(round((HollowLayout.MID_EAST_APPROACH.x + 320.0) / tile)), heart_row)
	var dig_pad := Vector2i(int(round(((HollowLayout.MID_EAST_DIG_FRONT.x + HollowLayout.MID_EAST_DIG_FRONT.y) * 0.5) / tile)), heart_row)
	var dig_tip := Vector2i(int(round((HollowLayout.MID_EAST_DIG_FRONT.y - 160.0) / tile)), heart_row)
	var chamber_pad := Vector2i(int(round(((HollowLayout.CISTERN_CHAMBER.x + HollowLayout.CISTERN_CHAMBER.y) * 0.5) / tile)), cistern_row)
	var hang_pad := Vector2i(int(round((HollowLayout.LADDER_EAST_OPEN_X + 480.0) / tile)), hang_row)
	var ashram_pad := Vector2i(int(round((HollowLayout.PIT_RIGHT + 240.0) / tile)), ashram_row)
	if terrain.get_cell_source_id(landing_pad) == -1:
		push_error("FAIL Mid-East Landing must stay walkable west of the east shaft")
		quit(1)
		return
	if terrain.get_cell_source_id(approach_pad) == -1:
		push_error("FAIL Mid-East Approach must stay walkable east of the east shaft")
		quit(1)
		return
	if terrain.get_cell_source_id(dig_pad) == -1 or terrain.get_cell_source_id(dig_tip) == -1:
		push_error("FAIL Mid-East Dig Front must be walkable out to Dig Front tip")
		quit(1)
		return
	if terrain.get_cell_source_id(chamber_pad) == -1:
		push_error("FAIL Cistern chamber must be walkable past the approach lip")
		quit(1)
		return
	if terrain.get_cell_source_id(hang_pad) == -1:
		push_error("FAIL Glowbeds hang must be walkable east of the east shaft")
		quit(1)
		return
	if terrain.get_cell_source_id(ashram_pad) == -1:
		push_error("FAIL Ashram east must be walkable west of the east shaft")
		quit(1)
		return
	print("PASS east shaft + freight gaps; Dig Front / hang / Ashram / Cistern chamber painted")

	if absf(HollowLayout.civic_east_end() - HollowLayout.MID_EAST_APPROACH.y) > 0.5:
		push_error("FAIL civic_east_end must track Mid-East Approach tip")
		quit(1)
		return
	if absf(HollowLayout.civic_east_end() - HollowLayout.MID_EAST_DIG_FRONT.x) > 0.5:
		push_error("FAIL Dig Front must begin exactly at civic_east_end")
		quit(1)
		return
	if absf(HollowLayout.MID_EAST_DIG_FRONT.y - 11840.0) > 0.5:
		push_error("FAIL Dig Front east tip must reach x=11840")
		quit(1)
		return
	print("PASS civic east tip tracks Mid-East Approach; Dig Front starts after it")

	# Dig envelope starts at EXIT_RIGHT (world x=1280) and used to solid-fill
	# Mid-East decks + LadderEastStack. Civic walk corridors and the east shaft
	# must be carved open so dig rock does not seal the Mouth-side approach.
	var dig: TileMapLayer = scene.get_node("Terrain") as TileMapLayer
	var dig_start_px := float(TerrainLayer.DIG_START_X) * tile
	var approach_air := Vector2i(
		int(round((dig_start_px + 16.0) / tile)),
		int(round((HollowLayout.HEART_Y - 32.0) / tile))
	)
	if dig.get_cell_source_id(approach_air) != -1:
		push_error(
			"FAIL dig rock still plugs Mid-East approach air at %s (blocks LadderEastStack)"
			% approach_air
		)
		quit(1)
		return
	var landing_floor_under_dig := Vector2i(
		int(round((dig_start_px + 16.0) / tile)),
		heart_row
	)
	if dig.get_cell_source_id(landing_floor_under_dig) != -1:
		push_error(
			"FAIL dig rock still covers Mid-East Landing floor at %s"
			% landing_floor_under_dig
		)
		quit(1)
		return
	for x_px in [east_open + 16.0, east_open + 48.0]:
		var shaft_col := int(round(x_px / tile))
		for band_y in [
			HollowLayout.UPPER_RES_Y,
			HollowLayout.FARMS_Y,
			HollowLayout.GLOW_SUB_Y,
			HollowLayout.HEART_Y,
			HollowLayout.LOWER_WORK_Y,
			HollowLayout.CISTERN_Y,
		]:
			var shaft_cell := Vector2i(shaft_col, int(round(band_y / tile)))
			if dig.get_cell_source_id(shaft_cell) != -1:
				push_error(
					"FAIL dig rock still fills east ladder shaft at %s"
					% shaft_cell
				)
				quit(1)
				return
	# Thin diggable face may sit immediately above each walk clear — but the
	# inter-deck air (Hang↔Heart, Heart↔Lower) must stay open void. Prior bug:
	# solid teal dig fill between terraces read as aqua filler blocks east of
	# LadderEastStack ("Side galleries ahead").
	var civic_sample_x := int(round((dig_start_px + 48.0) / tile))
	# Explicit mid-gap samples (not average of deck tops — that can land in walk clear).
	var hang_heart_air := Vector2i(
		civic_sample_x,
		int(round((HollowLayout.HEART_Y - 800.0) / tile))
	)
	if dig.get_cell_source_id(hang_heart_air) != -1:
		push_error(
			"FAIL dig teal still fills Hang↔Heart void at %s (aqua filler blocks)"
			% hang_heart_air
		)
		quit(1)
		return
	var heart_lower_air := Vector2i(
		civic_sample_x,
		int(round((HollowLayout.HEART_Y + 720.0) / tile))
	)
	if dig.get_cell_source_id(heart_lower_air) != -1:
		push_error(
			"FAIL dig teal still fills Heart↔Lower void at %s (aqua filler blocks)"
			% heart_lower_air
		)
		quit(1)
		return
	# Dig Front proper (past civic tip) keeps excavation mass above the walk.
	var dig_front_ceiling := Vector2i(
		int(round((HollowLayout.civic_east_end() + 320.0) / tile)),
		int(round((HollowLayout.HEART_Y - 128.0) / tile))
	)
	if dig.get_cell_source_id(dig_front_ceiling) == -1:
		push_error("FAIL Dig Front must keep diggable rock above its walk corridor")
		quit(1)
		return
	print("PASS dig envelope carved open for Mid-East walk + east ladder shaft")
	print("PASS civic east inter-deck air is void (no teal aqua fillers)")

	# Dig placeholder must not be the old aqua/teal Color(0.25, 0.4, 0.42).
	var dig_color: Color = TerrainLayer.DIG_ROCK_COLOR
	var aqua := Color(0.25, 0.4, 0.42)
	if dig_color.is_equal_approx(aqua):
		push_error("FAIL dig rock color is still aqua/teal placeholder")
		quit(1)
		return
	if dig_color.g > dig_color.r + 0.04 and dig_color.b > dig_color.r + 0.04:
		push_error("FAIL dig rock color still reads teal/aqua (r=%s g=%s b=%s)" % [dig_color.r, dig_color.g, dig_color.b])
		quit(1)
		return
	print("PASS dig rock uses non-aqua treatment")

	# Mid Heart must be the continuous Mouth crossing (west lip → east lip).
	if not HollowLayout.mid_heart_spans_mouth():
		push_error("FAIL Mid Heart decks must span Mouth west lip → east lip")
		quit(1)
		return
	var heart_west_pad := Vector2i(
		int(round((HollowLayout.PIT_LEFT + 16.0) / tile)),
		heart_row
	)
	var heart_east_pad := Vector2i(
		int(round((HollowLayout.PIT_RIGHT - 16.0) / tile)),
		heart_row
	)
	if terrain.get_cell_source_id(heart_west_pad) == -1:
		push_error("FAIL Mid Heart must be walkable at Mouth west lip")
		quit(1)
		return
	if terrain.get_cell_source_id(heart_east_pad) == -1:
		push_error("FAIL Mid Heart must be walkable at Mouth east lip")
		quit(1)
		return
	print("PASS Mid Heart spans Mouth west lip → east lip")

	# Devil's Mouth (x=PIT_LEFT..PIT_RIGHT) must stay open void: dig rock never
	# enters it, and HollowTerrain may only keep intentional Mid Heart deck tops
	# (plus thin stair treads) — no solid stair/filler mass plugging the shaft.
	var pit_l := int(round(HollowLayout.PIT_LEFT / tile))
	var pit_r := int(round(HollowLayout.PIT_RIGHT / tile))
	var heart_top := int(round(HollowLayout.HEART_Y / tile))
	for cell in dig.get_used_cells():
		if cell.x >= pit_l and cell.x < pit_r:
			push_error("FAIL dig rock plugs Mouth void at %s" % cell)
			quit(1)
			return
	var mouth_fill := 0
	for cell in terrain.get_used_cells():
		if cell.x < pit_l or cell.x >= pit_r:
			continue
		if cell.y == heart_top:
			continue
		# One-tile stair treads approaching Heart are allowed; solid columns under
		# them are not (those plug the void).
		var below := Vector2i(cell.x, cell.y + 1)
		if terrain.get_cell_source_id(below) != -1 and below.y != heart_top:
			# Stack of 2+ tiles in a Mouth column = filler mass.
			mouth_fill += 1
			if mouth_fill > 0:
				push_error(
					"FAIL Mouth void plugged by solid fill at %s (and below %s)"
					% [cell, below]
				)
				quit(1)
				return
	print("PASS Mouth void stays open (no dig rock; no solid stair filler)")

	var mouth_w := HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT
	if absf(mouth_w - 3520.0) > 0.5:
		push_error("FAIL Mouth width must be 3520 (1440..4960), got %s" % mouth_w)
		quit(1)
		return
	if HollowLayout.heart_deck_rects().size() != 1:
		push_error("FAIL Mid Heart must be a single continuous deck, not multi-raft segments")
		quit(1)
		return
	var lower_mouth := 0
	for x in range(pit_l, pit_r):
		if terrain.get_cell_source_id(Vector2i(x, lower_row)) != -1:
			lower_mouth += 1
	if lower_mouth > 0:
		push_error("FAIL Lower Work still paints a secondary Mouth crossing (%s cells)" % lower_mouth)
		quit(1)
		return
	print("PASS Mouth widened to 3520; single Mid Heart deck; no lower Mouth crossing")

	var west_dig := Vector2i(
		int(round((HollowLayout.HIGH_WEST_DIG_LEFT + 320.0) / tile)),
		int(round((HollowLayout.FARMS_Y - 160.0) / tile))
	)
	if dig.get_cell_source_id(west_dig) == -1:
		push_error("FAIL High-West Dig Front must have diggable rock outside Mouth")
		quit(1)
		return
	if west_dig.x >= pit_l and west_dig.x < pit_r:
		push_error("FAIL west dig sample landed inside Mouth")
		quit(1)
		return
	print("PASS dig flanks exist outside Mouth (east Dig Front + High-West)")

	print("PLAYABLE_EXPANSION_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
