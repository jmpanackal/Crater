extends SceneTree
## Build Bible Spec 12 (Deposits + Extraction) acceptance tests.
##
## Uses the real authored east-envelope pockets (content/deposits/
## east_dig_site.tres) so the content path is exercised too, not a
## synthetic deposit. The hold is driven through the real Interact input
## (Input.action_press), the same way test_hollow_lift.gd drives lifts.
##
## Not covered here, and why:
## - Per-Material extraction feel differences — canon-OPEN and tuning-
##   registry-owned per the spec; nothing locked to assert.
## - The physical haul the Material rides home in — Spec 13, not built;
##   extraction grants straight into Storage until then (terrain.gd's
##   _grant_extracted() is the one seam Spec 13 takes over).

const InteractionScript := preload("res://interaction.gd")

const SUTRAL_CELL := Vector2i(70, 34)      # sutral x3
const RAVELSTONE_CELL := Vector2i(84, 44)  # ravelstone x4
const BRINE_CELL := Vector2i(76, 60)       # brinecrystal x2
const PLAIN_CELL := Vector2i(66, 40)       # ordinary rock, no pocket


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage: Node = root.get_node_or_null("Storage")
	var event_bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var hauling: Node = root.get_node_or_null("Hauling")
	if storage == null or event_bus == null or save_load == null or hauling == null:
		push_error("FAIL missing autoloads (Storage / EventBus / SaveLoad / Hauling)")
		quit(1)
		return
	Input.action_release("interact")
	storage.reset_all()
	hauling.reset_all()

	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	await process_frame
	terrain.reset_all()
	var overlay: TileMapLayer = terrain.get_deposit_overlay()
	if overlay == null:
		push_error("FAIL deposit overlay layer missing")
		quit(1)
		return

	var exposed_events: Array = []
	var extracted_events: Array = []
	event_bus.deposit_exposed.connect(func(cell: Vector2i, id: StringName) -> void: exposed_events.append([cell, id]))
	event_bus.material_extracted.connect(func(id: StringName, amount: int, cell: Vector2i) -> void: extracted_events.append([id, amount, cell]))

	# --- 1. Authored pockets load; hidden until dug; ordinary rock is
	# "none"; nothing granted just by existing. ---
	var cells: Array[Vector2i] = terrain.get_deposit_cells()
	if not cells.has(SUTRAL_CELL) or not cells.has(RAVELSTONE_CELL) or not cells.has(BRINE_CELL):
		push_error("FAIL authored east pockets not loaded: %s" % [cells])
		quit(1)
		return
	var sutral_world: Vector2 = terrain.to_global(terrain.map_to_local(SUTRAL_CELL))
	if terrain.get_deposit_state(sutral_world) != &"intact" or bool(terrain.is_deposit_exposed(SUTRAL_CELL)):
		push_error("FAIL hidden deposit should be intact and not exposed")
		quit(1)
		return
	if terrain.get_deposit_state(terrain.to_global(terrain.map_to_local(PLAIN_CELL))) != &"none":
		push_error("FAIL ordinary rock reported a deposit")
		quit(1)
		return
	if overlay.get_cell_source_id(SUTRAL_CELL) != -1 or terrain.get_deposit_node(SUTRAL_CELL) != null:
		push_error("FAIL hidden deposit already has an overlay/interactable")
		quit(1)
		return
	if not terrain.has_tile(SUTRAL_CELL):
		push_error("FAIL deposit cell should still be rock before digging")
		quit(1)
		return
	if int(storage.get_material_count(&"sutral")) != 0:
		push_error("FAIL Material granted before any extraction")
		quit(1)
		return
	print("PASS authored pockets load hidden inside rock; ordinary rock is 'none'; nothing granted")

	# --- 2. Digging EXPOSES the deposit without granting the Material:
	# intact overlay appears, an Interactable appears, Storage unchanged. ---
	var above_world: Vector2 = terrain.to_global(terrain.map_to_local(SUTRAL_CELL + Vector2i.UP))
	var dig_result: Dictionary = terrain.dig(above_world, Vector2i.DOWN)
	if not bool(dig_result["success"]):
		push_error("FAIL dig onto the deposit cell failed: %s" % dig_result)
		quit(1)
		return
	if not bool(terrain.is_deposit_exposed(SUTRAL_CELL)) or terrain.get_deposit_state(sutral_world) != &"intact":
		push_error("FAIL digging did not expose the deposit (still intact)")
		quit(1)
		return
	if overlay.get_cell_atlas_coords(SUTRAL_CELL) != TerrainLayer.DEPOSIT_INTACT_ATLAS:
		push_error("FAIL exposed deposit should show the INTACT overlay")
		quit(1)
		return
	var node: Node = terrain.get_deposit_node(SUTRAL_CELL)
	if node == null or not node.has_method("on_interact"):
		push_error("FAIL exposed deposit has no Interactable node")
		quit(1)
		return
	if int(storage.get_material_count(&"sutral")) != 0:
		push_error("FAIL exposing granted the Material — expose and extract must be distinct")
		quit(1)
		return
	if exposed_events.size() != 1 or exposed_events[0][0] != SUTRAL_CELL or exposed_events[0][1] != &"sutral":
		push_error("FAIL deposit_exposed did not fire exactly once: %s" % [exposed_events])
		quit(1)
		return
	# The player's generic Interaction (Spec 10) finds it by overlap and
	# shows its prompt — no deposit-specific input handling anywhere.
	var interaction: Area2D = InteractionScript.new()
	interaction.global_position = sutral_world
	root.add_child(interaction)
	for _i in range(5):
		await physics_frame
	if interaction.get_current_target() != node or not str(interaction.get_current_prompt()).contains("Sutral"):
		push_error("FAIL Interaction did not target the exposed deposit / prompt: '%s'" % interaction.get_current_prompt())
		quit(1)
		return
	print("PASS digging exposes a deposit without granting it; it's a Spec 10 interactable with a prompt")

	# --- 3. Completing the hold-to-extract grants the Material and flips
	# the visual to depleted; the deposit is finite. With Hauling (Spec 13)
	# present the Material becomes a physical towed bundle first — it only
	# reaches Storage's abstract count when deposited at home. ---
	Input.action_press("interact")
	if not interaction.try_interact(null) or not bool(node.is_extracting()):
		push_error("FAIL Interact did not begin the extraction hold")
		quit(1)
		return
	var hold_frames := int(ceil(float(node.hold_seconds()) * 60.0)) + 60
	for _i in range(hold_frames):
		await physics_frame
		if bool(hauling.is_loaded()):
			break
	Input.action_release("interact")
	await physics_frame
	var load: Dictionary = hauling.get_load()
	if not bool(hauling.is_loaded()) or load["material_id"] != &"sutral" or int(load["amount"]) != 3:
		push_error("FAIL completed extraction did not put 3 Sutral in the towed bundle (got %s)" % [load])
		quit(1)
		return
	if int(storage.get_material_count(&"sutral")) != 0:
		push_error("FAIL extracted Material skipped the physical haul and went straight to Storage")
		quit(1)
		return
	if not bool(hauling.deposit_at_storage()) or int(storage.get_material_count(&"sutral")) != 3:
		push_error("FAIL depositing the bundle did not store 3 Sutral (got %d)" % storage.get_material_count(&"sutral"))
		quit(1)
		return
	if terrain.get_deposit_state(sutral_world) != &"depleted":
		push_error("FAIL deposit not depleted after extraction")
		quit(1)
		return
	if overlay.get_cell_atlas_coords(SUTRAL_CELL) != TerrainLayer.DEPOSIT_DEPLETED_ATLAS:
		push_error("FAIL depleted deposit should show the DEPLETED overlay")
		quit(1)
		return
	if terrain.get_deposit_node(SUTRAL_CELL) != null:
		push_error("FAIL depleted deposit still has an Interactable")
		quit(1)
		return
	if extracted_events.size() != 1 or extracted_events[0][0] != &"sutral" or int(extracted_events[0][1]) != 3 or extracted_events[0][2] != SUTRAL_CELL:
		push_error("FAIL material_extracted did not fire exactly once with the right payload: %s" % [extracted_events])
		quit(1)
		return
	if int(terrain.complete_extraction(SUTRAL_CELL)) != 0 or int(storage.get_material_count(&"sutral")) != 3:
		push_error("FAIL a depleted deposit could be extracted again (must be finite)")
		quit(1)
		return
	print("PASS hold-to-extract grants the Material once, flips to depleted, and never regenerates")

	# --- 4. Cancelling mid-hold leaves the deposit exactly as it was. ---
	var rav_world: Vector2 = terrain.to_global(terrain.map_to_local(RAVELSTONE_CELL))
	terrain.dig(terrain.to_global(terrain.map_to_local(RAVELSTONE_CELL + Vector2i.UP)), Vector2i.DOWN)
	var rav_node: Node = terrain.get_deposit_node(RAVELSTONE_CELL)
	if rav_node == null:
		push_error("FAIL second deposit did not expose")
		quit(1)
		return
	Input.action_press("interact")
	rav_node.begin_extraction()
	for _i in range(12):
		await physics_frame
	if not bool(rav_node.is_extracting()) or float(rav_node.get_extraction_progress()) <= 0.0:
		push_error("FAIL hold did not make progress while Interact was held")
		quit(1)
		return
	Input.action_release("interact")
	for _i in range(3):
		await physics_frame
	if bool(rav_node.is_extracting()) or float(rav_node.get_extraction_progress()) != 0.0:
		push_error("FAIL releasing Interact did not cancel back to zero progress")
		quit(1)
		return
	if terrain.get_deposit_state(rav_world) != &"intact" or overlay.get_cell_atlas_coords(RAVELSTONE_CELL) != TerrainLayer.DEPOSIT_INTACT_ATLAS:
		push_error("FAIL cancelled extraction changed the deposit")
		quit(1)
		return
	if int(storage.get_material_count(&"ravelstone")) != 0 or extracted_events.size() != 1:
		push_error("FAIL cancelled extraction granted something")
		quit(1)
		return
	# ...and it can still be completed afterwards in full.
	Input.action_press("interact")
	rav_node.begin_extraction()
	for _i in range(hold_frames):
		await physics_frame
		if bool(hauling.is_loaded()):
			break
	Input.action_release("interact")
	await physics_frame
	if not bool(hauling.deposit_at_storage()) or int(storage.get_material_count(&"ravelstone")) != 4 or terrain.get_deposit_state(rav_world) != &"depleted":
		push_error("FAIL deposit could not be extracted after a cancelled attempt")
		quit(1)
		return
	print("PASS cancelling mid-hold leaves the deposit untouched; it can still be extracted later")

	# --- 5. Persistence through the real SaveLoad system: exposed stays
	# exposed (with its interactable rebuilt, no new discovery event),
	# depleted stays depleted, hidden stays hidden. ---
	terrain.dig(terrain.to_global(terrain.map_to_local(BRINE_CELL + Vector2i.UP)), Vector2i.DOWN)
	if terrain.get_deposit_node(BRINE_CELL) == null:
		push_error("FAIL third deposit did not expose")
		quit(1)
		return
	var events_before_load := exposed_events.size()
	save_load.clear_save()
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return
	terrain.reset_all()
	if bool(terrain.is_deposit_exposed(BRINE_CELL)) or terrain.get_deposit_state(sutral_world) != &"intact":
		push_error("FAIL reset_all did not re-seed deposits to hidden/intact")
		quit(1)
		return
	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return
	await process_frame
	if terrain.get_deposit_state(sutral_world) != &"depleted" or overlay.get_cell_atlas_coords(SUTRAL_CELL) != TerrainLayer.DEPOSIT_DEPLETED_ATLAS:
		push_error("FAIL depleted deposit did not stay depleted across reload")
		quit(1)
		return
	if terrain.get_deposit_state(rav_world) != &"depleted":
		push_error("FAIL second depleted deposit did not persist")
		quit(1)
		return
	if not bool(terrain.is_deposit_exposed(BRINE_CELL)) or terrain.get_deposit_node(BRINE_CELL) == null or overlay.get_cell_atlas_coords(BRINE_CELL) != TerrainLayer.DEPOSIT_INTACT_ATLAS:
		push_error("FAIL exposed-but-intact deposit was not restored with its interactable")
		quit(1)
		return
	if terrain.has_tile(BRINE_CELL):
		push_error("FAIL restored exposed deposit is buried under rock again")
		quit(1)
		return
	var hidden_world: Vector2 = terrain.to_global(terrain.map_to_local(Vector2i(98, 40)))
	if bool(terrain.is_deposit_exposed(Vector2i(98, 40))) or terrain.get_deposit_state(hidden_world) != &"intact":
		push_error("FAIL an untouched pocket did not stay hidden/intact")
		quit(1)
		return
	if exposed_events.size() != events_before_load:
		push_error("FAIL restoring a save emitted deposit_exposed (restoration is not a discovery)")
		quit(1)
		return
	if int(storage.get_material_count(&"sutral")) != 3 or int(storage.get_material_count(&"ravelstone")) != 4:
		push_error("FAIL extracted Materials did not persist alongside the deposits")
		quit(1)
		return
	print("PASS deposit states and their interactables persist across a real save/load round-trip")

	Input.action_release("interact")
	save_load.clear_save()
	storage.reset_all()
	hauling.reset_all()
	interaction.queue_free()
	root.remove_child(terrain)
	terrain.queue_free()
	print("DEPOSITS_TESTS_PASSED")
	quit(0)
