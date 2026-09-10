extends SceneTree
## District passive rates, efficiency upgrades, and siphon cover health.


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
	for id in districts.get_district_ids():
		districts.set_stock(id, 0.0)
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

	var cover_low: float = districts.get_cover_health()
	var notice_high: float = districts.get_siphon_notice_chance()
	if cover_low >= 0.95:
		push_error("FAIL base cover too high %s" % cover_low)
		quit(1)
		return

	upgrades.set_level(upgrades.FARMS_EFF, 3)
	upgrades.set_level(upgrades.WICKWORK_EFF, 3)
	upgrades.set_level(upgrades.CISTERN_EFF, 3)
	var cover_high: float = districts.get_cover_health()
	var notice_low: float = districts.get_siphon_notice_chance()
	if cover_high <= cover_low:
		push_error("FAIL efficiency did not raise cover")
		quit(1)
		return
	if notice_low >= notice_high:
		push_error("FAIL healthier districts did not lower notice chance")
		quit(1)
		return
	print("PASS efficiency raises cover and lowers siphon notice")

	# Passive tick accumulates stock.
	districts.set_paused(false)
	districts.set_stock(districts.FARMS, 0.0)
	await create_timer(0.25).timeout
	var stock: float = districts.get_stock(districts.FARMS)
	if stock <= 0.05:
		push_error("FAIL farms stock did not grow %s" % stock)
		quit(1)
		return
	print("PASS farms stock ticks upward")

	districts.set_paused(true)
	districts.set_stock(districts.FARMS, 12.5)
	districts.set_stock(districts.WICKWORK, 3.0)
	districts.set_stock(districts.CISTERN, 7.0)
	if not save_load.save_game():
		push_error("FAIL save")
		quit(1)
		return
	districts.set_stock(districts.FARMS, 0.0)
	districts.set_stock(districts.WICKWORK, 0.0)
	districts.set_stock(districts.CISTERN, 0.0)
	if not save_load.load_game():
		push_error("FAIL load")
		quit(1)
		return
	if not is_equal_approx(districts.get_stock(districts.FARMS), 12.5):
		push_error("FAIL farms stock after load")
		quit(1)
		return
	print("PASS district stocks persist")

	save_load.clear_save()
	print("DISTRICT_COVER_TESTS_PASSED")
	quit(0)
