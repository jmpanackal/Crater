extends Node
## Krater Suspicion + Investigation (autoload: Investigation).
## Build Bible Spec 20 (docs/build-bible/specs/20-suspicion-investigation.md).
##
## The missing link between "something happened" (Witness, Spec 17;
## Evidence, Spec 18) and "something happens about it" (Trust, Spec 19).
## Stub slice per the spec: the generic contract is real; the vertical
## slice authors one investigation case through trigger_investigation().
##
## OWNS NO STATE. Everything here is DERIVED from the Fact Log, live:
## - get_suspicion(context): recomputed from a recent window of relevant
##   facts (option A) — Witness facts scoped to that NPC or location,
##   found_evidence facts scoped to that location, district discrepancy
##   facts scoped to that district (Spec 22 produces those). Older facts
##   age out of the window — that IS the cooldown; nothing decays.
##   Never a global meter (canon §19): a context is an NPC id, a zone id,
##   a district id, or an incident id.
## - get_investigation_stage(context): the latest of that context's own
##   search_requested / found_evidence / found_nothing facts — not a
##   stored state machine (option A).
## - Investigation triggers two ways (option A): a generic rule — on each
##   new fact, the contexts it touches are recomputed and the FIRST time
##   one crosses its threshold a search_requested is emitted — and the
##   authored path, trigger_investigation(context, reason), which bypasses
##   the threshold entirely.
## - Trust never adds to the score; it modulates the THRESHOLD only
##   (option A): higher Trust = more benefit of the doubt = higher
##   threshold; lower Trust triggers sooner.
## - Forbidden Gear is excluded from ordinary Witness entirely — enforced
##   upstream by Perception having no call path for grafts; nothing here
##   can manufacture a fact that was never written.
##
## Resolution: a search of a world context goes through
## Evidence.resolve_search() (Spec 18) at the tuned search tier; what it
## finds is logged as found_evidence facts (one per delta), nothing as a
## found_nothing fact. Real, unconcealed evidence -> exactly one
## Trust.submit_trust_event() with a reason built from what was found.
## The search_requested event is also emitted on the EventBus so Homes
## (Spec 27) can resolve a residence search against the workspace's
## concealment tier when it exists.
##
## "Freshly": after a resolution, the same context doesn't re-trigger on
## the very next fact — only facts newer than its last search count
## toward the auto-trigger, so it has to cross the threshold again.
##
## Access via get_tree().root.get_node("Investigation") (no class_name,
## matching the existing project convention — see resources.gd).

const TUNING_DOMAIN := "suspicion_tuning"

const FACT_SEARCH_REQUESTED := &"search_requested"
const FACT_FOUND_EVIDENCE := &"found_evidence"
const FACT_FOUND_NOTHING := &"found_nothing"
const FACT_DISTRICT_DISCREPANCY := &"district_discrepancy"

const STAGE_NONE := &"none"

const STAGE_FACTS: Array[StringName] = [FACT_SEARCH_REQUESTED, FACT_FOUND_EVIDENCE, FACT_FOUND_NOTHING]

## Guards re-entrancy while this system itself records resolution facts
## (those must never auto-trigger a fresh search mid-resolution).
var _resolving := false


func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and not bus.fact_recorded.is_connected(_on_fact_recorded):
		bus.fact_recorded.connect(_on_fact_recorded)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("suspicion", "suspicion <context> — derived suspicion score, threshold and stage for an NPC/zone/district id.", _debug_suspicion)
	console.register_command("investigate", "investigate <context> <reason...> — authored trigger: request and resolve a search now, regardless of suspicion.", _debug_investigate)


# --- Tuning ---------------------------------------------------------------------

func get_window_cycles() -> int:
	var tuning := _tuning()
	return maxi(0, int(tuning.window_cycles)) if tuning != null else 3


func get_threshold_base() -> float:
	var tuning := _tuning()
	return float(tuning.threshold_base) if tuning != null else 4.0


func get_threshold_per_trust_point() -> float:
	var tuning := _tuning()
	return float(tuning.threshold_per_trust_point) if tuning != null else 0.05


func get_default_search_tier() -> StringName:
	var tuning := _tuning()
	return StringName(str(tuning.default_search_tier)) if tuning != null else &"basic"


func get_found_evidence_trust_delta() -> float:
	var tuning := _tuning()
	return float(tuning.found_evidence_trust_delta) if tuning != null else -10.0


func _weight(name: String, fallback: float) -> float:
	var tuning := _tuning()
	return float(tuning.get(name)) if tuning != null else fallback


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- Derived queries -------------------------------------------------------------------

## Live suspicion for a context, summed over the recent window. 0.0 for a
## context nothing points at. Never stored.
func get_suspicion(context: StringName) -> float:
	return _score(context, -1)


## The threshold this context must cross for an automatic investigation
## — read against Trust's internal value (higher Trust, higher bar).
func get_threshold(_context: StringName) -> float:
	var trust_value := 50.0
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust != null and trust.has_method("get_trust_value"):
		trust_value = float(trust.get_trust_value())
	return get_threshold_base() + trust_value * get_threshold_per_trust_point()


## none / search_requested / found_evidence / found_nothing — the latest
## of this context's own resolution facts.
func get_investigation_stage(context: StringName) -> StringName:
	var latest := _latest_stage_fact(context)
	if latest.is_empty():
		return STAGE_NONE
	return latest["type"]


## Facts newer than `after_index` (-1 = all) inside the window that bear
## on `context`, weighted.
func _score(context: StringName, after_index: int) -> float:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return 0.0
	var current_cycle := _current_cycle()
	var oldest := current_cycle - get_window_cycles()
	var total := 0.0
	for fact: Dictionary in fact_log.get_all():
		if int(fact["index"]) <= after_index:
			continue
		var cycle := int(fact["cycle"])
		if cycle >= 0 and cycle < oldest:
			continue
		total += _relevance(fact, context)
	return total


## How much one fact counts toward `context` (0 if unrelated).
func _relevance(fact: Dictionary, context: StringName) -> float:
	var type: StringName = fact["type"]
	var ctx: Dictionary = fact.get("context", {})
	var location := StringName(str(fact.get("location", "")))
	match type:
		FACT_SEARCH_REQUESTED, FACT_FOUND_NOTHING:
			return 0.0  # bookkeeping, never suspicion
		FACT_FOUND_EVIDENCE:
			# Real evidence found in a place keeps that place hot.
			if location == context or StringName(str(ctx.get("investigation_context", ""))) == context:
				return _weight("weight_found_evidence", 3.0)
			return 0.0
		FACT_DISTRICT_DISCREPANCY:
			if StringName(str(ctx.get("district_id", ""))) == context:
				return _weight("weight_district_discrepancy", 2.0)
			return 0.0
	# Witness facts (Spec 17): scoped to the witnessing NPC and to the
	# location they saw it in.
	if ctx.has("npc_id") and ctx.has("sense"):
		if StringName(str(ctx["npc_id"])) == context or location == context:
			return _weight("weight_witness_sight", 2.0) if str(ctx["sense"]) == "sight" else _weight("weight_witness_sound", 1.0)
	return 0.0


func _latest_stage_fact(context: StringName) -> Dictionary:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return {}
	var latest: Dictionary = {}
	for fact: Dictionary in fact_log.get_all():
		if not STAGE_FACTS.has(fact["type"]):
			continue
		if StringName(str((fact.get("context", {}) as Dictionary).get("investigation_context", ""))) != context:
			continue
		if latest.is_empty() or int(fact["index"]) > int(latest["index"]):
			latest = fact
	return latest


func _last_request_index(context: StringName) -> int:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return -1
	var index := -1
	for fact: Dictionary in fact_log.get_by_type(FACT_SEARCH_REQUESTED):
		if StringName(str((fact.get("context", {}) as Dictionary).get("investigation_context", ""))) == context:
			index = maxi(index, int(fact["index"]))
	return index


# --- The generic, state-driven trigger --------------------------------------------------

func _on_fact_recorded(fact: Dictionary) -> void:
	if _resolving:
		return
	for context: StringName in _contexts_of(fact):
		# Only facts newer than the context's last search count — a
		# resolved search must be crossed freshly.
		var score := _score(context, _last_request_index(context))
		if score >= get_threshold(context):
			trigger_investigation(context, "Suspicion crossed the threshold (%.1f / %.1f)" % [score, get_threshold(context)])


## The contexts a new fact could raise suspicion for.
func _contexts_of(fact: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	var ctx: Dictionary = fact.get("context", {})
	var location := StringName(str(fact.get("location", "")))
	if fact["type"] == FACT_DISTRICT_DISCREPANCY and ctx.has("district_id"):
		out.append(StringName(str(ctx["district_id"])))
	if ctx.has("npc_id") and ctx.has("sense"):
		out.append(StringName(str(ctx["npc_id"])))
	if location != &"" and not out.has(location):
		out.append(location)
	return out


# --- Investigations ---------------------------------------------------------------------

## The authored/story entry point — and what the auto-trigger calls.
## Always fires regardless of suspicion: logs search_requested, emits it
## on the bus (Homes, Spec 27, resolves residence searches on it), then
## resolves the world half of the search right here. Returns the
## resolution: {"context", "found": [records], "stage"}.
func trigger_investigation(context: StringName, reason: String) -> Dictionary:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null or context == &"":
		return {"context": context, "found": [], "stage": STAGE_NONE}
	var tier := get_default_search_tier()
	_resolving = true
	var witnesses: Array[String] = []
	fact_log.record(FACT_SEARCH_REQUESTED, fact_log.SUBJECT_PLAYER, _location_of(context), witnesses, {
		"investigation_context": str(context), "reason": reason, "search_tier": str(tier),
	}, _current_cycle())
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("search_requested"):
		bus.search_requested.emit(context, reason)
	var found := _resolve_world_search(context, tier)
	var stage := FACT_FOUND_NOTHING
	if found.is_empty():
		fact_log.record(FACT_FOUND_NOTHING, fact_log.SUBJECT_PLAYER, _location_of(context), witnesses, {
			"investigation_context": str(context), "search_tier": str(tier),
		}, _current_cycle())
	else:
		stage = FACT_FOUND_EVIDENCE
		for record: Dictionary in found:
			var cell: Vector2i = record["cell"]
			fact_log.record(FACT_FOUND_EVIDENCE, fact_log.SUBJECT_PLAYER, StringName(str(record["zone_id"])), witnesses, {
				"investigation_context": str(context), "cell": [cell.x, cell.y],
				"sealed_tier": str(record["sealed_tier"]), "search_tier": str(tier),
			}, _current_cycle())
		_submit_trust_for(context, found)
	_resolving = false
	if bus != null and bus.has_signal("investigation_resolved"):
		bus.investigation_resolved.emit(context, found.size())
	return {"context": context, "found": found, "stage": stage}


## The world half: which zone to search for this context. A zone id
## searches itself; an NPC id searches the NPC's current zone (what
## they'd point at); anything else (a district, an incident id) has no
## world footprint to search yet — that's Spec 22/27's side.
func _resolve_world_search(context: StringName, tier: StringName) -> Array[Dictionary]:
	var evidence := get_tree().root.get_node_or_null("Evidence")
	if evidence == null or not evidence.has_method("resolve_search"):
		return []
	var zone_id := _zone_for_context(context)
	if zone_id == "":
		return []
	return evidence.resolve_search(zone_id, tier)


func _zone_for_context(context: StringName) -> String:
	var zones := get_tree().root.get_node_or_null("Zones")
	if zones != null and bool(zones.has_zone(str(context))):
		return str(context)
	var npcs := get_tree().root.get_node_or_null("Npcs")
	if npcs != null and bool(npcs.is_known_npc(context)):
		return str(npcs.get_current_zone(context))
	return ""


func _location_of(context: StringName) -> StringName:
	var zone_id := _zone_for_context(context)
	return StringName(zone_id) if zone_id != "" else StringName()


## Exactly one Trust event per resolution that found real evidence, with
## a reason built from what was found (Spec 19: reasons, never numbers).
func _submit_trust_for(context: StringName, found: Array[Dictionary]) -> void:
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust == null or not trust.has_method("submit_trust_event"):
		return
	var zones := get_tree().root.get_node_or_null("Zones")
	var where := str(context)
	if zones != null and zones.has_method("get_display_name") and bool(zones.has_zone(str(context))):
		where = str(zones.get_display_name(str(context)))
	var reason := "A search of %s found %d fresh cut%s in restricted rock" % [where, found.size(), "" if found.size() == 1 else "s"]
	trust.submit_trust_event(&"evidence_found", get_found_evidence_trust_delta(), reason)


func _current_cycle() -> int:
	var clock := get_tree().root.get_node_or_null("Clock")
	return int(clock.get_cycles_elapsed()) if clock != null else -1


# --- Build Bible Spec 02 uniform SaveLoad contract — nothing to save ----------------------

func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass


func reset_all() -> void:
	_resolving = false


# --- Debug -----------------------------------------------------------------------------------

func _debug_suspicion(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: suspicion <context>"
	var context := StringName(args[0])
	return "%s: suspicion %.1f / threshold %.1f — stage %s" % [context, get_suspicion(context), get_threshold(context), get_investigation_stage(context)]


func _debug_investigate(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: investigate <context> <reason...>"
	var context := StringName(args[0])
	var result := trigger_investigation(context, " ".join(args.slice(1)))
	return "Investigated %s: %s (%d found)" % [context, result["stage"], (result["found"] as Array).size()]
