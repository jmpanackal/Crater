extends SceneTree
## Build Bible Spec 03 (Debug Tools Framework) acceptance tests.
##
## Not covered here, and why:
## - "Console toggles in a debug build; has no effect at all in a release
##   build" — the debug-build half is implicitly exercised (this test
##   environment runs via --headless --script, which OS.is_debug_build()
##   reports as true, same as the editor), but faking a release build to
##   verify the negative case isn't something a script test can do; that's
##   verified by code review of the OS.is_debug_build() gate in
##   autoload/debug_console.gd's _ready()/_unhandled_input().
## - Registering the core teleport-to-chunk / force-phase commands is each
##   of those systems' own job once Specs 04/05 exist, not this one's —
##   matches the spec's own "verified incrementally as each dependent spec
##   lands, not all at once here."


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var console: Node = root.get_node_or_null("DebugConsole")
	if console == null:
		push_error("FAIL DebugConsole autoload missing")
		quit(1)
		return

	# --- 1. help lists the built-in commands, including the ones this test
	# will exercise below. ---
	var help_text: String = console.execute("help")
	if not help_text.contains("dump") or not help_text.contains("facts"):
		push_error("FAIL help did not list built-in commands: %s" % help_text)
		quit(1)
		return
	print("PASS help lists registered commands")

	# --- 2. A new system can register a command without modifying this
	# framework's own code — the exact acceptance test's own wording. ---
	var call_count := {"n": 0}
	console.register_command("ping_test", "test-only command", func(_args: Array[String]) -> String:
		call_count["n"] += 1
		return "pong"
	)
	var ping_result: String = console.execute("ping_test")
	if ping_result != "pong" or call_count["n"] != 1:
		push_error("FAIL registered command did not execute correctly")
		quit(1)
		return
	print("PASS a new system can register and run a command with no framework code change")

	# --- 3. Unknown command fails with a message, never crashes the
	# session (Spec 03 failure-case rule). ---
	var unknown_result: String = console.execute("this_command_does_not_exist")
	if not unknown_result.begins_with("Unknown command"):
		push_error("FAIL unknown command did not return a clean error: %s" % unknown_result)
		quit(1)
		return
	print("PASS an unknown/malformed command fails with a message, not a crash")

	# --- 4. dump falls back to a domain's save_state() (Spec 02 contract)
	# with no custom inspector registration required. ---
	var wallet: Node = root.get_node_or_null("Wallet")
	if wallet == null:
		push_error("FAIL Wallet autoload missing")
		quit(1)
		return
	wallet.reset_all()
	wallet.earn(7, "debug console test")
	var dump_result: String = console.execute("dump Wallet")
	if not dump_result.contains("balance") or not dump_result.contains("7"):
		push_error("FAIL dump did not reflect Wallet's save_state(): %s" % dump_result)
		quit(1)
		return
	print("PASS dump uses a domain's existing save_state() with no extra registration")

	# --- 5. A registered custom inspector overrides the save_state()
	# fallback. ---
	console.register_inspector("Wallet", func() -> Dictionary: return {"custom": true})
	var custom_dump: String = console.execute("dump Wallet")
	if not custom_dump.contains("custom"):
		push_error("FAIL registered inspector did not override save_state() fallback")
		quit(1)
		return
	console.unregister_inspector("Wallet")
	print("PASS a registered custom inspector overrides the save_state() fallback")

	# --- 6. facts command reads through to the real FactLog. ---
	var fact_log: Node = root.get_node_or_null("FactLog")
	if fact_log == null:
		push_error("FAIL FactLog autoload missing")
		quit(1)
		return
	fact_log.clear_all()
	var no_witnesses: Array[String] = []
	fact_log.record(&"debug_console_test_fact", "player", &"bottom_west", no_witnesses, {}, 5)
	var facts_result: String = console.execute("facts type=debug_console_test_fact")
	if not facts_result.contains("debug_console_test_fact"):
		push_error("FAIL facts command did not surface the matching fact: %s" % facts_result)
		quit(1)
		return
	var facts_miss: String = console.execute("facts type=no_such_type")
	if not facts_miss.begins_with("No matching facts"):
		push_error("FAIL facts command should report no matches cleanly: %s" % facts_miss)
		quit(1)
		return
	print("PASS facts command filters through the real Fact Log")

	# --- 7. set_trust and spawn_material — real, already-buildable commands
	# wired to the current Trust/Materials stand-ins. ---
	var trust_result: String = console.execute("set_trust 42")
	var trust_node: Node = root.get_node_or_null("Trust")
	if trust_node == null or not is_equal_approx(float(trust_node.get_trust_value()), 42.0) or not trust_result.contains("42"):
		push_error("FAIL set_trust did not move Trust (Build Bible Spec 19) to 42")
		quit(1)
		return
	# spawn_material targets Storage (Build Bible Spec 11), the canon
	# Materials owner, not the retired Resources wallet.
	var storage: Node = root.get_node_or_null("Storage")
	if storage == null:
		push_error("FAIL Storage autoload missing")
		quit(1)
		return
	storage.reset_all()
	var spawn_result: String = console.execute("spawn_material sutral 3")
	if int(storage.get_material_count(&"sutral")) != 3 or not spawn_result.contains("3"):
		push_error("FAIL spawn_material did not add Materials to Storage: %s" % spawn_result)
		quit(1)
		return
	# A retired name is refused with a message, not minted (Spec 11 enforces
	# the locked roster as data).
	var refused: String = console.execute("spawn_material sporemeal 3")
	if not refused.begins_with("Refused") or int(storage.get_material_count(&"sporemeal")) != 0:
		push_error("FAIL spawn_material accepted a retired Material name: %s" % refused)
		quit(1)
		return
	print("PASS set_trust and spawn_material work against the current systems")

	console.unregister_command("ping_test")
	fact_log.clear_all()
	wallet.reset_all()
	storage.reset_all()
	print("DEBUG_CONSOLE_TESTS_PASSED")
	quit(0)
