extends SceneTree
## Build Bible Spec 08 (Stamina + Blocks) acceptance tests.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stamina: Node = root.get_node_or_null("Stamina")
	if stamina == null:
		push_error("FAIL Stamina autoload missing")
		quit(1)
		return

	stamina.reset_all()

	# --- 1. A hauling block and a Rig Strain block coexist and release
	# independently. ---
	stamina.request_block(stamina.SOURCE_HAULING, 20.0)
	stamina.request_block(stamina.SOURCE_RIG_STRAIN, 15.0)
	if not is_equal_approx(float(stamina.get_total_blocked()), 35.0):
		push_error("FAIL total_blocked expected 35, got %s" % stamina.get_total_blocked())
		quit(1)
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 20.0):
		push_error("FAIL hauling block expected 20")
		quit(1)
		return
	stamina.release_block(stamina.SOURCE_HAULING)
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 0.0):
		push_error("FAIL releasing hauling did not clear it")
		quit(1)
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), 15.0):
		push_error("FAIL releasing hauling wrongly touched rig_strain")
		quit(1)
		return
	print("PASS a hauling block and a Rig Strain block coexist and release independently")

	# --- 2. Overflow past the bar is only reachable via Overexertion,
	# converts to fatigue exactly, and warns first (signal fires). ---
	stamina.reset_all()
	var max_stamina: float = stamina.get_max_stamina()
	stamina.spend(max_stamina)  # drain to exactly zero via the normal path
	if not is_equal_approx(float(stamina.get_current()), 0.0):
		push_error("FAIL spend() to exactly zero should land at zero")
		quit(1)
		return

	var received: Array[float] = []
	var listener := func(fatigue_added: float) -> void: received.append(fatigue_added)
	stamina.overexertion_triggered.connect(listener)

	var overexert_cost := 30.0
	var fatigue_added: float = stamina.overexert(overexert_cost)
	if not is_equal_approx(fatigue_added, overexert_cost):
		push_error("FAIL overexert shortfall expected %s, got %s" % [overexert_cost, fatigue_added])
		quit(1)
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_FATIGUE)), overexert_cost):
		push_error("FAIL overexert did not convert the shortfall into fatigue block exactly")
		quit(1)
		return
	if not is_equal_approx(float(stamina.get_current()), 0.0):
		push_error("FAIL current stamina should be exactly zero after overexerting, never negative")
		quit(1)
		return
	if received.size() != 1:
		push_error("FAIL overexertion_triggered should fire exactly once (the warning hook)")
		quit(1)
		return
	stamina.overexertion_triggered.disconnect(listener)
	print("PASS overflow only happens via Overexertion, converts to fatigue exactly, and warns")

	# A spend() alone (no overexert) never pushes blocked past max — the
	# invariant only ever gets exceeded through the controlled Overexertion
	# path (G2).
	stamina.reset_all()
	stamina.spend(max_stamina + 500.0)  # wildly over-spend via the normal path
	if float(stamina.get_current()) < 0.0:
		push_error("FAIL spend() let current stamina go negative outside Overexertion")
		quit(1)
		return
	print("PASS spend() alone never drives stamina negative — only overexert() converts shortfall to fatigue")

	# --- 2b. Exhaustion is specifically fatigue-alone filling the bar. ---
	stamina.reset_all()
	stamina.request_block(stamina.SOURCE_HAULING, max_stamina)  # blocked fully, but NOT via fatigue
	if bool(stamina.is_exhausted()):
		push_error("FAIL is_exhausted() should be false when hauling (not fatigue) fills the bar")
		quit(1)
		return
	stamina.reset_all()
	stamina.request_block(stamina.SOURCE_FATIGUE, max_stamina)
	if not bool(stamina.is_exhausted()):
		push_error("FAIL is_exhausted() should be true when fatigue alone fills the bar")
		quit(1)
		return
	print("PASS is_exhausted() is specifically fatigue-alone filling the bar, not any combined block")

	# --- 3. Walking regenerates stamina at the normal rate; sprinting
	# (regen paused) does not. ---
	stamina.reset_all()
	stamina.spend(50.0)
	var before_walk: float = stamina.get_current()
	stamina._process(1.0)  # simulate 1 second of normal (walking) time
	if float(stamina.get_current()) <= before_walk:
		push_error("FAIL stamina did not regenerate over time while unblocked")
		quit(1)
		return
	print("PASS stamina regenerates at the normal rate when nothing suppresses it (walking)")

	stamina.reset_all()
	stamina.spend(50.0)
	stamina.pause_regen("sprint")
	var before_sprint: float = stamina.get_current()
	stamina._process(2.0)
	if not is_equal_approx(float(stamina.get_current()), before_sprint):
		push_error("FAIL stamina regenerated while regen was paused (sprinting)")
		quit(1)
		return
	stamina.resume_regen("sprint")
	stamina._process(1.0)
	if float(stamina.get_current()) <= before_sprint:
		push_error("FAIL stamina did not resume regenerating after resume_regen()")
		quit(1)
		return
	print("PASS sprinting (paused regen) blocks regeneration; resuming regen works again")

	# --- Save/load round-trip (Spec 02 contract). ---
	stamina.reset_all()
	stamina.request_block(stamina.SOURCE_RIG_STRAIN, 12.0)
	stamina.spend(10.0)
	var snapshot: Dictionary = stamina.save_state()
	stamina.reset_all()
	stamina.load_state(snapshot)
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), 12.0):
		push_error("FAIL save/load did not restore blocks")
		quit(1)
		return
	print("PASS Stamina save_state()/load_state() round-trips")

	stamina.reset_all()
	print("STAMINA_TESTS_PASSED")
	quit(0)
