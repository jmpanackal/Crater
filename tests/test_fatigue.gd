extends SceneTree
## Build Bible Spec 09 (Fatigue / Overexertion / Recovery) acceptance tests.
## Overexertion's own mechanics (fixed cost, warning signal, Exhausted
## refusal) are exercised together with Stamina in test_stamina.gd; this
## file covers what's specifically Fatigue's own contract: accumulation to
## Exhausted blocking further action, the two recovery paths, and that
## ordinary regeneration never touches fatigue.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stamina: Node = root.get_node_or_null("Stamina")
	var fatigue: Node = root.get_node_or_null("Fatigue")
	if stamina == null or fatigue == null:
		push_error("FAIL missing autoloads (Stamina / Fatigue)")
		quit(1)
		return

	stamina.reset_all()

	# --- 1. Repeated Overexertion accumulates fatigue and eventually
	# reaches Exhausted, which then blocks further strenuous action. ---
	var max_stamina: float = stamina.get_max_stamina()
	var fixed_cost: float = fatigue.get_fixed_overexertion_cost()
	var safety_limit := 200  # generous upper bound so a tuning change can't hang this test
	var iterations := 0
	while not bool(fatigue.is_exhausted()) and iterations < safety_limit:
		stamina.spend(max_stamina)  # drain whatever's currently available
		stamina.overexert(9999.0)
		iterations += 1
	if not bool(fatigue.is_exhausted()):
		push_error("FAIL repeated Overexertion never reached Exhausted within %d iterations" % safety_limit)
		quit(1)
		return
	if iterations < 2:
		push_error("FAIL reached Exhausted in a single Overexertion — fixed cost should require several")
		quit(1)
		return
	# Once Exhausted, can_afford refuses any real cost (available_max is 0).
	if bool(stamina.can_afford(1.0)):
		push_error("FAIL can_afford() should refuse any real cost once Exhausted")
		quit(1)
		return
	# ...and a further Overexertion attempt adds nothing more (Spec 09's
	# own explicit failure case: no further Overexertion once Exhausted).
	var fatigue_before_extra: float = fatigue.get_current()
	var extra: float = stamina.overexert(50.0)
	if not is_equal_approx(extra, 0.0) or not is_equal_approx(float(fatigue.get_current()), fatigue_before_extra):
		push_error("FAIL a further Overexertion attempt added fatigue past Exhausted")
		quit(1)
		return
	print("PASS repeated Overexertion accumulates to Exhausted, which then blocks further strenuous action")

	# --- 2. Sleep clears fatigue fully; field rest clears it partially and
	# costs time (the time cost itself is the caller's concern — this
	# tests the recovery amount, not a time system that doesn't exist
	# yet). ---
	fatigue.recover_full()
	if not is_equal_approx(float(fatigue.get_current()), 0.0):
		push_error("FAIL recover_full() did not clear fatigue to zero")
		quit(1)
		return
	if bool(fatigue.is_exhausted()):
		push_error("FAIL still Exhausted after a full recovery")
		quit(1)
		return
	print("PASS sleep (recover_full) clears fatigue completely")

	stamina.reset_all()
	fatigue.add_from_overexertion()
	fatigue.add_from_overexertion()
	var before_partial: float = fatigue.get_current()
	var partial_amount := fixed_cost * 0.5
	fatigue.recover_partial(partial_amount)
	if not is_equal_approx(float(fatigue.get_current()), maxf(0.0, before_partial - partial_amount)):
		push_error("FAIL recover_partial() did not clear exactly the requested amount")
		quit(1)
		return
	if is_equal_approx(float(fatigue.get_current()), 0.0):
		push_error("FAIL recover_partial() should not fully clear fatigue on its own")
		quit(1)
		return
	print("PASS field rest (recover_partial) clears fatigue partially, not fully")

	# --- 3. Fatigue never decreases from ordinary stamina regeneration
	# alone. ---
	stamina.reset_all()
	fatigue.add_from_overexertion()
	var fatigue_before_regen: float = fatigue.get_current()
	stamina._process(5.0)  # simulate several seconds of ordinary regen
	if not is_equal_approx(float(fatigue.get_current()), fatigue_before_regen):
		push_error("FAIL fatigue decreased from ordinary stamina regeneration alone")
		quit(1)
		return
	print("PASS fatigue never decreases from ordinary stamina regeneration alone")

	stamina.reset_all()
	print("FATIGUE_TESTS_PASSED")
	quit(0)
