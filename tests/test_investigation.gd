extends SceneTree
## Build Bible Spec 20 (Suspicion + Investigation, derived) acceptance tests.
##
## Not covered here, and why:
## - District discrepancy facts as a suspicion source — Spec 22 produces
##   them; the weight and context scoping are exercised with a hand-
##   recorded fact of that type.
## - Residence/workspace searches resolving against the concealment tier
##   — Spec 27 listens to search_requested for those; only the world half
##   (Evidence.resolve_search) resolves today.
## - Escalation (`escalated`) — optional in the spec's own stage list, not
##   built for the stub slice.
## - Council/Steward graft examination — Spec 28's; this spec only locks
##   that ordinary Witness never sees a graft, which is asserted below.

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


func _requests_for(requests: Array, context: StringName) -> int:
	var n := 0
	for r: Dictionary in requests:
		if r["context"] == context:
			n += 1
	return n


func _count(fact_log: Node, type: StringName, context: StringName) -> int:
	var n := 0
	for fact: Dictionary in fact_log.get_by_type(type):
		if str((fact["context"] as Dictionary).get("investigation_context", "")) == str(context):
			n += 1
	return n


func _run() -> void:
	var investigation: Node = root.get_node_or_null("Investigation")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var perception: Node = root.get_node_or_null("Perception")
	var npcs: Node = root.get_node_or_null("Npcs")
	var zones: Node = root.get_node_or_null("Zones")
	var trust: Node = root.get_node_or_null("Trust")
	var evidence: Node = root.get_node_or_null("Evidence")
	var storage: Node = root.get_node_or_null("Storage")
	var bus: Node = root.get_node_or_null("EventBus")
	var clock: Node = root.get_node_or_null("Clock")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if investigation == null or fact_log == null or perception == null or npcs == null or zones == null or trust == null or evidence == null or storage == null or bus == null or clock == null or save_load == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	root.get_node("Homes").reset_all()
	clock.reset_all()
	clock.pause("test")
	fact_log.clear_all()
	trust.reset_all()
	storage.reset_all()
	perception.clear_cooldowns()
	var requests: Array = []
	bus.search_requested.connect(func(context: StringName, reason: String) -> void: requests.append({"context": context, "reason": reason}))
	var trust_events: Array = []
	bus.trust_changed.connect(func(standing: StringName, delta: float, reason: String) -> void: trust_events.append({"standing": standing, "delta": delta, "reason": reason}))

	# A loaded NPC (Pell, Glowbeds) to witness things.
	var anchor: Node2D = ZoneAnchorScript.new()
	anchor.zone_id = "glowbeds"
	var marker := Marker2D.new()
	anchor.add_child(marker)
	root.add_child(anchor)
	var pell := FakeBody.new()
	root.add_child(pell)
	npcs.register_agent(&"pell", pell)
	await process_frame
	await process_frame
	if not bool(npcs.is_agent_loaded(&"pell")):
		_fail("fake Pell not loaded")
		return
	var eye := Vector2(0, -24)
	var threshold: float = float(investigation.get_threshold(&"pell"))
	var sight_weight := 2.0

	# --- 1. A single Witness fact does not cross the threshold; enough
	# facts within the window do, and crossing emits exactly one
	# search_requested for that context. ---
	perception.flag_witnessable("w1", Vector2(60, -24), &"excavated_restricted_wall")
	if (fact_log.get_by_type(&"excavated_restricted_wall") as Array).size() != 1:
		_fail("setup: first witness fact not logged")
		return
	var one: float = float(investigation.get_suspicion(&"pell"))
	if one <= 0.0 or one >= threshold or not requests.is_empty() or investigation.get_investigation_stage(&"pell") != &"none":
		_fail("one witness fact should raise suspicion (%s) below threshold (%s) with no search: %s" % [one, threshold, requests])
		return
	var needed := int(ceil(threshold / sight_weight))
	for i in range(needed):
		perception.flag_witnessable("w%d" % (i + 2), Vector2(60, -24), &"excavated_restricted_wall")
	# A witness fact is scoped to the NPC AND the place they saw it in, so
	# the location context (glowbeds) legitimately crosses too — the rule
	# is exactly ONE request per context.
	if _requests_for(requests, &"pell") != 1 or _requests_for(requests, &"glowbeds") > 1:
		_fail("crossing the threshold should emit exactly one search_requested per context, got %s" % [requests])
		return
	if _count(fact_log, &"search_requested", &"pell") != 1 or investigation.get_investigation_stage(&"pell") != &"found_nothing":
		_fail("search for an NPC context should log one request and resolve (found_nothing, Glowbeds has no evidence): stage %s" % investigation.get_investigation_stage(&"pell"))
		return
	# The very next fact must NOT re-trigger — it has to cross freshly.
	perception.flag_witnessable("w_after", Vector2(60, -24), &"excavated_restricted_wall")
	if _requests_for(requests, &"pell") != 1 or _requests_for(requests, &"glowbeds") > 1:
		_fail("a resolved context re-triggered on the very next fact: %s" % [requests])
		return
	if float(investigation.get_suspicion(&"pell")) <= float(one):
		_fail("suspicion should still be derived from the full window after a search")
		return
	print("PASS one fact stays below threshold; enough facts trigger exactly one search; no immediate re-trigger")

	# --- 2. Trust modulates the threshold only, never the score: the same
	# facts trigger sooner at low Trust than at high Trust. ---
	fact_log.clear_all()
	perception.clear_cooldowns()
	requests.clear()
	trust.reset_all()
	var score_before: float = float(investigation.get_suspicion(&"glowbeds"))
	trust.submit_trust_event(&"major_accomplishment", 45.0, "Trusted senior hand")  # high Trust
	trust_events.clear()
	var high_threshold: float = float(investigation.get_threshold(&"pell"))
	if high_threshold <= threshold or float(investigation.get_suspicion(&"glowbeds")) != score_before:
		_fail("high Trust should raise the threshold (%s -> %s) without touching the score" % [threshold, high_threshold])
		return
	for i in range(needed):
		perception.flag_witnessable("h%d" % i, Vector2(60, -24), &"excavated_restricted_wall")
	if not requests.is_empty():
		_fail("at high Trust the same facts should NOT yet trigger a search: %s" % [requests])
		return
	var extra := int(ceil((high_threshold - float(needed) * sight_weight) / sight_weight)) + 1
	for i in range(extra):
		perception.flag_witnessable("h_more%d" % i, Vector2(60, -24), &"excavated_restricted_wall")
	if requests.size() < 1:
		_fail("eventually the high-Trust context must still trigger")
		return
	print("PASS the lower-Trust context crosses the auto-investigation threshold first")

	# --- 3. The authored investigation triggers regardless of suspicion;
	# sealed evidence resolves to found_nothing, unconcealed evidence to
	# found_evidence with exactly one Trust event. ---
	fact_log.clear_all()
	perception.clear_cooldowns()
	requests.clear()
	trust.reset_all()
	trust_events.clear()
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	await process_frame
	terrain.reset_all()
	if float(investigation.get_suspicion(&"east_firmament")) != 0.0:
		_fail("fresh zone should have zero suspicion")
		return
	var clean: Dictionary = investigation.trigger_investigation(&"east_firmament", "Wardens inspect the upper gallery")
	if requests.size() != 1 or clean["stage"] != &"found_nothing" or investigation.get_investigation_stage(&"east_firmament") != &"found_nothing" or not trust_events.is_empty():
		_fail("authored trigger on a clean zone should request + resolve to found_nothing with no Trust event: %s %s" % [clean, trust_events])
		return
	# Dig a restricted cell, seal it: a routine (Basic) search finds nothing.
	var cell := Vector2i(70, 10)
	terrain.dig(terrain.to_global(terrain.map_to_local(cell + Vector2i.UP)), Vector2i.DOWN)
	storage.add_component(&"seal_kit")
	var sealed: Dictionary = evidence.seal(terrain.to_global(terrain.map_to_local(cell)), &"seal_kit")
	if not bool(sealed["success"]):
		_fail("setup: seal failed %s" % [sealed])
		return
	var hidden: Dictionary = investigation.trigger_investigation(&"east_firmament", "Wardens inspect again")
	if hidden["stage"] != &"found_nothing" or not trust_events.is_empty() or _count(fact_log, &"found_evidence", &"east_firmament") != 0:
		_fail("a search against successfully sealed evidence should be found_nothing: %s" % [hidden])
		return
	# An unconcealed cut is found: one found_evidence fact, exactly one
	# Trust event, stage found_evidence.
	var open_cell := Vector2i(72, 10)
	terrain.dig(terrain.to_global(terrain.map_to_local(open_cell + Vector2i.UP)), Vector2i.DOWN)
	var trust_before: float = float(trust.get_trust_value())
	var found: Dictionary = investigation.trigger_investigation(&"east_firmament", "A Warden follows the dust")
	if found["stage"] != &"found_evidence" or (found["found"] as Array).size() != 1 or investigation.get_investigation_stage(&"east_firmament") != &"found_evidence":
		_fail("unconcealed evidence should be found: %s" % [found])
		return
	if trust_events.size() != 1 or float(trust.get_trust_value()) >= trust_before or str(trust_events[0]["reason"]) == "":
		_fail("finding real evidence should submit exactly one reasoned Trust event: %s" % [trust_events])
		return
	if _count(fact_log, &"found_evidence", &"east_firmament") != 1 or _count(fact_log, &"search_requested", &"east_firmament") != 3:
		_fail("resolution facts wrong (found %d, requests %d)" % [_count(fact_log, &"found_evidence", &"east_firmament"), _count(fact_log, &"search_requested", &"east_firmament")])
		return
	if float(investigation.get_suspicion(&"east_firmament")) <= 0.0:
		_fail("found evidence should keep the zone's suspicion hot")
		return
	print("PASS the authored investigation always fires; sealed -> found_nothing; unconcealed -> found_evidence + one Trust event")

	# --- 4. A district discrepancy fact (Spec 22's future source) counts
	# toward its district's suspicion and nobody else's. ---
	var witnesses: Array[String] = []
	fact_log.record(&"district_discrepancy", "wickwork", &"wickwork", witnesses, {"district_id": "wickwork", "unexplained_loss": 3}, 0)
	if float(investigation.get_suspicion(&"wickwork")) <= 0.0 or float(investigation.get_suspicion(&"cistern")) != 0.0:
		_fail("district discrepancy not scoped to its district")
		return
	print("PASS district discrepancy facts are scoped to their district")

	# --- 5. Old facts age out of the window — the natural cooldown. ---
	var before_age: float = float(investigation.get_suspicion(&"wickwork"))
	for _i in range(4 * (int(investigation.get_window_cycles()) + 1)):
		clock._advance_phase()
	if float(investigation.get_suspicion(&"wickwork")) != 0.0 or before_age <= 0.0:
		_fail("facts older than the window should age out (%s -> %s)" % [before_age, investigation.get_suspicion(&"wickwork")])
		return
	print("PASS suspicion ages out with the fact window, with no decay timer")

	# --- 6. Forbidden Gear: a loaded ordinary NPC standing next to an
	# exposed, unconcealed graft never produces a witness fact. ---
	fact_log.clear_all()
	var rig: Node = root.get_node_or_null("Rig")
	var body := CharacterBody2D.new()
	body.name = "Player"
	body.add_to_group("player")
	body.collision_layer = 1
	body.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	body_shape.shape = rect
	body.add_child(body_shape)
	root.add_child(body)
	var workspace: Area2D = RigStationScript.new()
	workspace.station_kind = &"workspace"
	workspace.position = Vector2(30, 0)  # right beside Pell
	root.add_child(workspace)
	var homes: Node = root.get_node("Homes")  # Build Bible Spec 27's real owner
	homes.grant_residence(&"mid_reach", "test: the Mid Reach residence")
	body.global_position = workspace.position
	for _i in range(4):
		await physics_frame
	pell.facing = 1.0
	var grafted: Dictionary = rig.graft(&"quieting_coupler")
	if not bool(grafted["success"]):
		_fail("setup: graft failed %s" % [grafted])
		return
	for _i in range(4):
		await physics_frame
	# Grafting legitimately logs a Spec 25 `discovery` fact (understanding
	# the design); what must NOT exist is any WITNESS fact — one with an
	# npc_id/sense — or any suspicion on the NPC beside the graft.
	var witness_facts := (fact_log.get_all() as Array).filter(func(f: Dictionary) -> bool: return (f["context"] as Dictionary).has("npc_id"))
	if not witness_facts.is_empty() or float(investigation.get_suspicion(&"pell")) != 0.0:
		_fail("an ordinary NPC produced a witness fact about a graft: %s" % [witness_facts])
		return
	rig.reset_all()
	print("PASS an ordinary loaded NPC beside an exposed graft never produces a witness fact")

	npcs.unregister_agent(&"pell")
	pell.queue_free()
	anchor.queue_free()
	body.queue_free()
	workspace.queue_free()
	homes.reset_all()
	terrain.queue_free()
	fact_log.clear_all()
	trust.reset_all()
	storage.reset_all()
	save_load.clear_save()
	clock.reset_all()
	await process_frame
	print("INVESTIGATION_TESTS_PASSED")
	quit(0)
