extends SceneTree
## Build Bible Spec 24 (Jobs + Commitments) acceptance tests.
##
## Not covered here, and why:
## - The dispatcher/foreman NPC dialogue that OFFERS the opening job in
##   the world — authored content for the play scene; the contract it
##   calls (offer/accept) is driven directly.
## - Personal NPC Request content — none authored for the thin slice;
##   the type shares the no-promise path tested for Available Work.
## - Presentation (notes / work records) — UI.

const DeliveryPointScript := preload("res://job_delivery_point.gd")


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var jobs: Node = root.get_node_or_null("Jobs")
	var wallet: Node = root.get_node_or_null("Wallet")
	var trust: Node = root.get_node_or_null("Trust")
	var hauling: Node = root.get_node_or_null("Hauling")
	var district: Node = root.get_node_or_null("District")
	var clock: Node = root.get_node_or_null("Clock")
	var bus: Node = root.get_node_or_null("EventBus")
	var console: Node = root.get_node_or_null("DebugConsole")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var stamina: Node = root.get_node_or_null("Stamina")
	var community: Node = root.get_node_or_null("Community")
	if jobs == null or wallet == null or trust == null or hauling == null or district == null or clock == null or bus == null or console == null or fact_log == null or save_load == null or stamina == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	jobs.reset_all()
	wallet.reset_all()
	trust.reset_all()
	hauling.reset_all()
	district.reset_all()
	fact_log.clear_all()
	var trust_events: Array = []
	bus.trust_changed.connect(func(standing: StringName, delta: float, reason: String) -> void: trust_events.append({"standing": standing, "delta": delta, "reason": reason}))
	var settlements: Array = []
	bus.job_settled.connect(func(job_id: StringName, record: Dictionary) -> void: settlements.append({"job_id": job_id, "record": record}))

	# --- 1. The opening job end to end: offered (Duty, Trust-tier 0),
	# accepted, Sutral hauled in a real bundle and handed to the worksite
	# collection point, settled with a grade, Tallies earned — and no
	# Trust event for ordinary completion. ---
	if (jobs.get_definition_ids() as Array) != [&"emergency_wickwork", &"open_the_gallery", &"senior_survey_run", &"spare_hands"]:
		_fail("job definitions not loaded from content: %s" % [jobs.get_definition_ids()])
		return
	var opening: StringName = jobs.offer(&"open_the_gallery")
	if opening == &"" or jobs.get_stage(opening) != &"offered" or jobs.get_deadline_status(opening) != &"open":
		_fail("opening job not offered (%s, %s)" % [opening, jobs.get_stage(opening)])
		return
	if int(jobs.progress(opening, &"sutral", 1)) != 0:
		_fail("a Duty counted progress before it was accepted")
		return
	if not bool(jobs.accept(opening)) or jobs.get_stage(opening) != &"accepted":
		_fail("accept failed")
		return
	var point: Area2D = DeliveryPointScript.new()
	point.district_id = &"wickwork"
	root.add_child(point)
	await process_frame
	# Empty-handed: nothing delivered, prompt names the job.
	point.on_interact(null)
	if int(jobs.get_job(opening)["delivered"]) != 0 or not str(point.get_interact_prompt()).contains("Open the new gallery"):
		_fail("empty-handed delivery counted / prompt wrong: '%s'" % point.get_interact_prompt())
		return
	# The wrong Material stays in the bundle.
	hauling.attach(&"ravelstone", 2)
	point.on_interact(null)
	if int(jobs.get_job(opening)["delivered"]) != 0 or not bool(hauling.is_loaded()):
		_fail("the wrong Material was delivered / taken")
		return
	hauling.reset_all()
	stamina.reset_all()
	hauling.attach(&"sutral", 2)
	point.on_interact(null)
	if int(jobs.get_job(opening)["delivered"]) != 2 or bool(hauling.is_loaded()) or float(stamina.get_block(stamina.SOURCE_HAULING)) != 0.0:
		_fail("delivering the bundle did not count it / release the haul (delivered %d, loaded %s)" % [int(jobs.get_job(opening)["delivered"]), hauling.is_loaded()])
		return
	if jobs.get_stage(opening) != &"in_progress":
		_fail("stage should be in_progress after a delivery")
		return
	hauling.attach(&"sutral", 1)
	point.on_interact(null)
	var record: Dictionary = jobs.settle(opening)
	if record.is_empty() or record["outcome"] != &"strong" or int(record["tallies"]) != int(jobs.get_pay(opening)) or int(wallet.get_balance()) != int(jobs.get_pay(opening)):
		_fail("settlement of the completed opening job wrong: %s (balance %d)" % [record, wallet.get_balance()])
		return
	if not trust_events.is_empty() or settlements.size() != 1 or (fact_log.get_by_type(&"job_settled") as Array).size() != 1:
		_fail("ordinary completion should pay Tallies with no Trust event, one settlement: %s" % [trust_events])
		return
	if jobs.get_stage(opening) != &"settled" or not (jobs.settle(opening) as Dictionary).is_empty():
		_fail("a settled job settled twice")
		return
	print("PASS the opening job runs end to end: offer, accept, haul + deliver, settle with a grade, Tallies, no Trust event")

	# --- 2. Abandoning an accepted job before its deadline settles as a
	# broken commitment with exactly one Trust event. ---
	trust_events.clear()
	var second: StringName = jobs.offer(&"open_the_gallery")
	jobs.accept(second)
	var broken: Dictionary = jobs.abandon(second)
	if broken["outcome"] != &"broken_commitment" or trust_events.size() != 1 or float(trust_events[0]["delta"]) >= 0.0 or int(broken["tallies"]) != 0:
		_fail("abandoning an accepted Duty should be one negative Trust event: %s %s" % [broken, trust_events])
		return
	print("PASS abandoning an accepted job settles as a broken commitment with exactly one Trust event")

	# --- 3. A higher-tier job is never offered below its Trust standing,
	# pays more on success, and costs more Trust when broken. ---
	trust_events.clear()
	trust.reset_all()  # default standing: accepted
	if jobs.offer(&"senior_survey_run") != &"":
		_fail("a job above the player's Trust standing was offered")
		return
	trust.submit_trust_event(&"major_accomplishment", 30.0, "Opened the gallery ahead of schedule")  # -> relied_on
	trust_events.clear()
	var senior: StringName = jobs.offer(&"senior_survey_run")
	if senior == &"":
		_fail("higher-tier job should be offered once the standing is met (%s)" % trust.get_trust())
		return
	if int(jobs.get_pay(senior)) <= int(jobs.get_pay(&"open_the_gallery")):
		_fail("higher tier should pay more (%d vs %d)" % [jobs.get_pay(senior), jobs.get_pay(&"open_the_gallery")])
		return
	jobs.accept(senior)
	var senior_broken: Dictionary = jobs.abandon(senior)
	var routine_delta: float = float(jobs.get_broken_commitment_delta(&"open_the_gallery"))
	if trust_events.size() != 1 or float(senior_broken["trust_delta"]) >= routine_delta:
		_fail("breaking a higher-tier commitment should cost more Trust (%s vs routine %s)" % [senior_broken["trust_delta"], routine_delta])
		return
	# Completing a higher-tier job pays its higher rate.
	trust.submit_trust_event(&"major_accomplishment", 30.0, "Still trusted")
	var senior2: StringName = jobs.offer(&"senior_survey_run")
	jobs.accept(senior2)
	wallet.reset_all()
	jobs.progress(senior2, &"ravelstone", 2)
	var senior_done: Dictionary = jobs.settle(senior2)
	if senior_done["outcome"] != &"strong" or int(wallet.get_balance()) != int(jobs.get_pay(senior2)) or int(wallet.get_balance()) <= int(jobs.get_pay(&"open_the_gallery")):
		_fail("higher-tier completion pay wrong: %s balance %d" % [senior_done, wallet.get_balance()])
		return
	print("PASS Trust tier gates offers; higher tiers pay more and cost more when broken")

	# --- 4. Ignoring Available Work: no acceptance stage, no settlement
	# events, no Trust — even when its (non-)deadline never comes; and an
	# exceptional outcome earns a positive Trust event on any type. ---
	trust_events.clear()
	settlements.clear()
	var spare: StringName = jobs.offer(&"spare_hands")
	if bool(jobs.accept(spare)):
		_fail("Available Work must not have an Accepted stage")
		return
	console.execute("force_advance 8")  # two full cycles pass; deadline_shape none
	if jobs.get_stage(spare) != &"offered" or not settlements.is_empty() or not trust_events.is_empty():
		_fail("ignored Available Work produced a settlement/Trust event: %s %s" % [settlements, trust_events])
		return
	# Doing far more than asked on it is above-and-beyond: +Trust.
	jobs.progress(spare, &"brinecrystal", 2)  # required 1 -> ratio 2.0
	var exceptional: Dictionary = jobs.settle(spare)
	if exceptional["outcome"] != &"exceptional" or trust_events.size() != 1 or float(trust_events[0]["delta"]) <= 0.0:
		_fail("an exceptional outcome should be one positive Trust event: %s %s" % [exceptional, trust_events])
		return
	print("PASS ignored Available Work settles nothing; an exceptional outcome earns positive Trust on any type")

	# --- 5. Emergency / World Need: spawned by a district resolving with
	# Unmet Demand (G5-B); resolving without the player produces no Trust
	# event and no Tallies; completing it lends temporary Capacity. ---
	trust_events.clear()
	settlements.clear()
	wallet.reset_all()
	district.reset_all()
	district.register_demand_contributor(&"wickwork", "crisis", "Cable failure across the mid band", 6.0)  # demand 10 > 6 + 2
	console.execute("force_advance 4")  # resolution: unmet > 0 -> emergency job spawned
	var emergency_id := &""
	for job: Dictionary in jobs.get_active_jobs():
		if job["def_id"] == &"emergency_wickwork":
			emergency_id = job["job_id"]
	if emergency_id == &"" or jobs.get_job(emergency_id)["work_type"] != &"emergency":
		_fail("unmet demand did not spawn the district's emergency job: %s" % [jobs.get_active_jobs()])
		return
	if bool(jobs.accept(emergency_id)):
		_fail("Emergency work must not have an Accepted stage")
		return
	console.execute("force_advance 4")  # this_cycle deadline passes with nobody helping
	if jobs.get_stage(emergency_id) != &"settled" or jobs.get_job(emergency_id)["grade"] != &"unengaged" or not trust_events.is_empty() or int(wallet.get_balance()) != 0:
		_fail("an emergency resolving without the player should settle with no Trust/Tallies: %s %s" % [jobs.get_job(emergency_id), trust_events])
		return
	# A new one spawned for the still-short district; helping this time
	# lends Wickwork temporary Capacity.
	var emergency2 := &""
	for job: Dictionary in jobs.get_active_jobs():
		if job["def_id"] == &"emergency_wickwork":
			emergency2 = job["job_id"]
	if emergency2 == &"":
		_fail("a second emergency should spawn while demand stays unmet")
		return
	var capacity_before: float = float(district.get_capacity(&"wickwork"))
	jobs.progress(emergency2, &"sutral", 2)
	var helped: Dictionary = jobs.settle(emergency2)
	if helped["outcome"] != &"strong" or int(wallet.get_balance()) <= 0 or not trust_events.is_empty():
		_fail("helping with an emergency should pay Tallies, no Trust: %s" % [helped])
		return
	if float(district.get_capacity(&"wickwork")) <= capacity_before:
		_fail("completing the emergency should lend the district temporary Capacity")
		return
	district.unregister_demand_contributor(&"wickwork", "crisis")
	print("PASS emergencies spawn from unmet demand, never promise, and lend Capacity when helped")

	# --- 6. Deadline shapes are the job's own: a missed accepted Duty
	# settles as broken when its shape passes. ---
	trust_events.clear()
	clock.reset_all()
	clock.pause("test")
	var late: StringName = jobs.offer(&"open_the_gallery")  # multi_cycle, deadline_cycles=1
	jobs.accept(late)
	console.execute("force_advance 4")  # one full cycle — deadline_cycles not yet exceeded
	if jobs.get_deadline_status(late) != &"open" or jobs.get_stage(late) != &"accepted":
		_fail("deadline passed too early")
		return
	console.execute("force_advance 4")  # a second full cycle — deadline_cycles now exceeded
	if jobs.get_stage(late) != &"settled" or jobs.get_job(late)["grade"] != &"broken_commitment" or trust_events.size() != 1:
		_fail("a Duty missed past its cycle deadline should settle as broken: %s %s" % [jobs.get_job(late), trust_events])
		return
	print("PASS a missed deadline settles an accepted Duty as a broken commitment")

	# --- 7. Persistence through the real SaveLoad path. ---
	var live: StringName = jobs.offer(&"open_the_gallery")
	jobs.accept(live)
	jobs.progress(live, &"sutral", 1)
	var pre_save: Dictionary = jobs.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	jobs.reset_all()
	if not save_load.load_game():
		_fail("load_game")
		return
	if jobs.save_state() != pre_save or jobs.get_stage(live) != &"in_progress" or int(jobs.get_job(live)["delivered"]) != 1:
		_fail("Jobs did not round-trip:\n%s\nvs\n%s" % [pre_save, jobs.save_state()])
		return
	print("PASS job instances persist through save/load")

	point.queue_free()
	save_load.clear_save()
	jobs.reset_all()
	wallet.reset_all()
	trust.reset_all()
	hauling.reset_all()
	district.reset_all()
	fact_log.clear_all()
	clock.reset_all()
	await process_frame
	print("JOBS_TESTS_PASSED")
	quit(0)
