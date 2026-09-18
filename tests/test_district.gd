extends SceneTree
## Build Bible Spec 22 (Districts: Capacity / Demand / District Reserves)
## acceptance tests. Wickwork carries real contributor content; the other
## two districts run the same machinery on placeholders.
##
## Not covered here, and why:
## - Diversion writing its own unexplained-loss facts (G4-A) — Spec 26's;
##   here an UNRECORDED withdrawal stands in for a theft and G4-C's
##   accounting check is what's proven.
## - Emergency jobs granting temporary Capacity (G5-B) — Spec 24 registers
##   them; the expiring-contributor mechanism they use is tested directly.
## - The retired districts.gd goods/Harvest economy — alongside, untouched.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var district: Node = root.get_node_or_null("District")
	var bus: Node = root.get_node_or_null("EventBus")
	var clock: Node = root.get_node_or_null("Clock")
	var console: Node = root.get_node_or_null("DebugConsole")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var investigation: Node = root.get_node_or_null("Investigation")
	var community: Node = root.get_node_or_null("Community")
	if district == null or bus == null or clock == null or console == null or fact_log == null or save_load == null or investigation == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	fact_log.clear_all()
	district.reset_all()
	var resolutions: Array = []
	bus.district_resolved.connect(func(id: StringName, summary: Dictionary) -> void: resolutions.append({"id": id, "summary": summary}))
	var W := &"wickwork"

	# --- 1. Districts are content; Demand is a sum of NAMED contributors
	# and the breakdown is the data. ---
	if (district.get_district_ids() as Array) != [&"cistern", &"glowbeds", &"wickwork"]:
		_fail("districts not loaded from content: %s" % [district.get_district_ids()])
		return
	if not is_equal_approx(float(district.get_capacity(W)), 6.0) or not is_equal_approx(float(district.get_demand(W)), 4.0) or not is_equal_approx(float(district.get_reserves(W)), 2.0) or not is_equal_approx(float(district.get_reserve_cap(W)), 5.0):
		_fail("Wickwork baseline wrong (cap %s demand %s reserves %s/%s)" % [district.get_capacity(W), district.get_demand(W), district.get_reserves(W), district.get_reserve_cap(W)])
		return
	var breakdown: Array[Dictionary] = district.get_demand_breakdown(W)
	if breakdown.size() != 2 or str(breakdown[0]["name"]) == "" or not is_equal_approx(float(breakdown[0]["amount"]) + float(breakdown[1]["amount"]), float(district.get_demand(W))):
		_fail("demand breakdown is not the named-contributor sum: %s" % [breakdown])
		return
	if not bool(district.register_demand_contributor(W, "west_expansion", "West expansion braces", 4.0)) or bool(district.register_demand_contributor(W, "nameless", "", 1.0)):
		_fail("registering a named contributor failed / a nameless one was accepted")
		return
	if not is_equal_approx(float(district.get_demand(W)), 8.0) or (district.get_demand_breakdown(W) as Array).size() != 3:
		_fail("registered contributor not in the live sum")
		return
	district.unregister_demand_contributor(W, "west_expansion")
	print("PASS districts load from content; Demand is the live sum of named contributors")

	# --- 2. A full resolution, driven by the real Ritual -> Rousing event,
	# follows canon's exact 5-step order. Wickwork: Capacity 6, Demand 4,
	# Reserves 2/5. ---
	console.execute("force_advance 4")  # rousing -> ... -> rousing: cycle 0 ends
	if resolutions.size() != 3 or (resolutions.filter(func(r: Dictionary) -> bool: return r["id"] == W) as Array).size() != 1:
		_fail("resolution should run exactly once per district per cycle: %s" % [resolutions.size()])
		return
	var r1: Dictionary = district.get_last_resolution(W)
	# 1: output 6; 2: serves 4; 3: surplus 2 banks up to cap 5 -> reserves 4; no deficit.
	if not is_equal_approx(float(r1["output"]), 6.0) or not is_equal_approx(float(r1["served"]), 4.0) or not is_equal_approx(float(r1["surplus_banked"]), 2.0) or not is_equal_approx(float(district.get_reserves(W)), 4.0) or float(r1["unmet"]) != 0.0:
		_fail("cycle 1 resolution wrong: %s" % [r1])
		return
	console.execute("force_advance 4")  # surplus 2 again, but cap 5: only 1 banks
	var r2: Dictionary = district.get_last_resolution(W)
	if not is_equal_approx(float(r2["surplus_banked"]), 1.0) or not is_equal_approx(float(district.get_reserves(W)), 5.0):
		_fail("surplus should fill Reserves only up to the Cap: %s" % [r2])
		return
	# Demand 9 > Capacity 6: 4. deficit 3 drawn from Reserves (5 -> 2), no unmet.
	district.register_demand_contributor(W, "west_expansion", "West expansion braces", 5.0)
	console.execute("force_advance 4")
	var r3: Dictionary = district.get_last_resolution(W)
	if not is_equal_approx(float(r3["served"]), 6.0) or not is_equal_approx(float(r3["drawn_from_reserves"]), 3.0) or not is_equal_approx(float(district.get_reserves(W)), 2.0) or float(r3["unmet"]) != 0.0:
		_fail("a short Output should draw on Reserves: %s" % [r3])
		return
	# 5. Reserves 2 can't cover deficit 3 -> unmet 1.
	console.execute("force_advance 4")
	var r4: Dictionary = district.get_last_resolution(W)
	if not is_equal_approx(float(r4["drawn_from_reserves"]), 2.0) or not is_equal_approx(float(r4["unmet"]), 1.0) or float(district.get_reserves(W)) != 0.0:
		_fail("what Reserves can't cover should become Unmet Demand: %s" % [r4])
		return
	if (fact_log.get_by_type(&"district_unmet_demand") as Array).size() != 1:
		_fail("unmet demand should be recorded once as a fact")
		return
	district.unregister_demand_contributor(W, "west_expansion")
	print("PASS resolution runs once per cycle in canon's 5-step order: produce, serve, bank to cap, draw reserves, unmet")

	# --- 3. Condition is derived live, never cached: a G5-C deposit shows
	# in the very next get_condition() with no resolution in between, and
	# the label always matches a recompute from the authoritative values. ---
	district.reset_all()
	fact_log.clear_all()
	var recompute := func(id: StringName) -> StringName:
		var health := (float(district.get_capacity(id)) + float(district.get_reserves(id)) - float(district.get_demand(id))) / maxf(float(district.get_demand(id)), 1.0)
		for step: Dictionary in district.get_condition_ladder():
			if health >= float(step["min_health"]):
				return step["id"]
		return &"critical"
	if district.get_condition(W) != recompute.call(W) or district.get_condition(W) != &"comfortable":
		_fail("baseline Wickwork condition should be Comfortable and match the recompute (%s)" % district.get_condition(W))
		return
	district.register_demand_contributor(W, "big_project", "A major project", 6.0)  # demand 10 > cap 6 + reserves 2
	var strained_or_worse: StringName = district.get_condition(W)
	if strained_or_worse != recompute.call(W) or strained_or_worse == &"comfortable" or strained_or_worse == &"stable":
		_fail("adding demand should worsen the live condition (%s)" % strained_or_worse)
		return
	var accepted: float = float(district.deposit(W, 3.0, {"source": "donation"}))
	if not is_equal_approx(accepted, 3.0) or not is_equal_approx(float(district.get_reserves(W)), 5.0):
		_fail("deposit not accepted up to the Cap (%s)" % accepted)
		return
	if district.get_condition(W) != recompute.call(W) or district.get_condition(W) == strained_or_worse:
		_fail("a deposit should be reflected immediately in get_condition (%s -> %s)" % [strained_or_worse, district.get_condition(W)])
		return
	if float(district.deposit(W, 5.0)) != 0.0:
		_fail("deposit beyond the Cap should accept nothing")
		return
	district.unregister_demand_contributor(W, "big_project")
	print("PASS condition is derived live and a G5-C deposit shows immediately")

	# --- 4. Withdrawals never go negative; only what's there is granted. ---
	district.reset_all()
	var granted: float = float(district.request_withdrawal(W, 10.0, {"recorded": true, "requester": "order"}))
	if not is_equal_approx(granted, 2.0) or float(district.get_reserves(W)) != 0.0 or float(district.request_withdrawal(W, 1.0)) != 0.0:
		_fail("withdrawal should grant only what's there (%s)" % granted)
		return
	print("PASS a withdrawal grants only what's actually in Reserves")

	# --- 5. G4-C: the same cumulative unexplained loss crosses the
	# discrepancy threshold sooner in a Strained district than a
	# Comfortable one; recorded (authorized) draws never count. ---
	district.reset_all()
	fact_log.clear_all()
	var comfortable_threshold: float = float(district.get_discrepancy_threshold(W))
	district.request_withdrawal(W, 2.0, {"recorded": false, "requester": "diversion"})  # theft of 2, below 3
	console.execute("force_advance 4")
	if (fact_log.get_by_type(&"district_discrepancy") as Array).size() != 0 or not is_equal_approx(float(district.get_last_resolution(W)["unexplained_loss"]), 2.0):
		_fail("a comfortable district should not notice a loss below its threshold (unexplained %s)" % district.get_last_resolution(W)["unexplained_loss"])
		return
	# Strain it: the same 2 units now cross the (lower) threshold.
	district.reset_all()
	fact_log.clear_all()
	district.register_demand_contributor(W, "big_project", "A major project", 5.0)  # demand 9 > capacity 6 + 2
	var strained_threshold: float = float(district.get_discrepancy_threshold(W))
	if strained_threshold >= comfortable_threshold:
		_fail("a strained district's threshold should be lower (%s vs %s)" % [strained_threshold, comfortable_threshold])
		return
	district.request_withdrawal(W, 2.0, {"recorded": false, "requester": "diversion"})
	console.execute("force_advance 4")
	var discrepancies: Array = fact_log.get_by_type(&"district_discrepancy")
	if discrepancies.size() != 1 or str((discrepancies[0]["context"] as Dictionary).get("district_id", "")) != "wickwork":
		_fail("a strained district should log a district_discrepancy fact for the same loss: %s" % [discrepancies])
		return
	if float(investigation.get_suspicion(W)) <= 0.0:
		_fail("the discrepancy fact should raise the district's derived suspicion")
		return
	# After a check the books match: the next clean cycle logs nothing.
	console.execute("force_advance 4")
	if (fact_log.get_by_type(&"district_discrepancy") as Array).size() != 1:
		_fail("a checked discrepancy re-logged with no new loss")
		return
	# A RECORDED draw of the same size is on the books — no discrepancy.
	district.request_withdrawal(W, 2.0, {"recorded": true, "requester": "order"})
	console.execute("force_advance 4")
	if (fact_log.get_by_type(&"district_discrepancy") as Array).size() != 1:
		_fail("an authorized, recorded withdrawal was treated as unexplained loss")
		return
	district.unregister_demand_contributor(W, "big_project")
	print("PASS unexplained loss crosses the threshold sooner when strained; recorded draws never count")

	# --- 6. Temporary contributors (G5-B emergency Capacity) expire after
	# their cycles; permanent ones don't. ---
	district.reset_all()
	district.register_capacity_contributor(W, "emergency_crew", "Emergency repair crew", 3.0, 2)
	if not is_equal_approx(float(district.get_capacity(W)), 9.0):
		_fail("temporary capacity not added")
		return
	console.execute("force_advance 4")
	if not is_equal_approx(float(district.get_capacity(W)), 9.0):
		_fail("temporary capacity expired one cycle early")
		return
	console.execute("force_advance 4")
	if not is_equal_approx(float(district.get_capacity(W)), 6.0):
		_fail("temporary capacity did not expire after its cycles")
		return
	print("PASS temporary contributors expire after their cycles")

	# --- 7. Persistence through the real SaveLoad path. ---
	district.reset_all()
	district.register_demand_contributor(W, "west_expansion", "West expansion braces", 2.0, 3)
	district.request_withdrawal(W, 1.0, {"recorded": false})
	console.execute("force_advance 4")
	var pre_save: Dictionary = district.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	district.reset_all()
	if (district.get_demand_breakdown(W) as Array).size() != 2:
		_fail("reset_all did not reseed from content")
		return
	if not save_load.load_game():
		_fail("load_game")
		return
	if district.save_state() != pre_save:
		_fail("District did not round-trip:\n%s\nvs\n%s" % [pre_save, district.save_state()])
		return
	print("PASS district state persists through a real save/load round-trip")

	save_load.clear_save()
	district.reset_all()
	fact_log.clear_all()
	clock.reset_all()
	print("DISTRICT_TESTS_PASSED")
	quit(0)
