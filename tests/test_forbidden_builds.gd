extends SceneTree
## Build Bible Spec 28 (Forbidden Builds) acceptance tests — against the
## AI-drafted spec, pending USER review.
##
## Not covered here, and why:
## - Fabrication consuming civic time — tuning's fabrication_cycles is 0
##   for the slice (canon: exact build-time rules are tuning).
## - Who the examining authority is in the world (Council / Steward
##   scene content) — examine()'s examiner_is_authority flag is the contract.
## - Full graft removal back to an unmodified body — canon says it needs
##   no definition before the slice.

const RigStationScript := preload("res://rig_station.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var forbidden: Node = root.get_node_or_null("ForbiddenBuilds")
	var web: Node = root.get_node_or_null("CapabilityWeb")
	var rig: Node = root.get_node_or_null("Rig")
	var homes: Node = root.get_node_or_null("Homes")
	var storage: Node = root.get_node_or_null("Storage")
	var wallet: Node = root.get_node_or_null("Wallet")
	var trust: Node = root.get_node_or_null("Trust")
	var journal: Node = root.get_node_or_null("Journal")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if forbidden == null or web == null or rig == null or homes == null or storage == null or wallet == null or trust == null or journal == null or fact_log == null or bus == null or save_load == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	for n in [forbidden, web, rig, homes, storage, wallet, trust]:
		n.reset_all()
	journal.clear_all()
	fact_log.clear_all()
	var trust_events: Array = []
	bus.trust_changed.connect(func(_s: StringName, delta: float, _r: String) -> void: trust_events.append(delta))
	var Q := &"quieting_coupler"

	# --- 1. Building refuses distinctly: away from a workspace / below
	# Mid Reach, then (at a Mid Reach workspace) while anything the design
	# needs is missing — including the diverted output. ---
	var away: Dictionary = forbidden.build(Q)
	if bool(away["success"]) or str(away["reason"]) != "not_at_workspace":
		_fail("build away from a workspace should refuse: %s" % [away])
		return
	var body := CharacterBody2D.new()
	body.name = "Player"
	body.add_to_group("player")
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	shape.shape = rect
	body.add_child(shape)
	root.add_child(body)
	var workspace: Area2D = RigStationScript.new()
	workspace.station_kind = &"workspace"
	root.add_child(workspace)
	body.global_position = workspace.position
	for _i in range(4):
		await physics_frame
	var lower: Dictionary = forbidden.build(Q)
	if bool(lower["success"]) or str(lower["reason"]) != "residence_tier_too_low":
		_fail("build at the Lower home's workspace should refuse for residence: %s" % [lower])
		return
	homes.grant_residence(&"mid_reach", "test")
	var unknown_design: Dictionary = forbidden.build(Q)
	if bool(unknown_design["success"]) or str(unknown_design["reason"]) != "not_available" or (unknown_design["missing"] as Array).is_empty():
		_fail("an unknown/unavailable design should refuse with what's missing: %s" % [unknown_design])
		return
	var not_forbidden: Dictionary = forbidden.build(&"load_harness")
	if bool(not_forbidden["success"]) or str(not_forbidden["reason"]) != "not_a_forbidden_design":
		_fail("Approved Gear is not built here: %s" % [not_forbidden])
		return
	# Discover + gather everything except the diverted output.
	storage.add_component(&"firstfall_coupling")  # -> Known
	journal.unlock_record(&"firmament_note")  # -> Understood
	storage.deposit_material(&"verdigris", 2)
	var no_output: Dictionary = forbidden.build(Q)
	if bool(no_output["success"]) or str(no_output["reason"]) != "not_available" or not (no_output["missing"] as Array).any(func(m: String) -> bool: return m.contains("diverted")):
		_fail("without stashed diverted output the build should refuse naming it: %s" % [no_output])
		return
	if int(storage.get_material_count(&"verdigris")) != 2 or int(storage.count_components(&"firstfall_coupling")) != 1:
		_fail("a refused build consumed something")
		return
	print("PASS building refuses distinctly for workspace, residence, design kind and missing recipe parts — consuming nothing")

	# --- 2. With everything, one build consumes exactly the recipe and
	# installs the graft in no slot; a second build is refused. ---
	storage.deposit_concealed(&"wickwork", 3)
	if not bool(web.is_available(Q)):
		_fail("setup: design should be Available now: %s" % [web.get_missing(Q)])
		return
	var slots_before: Array = rig.get_equipped()
	var built: Dictionary = forbidden.build(Q)
	if not bool(built["success"]) or not bool(rig.is_grafted(Q)) or (rig.get_equipped() as Array) != slots_before:
		_fail("build failed or used a slot: %s" % [built])
		return
	if int(storage.get_material_count(&"verdigris")) != 0 or int(storage.count_components(&"firstfall_coupling")) != 0 or int(storage.get_concealed(&"wickwork")) != 0:
		_fail("build did not consume exactly the recipe")
		return
	if (fact_log.get_by_type(&"forbidden_build") as Array).size() != 1 or forbidden.get_graft_concealment(Q) != &"basic":
		_fail("build should log one forbidden_build fact and start the graft at Basic concealment")
		return
	var again: Dictionary = forbidden.build(Q)
	if bool(again["success"]) or str(again["reason"]) != "already_grafted":
		_fail("a second build of an installed graft should refuse: %s" % [again])
		return
	print("PASS one build consumes exactly the recipe and installs the graft using no slot")

	# --- 3. Examiner-restricted discovery: an ordinary examination never
	# finds a graft; an authority's Basic examination exposes a Basic
	# graft with one Trust event; Improved concealment survives it. ---
	trust_events.clear()
	var ordinary: Dictionary = forbidden.examine(Q, false, &"advanced")
	if bool(ordinary["found"]) or ordinary["outcome"] != &"not_recognised" or not trust_events.is_empty():
		_fail("a non-authority examination should never recognise a graft: %s" % [ordinary])
		return
	var exposed: Dictionary = forbidden.examine(Q, true, &"basic")
	if not bool(exposed["found"]) or trust_events.size() != 1 or float(trust_events[0]) >= 0.0 or (fact_log.get_by_type(&"graft_exposed") as Array).size() != 1:
		_fail("an authority's Basic examination should expose a Basic graft with one Trust event: %s %s" % [exposed, trust_events])
		return
	trust_events.clear()
	wallet.earn(20, "pay")
	var improved: Dictionary = forbidden.improve_graft_concealment(Q)
	if not bool(improved["success"]) or forbidden.get_graft_concealment(Q) != &"improved":
		_fail("improve_graft_concealment failed: %s" % [improved])
		return
	var survived: Dictionary = forbidden.examine(Q, true, &"basic")
	if bool(survived["found"]) or survived["outcome"] != &"concealed" or not trust_events.is_empty():
		_fail("Improved concealment should survive a Basic examination: %s" % [survived])
		return
	if not bool(forbidden.examine(Q, true, &"improved")["found"]):
		_fail("a targeted (Improved) examination should find an Improved graft")
		return
	if bool(forbidden.examine(&"load_harness", true, &"advanced")["found"]):
		_fail("examining something that isn't a graft found something")
		return
	print("PASS ordinary examinations never recognise a graft; an authority exposes it per concealment tier")

	# --- 4. Concealment tiers persist. ---
	var pre: Dictionary = forbidden.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	forbidden.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if forbidden.save_state() != pre or forbidden.get_graft_concealment(Q) != &"improved":
		_fail("graft concealment did not round-trip")
		return
	print("PASS graft concealment persists")

	body.queue_free()
	workspace.queue_free()
	save_load.clear_save()
	for n in [forbidden, web, rig, homes, storage, wallet, trust]:
		n.reset_all()
	journal.clear_all()
	fact_log.clear_all()
	await process_frame
	print("FORBIDDEN_BUILDS_TESTS_PASSED")
	quit(0)
