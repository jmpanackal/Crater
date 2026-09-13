extends SceneTree
## One continuous economy loop, not per-system isolation: dig a tile, turn
## the Material in, Harvest applies district production + grants Tallies,
## spend Tallies at Requisition, steal District production at the Steal
## panel's data layer, then save -> mutate -> load and confirm everything
## survives the round trip together. Per-system behavior already has
## dedicated coverage (test_salvage_on_dig, test_district_production,
## test_upgrades, test_campaign_shell, ...) — this proves the full path
## still holds together as one path.


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var community: Node = root.get_node_or_null("Community")
	var districts: Node = root.get_node_or_null("Districts")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if wallet == null or upgrades == null or community == null or districts == null or save_load == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return

	community.set_paused(true)
	community.skip_lie_prompt = true
	save_load.clear_save()
	wallet.reset_all()
	districts.reset_production()
	for id in upgrades.get_upgrade_ids():
		upgrades.set_level(id, 0)
	upgrades.set_theft_station_open(true)
	upgrades.force_theft_notice = false
	community.set_trust(50)
	terrain.clear()

	# --- 1. Dig a tile: grants Salvage + one cycling Material (Sporemeal first). ---
	# dig_in_direction targets the cell ADJACENT to origin_world, so the tile
	# is placed one step DOWN from the (empty) origin cell — same pattern as
	# test_salvage_on_dig.gd. Mid-band cell avoids the Mouth's flaky +1 yield.
	var center := Vector2i(10, 6)
	terrain.set_cell(center + Vector2i.DOWN, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	var origin_world := terrain.to_global(terrain.map_to_local(center))
	var sporemeal_before: int = wallet.get_amount(wallet.SPOREMEAL)
	if not terrain.dig_in_direction(origin_world, Vector2i.DOWN):
		push_error("FAIL dig did not remove tile")
		quit(1)
		return
	if wallet.get_amount(wallet.SPOREMEAL) != sporemeal_before + 1:
		push_error("FAIL dig did not grant Sporemeal")
		quit(1)
		return
	print("PASS dig grants Materials")

	# --- 2. Turn in the Material: queues Glowbeds output and grants Tallies
	# immediately (the Sporemeal recipe pays 1 Tally on turn-in, not at Harvest). ---
	var queued_before: int = districts.get_queued(districts.GLOWRATIONS)
	var tallies_before_turn_in: int = wallet.get_amount(wallet.TALLIES)
	if not districts.queue_material(wallet.SPOREMEAL):
		push_error("FAIL queue_material")
		quit(1)
		return
	if wallet.get_amount(wallet.SPOREMEAL) != 0:
		push_error("FAIL Sporemeal not consumed by turn-in")
		quit(1)
		return
	if districts.get_queued(districts.GLOWRATIONS) <= queued_before:
		push_error("FAIL Glowrations not queued")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != tallies_before_turn_in + 1:
		push_error("FAIL turn-in did not grant Tallies")
		quit(1)
		return
	print("PASS turn-in queues District production and grants Tallies")

	# --- 3. Harvest: applies the queued output onto the actual district goods. ---
	var glowrations_before: int = districts.get_good_amount(districts.GLOWRATIONS)
	districts.apply_harvest()
	if districts.get_good_amount(districts.GLOWRATIONS) <= glowrations_before:
		push_error("FAIL Harvest did not raise Glowrations")
		quit(1)
		return
	print("PASS Harvest applies the queue")

	# --- 4. Requisition: spend Tallies on a sanctioned (efficiency) upgrade. ---
	# Top up beyond the single Tallies just earned — a real playthrough would
	# reach this over several turn-ins; topping up here keeps the test focused
	# on the acquire path itself rather than grinding the loop dozens of times.
	wallet.set_amount(wallet.TALLIES, 10)
	var farms_cost: int = upgrades.get_next_cost(upgrades.FARMS_EFF)
	var farms_level_before: int = upgrades.get_level(upgrades.FARMS_EFF)
	if not upgrades.acquire_upgrade(upgrades.FARMS_EFF):
		push_error("FAIL Requisition acquire_upgrade")
		quit(1)
		return
	if upgrades.get_level(upgrades.FARMS_EFF) != farms_level_before + 1:
		push_error("FAIL Requisition did not level up")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != 10 - farms_cost:
		push_error("FAIL Requisition did not spend Tallies")
		quit(1)
		return
	print("PASS Requisition spends Tallies")

	# --- 5. Steal: divert District production for a forbidden upgrade. ---
	districts.set_good_amount(districts.BINDCORD, 5)
	var bindcord_before: int = districts.get_good_amount(districts.BINDCORD)
	var dig_yield_before: int = upgrades.get_level(upgrades.DIG_YIELD)
	if not upgrades.acquire_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL Steal acquire_upgrade")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != dig_yield_before + 1:
		push_error("FAIL Steal did not level up")
		quit(1)
		return
	if districts.get_good_amount(districts.BINDCORD) >= bindcord_before:
		push_error("FAIL Steal did not divert Bindcord")
		quit(1)
		return
	print("PASS Steal diverts District production")

	# --- 6. Save -> mutate everything -> load -> confirm the whole loop survives together. ---
	var pre_save := {
		"glowrations": districts.get_good_amount(districts.GLOWRATIONS),
		"bindcord": districts.get_good_amount(districts.BINDCORD),
		"tallies": wallet.get_amount(wallet.TALLIES),
		"farms_eff_level": upgrades.get_level(upgrades.FARMS_EFF),
		"dig_yield_level": upgrades.get_level(upgrades.DIG_YIELD),
		"trust": community.get_trust(),
	}
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return

	# Mutate everything the snapshot covers so a trivial no-op load can't pass.
	districts.reset_production()
	wallet.reset_all()
	for id in upgrades.get_upgrade_ids():
		upgrades.set_level(id, 0)
	community.set_trust(1)

	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return

	if districts.get_good_amount(districts.GLOWRATIONS) != pre_save["glowrations"]:
		push_error("FAIL Glowrations did not persist")
		quit(1)
		return
	if districts.get_good_amount(districts.BINDCORD) != pre_save["bindcord"]:
		push_error("FAIL Bindcord did not persist")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != pre_save["tallies"]:
		push_error("FAIL Tallies did not persist")
		quit(1)
		return
	if upgrades.get_level(upgrades.FARMS_EFF) != pre_save["farms_eff_level"]:
		push_error("FAIL Requisition level did not persist")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != pre_save["dig_yield_level"]:
		push_error("FAIL Steal level did not persist")
		quit(1)
		return
	if community.get_trust() != pre_save["trust"]:
		push_error("FAIL Trust did not persist")
		quit(1)
		return
	print("PASS full loop persists across save/reload")

	save_load.clear_save()
	print("ECONOMY_LOOP_TESTS_PASSED")
	quit(0)
