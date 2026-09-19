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

	print("CAMERA_DIG_LIMIT_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
