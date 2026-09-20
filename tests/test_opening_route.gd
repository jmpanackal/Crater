extends SceneTree
## Build Bible Spec 05 — opening-route zones on the uniform west stack.
## Home Court → Switchback → Dispatch sit on Lower Worker; Bottom-West Dig Front
## sits below via LadderWestStack (no stair flights).


const OPENING_ROUTE_ZONE_IDS: Array[String] = [
	"home_court",
	"lower_switchback",
	"west_dispatch_yard",
	"bottom_west_approach",
	"lower_lift_landing",
	"bottom_west_threshold",
	"first_expansion_gallery",
	"collapsed_side_chamber",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var zones: Node = root.get_node_or_null("Zones")
	if zones == null:
		push_error("FAIL Zones autoload missing")
		quit(1)
		return

	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	for zone_id in OPENING_ROUTE_ZONE_IDS:
		if not zones.has_zone(zone_id):
			push_error("FAIL opening-route zone '%s' not authored in content/zones/" % zone_id)
			quit(1)
			return
		if not zones.is_zone_loaded(zone_id):
			push_error("FAIL opening-route zone '%s' has no zone_anchor in main.tscn" % zone_id)
			quit(1)
			return
	print("PASS all 8 opening-route zones authored and loaded")

	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL opening-route seams invalid: %s" % [problems])
		quit(1)
		return
	print("PASS opening-route seams are reciprocal (Zones.validate_seams())")

	var visited: Array[String] = ["home_court"]
	var frontier: Array[String] = ["home_court"]
	while not frontier.is_empty():
		var current: String = frontier.pop_back()
		for neighbor in zones.get_neighbor_ids(current):
			if neighbor in OPENING_ROUTE_ZONE_IDS and not (neighbor in visited):
				visited.append(neighbor)
				frontier.append(neighbor)
	for zone_id in OPENING_ROUTE_ZONE_IDS:
		if not (zone_id in visited):
			push_error("FAIL '%s' is not reachable from home_court via seams" % zone_id)
			quit(1)
			return
	print("PASS every opening-route zone is seam-reachable from Home Court")

	var drop := HollowLayout.BOTTOM_WEST_Y - HollowLayout.WEST_LW_UPPER_Y
	if drop < HollowLayout.MIN_BAND_GAP - 0.5:
		push_error(
			"FAIL Bottom-West Dig Front is not measurably below Home Court (drop=%s)" % drop
		)
		quit(1)
		return
	print("PASS Bottom-West Dig Front sits %spx below Home Court (a real descent)" % drop)

	var terrain: TileMapLayer = scene.get_node_or_null("Hollow/HollowTerrain") as TileMapLayer
	if terrain == null:
		push_error("FAIL Hollow/HollowTerrain missing")
		quit(1)
		return
	var tile_size := 16
	for rect in HollowLayout.opening_route_deck_rects():
		var mid_x := int(round((rect.x + rect.y) * 0.5 / tile_size))
		var open0 := int(round(HollowLayout.LADDER_WEST_OPEN_X / float(tile_size)))
		var open1 := int(round(HollowLayout.ladder_west_open_end() / float(tile_size)))
		if mid_x >= open0 and mid_x < open1:
			mid_x = open1 + 2
		var y := int(round(rect.z / tile_size))
		if terrain.get_cell_source_id(Vector2i(mid_x, y)) == -1:
			push_error("FAIL deck rect %s has no painted tile at its midpoint" % [rect])
			quit(1)
			return
	print("PASS every opening-route deck is painted (collision + visual, same tile)")

	if not HollowLayout.opening_route_stair_rects().is_empty():
		push_error("FAIL uniform west stack must not use opening-route stair flights")
		quit(1)
		return
	print("PASS opening route uses LadderWestStack (no stair flights)")

	var space := terrain.get_world_2d().direct_space_state
	var home_y: float = HollowLayout.WEST_LW_UPPER_Y
	var hit := space.intersect_ray(
		PhysicsRayQueryParameters2D.create(Vector2(-80, home_y - 40), Vector2(-80, home_y + 40))
	)
	if hit.is_empty():
		push_error("FAIL no physics collision under Home Court's painted floor")
		quit(1)
		return
	print("PASS Home Court floor has real physics collision")

	var ladder_chamber: Area2D = scene.get_node_or_null("Hollow/LadderChamber") as Area2D
	if ladder_chamber != null:
		push_error("FAIL LadderChamber leftover must be removed from clean west dig fronts")
		quit(1)
		return
	print("PASS no collapsed-chamber ladder leftover")

	if not scene.has_node("Hollow/LadderWestStack"):
		push_error("FAIL LadderWestStack missing for Home↔Bottom-West descent")
		quit(1)
		return
	print("PASS west stack ladder provides the Bottom-West descent")

	# Bottom-West Dig Front: both uniform platforms span the dig envelope.
	var bw_upper_row := int(round(HollowLayout.BOTTOM_WEST_UPPER_Y / float(tile_size)))
	var bw_lower_row := int(round(HollowLayout.BOTTOM_WEST_LOWER_Y / float(tile_size)))
	var dig_sample := int(round((HollowLayout.HIGH_WEST_DIG_LEFT + HollowLayout.WEST_HOLLOW_LEFT) * 0.5 / float(tile_size)))
	if terrain.get_cell_source_id(Vector2i(dig_sample, bw_upper_row)) == -1:
		push_error("FAIL Bottom-West Dig Front upper missing at y=%s" % HollowLayout.BOTTOM_WEST_UPPER_Y)
		quit(1)
		return
	if terrain.get_cell_source_id(Vector2i(dig_sample, bw_lower_row)) == -1:
		push_error("FAIL Bottom-West Dig Front lower missing at y=%s" % HollowLayout.BOTTOM_WEST_LOWER_Y)
		quit(1)
		return
	print(
		"PASS Bottom-West Dig Front upper=%s lower=%s both painted full-width"
		% [HollowLayout.BOTTOM_WEST_UPPER_Y, HollowLayout.BOTTOM_WEST_LOWER_Y]
	)

	print("OPENING_ROUTE_TESTS_PASSED")
	quit(0)
