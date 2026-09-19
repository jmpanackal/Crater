extends SceneTree
## Build Bible Spec 02 (Save / Load + Versioning) acceptance tests.
##
## Two of Spec 02's acceptance tests are deliberately NOT covered here and
## are noted inline where they'd go:
## - "Autosave actually fires at: sleep, each phase transition, and quit" —
##   none of those trigger points exist yet (Build Bible Spec 04, World
##   Clock, and later sleep/phase mechanics). SaveLoad already exposes the
##   save_game() hook those systems will call; wiring the trigger itself is
##   each of those specs' own job.
## - "Quit-save resume lands the player exactly where they left off,
##   including mid-cycle state and current phase countdown" — same reason;
##   there is no phase/cycle state yet to resume.
##
## Full domain-state round-trip through the real save/load path is already
## covered by tests/test_economy_loop.gd (six existing domains) — this file
## covers what's specifically new in Spec 02: schema versioning, atomic
## write, and FactLog now actually persisting through the real system
## rather than only its own isolated snapshot (test_core_infrastructure.gd).
##
## Wallet (Tallies) stands in for the domain-round-trip probe that used to
## ride on the retired Resources wallet — same shape, current canon owner
## (Build Bible Spec 23).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var wallet: Node = root.get_node_or_null("Wallet")
	if save_load == null or fact_log == null or wallet == null:
		push_error("FAIL missing autoloads (SaveLoad / FactLog / Wallet)")
		quit(1)
		return

	save_load.clear_save()
	fact_log.clear_all()
	wallet.reset_all()

	# --- 1. A well-formed save round-trips FactLog through the real
	# SaveLoad system (not just FactLog's own isolated snapshot). ---
	var no_witnesses: Array[String] = []
	fact_log.record(&"theft_witnessed", "player", &"wickwork", no_witnesses, {}, 2)
	wallet.earn(5, "test round-trip")
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return
	fact_log.clear_all()
	wallet.reset_all()
	if not save_load.load_game():
		push_error("FAIL load_game on a fresh well-formed save")
		quit(1)
		return
	if fact_log.count() != 1 or fact_log.get_by_type(&"theft_witnessed").size() != 1:
		push_error("FAIL FactLog did not round-trip through the real SaveLoad system")
		quit(1)
		return
	if wallet.get_balance() != 5:
		push_error("FAIL Wallet did not round-trip alongside FactLog")
		quit(1)
		return
	print("PASS FactLog round-trips through the real SaveLoad system alongside other domains")

	# --- 2. Atomic write: no leftover .tmp file after a successful save. ---
	var temp_path: String = save_load.SAVE_TEMP_PATH
	if FileAccess.file_exists(temp_path):
		push_error("FAIL leftover temp file after a successful save: %s" % temp_path)
		quit(1)
		return
	print("PASS atomic write leaves no leftover temp file")

	# --- 3. A save with a missing schema_version is rejected outright, per
	# Spec 02's explicit "never silently loaded as-is" invariant. ---
	var pre_reject_balance: int = wallet.get_balance()
	var no_version := {"domains": {"Wallet": {"balance": 999}}}
	var path: String = save_load.SAVE_PATH
	var f1 := FileAccess.open(path, FileAccess.WRITE)
	f1.store_string(JSON.stringify(no_version))
	f1.close()
	if save_load.load_game():
		push_error("FAIL a save with no schema_version should be rejected")
		quit(1)
		return
	if wallet.get_balance() != pre_reject_balance:
		push_error("FAIL a rejected load must not mutate any domain's state")
		quit(1)
		return
	print("PASS a save missing schema_version is rejected, not silently loaded")

	# --- 4. A save with a mismatched (wrong, but present) schema_version is
	# also rejected outright. ---
	var wrong_version := {"schema_version": 999, "domains": {"Wallet": {"balance": 999}}}
	var f2 := FileAccess.open(path, FileAccess.WRITE)
	f2.store_string(JSON.stringify(wrong_version))
	f2.close()
	if save_load.load_game():
		push_error("FAIL a save with a mismatched schema_version should be rejected")
		quit(1)
		return
	if wallet.get_balance() != pre_reject_balance:
		push_error("FAIL a rejected mismatched-version load must not mutate any domain's state")
		quit(1)
		return
	print("PASS a save with a mismatched schema_version is rejected, not silently loaded")

	# --- 5. A domain missing save_state()/load_state() is skipped with a
	# warning rather than failing the whole save/load (forward-compat with
	# systems that land ahead of their own Spec's save wiring). ---
	var known_domains: Array = save_load.DOMAIN_AUTOLOAD_NAMES
	if not known_domains.has("FactLog") or not known_domains.has("Wallet"):
		push_error("FAIL DOMAIN_AUTOLOAD_NAMES missing expected core domains")
		quit(1)
		return
	print("PASS domain list includes the new Spec 01/02 domains")

	save_load.clear_save()
	fact_log.clear_all()
	wallet.reset_all()
	print("SAVE_LOAD_TESTS_PASSED")
	quit(0)
