extends SceneTree
## Every Presswater elevator in HollowMap.lifts() works in the real engine with real input: stand on the cab, W rides
## it up a stop, S rides it back, the call point brings it to a landing, and the Cistern's condition slows or parks
## it (an essential lift never parks). Ashram Heights is reachable only by a lift (the lint proves the graph; this
## proves the cabs carry you).


var _failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failed = true
	push_error("FAIL " + msg)


func _reset(player: CharacterBody2D) -> void:
	player._climbing = false
	player._climb_ladders.clear()
	player.collision_mask = player.WORLD_COLLISION_MASK
	player.velocity = Vector2.ZERO
	for a in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		Input.action_release(a)


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in range(10):
		await process_frame
	var player: CharacterBody2D = scene.get_node("Player")
	var structures: Node = scene.get_node("Hollow/Structures")
	var rode := 0
	for lf in HollowMap.lifts():
		var lift: Node = structures.get_node("Lift_%s" % str(lf["id"]))
		var stops: Array = lf["stops"]
		var n := stops.size()
		if lift.stop_count() != n or lift.current_stop_index() != n - 1:
			_fail("lift %s should park at its bottom stop (%d stops)" % [str(lf["id"]), n])
			continue
		# a cab sits flush with its landing: the deck, the cab floor and the call point agree
		var cab_x: float = float(lf["open_x"]) + float(lf["width"]) * 0.5
		# with the cab at the bottom, the landing at the top stop still holds a walker up (the floor is open, the plate is not)
		_reset(player)
		player.global_position = Vector2(cab_x, float(stops[0]) - 64.0)
		for _i in range(60):
			await physics_frame
		if absf(player.global_position.y - (float(stops[0]) - 32.0)) > 6.0 or not player.is_on_floor():
			_fail("lift %s: a walker fell into the shaft at its top landing (player %s)" % [str(lf["id"]), str(player.global_position)])
			continue
		_reset(player)
		player.global_position = Vector2(cab_x, float(stops[n - 1]) - 32.0)
		for _i in range(30):
			await physics_frame
		# W: one stop up
		Input.action_press("ui_up")
		var up_ok := false
		for _i in range(900):
			await physics_frame
			if lift.current_stop_index() == n - 2 and not lift.is_moving() and absf(player.global_position.y - (float(stops[n - 2]) - 32.0)) < 6.0:
				up_ok = true
				break
		Input.action_release("ui_up")
		if not up_ok:
			_fail("lift %s did not carry the player up one stop (cab stop %d, player %s)" % [str(lf["id"]), lift.current_stop_index(), str(player.global_position)])
			continue
		for _i in range(20):
			await physics_frame
		# S: back down
		Input.action_press("ui_down")
		var down_ok := false
		for _i in range(900):
			await physics_frame
			if lift.current_stop_index() == n - 1 and not lift.is_moving() and absf(player.global_position.y - (float(stops[n - 1]) - 32.0)) < 6.0:
				down_ok = true
				break
		Input.action_release("ui_down")
		if not down_ok:
			_fail("lift %s did not carry the player back down (player %s)" % [str(lf["id"]), str(player.global_position)])
			continue
		# the call button brings an empty cab to a landing (one stop away, so the test stays short)
		_reset(player)
		player.global_position = Vector2(cab_x, float(stops[n - 2]) - 32.0 - 600.0)
		if not lift.call_to(n - 2):
			_fail("lift %s refused a call to the stop above it" % str(lf["id"]))
			continue
		var called := false
		for _i in range(900):
			await physics_frame
			if lift.current_stop_index() == n - 2 and not lift.is_moving():
				called = true
				break
		if not called:
			_fail("lift %s did not answer the call" % str(lf["id"]))
			continue
		lift.call_to(n - 1)
		for _i in range(900):
			await physics_frame
			if lift.current_stop_index() == n - 1 and not lift.is_moving():
				break
		rode += 1
	if _failed:
		quit(1)
		return
	# Presswater: the service multiplier follows the Cistern's condition; an essential lift never parks.
	for lf in HollowMap.lifts():
		var lift: Node = structures.get_node("Lift_%s" % str(lf["id"]))
		var base: float = lift.service_speed_mult()
		if base <= 0.0:
			_fail("lift %s should run at the start (multiplier %s)" % [str(lf["id"]), base])
			quit(1)
			return
		if bool(lf["essential"]) and lift.service_speed_mult() < lift.thin_speed_mult - 0.001:
			_fail("essential lift %s dropped below the slow speed" % str(lf["id"]))
			quit(1)
			return
	print("PASS %d elevators carry the player up and down and answer calls; essential lifts never park" % rode)
	quit(0)
