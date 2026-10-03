extends SceneTree
## Walk the opening route with real input: Home Court -> west down the Bottom-West stairs to
## the First Expansion Gallery and back, then up the Worker Stair and the Allotment/Wickwork
## ladders to Mid Heart, over the Ritual deck and on to the Mid-East Landing.


var _failed := false


func _init() -> void:
	call_deferred("_run")


## Hold `action` until `pred` is true or `max_frames` pass. Fails the test on timeout.
func _hold_until(player: CharacterBody2D, action: String, pred: Callable, max_frames: int, what: String) -> void:
	Input.action_press(action)
	var ok := false
	var dir := -1.0 if action == "ui_left" else 1.0
	for _frame in range(max_frames):
		await physics_frame
		# a stair opening in the street ahead (it is open, with no covering): jump it like a player would
		if player.is_on_floor():
			var feet_y := player.global_position.y + 32.0
			for h in HollowMap.stair_holes():
				var ahead_x := player.global_position.x + dir * 24.0
				if absf(float(h["y"]) - feet_y) < 8.0 and ahead_x >= float(h["x0"]) - 8.0 and ahead_x < float(h["x1"]) and _street_over(ahead_x, feet_y):
					Input.action_press("ui_accept")
					await physics_frame
					Input.action_release("ui_accept")
					break
		if pred.call():
			ok = true
			break
	Input.action_release(action)
	for _frame in range(16):
		await physics_frame
	if ok:
		print("PASS %s" % what)
	else:
		_failed = true
		push_error("FAIL %s (stopped at %s)" % [what, str(player.global_position)])


## True when a street (run piece) passes over x at this deck height: only then is a stair opening a gap to jump.
func _street_over(x: float, y: float) -> bool:
	for p in HollowMap.deck_pieces():
		if absf(float(p["y"]) - y) < 0.5 and x >= float(p["x0"]) and x <= float(p["x1"]):
			return true
	return false


func _on(player: CharacterBody2D, x: float, deck_y: float, slop: float = 24.0) -> bool:
	return absf(player.global_position.x - x) < slop and absf(player.global_position.y - (deck_y - 32.0)) < 8.0 and player.is_on_floor()


func _climb(player: CharacterBody2D, ladder: Area2D, from_y: float, to_y: float, action: String, what: String) -> void:
	var lx := ladder.position.x
	player.global_position = Vector2(lx - 4.0, from_y - 32.0)
	player.velocity = Vector2.ZERO
	player.enter_climb_zone(ladder)
	await _hold_until(player, action, func() -> bool: return player.is_on_floor() and not player.is_climbing() and absf(player.global_position.y - (to_y - 32.0)) < 8.0, 1500, what)


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var player: CharacterBody2D = scene.get_node("Player")
	var st: Node = scene.get_node("Hollow/Structures")
	for _frame in range(12):
		await physics_frame
	if player.position.distance_to(HollowLayout.player_spawn_point()) > 2.0:
		push_error("FAIL Home Court spawn is obstructed")
		quit(1)
		return

	var L8 := HollowLayout.WEST_LW_UPPER_Y

	# West: Home Court -> Dispatch -> down S_BW1 -> Approach -> down S_BW2 -> First Expansion Gallery.
	await _hold_until(player, "ui_left", func() -> bool: return _on(player, -1590.0, L8, 30.0), 2000, "Home Court walks west to the Dispatch Yard edge")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_left", func() -> bool: return _on(player, -3000.0, HollowLayout.WEST_LW_LOWER_Y, 60.0), 2000, "Dispatch Yard descends S_BW1 onto the Bottom-West Approach")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_left", func() -> bool: return _on(player, -5600.0, HollowLayout.BOTTOM_WEST_UPPER_Y, 60.0), 3000, "Approach descends S_BW2 into the First Expansion Gallery")
	if _failed:
		quit(1)
		return

	# ... and back.
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, -1500.0, L8, 40.0), 4000, "gallery climbs back up both stairs to the Dispatch Yard")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, 560.0, L8, 40.0), 2000, "Dispatch Yard walks east past Home Court to the Worker Stair foot")
	if _failed:
		quit(1)
		return

	# East: the Worker Stair up to the Allotment street, then the ladder shortcuts to Wickwork.
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, 1260.0, HollowLayout.MID_ALLOT_LOWER_Y, 40.0), 1200, "the Worker Stair (S_LW) climbs to the Allotment street")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_left", func() -> bool: return _on(player, -440.0, HollowLayout.MID_ALLOT_LOWER_Y, 40.0), 1500, "Allotment street walks west to the LAD_AL ladder")
	if _failed:
		quit(1)
		return
	await _climb(player, st.get_node("LAD_AL"), HollowLayout.MID_ALLOT_LOWER_Y, HollowLayout.MID_ALLOT_UPPER_Y, "ui_up", "LAD_AL climbs to the upper Allotments")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, -32.0, HollowLayout.MID_ALLOT_UPPER_Y, 24.0), 400, "upper Allotments walks east to LAD_AL2")
	if _failed:
		quit(1)
		return
	await _climb(player, st.get_node("LAD_AL2"), HollowLayout.MID_ALLOT_UPPER_Y, HollowLayout.WICK_LOWER_Y, "ui_up", "LAD_AL2 climbs to Wickwork's lower bays")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_left", func() -> bool: return _on(player, -672.0, HollowLayout.WICK_LOWER_Y, 24.0), 400, "lower bays walk west to LAD_WK5")
	if _failed:
		quit(1)
		return
	await _climb(player, st.get_node("LAD_WK5"), HollowLayout.WICK_LOWER_Y, HollowLayout.WICK_Y, "ui_up", "LAD_WK5 climbs to Wickwork's street")
	if _failed:
		quit(1)
		return

	# Mid Heart: West Exchange -> up over the Ritual deck -> down -> East Service -> Mid-East Landing.
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, HollowLayout.PIT_LEFT + 160.0, HollowLayout.HEART_Y, 24.0), 1200, "Wickwork street runs onto Mid Heart's West Exchange")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, HollowLayout.HEART_MID_X, HollowLayout.RITUAL_Y, 24.0), 1200, "the crossing climbs over the raised Ritual deck")
	if _failed:
		quit(1)
		return
	await _hold_until(player, "ui_right", func() -> bool: return _on(player, HollowLayout.PIT_RIGHT + 160.0, HollowLayout.HEART_Y, 24.0), 1200, "the crossing descends to the East Service raft and the Mid-East Landing")
	if _failed:
		quit(1)
		return

	print("HOME_COURT_NAVIGATION_PASSED")
	quit(0)
