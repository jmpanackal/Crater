extends Node
## Krater Dialogue + Questioning (autoload: Dialogue).
## Build Bible Spec 21 (docs/build-bible/specs/21-dialogue-questioning.md).
##
## Canon §18's contextual lying model, as the contract the dependency map
## names: "Dialogue writes a claim_made fact; contradiction checks are
## derived; exposure emits a fact that Trust reads." There is no generic
## Lie button — a claim is whatever an authored questioning moment
## commits the player to.
##
## OWNS NO STATE: claims live as `claim_made` facts in the Fact Log
## (Spec 01); everything else here is derived from the log on demand.
##
## Confirmed choices, implemented literally:
## - Every claim carries a `trust_relevant` tag (option A). The fact is
##   written either way (the world remembers everything said), but only a
##   trust_relevant claim can ever feed a Trust consequence — a hard gate.
## - Claims check only against the Fact Log's existing record (option B):
##   no predictive claims resolving against future state in this slice.
## - Deflection and partial truth are authoring shapes (option A): a
##   partial truth is just a claim; pure deflection writes NO fact, so
##   there is nothing to contradict or expose — no third branch.
## - Exposure needs an in-fiction moment (option A): a contradiction being
##   derivable does nothing by itself. expose_claim() is called by
##   Investigation (Spec 20) on a conflicting resolution, or by an
##   authored confrontation node. Then, and only then, a trust_relevant +
##   contradicted claim submits exactly one `exposed_lie` Trust event.
##
## What a claim ASSERTS is data on the fact (context["asserts"]), checked
## by is_contradicted():
##   ASSERT_WAS_NOT_AT      {"location": zone_id, "cycle": n}
##       contradicted by any player fact at that location in that cycle
##       (a Witness fact placing them there, evidence found there, ...).
##   ASSERT_ATTENDED_RITUAL {"cycle": n}
##       contradicted by a ritual_missed fact for that cycle (Spec 15).
##   ASSERT_DID_NOT         {"fact_type": t, "cycle": n}
##       contradicted by any player fact of that type in that cycle.
## Bookkeeping facts (claims, exposures, search requests, found_nothing)
## never count as contradictions.
##
## Access via get_tree().root.get_node("Dialogue") (no class_name,
## matching the existing project convention — see resources.gd).

const TUNING_DOMAIN := "dialogue_tuning"

const FACT_CLAIM_MADE := &"claim_made"
const FACT_CLAIM_EXPOSED := &"claim_exposed_as_lie"

const ASSERT_WAS_NOT_AT := &"was_not_at"
const ASSERT_ATTENDED_RITUAL := &"attended_ritual"
const ASSERT_DID_NOT := &"did_not"

const TRUST_EVENT_EXPOSED_LIE := &"exposed_lie"

## Facts that are about the record itself, never about what the player did.
const BOOKKEEPING_FACTS: Array[StringName] = [
	&"claim_made", &"claim_exposed_as_lie", &"search_requested", &"found_nothing",
]


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("claims", "claims — every claim made, whether it's contradicted by the record, and whether it was exposed.", _debug_claims)
	console.register_command("expose", "expose <claim_id> — authored confrontation: expose a claim now (Trust moves only if trust-relevant AND contradicted).", _debug_expose)


func get_exposed_lie_trust_delta() -> float:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return -12.0
	var tuning: Resource = registry.get_domain(TUNING_DOMAIN)
	return float(tuning.exposed_lie_trust_delta) if tuning != null else -12.0


# --- The contract ---------------------------------------------------------------------

## Commits the player to a claim: logs ONE claim_made fact. `context`
## must carry "asserts" (an ASSERT_* id) plus what that assertion needs;
## "cycle" defaults to the current cycle; "text" is the human-readable
## line, used in the exposure reason. Refused (empty Dictionary, nothing
## logged) for an empty id or an unknown assertion. Deflection is simply
## NOT calling this — nothing is committed to.
func make_claim(claim_id: StringName, trust_relevant: bool, context: Dictionary = {}) -> Dictionary:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null or claim_id == &"":
		return {}
	var asserts := StringName(str(context.get("asserts", "")))
	if not [ASSERT_WAS_NOT_AT, ASSERT_ATTENDED_RITUAL, ASSERT_DID_NOT].has(asserts):
		push_warning("Dialogue: claim '%s' has no checkable assertion (%s) — refused" % [claim_id, asserts])
		return {}
	var full := context.duplicate(true)
	full["claim_id"] = str(claim_id)
	full["trust_relevant"] = trust_relevant
	full["asserts"] = str(asserts)
	if not full.has("cycle"):
		full["cycle"] = _current_cycle()
	var location := StringName(str(full.get("location", "")))
	var witnesses: Array[String] = []
	return fact_log.record(FACT_CLAIM_MADE, fact_log.SUBJECT_PLAYER, location, witnesses, full, _current_cycle())


## The latest claim_made fact for this id, or {}.
func get_claim(claim_id: StringName) -> Dictionary:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return {}
	var latest: Dictionary = {}
	for fact: Dictionary in fact_log.get_by_type(FACT_CLAIM_MADE):
		if str((fact["context"] as Dictionary).get("claim_id", "")) != str(claim_id):
			continue
		if latest.is_empty() or int(fact["index"]) > int(latest["index"]):
			latest = fact
	return latest


func has_claim(claim_id: StringName) -> bool:
	return not get_claim(claim_id).is_empty()


func is_trust_relevant(claim_id: StringName) -> bool:
	var claim := get_claim(claim_id)
	return not claim.is_empty() and bool((claim["context"] as Dictionary).get("trust_relevant", false))


## Derived: does the Fact Log's actual record disagree with the claim?
## False for a claim that was never made. Nothing happens because of this
## being true — exposure is a separate, in-fiction step.
func is_contradicted(claim_id: StringName) -> bool:
	var claim := get_claim(claim_id)
	if claim.is_empty():
		return false
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return false
	var ctx: Dictionary = claim["context"]
	var asserts := StringName(str(ctx.get("asserts", "")))
	var cycle := int(ctx.get("cycle", -1))
	for fact: Dictionary in fact_log.get_all():
		if BOOKKEEPING_FACTS.has(fact["type"]) or str(fact["subject"]) != fact_log.SUBJECT_PLAYER:
			continue
		if int(fact["cycle"]) != cycle:
			continue
		match asserts:
			ASSERT_WAS_NOT_AT:
				if StringName(str(fact["location"])) == StringName(str(ctx.get("location", ""))) and str(ctx.get("location", "")) != "":
					return true
			ASSERT_ATTENDED_RITUAL:
				if fact["type"] == &"ritual_missed":
					return true
			ASSERT_DID_NOT:
				if fact["type"] == StringName(str(ctx.get("fact_type", ""))):
					return true
	return false


func is_exposed(claim_id: StringName) -> bool:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return false
	for fact: Dictionary in fact_log.get_by_type(FACT_CLAIM_EXPOSED):
		if str((fact["context"] as Dictionary).get("claim_id", "")) == str(claim_id):
			return true
	return false


## The in-fiction moment: Investigation resolving a conflicting search, or
## an authored confrontation, surfaces the claim. If it IS contradicted,
## logs one claim_exposed_as_lie fact (referencing the claim, so writers
## can follow it) and — only if trust_relevant — submits exactly one
## `exposed_lie` Trust event. A claim is exposed at most once. Returns
## whether a Trust event was submitted.
func expose_claim(claim_id: StringName) -> bool:
	var claim := get_claim(claim_id)
	if claim.is_empty() or is_exposed(claim_id) or not is_contradicted(claim_id):
		return false
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return false
	var ctx: Dictionary = claim["context"]
	var relevant := bool(ctx.get("trust_relevant", false))
	var witnesses: Array[String] = []
	fact_log.record(FACT_CLAIM_EXPOSED, fact_log.SUBJECT_PLAYER, StringName(str(claim["location"])), witnesses, {
		"claim_id": str(claim_id), "claim_index": int(claim["index"]), "trust_relevant": relevant,
	}, _current_cycle())
	if not relevant:
		return false
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust == null or not trust.has_method("submit_trust_event"):
		return false
	var text := str(ctx.get("text", claim_id))
	return bool(trust.submit_trust_event(TRUST_EVENT_EXPOSED_LIE, get_exposed_lie_trust_delta(), "Your claim came apart: \"%s\"" % text))


## Investigation's hook (Spec 20 -> 21): a search of `location` that
## found real evidence exposes every contradicted claim about that place.
## Returns how many Trust events were submitted.
func expose_contradicted_claims_at(location: StringName) -> int:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null or location == &"":
		return 0
	var exposed := 0
	var seen: Array[String] = []
	for fact: Dictionary in fact_log.get_by_type(FACT_CLAIM_MADE):
		var ctx: Dictionary = fact["context"]
		var claim_id := str(ctx.get("claim_id", ""))
		if claim_id == "" or seen.has(claim_id):
			continue
		seen.append(claim_id)
		if StringName(str(ctx.get("location", ""))) != location:
			continue
		if expose_claim(StringName(claim_id)):
			exposed += 1
	return exposed


func _current_cycle() -> int:
	var clock := get_tree().root.get_node_or_null("Clock")
	return int(clock.get_cycles_elapsed()) if clock != null else -1


# --- Build Bible Spec 02 uniform SaveLoad contract — nothing to save ------------------------

func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass


func reset_all() -> void:
	pass


# --- Debug -----------------------------------------------------------------------------------

func _debug_claims(_args: Array[String]) -> String:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	if fact_log == null:
		return "FactLog missing."
	var lines: PackedStringArray = []
	var seen: Array[String] = []
	for fact: Dictionary in fact_log.get_by_type(FACT_CLAIM_MADE):
		var ctx: Dictionary = fact["context"]
		var claim_id := str(ctx.get("claim_id", ""))
		if seen.has(claim_id):
			continue
		seen.append(claim_id)
		lines.append("  %s [%s] asserts %s (cycle %s) — %s%s" % [
			claim_id, "trust-relevant" if bool(ctx.get("trust_relevant", false)) else "not trust-relevant",
			ctx.get("asserts", "?"), ctx.get("cycle", "?"),
			"CONTRADICTED" if is_contradicted(StringName(claim_id)) else "holds so far",
			", exposed" if is_exposed(StringName(claim_id)) else "",
		])
	return "No claims made." if lines.is_empty() else "\n".join(lines)


func _debug_expose(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: expose <claim_id>"
	var id := StringName(args[0])
	if not has_claim(id):
		return "No claim '%s'." % id
	var moved := expose_claim(id)
	return "Exposed %s — Trust %s" % [id, "moved (exposed_lie)" if moved else "unchanged (not contradicted, not trust-relevant, or already exposed)"]
