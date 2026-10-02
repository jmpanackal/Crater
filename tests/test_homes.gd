extends SceneTree
## Build Bible Spec 27 (Residences + Workspace) acceptance tests — against
## the AI-drafted spec, pending USER review.
##
## Not covered here, and why:
## - The residence scenes/interiors (Mid Reach, Ashram Heights) — content.
## - Confrontation dialogue / local restrictions after a discovery — the
##   facts and Trust event are the contract; Dialogue/Access content later.
## - Grafts on the body — never found by a home search (Spec 20); the
##   contraband a search reads is stolen output only.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _count(fact_log: Node, type: StringName, context: String) -> int:
	var n := 0
	for fact: Dictionary in fact_log.get_by_type(type):
		if str((fact["context"] as Dictionary).get("investigation_context", "")) == context:
			n += 1
	return n


func _run() -> void:
	var homes: Node = root.get_node_or_null("Homes")
	var story: Node = root.get_node_or_null("Story")
	var trust: Node = root.get_node_or_null("Trust")
	var wallet: Node = root.get_node_or_null("Wallet")
	var rig: Node = root.get_node_or_null("Rig")
	var storage: Node = root.get_node_or_null("Storage")
	var diversion: Node = root.get_node_or_null("Diversion")
	var district: Node = root.get_node_or_null("District")
	var investigation: Node = root.get_node_or_null("Investigation")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var bus: Node = root.get_node_or_null("EventBus")
	var clock: Node = root.get_node_or_null("Clock")
	var console: Node = root.get_node_or_null("DebugConsole")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if homes == null or story == null or trust == null or wallet == null or rig == null or storage == null or diversion == null or district == null or investigation == null or fact_log == null or bus == null or clock == null or console == null or save_load == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	for n in [homes, story, trust, wallet, rig, storage, diversion, district]:
		n.reset_all()
	fact_log.clear_all()
	var trust_events: Array = []
	bus.trust_changed.connect(func(_s: StringName, delta: float, reason: String) -> void: trust_events.append({"delta": delta, "reason": reason}))
	var warnings: Array = []
	bus.investigation_warning.connect(func(context: StringName, ratio: float) -> void: warnings.append({"context": context, "ratio": ratio}))
	var discoveries: Array = []
	bus.workspace_discovered.connect(func(units: int) -> void: discoveries.append(units))

	# --- 1. Acquiring Mid Reach needs story clearance, standing and
	# Tallies — each refusal distinct and atomic; Rig then permits grafting;
	# Ashram is not acquirable before Mid Reach. ---
	if homes.get_residence_tier() != &"lower" or homes.get_workspace_concealment() != &"basic" or rig.get_residence_tier() != &"lower":
		_fail("fresh game should start at the Lower home with a crude (Basic) workspace")
		return
	var no_flag: Dictionary = homes.acquire(&"mid_reach")
	if bool(no_flag["success"]) or str(no_flag["reason"]) != "story_clearance_missing":
		_fail("acquisition without story clearance not refused: %s" % [no_flag])
		return
	if not bool(story.set_flag(&"mid_reach_clearance", "The Steward's office posted your name")) or bool(story.set_flag(&"mid_reach_clearance", "again")) or bool(story.set_flag(&"x", "")):
		_fail("story flags: set once, refuse repeats and reason-less sets")
		return
	var low_trust: Dictionary = homes.acquire(&"mid_reach")
	if bool(low_trust["success"]) or str(low_trust["reason"]) != "trust_too_low":
		_fail("acquisition below the Trust standing not refused: %s" % [low_trust])
		return
	trust.submit_trust_event(&"major_accomplishment", 30.0, "Opened the gallery")  # -> relied_on
	var poor: Dictionary = homes.acquire(&"mid_reach")
	if bool(poor["success"]) or str(poor["reason"]) != "insufficient_tallies" or homes.get_residence_tier() != &"lower":
		_fail("acquisition without Tallies not refused atomically: %s" % [poor])
		return
	var skip: Dictionary = homes.acquire(&"ashram_heights")
	if bool(skip["success"]) or str(skip["reason"]) != "not_next_tier":
		_fail("skipping to Ashram Heights should be refused: %s" % [skip])
		return
	wallet.earn(40, "A season of work")
	var moved: Dictionary = homes.acquire(&"mid_reach")
	if not bool(moved["success"]) or homes.get_residence_tier() != &"mid_reach" or int(wallet.get_balance()) != 10 or rig.get_residence_tier() != &"mid_reach":
		_fail("acquiring Mid Reach failed: %s (balance %d)" % [moved, wallet.get_balance()])
		return
	if homes.get_workspace_concealment() != &"improved" or (fact_log.get_by_type(&"residence_acquired") as Array).size() != 1:
		_fail("Mid Reach should bring an Improved workspace and one residence fact")
		return
	if not bool(rig.can_graft_at_current_location()["ok"]) and str(rig.can_graft_at_current_location()["reason"]) == "residence_tier_too_low":
		_fail("Rig should no longer refuse grafting for residence tier")
		return
	if not bool(homes.grant_residence(&"ashram_heights", "story: the Council's house")) or homes.get_residence_tier() != &"ashram_heights":
		_fail("story grant failed")
		return
	print("PASS residence acquisition needs clearance + standing + Tallies, each refused distinctly; Rig reads the tier")

	# --- 2. A search: an empty workspace is found_nothing with no Trust
	# event; a Basic-concealed workspace holding stolen output is found by
	# a Basic (deliberate) search — facts, confiscation, books reconciled,
	# one Trust event; an Improved workspace survives a Basic search. ---
	homes.reset_all()  # Lower: Basic concealment
	fact_log.clear_all()
	trust_events.clear()
	var empty: Dictionary = homes.resolve_home_search(&"basic")
	if bool(empty["found"]) or _count(fact_log, &"found_nothing", "residence") != 1 or not trust_events.is_empty():
		_fail("an empty workspace should be found_nothing with no Trust event: %s" % [empty])
		return
	district.reset_all()
	diversion.complete_take(&"wickwork")
	diversion.complete_take(&"wickwork")
	storage.deposit_concealed(&"cistern", 3)  # already stashed earlier
	fact_log.clear_all()
	var found: Dictionary = homes.resolve_home_search(&"basic")
	if not bool(found["found"]) or int(found["units"]) != 5 or trust_events.size() != 1 or float(trust_events[0]["delta"]) >= 0.0:
		_fail("a Basic search of a Basic workspace with contraband should find it with one Trust event: %s %s" % [found, trust_events])
		return
	if _count(fact_log, &"found_evidence", "residence") != 2 or (fact_log.get_by_type(&"workspace_discovered") as Array).size() != 1 or discoveries != [5]:
		_fail("discovery facts wrong (found_evidence %d)" % _count(fact_log, &"found_evidence", "residence"))
		return
	if int(storage.get_concealed_total()) != 0 or int(diversion.get_carried_total()) != 0:
		_fail("contraband was not confiscated")
		return
	console.execute("force_advance 4")
	if float(district.get_last_resolution(&"wickwork")["unexplained_loss"]) != 0.0:
		_fail("confiscated units should reconcile the district's books")
		return
	if investigation.get_investigation_stage(&"residence") != &"found_evidence":
		_fail("stage should read from Homes' resolution facts")
		return
	# Improved concealment survives a deliberate search, falls to a targeted one.
	homes.grant_residence(&"mid_reach", "test")
	diversion.complete_take(&"wickwork")
	trust_events.clear()
	var survived: Dictionary = homes.resolve_home_search(&"basic")
	if bool(survived["found"]) or int(diversion.get_carried_total()) != 1 or not trust_events.is_empty():
		_fail("an Improved workspace should survive a Basic search: %s" % [survived])
		return
	var targeted: Dictionary = homes.resolve_home_search(&"improved")
	if not bool(targeted["found"]) or int(targeted["units"]) != 1:
		_fail("a targeted (Improved) search should find an Improved workspace: %s" % [targeted])
		return
	wallet.earn(20, "pay")
	if not bool(homes.improve_concealment()["success"]) or homes.get_workspace_concealment() != &"advanced" or bool(homes.improve_concealment()["success"]):
		_fail("improve_concealment should step to Advanced once")
		return
	print("PASS home searches resolve against concealment: empty -> nothing, Basic found by a deliberate search, Improved survives it")

	# --- 3. Fair warning, then a real delegated search: repeated district
	# discrepancies warn the residence context before Investigation
	# requests a home search, and that search is resolved by Homes. ---
	homes.reset_all()
	fact_log.clear_all()
	trust_events.clear()
	warnings.clear()
	diversion.reset_all()
	storage.reset_all()
	diversion.complete_take(&"wickwork")  # something to find
	var witnesses: Array[String] = []
	var threshold: float = float(investigation.get_threshold(&"residence"))
	var per_fact := 2.0
	var needed := int(ceil(threshold / per_fact))
	var warned_before_search := false
	var searched := false
	for i in range(needed):
		fact_log.record(&"district_discrepancy", "wickwork", &"wickwork", witnesses, {"district_id": "wickwork", "unexplained_loss": 3}, int(clock.get_cycles_elapsed()))
		var have_warning := (warnings.filter(func(w: Dictionary) -> bool: return w["context"] == &"residence") as Array).size() > 0
		var have_search := _count(fact_log, &"search_requested", "residence") > 0
		if have_warning and not have_search:
			warned_before_search = true
		if have_search:
			searched = true
			break
	if not warned_before_search or not searched:
		_fail("discrepancies should warn the residence context before a search is requested (warned %s, searched %s)" % [warned_before_search, searched])
		return
	if _count(fact_log, &"found_evidence", "residence") != 1 or int(diversion.get_carried_total()) != 0 or trust_events.size() != 1:
		_fail("the delegated home search should have been resolved by Homes (found_evidence %d, carried %d, trust %s)" % [_count(fact_log, &"found_evidence", "residence"), diversion.get_carried_total(), trust_events])
		return
	# (Each discrepancy also warns the wickwork context — one per context.)
	if _count(fact_log, &"investigation_warning", "residence") != 1:
		_fail("exactly one residence warning fact per fresh crossing (got %d)" % _count(fact_log, &"investigation_warning", "residence"))
		return
	print("PASS repeated discrepancies warn first, then a delegated home search resolves through Homes")

	# --- 4. Persistence. ---
	homes.grant_residence(&"mid_reach", "test")
	wallet.earn(20, "pay")
	homes.improve_concealment()
	story.set_flag(&"ashram_clearance", "test")
	var pre_home: Dictionary = homes.save_state()
	var pre_story: Dictionary = story.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	homes.reset_all()
	story.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if homes.save_state() != pre_home or story.save_state() != pre_story or homes.get_workspace_concealment() != &"advanced" or not bool(story.has_flag(&"ashram_clearance")):
		_fail("Homes/Story did not round-trip")
		return
	print("PASS residence, concealment and story flags persist")

	save_load.clear_save()
	for n in [homes, story, trust, wallet, rig, storage, diversion, district]:
		n.reset_all()
	fact_log.clear_all()
	clock.reset_all()
	print("HOMES_TESTS_PASSED")
	quit(0)
