extends SceneTree
## Build Bible Spec 29 (Projects) acceptance tests — against the AI-drafted
## spec, pending USER review.
##
## Not covered here, and why:
## - The world visibly changing on completion (new lift, repaired route) —
##   dressing content keys off the completion story flag; the flag is what
##   is tested.
## - Autonomous healthy-district improvements (canon §26 DIRECTION) —
##   authored world changes, not this system.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var projects: Node = root.get_node_or_null("Projects")
	var district: Node = root.get_node_or_null("District")
	var storage: Node = root.get_node_or_null("Storage")
	var web: Node = root.get_node_or_null("CapabilityWeb")
	var hauling: Node = root.get_node_or_null("Hauling")
	var story: Node = root.get_node_or_null("Story")
	var journal: Node = root.get_node_or_null("Journal")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if projects == null or district == null or storage == null or web == null or hauling == null or story == null or journal == null or fact_log == null or bus == null or save_load == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	for n in [projects, district, storage, web, hauling, story]:
		n.reset_all()
	journal.clear_all()
	fact_log.clear_all()
	var completed: Array = []
	bus.project_completed.connect(func(id: StringName, d: StringName) -> void: completed.append({"id": id, "district": d}))
	var CAP := &"wickwork_second_rope_walk"
	var CIV := &"east_freight_lift_repair"
	var W := &"wickwork"

	# --- 1. Starting needs knowledge and a district not in shortage;
	# starting registers building Demand. ---
	if (projects.get_project_ids() as Array) != [CIV, CAP]:
		_fail("projects not loaded from content: %s" % [projects.get_project_ids()])
		return
	var no_knowledge: Dictionary = projects.start(CAP)
	if bool(no_knowledge["success"]) or str(no_knowledge["reason"]) != "knowledge_missing":
		_fail("a project needing knowledge started without it: %s" % [no_knowledge])
		return
	journal.unlock_record(&"nursery_rhyme")  # -> harness_reinforcement Understood
	if not bool(web.is_understood(&"harness_reinforcement")):
		_fail("setup: knowledge not understood")
		return
	district.register_demand_contributor(W, "crisis", "Cable failure", 6.0)  # shortage
	var short: Dictionary = projects.start(CAP)
	if bool(short["success"]) or str(short["reason"]) != "district_in_shortage":
		_fail("a project should not start in a district in shortage: %s" % [short])
		return
	district.unregister_demand_contributor(W, "crisis")
	var demand_before: float = float(district.get_demand(W))
	var started: Dictionary = projects.start(CAP)
	if not bool(started["success"]) or projects.get_status(CAP) != &"in_progress" or not is_equal_approx(float(district.get_demand(W)), demand_before + 2.0):
		_fail("starting did not register building Demand: %s (demand %s -> %s)" % [started, demand_before, district.get_demand(W)])
		return
	var twice: Dictionary = projects.start(CAP)
	if bool(twice["success"]) or str(twice["reason"]) != "already_started":
		_fail("starting twice not refused: %s" % [twice])
		return
	print("PASS starting needs knowledge and district capacity, and registers building Demand")

	# --- 2. Contributions withdraw exactly what's there; completion drops
	# the building Demand and adds a permanent Capacity contributor + flag. ---
	var capacity_before: float = float(district.get_capacity(W))
	if int(projects.contribute(CAP, &"ravelstone", 3)) != 0:
		_fail("contributed Materials the player doesn't have")
		return
	storage.deposit_material(&"ravelstone", 2)
	if int(projects.contribute(CAP, &"ravelstone", 5)) != 2 or int(storage.get_material_count(&"ravelstone")) != 0:
		_fail("contribution should take min(asked, needed, stored)")
		return
	storage.deposit_material(&"ravelstone", 5)
	if int(projects.contribute(CAP, &"ravelstone", 5)) != 1 or int(storage.get_material_count(&"ravelstone")) != 4:
		_fail("contribution beyond the need should be capped at the need")
		return
	if int(projects.contribute(CAP, &"verdigris", 1)) != 0:
		_fail("an unrelated Material counted")
		return
	# The Sutral arrives physically, in the towed bundle.
	hauling.attach(&"sutral", 3)
	if int(projects.contribute_from_bundle(CAP)) != 2 or bool(hauling.is_loaded()) or int(storage.get_material_count(&"sutral")) != 1:
		_fail("bundle contribution should use what's needed and bank the rest")
		return
	if projects.get_status(CAP) != &"complete" or completed.size() != 1 or completed[0]["id"] != CAP:
		_fail("project should complete once every requirement is met: %s" % projects.get_status(CAP))
		return
	if not is_equal_approx(float(district.get_demand(W)), demand_before) or not is_equal_approx(float(district.get_capacity(W)), capacity_before + 2.0):
		_fail("completion should drop building Demand and add lasting Capacity (demand %s, capacity %s)" % [district.get_demand(W), district.get_capacity(W)])
		return
	if not bool(story.has_flag(&"wickwork_second_rope_walk_built")) or (fact_log.get_by_type(&"project_completed") as Array).size() != 1:
		_fail("completion should set the story flag and log a fact")
		return
	var done: Dictionary = projects.start(CAP)
	if bool(done["success"]) or str(done["reason"]) != "already_complete":
		_fail("a complete project restarted: %s" % [done])
		return
	print("PASS contributions withdraw exactly what's there; a Capacity project completes into lasting Capacity + a story flag")

	# --- 3. A civic project carries Demand while building and leaves a
	# smaller maintenance Demand after. ---
	var d0: float = float(district.get_demand(W))
	projects.start(CIV)
	if not is_equal_approx(float(district.get_demand(W)), d0 + 3.0):
		_fail("civic building Demand not registered")
		return
	storage.deposit_material(&"sutral", 3)
	projects.contribute(CIV, &"sutral", 3)
	if projects.get_status(CIV) != &"complete" or not is_equal_approx(float(district.get_demand(W)), d0 + 1.0) or not bool(story.has_flag(&"east_freight_lift_repaired")):
		_fail("civic completion should leave only maintenance Demand + its flag (demand %s)" % district.get_demand(W))
		return
	print("PASS a civic project carries Demand while building and a smaller maintenance Demand after")

	# --- 4. Persistence. ---
	var pre: Dictionary = projects.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	projects.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if projects.save_state() != pre or projects.get_status(CAP) != &"complete":
		_fail("Projects did not round-trip")
		return
	print("PASS project state persists")

	save_load.clear_save()
	for n in [projects, district, storage, web, hauling, story]:
		n.reset_all()
	journal.clear_all()
	fact_log.clear_all()
	print("PROJECTS_TESTS_PASSED")
	quit(0)
