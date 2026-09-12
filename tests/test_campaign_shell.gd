extends SceneTree
## Title shell + new_game reset hooks.


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await process_frame

	var save_load: Node = root.get_node_or_null("SaveLoad")
	var wallet: Node = root.get_node_or_null("Resources")
	var upgrades: Node = root.get_node_or_null("Upgrades")
	var community: Node = root.get_node_or_null("Community")
	var journal: Node = root.get_node_or_null("Journal")
	var districts: Node = root.get_node_or_null("Districts")
	if save_load == null:
		push_error("FAIL SaveLoad missing")
		quit(1)
		return

	community.set_paused(true)
	wallet.set_amount(wallet.SALVAGE, 40)
	upgrades.set_level(upgrades.DIG_YIELD, 2)
	community.set_social_standing(22)
	community.set_pending_lie(true)
	journal.unlock_record(journal.RECORD_NURSERY)
	districts.set_stock(districts.FARMS, 9.0)
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
	if wallet.get_amount(wallet.SALVAGE) != 0:
		push_error("FAIL salvage not reset")
		quit(1)
		return
	if upgrades.get_level(upgrades.DIG_YIELD) != 0:
		push_error("FAIL upgrades not reset")
		quit(1)
		return
	if community.get_social_standing() != community.SOCIAL_STANDING_DEFAULT:
		push_error("FAIL standing not reset")
		quit(1)
		return
	if community.has_pending_lie():
		push_error("FAIL pending lie not cleared")
		quit(1)
		return
	if journal.has_record(journal.RECORD_NURSERY):
		push_error("FAIL journal not cleared")
		quit(1)
		return
	if districts.get_good_amount(districts.GLOWRATIONS) != districts.PROTECTED_RESERVE:
		push_error("FAIL district production not reset to reserve")
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

	print("CAMPAIGN_SHELL_TESTS_PASSED")
	quit(0)
