extends SceneTree
## Dig-approach camera: Hollow clamps dig strip, unlock expands without a hard snap.


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

	# Deep Hollow: dig columns must stay off-frame.
	player.global_position = Vector2(520.0, HollowLayout.WICK_Y - 16.0)
	player.velocity = Vector2.ZERO
	await process_frame
	await process_frame
	if float(cam.limit_right) > 1100.0:
		push_error("FAIL Hollow limit_right=%s exposes dig strip" % cam.limit_right)
		quit(1)
		return
	print("PASS Hollow clamps dig strip")

	# Walk toward civic excavation: limit_right must expand continuously (no unlock teleport).
	var prev := float(cam.limit_right)
	var max_step_jump := 0.0
	var x := 880.0
	while x <= 1160.0:
		player.global_position.x = x
		await process_frame
		var cur := float(cam.limit_right)
		var jump := absf(cur - prev)
		if jump > max_step_jump:
			max_step_jump = jump
		# ~10px walk steps; a hard 1024→2200 unlock is ~1176 and must fail.
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
	player.global_position.x = 1600.0
	await process_frame
	await process_frame
	if float(cam.limit_right) < 2000.0:
		push_error("FAIL dig limit_right=%s still clamped" % cam.limit_right)
		quit(1)
		return
	print("PASS dig limit fully unlocked in dig site")

	# Pure curve helper (if present): endpoints + continuity.
	if cam.has_method("desired_limit_right"):
		var deep: float = float(cam.desired_limit_right(400.0))
		var dig: float = float(cam.desired_limit_right(1500.0))
		if deep > 1100.0 or dig < 2000.0:
			push_error("FAIL desired_limit_right endpoints deep=%s dig=%s" % [deep, dig])
			quit(1)
			return
		var p := float(cam.desired_limit_right(860.0))
		var sx := 870.0
		while sx <= 1140.0:
			var c := float(cam.desired_limit_right(sx))
			if absf(c - p) > 160.0:
				push_error("FAIL desired_limit_right discontinuity at %s" % sx)
				quit(1)
				return
			p = c
			sx += 10.0
		print("PASS desired_limit_right curve")

	print("CAMERA_DIG_LIMIT_TESTS_PASSED")
	quit(0)
