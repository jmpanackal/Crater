extends SceneTree
## Dig/land dust Firmament quieter than Pit; sprite squash; dig-site dressing; orphan tiles gone.

const FeelAudio := preload("res://feel_audio.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var community: Node = root.get_node_or_null("Community")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if community:
		community.set_paused(true)
		if "skip_lie_prompt" in community:
			community.skip_lie_prompt = true
	if save_load:
		save_load.clear_save()

	# --- Intensity helpers (Firmament quieter than Pit) ---
	FeelFx.reset_debug()
	var cap_i := FeelFx.dig_intensity(true, false)
	var mid_i := FeelFx.dig_intensity(false, false)
	var pit_i := FeelFx.dig_intensity(false, true)
	if not (cap_i < mid_i and mid_i < pit_i):
		push_error("FAIL dig intensity order firmament=%s mid=%s pit=%s" % [cap_i, mid_i, pit_i])
		quit(1)
		return
	print("PASS Firmament dig dust quieter than Pit")

	# --- Soft shake amps Firmament quieter than Pit ---
	var cap_s := FeelFx.dig_shake_amp(true, false)
	var mid_s := FeelFx.dig_shake_amp(false, false)
	var pit_s := FeelFx.dig_shake_amp(false, true)
	if not (cap_s < mid_s and mid_s < pit_s):
		push_error("FAIL dig shake order firmament=%s mid=%s pit=%s" % [cap_s, mid_s, pit_s])
		quit(1)
		return
	if FeelFx.land_shake_amp(1.2) <= FeelFx.land_shake_amp(0.3):
		push_error("FAIL land shake should scale with impact")
		quit(1)
		return
	print("PASS Firmament dig shake quieter than Pit")

	# --- Procedural dig SFX stubs (Firmament quieter volume) ---
	FeelAudio.reset_debug()
	var cap_vol := FeelAudio.dig_volume_db(true, false)
	var pit_vol := FeelAudio.dig_volume_db(false, true)
	if cap_vol >= pit_vol:
		push_error("FAIL Firmament dig SFX not quieter than Pit (%s vs %s)" % [cap_vol, pit_vol])
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

	# --- Terrain dig spawns Firmament vs Pit dust ---
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	terrain.clear()
	var cap_cell := Vector2i(18, 2)
	var pit_cell := Vector2i(18, 12)
	terrain.set_cell(cap_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	terrain.set_cell(pit_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)

	FeelFx.reset_debug()
	if not terrain.destroy_cell(cap_cell, Vector2i.UP):
		push_error("FAIL Firmament dig")
		quit(1)
		return
	var cap_dust := FeelFx.last_dust_intensity
	if FeelFx.last_dust_kind != &"dig" or cap_dust >= 0.7:
		push_error("FAIL Firmament dig dust too loud kind=%s i=%s" % [FeelFx.last_dust_kind, cap_dust])
		quit(1)
		return

	FeelFx.reset_debug()
	if not terrain.destroy_cell(pit_cell, Vector2i.DOWN):
		push_error("FAIL Pit dig")
		quit(1)
		return
	var pit_dust := FeelFx.last_dust_intensity
	if pit_dust <= cap_dust:
		push_error("FAIL Pit dust not heavier than Firmament (%s vs %s)" % [pit_dust, cap_dust])
		quit(1)
		return
	print("PASS dig dust Firmament quieter than Pit in destroy_cell")

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
	if not dressing.has_method("firmament_quieter_than_pit") or not dressing.firmament_quieter_than_pit():
		push_error("FAIL Firmament haze not quieter than Pit gloom")
		quit(1)
		return
	if dressing.get_node_or_null("FirmamentHaze") == null or dressing.get_node_or_null("PitGloom") == null:
		push_error("FAIL Firmament/Pit dressing rects missing")
		quit(1)
		return
	print("PASS Firmament↑ / Pit↓ dig-site dressing")

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

	# Orphan single-tile dig sheets retired — atlas remains.
	for orphan in [
		"res://sprites/dig_site_cracked.png",
		"res://sprites/dig_site_debris.png",
		"res://sprites/dig_site_rubble.png",
		"res://sprites/dig_site_solid.png",
	]:
		if ResourceLoader.exists(orphan):
			push_error("FAIL orphan still present: %s" % orphan)
			quit(1)
			return
	if not ResourceLoader.exists("res://sprites/dig_site_tiles.png"):
		push_error("FAIL dig_site_tiles.png missing")
		quit(1)
		return
	print("PASS orphan dig_site_*.png retired; atlas kept")

	# Lie UX dimmer present; journal subtitle/count helpers.
	if scene.get_node_or_null("UI/LieDimmer") == null:
		push_error("FAIL LieDimmer missing")
		quit(1)
		return
	var journal_hud := scene.get_node_or_null("UI/JournalHud")
	if journal_hud == null:
		push_error("FAIL JournalHud missing")
		quit(1)
		return
	if scene.get_node_or_null("UI/JournalHud/Panel/Margin/VBox/Subtitle") == null:
		push_error("FAIL Journal subtitle missing")
		quit(1)
		return
	print("PASS Harvest lie dimmer + Journal subtitle")

	# Soft fog drift node present.
	if scene.get_node_or_null("Hollow/FarHaze") == null:
		push_error("FAIL FarHaze parallax polish missing")
		quit(1)
		return
	if scene.get_node_or_null("Hollow/PitShaftVeil") == null:
		push_error("FAIL PitShaftVeil parallax layer missing")
		quit(1)
		return
	print("PASS Hollow FarHaze + PitShaftVeil depth polish")

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
	var cap_h := FeelFx.dig_hitstop_ms(true, false)
	var pit_h := FeelFx.dig_hitstop_ms(false, true)
	if cap_h >= pit_h:
		push_error("FAIL Firmament hitstop not quieter/shorter than Pit")
		quit(1)
		return
	print("PASS dig hitstop Firmament shorter than Pit (smoke)")

	print("FEEL_POLISH_TESTS_PASSED")
	quit(0)
