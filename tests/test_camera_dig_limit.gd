extends SceneTree
## Dig-approach camera: Hollow clamps dig strip, Mid-East frames civically,
## unlock expands past Mid-East without a hard snap.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: CharacterBody2D = scene.get_node_or_null("Player") as CharacterBody2D
	var cam: Camera2D = scene.get_node_or_null("Player/Camera2D") as Camera2D
	if player == null or cam == null:
		push_error("FAIL Player/Camera2D missing")
		quit(1)
		return

	var mid_east_end := HollowLayout.civic_east_end()
	var mid_east_framed := mid_east_end + 2880.0

	# West of Mid Heart: dig framing must stay locked at the Hollow clamp.
	player.set_physics_process(false)
	player.global_position = Vector2(1000.0, HollowLayout.WICK_Y - 80.0)
	player.velocity = Vector2.ZERO
	await physics_frame
	await process_frame
	if float(cam.limit_right) >= 10000.0:
		push_error("FAIL west Hollow limit_right=%s unlocks full dig strip" % cam.limit_right)
		quit(1)
		return
	if absf(float(cam.limit_right) - float(cam.LIMIT_RIGHT_HOLLOW)) > 1.0:
		push_error(
			"FAIL west Hollow limit_right=%s should stay at Hollow clamp %s"
			% [cam.limit_right, cam.LIMIT_RIGHT_HOLLOW]
		)
		quit(1)
		return
	print("PASS west Hollow keeps dig framing locked")

	# Crossing Devil's Mouth / Mid Heart: limit_right must ease continuously.
	# A short Heart-East blend (~100px) jerks the clamped camera (~90px/step).
	var mouth_prev := float(cam.desired_limit_right(HollowLayout.HEART_WEST.x - 100.0))
	var mouth_max_jump := 0.0
	var mouth_x := HollowLayout.HEART_WEST.x - 100.0
	while mouth_x <= HollowLayout.PIT_RIGHT + 100.0:
		var mouth_cur := float(cam.desired_limit_right(mouth_x))
		var mouth_jump := absf(mouth_cur - mouth_prev)
		if mouth_jump > mouth_max_jump:
			mouth_max_jump = mouth_jump
		if mouth_jump > 40.0:
			push_error(
				"FAIL Mouth camera limit jerk jump=%s at x=%s (prev=%s cur=%s)"
				% [mouth_jump, mouth_x, mouth_prev, mouth_cur]
			)
			quit(1)
			return
		if mouth_cur > mid_east_framed + 1.0:
			push_error("FAIL Mouth x=%s unlocks full dig framing" % mouth_x)
			quit(1)
			return
		mouth_prev = mouth_cur
		mouth_x += 10.0
	print("PASS Mouth / Mid Heart limit eases without jerk (max step=%s)" % mouth_max_jump)

	# Mid-East Landing + Approach is still Hollow civic framing: camera must
	# cover the walk with viewport pad, and must NOT fully unlock dig yet.
	for mid_x in [HollowLayout.PIT_RIGHT + 80.0, HollowLayout.MID_EAST_APPROACH.x + 64.0]:
		player.global_position.x = mid_x
		await physics_frame
		await process_frame
		var mid_limit := float(cam.limit_right)
		if mid_limit < mid_east_framed - 1.0:
			push_error(
				"FAIL Mid-East x=%s limit_right=%s cannot frame civic walk (need ~%s)"
				% [mid_x, mid_limit, mid_east_framed]
			)
			quit(1)
			return
		if mid_limit > mid_east_framed + 1.0:
			push_error(
				"FAIL Mid-East x=%s still unlocks full dig framing (limit_right=%s)"
				% [mid_x, mid_limit]
			)
			quit(1)
			return
	print("PASS Mid-East Landing/Approach frames without dig unlock")

	# Past Mid-East Approach into dig front: limit_right expands continuously (no snap).
	var prev := float(cam.limit_right)
	var max_step_jump := 0.0
	var x := mid_east_end
	while x <= mid_east_end + 1400.0:
		player.global_position.x = x
		await physics_frame
		await process_frame
		var cur := float(cam.limit_right)
		var jump := absf(cur - prev)
		if jump > max_step_jump:
			max_step_jump = jump
		# ~10px walk steps; a hard hollow→dig unlock jump must fail.
		if jump > 160.0:
			push_error(
				"FAIL dig camera limit snap jump=%s at x=%s (prev=%s cur=%s)"
				% [jump, x, prev, cur]
			)
			quit(1)
			return
		prev = cur
		x += 10.0
	print("PASS dig limit expands without snap (max step=%s)" % max_step_jump)

	# Fully past dig mouth: full dig framing allowed.
	player.global_position.x = HollowLayout.civic_east_end() + 1400.0
	await physics_frame
	await process_frame
	if float(cam.limit_right) < float(cam.LIMIT_RIGHT_DIG) - 320.0:
		push_error("FAIL dig limit_right=%s still clamped" % cam.limit_right)
		quit(1)
		return
	print("PASS dig limit fully unlocked in dig site")

	# Pure curve helper (if present): endpoints + continuity across Mid-East→dig.
	if cam.has_method("desired_limit_right"):
		var deep: float = float(cam.desired_limit_right(2000.0))
		var dig: float = float(cam.desired_limit_right(HollowLayout.civic_east_end() + 1400.0))
		if deep > mid_east_end or dig < float(cam.LIMIT_RIGHT_DIG) - 320.0:
			push_error("FAIL desired_limit_right endpoints deep=%s dig=%s" % [deep, dig])
			quit(1)
			return
		var mid_east_curve: float = float(cam.desired_limit_right(HollowLayout.MID_EAST_APPROACH.x + 64.0))
		if mid_east_curve < mid_east_framed - 1.0 or mid_east_curve > mid_east_framed + 1.0:
			push_error(
				"FAIL desired_limit_right Mid-East=%s (need ~%s civic frame)"
				% [mid_east_curve, mid_east_framed]
			)
			quit(1)
			return
		var p := float(cam.desired_limit_right(mid_east_end - 100.0))
		var sx := mid_east_end - 10.0
		while sx <= mid_east_end + 1300.0:
			var c := float(cam.desired_limit_right(sx))
			if absf(c - p) > 160.0:
				push_error("FAIL desired_limit_right discontinuity at %s" % sx)
				quit(1)
				return
			p = c
			sx += 10.0
		print("PASS desired_limit_right curve")

	# Edge padding: limits must allow camera center on BW lower / Ashram upper.
	# Godot clamps center to [limit+half_view, limit-half_view]; stale limit_bottom
	# (6500) sat above BOTTOM_WEST_LOWER_Y (7360) and pinned the player to the
	# bottom of the frame.
	if cam.has_method("_apply_play_edge_limits"):
		cam._apply_play_edge_limits()
	var pad := Vector2(cam.EDGE_PAD_X, cam.EDGE_PAD_Y)
	if cam.has_method("edge_pad"):
		pad = cam.edge_pad()
	var slack := float(cam.STAND_CENTER_SLACK)

	var need_left := HollowLayout.HIGH_WEST_DIG_LEFT - pad.x - slack
	var need_top := HollowLayout.VAULTWARD_Y - pad.y - slack
	var need_bottom := HollowLayout.BOTTOM_WEST_LOWER_Y + pad.y + slack
	if float(cam.limit_left) > need_left + 1.0:
		push_error(
			"FAIL limit_left=%s too tight for west dig lip (need <= %s)"
			% [cam.limit_left, need_left]
		)
		quit(1)
		return
	if float(cam.limit_top) > need_top + 1.0:
		push_error(
			"FAIL limit_top=%s too tight for Vaultward/Ashram (need <= %s)"
			% [cam.limit_top, need_top]
		)
		quit(1)
		return
	if float(cam.limit_bottom) < need_bottom - 1.0:
		push_error(
			"FAIL limit_bottom=%s too tight for Bottom-West lower (need >= %s)"
			% [cam.limit_bottom, need_bottom]
		)
		quit(1)
		return
	print(
		"PASS edge limits pad past stands (L=%s T=%s B=%s pad=%s)"
		% [cam.limit_left, cam.limit_top, cam.limit_bottom, pad]
	)

	# Disable drag/smoothing so screen center can settle on the camera node.
	cam.drag_horizontal_enabled = false
	cam.drag_vertical_enabled = false
	cam.position_smoothing_enabled = false
	cam.offset = Vector2.ZERO

	var ladder_x := HollowLayout.LADDER_WEST_OPEN_X + HollowLayout.LADDER_OPENING * 0.5
	var body_h := float(player.BODY_HEIGHT)

	# Bottom-West Dig lower: camera screen center must match camera global (no clamp).
	player.global_position = Vector2(
		ladder_x,
		HollowLayout.BOTTOM_WEST_LOWER_Y - body_h
	)
	player.velocity = Vector2.ZERO
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	var bw_target := cam.global_position
	var bw_center := cam.get_screen_center_position()
	if bw_center.distance_to(bw_target) > 8.0:
		push_error(
			"FAIL BW lower camera off-center: screen=%s cam=%s player=%s limits T/B=%s/%s"
			% [bw_center, bw_target, player.global_position, cam.limit_top, cam.limit_bottom]
		)
		quit(1)
		return
	print("PASS Bottom-West lower keeps camera centered (delta=%s)" % bw_center.distance_to(bw_target))

	# Ashram upper: same centering check at the top of the west stack.
	player.global_position = Vector2(
		ladder_x,
		HollowLayout.WEST_ASHRAM_UPPER_Y - body_h
	)
	player.velocity = Vector2.ZERO
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame
	var ash_target := cam.global_position
	var ash_center := cam.get_screen_center_position()
	if ash_center.distance_to(ash_target) > 8.0:
		push_error(
			"FAIL Ashram upper camera off-center: screen=%s cam=%s player=%s limits T/B=%s/%s"
			% [ash_center, ash_target, player.global_position, cam.limit_top, cam.limit_bottom]
		)
		quit(1)
		return
	print("PASS Ashram upper keeps camera centered (delta=%s)" % ash_center.distance_to(ash_target))

	# Mid-East civic framing must still hold after edge-limit refresh (no dig yank).
	player.global_position = Vector2(HollowLayout.MID_EAST_APPROACH.x + 64.0, HollowLayout.HEART_Y - body_h)
	player.velocity = Vector2.ZERO
	await physics_frame
	await process_frame
	if absf(float(cam.limit_right) - mid_east_framed) > 1.0:
		push_error(
			"FAIL Mid-East limit_right=%s drifted after edge pad (need ~%s)"
			% [cam.limit_right, mid_east_framed]
		)
		quit(1)
		return
	print("PASS Mid-East civic limit_right intact after edge padding")

	print("CAMERA_DIG_LIMIT_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
