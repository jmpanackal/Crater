extends SceneTree
## Build Bible Spec 31 (Access / Gates) acceptance tests — against the
## AI-drafted spec, pending USER review.
##
## Not covered here, and why:
## - Warden NPCs physically manning a gate — content; the gate explains
##   itself through its prompt and Perception decides who saw a bypass.
## - Which routes get gates beyond Vaultward — level authoring.

const AccessGateScript := preload("res://access_gate.gd")
const ZoneAnchorScript := preload("res://zone_anchor.gd")


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
	var access: Node = root.get_node_or_null("Access")
	var trust: Node = root.get_node_or_null("Trust")
	var story: Node = root.get_node_or_null("Story")
	var homes: Node = root.get_node_or_null("Homes")
	var npcs: Node = root.get_node_or_null("Npcs")
	var perception: Node = root.get_node_or_null("Perception")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var clock: Node = root.get_node_or_null("Clock")
	var community: Node = root.get_node_or_null("Community")
	if access == null or trust == null or story == null or homes == null or npcs == null or perception == null or fact_log == null or save_load == null or clock == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	for n in [trust, story, homes]:
		n.reset_all()
	fact_log.clear_all()
	perception.clear_cooldowns()

	# --- 1. A gate is solid until each requirement is met, opens on the
	# very event that meets it, and explains itself without numbers. ---
	var gate: StaticBody2D = AccessGateScript.new()
	gate.gate_id = &"east_ward"
	gate.required_trust = &"relied_on"
	gate.required_flag = &"east_ward_clearance"
	gate.display_name = "East ward gate"
	gate.position = Vector2(0, 0)
	root.add_child(gate)
	await process_frame
	var shape := gate.get_node("CollisionShape2D") as CollisionShape2D
	var verdict: Dictionary = access.can_pass(&"east_ward")
	if bool(gate.is_open()) or shape.disabled or bool(verdict["ok"]) or str(verdict["reason"]) != "trust_too_low":
		_fail("gate should start closed for Trust: %s" % [verdict])
		return
	var prompt := str(gate.get_interact_prompt())
	if prompt.contains("/") or prompt.contains("70") or not prompt.contains("East ward gate") or prompt.length() < 20:
		_fail("prompt should explain in words, never numbers: '%s'" % prompt)
		return
	trust.submit_trust_event(&"major_accomplishment", 30.0, "Opened the gallery")  # -> relied_on: re-evaluated on the event
	if bool(gate.is_open()) or str(access.can_pass(&"east_ward")["reason"]) != "clearance_missing":
		_fail("with standing met the gate should still wait on clearance: %s" % [access.can_pass(&"east_ward")])
		return
	story.set_flag(&"east_ward_clearance", "The Steward vouched for you")
	await process_frame  # set_deferred on the shape
	if not bool(gate.is_open()) or not shape.disabled or not bool(access.is_open(&"east_ward")):
		_fail("meeting the last requirement should open the gate on that event (open %s, disabled %s)" % [gate.is_open(), shape.disabled])
		return
	if not str(gate.get_interact_prompt()).contains("open"):
		_fail("open gate prompt wrong: '%s'" % gate.get_interact_prompt())
		return
	if (access.get_gate_ids() as Array) != [&"east_ward"]:
		_fail("gate not registered: %s" % [access.get_gate_ids()])
		return
	print("PASS a gate opens on the event that meets its last requirement, and explains itself without numbers")

	# --- 2. A residence-gated gate; unknown gate; direct rule evaluation. ---
	var ward: StaticBody2D = AccessGateScript.new()
	ward.gate_id = &"ashram_gate"
	ward.required_residence = &"ashram_heights"
	ward.position = Vector2(400, 0)
	root.add_child(ward)
	await process_frame
	if bool(ward.is_open()) or str(access.can_pass(&"ashram_gate")["reason"]) != "residence_too_low":
		_fail("residence gate should be closed at the Lower home")
		return
	homes.grant_residence(&"ashram_heights", "test")
	await process_frame
	if not bool(ward.is_open()):
		_fail("granting the residence should open the ward gate")
		return
	if bool(access.can_pass(&"no_such_gate")["ok"]) or not bool(access.evaluate({"trust": &"", "flag": &"", "residence": &""})["ok"]):
		_fail("unknown gate / empty requirements evaluated wrong")
		return
	print("PASS residence-gated ways open with the residence; the rule is usable without a node")

	# --- 3. Bypassing a CLOSED gate into the area beyond is a restricted
	# entry — a fact, and witnessable; beyond an OPEN gate, nothing. ---
	homes.reset_all()
	await process_frame
	if bool(ward.is_open()):
		_fail("setup: ward gate should close again at the Lower home")
		return
	var body := CharacterBody2D.new()
	body.name = "Player"
	body.add_to_group("player")
	body.collision_layer = 1
	body.collision_mask = 0
	var bshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	bshape.shape = rect
	body.add_child(bshape)
	root.add_child(body)
	# A loaded NPC standing right there to see it.
	var anchor: Node2D = ZoneAnchorScript.new()
	anchor.zone_id = "glowbeds"
	anchor.add_child(Marker2D.new())
	anchor.position = ward.position + Vector2(-40, 0)
	root.add_child(anchor)
	var pell := FakeBody.new()
	root.add_child(pell)
	npcs.register_agent(&"pell", pell)
	await process_frame
	await process_frame
	pell.facing = 1.0
	fact_log.clear_all()
	body.global_position = Vector2(3000, 3000)
	for _i in range(3):
		await physics_frame
	body.global_position = ward.position + ward.beyond_offset  # dropped in past the closed gate
	for _i in range(4):
		await physics_frame
	if (fact_log.get_by_type(&"restricted_entry") as Array).size() != 1:
		_fail("entering beyond a closed gate should log one restricted_entry fact (%d)" % (fact_log.get_by_type(&"restricted_entry") as Array).size())
		return
	var seen: Array = fact_log.get_by_type(&"seen_entering_restricted_area")
	if seen.size() != 1 or (seen[0]["witnesses"] as Array) != ["pell"]:
		_fail("a loaded NPC beside a closed gate should witness the bypass: %s" % [seen])
		return
	# Beyond an open gate: nothing.
	homes.grant_residence(&"ashram_heights", "test")
	await process_frame
	fact_log.clear_all()
	perception.clear_cooldowns()
	body.global_position = Vector2(3000, 3000)
	for _i in range(3):
		await physics_frame
	body.global_position = ward.position + ward.beyond_offset
	for _i in range(4):
		await physics_frame
	if fact_log.count() != 0:
		_fail("passing an open gate logged something: %s" % [fact_log.get_all()])
		return
	print("PASS bypassing a closed gate is a witnessable restricted entry; an open gate is just a way")

	# --- 4. main.tscn's Vaultward gate is a real gate: closed at start,
	# open with the Ashram Heights residence. ---
	homes.reset_all()
	npcs.unregister_agent(&"pell")
	pell.queue_free()
	anchor.queue_free()
	gate.queue_free()
	ward.queue_free()
	body.queue_free()
	await process_frame
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	if not (access.get_gate_ids() as Array).has(&"vaultward"):
		_fail("main.tscn has no registered Vaultward gate: %s" % [access.get_gate_ids()])
		return
	if bool(access.is_open(&"vaultward")) or str(access.can_pass(&"vaultward")["reason"]) != "residence_too_low":
		_fail("Vaultward should be closed at the start: %s" % [access.can_pass(&"vaultward")])
		return
	homes.grant_residence(&"ashram_heights", "test")
	await process_frame
	if not bool(access.is_open(&"vaultward")):
		_fail("Vaultward should open with the Ashram Heights residence")
		return
	print("PASS main.tscn's Vaultward gate is closed at start and opens with Ashram Heights")

	scene.queue_free()
	save_load.clear_save()
	for n in [trust, story, homes]:
		n.reset_all()
	fact_log.clear_all()
	clock.reset_all()
	await process_frame
	print("ACCESS_TESTS_PASSED")
	quit(0)
