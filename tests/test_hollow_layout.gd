extends SceneTree
## Multi-band Devil's Mouth Hollow: void, sub-levels, three lifts, Vaultward lock.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var pit: ColorRect = scene.get_node_or_null("Hollow/PitVoid") as ColorRect
	if pit == null:
		push_error("FAIL PitVoid missing")
		quit(1)
		return
	if pit.offset_left > HollowLayout.PIT_LEFT + 1.0 or pit.offset_right < HollowLayout.PIT_RIGHT - 1.0:
		push_error("FAIL PitVoid bounds %s–%s" % [pit.offset_left, pit.offset_right])
		quit(1)
		return
	var void_w := pit.offset_right - pit.offset_left
	if void_w < 400.0:
		push_error("FAIL Devil's Mouth void too narrow: %s" % void_w)
		quit(1)
		return
	print("PASS central PitVoid present")

	var farms: Label = scene.get_node("Hollow/DistrictFarms") as Label
	var wick: Label = scene.get_node("Hollow/DistrictWickwork") as Label
	var cistern: Label = scene.get_node("Hollow/DistrictCistern") as Label
	var mid: Label = scene.get_node_or_null("Hollow/DistrictMidHeart") as Label
	var vault: Label = scene.get_node_or_null("Hollow/DistrictVaultward") as Label
	if farms.position.y >= wick.position.y or wick.position.y >= cistern.position.y:
		push_error(
			"FAIL district elevations farms=%s wick=%s cistern=%s"
			% [farms.position.y, wick.position.y, cistern.position.y]
		)
		quit(1)
		return
	if mid == null or not ("heart" in mid.text.to_lower()):
		push_error("FAIL Mid Heart soft label missing")
		quit(1)
		return
	if not ("glowbed" in farms.text.to_lower()):
		push_error("FAIL Glowbeds label missing (got '%s')" % farms.text)
		quit(1)
		return
	if vault == null or not ("vaultward" in vault.text.to_lower()):
		push_error("FAIL Vaultward restricted label missing")
		quit(1)
		return
	print("PASS districts on distinct elevations + Vaultward mark")

	# Horizontal-play rule: carved rooms + public terraces, not ladder-only.
	if HollowLayout.farms_terrace_tiles() < 5 or HollowLayout.farms_gallery_tiles() < 4:
		push_error(
			"FAIL Farms horizontal span terrace=%d gallery=%d"
			% [HollowLayout.farms_terrace_tiles(), HollowLayout.farms_gallery_tiles()]
		)
		quit(1)
		return
	if HollowLayout.wick_left_street_tiles() < 5:
		push_error("FAIL Wick left street too short: %d" % HollowLayout.wick_left_street_tiles())
		quit(1)
		return
	if HollowLayout.cistern_terrace_tiles() < 2:
		push_error("FAIL Cistern terrace too short: %d" % HollowLayout.cistern_terrace_tiles())
		quit(1)
		return
	if HollowLayout.HOLLOW_LEFT > -500.0:
		push_error("FAIL carved rooms not extended into left wall")
		quit(1)
		return
	# Sub-levels: upper / glow hang / mid allotment / lower work / seep exist as distinct bands.
	if HollowLayout.UPPER_RES_Y >= HollowLayout.FARMS_Y:
		push_error("FAIL upper residence not above Glowbeds")
		quit(1)
		return
	if HollowLayout.GLOW_SUB_Y <= HollowLayout.FARMS_Y or HollowLayout.GLOW_SUB_Y >= HollowLayout.WICK_Y:
		push_error("FAIL Glowbeds sub-level not between farms and wick")
		quit(1)
		return
	if HollowLayout.MID_ALLOT_Y <= HollowLayout.WICK_Y or HollowLayout.MID_ALLOT_Y >= HollowLayout.LOWER_WORK_Y:
		push_error("FAIL mid allotment band missing")
		quit(1)
		return
	if HollowLayout.LOWER_WORK_Y >= HollowLayout.CISTERN_Y:
		push_error("FAIL lower work not above Cistern")
		quit(1)
		return
	print("PASS horizontal carved rooms + multi-band sub-levels")

	# Vertical clearance: consecutive bands need headroom for 32px body under 32px floor.
	var bands := HollowLayout.walkable_band_ys()
	for i in range(bands.size() - 1):
		var gap := HollowLayout.band_gap(bands[i], bands[i + 1])
		var head := HollowLayout.band_headroom(bands[i], bands[i + 1])
		if gap + 0.1 < HollowLayout.MIN_BAND_GAP:
			push_error(
				"FAIL band gap %s→%s is %s (need ≥%s)"
				% [bands[i], bands[i + 1], gap, HollowLayout.MIN_BAND_GAP]
			)
			quit(1)
			return
		if head < 40.0:
			push_error(
				"FAIL headroom %s→%s is %s (player clips ceiling)"
				% [bands[i], bands[i + 1], head]
			)
			quit(1)
			return
	# Tile alignment keeps FloorVisual lips on collision tops.
	for y in bands:
		if int(round(y)) % HollowLayout.TILE != 0:
			push_error("FAIL band Y %s not tile-aligned" % y)
			quit(1)
			return
		if absf(HollowLayout.floor_visual_lip_y(y) - y) > 0.01:
			push_error("FAIL floor lip misaligned at %s" % y)
			quit(1)
			return
	print("PASS band clearances + floor lip alignment")

	var floor_body: StaticBody2D = scene.get_node("Hollow/Floor") as StaticBody2D
	var shapes := 0
	for child in floor_body.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			shapes += 1
	if shapes < 16:
		push_error("FAIL expected multi-band floor collisions, got %d" % shapes)
		quit(1)
		return
	if floor_body.get_node_or_null("HeartMid") == null:
		push_error("FAIL HeartMid collision missing")
		quit(1)
		return
	if floor_body.get_node_or_null("HeartWest") == null or floor_body.get_node_or_null("HeartEast") == null:
		push_error("FAIL Mid Heart cluster decks missing")
		quit(1)
		return
	if floor_body.get_node_or_null("LowerSpan") == null:
		push_error("FAIL Lower Heart freight span missing")
		quit(1)
		return
	if floor_body.get_node_or_null("LowerWorkWest") == null:
		push_error("FAIL lower working terrace missing")
		quit(1)
		return
	if floor_body.get_node_or_null("GlowSubWest") == null:
		push_error("FAIL Glowbeds hang sub-level missing")
		quit(1)
		return
	if floor_body.get_node_or_null("MidAllotWest") == null:
		push_error("FAIL mid allotment street missing")
		quit(1)
		return
	if floor_body.get_node_or_null("SeepGallery") == null:
		push_error("FAIL seep gallery approach missing")
		quit(1)
		return
	if floor_body.get_node_or_null("VaultwardStub") == null:
		push_error("FAIL Vaultward stub missing")
		quit(1)
		return
	print("PASS terraces + sub-levels + Mid Heart + ramps + openings")

	var heart: AnimatableBody2D = scene.get_node_or_null("Hollow/CivicLift") as AnimatableBody2D
	var left: AnimatableBody2D = scene.get_node_or_null("Hollow/LeftServiceLift") as AnimatableBody2D
	var freight: AnimatableBody2D = scene.get_node_or_null("Hollow/FreightLift") as AnimatableBody2D
	if heart == null or left == null or freight == null:
		push_error("FAIL lift network incomplete (need Heart + left service + freight)")
		quit(1)
		return
	if int(heart.call("stop_count")) < 3:
		push_error("FAIL Heart hoist needs three stops")
		quit(1)
		return
	if not bool(heart.call("is_essential")):
		push_error("FAIL Heart hoist must be essential")
		quit(1)
		return
	if bool(left.call("is_essential")) or bool(freight.call("is_essential")):
		push_error("FAIL secondary lifts marked essential")
		quit(1)
		return
	print("PASS three-lift Presswater network")

	var ladder_c: Area2D = scene.get_node_or_null("Hollow/LadderCistern") as Area2D
	var ladder_m: Area2D = scene.get_node_or_null("Hollow/LadderMid") as Area2D
	if ladder_c == null or ladder_m == null:
		push_error("FAIL local maintenance ladders missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderFarms") != null:
		push_error("FAIL primary Farms ladder still present — lifts should be the spine")
		quit(1)
		return
	if absf(ladder_c.position.y - HollowLayout.LOWER_WORK_Y) > 1.0:
		push_error("FAIL Cistern emergency ladder not on lower work deck")
		quit(1)
		return
	var ladder_u: Area2D = scene.get_node_or_null("Hollow/LadderUpper") as Area2D
	if ladder_u == null:
		push_error("FAIL LadderUpper missing")
		quit(1)
		return
	if absf(float(ladder_c.get("shaft_size").y) - HollowLayout.ladder_cistern_shaft_height()) > 1.0:
		push_error("FAIL LadderCistern shaft height wrong")
		quit(1)
		return
	if absf(float(ladder_m.get("shaft_size").y) - HollowLayout.ladder_mid_shaft_height()) > 1.0:
		push_error("FAIL LadderMid shaft height wrong")
		quit(1)
		return
	if absf(float(ladder_u.get("shaft_size").y) - HollowLayout.ladder_upper_shaft_height()) > 1.0:
		push_error("FAIL LadderUpper shaft height wrong")
		quit(1)
		return
	print("PASS local ladders only (lifts are primary vertical)")

	var gate := scene.get_node_or_null("Hollow/VaultwardGate")
	if gate == null:
		push_error("FAIL Vaultward gate missing")
		quit(1)
		return
	if not HollowLayout.vaultward_locked():
		push_error("FAIL Vaultward should start locked")
		quit(1)
		return
	print("PASS Vaultward locked at start")

	var pell: Node2D = scene.get_node("Hollow/NPCs/Pell") as Node2D
	var rook: Node2D = scene.get_node("Hollow/NPCs/Rook") as Node2D
	var sila: Node2D = scene.get_node("Hollow/NPCs/Sila") as Node2D
	var joss: Node2D = scene.get_node("Hollow/NPCs/Joss") as Node2D
	if absf(pell.position.y - HollowLayout.FARMS_Y) > 8.0:
		push_error("FAIL Pell not on Glowbeds band")
		quit(1)
		return
	if absf(rook.position.y - HollowLayout.WICK_Y) > 8.0:
		push_error("FAIL Rook not on Wickwork deck")
		quit(1)
		return
	if absf(sila.position.y - HollowLayout.CISTERN_Y) > 8.0:
		push_error("FAIL Sila not on Cistern deck")
		quit(1)
		return
	if absf(joss.position.y - HollowLayout.WICK_Y) > 8.0 or joss.position.x < HollowLayout.PIT_LEFT:
		push_error("FAIL Joss not on Mid Heart cluster")
		quit(1)
		return
	print("PASS NPCs on multiple decks")

	var cam: Camera2D = scene.get_node("Player/Camera2D") as Camera2D
	if cam.limit_top > -200 or cam.limit_bottom < int(HollowLayout.SEEP_Y) + 80:
		push_error("FAIL camera limits lack vertical room top=%d bottom=%d" % [cam.limit_top, cam.limit_bottom])
		quit(1)
		return
	if not cam.drag_vertical_enabled or cam.position_smoothing_speed > 7.0:
		push_error("FAIL camera missing soft follow / deadzone polish")
		quit(1)
		return
	print("PASS camera vertical limits")

	var player: Node2D = scene.get_node("Player") as Node2D
	if player.position.x > HollowLayout.PIT_LEFT:
		push_error("FAIL player spawn not on left terraces")
		quit(1)
		return
	if absf(player.position.y - (HollowLayout.LOWER_WORK_Y - 32.0)) > 8.0:
		push_error("FAIL player spawn not on lower working terraces (y=%s)" % player.position.y)
		quit(1)
		return
	print("PASS spawn on lower working terraces")

	if TerrainLayer.DIG_START_X * TerrainLayer.TILE_SIZE < int(HollowLayout.EXIT_RIGHT):
		push_error("FAIL dig starts before Hollow exit")
		quit(1)
		return
	print("PASS dig site past Hollow exit ledge")

	print("HOLLOW_LAYOUT_TESTS_PASSED")
	quit(0)
