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
	for child in scene.get_node("Hollow/Structures").get_children():
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("hollow_climb.gd"):
			ladders.append(child)
	if ladders.size() != HollowMap.ladders().size():
		push_error("FAIL expected %s ladders built from HollowMap, got %s" % [HollowMap.ladders().size(), ladders.size()])
		quit(1)
		return
	for removed in ["Hollow/LadderWestStack", "Hollow/LadderEastStack", "Hollow/LadderChamber", "Hollow/LadderWorkerReturn", "Hollow/LadderHomeToHeart"]:
		if scene.get_node_or_null(removed) != null:
			push_error("FAIL old hand-placed ladder %s must stay removed" % removed)
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
			push_error("FAIL ladder hints inconsistent: '%s' vs '%s' (%s)" % [shared_hint, hint_text, ladder.name])
			quit(1)
			return
	print("PASS all Hollow ladders share the same climb hint")

	var ladder: Area2D = scene.get_node_or_null("Hollow/Structures/LAD_WK5") as Area2D
	if ladder == null:
		push_error("FAIL LAD_WK5 missing")
		quit(1)
		return
	var open_x := -640.0
	var ladder_x := open_x + (HollowLayout.LADDER_OPENING - HollowLayout.LADDER_WIDTH) * 0.5

	player.global_position = Vector2(ladder_x + 8.0, HollowLayout.WICK_LOWER_Y - 32.0)
	player.velocity = Vector2.ZERO
	for _i in range(12):
		await physics_frame
	if not player.is_in_climb_zone():
		push_error("FAIL player not in the climb zone standing at the ladder's foot")
		quit(1)
		return

	var hint: CanvasItem = ladder.get_node_or_null("ClimbHint") as CanvasItem
	if hint == null or not hint.visible:
		push_error("FAIL climb hint not visible while overlapping")
		quit(1)
		return
	var hint_y: float = hint.global_position.y
	var player_y: float = player.global_position.y
	if absf(hint_y - player_y) > 96.0:
		push_error("FAIL climb hint stays at the shaft top (hint_y=%s player_y=%s)" % [hint_y, player_y])
		quit(1)
		return
	print("PASS tall ladder climb hint stays near the overlapping player")

	# Standing on solid deck beside the shaft must not keep the climb prompt.
	player.global_position = Vector2(open_x - player.BODY_HEIGHT - 4.0, HollowLayout.WICK_LOWER_Y - 32.0)
	player.velocity = Vector2.ZERO
	for _i in range(12):
		await physics_frame
	if player.is_in_climb_zone():
		push_error("FAIL standing beside the shaft still keeps the climb prompt")
		quit(1)
		return
	print("PASS solid deck beside shaft does not keep climb prompt")

	print("ALL TESTS PASSED")
	quit(0)
