extends SceneTree
## Build Bible Spec 26 (Diversion / Theft + Concealed Storage) acceptance
## tests — against the AI-drafted spec, pending USER review.
##
## Not covered here, and why:
## - Residence searches finding the concealed stockpile — Spec 27.
## - G9-A's "above a threshold becomes a physical haul load" — deferred
##   in the draft; the threshold sits in tuning as OPEN.
## - Scheduled NPC presence around stores (who is at the rack when) —
##   Spec 16 content; witness checks are proven with a placed body.

const StoreScript := preload("res://district_store.gd")
const ZoneAnchorScript := preload("res://zone_anchor.gd")
const RigStationScript := preload("res://rig_station.gd")


class FakeBody extends Node2D:
	var facing := 1.0
	func get_facing_sign() -> float:
		return facing
	func relocate_to(p: Vector2) -> void:
		global_position = p
	func set_present(p: bool) -> void:
		visible = p


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var diversion: Node = root.get_node_or_null("Diversion")
	var district: Node = root.get_node_or_null("District")
	var storage: Node = root.get_node_or_null("Storage")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var npcs: Node = root.get_node_or_null("Npcs")
	var perception: Node = root.get_node_or_null("Perception")
	var rig: Node = root.get_node_or_null("Rig")
	var trust: Node = root.get_node_or_null("Trust")
	var console: Node = root.get_node_or_null("DebugConsole")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var clock: Node = root.get_node_or_null("Clock")
	var community: Node = root.get_node_or_null("Community")
	if diversion == null or district == null or storage == null or fact_log == null or npcs == null or perception == null or rig == null or trust == null or console == null or save_load == null or clock == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	Input.action_release("interact")
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	diversion.reset_all()
	district.reset_all()
	storage.reset_all()
	fact_log.clear_all()
	trust.reset_all()
	perception.clear_cooldowns()
	var trust_events: Array = []
	root.get_node("EventBus").trust_changed.connect(func(_s: StringName, _d: float, _r: String) -> void: trust_events.append(1))
	var W := &"wickwork"

	# --- 1. A completed take: one unit out of Reserves unrecorded, one
	# carried on the player, one unexplained_loss fact; the district's next
	# resolution sees it as unexplained loss. Trust never moves. ---
	var store: Area2D = StoreScript.new()
	store.district_id = W
	store.position = Vector2(0, 0)
	root.add_child(store)
	await process_frame
	var reserves_before: float = float(district.get_reserves(W))
	if not str(store.get_interact_prompt()).contains("hold"):
		_fail("store prompt should offer the hold: '%s'" % store.get_interact_prompt())
		return
	Input.action_press("interact")
	store.on_interact(null)
	if not bool(store.is_taking()):
		_fail("hold did not begin")
		return
	var frames := int(ceil(float(store.hold_seconds()) * 60.0)) + 60
	for _i in range(frames):
		await physics_frame
		if int(diversion.get_carried(W)) > 0:
			break
	Input.action_release("interact")
	await physics_frame
	if int(diversion.get_carried(W)) != 1 or not is_equal_approx(float(district.get_reserves(W)), reserves_before - 1.0):
		_fail("take did not move one unit (carried %d, reserves %s)" % [diversion.get_carried(W), district.get_reserves(W)])
		return
	if (fact_log.get_by_type(&"unexplained_loss") as Array).size() != 1 or not trust_events.is_empty():
		_fail("take should log exactly one unexplained_loss fact and never move Trust")
		return
	console.execute("force_advance 4")
	if float(district.get_last_resolution(W)["unexplained_loss"]) < 1.0:
		_fail("the district's next resolution should see the unrecorded unit as unexplained loss: %s" % [district.get_last_resolution(W)])
		return
	print("PASS a take is one unrecorded unit out, one carried unit, one unexplained_loss fact, seen at resolution")

	# --- 2. Cancelling mid-hold changes nothing; an empty store refuses. ---
	var carried_before := int(diversion.get_carried(W))
	var reserves_now: float = float(district.get_reserves(W))
	Input.action_press("interact")
	store.on_interact(null)
	for _i in range(6):
		await physics_frame
	if not bool(store.is_taking()) or float(store.get_take_progress()) <= 0.0:
		_fail("hold not progressing")
		return
	Input.action_release("interact")
	for _i in range(3):
		await physics_frame
	if bool(store.is_taking()) or float(store.get_take_progress()) != 0.0 or int(diversion.get_carried(W)) != carried_before or float(district.get_reserves(W)) != reserves_now:
		_fail("cancelling mid-hold changed something")
		return
	district.request_withdrawal(W, 100.0, {"recorded": true, "requester": "drain"})
	if bool(store.begin_take()) or bool(diversion.can_take(W)["ok"]) or str(diversion.complete_take(W)["reason"]) != "nothing_to_take":
		_fail("an empty store should refuse the take")
		return
	print("PASS cancelling leaves everything untouched; an empty store refuses")

	# --- 3. Witnesses: a take begun with nobody nearby stays unwitnessed;
	# an NPC arriving mid-hold is caught by the next noise tick. ---
	district.reset_all()
	fact_log.clear_all()
	perception.clear_cooldowns()
	var anchor: Node2D = ZoneAnchorScript.new()
	anchor.zone_id = "wickwork"
	anchor.add_child(Marker2D.new())
	anchor.position = Vector2(5000, 0)  # Rook's idle point, far away
	root.add_child(anchor)
	var rook := FakeBody.new()
	root.add_child(rook)
	npcs.register_agent(&"rook", rook)
	await process_frame
	await process_frame
	Input.action_press("interact")
	store.on_interact(null)
	for _i in range(8):
		await physics_frame
	if (fact_log.get_by_type(&"theft_witnessed") as Array).size() != 0:
		_fail("a take with nobody nearby was witnessed")
		return
	rook.global_position = Vector2(60, 0)  # walks in mid-hold
	rook.facing = -1.0
	var tick_frames := int(ceil(float(diversion.get_noise_tick_seconds()) * 60.0)) + 10
	for _i in range(tick_frames):
		await physics_frame
	Input.action_release("interact")
	await physics_frame
	var witnessed: Array = fact_log.get_by_type(&"theft_witnessed")
	if witnessed.size() != 1 or (witnessed[0]["witnesses"] as Array) != ["rook"]:
		_fail("an NPC arriving mid-hold should be caught by the next tick: %s" % [witnessed])
		return
	print("PASS a quiet start is safe; a wanderer mid-hold is caught by the next noise tick")

	# --- 4. Stashing only at a workspace; concealed storage is Storage's;
	# returning anonymously vs openly. ---
	diversion.reset_all()
	district.reset_all()
	diversion.complete_take(W)
	diversion.complete_take(W)
	if int(diversion.stash_at_workspace()) != 0 or int(storage.get_concealed(W)) != 0 or int(diversion.get_carried(W)) != 2:
		_fail("stashing away from a workspace should refuse")
		return
	var workspace: Area2D = RigStationScript.new()
	workspace.station_kind = &"workspace"
	workspace.position = Vector2(300, 0)
	root.add_child(workspace)
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
	body.global_position = workspace.position
	for _i in range(4):
		await physics_frame
	if int(diversion.stash_at_workspace()) != 2 or int(storage.get_concealed(W)) != 2 or int(diversion.get_carried_total()) != 0:
		_fail("stash at the workspace failed (concealed %d)" % storage.get_concealed(W))
		return
	fact_log.clear_all()
	# Openly returning one unit is on the books; anonymously returning the
	# other shrinks the loss the next check sees without a record.
	var reserves_pre: float = float(district.get_reserves(W))
	if not is_equal_approx(float(diversion.return_output(W, 1, false)), 1.0) or not is_equal_approx(float(district.get_reserves(W)), reserves_pre + 1.0):
		_fail("open return did not land in Reserves")
		return
	if not is_equal_approx(float(diversion.return_output(W, 1, true)), 1.0) or int(storage.get_concealed(W)) != 0:
		_fail("anonymous return failed")
		return
	console.execute("force_advance 4")
	if float(district.get_last_resolution(W)["unexplained_loss"]) != 0.0:
		_fail("after returning both units the books should balance (unexplained %s)" % district.get_last_resolution(W)["unexplained_loss"])
		return
	if float(diversion.return_output(W, 1, true)) != 0.0:
		_fail("returning more than concealed should refuse")
		return
	print("PASS stashing needs a workspace; concealed storage is Storage's; open returns record, anonymous returns balance the loss")

	# --- 5. Carried and concealed persist through the real SaveLoad path. ---
	diversion.complete_take(W)
	storage.deposit_concealed(&"cistern", 3)
	var pre_div: Dictionary = diversion.save_state()
	var pre_store: Dictionary = storage.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	diversion.reset_all()
	storage.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if diversion.save_state() != pre_div or storage.save_state() != pre_store or int(storage.get_concealed(&"cistern")) != 3:
		_fail("carried/concealed did not round-trip")
		return
	print("PASS carried and concealed stolen goods persist")

	Input.action_release("interact")
	npcs.unregister_agent(&"rook")
	rook.queue_free()
	anchor.queue_free()
	store.queue_free()
	workspace.queue_free()
	body.queue_free()
	save_load.clear_save()
	diversion.reset_all()
	district.reset_all()
	storage.reset_all()
	fact_log.clear_all()
	trust.reset_all()
	clock.reset_all()
	await process_frame
	print("DIVERSION_TESTS_PASSED")
	quit(0)
