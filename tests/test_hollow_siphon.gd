extends SceneTree
## Siphon only works in Hollow; dig-site siphon fails; Hollow siphon diverts production.


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
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
	upgrades.set_siphon_station_open(false)
	upgrades.force_siphon_notice = false
	wallet.set_amount(wallet.SALVAGE, 20)
	districts.reset_production()
	districts.set_good_amount(districts.BINDCORD, 4)

	# Dig site: cannot siphon even with Bindcord available.
	if upgrades.can_siphon(upgrades.DIG_YIELD):
		push_error("FAIL can_siphon true at dig site")
		quit(1)
		return
	if upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL siphon succeeded away from Hollow")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 0 or districts.get_good_amount(districts.BINDCORD) != 4:
		push_error("FAIL dig-site siphon mutated state")
		quit(1)
		return
	print("PASS siphon blocked at dig site")

	# Return to Hollow: open station and siphon Bindcord.
	upgrades.set_siphon_station_open(true)
	if not upgrades.can_siphon(upgrades.DIG_YIELD):
		push_error("FAIL can_siphon false in Hollow with Bindcord")
		quit(1)
		return
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL Hollow siphon failed")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 1 or districts.get_good_amount(districts.BINDCORD) != 3:
		push_error(
			"FAIL after siphon level=%d bindcord=%d"
			% [upgrades.get_level(upgrades.DIG_YIELD), districts.get_good_amount(districts.BINDCORD)]
		)
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != 20:
		push_error("FAIL forbidden siphon spent Salvage")
		quit(1)
		return
	print("PASS Hollow siphon diverts Bindcord and levels upgrade")

	# Dig yield improved after siphon (level 1 => 2 materials/dig).
	if upgrades.get_dig_salvage_yield() != 2:
		push_error("FAIL yield=%d expected 2" % upgrades.get_dig_salvage_yield())
		quit(1)
		return

	terrain.clear()
	# Mid-band cell so DOWN is not a Mouth bonus tile.
	var center := Vector2i(12, 6)
	terrain.set_cell(center + Vector2i.DOWN, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	wallet.reset_all()
	var origin := terrain.to_global(terrain.map_to_local(center))
	# Dig still works away from Hollow; station can be closed.
	upgrades.set_siphon_station_open(false)
	if not terrain.dig_in_direction(origin, Vector2i.DOWN):
		push_error("FAIL dig after leaving Hollow")
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != 2:
		push_error("FAIL dig Salvage payout=%d expected 2" % wallet.get_amount(wallet.SALVAGE))
		quit(1)
		return
	var mat_total: int = (
		wallet.get_amount(wallet.SPOREMEAL)
		+ wallet.get_amount(wallet.LAMPWICK)
		+ wallet.get_amount(wallet.BRINECRYSTAL)
	)
	if mat_total != 2:
		push_error("FAIL dig Materials payout=%d expected 2" % mat_total)
		quit(1)
		return
	print("PASS dig still works at dig site with improved yield")

	print("HOLLOW_SIPHON_TESTS_PASSED")
	quit(0)
