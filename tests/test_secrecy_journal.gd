extends SceneTree
## Harvest miss lie dodge, upward dig catch, journal unlock + save.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var community: Node = root.get_node_or_null("Community")
	var journal: Node = root.get_node_or_null("Journal")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var wallet: Node = root.get_node_or_null("Resources")
	if community == null or journal == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return
	community.set_paused(true)
	if save_load:
		save_load.clear_save()
	if wallet:
		wallet.set_amount(wallet.SALVAGE, 0)
	if upgrades:
		for id in upgrades.get_upgrade_ids():
			upgrades.set_level(id, 0)

	# Lie prompt path: dodge Standing, set pending_lie.
	community.skip_lie_prompt = false
	community.set_social_standing(50)
	community.set_pending_lie(false)
	if upgrades:
		upgrades.set_siphon_station_open(false)
	if community.is_player_in_hollow():
		push_error("FAIL expected Dig Site (siphon closed) for miss prompt")
		quit(1)
		return
	var prompted: Array = [false]
	community.harvest_miss_prompt.connect(func() -> void:
		prompted[0] = true
		community.resolve_harvest_miss(true)
	, CONNECT_ONE_SHOT)
	community.trigger_harvest_now()
	if not bool(prompted[0]):
		push_error("FAIL harvest miss prompt not emitted (skip_lie_prompt=%s)" % community.skip_lie_prompt)
		quit(1)
		return
	if community.get_social_standing() != 50:
		push_error("FAIL lie still penalized Standing")
		quit(1)
		return
	if not community.has_pending_lie():
		push_error("FAIL lie did not set pending_lie")
		quit(1)
		return
	print("PASS Harvest miss lie dodges Standing")
	community.skip_lie_prompt = true

	# Truth path still penalizes.
	community.set_pending_lie(false)
	community.set_social_standing(50)
	var before: int = community.get_social_standing()
	community.on_harvest_missed()
	if community.get_social_standing() != before - community.SOCIAL_STANDING_MISS_PENALTY:
		push_error("FAIL truth miss penalty")
		quit(1)
		return
	print("PASS honest miss still penalizes")

	# Upward dig catch with forced RNG via many rolls is awkward — call caught directly.
	community.set_social_standing(40)
	community.set_pending_lie(true)
	before = community.get_social_standing()
	community.on_caught_upward_dig()
	var drop: int = before - community.get_social_standing()
	if drop != community.UPWARD_DIG_PENALTY + community.LIE_EXPOSED_EXTRA_PENALTY:
		push_error("FAIL upward catch drop=%d" % drop)
		quit(1)
		return
	print("PASS upward dig catch exposes lie")

	# Journal unlock + persist.
	journal.clear_all()
	if upgrades and upgrades.has_method("is_unlocked"):
		if upgrades.is_unlocked(upgrades.QUIET_DIG):
			push_error("FAIL Quiet Dig unlocked without Firmament note")
			quit(1)
			return
	if not journal.unlock_record(journal.RECORD_SLATE):
		push_error("FAIL unlock slate")
		quit(1)
		return
	if upgrades and upgrades.has_method("is_unlocked"):
		if upgrades.is_unlocked(upgrades.QUIET_DIG):
			push_error("FAIL Quiet Dig unlocked by wrong Record")
			quit(1)
			return
	if not journal.unlock_record(journal.RECORD_FIRMAMENT_NOTE):
		push_error("FAIL unlock Firmament note")
		quit(1)
		return
	if upgrades and upgrades.has_method("is_unlocked"):
		if not upgrades.is_unlocked(upgrades.QUIET_DIG):
			push_error("FAIL Firmament note should unlock Quiet Dig")
			quit(1)
			return
	print("PASS Firmament note gates Quiet Dig")
	if not journal.has_record(journal.RECORD_SLATE):
		push_error("FAIL has_record")
		quit(1)
		return
	community.set_pending_lie(false)
	community.set_social_standing(33)
	if not save_load.save_game():
		push_error("FAIL save")
		quit(1)
		return
	journal.clear_all()
	community.set_social_standing(50)
	if not save_load.load_game():
		push_error("FAIL load")
		quit(1)
		return
	if not journal.has_record(journal.RECORD_SLATE):
		push_error("FAIL journal missing after load")
		quit(1)
		return
	if not journal.has_record(journal.RECORD_FIRMAMENT_NOTE):
		push_error("FAIL Firmament note missing after load")
		quit(1)
		return
	if upgrades and upgrades.has_method("is_unlocked") and not upgrades.is_unlocked(upgrades.QUIET_DIG):
		push_error("FAIL Quiet Dig locked after Firmament note load")
		quit(1)
		return
	if community.get_social_standing() != 33:
		push_error("FAIL standing after journal save load")
		quit(1)
		return
	print("PASS journal + standing persist")

	# Firmament vs Pit cell helpers.
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	if not terrain.is_firmament_cell(Vector2i(12, 2)):
		push_error("FAIL Firmament cell")
		quit(1)
		return
	if not terrain.is_pit_cell(Vector2i(12, 12)):
		push_error("FAIL pit cell")
		quit(1)
		return
	if terrain.is_firmament_cell(Vector2i(12, 12)) or terrain.is_pit_cell(Vector2i(12, 2)):
		push_error("FAIL frontier helpers crossed")
		quit(1)
		return
	print("PASS Firmament/Pit frontier helpers")

	if save_load:
		save_load.clear_save()
	print("SECRECY_JOURNAL_TESTS_PASSED")
	quit(0)
