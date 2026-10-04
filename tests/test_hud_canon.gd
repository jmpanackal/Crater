extends SceneTree
## The HUD the canon describes (mechanics-canon section 55, the invisible interface): small, with the Pulse lamps, the
## Rig sockets and the stamina bar always on; the old top-left stack and district chip gone; Trust and the Rig as
## panels you open. Standing shows a qualitative state and reasons, never a raw number; the Rig panel mounts Gear only
## at a station and says why when it cannot.

const StationScript := preload("res://rig_station.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failed = true
	push_error("FAIL " + msg)


func _run() -> void:
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in range(5):
		await process_frame
	for path in ["UI/Hud/Clock/PulseLamps", "UI/Hud/Clock/PhaseName", "UI/Hud/Hotbar", "UI/Hud/Vitals/Stamina", "UI/Hud/Prompt", "UI/StandingPanel", "UI/RigPanel"]:
		if scene.get_node_or_null(path) == null:
			_fail("missing HUD piece %s" % path)
	for legacy in ["UI/PrimaryHud", "UI/SalvageLabel", "UI/CycleLabel", "UI/TrustLabel", "UI/UpgradePanel"]:
		var n := scene.get_node_or_null(legacy) as CanvasItem
		if n != null and n.visible:
			_fail("the old HUD stack is still showing: %s" % legacy)
	# Standing: qualitative, no score
	var standing: Control = scene.get_node("UI/StandingPanel")
	root.get_node("Trust").submit_trust_event(&"work", 1.0, "You delivered a full load on time.")
	standing.open()
	await process_frame
	var texts := _all_text(standing)
	if not ("Accepted" in texts or "Doubted" in texts or "Relied on" in texts):
		_fail("Standing shows no qualitative state (%s)" % texts)
	if "You delivered a full load on time." not in texts:
		_fail("Standing does not list the reason")
	for word in texts.split(" "):
		if word.is_valid_int() or word.contains("/100"):
			_fail("Standing shows a raw number (%s)" % word)
			break
	standing.close()
	# Rig: refused away from a station, mounted at one
	var rig_panel: Control = scene.get_node("UI/RigPanel")
	var rig := root.get_node("Rig")
	rig.add_owned_gear(&"fracture_pick")
	rig_panel.open()
	await process_frame
	rig_panel._mount(&"fracture_pick")
	if rig.is_equipped(&"fracture_pick"):
		_fail("the Rig panel mounted Gear away from a station")
	await process_frame
	if "station" not in _all_text(rig_panel).to_lower():
		_fail("the Rig panel did not say why it refused")
	var station := Area2D.new()
	station.set_script(StationScript)
	scene.add_child(station) # a station only counts while it is in the tree
	rig.enter_station(station)
	rig_panel._mount(&"fracture_pick")
	if not rig.is_equipped(&"fracture_pick"):
		_fail("the Rig panel could not mount Gear at a station")
	rig_panel._unmount(0)
	if rig.is_equipped(&"fracture_pick"):
		_fail("the Rig panel could not unmount Gear at a station")
	rig.leave_station(station)
	station.queue_free()
	rig_panel.close()
	if _failed:
		quit(1)
		return
	print("PASS the HUD is the quiet canon one; Standing is qualitative; the Rig panel refits only at a station")
	quit(0)


func _all_text(node: Node) -> String:
	var out := ""
	if node is Label:
		out += (node as Label).text + " "
	if node is Button:
		out += (node as Button).text + " "
	for c in node.get_children():
		out += _all_text(c)
	return out
