extends SceneTree
## Build Bible Spec 05 — opening-route zones. Home Court -> Switchback -> Dispatch sit on
## Lower Worker (L8); the Bottom-West Approach and Dig Front sit below via the S_BW1 / S_BW2
## stairs (a real descent, no ladder shaft).


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
			push_error("FAIL opening-route zone '%s' has no zone anchor (HollowStructures builds them)" % zone_id)
			quit(1)
			return
	print("PASS all %d opening-route zones authored and loaded" % OPENING_ROUTE_ZONE_IDS.size())

	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL seams invalid: %s" % [problems])
		quit(1)
		return
	print("PASS every zone seam is reciprocal (Zones.validate_seams())")

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
		push_error("FAIL Bottom-West Dig Front is not measurably below Home Court (drop=%s)" % drop)
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
		var y := int(round(rect.z / tile_size))
		if terrain.cell_source(Vector2i(mid_x, y)) == -1:
			push_error("FAIL deck rect %s has no painted tile at its midpoint" % [rect])
			quit(1)
			return
	print("PASS every opening-route deck is painted (collision + visual, same tile)")

	if HollowLayout.opening_route_stair_rects().size() != 3:
		push_error("FAIL the opening route is the Worker Stair plus the two Bottom-West descents (3 stairs)")
		quit(1)
		return
	for removed in ["Hollow/LadderChamber", "Hollow/LadderWestStack"]:
		if scene.get_node_or_null(removed) != null:
			push_error("FAIL old ladder %s must stay removed" % removed)
			quit(1)
			return
	print("PASS the opening route uses stairs; no leftover ladder shaft")

	var space := terrain.get_world_2d().direct_space_state
	var hit := space.intersect_ray(
		PhysicsRayQueryParameters2D.create(Vector2(-80, HollowLayout.WEST_LW_UPPER_Y - 40), Vector2(-80, HollowLayout.WEST_LW_UPPER_Y + 40))
	)
	if hit.is_empty():
		push_error("FAIL no physics collision under Home Court's painted floor")
		quit(1)
		return
	print("PASS Home Court floor has real physics collision")

	# Bottom-West Dig Front: both galleries are painted and open into diggable rock.
	var dig_sample := int(round((HollowLayout.HIGH_WEST_DIG_LEFT + HollowLayout.BOTTOM_WEST_THRESHOLD_LEFT) * 0.5 / float(tile_size)))
	for level_y in [HollowLayout.BOTTOM_WEST_UPPER_Y, HollowLayout.BOTTOM_WEST_LOWER_Y]:
		if terrain.cell_source(Vector2i(dig_sample, int(round(level_y / float(tile_size))))) == -1:
			push_error("FAIL Bottom-West gallery at y=%s missing" % level_y)
			quit(1)
			return
	var dig: TileMapLayer = scene.get_node("Terrain") as TileMapLayer
	if not dig.can_dig(Vector2(HollowLayout.HIGH_WEST_DIG_LEFT + 200.0, HollowLayout.BOTTOM_WEST_UPPER_Y - 160.0)):
		push_error("FAIL Bottom-West gallery must have diggable rock above it")
		quit(1)
		return
	print("PASS Bottom-West galleries painted with diggable rock around them")

	print("OPENING_ROUTE_TESTS_PASSED")
	quit(0)
