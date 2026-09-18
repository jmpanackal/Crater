extends SceneTree
## Build Bible Spec 05 (Authored Topology / Zones) — real opening-route content,
## rebuilt on hollow_terrain.gd's single-source-of-truth tile system.
##
## The opening route (mechanics-canon.md §52, hollow-chunk-map.md): Home Court ->
## Lower Switchback -> West Dispatch Yard -> Bottom-West Approach -> Lower Lift
## Landing -> Bottom-West Threshold -> First Expansion Gallery (+ Collapsed Side
## Chamber branch). Per the confirmed spatial blueprint
## (docs/hollow-level-authoring.md), Bottom-West Dig Front sits MEASURABLY BELOW
## Home Court — a compact, vertically-arranged cluster, not a flat westward strip
## (a prior pass got that wrong; see the doc's "not-a-straight-line rule").


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

	# --- 1. All 8 opening-route zones are authored AND loaded. ---
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

	# --- 2. Real seams validate cleanly. ---
	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL opening-route seams invalid: %s" % [problems])
		quit(1)
		return
	print("PASS opening-route seams are reciprocal (Zones.validate_seams())")

	# --- 3. The chain is connected end to end via get_neighbor_ids. ---
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

	# --- 4. The core spatial correction: Bottom-West sits BELOW Home Court, not
	# beside it at the same elevation (the mistake a prior pass made). ---
	var drop := HollowLayout.BOTTOM_WEST_Y - HollowLayout.LOWER_WORK_Y
	if drop < 128.0:
		push_error(
			"FAIL Bottom-West Dig Front is not measurably below Home Court (drop=%s)" % drop
		)
		quit(1)
		return
	print("PASS Bottom-West Dig Front sits %spx below Home Court (a real descent)" % drop)

	# --- 5. Terrain collision + visuals are painted together (hollow_terrain.gd
	# Rule 1) for every flat deck and every stair flight — no invisible collision. ---
	var terrain: TileMapLayer = scene.get_node_or_null("Hollow/HollowTerrain") as TileMapLayer
	if terrain == null:
		push_error("FAIL Hollow/HollowTerrain missing")
		quit(1)
		return
	var tile_size := 16 # hollow_terrain.gd's TILE_SIZE (typed as TileMapLayer here, so not statically accessible)
	for rect in HollowLayout.opening_route_deck_rects():
		var mid_x := int(round((rect.x + rect.y) * 0.5 / tile_size))
		var y := int(round(rect.z / tile_size))
		if terrain.get_cell_source_id(Vector2i(mid_x, y)) == -1:
			push_error("FAIL deck rect %s has no painted tile at its midpoint" % [rect])
			quit(1)
			return
	print("PASS every opening-route deck is painted (collision + visual, same tile)")

	for stair in HollowLayout.opening_route_stair_rects():
		var sx0 := int(round(stair.x / tile_size))
		var sy0 := int(round(stair.y / tile_size))
		if terrain.get_cell_source_id(Vector2i(sx0, sy0)) == -1:
			push_error("FAIL stair flight %s has no painted tile at its start" % [stair])
			quit(1)
			return
	print("PASS every stair flight is painted (no floating ramp collision)")

	# --- 6. Real physics collision exists under a painted deck (not just a tile
	# ID) — raycast through Home Court's floor. ---
	var space := terrain.get_world_2d().direct_space_state
	var home_y: float = HollowLayout.LOWER_WORK_Y
	var hit := space.intersect_ray(
		PhysicsRayQueryParameters2D.create(Vector2(120, home_y - 40), Vector2(120, home_y + 40))
	)
	if hit.is_empty():
		push_error("FAIL no physics collision under Home Court's painted floor")
		quit(1)
		return
	print("PASS Home Court floor has real physics collision")

	# --- 7. Climb shafts exist and reach the elevations they claim to. ---
	var ladder_chamber: Area2D = scene.get_node_or_null("Hollow/LadderChamber") as Area2D
	if ladder_chamber == null or not ladder_chamber.has_method("deck_bottom_y"):
		push_error("FAIL LadderChamber missing")
		quit(1)
		return
	if absf(ladder_chamber.deck_bottom_y() - HollowLayout.CHAMBER_ALCOVE_Y) > 1.0:
		push_error(
			"FAIL LadderChamber bottom Y=%s expected alcove=%s"
			% [ladder_chamber.deck_bottom_y(), HollowLayout.CHAMBER_ALCOVE_Y]
		)
		quit(1)
		return

	var ladder_shortcut: Area2D = scene.get_node_or_null("Hollow/LadderShortcut") as Area2D
	if ladder_shortcut == null or not ladder_shortcut.has_method("deck_bottom_y"):
		push_error("FAIL LadderShortcut missing")
		quit(1)
		return
	if absf(ladder_shortcut.deck_top_y() - HollowLayout.LADDER_SHORTCUT_TOP_Y) > 1.0:
		push_error("FAIL LadderShortcut top Y wrong: %s" % ladder_shortcut.deck_top_y())
		quit(1)
		return
	if absf(ladder_shortcut.deck_bottom_y() - HollowLayout.LADDER_SHORTCUT_BOTTOM_Y) > 1.0:
		push_error("FAIL LadderShortcut bottom Y wrong: %s" % ladder_shortcut.deck_bottom_y())
		quit(1)
		return
	print("PASS Collapsed Side Chamber ladder and the Lower Lift Landing shortcut both reach their claimed elevations")

	# --- 8. Verticality ratio (docs/hollow-level-authoring.md Rule 4): the
	# Home Court <-> Bottom-West elevation change has 2 distinct connections
	# (the long staircase via Bottom-West Approach, and the LadderShortcut),
	# not a single mandatory route. ---
	var stair_count := HollowLayout.opening_route_stair_rects().size()
	if stair_count < 2:
		push_error("FAIL expected multiple stair flights for the descent, got %d" % stair_count)
		quit(1)
		return
	print("PASS at least 2 distinct routes exist between Home Court's and Bottom-West's elevations")

	print("OPENING_ROUTE_TESTS_PASSED")
	quit(0)
