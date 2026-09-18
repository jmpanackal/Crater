extends SceneTree
## Build Bible Spec 23 (Tallies + Approved Gear Orders) acceptance tests.
##
## Not covered here, and why:
## - Jobs settling into Wallet.earn (Spec 24) — that spec's; here earn()
##   is driven directly and proven never to touch Trust.
## - An order counter interactable in the world — presentation; the
##   station rule Spec 14 locked is respected by ordering never equipping.
## - The retired Resources.TALLIES wallet — alongside, untouched, until
##   Spec 24 moves the work-order loop.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var wallet: Node = root.get_node_or_null("Wallet")
	var orders: Node = root.get_node_or_null("Orders")
	var rig: Node = root.get_node_or_null("Rig")
	var district: Node = root.get_node_or_null("District")
	var trust: Node = root.get_node_or_null("Trust")
	var bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var console: Node = root.get_node_or_null("DebugConsole")
	var community: Node = root.get_node_or_null("Community")
	if wallet == null or orders == null or rig == null or district == null or trust == null or bus == null or save_load == null or fact_log == null or console == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	wallet.reset_all()
	rig.reset_all()
	district.reset_all()
	trust.reset_all()
	fact_log.clear_all()
	var trust_events: Array = []
	bus.trust_changed.connect(func(standing: StringName, delta: float, reason: String) -> void: trust_events.append({"standing": standing, "delta": delta, "reason": reason}))
	var tallies_events: Array = []
	bus.tallies_changed.connect(func(balance: int, delta: int, reason: String) -> void: tallies_events.append({"balance": balance, "delta": delta, "reason": reason}))
	var W := &"wickwork"

	# --- 1. Wallet: earn/spend with a required reason; never negative;
	# earning Tallies never submits a Trust event (§17). ---
	if int(wallet.get_balance()) != int(wallet.get_starting_tallies()):
		_fail("fresh wallet should hold the tuned starting Tallies")
		return
	if bool(wallet.earn(5, "")) or bool(wallet.earn(0, "nothing")) or bool(wallet.earn(-3, "negative")):
		_fail("an earn without a reason / non-positive amount was accepted")
		return
	if not bool(wallet.earn(12, "Delivered two loads of Sutral to Wickwork")):
		_fail("valid earn refused")
		return
	if int(wallet.get_balance()) != 12 or tallies_events.size() != 1 or int(tallies_events[0]["delta"]) != 12:
		_fail("earn did not apply / emit (balance %d, events %s)" % [wallet.get_balance(), tallies_events])
		return
	if bool(wallet.spend(20, "Too much")) or bool(wallet.spend(3, "")) or int(wallet.get_balance()) != 12:
		_fail("spend beyond balance / without reason was accepted")
		return
	if not bool(wallet.spend(4, "Lamp oil")) or int(wallet.get_balance()) != 8:
		_fail("valid spend failed")
		return
	var reasons: Array[Dictionary] = wallet.get_reasons()
	if reasons.size() != 2 or int(reasons[0]["delta"]) != 12 or int(reasons[1]["delta"]) != -4 or not str(reasons[0]["reason"]).contains("Sutral"):
		_fail("reasons list wrong: %s" % [reasons])
		return
	if not trust_events.is_empty() or not (trust.get_trust_reasons() as Array).is_empty():
		_fail("earning/spending Tallies touched Trust: %s" % [trust_events])
		return
	print("PASS Wallet earns/spends only with a reason, never negative, and never touches Trust")

	# --- 2. Order terms come from Gear content; grafts are never orderable. ---
	var terms: Dictionary = orders.get_order_terms(&"load_harness")
	if terms.is_empty() or terms["district"] != W or int(terms["tallies"]) != 6 or not is_equal_approx(float(terms["output"]), 2.0):
		_fail("Load Harness order terms not loaded from content: %s" % [terms])
		return
	if not (orders.get_order_terms(&"quieting_coupler") as Dictionary).is_empty() or (orders.get_orderable_gear_ids() as Array).has(&"quieting_coupler"):
		_fail("a graft design was orderable")
		return
	var no_such: Dictionary = orders.order(&"pressure_bore")
	if bool(no_such["success"]) or str(no_such["reason"]) != "unknown_gear":
		_fail("unknown gear order not refused cleanly: %s" % [no_such])
		return
	var graft_order: Dictionary = orders.order(&"quieting_coupler")
	if bool(graft_order["success"]) or str(graft_order["reason"]) != "not_orderable":
		_fail("graft order not refused as not_orderable: %s" % [graft_order])
		return
	print("PASS order terms are Gear content; grafts and unknown ids are not orderable")

	# --- 3. A successful order spends exactly the Tallies, draws exactly
	# the District Output on the books, and adds the Gear to Rig's owned
	# list WITHOUT equipping it. ---
	wallet.reset_all()
	wallet.earn(20, "Season's work")
	var reserves_before: float = float(district.get_reserves(W))  # Wickwork starts at 2
	var ok: Dictionary = orders.order(&"load_harness")
	if not bool(ok["success"]) or int(ok["tallies_spent"]) != 6 or not is_equal_approx(float(ok["output_drawn"]), 2.0):
		_fail("order failed or spent wrong amounts: %s" % [ok])
		return
	if int(wallet.get_balance()) != 14 or not is_equal_approx(float(district.get_reserves(W)), reserves_before - 2.0):
		_fail("Tallies/output not drawn correctly (balance %d, reserves %s)" % [wallet.get_balance(), district.get_reserves(W)])
		return
	if not bool(rig.is_owned(&"load_harness")) or (rig.get_equipped() as Array).has(&"load_harness"):
		_fail("ordered Gear should be owned and NOT equipped")
		return
	# An authorized order is on the books: the next resolution sees no
	# unexplained loss.
	console.execute("force_advance 4")
	if float(district.get_last_resolution(W)["unexplained_loss"]) != 0.0 or (fact_log.get_by_type(&"district_discrepancy") as Array).size() != 0:
		_fail("a recorded order showed up as unexplained loss")
		return
	var again: Dictionary = orders.order(&"load_harness")
	if bool(again["success"]) or str(again["reason"]) != "already_owned" or int(wallet.get_balance()) != 14:
		_fail("re-ordering owned Gear was accepted or charged: %s" % [again])
		return
	print("PASS a successful order spends the right Tallies, draws recorded District Output, and adds owned-not-equipped Gear")

	# --- 4. Three distinct, atomic failures: insufficient Tallies,
	# insufficient District Output, district refusing for demand. ---
	wallet.reset_all()
	rig.reset_all()
	district.reset_all()
	wallet.earn(3, "Pocket change")
	var reserves_now: float = float(district.get_reserves(W))
	var poor: Dictionary = orders.order(&"fracture_pick")  # 8 Tallies
	if bool(poor["success"]) or str(poor["reason"]) != "insufficient_tallies" or int(wallet.get_balance()) != 3 or not is_equal_approx(float(district.get_reserves(W)), reserves_now):
		_fail("insufficient Tallies not refused atomically: %s" % [poor])
		return
	wallet.earn(20, "A good stretch")
	district.request_withdrawal(W, 10.0, {"recorded": true, "requester": "test_drain"})  # reserves -> 0
	var dry: Dictionary = orders.order(&"fracture_pick")  # needs 2 output
	if bool(dry["success"]) or str(dry["reason"]) != "insufficient_district_output" or int(wallet.get_balance()) != 23:
		_fail("insufficient District Output not refused atomically: %s" % [dry])
		return
	district.reset_all()  # reserves back to 2
	district.register_demand_contributor(W, "crisis", "Cable failure across the mid band", 6.0)  # demand 10 > cap 6 + 2: shortage
	if float(district.get_health(W)) >= 0.0:
		_fail("setup: Wickwork should be in shortage")
		return
	var refused: Dictionary = orders.order(&"fracture_pick")
	if bool(refused["success"]) or str(refused["reason"]) != "district_refused_for_demand" or int(wallet.get_balance()) != 23 or not is_equal_approx(float(district.get_reserves(W)), 2.0):
		_fail("district demand refusal not distinct/atomic: %s" % [refused])
		return
	district.unregister_demand_contributor(W, "crisis")
	var fine: Dictionary = orders.order(&"fracture_pick")
	if not bool(fine["success"]) or int(wallet.get_balance()) != 15:
		_fail("order should succeed once the district is comfortable again: %s" % [fine])
		return
	print("PASS insufficient Tallies, insufficient output, and demand refusal each fail distinctly with no partial spend")

	# --- 5. A Trust standing gate on an order reads Trust's ladder. ---
	wallet.earn(20, "More work")
	var gated: Dictionary = orders.order(&"dampening_wrap")  # needs relied_on; default standing is accepted
	if bool(gated["success"]) or str(gated["reason"]) != "trust_too_low":
		_fail("Trust-gated order not refused: %s" % [gated])
		return
	trust.submit_trust_event(&"major_accomplishment", 30.0, "Opened the new gallery")  # 80 -> relied_on
	district.reset_all()  # section 4's order drained Wickwork; refill so only the Trust gate is under test
	var allowed: Dictionary = orders.order(&"dampening_wrap")
	if not bool(allowed["success"]):
		_fail("order should be allowed at the required standing: %s (standing %s)" % [allowed, trust.get_trust()])
		return
	print("PASS Trust standing gates orders through Trust's own ladder")

	# --- 6. Wallet persists through the real SaveLoad path. ---
	var pre_save: Dictionary = wallet.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	wallet.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if wallet.save_state() != pre_save:
		_fail("Wallet did not round-trip:\n%s\nvs\n%s" % [pre_save, wallet.save_state()])
		return
	print("PASS Wallet persists through save/load")

	save_load.clear_save()
	wallet.reset_all()
	rig.reset_all()
	district.reset_all()
	trust.reset_all()
	fact_log.clear_all()
	print("ORDERS_TESTS_PASSED")
	quit(0)
