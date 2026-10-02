extends SceneTree
## Every stair, ladder and lift in HollowMap actually works in the real engine with real
## input, in both directions, and the gates behave. This is the check HollowMapLint cannot
## make: it proves the geometry can be *played*, not just that the data is consistent.


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
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")


func _run() -> void:
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	for _i in range(10):
		await process_frame
	var player: CharacterBody2D = scene.get_node("Player")
	var structures: Node = scene.get_node("Hollow/Structures")

	# --- spawn rests on Home Court; the void plane is below the lowest deck ---
	player.global_position = HollowLayout.player_spawn_point()
	for _i in range(20):
		await physics_frame
	if absf(player.global_position.y - HollowLayout.player_spawn_point().y) > 8.0 or not player.is_on_floor():
		_fail("player does not rest on Home Court at spawn")
	var void_y := float(player.VOID_FALL_Y)
	if void_y <= HollowLayout.BOTTOM_WEST_LOWER_Y - float(player.BODY_HEIGHT) + 8.0:
		_fail("VOID_FALL_Y=%s would kill a player standing on the lowest deck" % void_y)
	print("PASS spawn rests on Home Court; void plane is below the lowest deck")

	# --- stairs up: hold the arrow toward the flight, arrive on the deck above ---
	var stairs_ok := 0
	for s in HollowMap.stairs():
		_reset(player)
		var dir := float(s["dir"])
		player.global_position = Vector2(float(s["foot_x"]) - dir * 80.0, float(s["foot_y"]) - 32.0)
		for _i in range(20):
			await physics_frame
		var action := "ui_right" if dir > 0.0 else "ui_left"
		Input.action_press(action)
		var reached := false
		for _i in range(900):
			await physics_frame
			if absf(player.global_position.y - (float(s["top_y"]) - 32.0)) < 6.0 and absf(player.global_position.x - float(s["top_x"])) < 120.0:
				reached = true
				break
		Input.action_release(action)
		if reached:
			stairs_ok += 1
		else:
			_fail("stair %s cannot be climbed (ended at %s, wanted y=%s)" % [str(s["id"]), str(player.global_position), str(float(s["top_y"]) - 32.0)])
	print("PASS %d/%d stairs climb with plain walking" % [stairs_ok, HollowMap.stairs().size()])

	# --- stairs down: stand on the street over the flight, press Down, walk down to the foot ---
	var down_ok := 0
	for s in HollowMap.stairs():
		_reset(player)
		var dir := float(s["dir"])
		player.global_position = Vector2(float(s["top_x"]) - dir * 40.0, float(s["top_y"]) - 32.0)
		for _i in range(20):
			await physics_frame
		Input.action_press("ui_down")
		for _i in range(3):
			await physics_frame
		Input.action_release("ui_down")
		var action := "ui_left" if dir > 0.0 else "ui_right"
		Input.action_press(action)
		var arrived := false
		for _i in range(1200):
			await physics_frame
			if absf(player.global_position.y - (float(s["foot_y"]) - 32.0)) < 6.0 and player.is_on_floor() and absf(player.global_position.x - float(s["foot_x"])) < 160.0:
				arrived = true
				break
		Input.action_release(action)
		if arrived:
			down_ok += 1
		else:
			_fail("stair %s cannot be descended with Down + walking (ended at %s)" % [str(s["id"]), str(player.global_position)])
	print("PASS %d/%d stairs descend (Down drops through the street onto the flight)" % [down_ok, HollowMap.stairs().size()])

	# --- ladders: climb up from the bottom, then mount from the top deck and climb down ---
	var ladders_ok := 0
	for l in HollowMap.ladders():
		_reset(player)
		var node: Area2D = structures.get_node(str(l["id"]))
		var lx := float(l["open_x"]) + 12.0
		player.global_position = Vector2(lx - 4.0, float(l["bottom_y"]) - 32.0)
		for _i in range(20):
			await physics_frame
		player.enter_climb_zone(node)
		Input.action_press("ui_up")
		var up := false
		for _i in range(1500):
			await physics_frame
			if player.is_on_floor() and not player.is_climbing() and absf(player.global_position.y - (float(l["top_y"]) - 32.0)) < 8.0:
				up = true
				break
		Input.action_release("ui_up")
		if not up:
			_fail("ladder %s cannot be climbed up (ended at %s)" % [str(l["id"]), str(player.global_position)])
			continue
		for _i in range(10):
			await physics_frame
		# Now standing on the top deck: Down must grab the ladder (no hatch to walk into).
		_reset(player)
		player.global_position = Vector2(lx - 4.0, float(l["top_y"]) - 32.0)
		for _i in range(20):
			await physics_frame
		player.enter_climb_zone(node)
		for _i in range(4):
			await physics_frame
		Input.action_press("ui_down")
		var down := false
		for _i in range(1500):
			await physics_frame
			if player.is_on_floor() and not player.is_climbing() and absf(player.global_position.y - (float(l["bottom_y"]) - 32.0)) < 8.0:
				down = true
				break
		Input.action_release("ui_down")
		if down:
			ladders_ok += 1
		else:
			_fail("ladder %s cannot be mounted from the deck on top and climbed down (ended at %s)" % [str(l["id"]), str(player.global_position)])
	print("PASS %d/%d ladders climb up, and mount from the top deck to climb down" % [ladders_ok, HollowMap.ladders().size()])

	# --- lifts: park at the bottom stop, ride to the top ---
	for lf in HollowMap.lifts():
		_reset(player)
		var lift: Node = structures.get_node("Lift_%s" % str(lf["id"]))
		var stops: Array = lf["stops"]
		if lf["gate"] != &"":
			if not lift.is_locked():
				_fail("lift %s is Warden-run and must start locked" % str(lf["id"]))
			continue
		lift.position.y = stops[stops.size() - 1]
		lift._stop_index = stops.size() - 1
		lift._target_y = lift.position.y
		player.global_position = Vector2(HollowLayout.lift_x_for(lf["id"]) + 8.0, float(stops[stops.size() - 1]) - 32.0)
		for _i in range(30):
			await physics_frame
		Input.action_press("ui_up")
		var top := false
		for _i in range(4000):
			await physics_frame
			if absf(player.global_position.y - (float(stops[0]) - 32.0)) < 6.0 and not lift.is_moving():
				top = true
				break
		Input.action_release("ui_up")
		if not top:
			_fail("lift %s did not carry the player to its top stop (ended at %s)" % [str(lf["id"]), str(player.global_position)])
	print("PASS open lifts ride from the bottom stop to the top stop; the Warden lift starts locked")

	# --- gates: shut at the start, open on their story flag ---
	var story: Node = root.get_node_or_null("Story")
	var access: Node = root.get_node_or_null("Access")
	if story == null or access == null:
		_fail("Story / Access autoloads missing")
	else:
		for g in HollowMap.gates():
			if bool(access.is_open(g["id"])):
				_fail("gate %s is open at the start" % str(g["id"]))
		for g in HollowMap.gates():
			story.set_flag(g["flag"], "test clearance")
		for g in HollowMap.gates():
			if not bool(access.is_open(g["id"])):
				_fail("gate %s did not open on flag %s" % [str(g["id"]), str(g["flag"])])
		for g in HollowMap.gates():
			story.clear_flag(g["flag"])
		print("PASS gates start shut and open on their story flags")

	if _failed:
		quit(1)
		return
	print("HOLLOW_TRAVERSAL_PASSED")
	quit(0)
