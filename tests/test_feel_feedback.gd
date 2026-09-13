extends SceneTree
## Dig hit-stop Firmament shorter than Devil's Mouth; salvage/record floats; NPC face/bob;
## harvest pulse; trust toast tone; dig approach threshold; title quiet.

const FeelAudio := preload("res://feel_audio.gd")
const UpgradeHudScript := preload("res://upgrade_hud.gd")


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

	# --- Notice toast tones ---
	if UpgradeHudScript.notice_tone_for("Missed Harvest. People noticed you were gone.") != &"loss":
		push_error("FAIL miss notice tone")
		quit(1)
		return
	if UpgradeHudScript.notice_tone_for("You help in the Farms. (+1 Trust)") != &"gain":
		push_error("FAIL gain notice tone")
		quit(1)
		return
	if UpgradeHudScript.notice_tone_for("You lied about where you were. For now, it holds.") != &"caution":
		push_error("FAIL caution notice tone")
		quit(1)
		return
	if UpgradeHudScript.notice_tone_for("Theft complete. Cover held.") != &"neutral":
		push_error("FAIL neutral notice tone")
		quit(1)
		return
	print("PASS trust toast tone clarity")

	# --- Terrain dig: float + hitstop request ---
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	terrain.clear()
	var firmament_cell := Vector2i(18, 2)
	var mouth_cell := Vector2i(18, 12)
	terrain.set_cell(firmament_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)
	terrain.set_cell(mouth_cell, 0, TerrainLayer.PLACEHOLDER_ATLAS)

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

	var approach: Node = scene.get_node_or_null("Approach")
	if approach == null or not approach.has_method("entry_reads_as_threshold"):
		push_error("FAIL Approach dig entry script missing")
		quit(1)
		return
	if not approach.entry_reads_as_threshold():
		push_error("FAIL dig site entry threshold pieces")
		quit(1)
		return
	print("PASS dig site entry threshold")

	var npc: Node2D = scene.get_node_or_null("Hollow/NPCs/Pell") as Node2D
	var player: CharacterBody2D = scene.get_node("Player") as CharacterBody2D
	if npc == null or player == null:
		push_error("FAIL NPC/player missing")
		quit(1)
		return
	player.global_position = npc.global_position + Vector2(80, 0)
	await process_frame
	await process_frame
	if not npc.has_method("debug_face_sign") or float(npc.debug_face_sign()) <= 0.0:
		push_error("FAIL NPC did not face player to the right")
		quit(1)
		return
	player.global_position = npc.global_position + Vector2(-80, 0)
	await process_frame
	await process_frame
	if float(npc.debug_face_sign()) >= 0.0:
		push_error("FAIL NPC did not face player to the left")
		quit(1)
		return
	if npc.get_node_or_null("Body") == null or npc.get_node_or_null("Head") == null:
		push_error("FAIL NPC body/head missing for bob")
		quit(1)
		return
	print("PASS NPC face toward player + bob parts")

	var panel: Node = scene.get_node_or_null("UI/UpgradePanel")
	var community_live: Node = root.get_node_or_null("Community")
	if panel == null or community_live == null:
		push_error("FAIL panel/community missing")
		quit(1)
		return
	community_live.set_harvest_timer(8.0)
	await process_frame
	await process_frame
	if not panel.has_method("is_harvest_urgent") or not panel.is_harvest_urgent():
		push_error("FAIL harvest urgency not active at 8s")
		quit(1)
		return
	var harvest_lbl: Label = scene.get_node("UI/HarvestLabel") as Label
	if harvest_lbl == null or harvest_lbl.modulate.r < 0.9 or harvest_lbl.modulate.a < 0.5:
		push_error(
			"FAIL harvest pulse modulate flat %s"
			% (harvest_lbl.modulate if harvest_lbl else Color())
		)
		quit(1)
		return
	print("PASS harvest clock urgent pulse band")

	if panel.has_method("_show_notice"):
		panel._show_notice("Caught digging the Firmament — and your lie cracked. (−12 Trust)")
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
