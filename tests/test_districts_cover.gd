extends SceneTree
## District efficiency still raises illustrative rates; Cover uses named goods.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var districts: Node = root.get_node_or_null("Districts")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var wallet: Node = root.get_node_or_null("Resources")
	if districts == null or upgrades == null or wallet == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return
	if community:
		community.set_paused(true)
		community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	districts.set_paused(true)
	districts.reset_production()
	for id in districts.get_district_ids():
		match str(id):
			"farms":
				upgrades.set_level(upgrades.FARMS_EFF, 0)
			"wickwork":
				upgrades.set_level(upgrades.WICKWORK_EFF, 0)
			"cistern":
				upgrades.set_level(upgrades.CISTERN_EFF, 0)

	var base_total: float = districts.get_total_rate()
	if base_total < 2.5 or base_total > 3.0:
		push_error("FAIL unexpected base total rate %s" % base_total)
		quit(1)
		return

	# Thin production → weaker Cover / higher notice.
	for good_id in districts.get_good_ids():
		districts.set_good_amount(good_id, districts.PROTECTED_RESERVE)
	var cover_low: float = districts.get_cover_health()
	var notice_high: float = districts.get_siphon_notice_chance()
	if cover_low >= 0.95:
		push_error("FAIL base cover too high %s" % cover_low)
		quit(1)
		return

	for good_id in districts.get_good_ids():
		districts.set_good_amount(good_id, districts.CAPACITY)
	var cover_high: float = districts.get_cover_health()
	var notice_low: float = districts.get_siphon_notice_chance()
	if cover_high <= cover_low:
		push_error("FAIL healthy production did not raise cover")
		quit(1)
		return
	if notice_low >= notice_high:
		push_error("FAIL healthier districts did not lower notice chance")
		quit(1)
		return
	print("PASS healthy named goods raise cover and lower siphon notice")

	# Efficiency still raises get_rate for Harvest bonus wiring.
	upgrades.set_level(upgrades.FARMS_EFF, 3)
	upgrades.set_level(upgrades.WICKWORK_EFF, 3)
	upgrades.set_level(upgrades.CISTERN_EFF, 3)
	if districts.get_total_rate() <= base_total:
		push_error("FAIL efficiency did not raise rates")
		quit(1)
		return
	print("PASS efficiency raises district rates")

	districts.reset_production()
	districts.set_good_amount(districts.GLOWRATIONS, 5)
	districts.set_good_amount(districts.WICKLAMPS, 3)
	districts.set_good_amount(districts.PRESSWATER, 4)
	if not save_load.save_game():
		push_error("FAIL save")
		quit(1)
		return
	districts.reset_production()
	if not save_load.load_game():
		push_error("FAIL load")
		quit(1)
		return
	if districts.get_good_amount(districts.GLOWRATIONS) != 5:
		push_error("FAIL Glowrations after load")
		quit(1)
		return
	print("PASS district production persists")

	save_load.clear_save()
	print("DISTRICT_COVER_TESTS_PASSED")
	quit(0)
