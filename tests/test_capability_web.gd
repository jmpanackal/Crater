extends SceneTree
## Build Bible Spec 25 (Capability Web) acceptance tests.
##
## Not covered here, and why:
## - Pulse Binder dialogue mentions as a discovery source — Dialogue
##   content for later; the contract they'd call (submit_discovery) is
##   driven directly.
## - The Discoveries / Forbidden Designs UI surfaces (canon §42) —
##   DIRECTION-level guidance; get_state()'s `missing` list is the data.
## - The Forbidden build itself (diverted output, fabrication) — Spec 28.


func _init() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	push_error("FAIL " + msg)
	quit(1)


func _run() -> void:
	var web: Node = root.get_node_or_null("CapabilityWeb")
	var storage: Node = root.get_node_or_null("Storage")
	var wallet: Node = root.get_node_or_null("Wallet")
	var journal: Node = root.get_node_or_null("Journal")
	var rig: Node = root.get_node_or_null("Rig")
	var district: Node = root.get_node_or_null("District")
	var trust: Node = root.get_node_or_null("Trust")
	var bus: Node = root.get_node_or_null("EventBus")
	var fact_log: Node = root.get_node_or_null("FactLog")
	var save_load: Node = root.get_node_or_null("SaveLoad")
	var community: Node = root.get_node_or_null("Community")
	if web == null or storage == null or wallet == null or journal == null or rig == null or district == null or trust == null or bus == null or fact_log == null or save_load == null:
		_fail("missing autoloads")
		return
	if community:
		community.set_paused(true)
	save_load.clear_save()
	web.reset_all()
	storage.reset_all()
	wallet.reset_all()
	journal.clear_all()
	rig.reset_all()
	district.reset_all()
	trust.reset_all()
	fact_log.clear_all()
	var discoveries: Array = []
	bus.technology_discovered.connect(func(tech_id: StringName, level: StringName) -> void: discoveries.append({"tech_id": tech_id, "level": level}))
	var Q := &"quieting_coupler"

	# --- 1. A tech with no discovery events is neither Known nor
	# Understood, and NOT Available even when everything else is in
	# place; families are several tags at once. ---
	if not (web.get_tech_ids() as Array).has(Q) or not (web.get_tech_ids() as Array).has(&"load_harness"):
		_fail("technologies not loaded from content: %s" % [web.get_tech_ids()])
		return
	# Give the player everything the coupler would need...
	storage.deposit_material(&"verdigris", 2)
	storage.add_component(&"firstfall_coupling")  # (this makes it Known — undo for the pure check)
	web.reset_all()
	discoveries.clear()  # the Component's real discovery event fired above; the pure check starts clean
	fact_log.clear_all()
	var homes_script := GDScript.new()
	homes_script.source_code = "extends Node\nfunc get_residence_tier() -> StringName:\n\treturn &\"mid_reach\"\n"
	homes_script.reload()
	var homes := Node.new()
	homes.name = "Homes"
	homes.set_script(homes_script)
	root.add_child(homes)
	var blank: Dictionary = web.get_state(Q)
	if bool(blank["known"]) or bool(blank["understood"]) or bool(blank["available"]):
		_fail("a tech with no discovery events should be nothing, regardless of affordability: %s" % [blank])
		return
	var fams: Array[StringName] = web.get_families(Q)
	if fams.size() != 2 or not fams.has(&"secrecy") or not fams.has(&"excavation"):
		_fail("families should be several tags: %s" % [fams])
		return
	if (web.get_leads(&"secrecy") as Array).any(func(l: Dictionary) -> bool: return l["tech_id"] == Q):
		_fail("an unknown tech surfaced as a lead — no greyed-out mysteries")
		return
	print("PASS undiscovered tech is nothing, even when affordable; families are multiple tags")

	# --- 2. A Known-level event makes known: true without touching
	# Understood/Available; repeats and lower levels are no-ops; nothing
	# un-discovers. ---
	if not bool(web.submit_discovery(Q, &"known", {"source": "test"})):
		_fail("known discovery refused")
		return
	var known: Dictionary = web.get_state(Q)
	if not bool(known["known"]) or bool(known["understood"]) or bool(known["available"]) or discoveries.size() != 1:
		_fail("known event should set only known: %s" % [known])
		return
	if bool(web.submit_discovery(Q, &"known", {})) or discoveries.size() != 1 or (fact_log.get_by_type(&"discovery") as Array).size() != 1:
		_fail("a repeat discovery was not a no-op")
		return
	if bool(web.submit_discovery(Q, &"nonsense", {})) or bool(web.submit_discovery(&"no_such_tech", &"known", {})):
		_fail("bad discovery accepted")
		return
	if not (web.get_leads(&"secrecy") as Array).any(func(l: Dictionary) -> bool: return l["tech_id"] == Q and not bool(l["understood"])):
		_fail("a Known tech should surface as a lead in its family with what it's missing")
		return
	web.submit_discovery(Q, &"understood", {"source": "test"})
	if bool(web.submit_discovery(Q, &"known", {})) or not bool(web.is_understood(Q)):
		_fail("a lower-level event after understood should be a no-op, never un-discovering")
		return
	print("PASS Known sets only known; discovery is one-directional and repeats are no-ops")

	# --- 3. Available is live: Known + Understood but missing a Material
	# reads false; acquiring it flips the very next query with no event;
	# spending it flips back. ---
	storage.reset_all()
	storage.add_component(&"firstfall_coupling")
	var lacking: Dictionary = web.get_state(Q)
	if bool(lacking["available"]) or not (lacking["missing"] as Array).any(func(m: String) -> bool: return m.contains("Verdigris")):
		_fail("missing Material should read unavailable with the Material named: %s" % [lacking])
		return
	storage.deposit_material(&"verdigris", 2)
	var have: Dictionary = web.get_state(Q)
	if not bool(have["available"]) or not (have["missing"] as Array).is_empty() or discoveries.size() != 2:
		_fail("acquiring the Material should make the next query available with no new event: %s" % [have])
		return
	storage.withdraw_material(&"verdigris", 2)
	if bool(web.is_available(Q)):
		_fail("spending the Material should read unavailable again (no stale cache)")
		return
	homes.queue_free()
	await process_frame
	storage.deposit_material(&"verdigris", 2)
	if bool(web.is_available(Q)) or not (web.get_missing(Q) as Array).any(func(m: String) -> bool: return m.contains("residence")):
		_fail("without the Mid Reach residence the graft design should be unavailable: %s" % [web.get_missing(Q)])
		return
	print("PASS Available is recomputed live from current Materials/Components/residence")

	# --- 4. Real discovery sources: a Component recovered makes a tech
	# Known; a Record read makes one Understood; Gear owned is understood. ---
	web.reset_all()
	storage.reset_all()
	discoveries.clear()
	storage.add_component(&"firstfall_coupling")
	if not bool(web.is_tech_known(Q)) or discoveries.is_empty() or discoveries[-1]["level"] != &"known":
		_fail("recovering a strange Component should make the design Known: %s" % [discoveries])
		return
	journal.unlock_record(&"firmament_note")
	if not bool(web.is_understood(Q)) or discoveries[-1]["level"] != &"understood":
		_fail("reading the Record should make the design Understood: %s" % [discoveries])
		return
	if bool(web.is_understood(&"counterweight_frame")):
		_fail("setup: Counterweight Frame should start Known but not Understood")
		return
	journal.unlock_record(&"slate_shard")
	if not bool(web.is_understood(&"counterweight_frame")):
		_fail("a Record wired to a sanctioned tech should make it Understood")
		return
	web.reset_all()
	rig.add_owned_gear(&"counterweight_frame")
	if not bool(web.is_understood(&"counterweight_frame")):
		_fail("owning Gear should count as understanding it")
		return
	print("PASS Components, Records and owned Gear are wired discovery sources")

	# --- 5. Approved Gear starts Known + Understood (the public catalog)
	# and its Availability is exactly Orders' terms; a Core Improvement's
	# requirements are its own. ---
	web.reset_all()
	wallet.reset_all()
	rig.reset_all()
	district.reset_all()
	var harness: Dictionary = web.get_state(&"load_harness")
	if not bool(harness["known"]) or not bool(harness["understood"]) or bool(harness["available"]) or not (harness["missing"] as Array).any(func(m: String) -> bool: return m.contains("Tallies")):
		_fail("sanctioned Gear should be Known+Understood and missing Tallies: %s" % [harness])
		return
	wallet.earn(6, "Shift pay")
	if not bool(web.is_available(&"load_harness")):
		_fail("with Tallies + district output the Load Harness should be Available")
		return
	var core: Dictionary = web.get_state(&"harness_reinforcement")
	if not bool(core["known"]) or bool(core["understood"]) or bool(core["available"]):
		_fail("Harness Reinforcement should start Known only: %s" % [core])
		return
	journal.unlock_record(&"nursery_rhyme")
	storage.deposit_material(&"ravelstone", 2)
	wallet.earn(8, "More pay")
	if not bool(web.is_available(&"harness_reinforcement")):
		_fail("core improvement with Record + Ravelstone + Tallies + standing should be Available: %s" % [web.get_missing(&"harness_reinforcement")])
		return
	print("PASS sanctioned tech is the public catalog; Availability reads Orders' terms or the tech's own requirements")

	# --- 6. Levels persist; starting levels re-seed on load. ---
	web.submit_discovery(Q, &"known", {"source": "test"})
	var pre_save: Dictionary = web.save_state()
	save_load.clear_save()
	if not save_load.save_game():
		_fail("save_game")
		return
	web.reset_all()
	if bool(web.is_tech_known(Q)):
		_fail("reset_all did not clear")
		return
	if not save_load.load_game():
		_fail("load_game")
		return
	if web.save_state() != pre_save or not bool(web.is_tech_known(Q)) or not bool(web.is_understood(&"load_harness")):
		_fail("CapabilityWeb did not round-trip:\n%s\nvs\n%s" % [pre_save, web.save_state()])
		return
	print("PASS Known/Understood persist through save/load")

	save_load.clear_save()
	web.reset_all()
	storage.reset_all()
	wallet.reset_all()
	journal.clear_all()
	rig.reset_all()
	district.reset_all()
	trust.reset_all()
	fact_log.clear_all()
	print("CAPABILITY_WEB_TESTS_PASSED")
	quit(0)
