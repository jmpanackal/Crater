extends SceneTree
## Forbidden Dig Yield costs Bindcord; efficiency keeps Salvage curve.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var districts: Node = root.get_node_or_null("Districts")
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if wallet == null or upgrades == null or districts == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return
	if community:
		community.set_paused(true)
	if save_load:
		save_load.clear_save()

	upgrades.set_level(upgrades.DIG_YIELD, 0)
	upgrades.set_siphon_station_open(true)
	upgrades.force_siphon_notice = false
	wallet.set_amount(wallet.SALVAGE, 0)
	districts.reset_production()
	districts.set_good_amount(districts.BINDCORD, districts.PROTECTED_RESERVE)

	if upgrades.get_next_cost(upgrades.DIG_YIELD) != 1:
		push_error("FAIL Dig Yield divert cost")
		quit(1)
		return
	if upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL siphon at reserve Bindcord")
		quit(1)
		return

	districts.set_good_amount(districts.BINDCORD, 3)
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL first siphon")
		quit(1)
		return
	if districts.get_good_amount(districts.BINDCORD) != 2 or upgrades.get_level(upgrades.DIG_YIELD) != 1:
		push_error("FAIL after first siphon")
		quit(1)
		return

	# Efficiency still uses Salvage cost curve.
	upgrades.set_level(upgrades.FARMS_EFF, 0)
	if upgrades.get_next_cost(upgrades.FARMS_EFF) != 4:
		push_error("FAIL efficiency base cost")
		quit(1)
		return
	wallet.set_amount(wallet.SALVAGE, 4)
	if not upgrades.siphon_for_upgrade(upgrades.FARMS_EFF):
		push_error("FAIL efficiency siphon")
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != 0 or upgrades.get_level(upgrades.FARMS_EFF) != 1:
		push_error("FAIL after efficiency siphon")
		quit(1)
		return
	if upgrades.get_next_cost(upgrades.FARMS_EFF) != 6:
		push_error("FAIL efficiency growth cost %d" % upgrades.get_next_cost(upgrades.FARMS_EFF))
		quit(1)
		return

	print("UPGRADE_SIPHON_CURVE_PASSED")
	quit(0)
