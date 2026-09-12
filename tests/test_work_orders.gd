extends SceneTree
## Act 1 Work Orders: sequence, deliveries, Harvest gate, Tallies, Verdigris optional, save.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var wo: Node = root.get_node_or_null("WorkOrders")
	var districts: Node = root.get_node_or_null("Districts")
	var wallet: Node = root.get_node_or_null("Resources")
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	if wo == null or districts == null or wallet == null or community == null or save_load == null:
		push_error("FAIL missing autoloads (WorkOrders required)")
		quit(1)
		return

	community.set_paused(true)
	community.skip_lie_prompt = true
	districts.set_paused(true)
	save_load.clear_save()
	wo.reset_all()
	districts.reset_production()
	wallet.reset_all()
	if upgrades:
		for id in upgrades.get_upgrade_ids():
			upgrades.set_level(id, 0)

	# --- Starts offered: Feed the Glowbeds ---
	if wo.get_active_order_id() != wo.FEED_GLOWBEDS:
		push_error("FAIL start order id %s" % str(wo.get_active_order_id()))
		quit(1)
		return
	if wo.get_state() != wo.STATE_OFFERED:
		push_error("FAIL start state %s" % str(wo.get_state()))
		quit(1)
		return
	print("PASS starts with Feed the Glowbeds offered")

	# --- Accept → active ---
	if not wo.accept_offered():
		push_error("FAIL accept offered")
		quit(1)
		return
	if wo.get_state() != wo.STATE_ACTIVE:
		push_error("FAIL not active after accept")
		quit(1)
		return
	print("PASS accept moves to active")

	# --- Delivery only via normal queue_material; needs 2 Sporemeal ---
	wallet.set_amount(wallet.SPOREMEAL, 2)
	wallet.set_amount(wallet.TALLIES, 0)
	if not districts.queue_material(wallet.SPOREMEAL):
		push_error("FAIL queue first Sporemeal")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != 1:
		push_error("FAIL first Sporemeal Tallies")
		quit(1)
		return
	if wo.get_delivered_count() != 1:
		push_error("FAIL delivered count after 1")
		quit(1)
		return
	if wo.get_state() != wo.STATE_ACTIVE:
		push_error("FAIL should stay active after 1/2")
		quit(1)
		return
	if not districts.queue_material(wallet.SPOREMEAL):
		push_error("FAIL queue second Sporemeal")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != 2:
		push_error("FAIL second Sporemeal Tallies")
		quit(1)
		return
	if wo.get_state() != wo.STATE_MATERIALS_DELIVERED:
		push_error("FAIL materials_delivered after 2 Sporemeal, got %s" % str(wo.get_state()))
		quit(1)
		return
	print("PASS Glowbeds delivery + normal Tallies")

	# --- Harvest alone does not resolve until awaiting_Harvest ---
	community.trigger_harvest_now()
	await process_frame
	if wo.get_state() != wo.STATE_MATERIALS_DELIVERED:
		push_error("FAIL Harvest before acknowledge should not resolve")
		quit(1)
		return
	if not wo.acknowledge_delivery():
		push_error("FAIL acknowledge delivery")
		quit(1)
		return
	if wo.get_state() != wo.STATE_AWAITING_HARVEST:
		push_error("FAIL awaiting_Harvest after acknowledge")
		quit(1)
		return
	print("PASS acknowledge gates awaiting_Harvest")

	# --- Resolve only at Harvest ---
	community.trigger_harvest_now()
	await process_frame
	if not wo.is_completed(wo.FEED_GLOWBEDS):
		push_error("FAIL Feed the Glowbeds not completed")
		quit(1)
		return
	if wo.get_active_order_id() != wo.HOLD_GALLERY:
		push_error("FAIL next order should be Hold the Gallery")
		quit(1)
		return
	if wo.get_state() != wo.STATE_OFFERED:
		push_error("FAIL next should be offered")
		quit(1)
		return
	print("PASS resolves at Harvest and offers WO2")

	# --- WO2: Lampwick only; Verdigris does not count ---
	wo.accept_offered()
	wallet.set_amount(wallet.LAMPWICK, 2)
	wallet.set_amount(wallet.VERDIGRIS, 2)
	wallet.set_amount(wallet.TALLIES, 0)
	var tallies_before_v: int = wallet.get_amount(wallet.TALLIES)
	if not districts.queue_material(wallet.VERDIGRIS):
		push_error("FAIL Verdigris still queues at Wickwork")
		quit(1)
		return
	if wo.get_delivered_count() != 0:
		push_error("FAIL Verdigris counted toward Hold the Gallery")
		quit(1)
		return
	# Mid Heart Tallies path remains optional and separate.
	wallet.set_amount(wallet.VERDIGRIS, 1)
	if not districts.turn_in_verdigris_for_tallies():
		push_error("FAIL Verdigris Mid Heart Tallies path")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != tallies_before_v + 3:
		# queue Verdigris grants 0 Tallies; Mid Heart +3
		push_error("FAIL Verdigris Mid Heart Tallies amount")
		quit(1)
		return
	if wo.get_delivered_count() != 0:
		push_error("FAIL Verdigris Mid Heart counted as WO delivery")
		quit(1)
		return

	districts.queue_material(wallet.LAMPWICK)
	districts.queue_material(wallet.LAMPWICK)
	if wallet.get_amount(wallet.TALLIES) != tallies_before_v + 3 + 2:
		push_error("FAIL Lampwick Tallies %d" % wallet.get_amount(wallet.TALLIES))
		quit(1)
		return
	if wo.get_state() != wo.STATE_MATERIALS_DELIVERED:
		push_error("FAIL WO2 materials_delivered")
		quit(1)
		return
	wo.acknowledge_delivery()
	community.trigger_harvest_now()
	await process_frame
	if not wo.is_completed(wo.HOLD_GALLERY):
		push_error("FAIL Hold the Gallery not completed")
		quit(1)
		return
	if wo.get_active_order_id() != wo.PRESSURE_BELOW:
		push_error("FAIL next should be Pressure Below")
		quit(1)
		return
	print("PASS Hold the Gallery; Verdigris optional")

	# --- WO3 Brinecrystal ---
	wo.accept_offered()
	wallet.set_amount(wallet.BRINECRYSTAL, 2)
	wallet.set_amount(wallet.TALLIES, 0)
	districts.queue_material(wallet.BRINECRYSTAL)
	districts.queue_material(wallet.BRINECRYSTAL)
	if wallet.get_amount(wallet.TALLIES) != 2:
		push_error("FAIL Brinecrystal Tallies")
		quit(1)
		return
	if wo.get_state() != wo.STATE_MATERIALS_DELIVERED:
		push_error("FAIL WO3 materials_delivered")
		quit(1)
		return
	wo.acknowledge_delivery()
	community.trigger_harvest_now()
	await process_frame
	if not wo.is_completed(wo.PRESSURE_BELOW):
		push_error("FAIL Pressure Below not completed")
		quit(1)
		return
	if wo.get_state() != wo.STATE_RESOLVED and wo.get_active_order_id() != StringName():
		# All done: either idle resolved or no active order.
		if not wo.are_all_complete():
			push_error("FAIL all Work Orders should be complete")
			quit(1)
			return
	print("PASS Pressure Below sequence")

	# --- Save / load persistence mid-order ---
	wo.reset_all()
	wo.accept_offered()
	wallet.set_amount(wallet.SPOREMEAL, 1)
	districts.queue_material(wallet.SPOREMEAL)
	if wo.get_delivered_count() != 1 or wo.get_state() != wo.STATE_ACTIVE:
		push_error("FAIL setup for save")
		quit(1)
		return
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return
	wo.reset_all()
	if wo.get_state() != wo.STATE_OFFERED or wo.get_delivered_count() != 0:
		push_error("FAIL reset before load")
		quit(1)
		return
	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return
	if wo.get_active_order_id() != wo.FEED_GLOWBEDS:
		push_error("FAIL loaded order id")
		quit(1)
		return
	if wo.get_state() != wo.STATE_ACTIVE:
		push_error("FAIL loaded state %s" % str(wo.get_state()))
		quit(1)
		return
	if wo.get_delivered_count() != 1:
		push_error("FAIL loaded delivered %d" % wo.get_delivered_count())
		quit(1)
		return
	print("PASS save/load Work Order persistence")

	# --- Dialogue helpers exist and stay brief ---
	var lines: PackedStringArray = wo.get_joss_lines()
	if lines.size() < 2 or lines.size() > 4:
		push_error("FAIL Joss lines count %d" % lines.size())
		quit(1)
		return
	print("PASS Joss dialogue length")

	print("ALL PASS test_work_orders")
	quit(0)
