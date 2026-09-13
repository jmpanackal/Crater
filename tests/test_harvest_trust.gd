extends SceneTree
## Harvest timer, miss penalty at Dig Site, no penalty in Hollow, Trust save/load.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Let SaveLoad's deferred load_game finish before we reset test state.
	await process_frame

	var community: Node = root.get_node_or_null("Community")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var wallet: Node = root.get_node_or_null("Resources")
	if community == null or upgrades == null or save_load == null or wallet == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return

	save_load.clear_save()
	community.set_paused(true)
	community.skip_lie_prompt = true
	community.set_trust(community.TRUST_DEFAULT)
	community.set_harvest_timer(community.HARVEST_INTERVAL_SEC)
	upgrades.set_level(upgrades.DIG_YIELD, 0)
	upgrades.set_theft_station_open(false)
	wallet.set_amount(wallet.SALVAGE, 0)

	# Timer countdown + reset after harvest.
	community.set_harvest_timer(12.5)
	if not is_equal_approx(community.get_harvest_seconds_remaining(), 12.5):
		push_error("FAIL timer set")
		quit(1)
		return

	# Missed Harvest at Dig Site reduces Trust.
	upgrades.set_theft_station_open(false)
	var before: int = community.get_trust()
	community.trigger_harvest_now()
	var after_miss: int = community.get_trust()
	if after_miss != before - community.TRUST_MISS_PENALTY:
		push_error("FAIL miss trust %d -> %d" % [before, after_miss])
		quit(1)
		return
	if not is_equal_approx(community.get_harvest_seconds_remaining(), community.HARVEST_INTERVAL_SEC):
		push_error("FAIL timer did not reset after harvest")
		quit(1)
		return
	print("PASS Dig Site miss reduces Trust and resets timer")

	# Hollow attendance does NOT reduce Trust.
	upgrades.set_theft_station_open(true)
	before = community.get_trust()
	community.trigger_harvest_now()
	if community.get_trust() != before:
		push_error("FAIL Hollow harvest changed Trust")
		quit(1)
		return
	print("PASS Hollow Harvest does not reduce Trust")

	# Persist Trust across save/load.
	community.set_trust(37)
	community.set_harvest_timer(41.0)
	wallet.set_amount(wallet.SALVAGE, 9)
	upgrades.set_level(upgrades.DIG_YIELD, 2)
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return

	community.set_trust(50)
	community.set_harvest_timer(60.0)
	wallet.set_amount(wallet.SALVAGE, 0)
	upgrades.set_level(upgrades.DIG_YIELD, 0)

	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return
	if community.get_trust() != 37:
		push_error("FAIL trust after load=%d" % community.get_trust())
		quit(1)
		return
	if not is_equal_approx(community.get_harvest_seconds_remaining(), 41.0):
		push_error("FAIL harvest_timer after load")
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != 9 or upgrades.get_level(upgrades.DIG_YIELD) != 2:
		push_error("FAIL salvage/upgrades after load")
		quit(1)
		return
	print("PASS Trust (and related state) persists after reload")

	# Live countdown while unpaused.
	community.set_paused(false)
	community.set_harvest_timer(0.2)
	await create_timer(0.35).timeout
	var rem: float = community.get_harvest_seconds_remaining()
	if rem < 50.0 or rem > community.HARVEST_INTERVAL_SEC + 0.1:
		push_error("FAIL countdown/reset live rem=%s" % rem)
		quit(1)
		return
	print("PASS harvest timer counts down and resets live")

	community.set_paused(true)
	save_load.clear_save()
	print("HARVEST_TRUST_TESTS_PASSED")
	quit(0)
