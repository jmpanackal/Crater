extends SceneTree
## Materials HUD text updates live — against Storage (Build Bible Spec 11),
## the canon owner of carried Materials (replaces the retired Resources
## wallet; see salvage_hud.gd, already rewritten to read Storage).


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var storage: Node = root.get_node_or_null("Storage")
	if storage == null:
		push_error("FAIL Storage missing")
		quit(1)
		return

	storage.reset_all()
	var label := Label.new()
	label.set_script(load("res://salvage_hud.gd"))
	root.add_child(label)

	if str(label.text) != "Materials: 0":
		push_error("FAIL initial '%s'" % label.text)
		quit(1)
		return

	storage.deposit_material(&"sutral", 2)
	if str(label.text) != "Materials: Sutral 2":
		push_error("FAIL after deposit '%s'" % label.text)
		quit(1)
		return

	storage.reset_all()
	print("SALVAGE_HUD_TESTS_PASSED")
	quit(0)
