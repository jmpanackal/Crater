extends SceneTree
## Build Bible Spec 21 (Dialogue + Questioning) acceptance tests.
##
## Not covered here, and why:
## - Authored dialogue CONTENT (which NPC asks what, when) — thin slice;
##   the Ritual alibi case below is the one real questioning moment wired
##   through this contract against CivicCycle's real ritual_missed fact.
## - Predictive claims resolving against future state — out of scope by
##   the spec's own confirmed choice (option B).
## - Council/Steward examination of grafts — Spec 28.
## - The retired Harvest-miss lie prompt (community.gd's
##   trigger_harvest_now()/resolve_harvest_miss()/on_theft_noticed()) is
##   gone outright (Build Bible Spec 15: Ritual-miss is "contextual, never
##   an automatic stat penalty" — no lie/truth prompt is rebuilt). Its
##   structural replacement is the Ritual alibi case: a real ritual_missed
##   fact contradicts a claim, and an authored confrontation exposes it.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _events_of(events: Array, type_text: String) -> int:
	var n := 0
	for e: Dictionary in events:
		if str(e["reason"]).contains(type_text):
			n += 1
	return n


func _run() -> void:
	var dialogue: Node = root.get_node_or_null("Dialogue")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var trust: Node = root.get_node_or_null("Trust")
	var investigation: Node = root.get_node_or_null("Investigation")
	var evidence: Node = root.get_node_or_null("Evidence")
	var bus: Node = root.get_node_or_null("EventBus")
	var clock: Node = root.get_node_or_null("Clock")
	var civic: Node = root.get_node_or_null("CivicCycle")
	var console: Node = root.get_node_or_null("DebugConsole")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if dialogue == null or fact_log == null or trust == null or investigation == null or evidence == null or bus == null or clock == null or civic == null or console == null or save_load == null:
		_fail("missing autoloads")
		return
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	fact_log.clear_all()
	trust.reset_all()
	civic.reset_all()
	var trust_events: Array = []
	bus.trust_changed.connect(func(standing: StringName, delta: float, reason: String) -> void: trust_events.append({"standing": standing, "delta": delta, "reason": reason}))
	var exposed_lie_count := func() -> int:
		var n := 0
		for r: Dictionary in trust.get_trust_reasons():
			if r["type"] == &"exposed_lie":
				n += 1
		return n

	# --- 1. A claim writes exactly one claim_made fact carrying its tag
	# and assertion; deflecting writes nothing; a claim with no checkable
	# assertion is refused. ---
	var before := int(fact_log.count())
	var claim: Dictionary = dialogue.make_claim(&"not_near_firmament", true, {
		"asserts": "was_not_at", "location": "firmament", "text": "I haven't been near the upper gallery",
	})
	if claim.is_empty() or int(fact_log.count()) != before + 1 or claim["type"] != &"claim_made":
		_fail("make_claim did not write one claim_made fact: %s" % [claim])
		return
	var ctx: Dictionary = claim["context"]
	if not bool(ctx["trust_relevant"]) or str(ctx["asserts"]) != "was_not_at" or int(ctx["cycle"]) != int(clock.get_cycles_elapsed()) or claim["location"] != &"firmament":
		_fail("claim fact shape wrong: %s" % [claim])
		return
	# Deflection: nothing is called, nothing is written.
	if int(fact_log.count()) != before + 1 or bool(dialogue.has_claim(&"deflected_question")) or bool(dialogue.is_contradicted(&"deflected_question")) or bool(dialogue.expose_claim(&"deflected_question")):
		_fail("deflection produced something to contradict or expose")
		return
	if not (dialogue.make_claim(&"vague", true, {"text": "Things are fine"}) as Dictionary).is_empty() or int(fact_log.count()) != before + 1:
		_fail("a claim with no checkable assertion was accepted")
		return
	print("PASS a claim is one tagged claim_made fact; deflection writes nothing; uncheckable claims are refused")

	# --- 2. A contradiction becoming derivable does nothing by itself;
	# exposure via Investigation's conflicting resolution produces exactly
	# one exposed_lie Trust event (alongside the evidence event). ---
	if bool(dialogue.is_contradicted(&"not_near_firmament")) or bool(dialogue.expose_claim(&"not_near_firmament")):
		_fail("an uncontradicted claim was contradicted/exposed")
		return
	var witnesses: Array[String] = ["pell"]
	fact_log.record(&"excavated_restricted_wall", "player", &"firmament", witnesses, {"npc_id": "pell", "sense": "sight"}, int(clock.get_cycles_elapsed()))
	if not bool(dialogue.is_contradicted(&"not_near_firmament")):
		_fail("a Witness fact placing the player at the location should contradict the claim")
		return
	if not trust_events.is_empty() or bool(dialogue.is_exposed(&"not_near_firmament")):
		_fail("a derivable contradiction fired something by itself")
		return
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	await process_frame
	terrain.reset_all()
	terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(590, 9))), Vector2i.DOWN)
	var result: Dictionary = investigation.trigger_investigation(&"firmament", "A Warden follows the dust")
	if result["stage"] != &"found_evidence":
		_fail("setup: investigation should find the fresh cut: %s" % [result])
		return
	if not bool(dialogue.is_exposed(&"not_near_firmament")) or exposed_lie_count.call() != 1:
		_fail("Investigation's conflicting resolution should expose the claim with exactly one exposed_lie event (%d)" % exposed_lie_count.call())
		return
	if bool(dialogue.expose_claim(&"not_near_firmament")) or exposed_lie_count.call() != 1:
		_fail("a claim was exposed twice")
		return
	print("PASS a contradicted trust-relevant claim, exposed via Investigation, yields exactly one exposed_lie Trust event")

	# --- 3. The same scenario tagged trust_relevant: false yields zero
	# Trust events, even when explicitly exposed. ---
	fact_log.clear_all()
	trust.reset_all()
	trust_events.clear()
	dialogue.make_claim(&"white_lie", false, {"asserts": "was_not_at", "location": "firmament", "text": "Nothing to worry about up there"})
	fact_log.record(&"excavated_restricted_wall", "player", &"firmament", witnesses, {"npc_id": "pell", "sense": "sight"}, int(clock.get_cycles_elapsed()))
	if not bool(dialogue.is_contradicted(&"white_lie")):
		_fail("setup: white lie should be contradicted")
		return
	terrain.reset_all()
	terrain.dig(terrain.to_global(terrain.map_to_local(Vector2i(590, 9))), Vector2i.DOWN)
	investigation.trigger_investigation(&"firmament", "Again")
	var direct: bool = bool(dialogue.expose_claim(&"white_lie"))
	if direct or exposed_lie_count.call() != 0:
		_fail("a trust_relevant:false claim produced a Trust event")
		return
	if not bool(dialogue.is_exposed(&"white_lie")):
		_fail("the white lie should still be remembered as exposed (narrative only)")
		return
	print("PASS a trust_relevant:false claim never moves Trust, even when exposed")

	# --- 4. A Ritual alibi is contradicted by CivicCycle's real
	# ritual_missed fact and exposed by an authored confrontation. ---
	fact_log.clear_all()
	trust.reset_all()
	trust_events.clear()
	var cycle_now := int(clock.get_cycles_elapsed())
	dialogue.make_claim(&"ritual_alibi", true, {"asserts": "attended_ritual", "cycle": cycle_now, "text": "I was at the Ritual, near the back"})
	if bool(dialogue.is_contradicted(&"ritual_alibi")):
		_fail("alibi contradicted before any Ritual was missed")
		return
	console.execute("force_phase gathering")
	console.execute("force_advance 1")  # gathering -> ritual with nobody on the ground
	if (fact_log.get_by_type(&"ritual_missed") as Array).size() != 1 or not bool(dialogue.is_contradicted(&"ritual_alibi")):
		_fail("a real ritual_missed fact should contradict the alibi")
		return
	var confront: String = console.execute("expose ritual_alibi")
	if not confront.contains("moved") or exposed_lie_count.call() != 1:
		_fail("authored confrontation did not expose the alibi once: '%s'" % confront)
		return
	print("PASS a Ritual alibi is contradicted by the real ritual_missed fact and exposed by an authored confrontation")

	fact_log.clear_all()
	trust.reset_all()
	civic.reset_all()
	clock.reset_all()
	save_load.clear_save()
	terrain.queue_free()
	await process_frame
	print("DIALOGUE_TESTS_PASSED")
	quit(0)
