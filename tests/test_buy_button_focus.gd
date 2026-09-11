extends SceneTree
## Siphon buttons have no keyboard focus; shop opens with U; click buys only in Hollow.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if wallet == null or upgrades == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return
	if community:
		community.set_paused(true)
		community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	upgrades.set_level(upgrades.DIG_YIELD, 0)
	upgrades.set_siphon_station_open(true)
	wallet.set_amount(wallet.SALVAGE, 50)

	var packed: PackedScene = load("res://main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var panel: CanvasItem = scene.get_node("UI/UpgradePanel")
	var shop_panel: CanvasItem = scene.get_node("UI/SiphonShopPanel") as CanvasItem
	var siphon_list: Node = scene.get_node("UI/SiphonShopPanel/Margin/VBox/SiphonList")
	var button: Button = siphon_list.get_node_or_null("dig_yield") as Button
	if button == null:
		for child in siphon_list.get_children():
			if child is Button and str(child.name) == "dig_yield":
				button = child
				break
	if button == null:
		push_error("FAIL dig_yield siphon button missing")
		quit(1)
		return

	if button.focus_mode != Control.FOCUS_NONE:
		push_error("FAIL focus_mode")
		quit(1)
		return

	button.grab_focus()
	if button.has_focus():
		push_error("FAIL button grabbed focus")
		quit(1)
		return

	# Hollow chip visible; shop modal starts closed.
	if not panel.visible:
		push_error("FAIL siphon UI hidden while station open")
		quit(1)
		return
	if shop_panel.visible:
		push_error("FAIL shop modal open by default")
		quit(1)
		return

	var level_before: int = upgrades.get_level(upgrades.DIG_YIELD)

	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	root.get_viewport().push_input(accept)
	await process_frame

	if upgrades.get_level(upgrades.DIG_YIELD) != level_before:
		push_error("FAIL ui_accept purchased")
		quit(1)
		return
	print("PASS jump does not siphon")

	# U opens the shop modal without purchasing.
	var buy := InputEventAction.new()
	buy.action = &"siphon_upgrade"
	buy.pressed = true
	root.get_viewport().push_input(buy)
	await process_frame
	if not shop_panel.visible:
		push_error("FAIL U did not open shop modal")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != level_before:
		push_error("FAIL U purchased instead of opening shop")
		quit(1)
		return
	print("PASS U opens siphon shop")

	button.pressed.emit()
	await process_frame
	if upgrades.get_level(upgrades.DIG_YIELD) != level_before + 1:
		push_error("FAIL click siphon")
		quit(1)
		return
	print("PASS click siphons in Hollow")

	# Second U closes shop without another purchase.
	level_before = upgrades.get_level(upgrades.DIG_YIELD)
	root.get_viewport().push_input(buy)
	await process_frame
	if shop_panel.visible:
		push_error("FAIL U did not close shop")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != level_before:
		push_error("FAIL closing shop via U purchased")
		quit(1)
		return
	print("PASS U toggles shop closed")

	# Leave Hollow: UI hides and U cannot open shop / siphon.
	upgrades.set_siphon_station_open(false)
	await process_frame
	if panel.visible or shop_panel.visible:
		push_error("FAIL UI still visible at dig site")
		quit(1)
		return
	level_before = upgrades.get_level(upgrades.DIG_YIELD)
	var salvage_before: int = wallet.get_amount(wallet.SALVAGE)
	root.get_viewport().push_input(buy)
	await process_frame
	if upgrades.get_level(upgrades.DIG_YIELD) != level_before or wallet.get_amount(wallet.SALVAGE) != salvage_before:
		push_error("FAIL siphon at dig site via U")
		quit(1)
		return
	if shop_panel.visible:
		push_error("FAIL shop opened at dig site")
		quit(1)
		return
	print("PASS dig site blocks siphon UI and U")

	print("SIPHON_UI_FOCUS_TESTS_PASSED")
	quit(0)
