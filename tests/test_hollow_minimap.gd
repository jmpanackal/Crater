extends SceneTree
## Hollow minimap: default-visible corner overlay, M toggles, player + orientation markers.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var minimap: Node = scene.get_node_or_null("UI/HollowMinimap")
	if minimap == null:
		push_error("FAIL UI/HollowMinimap missing")
		quit(1)
		return
	if not (minimap is CanvasItem) or not (minimap as CanvasItem).visible:
		push_error("FAIL minimap must default visible")
		quit(1)
		return
	if not minimap.has_method("world_to_map") or not minimap.has_method("toggle") or not minimap.has_method("orientation_markers"):
		push_error("FAIL minimap missing world_to_map / toggle / orientation_markers")
		quit(1)
		return

	var Macro := load("res://hollow_macro_background.gd")
	var map_bounds: Rect2 = minimap.call("map_world_bounds")
	var content_bounds: Rect2 = minimap.call("map_content_bounds")
	if map_bounds != content_bounds:
		push_error("FAIL minimap extent must track tight content bounds, not padded WORLD_BOUNDS")
		quit(1)
		return
	if map_bounds == Macro.WORLD_BOUNDS:
		push_error("FAIL minimap must not use full WORLD_BOUNDS padding (scale looks tiny)")
		quit(1)
		return
	if not Macro.WORLD_BOUNDS.encloses(map_bounds):
		push_error("FAIL content bounds drifted outside Macro WORLD_BOUNDS")
		quit(1)
		return

	var player: Node2D = scene.get_node_or_null("Player") as Node2D
	if player == null:
		push_error("FAIL Player missing")
		quit(1)
		return
	player.global_position = HollowLayout.player_spawn_point()
	await process_frame
	var local: Vector2 = minimap.call("world_to_map", player.global_position)
	var size: Vector2 = (minimap as Control).size
	if local.x < 0.0 or local.y < 0.0 or local.x > size.x or local.y > size.y:
		push_error("FAIL spawn maps outside minimap panel: %s in %s" % [local, size])
		quit(1)
		return

	# Dig Front sits east of civic edge — must still land on the panel.
	var dig := Vector2((HollowLayout.MID_EAST_DIG_FRONT.x + HollowLayout.MID_EAST_DIG_FRONT.y) * 0.5, HollowLayout.HEART_Y)
	var dig_local: Vector2 = minimap.call("world_to_map", dig)
	if dig_local.x <= local.x:
		push_error("FAIL Dig Front should map east of Home Court spawn")
		quit(1)
		return
	if dig_local.x < 0.0 or dig_local.x > size.x:
		push_error("FAIL Dig Front maps outside panel: %s" % dig_local)
		quit(1)
		return

	var markers: Array = minimap.call("orientation_markers")
	var names: PackedStringArray = PackedStringArray()
	for entry in markers:
		names.append(str(entry.get("name", "")))
	for required in [
		"Mouth",
		"Home Court",
		"Ashram",
		"Ashram East",
		"High-West Dig",
		"Glowbeds",
		"Wickwork",
		"Mid Heart",
		"Allotments",
		"Dig Front",
		"Lower-East",
		"Bottom-West",
		"Cistern",
		"Seep",
	]:
		if not required in names:
			push_error("FAIL missing orientation marker: %s" % required)
			quit(1)
			return
	# Every labelled marker (except the Mouth) sits exactly on a zone footprint.
	for entry in markers:
		if str(entry.get("name", "")) == "Mouth":
			continue
		var on_footprint := false
		for district in Macro.district_guides():
			if entry.get("bounds", Rect2()) == district.bounds:
				on_footprint = true
				break
		if not on_footprint:
			push_error("FAIL orientation marker '%s' is not on a zone footprint" % entry.get("name", ""))
			quit(1)
			return
	print("PASS every minimap district section is named")

	# Mouth must read as open void on the minimap — not an opaque black plug.
	if not minimap.has_method("mouth_void_color") or not minimap.has_method("district_draw_bounds"):
		push_error("FAIL minimap missing mouth_void_color / district_draw_bounds")
		quit(1)
		return
	var mouth_color: Color = minimap.call("mouth_void_color")
	if mouth_color.a >= 0.55:
		push_error("FAIL Mouth minimap fill must stay translucent void (a=%s)" % mouth_color.a)
		quit(1)
		return

	# East-wall district guides must not draw into the Mouth band.
	var mouth_world: Rect2 = Macro.MOUTH_BOUNDS
	if mouth_world.size.x < 640.0:
		push_error("FAIL minimap Mouth band too narrow (w=%s) — scale plan needs prominent void" % mouth_world.size.x)
		quit(1)
		return
	for district in Macro.district_guides():
		var name: String = str(district.name)
		var is_east_wall := (
			name.begins_with("Mid-East")
			or name.begins_with("Glowbeds")
			or name.begins_with("Ashram Heights / east")
			or name.begins_with("Cistern")
			or name.begins_with("Lower-East")
			or name.begins_with("Seep")
		)
		if not is_east_wall:
			continue
		var drawn: Rect2 = minimap.call("district_draw_bounds", district.bounds)
		if drawn.size.x <= 0.0 or drawn.size.y <= 0.0:
			push_error("FAIL east district draw bounds empty: %s" % name)
			quit(1)
			return
		# World-space clip: drawn rect must not enter Mouth interior.
		if drawn.position.x < HollowLayout.PIT_RIGHT - 0.5:
			push_error(
				"FAIL east district '%s' draws into Mouth (x0=%s, PIT_RIGHT=%s)"
				% [name, drawn.position.x, HollowLayout.PIT_RIGHT]
			)
			quit(1)
			return
	# Mid Heart is the primary Mouth crossing — minimap draws the full west→east band.
	var mid_heart_guide: Rect2
	for district in Macro.district_guides():
		if str(district.name).begins_with("Mid Heart"):
			mid_heart_guide = district.bounds
			break
	var mid_drawn: Rect2 = minimap.call("district_draw_bounds", mid_heart_guide)
	if mid_drawn.size.x < mouth_world.size.x - 1.0:
		push_error(
			"FAIL Mid Heart minimap must span Mouth as the primary bridge (drawn_w=%s mouth_w=%s)"
			% [mid_drawn.size.x, mouth_world.size.x]
		)
		quit(1)
		return
	if mid_drawn.size.y > 128.0:
		push_error(
			"FAIL Mid Heart minimap must stay a thin deck band (h=%s), not a Mouth fill"
			% mid_drawn.size.y
		)
		quit(1)
		return
	# No district draw poly may cover the Mouth interior band except Mid Heart's
	# thin crossing band (west lip → east lip).
	var mouth_inner := Rect2(
		HollowLayout.PIT_LEFT + 8.0,
		mouth_world.position.y + 8.0,
		mouth_world.size.x - 16.0,
		mouth_world.size.y - 16.0
	)
	for district in Macro.district_guides():
		var name: String = str(district.name)
		var drawn: Rect2 = minimap.call("district_draw_bounds", district.bounds)
		if drawn.size.x <= 0.0 or drawn.size.y <= 0.0:
			continue
		if name.begins_with("Mid Heart") or name.begins_with("Upper Heart"):
			continue
		if drawn.intersects(mouth_inner):
			push_error(
				"FAIL district '%s' draw bounds intersect Mouth void %s ∩ %s"
				% [name, drawn, mouth_inner]
			)
			quit(1)
			return
	# Scale: map content must fill the panel tightly (aspect-correct). Large empty
	# margins from letterboxing WORLD_BOUNDS padding made rooms look tiny/clustered.
	if not minimap.has_method("map_content_fill_ratio"):
		push_error("FAIL minimap missing map_content_fill_ratio")
		quit(1)
		return
	var fill_ratio: float = float(minimap.call("map_content_fill_ratio"))
	if fill_ratio < 0.72:
		push_error(
			"FAIL minimap content fill too small (ratio=%s) — rooms look clustered with empty margin"
			% fill_ratio
		)
		quit(1)
		return
	# Labels: Home Court / Dispatch stay west of Mouth; Mouth label stays in band;
	# Mid Heart sits on the crossing (inside Mouth x-range).
	for entry in markers:
		var marker_name := str(entry.get("name", ""))
		var pos: Vector2 = entry.pos
		if marker_name in [
			"Home Court",
			"Wickwork",
			"Ashram",
			"High-West Dig",
			"Allotments",
			"Bottom-West",
		]:
			if pos.x >= HollowLayout.PIT_LEFT:
				push_error("FAIL %s label must stay west of Mouth (x=%s)" % [marker_name, pos.x])
				quit(1)
				return
		if marker_name in [
			"Dig Front",
			"Cistern",
			"Glowbeds",
			"Ashram East",
			"Lower-East",
			"Seep",
		]:
			if pos.x < HollowLayout.PIT_RIGHT:
				push_error("FAIL %s label sits in Mouth at x=%s" % [marker_name, pos.x])
				quit(1)
				return
		if marker_name == "Mouth":
			if pos.x < HollowLayout.PIT_LEFT or pos.x > HollowLayout.PIT_RIGHT:
				push_error("FAIL Mouth label must sit inside Mouth band")
				quit(1)
				return
		if marker_name == "Mid Heart":
			if pos.x < HollowLayout.PIT_LEFT or pos.x > HollowLayout.PIT_RIGHT:
				push_error("FAIL Mid Heart label must sit on the Mouth crossing")
				quit(1)
				return
	print("PASS minimap Mouth void + Mid Heart spans as primary bridge")
	print("PASS minimap scale fills panel; labels stay off Mouth overlaps")

	# Landmark labels must be centered in their section bounds (not right-aligned
	# to a floating point marker that clips box edges).
	if not minimap.has_method("orientation_label_rect"):
		push_error("FAIL minimap missing orientation_label_rect for section centering")
		quit(1)
		return
	for entry in markers:
		var marker_name := str(entry.get("name", ""))
		if not entry.has("bounds"):
			push_error("FAIL orientation marker '%s' must expose section bounds" % marker_name)
			quit(1)
			return
		var section: Rect2 = entry.bounds
		if section.size.x <= 0.0 or section.size.y <= 0.0:
			push_error("FAIL orientation marker '%s' has empty section bounds" % marker_name)
			quit(1)
			return
		var label_rect: Rect2 = minimap.call("orientation_label_rect", entry)
		var section_map_a: Vector2 = minimap.call("world_to_map", section.position)
		var section_map_b: Vector2 = minimap.call("world_to_map", section.end)
		var section_map := Rect2(
			Vector2(minf(section_map_a.x, section_map_b.x), minf(section_map_a.y, section_map_b.y)),
			Vector2(absf(section_map_b.x - section_map_a.x), absf(section_map_b.y - section_map_a.y))
		)
		if section_map.size.x < 4.0 or section_map.size.y < 4.0:
			continue
		var label_c := label_rect.get_center()
		var section_c := section_map.get_center()
		if absf(label_c.x - section_c.x) > 2.0:
			push_error(
				"FAIL '%s' label not horizontally centered in section (label=%s section=%s)"
				% [marker_name, label_c, section_c]
			)
			quit(1)
			return
		if absf(label_c.y - section_c.y) > 2.0:
			push_error(
				"FAIL '%s' label not vertically centered in section (label=%s section=%s)"
				% [marker_name, label_c, section_c]
			)
			quit(1)
			return
		if not section_map.grow(1.0).has_point(label_c):
			push_error(
				"FAIL '%s' label center escapes section bounds (label=%s section=%s)"
				% [marker_name, label_c, section_map]
			)
			quit(1)
			return
	print("PASS minimap section labels are centered in their bounds")

	minimap.call("toggle")
	await process_frame
	if (minimap as CanvasItem).visible:
		push_error("FAIL toggle should hide minimap")
		quit(1)
		return
	minimap.call("toggle")
	await process_frame
	if not (minimap as CanvasItem).visible:
		push_error("FAIL toggle should show minimap again")
		quit(1)
		return

	# M key path (action or raw key) must flip visibility.
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_M
	ev.physical_keycode = KEY_M
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
	if (minimap as CanvasItem).visible:
		push_error("FAIL M key should hide the minimap")
		quit(1)
		return

	print("HOLLOW_MINIMAP_TESTS_PASSED")
	quit(0)
