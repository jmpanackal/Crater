extends SceneTree

const Macro := preload("res://hollow_macro_background.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var background: Node2D = scene.get_node("Hollow/MacroBackground")
	background.show_guides_in_game = true
	await process_frame
	await process_frame
	if scene.has_node("Hollow/DepthBg") or scene.has_node("Hollow/RockBack"):
		push_error("FAIL old opening-only background remains")
		quit(1)
		return
	for region in Macro.district_guides():
		var bounds: Rect2 = region.bounds
		if not Macro.WORLD_BOUNDS.encloses(bounds) or region.level < bounds.position.y or region.level > bounds.end.y:
			push_error("FAIL region extent/level outside map: %s" % region.name)
			quit(1)
			return
	for deck in HollowLayout.opening_route_deck_rects():
		if not Macro.WORLD_BOUNDS.has_point(Vector2(deck.x, deck.z)) or not Macro.WORLD_BOUNDS.has_point(Vector2(deck.y, deck.z)):
			push_error("FAIL background does not cover the existing opening route")
			quit(1)
			return
	var lifts := Macro.transport_guides()
	if lifts.size() != 3 or lifts[0].stops.back() != HollowLayout.WICK_Y or lifts[1].stops.back() != HollowLayout.HEART_Y or lifts[2].stops.front() != HollowLayout.HEART_Y:
		push_error("FAIL the three distinct canonical transport spans drifted")
		quit(1)
		return
	var overlay := background.get_node_or_null("PlanningGuides")
	if overlay == null or overlay.z_index <= 0 or overlay.get_child_count(true) != 0 or overlay is CollisionObject2D:
		push_error("FAIL planning overlay must stay readable above terrain without adding collision")
		quit(1)
		return
	if Macro.MOUTH_BOUNDS.position.x != HollowLayout.PIT_LEFT or Macro.MOUTH_BOUNDS.end.x != HollowLayout.PIT_RIGHT:
		push_error("FAIL Mouth bounds differ from shared world metrics")
		quit(1)
		return
	print("PASS full background covers all districts and existing playable decks")
	print("PASS Mouth remains open, three canonical transport spans, non-colliding guides")
	scene.queue_free()
	await process_frame
	quit(0)
