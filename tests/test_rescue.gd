extends SceneTree
## Build Bible Spec 30 (Failure / Rescue) acceptance tests — against the
## AI-drafted spec, pending USER review.
##
## Not covered here, and why:
## - Authored barriers preventing lethal drops (G22-A) — level content.
## - Who exactly rescues the player (NPC content) — the facts carry the
##   zone and what was found; the rescuer's identity is scene authoring.
## - Breathing/exertion audio and warning UI — strain_state_changed is the
##   data hook.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var rescue: Node = root.get_node_or_null("Rescue")
	var fatigue: Node = root.get_node_or_null("Fatigue")
	var stamina: Node = root.get_node_or_null("Stamina")
	var hauling: Node = root.get_node_or_null("Hauling")
	var clock: Node = root.get_node_or_null("Clock")
	var storage: Node = root.get_node_or_null("Storage")
	var journal: Node = root.get_node_or_null("Journal")
	var diversion: Node = root.get_node_or_null("Diversion")
	var district: Node = root.get_node_or_null("District")
	var trust: Node = root.get_node_or_null("Trust")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var bus: Node = root.get_node_or_null("EventBus")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	if rescue == null or fatigue == null or stamina == null or hauling == null or clock == null or storage == null or journal == null or diversion == null or district == null or trust == null or fact_log == null or bus == null or save_load == null:
		_fail("missing autoloads")
		return
	rescue.suspend_forced_rescue = true
	save_load.clear_save()
	clock.reset_all()
	clock.pause("test")
	for n in [rescue, hauling, storage, diversion, district, trust, stamina]:
		n.reset_all()
	journal.clear_all()
	fact_log.clear_all()
	var trust_events: Array = []
	bus.trust_changed.connect(func(_s: StringName, delta: float, _r: String) -> void: trust_events.append(delta))
	var states: Array = []
	bus.strain_state_changed.connect(func(state: StringName) -> void: states.append(state))
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	await process_frame

	# --- 1. A severe fall: fatigue added, haul left as a cache at the last
	# safe ground, the tuned phases of civic time lost, one fact; stored
	# Components/Records untouched. ---
	storage.add_component(&"firstfall_coupling")
	journal.unlock_record(&"slate_shard")
	hauling.attach(&"sutral", 2)
	var phase_before: StringName = clock.get_phase()
	var fatigue_before: float = float(fatigue.get_current())
	var safe := Vector2(120.0, HollowLayout.WEST_LW_UPPER_Y - 32.0)
	var record: Dictionary = rescue.report_severe_fall(Vector2(500, 2000), safe)
	if float(fatigue.get_current()) <= fatigue_before or float(record["fatigue_added"]) <= 0.0:
		_fail("a severe fall should add fatigue: %s" % [record])
		return
	if bool(hauling.is_loaded()) or not bool(record["haul_cached"]) or (hauling.get_caches() as Array).size() != 1 or ((hauling.get_caches() as Array)[0]["position"] as Vector2).distance_to(safe) > 0.5:
		_fail("the haul should be left as a cache at the last safe ground: %s" % [hauling.get_caches()])
		return
	if clock.get_phase() == phase_before and int(record["phases_lost"]) > 0:
		_fail("a severe fall should cost civic time (phase still %s)" % clock.get_phase())
		return
	if (fact_log.get_by_type(&"severe_fall") as Array).size() != 1:
		_fail("one severe_fall fact expected")
		return
	if int(storage.count_components(&"firstfall_coupling")) != 1 or not bool(journal.has_record(&"slate_shard")):
		_fail("a fall must never delete Components or Records")
		return
	print("PASS a severe fall adds fatigue, caches the haul at safe ground, costs civic time, and touches no stored goods")

	# --- 2. Failure states are derived: none -> strained -> exhausted ->
	# stranded (exhausted outside the Hollow); Rescue reads Hollow presence
	# from the player's real position (HollowLayout bounds), not a flag; the
	# transitions are announced. ---
	stamina.reset_all()
	fatigue.recover_full()
	player.global_position = HollowLayout.player_spawn_point()
	await process_frame
	if rescue.get_failure_state() != &"none":
		_fail("fresh stamina should read no failure state (%s)" % rescue.get_failure_state())
		return
	stamina.request_block(stamina.SOURCE_HAULING, float(stamina.get_max_stamina()) * 0.8)
	if rescue.get_failure_state() != &"strained":
		_fail("heavily blocked stamina should read strained (%s)" % rescue.get_failure_state())
		return
	stamina.release_block(stamina.SOURCE_HAULING)
	player.global_position = Vector2(2000.0, 1000.0)  # well outside HollowLayout's bounds — out in the field
	stamina.request_block(stamina.SOURCE_FATIGUE, float(stamina.get_max_stamina()))  # exhausted
	if not bool(fatigue.is_exhausted()) or rescue.get_failure_state() != &"stranded":
		_fail("exhausted outside the Hollow should read stranded (%s)" % rescue.get_failure_state())
		return
	player.global_position = HollowLayout.player_spawn_point()  # inside the Hollow
	if rescue.get_failure_state() != &"exhausted":
		_fail("exhausted inside the Hollow should read exhausted, not stranded")
		return
	player.global_position = Vector2(2000.0, 1000.0)
	await process_frame
	await process_frame
	if not states.has(&"stranded"):
		_fail("strain_state_changed should announce transitions: %s" % [states])
		return
	print("PASS failure states derive from Stamina/Fatigue and Hollow presence, and are announced")

	# --- 3. Rescue from a restricted zone while carrying stolen output:
	# exposure facts, contraband confiscated, one Trust event, haul cached
	# at the site, home with partial recovery, time advanced to Rousing. ---
	fact_log.clear_all()
	trust_events.clear()
	hauling.reset_all()
	district.reset_all()
	diversion.complete_take(&"wickwork")
	hauling.attach(&"ravelstone", 1)
	player.global_position = Vector2(1100, 100)  # east_firmament: restricted
	clock.reset_all()
	clock.pause("test")
	root.get_node("DebugConsole").execute("force_phase working")
	var rescued: Dictionary = rescue.request_rescue(false)
	if rescued.is_empty() or not bool(rescued["restricted"]) or int(rescued["contraband_units"]) != 1:
		_fail("rescue from restricted rock with contraband should record both: %s" % [rescued])
		return
	if (fact_log.get_by_type(&"rescued_from_restricted_area") as Array).size() != 1 or (fact_log.get_by_type(&"found_evidence") as Array).size() != 1 or (fact_log.get_by_type(&"rescued") as Array).size() != 1:
		_fail("rescue exposure facts wrong")
		return
	if trust_events.size() != 1 or float(trust_events[0]) >= 0.0 or int(diversion.get_carried_total()) != 0:
		_fail("contraband found by rescuers should be one Trust event + confiscation: %s" % [trust_events])
		return
	if bool(hauling.is_loaded()) or (hauling.get_caches() as Array).size() != 1:
		_fail("the haul should be cached at the rescue site")
		return
	if clock.get_phase() != &"rousing" or int(clock.get_cycles_elapsed()) != 1:
		_fail("a rescue should advance the Clock to the next Rousing (%s, cycle %d)" % [clock.get_phase(), clock.get_cycles_elapsed()])
		return
	if bool(fatigue.is_exhausted()) or float(fatigue.get_current()) <= 0.0 or player.global_position.distance_to(HollowLayout.player_spawn_point()) > 0.5:
		_fail("after rescue the player should be home with fatigue partially recovered")
		return
	print("PASS rescue from restricted excavation with contraband exposes it: facts, confiscation, one Trust event, time lost")

	# --- 4. Rescue from ordinary civic work with nothing carried costs
	# only time/haul/fatigue — no Trust event. ---
	fact_log.clear_all()
	trust_events.clear()
	hauling.reset_all()
	stamina.request_block(stamina.SOURCE_FATIGUE, float(stamina.get_max_stamina()))
	player.global_position = Vector2(1500, 1000)  # east_dig_site: sanctioned
	var civic: Dictionary = rescue.request_rescue(true)
	if bool(civic["restricted"]) or int(civic["contraband_units"]) != 0 or not trust_events.is_empty() or (fact_log.get_by_type(&"rescued_from_restricted_area") as Array).size() != 0:
		_fail("rescue from civic work should carry no Trust consequence: %s %s" % [civic, trust_events])
		return
	if bool(rescue.request_rescue(false).size() > 0):
		_fail("a rescue should not be available when not exhausted")
		return
	print("PASS rescue from sanctioned civic work costs only time, haul and fatigue")

	# --- 5. The grace period: stranded long enough forces the rescue. ---
	fact_log.clear_all()
	stamina.request_block(stamina.SOURCE_FATIGUE, float(stamina.get_max_stamina()))
	player.global_position = Vector2(1500, 1000)
	rescue.suspend_forced_rescue = false
	var grace: float = float(rescue.get_stranded_grace_seconds())
	# Drive the timer with controlled deltas (headless frames are far faster
	# than wall-clock, same reason test_clock.gd calls _process directly).
	rescue._process(grace * 0.5)
	if not bool(rescue.is_stranded()) or float(rescue.get_stranded_seconds()) <= 0.0 or (fact_log.get_by_type(&"rescued") as Array).size() != 0:
		_fail("half the grace period should not yet force a rescue (%s, %.0fs)" % [rescue.get_failure_state(), rescue.get_stranded_seconds()])
		return
	rescue._process(grace * 0.5 + 1.0)
	if (fact_log.get_by_type(&"rescued") as Array).size() != 1 or not bool(((fact_log.get_by_type(&"rescued") as Array)[0]["context"] as Dictionary).get("forced", false)):
		_fail("staying stranded past the grace period should force a rescue")
		return
	rescue.suspend_forced_rescue = true
	print("PASS a stranded player is rescued by force after the grace period")

	player.queue_free()
	save_load.clear_save()
	for n in [rescue, hauling, storage, diversion, district, trust, stamina]:
		n.reset_all()
	journal.clear_all()
	fact_log.clear_all()
	clock.reset_all()
	await process_frame
	print("RESCUE_TESTS_PASSED")
	quit(0)
