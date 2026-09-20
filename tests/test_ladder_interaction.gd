extends SceneTree
## Climb prompts must be consistent across Hollow ladders and readable while
## overlapping (including tall shafts where the player stands far from the top).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player: CharacterBody2D = scene.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		push_error("FAIL Player missing")
		quit(1)
		return

	var ladders: Array[Node] = []
	for child in scene.get_node("Hollow").get_children():
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("hollow_climb.gd"):
			ladders.append(child)
	if ladders.size() != 3:
		push_error(
			"FAIL expected Chamber + WestStack + EastStack, got %s"
			% ladders.size()
		)
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderMid") != null:
		push_error("FAIL LadderMid must not sit beside the west stack")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderWestStack") == null:
		push_error("FAIL LadderWestStack missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderEastStack") == null:
		push_error("FAIL LadderEastStack missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderWorkerReturn") != null:
		push_error("FAIL redundant LadderWorkerReturn must be removed")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/LadderHomeToHeart") != null:
		push_error("FAIL redundant LadderHomeToHeart must be removed")
		quit(1)
		return

	var shared_hint := ""
	for ladder in ladders:
		var hint_text := str(ladder.get("hint_text"))
		if not hint_text.contains("W/S") or not hint_text.to_lower().contains("climb"):
			push_error("FAIL ladder %s hint is unclear: '%s'" % [ladder.name, hint_text])
			quit(1)
			return
		if shared_hint.is_empty():
			shared_hint = hint_text
		elif hint_text != shared_hint:
			push_error(
				"FAIL ladder hints inconsistent: '%s' vs '%s' (%s)"
				% [shared_hint, hint_text, ladder.name]
			)
			quit(1)
			return
	print("PASS all Hollow ladders share the same climb hint")

	var west: Area2D = scene.get_node_or_null("Hollow/LadderWestStack") as Area2D
	var chamber: Area2D = scene.get_node_or_null("Hollow/LadderChamber") as Area2D
	if west == null or chamber == null:
		push_error("FAIL LadderWestStack / LadderChamber missing")
		quit(1)
		return

	player.global_position = Vector2(
		HollowLayout.LADDER_WEST_X + 8.0,
		HollowLayout.WEST_LW_UPPER_Y - 32.0
	)
	player.velocity = Vector2.ZERO
	for _i in range(12):
		await physics_frame
	if not player.is_in_climb_zone():
		push_error("FAIL player not in west stack climb zone at Home Court landing")
		quit(1)
		return

	var hint: CanvasItem = west.get_node_or_null("ClimbHint") as CanvasItem
	if hint == null or not hint.visible:
		push_error("FAIL west stack climb hint not visible while overlapping")
		quit(1)
		return
	var hint_y: float = hint.global_position.y
	var player_y: float = player.global_position.y
	if absf(hint_y - player_y) > 96.0:
		push_error(
			"FAIL west stack climb hint stays at shaft top (hint_y=%s player_y=%s)"
			% [hint_y, player_y]
		)
		quit(1)
		return
	print("PASS tall ladder climb hint stays near the overlapping player")

	# Standing on solid deck beside the shaft must not keep the climb prompt.
	player.global_position = Vector2(
		HollowLayout.LADDER_WEST_OPEN_X - player.BODY_HEIGHT - 4.0,
		HollowLayout.WEST_LW_UPPER_Y - 32.0
	)
	player.velocity = Vector2.ZERO
	for _i in range(12):
		await physics_frame
	if player.is_in_climb_zone():
		push_error("FAIL sit-on-deck still keeps west stack climb prompt")
		quit(1)
		return
	print("PASS solid deck beside shaft does not keep climb prompt")

	print("ALL TESTS PASSED")
	quit(0)
