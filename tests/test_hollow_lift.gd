extends SceneTree
## Presswater lift network — Heart hoist essential; secondaries respect thin/reserve.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var districts: Node = root.get_node_or_null("Districts")
	var heart: AnimatableBody2D = scene.get_node_or_null("Hollow/CivicLift") as AnimatableBody2D
	var left: AnimatableBody2D = scene.get_node_or_null("Hollow/LeftServiceLift") as AnimatableBody2D
	var freight: AnimatableBody2D = scene.get_node_or_null("Hollow/FreightLift") as AnimatableBody2D
	var player: CharacterBody2D = scene.get_node_or_null("Player") as CharacterBody2D
	if heart == null or left == null or freight == null or player == null or districts == null:
		push_error("FAIL lifts, Player, or Districts missing")
		quit(1)
		return

	if int(heart.call("stop_count")) != 3:
		push_error("FAIL Heart stop_count=%s" % heart.call("stop_count"))
		quit(1)
		return
	if absf(heart.position.x - HollowLayout.LIFT_X) > 1.0:
		push_error("FAIL Heart hoist not in civic shaft")
		quit(1)
		return
	print("PASS Heart hoist placed")

	# Healthy Presswater — all lifts runnable.
	districts.set_good_amount(districts.PRESSWATER, 4)
	if float(heart.call("service_speed_mult")) < 0.99:
		push_error("FAIL essential lift slowed while healthy")
		quit(1)
		return
	if float(left.call("service_speed_mult")) < 0.99:
		push_error("FAIL left service not full speed while healthy")
		quit(1)
		return
	print("PASS healthy Presswater → all lifts normal")

	# Thin — secondaries slow; essential stays full.
	districts.set_good_amount(districts.PRESSWATER, 2)
	if float(heart.call("service_speed_mult")) < 0.99:
		push_error("FAIL essential slowed while thin")
		quit(1)
		return
	if float(left.call("service_speed_mult")) > 0.5:
		push_error("FAIL secondary not slowed while thin")
		quit(1)
		return
	print("PASS thin Presswater → secondary slow, essential full")

	# Reserve — secondaries parked; essential still available (no softlock).
	districts.set_good_amount(districts.PRESSWATER, districts.PROTECTED_RESERVE)
	if float(heart.call("service_speed_mult")) < 0.99:
		push_error("FAIL essential unavailable at reserve")
		quit(1)
		return
	if float(left.call("service_speed_mult")) > 0.0 or not bool(left.call("is_parked")):
		push_error("FAIL secondary not parked at reserve")
		quit(1)
		return
	if float(freight.call("service_speed_mult")) > 0.0:
		push_error("FAIL freight not parked at reserve")
		quit(1)
		return
	print("PASS reserve Presswater → secondary parked, essential lives")

	# Steal cannot drop below reserve (already enforced by Districts); keep essential route.
	districts.set_good_amount(districts.PRESSWATER, districts.PROTECTED_RESERVE)
	if districts.divert_good(districts.PRESSWATER, 1):
		push_error("FAIL steal took Presswater below reserve")
		quit(1)
		return
	if districts.get_good_amount(districts.PRESSWATER) < districts.PROTECTED_RESERVE:
		push_error("FAIL Presswater dropped below reserve")
		quit(1)
		return
	if float(heart.call("service_speed_mult")) < 0.99:
		push_error("FAIL softlock: essential lift dead after spend attempt")
		quit(1)
		return
	print("PASS no softlock — essential route always available")

	# Ride Heart hoist Lower → Mid → Glowbeds on-screen.
	districts.set_good_amount(districts.PRESSWATER, 4)
	# Force Heart to lower stop index 2.
	heart.set("_stop_index", 2)
	heart.set("_target_y", HollowLayout.LOWER_WORK_Y)
	heart.set("_moving", false)
	heart.position.y = HollowLayout.LOWER_WORK_Y

	player.global_position = Vector2(HollowLayout.LIFT_X + 8.0, HollowLayout.LOWER_WORK_Y - 32.0)
	player.velocity = Vector2.ZERO
	for _i in range(8):
		await physics_frame

	Input.action_press("ui_up")
	for _i in range(280):
		await physics_frame
		if absf(float(heart.position.y) - HollowLayout.WICK_Y) <= 3.0:
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if absf(float(heart.position.y) - HollowLayout.WICK_Y) > 4.0:
		push_error("FAIL Heart hoist did not reach Mid stop (y=%s)" % heart.position.y)
		quit(1)
		return
	print("PASS Heart hoist rides Lower → Mid")

	Input.action_press("ui_up")
	for _i in range(280):
		await physics_frame
		if absf(float(heart.position.y) - HollowLayout.FARMS_Y) <= 3.0:
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if absf(float(heart.position.y) - HollowLayout.FARMS_Y) > 4.0:
		push_error("FAIL Heart hoist did not reach Glowbeds (y=%s)" % heart.position.y)
		quit(1)
		return
	print("PASS Heart hoist rides Mid → Glowbeds")

	# Left service ride while healthy.
	left.set("_stop_index", 1)
	left.set("_target_y", HollowLayout.GLOW_SUB_Y)
	left.set("_moving", false)
	left.position.y = HollowLayout.GLOW_SUB_Y
	player.global_position = Vector2(HollowLayout.LEFT_LIFT_X + 8.0, HollowLayout.GLOW_SUB_Y - 32.0)
	player.velocity = Vector2.ZERO
	for _i in range(8):
		await physics_frame
	Input.action_press("ui_up")
	for _i in range(220):
		await physics_frame
		if absf(float(left.position.y) - HollowLayout.FARMS_Y) <= 3.0:
			break
	Input.action_release("ui_up")
	for _i in range(8):
		await physics_frame
	if absf(float(left.position.y) - HollowLayout.FARMS_Y) > 4.0:
		push_error("FAIL left service did not reach Glowbeds (y=%s)" % left.position.y)
		quit(1)
		return
	print("PASS left service lift rides hang → Glowbeds")

	# W/S must drive lifts (player uses physical W/S; ui_* alone is not enough).
	heart.set("_stop_index", 2)
	heart.set("_target_y", HollowLayout.LOWER_WORK_Y)
	heart.set("_moving", false)
	heart.position.y = HollowLayout.LOWER_WORK_Y
	player.global_position = Vector2(HollowLayout.LIFT_X + 8.0, HollowLayout.LOWER_WORK_Y - 32.0)
	player.velocity = Vector2.ZERO
	for _i in range(8):
		await physics_frame

	var press_w := InputEventKey.new()
	press_w.physical_keycode = KEY_W
	press_w.pressed = true
	Input.parse_input_event(press_w)
	for _i in range(280):
		await physics_frame
		if absf(float(heart.position.y) - HollowLayout.WICK_Y) <= 3.0:
			break
	var release_w := InputEventKey.new()
	release_w.physical_keycode = KEY_W
	release_w.pressed = false
	Input.parse_input_event(release_w)
	for _i in range(8):
		await physics_frame
	if absf(float(heart.position.y) - HollowLayout.WICK_Y) > 4.0:
		push_error("FAIL Heart hoist ignored W key (y=%s)" % heart.position.y)
		quit(1)
		return
	print("PASS Heart hoist rides on W key")

	print("HOLLOW_LIFT_TESTS_PASSED")
	quit(0)
