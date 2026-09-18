extends Node
## Krater Residences + Workspace (autoload: Homes).
## Build Bible Spec 27 (docs/build-bible/specs/27-residences-workspace.md
## — AI draft pending USER review).
##
## Owns the player's residence tier (Lower -> the Mid Reach -> Ashram
## Heights, canon §62) and the private Forbidden workspace's qualitative
## concealment tier (Basic / Improved / Advanced, §62 — state-based, never
## a percentage). Rig (Spec 14) reads the tier for grafting; CapabilityWeb
## (Spec 25) for residence requirements; Diversion (Spec 26) stashes into
## the workspace.
##
## Safe by default (§47/§62): nothing here rolls a search. A residence
## search happens only when Investigation (Spec 20) requests one for the
## "residence" context — repeated district discrepancies, an authored
## trigger — and this system resolves it against the concealment tier:
## the search finds the workspace when its tier rank >= the concealment
## rank (Basic concealment falls to a deliberate search, Improved to a
## targeted one, §62's wording). What is found is what the player
## actually hid — concealed stolen output and stolen units on the person;
## grafts are never found by a home search (Spec 20: examiner-only).
## Finding it is serious but not game over: facts, confiscation, the
## districts' books reconciled, ONE Trust event scaled by the haul.
##
## Access via get_tree().root.get_node("Homes") (no class_name).

const TUNING_DOMAIN := "homes_tuning"
const RESIDENCE_CONTEXT := &"residence"

const TIER_LOWER := &"lower"
const TIER_MID_REACH := &"mid_reach"
const TIER_ASHRAM_HEIGHTS := &"ashram_heights"
const TIER_ORDER: Array[StringName] = [TIER_LOWER, TIER_MID_REACH, TIER_ASHRAM_HEIGHTS]

const CONCEAL_BASIC := &"basic"
const CONCEAL_IMPROVED := &"improved"
const CONCEAL_ADVANCED := &"advanced"
const CONCEAL_ORDER: Array[StringName] = [CONCEAL_BASIC, CONCEAL_IMPROVED, CONCEAL_ADVANCED]

const FACT_RESIDENCE_ACQUIRED := &"residence_acquired"
const FACT_WORKSPACE_DISCOVERED := &"workspace_discovered"

var _tier: StringName = TIER_LOWER
## Extra concealment steps bought on top of the tier's base.
var _concealment_bonus: int = 0


func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("search_requested") and not bus.search_requested.is_connected(_on_search_requested):
		bus.search_requested.connect(_on_search_requested)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("home", "home — residence tier, workspace concealment, what a search would find.", _debug_home)
	console.register_command("acquire_home", "acquire_home <mid_reach|ashram_heights> — acquire the next residence (Trust + Tallies + story flag).", _debug_acquire)
	console.register_command("grant_home", "grant_home <tier> — story grant: set the residence tier with no cost.", _debug_grant)
	console.register_command("search_home", "search_home [basic|improved|advanced] — resolve a residence search now.", _debug_search)


# --- Tuning ---------------------------------------------------------------------

func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


func _tune(name: String, fallback: Variant) -> Variant:
	var tuning := _tuning()
	if tuning == null:
		return fallback
	var v: Variant = tuning.get(name)
	return fallback if v == null else v


# --- Residence tier --------------------------------------------------------------------

func get_residence_tier() -> StringName:
	return _tier


func tier_rank(tier: StringName) -> int:
	return TIER_ORDER.find(tier)


func has_at_least(tier: StringName) -> bool:
	return tier_rank(_tier) >= tier_rank(tier)


## {"ok", "reason"}: next tier only; Trust standing, Tallies and the story
## flag each refuse distinctly.
func can_acquire(tier: StringName) -> Dictionary:
	if not TIER_ORDER.has(tier) or tier == TIER_LOWER:
		return {"ok": false, "reason": "unknown_tier"}
	if tier_rank(tier) != tier_rank(_tier) + 1:
		return {"ok": false, "reason": "already_owned" if tier_rank(tier) <= tier_rank(_tier) else "not_next_tier"}
	var terms := _terms(tier)
	var story := get_tree().root.get_node_or_null("Story")
	if terms["flag"] != &"" and (story == null or not bool(story.has_flag(terms["flag"]))):
		return {"ok": false, "reason": "story_clearance_missing"}
	var trust := get_tree().root.get_node_or_null("Trust")
	if terms["min_trust"] != &"" and trust != null and not _standing_at_least(trust, terms["min_trust"]):
		return {"ok": false, "reason": "trust_too_low"}
	var wallet := get_tree().root.get_node_or_null("Wallet")
	if int(terms["tallies"]) > 0 and (wallet == null or not bool(wallet.can_afford(int(terms["tallies"])))):
		return {"ok": false, "reason": "insufficient_tallies"}
	return {"ok": true, "reason": ""}


## Acquires the next residence: spends the Tallies (Wallet, reasoned),
## moves in. Atomic — a refusal spends nothing. {"success", "reason"}.
func acquire(tier: StringName) -> Dictionary:
	var check := can_acquire(tier)
	if not bool(check["ok"]):
		return {"success": false, "reason": str(check["reason"])}
	var terms := _terms(tier)
	var wallet := get_tree().root.get_node_or_null("Wallet")
	if int(terms["tallies"]) > 0 and not bool(wallet.spend(int(terms["tallies"]), "Moved up to the %s residence" % _label(tier))):
		return {"success": false, "reason": "insufficient_tallies"}
	_set_tier(tier, "acquired")
	return {"success": true, "reason": ""}


## The authored/story path: a residence granted by events, no cost.
func grant_residence(tier: StringName, reason: String) -> bool:
	if not TIER_ORDER.has(tier) or reason.strip_edges() == "":
		return false
	_set_tier(tier, reason.strip_edges())
	return true


func _set_tier(tier: StringName, reason: String) -> void:
	var old := _tier
	_tier = tier
	_concealment_bonus = 0  # a new home starts at its own base concealment
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log != null and old != tier:
		var witnesses: Array[String] = []
		fact_log.record(FACT_RESIDENCE_ACQUIRED, fact_log.SUBJECT_PLAYER, StringName(), witnesses, {"tier": str(tier), "from": str(old), "reason": reason}, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("residence_changed"):
		bus.residence_changed.emit(tier)


func _terms(tier: StringName) -> Dictionary:
	match tier:
		TIER_MID_REACH:
			return {"min_trust": StringName(str(_tune("mid_reach_min_trust", &"relied_on"))), "tallies": int(_tune("mid_reach_tallies", 30)), "flag": StringName(str(_tune("mid_reach_flag", &"mid_reach_clearance")))}
		TIER_ASHRAM_HEIGHTS:
			return {"min_trust": StringName(str(_tune("ashram_min_trust", &"esteemed"))), "tallies": int(_tune("ashram_tallies", 80)), "flag": StringName(str(_tune("ashram_flag", &"ashram_clearance")))}
	return {"min_trust": &"", "tallies": 0, "flag": &""}


func _label(tier: StringName) -> String:
	match tier:
		TIER_MID_REACH:
			return "Mid Reach"
		TIER_ASHRAM_HEIGHTS:
			return "Ashram Heights"
	return "Lower"


func _standing_at_least(trust: Node, needed: StringName) -> bool:
	var ladder: Array[Dictionary] = trust.get_standing_ladder()
	var current: StringName = trust.get_trust()
	var current_rank := -1
	var needed_rank := -1
	for i in range(ladder.size()):
		if ladder[i]["id"] == current:
			current_rank = i
		if ladder[i]["id"] == needed:
			needed_rank = i
	return needed_rank < 0 or current_rank >= needed_rank


# --- Workspace concealment --------------------------------------------------------------

## Base concealment follows the home (draft choice): Lower crude = Basic,
## Mid Reach / Ashram = Improved; improve_concealment() steps up.
func get_workspace_concealment() -> StringName:
	var base := 0 if _tier == TIER_LOWER else 1
	return CONCEAL_ORDER[clampi(base + _concealment_bonus, 0, CONCEAL_ORDER.size() - 1)]


func concealment_rank(tier: StringName) -> int:
	return maxi(0, CONCEAL_ORDER.find(tier))


## One step better (Tallies), up to Advanced. {"success", "reason"}.
func improve_concealment() -> Dictionary:
	if get_workspace_concealment() == CONCEAL_ADVANCED:
		return {"success": false, "reason": "already_advanced"}
	var wallet := get_tree().root.get_node_or_null("Wallet")
	var price := int(_tune("improve_concealment_tallies", 15))
	if wallet == null or not bool(wallet.spend(price, "Improved the workspace's concealment")):
		return {"success": false, "reason": "insufficient_tallies"}
	_concealment_bonus += 1
	return {"success": true, "reason": ""}


# --- Residence searches -----------------------------------------------------------------

func _on_search_requested(context: StringName, _reason: String) -> void:
	if context != RESIDENCE_CONTEXT:
		return
	# The search's tier rides on Investigation's request fact.
	var tier := CONCEAL_BASIC
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log != null:
		var latest: Dictionary = {}
		for fact: Dictionary in fact_log.get_by_type(&"search_requested"):
			if str((fact["context"] as Dictionary).get("investigation_context", "")) == str(RESIDENCE_CONTEXT):
				if latest.is_empty() or int(fact["index"]) > int(latest["index"]):
					latest = fact
		if not latest.is_empty():
			var t := StringName(str((latest["context"] as Dictionary).get("search_tier", "basic")))
			if CONCEAL_ORDER.has(t):
				tier = t
	resolve_home_search(tier)


## What the workspace currently hides: {"concealed": {district: units},
## "carried": {district: units}, "total": int}.
func get_contraband() -> Dictionary:
	var storage := get_tree().root.get_node_or_null("Storage")
	var diversion := get_tree().root.get_node_or_null("Diversion")
	var concealed: Dictionary = storage.get_concealed_snapshot() if storage != null and storage.has_method("get_concealed_snapshot") else {}
	var carried: Dictionary = diversion.get_carried_snapshot() if diversion != null and diversion.has_method("get_carried_snapshot") else {}
	var total := 0
	for key: Variant in concealed.keys():
		total += int(concealed[key])
	for key: Variant in carried.keys():
		total += int(carried[key])
	return {"concealed": concealed, "carried": carried, "total": total}


## Resolves a search of the player's residence at `search_tier`. Returns
## {"found": bool, "outcome": "found_evidence"|"found_nothing", "units": int,
## "trust_delta": float}. Logs the resolution facts under the "residence"
## investigation context (Investigation delegates this context here).
func resolve_home_search(search_tier: StringName = CONCEAL_BASIC) -> Dictionary:
	var contraband := get_contraband()
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	var cycle := int(clock.get_cycles_elapsed()) if clock != null else -1
	var witnesses: Array[String] = []
	var beaten := concealment_rank(search_tier) >= concealment_rank(get_workspace_concealment())
	var units := int(contraband["total"])
	var bus := get_tree().root.get_node_or_null("EventBus")
	if units <= 0 or not beaten:
		if fact_log != null:
			fact_log.record(&"found_nothing", fact_log.SUBJECT_PLAYER, StringName(), witnesses, {
				"investigation_context": str(RESIDENCE_CONTEXT), "search_tier": str(search_tier),
				"concealment": str(get_workspace_concealment()), "survived": units > 0,
			}, cycle)
		if bus != null and bus.has_signal("investigation_resolved"):
			bus.investigation_resolved.emit(RESIDENCE_CONTEXT, 0)
		return {"found": false, "outcome": &"found_nothing", "units": 0, "trust_delta": 0.0}
	# Found: facts naming what, confiscation, the books reconciled, one
	# Trust event scaled by how much was there.
	var storage := get_tree().root.get_node_or_null("Storage")
	var diversion := get_tree().root.get_node_or_null("Diversion")
	var district := get_tree().root.get_node_or_null("District")
	var found_by_district: Dictionary = {}
	for source in [contraband["concealed"], contraband["carried"]]:
		for key: Variant in (source as Dictionary).keys():
			found_by_district[str(key)] = int(found_by_district.get(str(key), 0)) + int((source as Dictionary)[key])
	if fact_log != null:
		for key: Variant in found_by_district.keys():
			fact_log.record(&"found_evidence", fact_log.SUBJECT_PLAYER, StringName(), witnesses, {
				"investigation_context": str(RESIDENCE_CONTEXT), "search_tier": str(search_tier),
				"what": "stolen_output", "district_id": str(key), "units": int(found_by_district[key]),
			}, cycle)
		fact_log.record(FACT_WORKSPACE_DISCOVERED, fact_log.SUBJECT_PLAYER, StringName(), witnesses, {
			"investigation_context": str(RESIDENCE_CONTEXT), "units": units, "concealment": str(get_workspace_concealment()),
		}, cycle)
	if storage != null and storage.has_method("clear_concealed"):
		storage.clear_concealed()
	if diversion != null and diversion.has_method("confiscate_carried"):
		diversion.confiscate_carried()
	if district != null and district.has_method("explain_loss"):
		for key: Variant in found_by_district.keys():
			district.explain_loss(StringName(str(key)), float(found_by_district[key]))
	var delta := maxf(float(_tune("discovered_trust_delta_cap", -18.0)), float(_tune("discovered_trust_delta_per_unit", -3.0)) * float(units))
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust != null:
		trust.submit_trust_event(&"workspace_discovered", delta, "A search of your home turned up %d unit%s of diverted district output" % [units, "" if units == 1 else "s"])
	if bus != null:
		if bus.has_signal("workspace_discovered"):
			bus.workspace_discovered.emit(units)
		if bus.has_signal("investigation_resolved"):
			bus.investigation_resolved.emit(RESIDENCE_CONTEXT, found_by_district.size())
	return {"found": true, "outcome": &"found_evidence", "units": units, "trust_delta": delta}


# --- Build Bible Spec 02 uniform SaveLoad contract ----------------------------------------

func save_state() -> Dictionary:
	return {"tier": str(_tier), "concealment_bonus": _concealment_bonus}


func load_state(data: Dictionary) -> void:
	var tier := StringName(str(data.get("tier", "lower")))
	_tier = tier if TIER_ORDER.has(tier) else TIER_LOWER
	_concealment_bonus = maxi(0, int(data.get("concealment_bonus", 0)))
	_emit_residence_changed()  # gates (Spec 31) re-evaluate on a load too


func reset_all() -> void:
	_tier = TIER_LOWER
	_concealment_bonus = 0
	_emit_residence_changed()


## Loading is inert (Spec 02) — this is a state notification, not a
## "welcome back" side effect: Access derives open/closed from it.
func _emit_residence_changed() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus") if is_inside_tree() else null
	if bus != null and bus.has_signal("residence_changed"):
		bus.residence_changed.emit(_tier)


# --- Debug ------------------------------------------------------------------------------------

func _debug_home(_args: Array[String]) -> String:
	var c := get_contraband()
	return "Residence: %s — workspace concealment %s — hiding %d unit(s): concealed %s, carried %s" % [_label(_tier), get_workspace_concealment(), int(c["total"]), c["concealed"], c["carried"]]


func _debug_acquire(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: acquire_home <mid_reach|ashram_heights>"
	var result := acquire(StringName(args[0]))
	return "Moved to %s" % _label(StringName(args[0])) if bool(result["success"]) else "Refused: %s" % result["reason"]


func _debug_grant(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: grant_home <lower|mid_reach|ashram_heights>"
	return "Granted %s" % args[0] if grant_residence(StringName(args[0]), "debug grant") else "Unknown tier"


func _debug_search(args: Array[String]) -> String:
	var tier := StringName(args[0].to_lower()) if not args.is_empty() else CONCEAL_BASIC
	var result := resolve_home_search(tier if CONCEAL_ORDER.has(tier) else CONCEAL_BASIC)
	return "Search (%s): %s%s" % [tier, result["outcome"], " — %d unit(s) confiscated, Trust %.1f" % [int(result["units"]), float(result["trust_delta"])] if bool(result["found"]) else ""]
