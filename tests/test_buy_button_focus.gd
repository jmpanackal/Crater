extends SceneTree
## Requisition controls never take keyboard focus; diversion is world-only.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame
	var packed: PackedScene = load("res://main.tscn")
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var hud: Node = scene.get_node("UI/UpgradePanel")
	var button: Button = scene.get_node("UI/UpgradePanel/Margin/Content/RequisitionExpandHint") as Button
	if button == null or button.focus_mode != Control.FOCUS_NONE:
		push_error("FAIL requisition button focus")
		quit(1)
		return
	if scene.get_node_or_null("UI/TheftShopPanel") != null or InputMap.has_action("steal_upgrade"):
		push_error("FAIL remote steal UI or hotkey remains")
		quit(1)
		return
	hud.open_requisition()
	await process_frame
	if not (scene.get_node("UI/RequisitionPanel") as CanvasItem).visible:
		push_error("FAIL requisition did not open")
		quit(1)
		return
	print("REQUISITION_FOCUS_TESTS_PASSED")
	quit(0)
