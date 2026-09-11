extends SceneTree
## Forbidden siphon notice uses cover; efficiency siphons skip notice.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var upgrades: Node = root.get_node_or_null("Upgrades")
	var community: Node = root.get_node_or_null("Community")
	var wallet: Node = root.get_node_or_null("Resources")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if upgrades == null or community == null or wallet == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return
	community.set_paused(true)
	community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	for id in upgrades.get_upgrade_ids():
		upgrades.set_level(id, 0)
	upgrades.set_siphon_station_open(true)
	community.set_social_standing(50)
	community.set_pending_lie(false)
	wallet.set_amount(wallet.SALVAGE, 100)

	# Forced notice on forbidden Dig Yield.
	upgrades.force_siphon_notice = true
	var before: int = community.get_social_standing()
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL forbidden siphon")
		quit(1)
		return
	if community.get_social_standing() >= before:
		push_error("FAIL noticed siphon did not drop Standing")
		quit(1)
		return
	print("PASS forbidden siphon can drop Standing")

	# Efficiency siphon never rolls notice even if force flag is set.
	# (force only applies inside forbidden branch)
	community.set_social_standing(50)
	upgrades.force_siphon_notice = true
	before = community.get_social_standing()
	if not upgrades.siphon_for_upgrade(upgrades.FARMS_EFF):
		push_error("FAIL efficiency siphon")
		quit(1)
		return
	if community.get_social_standing() != before:
		push_error("FAIL efficiency siphon changed Standing")
		quit(1)
		return
	print("PASS efficiency siphon is open (no notice)")

	# Exposed lie worsens siphon penalty (Quiet Dig needs Firmament note Record).
	var journal: Node = root.get_node_or_null("Journal")
	if journal:
		journal.unlock_record(journal.RECORD_FIRMAMENT_NOTE)
	community.set_social_standing(50)
	community.set_pending_lie(true)
	upgrades.force_siphon_notice = true
	before = community.get_social_standing()
	if not upgrades.siphon_for_upgrade(upgrades.QUIET_DIG):
		push_error("FAIL Quiet Dig siphon after Firmament note")
		quit(1)
		return
	var after: int = community.get_social_standing()
	var expected_drop: int = community.SIPHON_NOTICE_PENALTY + community.LIE_EXPOSED_EXTRA_PENALTY
	if before - after != expected_drop:
		push_error("FAIL lie expose drop %d -> %d expected -%d" % [before, after, expected_drop])
		quit(1)
		return
	if community.has_pending_lie():
		push_error("FAIL pending lie not cleared")
		quit(1)
		return
	print("PASS exposed lie worsens siphon penalty")

	upgrades.force_siphon_notice = null
	if save_load:
		save_load.clear_save()
	print("SIPHON_COVER_RISK_TESTS_PASSED")
	quit(0)
