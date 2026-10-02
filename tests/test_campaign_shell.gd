extends SceneTree
## Title shell + new_game reset hooks — against the current canon domains
## (Storage, Rig, Trust, Journal, District) replacing the retired
## Resources/Upgrades/Community/Districts prototype.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var save_load: Node = root.get_node_or_null("SaveLoad")
	var storage: Node = root.get_node_or_null("Storage")
	var rig: Node = root.get_node_or_null("Rig")
	var trust: Node = root.get_node_or_null("Trust")
	var journal: Node = root.get_node_or_null("Journal")
	var district: Node = root.get_node_or_null("District")
	if save_load == null or storage == null or rig == null or trust == null or journal == null or district == null:
		push_error("FAIL missing autoloads")
		quit(1)
		return

	storage.reset_all()
	rig.reset_all()
	trust.reset_all()
	journal.reset_all()
	district.reset_all()

	storage.deposit_material(&"sutral", 40)
	rig.add_owned_gear(&"load_harness")
	trust.submit_trust_event(&"test", -28.0, "campaign shell test")
	journal.unlock_record(journal.RECORD_NURSERY)
	district.request_withdrawal(&"wickwork", 2.0, {"recorded": true})
	if not save_load.save_game():
		push_error("FAIL save")
		quit(1)
		return
	if not save_load.has_save():
		push_error("FAIL has_save false")
		quit(1)
		return
	print("PASS save exists after save_game")

	save_load.new_game()
	if save_load.has_save():
		push_error("FAIL save still present after new_game")
		quit(1)
		return
	if storage.get_material_count(&"sutral") != 0:
		push_error("FAIL Materials not reset")
		quit(1)
		return
	if rig.is_owned(&"load_harness"):
		push_error("FAIL owned Gear not reset")
		quit(1)
		return
	if not is_equal_approx(float(trust.get_trust_value()), float(trust.get_default_trust())):
		push_error("FAIL trust not reset")
		quit(1)
		return
	if journal.has_record(journal.RECORD_NURSERY):
		push_error("FAIL journal not cleared")
		quit(1)
		return
	if not is_equal_approx(float(district.get_reserves(&"wickwork")), 2.0):
		push_error("FAIL district Reserves not reset to the seeded starting value")
		quit(1)
		return
	print("PASS new_game resets Act 1 state")

	var title_packed: PackedScene = load("res://title_screen.tscn")
	if title_packed == null:
		push_error("FAIL title_screen missing")
		quit(1)
		return
	var title: Node = title_packed.instantiate()
	root.add_child(title)
	await process_frame
	if title.get_node_or_null("Center/VBox/NewGameButton") == null:
		push_error("FAIL New Dig button missing")
		quit(1)
		return
	if title.get_node_or_null("Center/VBox/ContinueButton") == null:
		push_error("FAIL Continue button missing")
		quit(1)
		return
	var blurb: Label = title.get_node_or_null("Center/VBox/Blurb") as Label
	if blurb == null or not ("W/S" in blurb.text or "climb" in blurb.text.to_lower()):
		push_error("FAIL title blurb missing climb hint")
		quit(1)
		return
	if not title.has_method("has_quiet_atmosphere") or not title.has_quiet_atmosphere():
		push_error("FAIL title quiet atmosphere missing")
		quit(1)
		return
	print("PASS title screen scene loads")

	save_load.clear_save()
	storage.reset_all()
	rig.reset_all()
	trust.reset_all()
	journal.reset_all()
	district.reset_all()
	print("CAMPAIGN_SHELL_TESTS_PASSED")
	quit(0)
