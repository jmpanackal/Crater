extends SceneTree
## Canon HUD shows Materials, civic phase, qualitative Trust, and District condition.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	for path in ["UI/SalvageLabel", "UI/CycleLabel", "UI/TrustLabel", "UI/UpgradePanel/Margin/Content/DistrictConditionLabel"]:
		if scene.get_node_or_null(path) == null:
			push_error("FAIL missing canon HUD node %s" % path)
			quit(1)
			return
	if scene.get_node_or_null("UI/TheftShopPanel") != null or scene.get_node_or_null("UI/LiePromptPanel") != null:
		push_error("FAIL retired HUD panels remain")
		quit(1)
		return
	var hud: Node = scene.get_node("UI/UpgradePanel")
	hud.open_requisition()
	await process_frame
	if not (scene.get_node("UI/RequisitionPanel") as CanvasItem).visible:
		push_error("FAIL requisition modal did not open")
		quit(1)
		return
	print("DISPLAY_HUD_TESTS_PASSED")
	quit(0)
