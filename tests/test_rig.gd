extends SceneTree
## Build Bible Spec 14 (Rig + Gear + Capacity / Strain) acceptance tests.
##
## Not covered here, and why:
## - What Gear COSTS to acquire (Tallies + District Output for Approved,
##   the diverted-output + Component + Material + Record recipe for grafts)
##   — Specs 23/28 own that and call add_owned_gear()/graft() afterwards.
## - The residence tier itself — Spec 27 (Homes) owns it; this test stands
##   in a stub "Homes" node to prove Rig reads it, and proves the fail-safe
##   (no Homes = Lower home = grafting refused) without one.
## - The refit UI — nothing here assumes a presentation; the station's
##   `opened` signal is the hook.
## - Terrain's quiet-dig and the player's dig-cost reads of Rig effects are
##   fail-safe one-line reads of get_effect_sum(); dig stamina cost is still
##   the untuned 0.0, so a numeric check there would assert nothing real.

const RigStationScript := preload("res://rig_station.gd")

const TEMP_GEAR_PATH := "res://content/gear/zz_test_temp_gear.tres"
const TEMP_GEAR_TEXT := """[gd_resource type="Resource" script_class="" load_steps=2 format=3]

[ext_resource type="Script" path="res://content/gear_definition.gd" id="1"]

[resource]
script = ExtResource("1")
gear_id = &"zz_test_temp_gear"
display_name = "Temp test Gear"
kind = &"approved"
capacity_cost = 1
effects = {
"quiet_dig_level": 7.0
}
"""

var _body: CharacterBody2D


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _move_body_to(pos: Vector2) -> void:
	_body.global_position = pos
	for _i in range(3):
		await physics_frame


func _run() -> void:
	var rig: Node = root.get_node_or_null("Rig")
	var stamina: Node = root.get_node_or_null("Stamina")
	var hauling: Node = root.get_node_or_null("Hauling")
	var storage: Node = root.get_node_or_null("Storage")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var console: Node = root.get_node_or_null("DebugConsole")
	var community: Node = root.get_node_or_null("Community")
	if rig == null or stamina == null or hauling == null or storage == null or save_load == null or console == null:
		_fail("missing autoloads (Rig / Stamina / Hauling / Storage / SaveLoad / DebugConsole)")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	rig.reset_all()
	hauling.reset_all()
	storage.reset_all()
	stamina.reset_all()

	# --- 1. Gear and Core Improvements are Content Definitions: the authored
	# roster loads, unknown ids are refused, and a brand-new .tres dropped
	# into content/gear/ is picked up with no script edit (Spec 01's own
	# acceptance test for Content Definitions names Gear specifically). ---
	for id: StringName in [&"load_harness", &"counterweight_frame", &"fracture_pick", &"dampening_wrap", &"quieting_coupler"]:
		if not bool(rig.is_known_gear(id)):
			_fail("authored Gear '%s' not loaded from content/gear/" % id)
			return
	if rig.get_gear_kind(&"quieting_coupler") != &"graft" or rig.get_gear_kind(&"load_harness") != &"approved":
		_fail("Gear kinds did not load from content")
		return
	if int(rig.get_gear_capacity_cost(&"counterweight_frame")) != 3 or str(rig.get_gear_display_name(&"dampening_wrap")) != "Dampening Wrap":
		_fail("Gear capacity_cost/display_name did not load from content")
		return
	if bool(rig.is_known_gear(&"pressure_bore")) or bool(rig.add_owned_gear(&"pressure_bore")):
		_fail("an unauthored Gear id was accepted")
		return
	for id: StringName in [&"harness_reinforcement", &"second_mount_rail"]:
		if not bool(rig.is_known_core_improvement(id)):
			_fail("authored Core Improvement '%s' not loaded" % id)
			return
	var temp := FileAccess.open(TEMP_GEAR_PATH, FileAccess.WRITE)
	if temp == null:
		_fail("could not write temp Gear file for the no-script-edit check")
		return
	temp.store_string(TEMP_GEAR_TEXT)
	temp.close()
	rig.reload_definitions()
	var picked_up: bool = bool(rig.is_known_gear(&"zz_test_temp_gear"))
	var temp_info: Dictionary = rig.get_gear_info(&"zz_test_temp_gear")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_GEAR_PATH))
	rig.reload_definitions()
	if not picked_up or float((temp_info.get("effects", {}) as Dictionary).get(&"quiet_dig_level", 0.0)) != 7.0:
		_fail("a new Gear .tres was not picked up by reload_definitions() (%s / %s)" % [picked_up, temp_info])
		return
	if bool(rig.is_known_gear(&"zz_test_temp_gear")):
		_fail("temp Gear file still known after removal — cleanup failed")
		return
	print("PASS Gear + Core Improvements load from content; unknown ids refused; a new .tres is picked up with no script edit")

	# --- 2. Station restriction is enforced by the system, not the UI:
	# every path (direct call, debug console) refuses away from a station,
	# and "at a station" is real physics overlap with the player body. ---
	_body = CharacterBody2D.new()
	_body.name = "Player"
	_body.add_to_group("player")
	_body.collision_layer = 1
	_body.collision_mask = 0
	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 32)
	body_shape.shape = rect
	_body.add_child(body_shape)
	root.add_child(_body)
	var home: Area2D = RigStationScript.new()
	home.name = "HomeStation"
	home.station_kind = &"home"
	home.position = Vector2(0, 0)
	root.add_child(home)
	var workspace: Area2D = RigStationScript.new()
	workspace.name = "WorkspaceStation"
	workspace.station_kind = &"workspace"
	workspace.position = Vector2(400, 0)
	root.add_child(workspace)
	await _move_body_to(Vector2(2000, 2000))
	if bool(rig.can_equip_at_current_location()):
		_fail("can_equip_at_current_location() true with no station in range")
		return
	rig.add_owned_gear(&"load_harness")
	var away: Dictionary = rig.equip(&"load_harness", 0)
	if bool(away["success"]) or str(away["reason"]) != "not_at_station":
		_fail("equip away from a station was not refused with not_at_station: %s" % [away])
		return
	var away_un: Dictionary = rig.unequip(0)
	if bool(away_un["success"]) or str(away_un["reason"]) != "not_at_station":
		_fail("unequip away from a station was not refused: %s" % [away_un])
		return
	var away_core: Dictionary = rig.install_core_improvement(&"second_mount_rail")
	if bool(away_core["success"]) or str(away_core["reason"]) != "not_at_station":
		_fail("Core Improvement install away from a station was not refused: %s" % [away_core])
		return
	var console_away: String = console.execute("equip load_harness 0")
	if not console_away.contains("not_at_station") or (rig.get_equipped() as Array).has(&"load_harness"):
		_fail("debug console bypassed the station rule: '%s'" % console_away)
		return
	if str(home.get_interact_prompt()) == "" or str(workspace.get_interact_prompt()) == "":
		_fail("station has no interact prompt (Spec 10 contract)")
		return
	await _move_body_to(home.position)
	if not bool(rig.can_equip_at_current_location()):
		_fail("standing inside the home station's area did not count as being at a station")
		return
	var unowned: Dictionary = rig.equip(&"counterweight_frame", 0)
	if bool(unowned["success"]) or str(unowned["reason"]) != "not_owned":
		_fail("equipping unowned Gear was accepted: %s" % [unowned])
		return
	var ok: Dictionary = rig.equip(&"load_harness", 0)
	if not bool(ok["success"]) or rig.get_equipped_in_slot(0) != &"load_harness":
		_fail("equip at the home station failed: %s" % [ok])
		return
	var twice: Dictionary = rig.equip(&"load_harness", 1)
	var bad_slot: Dictionary = rig.equip(&"load_harness", 99)
	rig.add_owned_gear(&"dampening_wrap")
	var occupied: Dictionary = rig.equip(&"dampening_wrap", 0)
	var graft_in_slot: Dictionary = rig.equip(&"quieting_coupler", 1)
	if bool(twice["success"]) or str(twice["reason"]) != "already_equipped" \
			or bool(bad_slot["success"]) or str(bad_slot["reason"]) != "no_such_slot" \
			or bool(occupied["success"]) or str(occupied["reason"]) != "slot_occupied" \
			or bool(graft_in_slot["success"]) or str(graft_in_slot["reason"]) != "grafts_do_not_use_slots":
		_fail("equip edge cases wrong: %s %s %s %s" % [twice, bad_slot, occupied, graft_in_slot])
		return
	await _move_body_to(Vector2(2000, 2000))
	var left: Dictionary = rig.unequip(0)
	if bool(left["success"]) or rig.get_equipped_in_slot(0) != &"load_harness":
		_fail("walking away from the station did not re-close refits: %s" % [left])
		return
	await _move_body_to(home.position)
	var cleared: Dictionary = rig.unequip(0)
	if not bool(cleared["success"]) or rig.get_equipped_in_slot(0) != &"":
		_fail("unequip at the station failed: %s" % [cleared])
		return
	var empty: Dictionary = rig.unequip(0)
	if bool(empty["success"]) or str(empty["reason"]) != "slot_empty":
		_fail("unequip of an empty slot not refused cleanly: %s" % [empty])
		return
	print("PASS equip/unequip refuse away from a station on every path; real body overlap is what opens them")

	# --- 3. Capacity is a soft limit: equipping beyond it SUCCEEDS and
	# creates a rig_strain block scaled by overcapacity, independent of the
	# hauling block; dropping back under releases exactly rig_strain. ---
	var capacity: int = int(rig.get_capacity())
	var per_point: float = float(rig.get_strain_block_per_overcapacity())
	if capacity != int(rig.get_base_capacity()) or int(rig.get_slot_count()) != int(rig.get_base_slots()) or capacity < 3:
		_fail("fresh Rig should be at tuned base slots/capacity (got %d slots, %d capacity)" % [rig.get_slot_count(), capacity])
		return
	stamina.request_block(stamina.SOURCE_HAULING, 5.0)
	rig.add_owned_gear(&"counterweight_frame")
	rig.add_owned_gear(&"fracture_pick")
	rig.equip(&"counterweight_frame", 0)  # cost 3 = exactly base capacity
	if int(rig.get_overcapacity()) != 0 or float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)) != 0.0:
		_fail("filling capacity exactly should create no strain (over %d, block %s)" % [rig.get_overcapacity(), stamina.get_block(stamina.SOURCE_RIG_STRAIN)])
		return
	var over1: Dictionary = rig.equip(&"load_harness", 1)  # +1 -> over by 1
	if not bool(over1["success"]):
		_fail("equipping beyond capacity was refused — it must succeed as a soft limit: %s" % [over1])
		return
	if int(rig.get_overcapacity()) != 1 or not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), per_point):
		_fail("1 over capacity should block %s via rig_strain, got %s" % [per_point, stamina.get_block(stamina.SOURCE_RIG_STRAIN)])
		return
	rig.equip(&"fracture_pick", 2)  # +1 -> over by 2: greater overcapacity, greater strain
	if int(rig.get_overcapacity()) != 2 or not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), 2.0 * per_point):
		_fail("2 over capacity should block %s, got %s" % [2.0 * per_point, stamina.get_block(stamina.SOURCE_RIG_STRAIN)])
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 5.0):
		_fail("rig strain disturbed the hauling block")
		return
	if not is_equal_approx(float(stamina.get_available_max()), float(stamina.get_max_stamina()) - 5.0 - 2.0 * per_point):
		_fail("available max should reflect both blocks summed")
		return
	rig.unequip(1)
	rig.unequip(2)
	if float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)) != 0.0 or not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 5.0):
		_fail("dropping under capacity did not release exactly the rig_strain block")
		return
	stamina.release_block(stamina.SOURCE_HAULING)
	print("PASS over-capacity equips succeed and create a rig_strain block that scales and releases independently of hauling")

	# --- 4. Grafts: refused away from the workspace, refused below Mid
	# Reach, then install using NO slot and drawing only Capacity. ---
	var at_home: Dictionary = rig.graft(&"quieting_coupler")
	if bool(at_home["success"]) or str(at_home["reason"]) != "not_at_workspace":
		_fail("graft at a plain home station was not refused with not_at_workspace: %s" % [at_home])
		return
	await _move_body_to(workspace.position)
	if not bool(rig.can_equip_at_current_location()):
		_fail("workspace station should also count as a station for ordinary refits")
		return
	var lower: Dictionary = rig.graft(&"quieting_coupler")
	if bool(lower["success"]) or str(lower["reason"]) != "residence_tier_too_low" or rig.get_residence_tier() != &"lower":
		_fail("graft before Mid Reach (no Homes = Lower home) was not refused cleanly: %s" % [lower])
		return
	var homes_script := GDScript.new()
	homes_script.source_code = "extends Node\nfunc get_residence_tier() -> StringName:\n\treturn &\"mid_reach\"\n"
	homes_script.reload()
	var homes := Node.new()
	homes.name = "Homes"
	homes.set_script(homes_script)
	root.add_child(homes)
	if rig.get_residence_tier() != &"mid_reach":
		_fail("Rig did not read the residence tier from Homes")
		return
	var not_graft: Dictionary = rig.graft(&"dampening_wrap")
	if bool(not_graft["success"]) or str(not_graft["reason"]) != "not_a_graft":
		_fail("grafting an Approved worn item was accepted: %s" % [not_graft])
		return
	var slots_before: Array = rig.get_equipped()
	var used_before: int = int(rig.get_capacity_used())
	var grafted: Dictionary = rig.graft(&"quieting_coupler")
	if not bool(grafted["success"]) or not bool(rig.is_grafted(&"quieting_coupler")):
		_fail("graft at a Mid Reach workspace failed: %s" % [grafted])
		return
	if (rig.get_equipped() as Array) != slots_before or (rig.get_equipped() as Array).has(&"quieting_coupler"):
		_fail("a graft took a Gear slot")
		return
	if int(rig.get_capacity_used()) != used_before + int(rig.get_gear_capacity_cost(&"quieting_coupler")):
		_fail("graft did not draw its capacity cost from the shared pool")
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), float(rig.get_overcapacity()) * per_point):
		_fail("graft overcapacity did not follow the same strain rule")
		return
	if not is_equal_approx(float(rig.get_effect_sum(&"quiet_dig_level")), 2.0):
		_fail("graft effect not counted in get_effect_sum")
		return
	var again: Dictionary = rig.graft(&"quieting_coupler")
	if bool(again["success"]) or str(again["reason"]) != "already_grafted":
		_fail("double graft not refused: %s" % [again])
		return
	await _move_body_to(home.position)
	var remove_away: Dictionary = rig.remove_graft(&"quieting_coupler")
	if bool(remove_away["success"]) or str(remove_away["reason"]) != "not_at_workspace":
		_fail("graft removal away from the workspace was accepted: %s" % [remove_away])
		return
	await _move_body_to(workspace.position)
	var removed: Dictionary = rig.remove_graft(&"quieting_coupler")
	if not bool(removed["success"]) or bool(rig.is_grafted(&"quieting_coupler")) or int(rig.get_capacity_used()) != used_before:
		_fail("graft removal at the workspace failed: %s" % [removed])
		return
	print("PASS grafts refuse away from the workspace and before Mid Reach; install with no slot, drawing only Capacity")

	# --- 5. Gear effects reach their consumers: Hauling-dimension Gear
	# raises the bundle capacity and softens the hauling block, and a load
	# already in tow is re-derived when the Rig changes. ---
	rig.unequip(0)  # counterweight_frame off -> base capacity again
	var base_bundle: int = int(hauling.get_bundle_capacity())
	var base_per_unit: float = float(hauling.get_block_per_unit())
	if not bool(hauling.attach(&"sutral", 2)):
		_fail("attach 2 sutral refused")
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 2.0 * base_per_unit):
		_fail("baseline hauling block wrong")
		return
	rig.equip(&"counterweight_frame", 0)
	if int(hauling.get_bundle_capacity()) != base_bundle + 2:
		_fail("Counterweight Frame did not raise the bundle capacity (%d -> %d)" % [base_bundle, hauling.get_bundle_capacity()])
		return
	if not bool(hauling.can_attach(&"sutral", base_bundle)):
		_fail("raised bundle capacity not honored by can_attach")
		return
	rig.equip(&"load_harness", 1)
	var reduced_per_unit: float = float(hauling.get_block_per_unit())
	if not is_equal_approx(reduced_per_unit, base_per_unit * 0.65):
		_fail("Load Harness should soften the block per unit by 35%% (%s -> %s)" % [base_per_unit, reduced_per_unit])
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 2.0 * reduced_per_unit):
		_fail("hauling block on the towed load was not re-derived after the Rig changed: %s" % stamina.get_block(stamina.SOURCE_HAULING))
		return
	rig.unequip(1)
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_HAULING)), 2.0 * base_per_unit):
		_fail("hauling block did not return to baseline after unequipping the harness")
		return
	rig.equip(&"dampening_wrap", 1)
	if not is_equal_approx(float(rig.get_effect_sum(&"quiet_dig_level")), 1.0) or not is_equal_approx(float(rig.get_effect_sum(&"no_such_effect")), 0.0):
		_fail("effect sums wrong")
		return
	hauling.deposit_at_storage()
	print("PASS Hauling-dimension Gear raises bundle capacity and softens the hauling block, re-derived live")

	# --- 6. Core Improvements: permanent, slot-less, raise slots/capacity. ---
	var slots_now: int = int(rig.get_slot_count())
	var strain_before: float = float(stamina.get_block(stamina.SOURCE_RIG_STRAIN))
	var core_slot: Dictionary = rig.install_core_improvement(&"second_mount_rail")
	if not bool(core_slot["success"]) or int(rig.get_slot_count()) != slots_now + 1 or (rig.get_equipped() as Array).size() != slots_now + 1:
		_fail("Second Mount Rail did not add a slot: %s" % [core_slot])
		return
	var core_cap: Dictionary = rig.install_core_improvement(&"harness_reinforcement")
	if not bool(core_cap["success"]) or int(rig.get_capacity()) != capacity + 2:
		_fail("Harness Reinforcement did not raise capacity: %s" % [core_cap])
		return
	if float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)) > strain_before:
		_fail("raising capacity increased strain")
		return
	var core_again: Dictionary = rig.install_core_improvement(&"harness_reinforcement")
	if bool(core_again["success"]) or str(core_again["reason"]) != "already_installed":
		_fail("double Core Improvement install not refused: %s" % [core_again])
		return
	if (rig.get_equipped() as Array).has(&"harness_reinforcement"):
		_fail("a Core Improvement consumed a Gear slot")
		return
	print("PASS Core Improvements add slots/capacity permanently without using a slot")

	# --- 7. Persistence through the real SaveLoad path; strain re-derived
	# on load; stations-in-range is live physical state, never saved. ---
	rig.equip(&"fracture_pick", 3)
	rig.graft(&"quieting_coupler")
	var pre_save: Dictionary = rig.save_state()
	var strain_pre: float = float(stamina.get_block(stamina.SOURCE_RIG_STRAIN))
	if not pre_save.has("slots") or pre_save.has("stations"):
		_fail("save_state shape wrong: %s" % [pre_save])
		return
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	rig.reset_all()
	if int(rig.get_capacity_used()) != 0 or float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)) != 0.0 or int(rig.get_slot_count()) != int(rig.get_base_slots()):
		_fail("reset_all did not clear the Rig / release strain")
		return
	if not save_load.load_game():
		_fail("load_game")
		return
	var post_load: Dictionary = rig.save_state()
	if post_load != pre_save:
		_fail("Rig did not round-trip through SaveLoad:\n%s\nvs\n%s" % [pre_save, post_load])
		return
	if not is_equal_approx(float(stamina.get_block(stamina.SOURCE_RIG_STRAIN)), strain_pre):
		_fail("rig_strain block not re-derived on load (%s vs %s)" % [stamina.get_block(stamina.SOURCE_RIG_STRAIN), strain_pre])
		return
	if not bool(rig.is_grafted(&"quieting_coupler")) or rig.get_equipped_in_slot(3) != &"fracture_pick" or int(rig.get_slot_count()) != slots_now + 1:
		_fail("loaded Rig state incomplete")
		return
	print("PASS Rig persists through a real save/load round-trip with strain re-derived")

	save_load.clear_save()
	rig.reset_all()
	hauling.reset_all()
	storage.reset_all()
	stamina.reset_all()
	homes.queue_free()
	home.queue_free()
	workspace.queue_free()
	_body.queue_free()
	await process_frame
	print("RIG_TESTS_PASSED")
	quit(0)
