extends SceneTree
## Build Bible Spec 05 (Authored Topology / Zones) — real opening-route content.
##
## The opening route (hollow-chunk-map.md): Home Court -> Lower Switchback ->
## West Dispatch Yard -> Bottom-West Approach -> Bottom-West Threshold ->
## First Expansion Gallery (+ Collapsed Side Chamber branch). This is the
## first time Zones.validate_seams() runs against real authored content
## instead of test_zones.gd's synthetic fixtures — closing the acceptance
## test the spec's own header promised.


const OPENING_ROUTE_ZONE_IDS: Array[String] = [
	"home_court",
	"lower_switchback",
	"west_dispatch_yard",
	"bottom_west_approach",
	"bottom_west_threshold",
	"first_expansion_gallery",
	"collapsed_side_chamber",
]

## (deck name, expected x0, expected x1) — contiguous chain, no gaps, matching
## hollow_decks.gd's _add_opening_route(). Ramp segments bridge the gaps
## between these flat decks (verified separately below).
const EXPECTED_DECKS := [
	["HomeCourtDeck", -64.0, 224.0],
	["SwitchbackFloor", -288.0, -160.0],
	["WestDispatchYard", -768.0, -384.0],
	["DispatchPlatform", -608.0, -512.0],
	["ApproachFlatA", -1152.0, -1088.0],
	["ApproachFlatB", -1024.0, -928.0],
	["ApproachFlatC", -864.0, -768.0],
	["BottomWestThreshold", -1408.0, -1152.0],
	["GalleryFloorA", -1728.0, -1600.0],
	["GalleryFloorB", -1536.0, -1472.0],
	["ChamberAlcove", -1792.0, -1696.0],
]

const EXPECTED_RAMPS := [
	"SwitchbackRampDown", "SwitchbackRampUp",
	"DispatchPlatformRampUp", "DispatchPlatformRampDown",
	"ApproachRampDown", "ApproachRampUp",
	"GalleryRampDown", "GalleryRampUp",
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

	# --- 1. All 7 opening-route zones are authored AND loaded. ---
	for zone_id in OPENING_ROUTE_ZONE_IDS:
		if not zones.has_zone(zone_id):
			push_error("FAIL opening-route zone '%s' not authored in content/zones/" % zone_id)
			quit(1)
			return
		if not zones.is_zone_loaded(zone_id):
			push_error("FAIL opening-route zone '%s' has no zone_anchor in main.tscn" % zone_id)
			quit(1)
			return
	print("PASS all 7 opening-route zones authored and loaded")

	# --- 2. Real seams validate cleanly — first time against authored content. ---
	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL opening-route seams invalid: %s" % [problems])
		quit(1)
		return
	print("PASS opening-route seams are reciprocal (Zones.validate_seams())")

	# --- 3. The chain is actually connected end to end via get_neighbor_ids. ---
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

	# --- 4. Floor collision is contiguous — no gaps a walking player could fall through. ---
	var floor_body: StaticBody2D = scene.get_node_or_null("Hollow/Floor") as StaticBody2D
	if floor_body == null:
		push_error("FAIL Hollow/Floor missing")
		quit(1)
		return
	for entry in EXPECTED_DECKS:
		var deck_name: String = entry[0]
		var x0: float = entry[1]
		var x1: float = entry[2]
		var col := floor_body.get_node_or_null(deck_name) as CollisionShape2D
		if col == null:
			push_error("FAIL deck '%s' missing from Floor" % deck_name)
			quit(1)
			return
		var shape := col.shape as RectangleShape2D
		if shape == null:
			push_error("FAIL deck '%s' has no RectangleShape2D" % deck_name)
			quit(1)
			return
		var got_x0 := col.position.x - shape.size.x * 0.5
		var got_x1 := col.position.x + shape.size.x * 0.5
		if absf(got_x0 - x0) > 0.5 or absf(got_x1 - x1) > 0.5:
			push_error(
				"FAIL deck '%s' spans %s..%s, expected %s..%s"
				% [deck_name, got_x0, got_x1, x0, x1]
			)
			quit(1)
			return
	print("PASS opening-route decks present at their authored world-space bounds")

	for ramp_name in EXPECTED_RAMPS:
		if floor_body.get_node_or_null(ramp_name) == null:
			push_error("FAIL ramp '%s' missing from Floor" % ramp_name)
			quit(1)
			return
	print("PASS elevation-change ramps present")

	# --- 5. Collapsed Side Chamber's ladder branch exists and reaches the alcove. ---
	var ladder: Area2D = scene.get_node_or_null("Hollow/LadderChamber") as Area2D
	if ladder == null:
		push_error("FAIL LadderChamber missing")
		quit(1)
		return
	if not ladder.has_method("deck_bottom_y"):
		push_error("FAIL LadderChamber missing deck_bottom_y")
		quit(1)
		return
	if absf(ladder.deck_bottom_y() - HollowLayout.CHAMBER_ALCOVE_Y) > 1.0:
		push_error(
			"FAIL LadderChamber bottom Y=%s expected alcove=%s"
			% [ladder.deck_bottom_y(), HollowLayout.CHAMBER_ALCOVE_Y]
		)
		quit(1)
		return
	print("PASS Collapsed Side Chamber ladder reaches the alcove deck")

	print("OPENING_ROUTE_TESTS_PASSED")
	quit(0)
