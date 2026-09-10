extends SceneTree
## Regression: Buy button ignores ui_accept/Space focus, still buys via click and U.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	if wallet == null or upgrades == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return

	upgrades.set_level(upgrades.DIG_YIELD, 0)
	wallet.set_amount(wallet.ORE, 50)

	var packed: PackedScene = load("res://main.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)

	var panel: Node = scene.get_node("UI/UpgradePanel")
	var button: Button = scene.get_node("UI/UpgradePanel/BuyButton")

	# Allow _ready to run on the panel/button.
	await process_frame

	if button.focus_mode != Control.FOCUS_NONE:
		push_error("FAIL BuyButton focus_mode=%d expected FOCUS_NONE" % button.focus_mode)
		quit(1)
		return

	button.grab_focus()
	if button.has_focus():
		push_error("FAIL BuyButton should not be able to take keyboard focus")
		quit(1)
		return

	var level_before: int = upgrades.get_level(upgrades.DIG_YIELD)
	var ore_before: int = wallet.get_amount(wallet.ORE)

	# Simulate jump / ui_accept — must NOT purchase when button can't focus.
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	root.get_viewport().push_input(accept)
	await process_frame

	if upgrades.get_level(upgrades.DIG_YIELD) != level_before or wallet.get_amount(wallet.ORE) != ore_before:
		push_error("FAIL ui_accept/Space triggered a purchase")
		quit(1)
		return
	print("PASS jump/ui_accept does not buy")

	# Mouse/click path: Button.pressed still purchases.
	button.pressed.emit()
	await process_frame
	if upgrades.get_level(upgrades.DIG_YIELD) != level_before + 1:
		push_error("FAIL click/pressed did not buy upgrade")
		quit(1)
		return
	print("PASS button pressed signal still buys")

	level_before = upgrades.get_level(upgrades.DIG_YIELD)
	ore_before = wallet.get_amount(wallet.ORE)

	# Explicit U hotkey path.
	var buy := InputEventAction.new()
	buy.action = &"buy_upgrade"
	buy.pressed = true
	root.get_viewport().push_input(buy)
	await process_frame

	if upgrades.get_level(upgrades.DIG_YIELD) != level_before + 1:
		push_error("FAIL U/buy_upgrade hotkey did not buy")
		quit(1)
		return
	if wallet.get_amount(wallet.ORE) >= ore_before:
		push_error("FAIL U hotkey did not spend Ore")
		quit(1)
		return
	print("PASS U hotkey still buys")

	print("BUY_BUTTON_FOCUS_TESTS_PASSED")
	quit(0)
