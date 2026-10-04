extends SceneTree
## The Pulse stands on the Ritual Raft at Mid Heart and its indicator lamps follow the civic phase. It is only
## a timekeeper in the picture: nothing here claims what it originally did (canon: OPEN).

const View := preload("res://hollow_pulse_view.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failed = true
	push_error("FAIL " + msg)


func _run() -> void:
	var lit := {}
	for p in [&"rousing", &"working", &"gathering", &"ritual"]:
		lit[p] = int(View.lamps_for(p)["lit"])
	if lit[&"rousing"] >= lit[&"working"] or lit[&"working"] >= lit[&"gathering"] or lit[&"gathering"] > lit[&"ritual"]:
		_fail("the lamps should light up through the civic day (%s)" % str(lit))
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in range(5):
		await process_frame
	var pulse := scene.find_child("Pulse", true, false)
	if pulse == null:
		_fail("no Pulse was built")
	else:
		var bus := root.get_node("EventBus")
		bus.phase_changed.emit(&"working", &"ritual")
		if int(pulse.current_lamps()["lit"]) != lit[&"ritual"]:
			_fail("the Pulse's lamps did not follow the phase change")
	if _failed:
		quit(1)
		return
	print("PASS the Pulse stands at Mid Heart and its lamps follow the civic phase")
	quit(0)
