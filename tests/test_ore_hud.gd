extends SceneTree
## Headless check: Ore HUD label text updates when Resources change.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	if wallet == null:
		push_error("FAIL Resources autoload missing")
		quit(1)
		return

	wallet.set_amount(wallet.ORE, 0)

	var label := Label.new()
	label.set_script(load("res://ore_hud.gd"))
	root.add_child(label)
	# Label._ready runs on add_child.
	if str(label.text) != "Ore: 0":
		push_error("FAIL initial HUD text was '%s'" % label.text)
		quit(1)
		return

	wallet.add(wallet.ORE, 2)
	if str(label.text) != "Ore: 2":
		push_error("FAIL HUD text after dig grant was '%s'" % label.text)
		quit(1)
		return

	print("ORE_HUD_TESTS_PASSED text=", label.text)
	quit(0)
