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
	if ladders.size() < 2:
		push_error("FAIL expected at least Chamber + WorkerReturn ladders, got %s" % ladders.size())
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

	var worker: Area2D = scene.get_node_or_null("Hollow/LadderWorkerReturn") as Area2D
	var chamber: Area2D = scene.get_node_or_null("Hollow/LadderChamber") as Area2D
	if worker == null or chamber == null:
		push_error("FAIL LadderWorkerReturn / LadderChamber missing")
		quit(1)
		return

	# Stand at the bottom of the tall Worker Return shaft — prompt must still read.
	# Keep physics on so the climb Area can register overlap and sync the hint.
	player.global_position = Vector2(
		HollowLayout.LADDER_RETURN_X + 8.0,
		HollowLayout.LOWER_WORK_Y - 32.0
	)
	player.velocity = Vector2.ZERO
	for _i in range(12):
		await physics_frame
	if not player.is_in_climb_zone():
		push_error("FAIL player not in Worker Return climb zone at lower landing")
		quit(1)
		return

	var hint: CanvasItem = worker.get_node_or_null("ClimbHint") as CanvasItem
	if hint == null or not hint.visible:
		push_error("FAIL Worker Return climb hint not visible while overlapping")
		quit(1)
		return
	var hint_y: float = hint.global_position.y
	var player_y: float = player.global_position.y
	if absf(hint_y - player_y) > 96.0:
		push_error(
			"FAIL Worker Return climb hint stays at shaft top (hint_y=%s player_y=%s)"
			% [hint_y, player_y]
		)
		quit(1)
		return
	print("PASS tall ladder climb hint stays near the overlapping player")

	# Chamber ladder must expose the same prompt affordance when overlapping.
	player.global_position = Vector2(
		HollowLayout.LADDER_CHAMBER_X + 8.0,
		HollowLayout.CHAMBER_ALCOVE_Y - 32.0
	)
	player.velocity = Vector2.ZERO
	for _i in range(12):
		await physics_frame
	var chamber_hint: CanvasItem = chamber.get_node_or_null("ClimbHint") as CanvasItem
	if chamber_hint == null or not chamber_hint.visible:
		push_error("FAIL Chamber climb hint not visible while overlapping")
		quit(1)
		return
	if str((chamber_hint as Label).text) != shared_hint:
		push_error("FAIL Chamber hint text drifted from shared climb copy")
		quit(1)
		return
	print("PASS Chamber ladder shows the shared climb prompt")

	# Climb hitboxes must match the drawn ladder rails (not a shifted/wider ghost).
	for ladder in ladders:
		if not ladder.has_method("visual_rect") or not ladder.has_method("climb_hit_rect"):
			push_error("FAIL ladder %s missing visual_rect/climb_hit_rect helpers" % ladder.name)
			quit(1)
			return
		var visual: Rect2 = ladder.visual_rect()
		var hit: Rect2 = ladder.climb_hit_rect()
		if absf(hit.position.x - visual.position.x) > 1.0 or absf(hit.size.x - visual.size.x) > 1.0:
			push_error(
				"FAIL ladder %s hitbox X (%s,%s) does not match visual (%s,%s)"
				% [ladder.name, hit.position.x, hit.size.x, visual.position.x, visual.size.x]
			)
			quit(1)
			return
		# Top may extend slightly above the rails for upper-deck foot overlap.
		var top_slack := 48.0
		if hit.position.y > visual.position.y + 1.0:
			push_error(
				"FAIL ladder %s hitbox starts below visual top (hit_y=%s visual_y=%s)"
				% [ladder.name, hit.position.y, visual.position.y]
			)
			quit(1)
			return
		if hit.position.y < visual.position.y - top_slack:
			push_error(
				"FAIL ladder %s hitbox extends too far above visual (hit_y=%s visual_y=%s)"
				% [ladder.name, hit.position.y, visual.position.y]
			)
			quit(1)
			return
		var hit_bottom := hit.position.y + hit.size.y
		var visual_bottom := visual.position.y + visual.size.y
		if absf(hit_bottom - visual_bottom) > 1.0:
			push_error(
				"FAIL ladder %s hitbox bottom=%s does not match visual bottom=%s"
				% [ladder.name, hit_bottom, visual_bottom]
			)
			quit(1)
			return
	print("PASS ladder climb hitboxes match visual rails")

	print("LADDER_INTERACTION_TESTS_PASSED")
	scene.queue_free()
	await process_frame
	quit(0)
