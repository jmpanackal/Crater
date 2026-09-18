extends SceneTree
## Build Bible Spec 11 (Materials / Components / Records + Storage)
## acceptance tests.
##
## Not covered here, and why:
## - The PHYSICAL half of "picking up a Material in the field" — the haul
##   bundle object itself — is Spec 13 (Hauling), not built yet. This test
##   proves the conversion contract from Storage's side: two separate
##   "trips" deposited through a world access point land as one exact
##   abstract count with nothing lost. Spec 13's own tests re-prove it from
##   the bundle side once the bundle exists.
## - Records: Spec 11 says they're owned by the Journal/Capability Web and
##   not duplicated in Storage, so there's nothing of theirs to test here
##   (journal.gd's existing tests cover Record unlocking).

const StorageAccessScript := preload("res://storage_access.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage: Node = root.get_node_or_null("Storage")
	var event_bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if storage == null or event_bus == null or save_load == null:
		push_error("FAIL missing autoloads (Storage / EventBus / SaveLoad)")
		quit(1)
		return
	storage.reset_all()

	# --- 1. The locked Act 1 roster is loaded from content, and a retired
	# name is unknown — deposits of it fail cleanly with no mutation. ---
	var expected_ids: Array[StringName] = [&"sutral", &"ravelstone", &"brinecrystal", &"verdigris", &"hullbit"]
	for id: StringName in expected_ids:
		if not bool(storage.is_known_material(id)):
			push_error("FAIL locked Material '%s' not loaded from content/materials/" % id)
			quit(1)
			return
	if bool(storage.is_known_material(&"sporemeal")) or bool(storage.deposit_material(&"sporemeal", 5)):
		push_error("FAIL retired Material name 'sporemeal' was accepted")
		quit(1)
		return
	if bool(storage.deposit_material(&"sutral", 0)) or bool(storage.deposit_material(&"sutral", -2)):
		push_error("FAIL non-positive deposit was accepted")
		quit(1)
		return
	if not (storage.get_materials_snapshot() as Dictionary).is_empty():
		push_error("FAIL refused deposits mutated storage: %s" % [storage.get_materials_snapshot()])
		quit(1)
		return
	if str(storage.get_material_display_name(&"ravelstone")) != "Ravelstone":
		push_error("FAIL display_name did not load from content")
		quit(1)
		return
	print("PASS locked Material roster loads from content; retired names and bad amounts are refused with no mutation")

	# --- 2. Two world access points at different residences are the SAME
	# unified pool (Spec 11, option A) — storage is identical whether opened
	# from the Lower home or a later residence. ---
	var lower_access: Area2D = StorageAccessScript.new()
	lower_access.residence_id = &"lower"
	root.add_child(lower_access)
	var later_access: Area2D = StorageAccessScript.new()
	later_access.residence_id = &"mid_reach"
	root.add_child(later_access)
	await process_frame
	var via_lower: Node = lower_access.get_storage()
	var via_later: Node = later_access.get_storage()
	if via_lower == null or via_lower != storage or via_later != storage:
		push_error("FAIL access points did not resolve to the one Storage autoload")
		quit(1)
		return
	if str(lower_access.get_interact_prompt()) == "":
		push_error("FAIL access point has no interact prompt (Spec 10 contract)")
		quit(1)
		return
	var opened_with: Array = []
	lower_access.opened.connect(func(rid: StringName, s: Node) -> void: opened_with.append([rid, s]))
	lower_access.on_interact(null)
	if opened_with.size() != 1 or opened_with[0][0] != &"lower" or opened_with[0][1] != storage:
		push_error("FAIL on_interact did not hand over the unified pool")
		quit(1)
		return
	print("PASS access points at different residences open the same unified pool")

	# --- 3. Field pickup -> store at home converts a haul into an abstract
	# count with no data loss: two separate trips (3, then 2) through
	# different access points total exactly 5. ---
	var events: Array = []
	var listener := func(kind: StringName, id: StringName, new_count: int) -> void:
		events.append({"kind": kind, "id": id, "count": new_count})
	event_bus.storage_changed.connect(listener)
	if not bool(via_lower.deposit_material(&"ravelstone", 3)):
		push_error("FAIL first haul deposit refused")
		quit(1)
		return
	if not bool(via_later.deposit_material(&"ravelstone", 2)):
		push_error("FAIL second haul deposit refused")
		quit(1)
		return
	if int(storage.get_material_count(&"ravelstone")) != 5:
		push_error("FAIL 3 + 2 hauled did not store as exactly 5 (got %d)" % storage.get_material_count(&"ravelstone"))
		quit(1)
		return
	if int(lower_access.get_storage().get_material_count(&"ravelstone")) != int(later_access.get_storage().get_material_count(&"ravelstone")):
		push_error("FAIL count differs between residences")
		quit(1)
		return
	if events.size() != 2 or int(events[0]["count"]) != 3 or int(events[1]["count"]) != 5 or events[1]["kind"] != &"material":
		push_error("FAIL storage_changed did not fire once per deposit with the new total: %s" % [events])
		quit(1)
		return
	print("PASS two hauls deposited from different residences store as one exact abstract count, one event each")

	# --- 4. A job expecting "5 Ravelstone" resolves against current totals
	# regardless of which trips the Materials came from — and against
	# totals at the moment of the check, not a reserved allocation. ---
	if not bool(storage.has_materials(&"ravelstone", 5)):
		push_error("FAIL job requirement of 5 not satisfied by 3 + 2")
		quit(1)
		return
	# Two independent jobs each expecting 5 both see it satisfied until one
	# actually withdraws (Spec 11's own edge-case rule: no locking).
	var job_a_ok: bool = bool(storage.has_materials(&"ravelstone", 5))
	var job_b_ok: bool = bool(storage.has_materials(&"ravelstone", 5))
	if not job_a_ok or not job_b_ok:
		push_error("FAIL totals were treated as reserved between two checks")
		quit(1)
		return
	if not bool(storage.withdraw_material(&"ravelstone", 5)):
		push_error("FAIL delivery withdrawal of 5 refused")
		quit(1)
		return
	if bool(storage.has_materials(&"ravelstone", 5)) or bool(storage.withdraw_material(&"ravelstone", 5)):
		push_error("FAIL second delivery still resolved after the pool was emptied")
		quit(1)
		return
	if int(storage.get_material_count(&"ravelstone")) != 0 or (storage.get_materials_snapshot() as Dictionary).has("ravelstone"):
		push_error("FAIL withdrawal did not settle to exactly zero / a partial withdrawal happened")
		quit(1)
		return
	if bool(storage.withdraw_material(&"sutral", 1)):
		push_error("FAIL withdrawing from an empty Material succeeded")
		quit(1)
		return
	print("PASS a job expecting 5 Ravelstone resolves on current totals, not reservations; withdrawals are all-or-nothing")

	# --- 5. Components: per-instance identity in the same unified pool. ---
	if bool(storage.is_known_component(&"no_such_part")) or int(storage.add_component(&"no_such_part")) != -1:
		push_error("FAIL unknown Component id was accepted")
		quit(1)
		return
	var uid_a: int = int(storage.add_component(&"firstfall_coupling", {"condition": "corroded"}))
	var uid_b: int = int(storage.add_component(&"firstfall_coupling"))
	if uid_a < 1 or uid_b != uid_a + 1:
		push_error("FAIL Component uids not stable/sequential: %d, %d" % [uid_a, uid_b])
		quit(1)
		return
	if int(storage.count_components(&"firstfall_coupling")) != 2 or not bool(storage.has_component(&"firstfall_coupling")):
		push_error("FAIL Component count wrong")
		quit(1)
		return
	var owned: Array[Dictionary] = storage.get_components(&"firstfall_coupling")
	if owned.size() != 2 or str((owned[0]["data"] as Dictionary).get("condition", "")) != "corroded":
		push_error("FAIL per-instance data not kept: %s" % [owned])
		quit(1)
		return
	# Returned instances are copies — editing one must not reach the owner.
	(owned[0]["data"] as Dictionary)["condition"] = "pristine"
	var reread: Array[Dictionary] = storage.get_components(&"firstfall_coupling")
	if str((reread[0]["data"] as Dictionary).get("condition", "")) != "corroded":
		push_error("FAIL get_components handed out a live reference, not a copy")
		quit(1)
		return
	if not bool(storage.remove_component(uid_a)) or bool(storage.remove_component(uid_a)):
		push_error("FAIL remove_component by uid did not work exactly once")
		quit(1)
		return
	if int(storage.count_components(&"firstfall_coupling")) != 1:
		push_error("FAIL count after removal wrong")
		quit(1)
		return
	print("PASS Components keep per-instance identity and data in the unified pool")

	# --- 6. Persistence through the real SaveLoad system (register-by-name
	# autoload domain), including the Component uid counter continuing past
	# loaded instances. ---
	storage.deposit_material(&"sutral", 4)
	var pre_save: Dictionary = storage.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		push_error("FAIL save_game")
		quit(1)
		return
	storage.reset_all()
	if int(storage.get_material_count(&"sutral")) != 0 or int(storage.count_components(&"firstfall_coupling")) != 0:
		push_error("FAIL reset_all did not clear before the reload check")
		quit(1)
		return
	if not save_load.load_game():
		push_error("FAIL load_game")
		quit(1)
		return
	var post_load: Dictionary = storage.save_state()
	if post_load != pre_save:
		push_error("FAIL Storage did not round-trip through SaveLoad:\n%s\nvs\n%s" % [pre_save, post_load])
		quit(1)
		return
	var uid_c: int = int(storage.add_component(&"firstfall_coupling"))
	if uid_c <= uid_b:
		push_error("FAIL uid counter did not continue past loaded instances (%d after %d)" % [uid_c, uid_b])
		quit(1)
		return
	print("PASS Materials and Components persist through a real save/load round-trip")

	event_bus.storage_changed.disconnect(listener)
	save_load.clear_save()
	storage.reset_all()
	lower_access.queue_free()
	later_access.queue_free()
	print("STORAGE_TESTS_PASSED")
	quit(0)
