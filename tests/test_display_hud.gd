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

	if scene.get_node_or_null("UI/PrimaryHud") == null:
		push_error("FAIL PrimaryHud chrome missing")
		quit(1)
		return
	var primary: Control = scene.get_node("UI/PrimaryHud") as Control
	if primary.size.x > 280.0 or (primary.offset_right - primary.offset_left) > 280.0:
		push_error("FAIL PrimaryHud too wide (blocks Hollow)")
		quit(1)
		return
	if scene.get_node_or_null("UI/HarvestLabel") == null:
		push_error("FAIL HarvestLabel missing")
		quit(1)
		return
	if scene.get_node_or_null("UI/StandingLabel") == null:
		push_error("FAIL StandingLabel missing")
		quit(1)
		return
	if scene.get_node_or_null("UI/UpgradePanel/HarvestLabel") != null:
		push_error("FAIL HarvestLabel still inside UpgradePanel")
		quit(1)
		return

	# Harvest / Standing / Materials must be distinct non-overlapping rows.
	var mats: Control = scene.get_node("UI/SalvageLabel") as Control
	var harvest: Control = scene.get_node("UI/HarvestLabel") as Control
	var standing: Control = scene.get_node("UI/StandingLabel") as Control
	if mats == null or harvest == null or standing == null:
		push_error("FAIL primary HUD rows missing")
		quit(1)
		return
	var mats_r := mats.get_global_rect()
	var harv_r := harvest.get_global_rect()
	var stand_r := standing.get_global_rect()
	if mats_r.intersects(harv_r) or harv_r.intersects(stand_r) or mats_r.intersects(stand_r):
		push_error(
			"FAIL HUD status rows overlap mats=%s harvest=%s standing=%s"
			% [mats_r, harv_r, stand_r]
		)
		quit(1)
		return
	if harv_r.position.y < mats_r.end.y - 0.5:
		push_error("FAIL HarvestLabel not below Materials row")
		quit(1)
		return
	if stand_r.position.y < harv_r.end.y - 0.5:
		push_error("FAIL StandingLabel not below Harvest row")
		quit(1)
		return
	print("PASS HUD status rows non-overlapping")
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
		var panel: Control = scene.get_node("UI/UpgradePanel") as Control
		if not panel.visible:
			push_error("FAIL UpgradePanel hidden in Hollow")
			quit(1)
			return
		if panel.size.x > 280.0 or (panel.offset_right - panel.offset_left) > 280.0:
			push_error("FAIL Hollow chip too wide")
			quit(1)
			return
		var harvest_lbl: Label = scene.get_node("UI/HarvestLabel") as Label
		var standing_lbl: Label = scene.get_node("UI/StandingLabel") as Label
		if not str(harvest_lbl.text).begins_with("Harvest"):
			push_error("FAIL harvest text '%s'" % harvest_lbl.text)
			quit(1)
			return
		if not str(standing_lbl.text).begins_with("Standing"):
			push_error("FAIL standing text '%s'" % standing_lbl.text)
			quit(1)
			return
		if harvest_lbl.tooltip_text.strip_edges() == "" or standing_lbl.tooltip_text.strip_edges() == "":
			push_error("FAIL Harvest/Standing missing meaning tooltips")
			quit(1)
			return
		var cover: Label = scene.get_node("UI/UpgradePanel/Margin/Content/CoverLabel") as Label
		if cover == null or cover.tooltip_text.strip_edges() == "":
			push_error("FAIL CoverLabel missing meaning tooltip")
			quit(1)
			return
		# Districts + upgrade rows live in the shop modal — not the slim chip.
		if scene.get_node_or_null("UI/UpgradePanel/Margin/Content/DistrictToggle") != null:
			push_error("FAIL DistrictToggle should not live on Hollow chip")
			quit(1)
			return
		if scene.get_node_or_null("UI/UpgradePanel/Margin/Content/SiphonList") != null:
			var legacy: CanvasItem = scene.get_node("UI/UpgradePanel/Margin/Content/SiphonList") as CanvasItem
			if legacy.visible:
				push_error("FAIL inline SiphonList visible on chip")
				quit(1)
				return
	print("PASS compact Hollow HUD hierarchy")

	var shop_panel: CanvasItem = scene.get_node_or_null("UI/SiphonShopPanel") as CanvasItem
	var siphon_list: CanvasItem = scene.get_node_or_null("UI/SiphonShopPanel/Margin/VBox/SiphonList") as CanvasItem
	if shop_panel == null or siphon_list == null:
		push_error("FAIL SiphonShopPanel / SiphonList missing")
		quit(1)
		return
	if shop_panel.visible:
		push_error("FAIL SiphonShop should start collapsed until U")
		quit(1)
		return
	var hint: Control = scene.get_node_or_null("UI/UpgradePanel/Margin/Content/SiphonExpandHint") as Control
	if hint == null or not hint.visible:
		push_error("FAIL SiphonExpandHint missing/hidden while collapsed")
		quit(1)
		return
	if not ("Shop" in str(hint.get("text"))):
		push_error("FAIL SiphonExpandHint text '%s'" % hint.get("text"))
		quit(1)
		return

	var hud: Node = scene.get_node("UI/UpgradePanel")
	if hud.has_method("open_shop"):
		hud.open_shop()
		await process_frame
		if not shop_panel.visible:
			push_error("FAIL open_shop did not show modal")
			quit(1)
			return
		var district_toggle: BaseButton = scene.get_node_or_null(
			"UI/SiphonShopPanel/Margin/VBox/DistrictToggle"
		) as BaseButton
		if district_toggle == null or not district_toggle.visible:
			push_error("FAIL DistrictToggle missing in open shop")
			quit(1)
			return
		hud.close_shop()
		await process_frame
		if shop_panel.visible:
			push_error("FAIL close_shop left modal open")
			quit(1)
			return
	print("PASS siphon shop modal collapsed by default")

	var cam: Camera2D = scene.get_node("Player/Camera2D") as Camera2D
	if cam.limit_right > 1100:
		push_error("FAIL Hollow camera limit_right=%d exposes dig strip" % cam.limit_right)
		quit(1)
		return
	print("PASS Hollow camera hides dig strip")

	if ResourceLoader.exists("res://ui_style.gd") == false:
		push_error("FAIL ui_style.gd missing")
		quit(1)
		return
	print("PASS ui_style shared chrome")

	print("DISPLAY_HUD_TESTS_PASSED")
	quit(0)
