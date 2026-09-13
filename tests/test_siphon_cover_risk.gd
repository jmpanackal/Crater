extends SceneTree
## Forbidden steal notice uses cover; efficiency steals skip notice.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var upgrades: Node = root.get_node_or_null("Upgrades")
	var community: Node = root.get_node_or_null("Community")
	var wallet: Node = root.get_node_or_null("Resources")
	var districts: Node = root.get_node_or_null("Districts")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if upgrades == null or community == null or wallet == null or districts == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return
	community.set_paused(true)
	community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	for id in upgrades.get_upgrade_ids():
		upgrades.set_level(id, 0)
	upgrades.set_theft_station_open(true)
	community.set_trust(50)
	community.set_pending_lie(false)
	wallet.set_amount(wallet.SALVAGE, 100)
	districts.reset_production()
	districts.set_good_amount(districts.BINDCORD, 5)
	districts.set_good_amount(districts.SEALBRINE, 5)

	# Forced notice on forbidden Dig Yield.
	upgrades.force_theft_notice = true
	var before: int = community.get_trust()
	if not upgrades.steal_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL forbidden steal")
		quit(1)
		return
	if community.get_trust() >= before:
		push_error("FAIL noticed steal did not drop Trust")
		quit(1)
		return
	print("PASS forbidden steal can drop Trust")

	# Efficiency steal never rolls notice even if force flag is set.
	community.set_trust(50)
	upgrades.force_theft_notice = true
	before = community.get_trust()
	if not upgrades.steal_for_upgrade(upgrades.FARMS_EFF):
		push_error("FAIL efficiency steal")
		quit(1)
		return
	if community.get_trust() != before:
		push_error("FAIL efficiency steal changed Trust")
		quit(1)
		return
	print("PASS efficiency steal is open (no notice)")

	# Exposed lie worsens steal penalty (Quiet Dig needs Firmament note Record).
	var journal: Node = root.get_node_or_null("Journal")
	if journal:
		journal.unlock_record(journal.RECORD_FIRMAMENT_NOTE)
	community.set_trust(50)
	community.set_pending_lie(true)
	upgrades.force_theft_notice = true
	before = community.get_trust()
	if not upgrades.steal_for_upgrade(upgrades.QUIET_DIG):
		push_error("FAIL Quiet Dig steal after Firmament note")
		quit(1)
		return
	var after: int = community.get_trust()
	var expected_drop: int = community.THEFT_NOTICE_PENALTY + community.LIE_EXPOSED_EXTRA_PENALTY
	if before - after != expected_drop:
		push_error("FAIL lie expose drop %d -> %d expected -%d" % [before, after, expected_drop])
		quit(1)
		return
	if community.has_pending_lie():
		push_error("FAIL pending lie not cleared")
		quit(1)
		return
	print("PASS exposed lie worsens steal penalty")

	upgrades.force_theft_notice = null
	if save_load:
		save_load.clear_save()
	print("STEAL_COVER_RISK_TESTS_PASSED")
	quit(0)
