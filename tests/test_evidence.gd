extends SceneTree
## Build Bible Spec 18 (Physical Evidence) acceptance tests.
##
## Not covered here, and why:
## - Investigation actually requesting a search and logging found_evidence
##   facts — Spec 20's job; resolve_search() returning what a search finds
##   is the contract it consumes, tested here directly.
## - Which Secrecy Gear raises a seal's tier — the spec's own open item.
##   Rig.EFFECT_SEAL_TIER_BONUS is the hook; no authored Gear provides it
##   yet, so it is exercised with a stub Rig effect, not real Gear.
## - Personal-storage / workspace search (Spec 27) and graft concealment
##   (Spec 28) — separate concealment states, per the spec's scope note.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var evidence: Node = root.get_node_or_null("Evidence")
	var zones: Node = root.get_node_or_null("Zones")
	var storage: Node = root.get_node_or_null("Storage")
	var bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if evidence == null or zones == null or storage == null or bus == null or save_load == null:
		_fail("missing autoloads (Evidence / Zones / Storage / EventBus / SaveLoad)")
		return
	if community:
		community.set_paused(true)
	Input.action_release("interact")
	save_load.clear_save()
	storage.reset_all()

	# --- 1. Restricted vs sanctioned is authored on zones with a real
	# footprint: the east Firmament band is restricted, the dig site below
	# it is not, and unmapped space belongs to no zone. ---
	if str(zones.get_zone_at(Vector2(1100, 100))) != "east_firmament" or not bool(zones.is_restricted_at(Vector2(1100, 100))):
		_fail("east_firmament footprint/restricted flag not authored (%s)" % zones.get_zone_at(Vector2(1100, 100)))
		return
	if str(zones.get_zone_at(Vector2(1500, 1000))) != "east_dig_site" or bool(zones.is_restricted_at(Vector2(1500, 1000))):
		_fail("east_dig_site should be sanctioned (%s)" % zones.get_zone_at(Vector2(1500, 1000)))
		return
	if str(zones.get_zone_at(Vector2(0, 0))) != "" or bool(zones.is_restricted_at(Vector2(0, 0))):
		_fail("unmapped space should belong to no zone")
		return
	if not bool(evidence.is_seal_kit(&"seal_kit")) or evidence.kit_tier(&"seal_kit_fine") != &"improved" or bool(evidence.is_seal_kit(&"firstfall_coupling")):
		_fail("seal-kit tiers not read from Component content")
		return
	print("PASS restricted/sanctioned is zone content; seal-kit tiers are Component content")

	# --- 2. Digging in a restricted zone flags that delta as evidence
	# (with an exposed-evidence interactable); a sanctioned dig does not. ---
	var terrain := TerrainLayer.new()
	root.add_child(terrain)
	await process_frame
	await process_frame
	terrain.reset_all()
	var events: Array = []
	bus.evidence_changed.connect(func(cell: Vector2i, tier: StringName, exists: bool) -> void: events.append({"cell": cell, "tier": tier, "exists": exists}))
	var restricted_cell := Vector2i(70, 10)
	var sanctioned_cell := Vector2i(70, 60)
	if not bool(terrain.is_restricted_dig_cell(restricted_cell)) or bool(terrain.is_restricted_dig_cell(sanctioned_cell)):
		_fail("is_restricted_dig_cell disagrees with the authored zones")
		return
	var dug: Dictionary = terrain.dig(terrain.to_global(terrain.map_to_local(restricted_cell + Vector2i.UP)), Vector2i.DOWN)
	if not bool(dug["success"]) or not bool(terrain.has_evidence(restricted_cell)):
		_fail("restricted dig did not flag evidence: %s" % [dug])
		return
	var info: Dictionary = terrain.get_evidence_info(restricted_cell)
	if info["sealed_tier"] != &"" or str(info["zone_id"]) != "east_firmament":
		_fail("evidence record wrong: %s" % [info])
		return
	var node: Node = terrain.get_evidence_node(restricted_cell)
	if node == null or not node.has_method("on_interact") or not str(node.get_interact_prompt()).contains("seal kit"):
		_fail("exposed evidence has no seal interactable / kit-less prompt (%s)" % [node.get_interact_prompt() if node else "null"])
		return
	if events.size() != 1 or events[0]["cell"] != restricted_cell or events[0]["tier"] != &"" or not bool(events[0]["exists"]):
		_fail("evidence_changed not emitted for the restricted dig: %s" % [events])
		return
	terrain.dig(terrain.to_global(terrain.map_to_local(sanctioned_cell + Vector2i.UP)), Vector2i.DOWN)
	if bool(terrain.has_evidence(sanctioned_cell)) or (terrain.get_evidence_cells() as Array).size() != 1:
		_fail("sanctioned dig flagged evidence")
		return
	# Same delta dug again (already empty) never double-flags.
	terrain.dig(terrain.to_global(terrain.map_to_local(restricted_cell + Vector2i.UP)), Vector2i.DOWN)
	if events.size() != 1:
		_fail("re-digging an empty cell re-flagged evidence")
		return
	print("PASS a restricted dig flags its delta as evidence; a sanctioned dig does not")

	# --- 3. Sealing: gated by owning a kit; a cancelled hold leaves the
	# delta exactly as it was; a completed hold consumes the kit and
	# records the tier; a sealed delta can't be sealed twice. ---
	var refused: Dictionary = evidence.seal(info["position"], &"seal_kit")
	if bool(refused["success"]) or str(refused["reason"]) != "no_kit" or bool(node.begin_seal()):
		_fail("sealing without a kit was not refused cleanly: %s" % [refused])
		return
	storage.add_component(&"seal_kit")
	var not_kit: Dictionary = evidence.seal(info["position"], &"firstfall_coupling")
	if bool(not_kit["success"]) or str(not_kit["reason"]) != "not_a_seal_kit":
		_fail("a non-kit Component was accepted as a seal: %s" % [not_kit])
		return
	if not str(node.get_interact_prompt()).contains("hold"):
		_fail("prompt should offer the hold once a kit is owned: '%s'" % node.get_interact_prompt())
		return
	Input.action_press("interact")
	node.on_interact(null)
	for _i in range(10):
		await physics_frame
	if not bool(node.is_sealing()) or float(node.get_seal_progress()) <= 0.0:
		_fail("seal hold did not progress while Interact was held")
		return
	Input.action_release("interact")
	for _i in range(3):
		await physics_frame
	if bool(node.is_sealing()) or float(node.get_seal_progress()) != 0.0:
		_fail("releasing Interact did not cancel the seal back to zero")
		return
	if terrain.get_evidence_info(restricted_cell)["sealed_tier"] != &"" or int(storage.count_components(&"seal_kit")) != 1 or terrain.get_evidence_node(restricted_cell) != node:
		_fail("a cancelled seal changed the evidence or consumed the kit")
		return
	Input.action_press("interact")
	node.on_interact(null)
	var hold_frames := int(ceil(float(node.hold_seconds()) * 60.0)) + 60
	for _i in range(hold_frames):
		await physics_frame
		if terrain.get_evidence_info(restricted_cell)["sealed_tier"] != &"":
			break
	Input.action_release("interact")
	await physics_frame
	var sealed: Dictionary = terrain.get_evidence_info(restricted_cell)
	if sealed["sealed_tier"] != &"basic" or int(storage.count_components(&"seal_kit")) != 0:
		_fail("completed seal did not record Basic tier and consume the kit: %s, kits %d" % [sealed, storage.count_components(&"seal_kit")])
		return
	await process_frame
	if terrain.get_evidence_node(restricted_cell) != null or events.size() != 2 or events[1]["tier"] != &"basic":
		_fail("sealed evidence still has its interactable / no evidence_changed for the seal: %s" % [events])
		return
	storage.add_component(&"seal_kit")
	var twice: Dictionary = evidence.seal(info["position"], &"seal_kit")
	if bool(twice["success"]) or str(twice["reason"]) != "already_sealed" or int(storage.count_components(&"seal_kit")) != 1:
		_fail("sealing an already-sealed delta was accepted or consumed a kit: %s" % [twice])
		return
	print("PASS sealing needs a kit, cancels to exactly untouched, consumes the kit on completion, and never double-seals")

	# --- 4. Searches: a search must BEAT the tier; a clean or
	# well-concealed area returns nothing; zone- and position-scoped. ---
	var second_cell := Vector2i(72, 10)
	terrain.dig(terrain.to_global(terrain.map_to_local(second_cell + Vector2i.UP)), Vector2i.DOWN)
	var basic_search: Array[Dictionary] = evidence.resolve_search("east_firmament", &"basic")
	if basic_search.size() != 1 or basic_search[0]["cell"] != second_cell:
		_fail("a Basic search should find only the exposed delta, got %s" % [basic_search])
		return
	var improved_search: Array[Dictionary] = evidence.resolve_search("east_firmament", &"improved")
	if improved_search.size() != 2:
		_fail("an Improved search should beat the Basic seal and find both, got %d" % improved_search.size())
		return
	if not (evidence.resolve_search("east_dig_site", &"advanced") as Array).is_empty():
		_fail("a search of the clean sanctioned zone found something")
		return
	var near: Array[Dictionary] = evidence.resolve_search(terrain.to_global(terrain.map_to_local(second_cell)), &"basic")
	var far: Array[Dictionary] = evidence.resolve_search(terrain.to_global(terrain.map_to_local(second_cell)) + Vector2(0, 600), &"advanced")
	if near.size() != 1 or not far.is_empty():
		_fail("position-scoped search wrong (near %d, far %d)" % [near.size(), far.size()])
		return
	# A fine kit seals at Improved; a Basic or Improved search no longer
	# finds it, an Advanced one does.
	storage.add_component(&"seal_kit_fine")
	var fine: Dictionary = evidence.seal(terrain.to_global(terrain.map_to_local(second_cell)), &"seal_kit_fine")
	if not bool(fine["success"]) or fine["tier"] != &"improved" or int(storage.count_components(&"seal_kit_fine")) != 0:
		_fail("fine kit did not seal at Improved: %s" % [fine])
		return
	var improved_after: Array[Dictionary] = evidence.resolve_search("east_firmament", &"improved")
	if improved_after.size() != 1 or improved_after[0]["cell"] != restricted_cell:
		_fail("an Improved search should still beat the Basic seal but NOT the Improved one (must strictly beat), got %s" % [improved_after])
		return
	if (evidence.resolve_search("east_firmament", &"advanced") as Array).size() != 2:
		_fail("an Advanced search should find both sealed deltas")
		return
	print("PASS a search finds exposed evidence and only sealed evidence whose tier it beats; clean areas return nothing")

	# --- 5. Secrecy Gear hook: a seal_tier_bonus effect raises the tier a
	# kit achieves (stubbed on Rig, since no authored Gear provides it yet). ---
	var rig: Node = root.get_node_or_null("Rig")
	if rig == null:
		_fail("Rig autoload missing")
		return
	if evidence.achievable_tier(&"seal_kit") != &"basic":
		_fail("achievable tier without Gear should be the kit's own")
		return
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node\nfunc get_effect_sum(id: StringName) -> float:\n\treturn 1.0 if id == &\"seal_tier_bonus\" else 0.0\n"
	stub_script.reload()
	rig.name = "Rig_real"
	var stub_rig := Node.new()
	stub_rig.name = "Rig"
	stub_rig.set_script(stub_script)
	root.add_child(stub_rig)
	var boosted: StringName = evidence.achievable_tier(&"seal_kit")
	var capped: StringName = evidence.achievable_tier(&"seal_kit_fine")
	stub_rig.queue_free()
	rig.name = "Rig"
	await process_frame
	if boosted != &"improved" or capped != &"advanced":
		_fail("seal_tier_bonus did not raise tiers (basic->%s, improved->%s)" % [boosted, capped])
		return
	print("PASS Secrecy Gear's seal_tier_bonus raises the tier a kit achieves")

	# --- 6. Evidence + tiers persist with the terrain delta through the
	# real SaveLoad path; only still-exposed evidence gets its
	# interactable back. ---
	var third_cell := Vector2i(74, 10)
	terrain.dig(terrain.to_global(terrain.map_to_local(third_cell + Vector2i.UP)), Vector2i.DOWN)
	var pre_save: Dictionary = terrain.save_state()
	if not pre_save.has("evidence") or (pre_save["evidence"] as Array).size() != 3:
		_fail("evidence not in the terrain delta save: %s" % [pre_save.get("evidence")])
		return
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	terrain.reset_all()
	await process_frame
	if not (terrain.get_evidence_cells() as Array).is_empty() or terrain.get_evidence_node(third_cell) != null:
		_fail("reset_all did not clear evidence")
		return
	if not save_load.load_game():
		_fail("load_game")
		return
	await process_frame
	if terrain.save_state() != pre_save:
		_fail("terrain delta (incl. evidence) did not round-trip:\n%s\nvs\n%s" % [pre_save, terrain.save_state()])
		return
	if terrain.get_evidence_info(restricted_cell)["sealed_tier"] != &"basic" or terrain.get_evidence_info(second_cell)["sealed_tier"] != &"improved" or terrain.get_evidence_info(third_cell)["sealed_tier"] != &"":
		_fail("tiers not restored")
		return
	if terrain.get_evidence_node(third_cell) == null or terrain.get_evidence_node(restricted_cell) != null:
		_fail("seal interactables not restored for exactly the exposed evidence")
		return
	if (evidence.resolve_search("east_firmament", &"basic") as Array).size() != 1:
		_fail("search after reload wrong")
		return
	print("PASS evidence and concealment tiers survive a save/load cycle with the terrain delta")

	Input.action_release("interact")
	save_load.clear_save()
	storage.reset_all()
	terrain.queue_free()
	await process_frame
	print("EVIDENCE_TESTS_PASSED")
	quit(0)
