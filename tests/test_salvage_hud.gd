extends SceneTree
## Salvage HUD text updates live.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	if wallet == null:
		push_error("FAIL Resources missing")
		quit(1)
		return

	wallet.set_amount(wallet.SALVAGE, 0)
	var label := Label.new()
	label.set_script(load("res://salvage_hud.gd"))
	root.add_child(label)

	if str(label.text) != "Salvage: 0":
		push_error("FAIL initial '%s'" % label.text)
		quit(1)
		return

	wallet.add(wallet.SALVAGE, 2)
	if str(label.text) != "Salvage: 2":
		push_error("FAIL after add '%s'" % label.text)
		quit(1)
		return

	print("SALVAGE_HUD_TESTS_PASSED")
	quit(0)
