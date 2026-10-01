extends SceneTree
## Camera limits cover the whole map: both dig flank tips, the Vaultward line above and the
## lowest deck below are all reachable with the player centred, and nothing is hidden by a
## per-region clamp (the old east dig clamp is gone with the symmetric map).


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
	player.set_physics_process(false)
	var pad: Vector2 = cam.edge_pad()

	# Right clamp is static and clears the east flank tip with a full half-viewport.
	var tip := HollowLayout.EAST_FLANK_RIGHT
	for x in [HollowLayout.player_spawn_point().x, HollowLayout.PIT_RIGHT + 80.0, tip - 64.0]:
		player.global_position = Vector2(x, HollowLayout.HEART_Y - 80.0)
		await physics_frame
		await process_frame
		if float(cam.limit_right) < tip + pad.x - 1.0:
			push_error("FAIL limit_right=%s hides the east flank tip (%s) at player x=%s" % [cam.limit_right, tip, x])
			quit(1)
			return
		if absf(float(cam.desired_limit_right(x)) - float(cam.limit_right)) > 1.0:
			push_error("FAIL desired_limit_right should be static (x=%s)" % x)
			quit(1)
			return
	print("PASS east limit is static and frames the Mid-East Dig Front tip")

	# West, top and bottom limits pad past the stand extents.
	if float(cam.limit_left) > HollowLayout.HIGH_WEST_DIG_LEFT - pad.x:
		push_error("FAIL limit_left=%s does not pad past the west dig tip" % cam.limit_left)
		quit(1)
		return
	if float(cam.limit_top) > HollowLayout.VAULTWARD_Y - pad.y:
		push_error("FAIL limit_top=%s hides the Vaultward line" % cam.limit_top)
		quit(1)
		return
	if float(cam.limit_bottom) < HollowLayout.BOTTOM_WEST_LOWER_Y + pad.y:
		push_error("FAIL limit_bottom=%s hides the lowest deck" % cam.limit_bottom)
		quit(1)
		return
	print("PASS west / top / bottom limits pad past the extents")

	# The map is symmetric: the camera's reach past each flank tip matches.
	var west_reach := HollowLayout.HIGH_WEST_DIG_LEFT - float(cam.limit_left)
	var east_reach := float(cam.limit_right) - HollowLayout.EAST_FLANK_RIGHT
	if absf(west_reach - east_reach) > 64.0:
		push_error("FAIL camera reach past the flank tips differs: west %s vs east %s" % [west_reach, east_reach])
		quit(1)
		return
	print("PASS camera reaches equally past both flank tips")

	print("ALL TESTS PASSED")
	quit(0)
