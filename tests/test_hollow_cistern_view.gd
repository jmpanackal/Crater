extends SceneTree
## The Cistern's pressure basin (hall H_CI) is dressed with tanks whose fill follows the Cistern's condition:
## fuller when comfortable, lower when strained or short, nearly empty when critical.


const View := preload("res://hollow_cistern_view.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failed = true
	push_error("FAIL " + msg)


func _run() -> void:
	var order := [&"comfortable", &"stable", &"strained", &"shortage", &"critical"]
	var last := 2.0
	for c in order:
		var f := View.fill_for(c)
		if f >= last or f <= 0.0:
			_fail("fill for %s (%s) should be above 0 and below the previous condition's" % [str(c), f])
		last = f
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in range(5):
		await process_frame
	var view := scene.find_child("CisternBasin", true, false)
	if view == null:
		_fail("no CisternBasin view was built")
	else:
		var bus := root.get_node("EventBus")
		bus.district_changed.emit(&"cistern", &"critical")
		if absf(view.current_fill() - View.fill_for(&"critical")) > 0.001:
			_fail("the basin did not follow a critical Cistern (fill %s)" % view.current_fill())
		bus.district_changed.emit(&"glowbeds", &"comfortable")
		if absf(view.current_fill() - View.fill_for(&"critical")) > 0.001:
			_fail("the basin reacted to another district's condition")
	if _failed:
		quit(1)
		return
	print("PASS the Cistern basin is dressed and its tanks follow the Cistern's condition")
	quit(0)
