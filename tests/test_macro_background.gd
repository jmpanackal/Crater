extends SceneTree

const Macro := preload("res://hollow_macro_background.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var background: Node2D = scene.get_node("Hollow/MacroBackground")
	# Capture play defaults BEFORE enabling guides for overlay readability checks.
	var guides_default_off := not bool(background.show_guides_in_game)
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
	for deck in HollowLayout.expansion_deck_rects():
		if not Macro.WORLD_BOUNDS.has_point(Vector2(deck.x, deck.z)) or not Macro.WORLD_BOUNDS.has_point(Vector2(deck.y, deck.z)):
			push_error("FAIL background does not cover playable expansion decks")
			quit(1)
			return
	var lifts := Macro.transport_guides()
	if (
		lifts.size() != 3
		or lifts[0].stops.back() != HollowLayout.WICK_Y
		or lifts[1].stops.front() != HollowLayout.UPPER_RES_Y
		or lifts[1].stops.back() != HollowLayout.CISTERN_Y
		or lifts[2].stops.front() != HollowLayout.HEART_Y
	):
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
	# Scale plan: Mouth void is x 1440..4960 (704 px ~1/5 world). East wall starts at PIT_RIGHT.
	if absf(Macro.MOUTH_BOUNDS.size.x - (HollowLayout.PIT_RIGHT - HollowLayout.PIT_LEFT)) > 0.5:
		push_error("FAIL Mouth width drifted from PIT_LEFT..PIT_RIGHT")
		quit(1)
		return
	if absf(Macro.MOUTH_BOUNDS.size.x - 3520.0) > 0.5:
		push_error("FAIL Mouth width must match scale plan (1440..4960 => 3520), got %s" % Macro.MOUTH_BOUNDS.size.x)
		quit(1)
		return
	if Macro.MOUTH_BOUNDS.size.x / Macro.WORLD_BOUNDS.size.x < 0.16:
		push_error("FAIL Mouth must be a prominent ~1/6+ of world width (got ratio %s)" % (Macro.MOUTH_BOUNDS.size.x / Macro.WORLD_BOUNDS.size.x))
		quit(1)
		return
	for region in Macro.district_guides():
		var name: String = str(region.name)
		var is_east_wall := (
			name.begins_with("Mid-East")
			or name.begins_with("Glowbeds")
			or name.begins_with("Ashram Heights / east")
			or name.begins_with("Cistern")
			or name.begins_with("Lower-East")
			or name.begins_with("Seep")
		)
		if is_east_wall and region.bounds.position.x < HollowLayout.PIT_RIGHT - 0.5:
			push_error(
				"FAIL east district '%s' overlaps Mouth (x0=%s)"
				% [name, region.bounds.position.x]
			)
			quit(1)
			return
	# Play must never show aqua planning-guide fills in the Mouth / world void.
	# show_guides_in_game defaults off; Mid Heart is the Mouth crossing band.
	if not guides_default_off:
		push_error("FAIL show_guides_in_game must default off for normal play")
		quit(1)
		return
	var mid_heart_bounds := Rect2()
	for region in Macro.district_guides():
		if str(region.name).begins_with("Mid Heart"):
			mid_heart_bounds = region.bounds
			break
	if mid_heart_bounds.size.x < Macro.MOUTH_BOUNDS.size.x - 1.0:
		push_error(
			"FAIL Mid Heart planning guide must span Mouth (w=%s mouth=%s)"
			% [mid_heart_bounds.size.x, Macro.MOUTH_BOUNDS.size.x]
		)
		quit(1)
		return
	if mid_heart_bounds.size.y > 640.0:
		push_error(
			"FAIL Mid Heart guide must stay a thin deck band (h=%s), not a Mouth fill"
			% mid_heart_bounds.size.y
		)
		quit(1)
		return
	if absf(mid_heart_bounds.position.x - HollowLayout.PIT_LEFT) > 0.5:
		push_error("FAIL Mid Heart guide must start at Mouth west lip")
		quit(1)
		return
	if absf(mid_heart_bounds.end.x - HollowLayout.PIT_RIGHT) > 0.5:
		push_error("FAIL Mid Heart guide must end at Mouth east lip")
		quit(1)
		return
	# GUIDE_COLOR is the aqua the user reported — stay translucent (outlines only).
	if Macro.GUIDE_COLOR.a >= 0.9:
		push_error("FAIL GUIDE_COLOR must stay translucent (not opaque aqua fill)")
		quit(1)
		return
	print("PASS full background covers all districts and existing playable decks")
	print("PASS Mouth remains open, three canonical transport spans, non-colliding guides")
	print("PASS Mouth width matches docs; east wall guides start at PIT_RIGHT")
	print("PASS in-game aqua planning guides stay off; Mid Heart spans Mouth as crossing")
	scene.queue_free()
	await process_frame
	quit(0)
