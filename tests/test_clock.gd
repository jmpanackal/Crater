extends SceneTree
## Build Bible Spec 04 (World Clock) acceptance tests.
##
## Not covered here, and why:
## - "Two simultaneous advance requests... must be idempotent/queued" — the
##   spec itself flags this as unresolved until Failure/Rescue (Spec 30)
##   exists to define the concrete scenario; nothing to test yet.
## - Real-time pause/resume "from exactly where it left off" is tested by
##   calling _process(delta) directly with controlled deltas rather than
##   actually waiting real minutes — see the tuning fixture below.

const CLOCK_TUNING_PATH := "res://tuning/clock_tuning.tres"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var clock: Node = root.get_node_or_null("Clock")
	var event_bus: Node = root.get_node_or_null("EventBus")
	var tuning: Node = root.get_node_or_null("TuningRegistry")
	if clock == null or event_bus == null or tuning == null:
		push_error("FAIL missing autoloads (Clock / EventBus / TuningRegistry)")
		quit(1)
		return

	# TuningRegistry keys a domain by filename, so overriding "clock_tuning"
	# for the test means temporarily overwriting the real, committed
	# res://tuning/clock_tuning.tres — a separate file would load under a
	# different domain name and Clock would never see it. Save the original
	# text first and restore it at the end, so this test never leaves the
	# real production tuning file mutated on disk.
	var original_text := _read_file(CLOCK_TUNING_PATH)
	_write_test_clock_tuning()
	tuning.reload_all()
	clock.reset_all()

	# --- 1. A full cycle advances through all four phases in the locked
	# order, wrapping back to Rousing and incrementing cycles_elapsed. ---
	var seen_phases: Array[StringName] = [clock.get_phase()]
	for i in range(4):
		clock._process(1.01)
		seen_phases.append(clock.get_phase())
	var expected: Array[StringName] = [
		&"rousing", &"working", &"gathering", &"ritual", &"rousing",
	]
	if seen_phases != expected:
		push_error("FAIL phase order %s != expected %s" % [seen_phases, expected])
		quit(1)
		return
	if clock.get_cycles_elapsed() != 1:
		push_error("FAIL cycles_elapsed expected 1, got %d" % clock.get_cycles_elapsed())
		quit(1)
		return
	print("PASS a full cycle advances through all four phases in order")

	# --- 2. Exactly one phase_changed event per transition, via EventBus,
	# no direct reference to Clock. ---
	var received: Array[Dictionary] = []
	var listener := func(old_phase: StringName, new_phase: StringName) -> void:
		received.append({"old": old_phase, "new": new_phase})
	event_bus.phase_changed.connect(listener)
	clock._process(1.01)  # rousing -> working
	if received.size() != 1 or received[0]["old"] != &"rousing" or received[0]["new"] != &"working":
		push_error("FAIL expected exactly one phase_changed(rousing, working), got %s" % [received])
		quit(1)
		return
	event_bus.phase_changed.disconnect(listener)
	print("PASS exactly one phase_changed event fires per transition, via EventBus")

	# --- 3. Pausing halts time; resuming continues from exactly where it
	# left off, not a recalculated point. ---
	clock.reset_all()
	clock._process(0.4)  # 0.4s into a 1s Rousing phase
	clock.pause("test_menu")
	clock._process(10.0)  # would cross several phases if not actually paused
	if clock.get_phase() != &"rousing":
		push_error("FAIL time advanced while paused (phase is %s)" % clock.get_phase())
		quit(1)
		return
	clock.resume("test_menu")
	clock._process(0.3)  # 0.4 + 0.3 = 0.7s, still short of the 1s phase length
	if clock.get_phase() != &"rousing":
		push_error("FAIL phase advanced too early after resume — time did not resume from where it left off")
		quit(1)
		return
	clock._process(0.31)  # 0.7 + 0.31 > 1.0s — should cross now
	if clock.get_phase() != &"working":
		push_error("FAIL phase did not advance after enough post-resume time accumulated")
		quit(1)
		return
	print("PASS pausing halts time; resuming continues from exactly where it left off")

	# --- 3b. Reference-counted pause: two pause() calls for the SAME
	# reason need two resume() calls to actually clear it. ---
	clock.reset_all()
	clock.pause("dialogue")
	clock.pause("dialogue")
	clock.resume("dialogue")
	if not clock.is_paused():
		push_error("FAIL a single resume() cleared a reason pushed twice")
		quit(1)
		return
	clock.resume("dialogue")
	if clock.is_paused():
		push_error("FAIL reason did not clear after matching resume() count")
		quit(1)
		return
	# Two DIFFERENT simultaneous reasons must both clear independently.
	clock.pause("menu")
	clock.pause("dialogue")
	clock.resume("menu")
	if not clock.is_paused():
		push_error("FAIL resuming one reason wrongly cleared a different simultaneous reason")
		quit(1)
		return
	clock.resume("dialogue")
	if clock.is_paused():
		push_error("FAIL clock still paused after both distinct reasons resumed")
		quit(1)
		return
	print("PASS pause reasons are reference-counted and independent per reason")

	# --- 4. request_advance_to_next_rousing() succeeds only from
	# Gathering/Ritual, fails (and does nothing) otherwise — the Clock
	# itself refuses, not just the UI. ---
	clock.reset_all()
	if clock.request_advance_to_next_rousing():
		push_error("FAIL sleep-advance succeeded from Rousing")
		quit(1)
		return
	if clock.get_phase() != &"rousing":
		push_error("FAIL a refused sleep-advance must not mutate phase")
		quit(1)
		return
	clock._process(1.01)  # -> working
	if clock.request_advance_to_next_rousing():
		push_error("FAIL sleep-advance succeeded from Working")
		quit(1)
		return
	clock._process(1.01)  # -> gathering
	if not clock.request_advance_to_next_rousing():
		push_error("FAIL sleep-advance refused from Gathering")
		quit(1)
		return
	if clock.get_phase() != &"rousing":
		push_error("FAIL sleep-advance from Gathering did not land on Rousing")
		quit(1)
		return
	print("PASS request_advance_to_next_rousing succeeds only from Gathering/Ritual")

	# Restore the real production tuning file exactly as it was.
	_write_file(CLOCK_TUNING_PATH, original_text)
	tuning.reload_all()
	clock.reset_all()
	print("CLOCK_TESTS_PASSED")
	quit(0)


## Overwrites clock_tuning.tres with a tiny, exactly-even 4-second cycle
## (1 second per phase) so tests don't wait real minutes and each phase's
## length is simple to compute. Restored via _write_file(original_text) at
## the end of _run().
func _write_test_clock_tuning() -> void:
	var text := (
		"[gd_resource type=\"Resource\" script_class=\"\" load_steps=2 format=3]\n\n"
		+ "[ext_resource type=\"Script\" path=\"res://tuning/clock_tuning.gd\" id=\"1\"]\n\n"
		+ "[resource]\n"
		+ "script = ExtResource(\"1\")\n"
		+ "cycle_length_minutes = 0.06666667\n"  # 4 seconds total
		+ "rousing_proportion = 0.25\n"
		+ "working_proportion = 0.25\n"
		+ "gathering_proportion = 0.25\n"
		+ "ritual_proportion = 0.25\n"
	)
	_write_file(CLOCK_TUNING_PATH, text)


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
