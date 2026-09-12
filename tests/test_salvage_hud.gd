extends SceneTree
## Materials HUD text updates live.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	if wallet == null:
		push_error("FAIL Resources missing")
		quit(1)
		return

	wallet.reset_all()
	var label := Label.new()
	label.set_script(load("res://salvage_hud.gd"))
	root.add_child(label)

	if str(label.text) != "Materials: 0":
		push_error("FAIL initial '%s'" % label.text)
		quit(1)
		return

	wallet.add(wallet.SPOREMEAL, 2)
	if str(label.text) != "Materials: Sporemeal 2":
		push_error("FAIL after add '%s'" % label.text)
		quit(1)
		return

	print("SALVAGE_HUD_TESTS_PASSED")
	quit(0)
