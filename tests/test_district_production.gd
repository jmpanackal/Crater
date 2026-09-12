extends SceneTree
## Named District production: Materials queue, Harvest apply, reserve, siphon, Cover.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var districts: Node = root.get_node_or_null("Districts")
	var wallet: Node = root.get_node_or_null("Resources")
	var community: Node = root.get_node_or_null("Community")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if districts == null or wallet == null or community == null or upgrades == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return

	community.set_paused(true)
	community.skip_lie_prompt = true
	districts.set_paused(true)
	if save_load:
		save_load.clear_save()

	districts.reset_production()
	for id in upgrades.get_upgrade_ids():
		upgrades.set_level(id, 0)
	wallet.set_amount(wallet.SPOREMEAL, 0)
	wallet.set_amount(wallet.LAMPWICK, 0)
	wallet.set_amount(wallet.BRINECRYSTAL, 0)
	wallet.set_amount(wallet.VERDIGRIS, 0)
	wallet.set_amount(wallet.TALLIES, 0)

	# --- Named goods start at protected reserve ---
	if districts.get_good_amount(districts.GLOWRATIONS) != districts.PROTECTED_RESERVE:
		push_error("FAIL Glowrations not at reserve")
		quit(1)
		return
	if districts.get_display_name(districts.GLOWBEDS) != "Glowbeds":
		push_error("FAIL Glowbeds display name")
		quit(1)
		return
	print("PASS named goods start at protected reserve")

	# --- Queue Sporemeal → 2 Glowrations + 1 Glowfiber, +1 Tally ---
	wallet.set_amount(wallet.SPOREMEAL, 1)
	if not districts.queue_material(wallet.SPOREMEAL):
		push_error("FAIL queue Sporemeal")
		quit(1)
		return
	if wallet.get_amount(wallet.SPOREMEAL) != 0:
		push_error("FAIL Sporemeal not consumed")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != 1:
		push_error("FAIL Sporemeal Tallies grant")
		quit(1)
		return
	if districts.get_queued(districts.GLOWRATIONS) != 2:
		push_error("FAIL Glowrations queue %d" % districts.get_queued(districts.GLOWRATIONS))
		quit(1)
		return
	if districts.get_queued(districts.GLOWFIBER) != 1:
		push_error("FAIL Glowfiber queue")
		quit(1)
		return
	if districts.get_next_harvest_forecast(districts.GLOWRATIONS) != 3:
		# reserve 1 + queued 2 = 3 (before demand)
		push_error(
			"FAIL Glowrations forecast %d expected 3"
			% districts.get_next_harvest_forecast(districts.GLOWRATIONS)
		)
		quit(1)
		return
	print("PASS Sporemeal queues Glowbeds output + Tally")

	# --- Harvest applies queue up to capacity, demand, clears queue ---
	community.trigger_harvest_now()
	await process_frame
	# 1 + 2 = 3, then demand consumes 1 above reserve → 2
	if districts.get_good_amount(districts.GLOWRATIONS) != 2:
		push_error(
			"FAIL after Harvest Glowrations=%d expected 2"
			% districts.get_good_amount(districts.GLOWRATIONS)
		)
		quit(1)
		return
	if districts.get_good_amount(districts.GLOWFIBER) != 1:
		# 1 + 1 = 2, demand → 1
		push_error(
			"FAIL after Harvest Glowfiber=%d expected 1"
			% districts.get_good_amount(districts.GLOWFIBER)
		)
		quit(1)
		return
	if districts.get_queued(districts.GLOWRATIONS) != 0:
		push_error("FAIL queue not cleared")
		quit(1)
		return
	print("PASS Harvest applies queue, demand, clears queue")

	# --- Capacity 6 clamps applied output ---
	districts.set_good_amount(districts.WICKLAMPS, 5)
	districts.set_good_amount(districts.BINDCORD, 1)
	wallet.set_amount(wallet.LAMPWICK, 1)
	if not districts.queue_material(wallet.LAMPWICK):
		push_error("FAIL queue Lampwick")
		quit(1)
		return
	# Queue: 1 Wicklamp + 2 Bindcord → lamps would be 6, cordcord 3; demand after
	districts.apply_harvest()
	if districts.get_good_amount(districts.WICKLAMPS) != 5:
		# min(6, 5+1)=6, demand → 5
		push_error(
			"FAIL capacity Wicklamps=%d expected 5"
			% districts.get_good_amount(districts.WICKLAMPS)
		)
		quit(1)
		return
	if districts.get_good_amount(districts.BINDCORD) != 2:
		# 1+2=3, demand → 2
		push_error(
			"FAIL Bindcord after harvest=%d expected 2"
			% districts.get_good_amount(districts.BINDCORD)
		)
		quit(1)
		return
	print("PASS capacity clamps Harvest output")

	# --- Siphon cannot take below reserve ---
	districts.set_good_amount(districts.PRESSWATER, 1)
	if districts.divert_good(districts.PRESSWATER, 1):
		push_error("FAIL divert below reserve allowed")
		quit(1)
		return
	districts.set_good_amount(districts.PRESSWATER, 3)
	if not districts.divert_good(districts.PRESSWATER, 1):
		push_error("FAIL divert above reserve failed")
		quit(1)
		return
	if districts.get_good_amount(districts.PRESSWATER) != 2:
		push_error("FAIL divert amount wrong")
		quit(1)
		return
	print("PASS siphon respects protected reserve")

	# --- Cover: 70% target above reserve + 30% sibling ---
	districts.set_good_amount(districts.PRESSWATER, 6)  # 5 above
	districts.set_good_amount(districts.SEALBRINE, 1)  # 0 above
	var cover_skewed: float = districts.get_cover_for_good(districts.PRESSWATER)
	districts.set_good_amount(districts.SEALBRINE, 6)  # 5 above
	var cover_balanced: float = districts.get_cover_for_good(districts.PRESSWATER)
	if cover_balanced <= cover_skewed:
		push_error("FAIL sibling production did not raise Cover")
		quit(1)
		return
	var notice_thin: float = districts.get_siphon_notice_chance(districts.PRESSWATER)
	districts.set_good_amount(districts.PRESSWATER, 2)
	districts.set_good_amount(districts.SEALBRINE, 1)
	var notice_worse: float = districts.get_siphon_notice_chance(districts.PRESSWATER)
	if notice_worse <= notice_thin:
		push_error("FAIL thin production did not raise notice chance")
		quit(1)
		return
	print("PASS Cover uses target + sibling production above reserve")

	# --- Verdigris: Wickwork production OR Mid Heart Tallies ---
	districts.reset_production()
	wallet.set_amount(wallet.VERDIGRIS, 2)
	wallet.set_amount(wallet.TALLIES, 0)
	if not districts.queue_material(wallet.VERDIGRIS):
		push_error("FAIL Verdigris to Wickwork")
		quit(1)
		return
	if districts.get_queued(districts.WICKLAMPS) != 2:
		push_error("FAIL Verdigris Wicklamps queue")
		quit(1)
		return
	if districts.get_queued(districts.BINDCORD) != 1:
		push_error("FAIL Verdigris Bindcord queue")
		quit(1)
		return
	if not districts.turn_in_verdigris_for_tallies():
		push_error("FAIL Verdigris Mid Heart turn-in")
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != 3:
		push_error("FAIL Verdigris Tallies=%d expected 3" % wallet.get_amount(wallet.TALLIES))
		quit(1)
		return
	print("PASS Verdigris Wickwork or Mid Heart Tallies")

	# --- Efficiency adds +1 output per queued input ---
	districts.reset_production()
	upgrades.set_level(upgrades.FARMS_EFF, 2)
	wallet.set_amount(wallet.SPOREMEAL, 1)
	wallet.set_amount(wallet.TALLIES, 0)
	districts.queue_material(wallet.SPOREMEAL)
	# Base 2+1, plus +2 to primary (Glowrations)
	if districts.get_queued(districts.GLOWRATIONS) != 4:
		push_error(
			"FAIL efficiency queue Glowrations=%d expected 4"
			% districts.get_queued(districts.GLOWRATIONS)
		)
		quit(1)
		return
	if districts.get_queued(districts.GLOWFIBER) != 1:
		push_error("FAIL efficiency should not change sibling base")
		quit(1)
		return
	print("PASS efficiency adds +1 per queued input to primary good")

	# --- Forbidden siphon diverts named good, not Salvage ---
	districts.reset_production()
	districts.set_good_amount(districts.BINDCORD, 4)
	wallet.set_amount(wallet.SALVAGE, 100)
	upgrades.set_siphon_station_open(true)
	upgrades.force_siphon_notice = false
	upgrades.set_level(upgrades.DIG_YIELD, 0)
	var salvage_before: int = wallet.get_amount(wallet.SALVAGE)
	if not upgrades.siphon_for_upgrade(upgrades.DIG_YIELD):
		push_error("FAIL Dig Yield siphon with Bindcord")
		quit(1)
		return
	if wallet.get_amount(wallet.SALVAGE) != salvage_before:
		push_error("FAIL forbidden siphon spent Salvage")
		quit(1)
		return
	if districts.get_good_amount(districts.BINDCORD) != 3:
		push_error("FAIL Dig Yield did not divert Bindcord")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 1:
		push_error("FAIL Dig Yield level")
		quit(1)
		return
	print("PASS forbidden siphon diverts District production")

	# --- Save / load named goods + queue + Materials ---
	districts.reset_production()
	upgrades.set_level(upgrades.FARMS_EFF, 0)
	districts.set_good_amount(districts.GLOWRATIONS, 4)
	districts.set_good_amount(districts.GLOWFIBER, 2)
	wallet.set_amount(wallet.SPOREMEAL, 3)
	wallet.set_amount(wallet.TALLIES, 5)
	districts.queue_material(wallet.SPOREMEAL)
	if not save_load.save_game():
		push_error("FAIL save")
		quit(1)
		return
	districts.reset_production()
	wallet.set_amount(wallet.SPOREMEAL, 0)
	wallet.set_amount(wallet.TALLIES, 0)
	if not save_load.load_game():
		push_error("FAIL load")
		quit(1)
		return
	if districts.get_good_amount(districts.GLOWRATIONS) != 4:
		push_error("FAIL Glowrations after load")
		quit(1)
		return
	if districts.get_queued(districts.GLOWRATIONS) != 2:
		push_error("FAIL queue after load")
		quit(1)
		return
	if wallet.get_amount(wallet.SPOREMEAL) != 2:
		# started 3, queued 1 → 2 saved
		push_error("FAIL Materials after load %d" % wallet.get_amount(wallet.SPOREMEAL))
		quit(1)
		return
	if wallet.get_amount(wallet.TALLIES) != 6:
		# 5 + 1 from queue
		push_error("FAIL Tallies after load %d" % wallet.get_amount(wallet.TALLIES))
		quit(1)
		return
	print("PASS save migrates named goods, queue, Materials")

	# --- Legacy district_stocks float map ---
	districts.reset_production()
	var legacy := {
		"version": 2,
		"salvage": 7,
		"upgrade_levels": {},
		"social_standing": 50,
		"harvest_timer": 60.0,
		"pending_lie": false,
		"district_stocks": {"farms": 4.0, "wickwork": 2.0, "cistern": 5.0},
	}
	var path: String = save_load.SAVE_PATH
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	if not save_load.load_game():
		push_error("FAIL legacy load")
		quit(1)
		return
	if districts.get_good_amount(districts.GLOWRATIONS) != 4:
		push_error("FAIL legacy farms→Glowrations")
		quit(1)
		return
	if districts.get_good_amount(districts.WICKLAMPS) != 2:
		push_error("FAIL legacy wickwork→Wicklamps")
		quit(1)
		return
	if districts.get_good_amount(districts.PRESSWATER) != 5:
		push_error("FAIL legacy cistern→Presswater")
		quit(1)
		return
	if districts.get_good_amount(districts.GLOWFIBER) != districts.PROTECTED_RESERVE:
		push_error("FAIL legacy sibling should stay at reserve")
		quit(1)
		return
	print("PASS legacy district_stocks migrate to primary goods")

	save_load.clear_save()
	print("DISTRICT_PRODUCTION_TESTS_PASSED")
	quit(0)
