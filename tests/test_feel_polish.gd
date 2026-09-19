extends SceneTree
## Dig/land dust Firmament quieter than Devil's Mouth; sprite squash; dig-site dressing; orphan tiles gone.

const FeelAudio := preload("res://feel_audio.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if save_load:
		save_load.clear_save()

	# --- Intensity helpers (Firmament quieter than Devil's Mouth) ---
	FeelFx.reset_debug()
	var firmament_i := FeelFx.dig_intensity(true, false)
	var mid_i := FeelFx.dig_intensity(false, false)
	var mouth_i := FeelFx.dig_intensity(false, true)
	if not (firmament_i < mid_i and mid_i < mouth_i):
		push_error("FAIL dig intensity order firmament=%s mid=%s mouth=%s" % [firmament_i, mid_i, mouth_i])
		quit(1)
		return
	print("PASS Firmament dig dust quieter than Devil's Mouth")

	# --- Soft shake amps Firmament quieter than Devil's Mouth ---
	var firmament_s := FeelFx.dig_shake_amp(true, false)
	var mid_s := FeelFx.dig_shake_amp(false, false)
	var mouth_s := FeelFx.dig_shake_amp(false, true)
	if not (firmament_s < mid_s and mid_s < mouth_s):
		push_error("FAIL dig shake order firmament=%s mid=%s mouth=%s" % [firmament_s, mid_s, mouth_s])
		quit(1)
		return
	if FeelFx.land_shake_amp(1.2) <= FeelFx.land_shake_amp(0.3):
		push_error("FAIL land shake should scale with impact")
		quit(1)
		return
	print("PASS Firmament dig shake quieter than Devil's Mouth")

	# --- Procedural dig SFX stubs (Firmament quieter volume) ---
	FeelAudio.reset_debug()
	var firmament_vol := FeelAudio.dig_volume_db(true, false)
	var mouth_vol := FeelAudio.dig_volume_db(false, true)
	if firmament_vol >= mouth_vol:
		push_error("FAIL Firmament dig SFX not quieter than Devil's Mouth (%s vs %s)" % [firmament_vol, mouth_vol])
		quit(1)
		return
	FeelAudio.play_dig(root, true, false)
	FeelAudio.play_dig(root, false, true)
	if FeelAudio.dig_play_count < 2:
		push_error("FAIL dig SFX stubs did not play")
		quit(1)
		return
	if FeelAudio.last_kind != &"dig":
		push_error("FAIL dig SFX kind")
		quit(1)
		return
	print("PASS dig SFX stubs Firmament quieter + pitch hooks")

	# --- Terrain dig spawns Firmament vs Devil's Mouth dust ---
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	terrain.clear()
	var firmament_cell := Vector2i(18, 10) ## World-scale pass (2026-09-19): row bands x5
	var mouth_cell := Vector2i(18, 300)
	terrain.set_cell(firmament_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	terrain.set_cell(mouth_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)

	FeelFx.reset_debug()
	if not terrain.destroy_cell(firmament_cell, Vector2i.UP):
		push_error("FAIL Firmament dig")
		quit(1)
		return
	var firmament_dust := FeelFx.last_dust_intensity
	if FeelFx.last_dust_kind != &"dig" or firmament_dust >= 0.7:
		push_error("FAIL Firmament dig dust too loud kind=%s i=%s" % [FeelFx.last_dust_kind, firmament_dust])
		quit(1)
		return

	FeelFx.reset_debug()
	if not terrain.destroy_cell(mouth_cell, Vector2i.DOWN):
		push_error("FAIL Devil's Mouth dig")
		quit(1)
		return
	var mouth_dust := FeelFx.last_dust_intensity
	if mouth_dust <= firmament_dust:
		push_error("FAIL Devil's Mouth dust not heavier than Firmament (%s vs %s)" % [mouth_dust, firmament_dust])
		quit(1)
		return
	print("PASS dig dust Firmament quieter than Devil's Mouth in destroy_cell")

	# --- Scene: dressing + squash + land dust + orphans gone ---
	var scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var dressing: Node = scene.get_node_or_null("DigDressing")
	if dressing == null:
		push_error("FAIL DigDressing missing")
		quit(1)
		return
	if dressing.get_node_or_null("FirmamentHaze") == null:
		push_error("FAIL Firmament dressing rect missing")
		quit(1)
		return
	# The downward dig direction used to carry its own "Devil's Mouth" gloom/
	# label here too, reusing the name of the real crater void elsewhere in
	# the Hollow — removed 2026-09-19 as a confusing stray artifact.
	if dressing.get_node_or_null("MouthGloom") != null or dressing.get_node_or_null("DevilsMouthMark") != null:
		push_error("FAIL stale Devil's Mouth dig-site dressing should be gone")
		quit(1)
		return
	print("PASS Firmament↑ dig-site dressing; no stray Devil's Mouth artifact")

	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	FeelFx.reset_debug()
	player.debug_force_land_feel(1.0)
	var scale: Vector2 = player.debug_feel_scale()
	if scale.x <= 1.0 or scale.y >= 1.0:
		push_error("FAIL land squash scale=%s" % scale)
		quit(1)
		return
	if FeelFx.last_dust_kind != &"land" or FeelFx.dust_spawn_count < 1:
		push_error("FAIL land dust not spawned")
		quit(1)
		return
	if FeelFx.shake_request_count < 1 or FeelFx.last_shake_amp < 0.15:
		push_error("FAIL land shake not requested amp=%s" % FeelFx.last_shake_amp)
		quit(1)
		return
	if FeelAudio.land_play_count < 1:
		push_error("FAIL land SFX stub not played")
		quit(1)
		return
	print("PASS land squash + land dust")

	# Camera look-ahead / deadzone / shake group.
	var cam: Camera2D = scene.get_node_or_null("Player/Camera2D") as Camera2D
	if cam == null or cam.get_script() == null:
		push_error("FAIL camera_follow script missing")
		quit(1)
		return
	if not cam.drag_horizontal_enabled or not cam.drag_vertical_enabled:
		push_error("FAIL camera deadzone drag margins disabled")
		quit(1)
		return
	if not cam.is_in_group("player_camera"):
		push_error("FAIL camera not in player_camera group")
		quit(1)
		return
	if cam.has_method("apply_shake"):
		cam.apply_shake(0.8)
		if cam.has_method("debug_shake") and float(cam.debug_shake()) < 0.5:
			push_error("FAIL camera shake not applied")
			quit(1)
			return
	print("PASS camera look-ahead / deadzone / shake")

	# Jump stretch via buffered jump on floor.
	var stand := HollowLayout.safe_stand_points()[0]
	player.global_position = stand
	player.velocity = Vector2.ZERO
	for _i in range(6):
		await physics_frame
	player.debug_set_jump_buffer(player.JUMP_BUFFER)
	await physics_frame
	var stretch: Vector2 = player.debug_feel_scale()
	if stretch.y <= 1.0 or stretch.x >= 1.0:
		push_error("FAIL jump stretch scale=%s" % stretch)
		quit(1)
		return
	print("PASS jump stretch (sprite only)")

	# Orphan single-tile dig sheets retired. The real dig_site_tiles.png
	# atlas is retired too (2026-09-17 scale correction) — sized for the
	# old 64px grid and generated in a style that predates the
	# placeholder-art-first plan; Terrain now uses a flat-color
	# placeholder instead (see terrain.gd's _build_tileset()).
	for orphan in [
		"res://sprites/dig_site_cracked.png",
		"res://sprites/dig_site_debris.png",
		"res://sprites/dig_site_rubble.png",
		"res://sprites/dig_site_solid.png",
		"res://sprites/dig_site_tiles.png",
	]:
		if ResourceLoader.exists(orphan):
			push_error("FAIL orphan still present: %s" % orphan)
			quit(1)
			return
	print("PASS orphan/retired dig_site_*.png sheets gone; placeholder tileset in use")

	# Journal subtitle/count helpers. The retired Harvest-miss lie dimmer
	# (UI/LieDimmer) has no successor — the lie/truth prompt it dimmed for
	# is gone outright (Build Bible Spec 15: Ritual-miss is contextual,
	# never an automatic stat penalty; no prompt is rebuilt), so there is
	# nothing left for a dimmer to gate and no node to assert on.
	var journal_hud := scene.get_node_or_null("UI/JournalHud")
	if journal_hud == null:
		push_error("FAIL JournalHud missing")
		quit(1)
		return
	if scene.get_node_or_null("UI/JournalHud/Panel/Margin/VBox/Subtitle") == null:
		push_error("FAIL Journal subtitle missing")
		quit(1)
		return
	print("PASS Journal subtitle")

	# QUARANTINED (2026-09-18): "Hollow FarHaze + PitShaftVeil depth polish"
	# checked Hollow/FarHaze and Hollow/PitShaftVeil parallax dressing.
	# main.tscn's Hollow subtree was deleted for a canon-grounded rebuild
	# (docs/hollow-level-authoring.md). This pass only rebuilds Home Court +
	# Bottom-West Dig Front; that depth-polish dressing is a later phase.
	# Restore this test's real assertions once it is rebuilt — tracked in
	# docs/priority-roadmap.md, not forgotten.

	# Help text mentions climb.
	var hints: Label = scene.get_node_or_null("UI/Hints") as Label
	if hints == null or not ("climb" in hints.text.to_lower()):
		push_error("FAIL help hints missing climb")
		quit(1)
		return
	print("PASS help text mentions climb")

	# Dig approach threshold + hitstop helpers (smoke).
	var approach: Node = scene.get_node_or_null("Approach")
	if approach == null or not approach.has_method("entry_reads_as_threshold") or not approach.entry_reads_as_threshold():
		push_error("FAIL dig approach threshold")
		quit(1)
		return
	print("PASS dig approach threshold")

	FeelFx.reset_debug()
	var firmament_h := FeelFx.dig_hitstop_ms(true, false)
	var mouth_h := FeelFx.dig_hitstop_ms(false, true)
	if firmament_h >= mouth_h:
		push_error("FAIL Firmament hitstop not quieter/shorter than Devil's Mouth")
		quit(1)
		return
	print("PASS dig hitstop Firmament shorter than Devil's Mouth (smoke)")

	print("FEEL_POLISH_TESTS_PASSED")
	quit(0)
