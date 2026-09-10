extends SceneTree
## Cost curve + Hollow siphon gating for Dig Yield.


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
	upgrades.set_siphon_station_open(true)
	wallet.set_amount(wallet.SALVAGE, 0)

	if upgrades.get_next_cost(upgrades.DIG_YIELD) != 5:
		push_error("FAIL initial cost")
		quit(1)
		return
	if upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL siphon with 0 Salvage")
		quit(1)
		return

	wallet.set_amount(wallet.SALVAGE, 5)
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL first siphon")
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != 0 or upgrades.get_level(upgrades.DIG_YIELD) != 1:
		push_error("FAIL after first siphon")
		quit(1)
		return
	if upgrades.get_next_cost(upgrades.DIG_YIELD) != 8:
		push_error("FAIL second cost")
		quit(1)
		return

	wallet.set_amount(wallet.SALVAGE, 8)
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL second siphon")
		quit(1)
		return
	if upgrades.get_next_cost(upgrades.DIG_YIELD) != 12:
		push_error("FAIL third cost")
		quit(1)
		return

	print("UPGRADE_SIPHON_CURVE_PASSED")
	quit(0)
