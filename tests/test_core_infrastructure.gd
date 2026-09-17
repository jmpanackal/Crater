extends SceneTree
## Build Bible Spec 01 (Event Bus, Fact Log, Tuning Registry) acceptance
## tests. No scene needed — EventBus, FactLog, and TuningRegistry are
## autoloads, present in any SceneTree run headlessly via --script.
##
## Two of Spec 01's acceptance tests are deliberately NOT covered here and
## are noted inline where they'd go:
## - "A new Gear Content Definition .tres file is picked up... by the Rig
##   system" — Rig doesn't exist yet (Build Bible Spec 14). Content
##   Definitions is a convention this test can't exercise until a real
##   content-consuming system is built.
## - "Authoritative State + Fact Log both round-trip through save/load" —
##   only FactLog's OWN snapshot round-trip is tested here; wiring it into
##   the real SaveLoad system is Build Bible Spec 02's job, not Spec 01's.

const TEST_TUNING_PATH := "res://tuning/test_example_tuning.tres"
const EXAMPLE_TUNING_SCRIPT := "res://tests/fixtures/example_tuning.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var tuning: Node = root.get_node_or_null("TuningRegistry")
	if event_bus == null or fact_log == null or tuning == null:
		push_error("FAIL missing autoloads (EventBus / FactLog / TuningRegistry)")
		quit(1)
		return

	fact_log.clear_all()

	# --- 1. EventBus fires and reaches an unrelated listener with no direct
	# reference between emitter (FactLog) and receiver (this test). ---
	var received: Array[Dictionary] = []
	var listener := func(fact: Dictionary) -> void: received.append(fact)
	event_bus.fact_recorded.connect(listener)

	var witnesses: Array[String] = ["npc_warden_1"]
	var recorded: Dictionary = fact_log.record(
		&"seen_in_restricted_area",
		"player",
		&"bottom_west",
		witnesses,
		{"note": "test fact"},
		3
	)
	if received.size() != 1:
		push_error("FAIL EventBus.fact_recorded did not reach the listener")
		quit(1)
		return
	if received[0]["type"] != &"seen_in_restricted_area":
		push_error("FAIL EventBus payload did not match the recorded fact")
		quit(1)
		return
	if recorded["index"] != 0 or recorded["cycle"] != 3:
		push_error("FAIL record() return value missing index/cycle")
		quit(1)
		return
	event_bus.fact_recorded.disconnect(listener)
	print("PASS EventBus signal reaches an unrelated listener")

	# --- 2. A fact can be appended and later queried back by type and by
	# cycle range. ---
	var no_witnesses: Array[String] = []
	fact_log.record(&"theft_witnessed", "player", &"wickwork", no_witnesses, {}, 3)
	fact_log.record(&"ritual_missed", "player", &"mid_heart", no_witnesses, {}, 7)

	var restricted: Array = fact_log.get_by_type(&"seen_in_restricted_area")
	if restricted.size() != 1:
		push_error("FAIL get_by_type did not return exactly 1 fact")
		quit(1)
		return

	var in_range: Array = fact_log.get_in_cycle_range(0, 3)
	if in_range.size() != 2:
		push_error("FAIL get_in_cycle_range(0,3) expected 2 facts, got %d" % in_range.size())
		quit(1)
		return
	if fact_log.count() != 3:
		push_error("FAIL count() expected 3, got %d" % fact_log.count())
		quit(1)
		return
	print("PASS facts queryable by type and by cycle range")

	# --- 3. FactLog's own snapshot round-trip (full SaveLoad wiring is
	# Spec 02's job). ---
	var snapshot: Array = fact_log.get_snapshot()
	fact_log.clear_all()
	if fact_log.count() != 0:
		push_error("FAIL clear_all did not clear the log")
		quit(1)
		return
	fact_log.apply_snapshot(snapshot)
	if fact_log.count() != 3:
		push_error("FAIL apply_snapshot did not restore all facts")
		quit(1)
		return
	if fact_log.get_by_type(&"ritual_missed").size() != 1:
		push_error("FAIL apply_snapshot did not restore fact content correctly")
		quit(1)
		return
	print("PASS FactLog snapshot round-trips")

	# --- 4. TuningRegistry hot-reload: changing a value in a .tres file
	# changes what get_domain() returns after reload_all(), no code change.
	# Written directly via FileAccess (standard Godot 4 .tres text format)
	# rather than through ResourceSaver.save(), which showed path/UID-cache
	# quirks when repeatedly saving to the same path across test runs —
	# ResourceLoader.load(..., CACHE_MODE_REPLACE) is the production code
	# path this is actually testing; how the file gets written is not. ---
	if not DirAccess.dir_exists_absolute("res://tuning/"):
		DirAccess.make_dir_absolute("res://tuning/")
	_write_example_tuning_tres(1)
	tuning.reload_all()
	var domain: Resource = tuning.get_domain("test_example_tuning")
	if domain == null or int(domain.get("test_value")) != 1:
		push_error("FAIL TuningRegistry did not load the initial .tres value")
		quit(1)
		return

	_write_example_tuning_tres(42)
	tuning.reload_all()
	var domain2: Resource = tuning.get_domain("test_example_tuning")
	if domain2 == null or int(domain2.get("test_value")) != 42:
		push_error("FAIL TuningRegistry did not pick up the changed .tres value on reload")
		quit(1)
		return
	print("PASS TuningRegistry reload picks up a changed .tres value with no code change")

	# Clean up the test fixture so it doesn't linger as committed debris.
	DirAccess.remove_absolute(TEST_TUNING_PATH)
	var uid_path := TEST_TUNING_PATH + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)

	fact_log.clear_all()
	print("CORE_INFRASTRUCTURE_TESTS_PASSED")
	quit(0)


## Writes a minimal, valid Godot 4 .tres text resource referencing the
## ExampleTuning fixture script, with test_value set to the given amount.
func _write_example_tuning_tres(value: int) -> void:
	var text := (
		"[gd_resource type=\"Resource\" script_class=\"\" load_steps=2 format=3]\n\n"
		+ "[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n\n" % EXAMPLE_TUNING_SCRIPT
		+ "[resource]\n"
		+ "script = ExtResource(\"1\")\n"
		+ "test_value = %d\n" % value
	)
	var file := FileAccess.open(TEST_TUNING_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
