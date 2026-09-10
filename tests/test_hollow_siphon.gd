extends SceneTree
## Siphon only works in Hollow; dig-site siphon fails; Hollow siphon applies upgrades.


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	if wallet == null or upgrades == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return

	upgrades.set_level(upgrades.DIG_YIELD, 0)
	upgrades.set_siphon_station_open(false)
	wallet.set_amount(wallet.SALVAGE, 20)

	# Dig site: cannot siphon even with plenty of Salvage.
	if upgrades.can_siphon(upgrades.DIG_YIELD):
		push_error("FAIL can_siphon true at dig site")
		quit(1)
		return
	if upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL siphon succeeded away from Hollow")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 0 or wallet.get_amount(wallet.SALVAGE) != 20:
		push_error("FAIL dig-site siphon mutated state")
		quit(1)
		return
	print("PASS siphon blocked at dig site")

	# Return to Hollow: open station and siphon.
	upgrades.set_siphon_station_open(true)
	if not upgrades.can_siphon(upgrades.DIG_YIELD):
		push_error("FAIL can_siphon false in Hollow with Salvage")
		quit(1)
		return
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL Hollow siphon failed")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 1 or wallet.get_amount(wallet.SALVAGE) != 15:
		push_error(
			"FAIL after siphon level=%d salvage=%d"
			% [upgrades.get_level(upgrades.DIG_YIELD), wallet.get_amount(wallet.SALVAGE)]
		)
		quit(1)
		return
	print("PASS Hollow siphon spends Salvage and levels upgrade")

	# Dig yield improved after siphon (level 1 => 2 salvage/dig).
	if upgrades.get_dig_salvage_yield() != 2:
		push_error("FAIL yield=%d expected 2" % upgrades.get_dig_salvage_yield())
		quit(1)
		return

	terrain.clear()
	var center := Vector2i(12, 12)
	terrain.set_cell(center + Vector2i.DOWN, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	wallet.set_amount(wallet.SALVAGE, 0)
	var origin := terrain.to_global(terrain.map_to_local(center))
	# Dig still works away from Hollow; station can be closed.
	upgrades.set_siphon_station_open(false)
	if not terrain.dig_in_direction(origin, Vector2i.DOWN):
		push_error("FAIL dig after leaving Hollow")
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != 2:
		push_error("FAIL dig payout=%d expected 2" % wallet.get_amount(wallet.SALVAGE))
		quit(1)
		return
	print("PASS dig still works at dig site with improved yield")

	print("HOLLOW_SIPHON_TESTS_PASSED")
	quit(0)
