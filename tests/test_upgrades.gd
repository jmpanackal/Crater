extends SceneTree
## Headless checks: Ore spend, rising costs, and dig yield improvement from Dig Yield upgrade.


func _init() -> void:
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	call_deferred("_run_tests", terrain)


func _run_tests(terrain: TerrainLayer) -> void:
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	if wallet == null or upgrades == null:
		push_error("FAIL missing Resources or Upgrades autoload")
		quit(1)
		return

	# Reset state.
	upgrades.set_level(upgrades.DIG_YIELD, 0)
	wallet.set_amount(wallet.ORE, 0)

	# Cost curve: level 0 -> 5, level 1 -> ceil(5*1.5)=8, level 2 -> ceil(5*2.25)=12
	var cost0: int = upgrades.get_next_cost(upgrades.DIG_YIELD)
	if cost0 != 5:
		push_error("FAIL initial cost=%d expected 5" % cost0)
		quit(1)
		return

	if upgrades.try_buy(upgrades.DIG_YIELD):
		push_error("FAIL buy should fail with 0 Ore")
		quit(1)
		return

	wallet.set_amount(wallet.ORE, 5)
	if not upgrades.try_buy(upgrades.DIG_YIELD):
		push_error("FAIL buy should succeed with 5 Ore")
		quit(1)
		return
	if wallet.get_amount(wallet.ORE) != 0:
		push_error("FAIL ore not spent fully, have %d" % wallet.get_amount(wallet.ORE))
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 1:
		push_error("FAIL level=%d expected 1" % upgrades.get_level(upgrades.DIG_YIELD))
		quit(1)
		return

	var cost1: int = upgrades.get_next_cost(upgrades.DIG_YIELD)
	if cost1 != 8:
		push_error("FAIL second cost=%d expected 8" % cost1)
		quit(1)
		return
	print("PASS spend + level + cost curve (5 -> 8)")

	wallet.set_amount(wallet.ORE, 8)
	if not upgrades.try_buy(upgrades.DIG_YIELD):
		push_error("FAIL second buy failed")
		quit(1)
		return
	var cost2: int = upgrades.get_next_cost(upgrades.DIG_YIELD)
	if upgrades.get_level(upgrades.DIG_YIELD) != 2 or cost2 != 12:
		push_error("FAIL after 2 buys level=%d cost=%d (expected 2 / 12)" % [
			upgrades.get_level(upgrades.DIG_YIELD), cost2
		])
		quit(1)
		return
	print("PASS third cost is 12")

	# Dig yield: level 2 => base 1 + 2 = 3 ore per dig.
	if upgrades.get_dig_ore_yield() != 3:
		push_error("FAIL dig yield=%d expected 3" % upgrades.get_dig_ore_yield())
		quit(1)
		return

	terrain.clear()
	var center := Vector2i(10, 10)
	var target := center + Vector2i.DOWN
	terrain.set_cell(target, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	wallet.set_amount(wallet.ORE, 0)
	var origin := terrain.to_global(terrain.map_to_local(center))
	if not terrain.dig_in_direction(origin, Vector2i.DOWN):
		push_error("FAIL dig did not destroy tile")
		quit(1)
		return
	if wallet.get_amount(wallet.ORE) != 3:
		push_error("FAIL dig payout=%d expected 3" % wallet.get_amount(wallet.ORE))
		quit(1)
		return
	print("PASS dig yield improved to 3 Ore")

	# HUD-ish: info strings should reflect level/cost (smoke via getters).
	print(
		"UPGRADE_TESTS_PASSED level=",
		upgrades.get_level(upgrades.DIG_YIELD),
		" next_cost=",
		upgrades.get_next_cost(upgrades.DIG_YIELD),
		" yield=",
		upgrades.get_dig_ore_yield()
	)
	quit(0)
