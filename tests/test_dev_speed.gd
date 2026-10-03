extends SceneTree
## Dev movement-speed toggle: the multiplier scales walking, the X key cycles it, the console sets it.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in range(10):
		await process_frame
	var player: CharacterBody2D = scene.get_node("Player")
	player.global_position = HollowLayout.player_spawn_point()
	for _i in range(20):
		await physics_frame
	var console: Node = root.get_node("DebugConsole")
	var baseline := await _run_speed(player, 1.0)
	var fast := await _run_speed(player, 3.0)
	if fast < baseline * 2.5:
		_fail("x3 should be about three times faster (got %s vs %s)" % [fast, baseline])
		return
	console.execute("speed 6")
	if not is_equal_approx(player.dev_speed_scale, 6.0):
		_fail("the console 'speed 6' did not set the multiplier (%s)" % player.dev_speed_scale)
		return
	player.set_dev_speed(1.0)
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = player.DEV_SPEED_KEY
	player._unhandled_key_input(ev)
	if not is_equal_approx(player.dev_speed_scale, 3.0):
		_fail("X should cycle 1 -> 3 (got %s)" % player.dev_speed_scale)
		return
	player.set_dev_speed(1.0)
	print("PASS dev speed scales walking, the X key cycles it, the console sets it")
	quit(0)


func _run_speed(player: CharacterBody2D, scale: float) -> float:
	player.set_dev_speed(scale)
	player.global_position = HollowLayout.player_spawn_point()
	player.velocity = Vector2.ZERO
	for _i in range(10):
		await physics_frame
	Input.action_press("ui_right")
	var top := 0.0
	for _i in range(40):
		await physics_frame
		top = maxf(top, absf(player.velocity.x))
	Input.action_release("ui_right")
	return top
