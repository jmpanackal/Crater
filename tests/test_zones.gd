extends SceneTree
## Build Bible Spec 05 (Authored Topology / Zones) acceptance tests.
##
## This test exercises the loading and seam-validation CONTRACT in isolation
## with synthetic fixture zones, so it stays fast and independent of any real
## content. See tests/test_opening_route.gd for the same contract exercised
## against the real authored opening-route zones (Home Court, Lower
## Switchback, etc.) — that's where "the opening route's ~8 zones load as one
## coherent scene with no visible gaps or misaligned collision at any seam"
## is actually checked.


const FIXTURE_DIR := "res://content/zones/"
const ZONE_A_PATH := FIXTURE_DIR + "test_zone_a.tres"
const ZONE_B_PATH := FIXTURE_DIR + "test_zone_b.tres"
const ZONE_C_PATH := FIXTURE_DIR + "test_zone_c.tres"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var zones: Node = root.get_node_or_null("Zones")
	if zones == null:
		push_error("FAIL Zones autoload missing")
		quit(1)
		return

	_cleanup_fixtures()

	# --- 1. A new zone can be added by adding content, not by editing an
	# existing zone's script — the acceptance test's own wording. ---
	_write_zone("test_zone_a", "Test Zone A", Vector2(0, 0), [
		{"edge": "east", "neighbor": "test_zone_b", "position": 100.0},
	])
	zones.reload_all()
	if not zones.has_zone("test_zone_a"):
		push_error("FAIL a new zone .tres was not picked up by reload_all()")
		quit(1)
		return
	if zones.get_display_name("test_zone_a") != "Test Zone A":
		push_error("FAIL zone display_name did not load correctly")
		quit(1)
		return
	print("PASS a new zone can be added by adding a .tres file, no script change")

	# --- 2. Seam validation: a correctly reciprocal seam pair is valid. ---
	_write_zone("test_zone_b", "Test Zone B", Vector2(500, 0), [
		{"edge": "west", "neighbor": "test_zone_a", "position": 100.0},
	])
	zones.reload_all()
	var problems: Array = zones.validate_seams()
	if not problems.is_empty():
		push_error("FAIL matching reciprocal seams flagged as invalid: %s" % [problems])
		quit(1)
		return
	print("PASS a correctly reciprocal seam pair validates cleanly")

	if zones.get_neighbor_ids("test_zone_a") != ["test_zone_b"]:
		push_error("FAIL get_neighbor_ids did not return the expected neighbor")
		quit(1)
		return
	print("PASS get_neighbor_ids reflects the authored seam graph")

	# --- 3. Seam validation catches a missing reciprocal seam. ---
	_write_zone("test_zone_c", "Test Zone C", Vector2(1000, 0), [
		{"edge": "west", "neighbor": "test_zone_b", "position": 999.0},
		# test_zone_b never lists a seam back to test_zone_c — one-directional.
	])
	zones.reload_all()
	problems = zones.validate_seams()
	var found_missing := false
	for p: String in problems:
		if p.contains("test_zone_c") and p.contains("no matching reciprocal"):
			found_missing = true
	if not found_missing:
		push_error("FAIL missing reciprocal seam was not flagged: %s" % [problems])
		quit(1)
		return
	print("PASS a missing reciprocal seam is caught by validation")

	# --- 4. Seam validation catches a mismatched shared position. ---
	_write_zone("test_zone_b", "Test Zone B", Vector2(500, 0), [
		{"edge": "west", "neighbor": "test_zone_a", "position": 999.0},  # was 100.0 — now mismatched
	])
	zones.reload_all()
	problems = zones.validate_seams()
	var found_mismatch := false
	for p: String in problems:
		if p.contains("position mismatch"):
			found_mismatch = true
	if not found_mismatch:
		push_error("FAIL mismatched seam position was not flagged: %s" % [problems])
		quit(1)
		return
	print("PASS a mismatched seam position is caught by validation")

	_cleanup_fixtures()
	zones.reload_all()
	print("ZONES_TESTS_PASSED")
	quit(0)


func _write_zone(zone_id: String, display_name: String, origin: Vector2, seams: Array) -> void:
	var seam_entries: PackedStringArray = []
	for seam: Dictionary in seams:
		seam_entries.append('{\n"edge": "%s",\n"neighbor": "%s",\n"position": %s\n}' % [
			seam["edge"], seam["neighbor"], seam["position"],
		])
	var seams_literal := "[" + ", ".join(seam_entries) + "]"
	var text := (
		"[gd_resource type=\"Resource\" script_class=\"\" load_steps=2 format=3]\n\n"
		+ "[ext_resource type=\"Script\" path=\"res://content/zone_definition.gd\" id=\"1\"]\n\n"
		+ "[resource]\n"
		+ "script = ExtResource(\"1\")\n"
		+ "zone_id = &\"%s\"\n" % zone_id
		+ "display_name = \"%s\"\n" % display_name
		+ "world_origin = Vector2(%s, %s)\n" % [origin.x, origin.y]
		+ "seams = %s\n" % seams_literal
	)
	var file := FileAccess.open(FIXTURE_DIR + zone_id + ".tres", FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _cleanup_fixtures() -> void:
	for path in [ZONE_A_PATH, ZONE_B_PATH, ZONE_C_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
