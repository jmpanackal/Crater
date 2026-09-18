extends SceneTree
## Build Bible Spec 19 (Trust + reasons view) acceptance tests.
##
## Not covered here, and why:
## - Who submits real Trust events (Investigation resolving evidence,
##   Spec 20; broken commitments, Spec 24; exposed lies, Spec 21) — each
##   is its own spec; this proves the contract they call.
## - Group-specific context modifiers (Wardens vs. residents) — G16 shapes
##   the query for them; Act 1 uses only the global context, so
##   get_trust(&"wardens") reading the same value is the current truth.
## - The retired community.gd Trust int and its HUD — still the legacy
##   owner of retired penalties until their specs migrate; not asserted
##   against here.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var trust: Node = root.get_node_or_null("Trust")
	var bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var console: Node = root.get_node_or_null("DebugConsole")
	var districts: Node = root.get_node_or_null("Districts")
	var wallet: Node = root.get_node_or_null("Resources")
	var community: Node = root.get_node_or_null("Community")
	if trust == null or bus == null or save_load == null or console == null or districts == null or wallet == null:
		_fail("missing autoloads (Trust / EventBus / SaveLoad / DebugConsole / Districts / Resources)")
		return
	if community:
		community.set_paused(true)
		community.skip_lie_prompt = true
	save_load.clear_save()
	trust.reset_all()
	var changes: Array = []
	bus.trust_changed.connect(func(standing: StringName, delta: float, reason: String) -> void: changes.append({"standing": standing, "delta": delta, "reason": reason}))
	var ladder: Array[Dictionary] = trust.get_standing_ladder()
	var ladder_ids: Array = []
	for step: Dictionary in ladder:
		ladder_ids.append(step["id"])
	if ladder.size() < 4 or ladder.size() > 5:
		_fail("canon asks for ~4-5 standing states from tuning, got %d" % ladder.size())
		return

	# --- 1. A submitted, reasoned event changes the value and appends a
	# matching, retrievable reason; the UI-facing query is a standing
	# state, never the number. ---
	var before: float = float(trust.get_trust_value())
	var initial: StringName = trust.get_trust()
	if not ladder_ids.has(initial) or typeof(trust.get_trust()) != TYPE_STRING_NAME:
		_fail("get_trust() should return a standing id from the tuning ladder, got %s" % [initial])
		return
	if not bool(trust.submit_trust_event(&"meaningful_help", 6.0, "Helped brace the Bottom-West gallery through a bad shift")):
		_fail("a valid reasoned event was refused")
		return
	if not is_equal_approx(float(trust.get_trust_value()), before + 6.0):
		_fail("delta not applied (%s -> %s)" % [before, trust.get_trust_value()])
		return
	var reasons: Array[Dictionary] = trust.get_trust_reasons()
	if reasons.size() != 1 or reasons[0]["type"] != &"meaningful_help" or not is_equal_approx(float(reasons[0]["delta"]), 6.0) or not str(reasons[0]["reason"]).contains("Bottom-West"):
		_fail("reason not appended/retrievable: %s" % [reasons])
		return
	if changes.size() != 1 or not is_equal_approx(float(changes[0]["delta"]), 6.0) or changes[0]["standing"] != trust.get_trust() or str(changes[0]["reason"]) == "":
		_fail("trust_changed not emitted with standing + delta + reason: %s" % [changes])
		return
	# Returned reasons are copies.
	(reasons[0] as Dictionary)["reason"] = "tampered"
	if str((trust.get_trust_reasons() as Array)[0]["reason"]) == "tampered":
		_fail("get_trust_reasons handed out live records")
		return
	print("PASS a reasoned event changes Trust and appends a retrievable reason; the query is a standing state")

	# --- 2. A reason is REQUIRED: an unexplained modifier is refused with
	# no mutation (loud in debug — the push_error below is expected). ---
	var value_now: float = float(trust.get_trust_value())
	if bool(trust.submit_trust_event(&"betrayal", -20.0, "")) or bool(trust.submit_trust_event(&"betrayal", -20.0, "   ")) or bool(trust.submit_trust_event(&"", -20.0, "typed but no type")):
		_fail("an event without a reason/type was accepted")
		return
	if not is_equal_approx(float(trust.get_trust_value()), value_now) or (trust.get_trust_reasons() as Array).size() != 1 or changes.size() != 1:
		_fail("a refused event mutated Trust")
		return
	print("PASS an event without a reason is refused with no mutation")

	# --- 3. Standing states come from tuning thresholds; the value clamps
	# to the tuned range at both ends. ---
	trust.reset_all()
	changes.clear()
	var top: Dictionary = ladder[-1]
	var bottom: Dictionary = ladder[0]
	trust.submit_trust_event(&"major_accomplishment", 1000.0, "Opened the new gallery ahead of the Steward's deadline")
	if trust.get_trust() != top["id"] or not is_equal_approx(float(trust.get_trust_value()), float(trust.get_max_trust())):
		_fail("huge positive delta should clamp at max and land on the top standing (%s, %s)" % [trust.get_trust(), trust.get_trust_value()])
		return
	trust.submit_trust_event(&"betrayal", -1000.0, "Caught diverting Wickwork racks")
	if trust.get_trust() != bottom["id"] or not is_equal_approx(float(trust.get_trust_value()), float(trust.get_min_trust())):
		_fail("huge negative delta should clamp at min and land on the bottom standing")
		return
	# Every threshold maps to exactly its own state.
	for step: Dictionary in ladder:
		trust.reset_all()
		trust.submit_trust_event(&"test", float(step["threshold"]) - float(trust.get_trust_value()), "threshold probe")
		if trust.get_trust() != step["id"] or str(trust.get_standing_label()) != str(step["label"]):
			_fail("value %s should be standing %s, got %s" % [step["threshold"], step["id"], trust.get_trust()])
			return
	if trust.get_trust(&"wardens") != trust.get_trust():
		_fail("context-aware query should read the one global value in Act 1")
		return
	print("PASS standing states follow the tuning ladder and the value clamps to the tuned range")

	# --- 4. Ordinary job completion earns Tallies and never touches Trust
	# (§17): drive the real legacy work-order delivery loop, which pays
	# Tallies, and watch Trust. ---
	trust.reset_all()
	changes.clear()
	var wo: Node = root.get_node_or_null("WorkOrders")
	if wo == null:
		_fail("WorkOrders autoload missing")
		return
	if districts.has_method("set_paused"):
		districts.set_paused(true)
	wo.reset_all()
	districts.reset_production()
	wallet.reset_all()
	wo.accept_offered()
	wallet.set_amount(wallet.SPOREMEAL, 2)
	wallet.set_amount(wallet.TALLIES, 0)
	districts.queue_material(wallet.SPOREMEAL)
	districts.queue_material(wallet.SPOREMEAL)
	if int(wallet.get_amount(wallet.TALLIES)) <= 0:
		_fail("the legacy delivery loop should have paid Tallies (got %d)" % int(wallet.get_amount(wallet.TALLIES)))
		return
	if not changes.is_empty() or not (trust.get_trust_reasons() as Array).is_empty() or not is_equal_approx(float(trust.get_trust_value()), float(trust.get_default_trust())):
		_fail("earning Tallies moved Trust: %s" % [changes])
		return
	print("PASS earning Tallies through job delivery never submits a Trust event")

	# --- 5. The reasons list is a capped recent window, oldest dropped. ---
	trust.reset_all()
	var capacity: int = int(trust.get_reasons_capacity())
	for i in range(capacity + 3):
		trust.submit_trust_event(&"reliability", 0.5, "Reliable shift %d" % i)
	var window: Array[Dictionary] = trust.get_trust_reasons()
	if window.size() != capacity or str(window[0]["reason"]) != "Reliable shift 3" or str(window[-1]["reason"]) != "Reliable shift %d" % (capacity + 2):
		_fail("reasons window not capped to the %d most recent: %s" % [capacity, window])
		return
	print("PASS the reasons list keeps only the recent window")

	# --- 6. Persistence through the real SaveLoad path; the debug console
	# moves Trust only through a reasoned event. ---
	trust.reset_all()
	trust.submit_trust_event(&"exposed_lie", -12.0, "Your story about the missed Ritual came apart")
	var pre_save: Dictionary = trust.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	trust.reset_all()
	if not (trust.get_trust_reasons() as Array).is_empty():
		_fail("reset_all did not clear")
		return
	if not save_load.load_game():
		_fail("load_game")
		return
	if trust.save_state() != pre_save:
		_fail("Trust did not round-trip:\n%s\nvs\n%s" % [pre_save, trust.save_state()])
		return
	var console_out: String = console.execute("set_trust 42")
	var after_console: Array[Dictionary] = trust.get_trust_reasons()
	if not is_equal_approx(float(trust.get_trust_value()), 42.0) or not console_out.contains("42") or after_console[-1]["type"] != &"debug" or int(after_console[-1]["index"]) <= int(pre_save["next_reason_index"]) - 1:
		_fail("debug set_trust did not go through a reasoned event continuing the index (%s)" % [after_console])
		return
	print("PASS Trust persists through save/load; debug changes are reasoned events too")

	save_load.clear_save()
	trust.reset_all()
	wo.reset_all()
	wallet.reset_all()
	print("TRUST_TESTS_PASSED")
	quit(0)
