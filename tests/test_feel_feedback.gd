extends SceneTree
## Dig hit-stop Firmament shorter than Devil's Mouth; salvage/record floats; NPC face/bob;
## civic-cycle countdown pulse; requisition toast tone; dig approach threshold; title quiet.

const FeelAudio := preload("res://feel_audio.gd")
const UpgradeHudScript := preload("res://upgrade_hud.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if save_load:
		save_load.clear_save()
	# clear_save() only deletes the file — SaveLoad's own autoload _ready()
	# already deferred-loads whatever save existed on disk BEFORE this
	# test's _run() gets to execute (both are call_deferred from _init/
	# _ready, and autoloads enter the tree first), so a stale leftover save
	# from an earlier test run can still leave Storage/District/etc.
	# seeded with old values. Reset the ones this test actually depends on
	# explicitly rather than assuming "no save file" implies "fresh state".
	var storage: Node = root.get_node_or_null("Storage")
	if storage and storage.has_method("reset_all"):
		storage.reset_all()

	# --- Hit-stop Firmament shorter than Devil's Mouth ---
	FeelFx.reset_debug()
	var firmament_h := FeelFx.dig_hitstop_ms(true, false)
	var mid_h := FeelFx.dig_hitstop_ms(false, false)
	var mouth_h := FeelFx.dig_hitstop_ms(false, true)
	if not (firmament_h < mid_h and mid_h < mouth_h):
		push_error("FAIL hitstop order firmament=%s mid=%s mouth=%s" % [firmament_h, mid_h, mouth_h])
		quit(1)
		return
	if mouth_h > 50.0:
		push_error("FAIL Devil's Mouth hitstop too long (%s ms)" % mouth_h)
		quit(1)
		return
	print("PASS dig hitstop Firmament shorter than Devil's Mouth")

	# --- Notice toast tones (canon Requisition notices — Build Bible Spec
	# 23; the retired Harvest-miss/lie copy is gone, no "caution" tone is
	# reachable through notice_tone_for() any more) ---
	if UpgradeHudScript.notice_tone_for("Order refused — not enough Tallies.") != &"loss":
		push_error("FAIL loss notice tone")
		quit(1)
		return
	if UpgradeHudScript.notice_tone_for("Order placed.") != &"gain":
		push_error("FAIL gain notice tone")
		quit(1)
		return
	if UpgradeHudScript.notice_tone_for("Wickwork: Stable.") != &"neutral":
		push_error("FAIL neutral notice tone")
		quit(1)
		return
	print("PASS requisition toast tone clarity")

	# --- Terrain dig: float + hitstop request ---
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	terrain.clear()
	var firmament_cell := Vector2i(18, 10) ## World-scale pass (2026-09-19): row bands x5
	var mouth_cell := Vector2i(18, 300)
	terrain.set_cell(firmament_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	terrain.set_cell(mouth_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)

	# Deterministic: an upward dig has a 12% chance to also find a Record,
	# which spawns a SECOND float after the salvage one and made the
	# "last float is salvage" check below fail intermittently.
	var journal: Node = root.get_node_or_null("Journal")
	if journal != null:
		journal.force_find_on_dig = false
	FeelFx.reset_debug()
	if not terrain.destroy_cell(firmament_cell, Vector2i.UP):
		push_error("FAIL Firmament dig")
		quit(1)
		return
	var firmament_stop := FeelFx.last_hitstop_ms
	if FeelFx.float_spawn_count < 1 or FeelFx.last_float_kind != &"salvage":
		push_error("FAIL Firmament salvage float missing")
		quit(1)
		return
	if FeelFx.hitstop_request_count < 1:
		push_error("FAIL Firmament hitstop not requested")
		quit(1)
		return

	FeelFx.reset_debug()
	if not terrain.destroy_cell(mouth_cell, Vector2i.DOWN):
		push_error("FAIL Devil's Mouth dig")
		quit(1)
		return
	if FeelFx.last_hitstop_ms <= firmament_stop:
		push_error("FAIL Devil's Mouth hitstop not longer than Firmament (%s vs %s)" % [FeelFx.last_hitstop_ms, firmament_stop])
		quit(1)
		return
	if not str(FeelFx.last_float_text).begins_with("+"):
		push_error("FAIL salvage float text '%s'" % FeelFx.last_float_text)
		quit(1)
		return
	print("PASS dig salvage float + Firmament/Devil's Mouth hitstop")

	# Restore timescale after live hitstop request.
	FeelFx.reset_debug()
	await process_frame

	# --- Scene polish ---
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame


	# QUARANTINED (2026-09-18): "NPC face toward player + bob parts" drove
	# Hollow/NPCs/Pell to prove facing + bob-part presence. main.tscn's
	# Hollow subtree was deleted for a canon-grounded rebuild
	# (docs/hollow-level-authoring.md). This pass only rebuilds Home Court +
	# Bottom-West Dig Front; Glowbeds and its NPC are a later phase. Restore
	# this test's real assertions once Glowbeds/Pell are rebuilt — tracked in
	# docs/priority-roadmap.md, not forgotten.
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	if player == null:
		push_error("FAIL player missing")
		quit(1)
		return

	var panel: Node = scene.get_node_or_null("UI/UpgradePanel")
	var clock_live: Node = root.get_node_or_null("Clock")
	if panel == null or clock_live == null:
		push_error("FAIL panel/clock missing")
		quit(1)
		return
	# Force the civic-cycle countdown into its final-10-seconds urgency band
	# (the harvest-timer pulse's real successor — see upgrade_hud.gd's
	# _refresh_status()/is_cycle_urgent()) by driving seconds_in_phase far
	# past the phase length; get_seconds_remaining_in_phase() clamps at 0.
	clock_live.load_state({"phase": "rousing", "cycles_elapsed": 0, "seconds_in_phase": 999999.0})
	await process_frame
	await process_frame
	if not panel.has_method("is_cycle_urgent") or not panel.is_cycle_urgent():
		push_error("FAIL civic-cycle urgency not active with no time left in phase")
		quit(1)
		return
	var cycle_lbl: Label = scene.get_node("UI/CycleLabel") as Label
	if cycle_lbl == null or cycle_lbl.modulate.r < 0.9 or cycle_lbl.modulate.a < 0.5:
		push_error(
			"FAIL civic-cycle pulse modulate flat %s"
			% (cycle_lbl.modulate if cycle_lbl else Color())
		)
		quit(1)
		return
	print("PASS civic-cycle countdown urgent pulse band")
	clock_live.reset_all()

	if panel.has_method("_show_notice"):
		panel._show_notice("Order refused — not enough Tallies.")
		if panel.debug_notice_tone() != &"loss":
			push_error("FAIL notice tone after show")
			quit(1)
			return
	print("PASS notice tone applied on show")

	# Title quiet atmosphere.
	var title_packed: PackedScene = load("res://title_screen.tscn")
	var title: Node = title_packed.instantiate()
	root.add_child(title)
	await process_frame
	if not title.has_method("has_quiet_atmosphere") or not title.has_quiet_atmosphere():
		push_error("FAIL title quiet atmosphere missing")
		quit(1)
		return
	print("PASS title INMOST-quiet atmosphere")

	FeelFx.reset_debug()
	print("FEEL_FEEDBACK_TESTS_PASSED")
	quit(0)
