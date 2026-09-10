extends SceneTree
## Display stretch + decluttered HUD assumptions.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var stretch_mode: String = str(ProjectSettings.get_setting("display/window/stretch/mode", ""))
	var stretch_aspect: String = str(ProjectSettings.get_setting("display/window/stretch/aspect", ""))
	var vw: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var vh: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	var tex_filter: int = int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1))
	var snap_2d: bool = bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", false))
	if stretch_mode != "canvas_items":
		push_error("FAIL stretch mode '%s'" % stretch_mode)
		quit(1)
		return
	if stretch_aspect != "expand":
		push_error("FAIL stretch aspect '%s'" % stretch_aspect)
		quit(1)
		return
	if vw < 640 or vh < 360:
		push_error("FAIL viewport size %dx%d" % [vw, vh])
		quit(1)
		return
	# 0 = Nearest (Godot CanvasItem.TextureFilter).
	if tex_filter != 0:
		push_error("FAIL default texture filter %d expected Nearest(0)" % tex_filter)
		quit(1)
		return
	if not snap_2d:
		push_error("FAIL snap_2d_transforms_to_pixel should be on for pixel art")
		quit(1)
		return
	print("PASS display stretch + viewport + nearest filter")

	var packed: PackedScene = load("res://main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	if scene.get_node_or_null("UI/StatusLabel") == null:
		push_error("FAIL StatusLabel missing")
		quit(1)
		return
	if scene.get_node_or_null("UI/UpgradePanel/HarvestLabel") != null:
		push_error("FAIL HarvestLabel still inside UpgradePanel")
		quit(1)
		return
	if scene.get_node_or_null("UI/JournalHud/Dimmer") == null:
		push_error("FAIL Journal Dimmer missing")
		quit(1)
		return
	if scene.get_node_or_null("UI/JournalHud/Panel/Margin/VBox/CloseButton") == null:
		push_error("FAIL Journal CloseButton missing")
		quit(1)
		return

	var journal: Node = scene.get_node("UI/JournalHud")
	if not journal.has_method("is_open") or journal.is_open():
		push_error("FAIL journal should start closed")
		quit(1)
		return
	journal.open()
	await process_frame
	if not journal.is_open():
		push_error("FAIL journal.open()")
		quit(1)
		return
	if not (scene.get_node("UI/JournalHud/Dimmer") as CanvasItem).visible:
		push_error("FAIL dimmer not visible when journal open")
		quit(1)
		return
	journal.close()
	await process_frame
	if journal.is_open():
		push_error("FAIL journal.close()")
		quit(1)
		return
	print("PASS journal modal open/close + dimmer")

	var farms: Label = scene.get_node("Hollow/DistrictFarms") as Label
	if farms.get_script() == null:
		push_error("FAIL district label missing soft script")
		quit(1)
		return
	if not farms.is_in_group("world_chrome"):
		push_error("FAIL district label not in world_chrome")
		quit(1)
		return
	print("PASS soft world labels")

	var upgrades: Node = root.get_node_or_null("Upgrades")
	if upgrades:
		upgrades.set_siphon_station_open(true)
		await process_frame
		await process_frame
		var panel: CanvasItem = scene.get_node("UI/UpgradePanel")
		if not panel.visible:
			push_error("FAIL UpgradePanel hidden in Hollow")
			quit(1)
			return
		var status: Label = scene.get_node("UI/StatusLabel")
		if not str(status.text).begins_with("Harvest"):
			push_error("FAIL status text '%s'" % status.text)
			quit(1)
			return
	print("PASS compact Hollow HUD hierarchy")

	var siphon_list: CanvasItem = scene.get_node("UI/UpgradePanel/SiphonList") as CanvasItem
	if siphon_list.visible:
		push_error("FAIL SiphonList should start collapsed until U")
		quit(1)
		return
	var hint: Label = scene.get_node_or_null("UI/UpgradePanel/SiphonExpandHint") as Label
	if hint == null or not hint.visible:
		push_error("FAIL SiphonExpandHint missing/hidden while collapsed")
		quit(1)
		return
	print("PASS siphon list collapsed by default")

	print("DISPLAY_HUD_TESTS_PASSED")
	quit(0)
