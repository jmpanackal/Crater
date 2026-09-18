extends Node
## Krater Forbidden Builds (autoload: ForbiddenBuilds).
## Build Bible Spec 28 (docs/build-bible/specs/28-forbidden-builds.md — AI
## draft pending USER review).
##
## The secret-progression payoff (canon §29/§67): a Known + Understood +
## Available Forbidden design becomes a graft at the private workspace.
## Requirements are the technology's own (Spec 25) — Material, Component,
## residence, and diverted District Output from the concealed stockpile
## (Spec 26) — so CapabilityWeb's Available already answers "buildable
## right now". build() is atomic: refuses with a distinct reason, or
## consumes exactly the recipe and calls Rig.graft() (Spec 14 enforces the
## workspace + Mid Reach gate). Fabrication is immediate for the slice
## (tuning has fabrication_cycles for when major builds should cost civic
## time).
##
## Owns per-graft concealment tiers (§67: same Basic/Improved/Advanced
## model as the workspace, tracked independently). Discovery is examiner-
## restricted (Spec 20): examine() by anyone who isn't an authority finds
## nothing; an authority's examination finds a graft when its tier rank >=
## the graft's concealment rank -> graft_exposed fact + one Trust event.
##
## Access via get_tree().root.get_node("ForbiddenBuilds") (no class_name).

const TUNING_DOMAIN := "forbidden_tuning"
const FACT_FORBIDDEN_BUILD := &"forbidden_build"
const FACT_GRAFT_EXPOSED := &"graft_exposed"

const CONCEAL_ORDER: Array[StringName] = [&"basic", &"improved", &"advanced"]

var _graft_concealment: Dictionary = {}  # design_id -> StringName tier


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("build_forbidden", "build_forbidden <design_id> — build a Forbidden design at the workspace.", _debug_build)
	console.register_command("conceal_graft", "conceal_graft <design_id> — improve a graft's concealment one tier (Tallies).", _debug_conceal)
	console.register_command("examine_graft", "examine_graft <design_id> [basic|improved|advanced] — an AUTHORITY examines the player.", _debug_examine)


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


# --- Building --------------------------------------------------------------------------

## {"ok", "reason"} — distinct reasons: unknown_design / not_a_forbidden_design
## / not_at_workspace / residence_tier_too_low / already_grafted /
## not_available (with CapabilityWeb's missing list attached).
func can_build(design_id: StringName) -> Dictionary:
	var web := get_tree().root.get_node_or_null("CapabilityWeb")
	var rig := get_tree().root.get_node_or_null("Rig")
	if web == null or rig == null:
		return {"ok": false, "reason": "system_missing"}
	if not bool(web.is_known_tech(design_id)):
		return {"ok": false, "reason": "unknown_design"}
	if web.get_kind(design_id) != &"forbidden_design":
		return {"ok": false, "reason": "not_a_forbidden_design"}
	var gate: Dictionary = rig.can_graft_at_current_location()
	if not bool(gate["ok"]):
		return {"ok": false, "reason": str(gate["reason"])}
	if bool(rig.is_grafted(design_id)):
		return {"ok": false, "reason": "already_grafted"}
	var state: Dictionary = web.get_state(design_id)
	if not bool(state["available"]):
		return {"ok": false, "reason": "not_available", "missing": state["missing"]}
	return {"ok": true, "reason": ""}


## Consumes exactly the recipe (Materials, Components, diverted output)
## and installs the graft. {"success", "reason", "consumed"}.
func build(design_id: StringName) -> Dictionary:
	var check := can_build(design_id)
	if not bool(check["ok"]):
		return {"success": false, "reason": str(check["reason"]), "consumed": {}, "missing": check.get("missing", [])}
	var web := get_tree().root.get_node_or_null("CapabilityWeb")
	var rig := get_tree().root.get_node_or_null("Rig")
	var storage := get_tree().root.get_node_or_null("Storage")
	var req: Dictionary = web.get_requirements(design_id)
	var consumed := {"materials": {}, "components": [], "diverted_output": {}}
	# All checks passed via Available; apply the consumption in one go.
	for key: Variant in (req["materials"] as Dictionary).keys():
		var amount := int((req["materials"] as Dictionary)[key])
		if amount > 0 and storage != null and bool(storage.withdraw_material(StringName(str(key)), amount)):
			(consumed["materials"] as Dictionary)[str(key)] = amount
	for c: Variant in (req["components"] as Array):
		if storage == null:
			break
		var owned: Array[Dictionary] = storage.get_components(StringName(str(c)))
		if not owned.is_empty() and bool(storage.remove_component(int(owned[0]["uid"]))):
			(consumed["components"] as Array).append(str(c))
	for key: Variant in (req["diverted_output"] as Dictionary).keys():
		var units := int((req["diverted_output"] as Dictionary)[key])
		if units > 0 and storage != null and bool(storage.withdraw_concealed(StringName(str(key)), units)):
			(consumed["diverted_output"] as Dictionary)[str(key)] = units
	var grafted: Dictionary = rig.graft(design_id)
	if not bool(grafted["success"]):
		return {"success": false, "reason": str(grafted["reason"]), "consumed": consumed}
	_graft_concealment[design_id] = CONCEAL_ORDER[0]
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log != null:
		var witnesses: Array[String] = []
		fact_log.record(FACT_FORBIDDEN_BUILD, fact_log.SUBJECT_PLAYER, StringName(), witnesses, {"design_id": str(design_id), "consumed": consumed.duplicate(true)}, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("forbidden_built"):
		bus.forbidden_built.emit(design_id)
	return {"success": true, "reason": "", "consumed": consumed}


# --- Graft concealment (§67) -------------------------------------------------------------

func get_graft_concealment(design_id: StringName) -> StringName:
	var rig := get_tree().root.get_node_or_null("Rig")
	if rig == null or not bool(rig.is_grafted(design_id)):
		return &""
	return StringName(str(_graft_concealment.get(design_id, CONCEAL_ORDER[0])))


func concealment_rank(tier: StringName) -> int:
	return maxi(0, CONCEAL_ORDER.find(tier))


## One tier better, at the workspace, for Tallies. {"success", "reason"}.
func improve_graft_concealment(design_id: StringName) -> Dictionary:
	var current := get_graft_concealment(design_id)
	if current == &"":
		return {"success": false, "reason": "not_grafted"}
	var rig := get_tree().root.get_node_or_null("Rig")
	var gate: Dictionary = rig.can_graft_at_current_location()
	if not bool(gate["ok"]):
		return {"success": false, "reason": str(gate["reason"])}
	if current == CONCEAL_ORDER[-1]:
		return {"success": false, "reason": "already_advanced"}
	var wallet := get_tree().root.get_node_or_null("Wallet")
	var price := int(_tune("conceal_graft_tallies", 12))
	if wallet == null or not bool(wallet.spend(price, "Concealed a graft better")):
		return {"success": false, "reason": "insufficient_tallies"}
	_graft_concealment[design_id] = CONCEAL_ORDER[concealment_rank(current) + 1]
	return {"success": true, "reason": ""}


## Examiner-restricted discovery (Spec 20). A non-authority finds nothing,
## ever. An authority's examination at `examination_tier` finds the graft
## when its rank >= the graft's concealment rank -> graft_exposed fact +
## one Trust event. {"found", "outcome"}.
func examine(design_id: StringName, examiner_is_authority: bool, examination_tier: StringName = &"basic") -> Dictionary:
	var concealment := get_graft_concealment(design_id)
	if concealment == &"":
		return {"found": false, "outcome": &"nothing_to_find"}
	if not examiner_is_authority:
		return {"found": false, "outcome": &"not_recognised"}
	if concealment_rank(examination_tier) < concealment_rank(concealment):
		return {"found": false, "outcome": &"concealed"}
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log != null:
		var witnesses: Array[String] = []
		fact_log.record(FACT_GRAFT_EXPOSED, fact_log.SUBJECT_PLAYER, StringName(), witnesses, {"design_id": str(design_id), "examination_tier": str(examination_tier), "concealment": str(concealment)}, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var trust := get_tree().root.get_node_or_null("Trust")
	if trust != null:
		var web := get_tree().root.get_node_or_null("CapabilityWeb")
		var display := str(web.get_display_name(design_id)) if web != null else str(design_id)
		trust.submit_trust_event(&"graft_exposed", float(_tune("graft_exposed_trust_delta", -20.0)), "An examination found the %s bound into your body" % display)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("graft_exposed"):
		bus.graft_exposed.emit(design_id)
	return {"found": true, "outcome": &"exposed"}


# --- Build Bible Spec 02 uniform SaveLoad contract ----------------------------------------

func save_state() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _graft_concealment.keys():
		out[str(key)] = str(_graft_concealment[key])
	return {"graft_concealment": out}


func load_state(data: Dictionary) -> void:
	_graft_concealment.clear()
	var tiers: Variant = data.get("graft_concealment", {})
	if typeof(tiers) == TYPE_DICTIONARY:
		for key: Variant in (tiers as Dictionary).keys():
			var tier := StringName(str((tiers as Dictionary)[key]))
			if CONCEAL_ORDER.has(tier):
				_graft_concealment[StringName(str(key))] = tier


func reset_all() -> void:
	_graft_concealment.clear()


# --- Debug -------------------------------------------------------------------------------------

func _debug_build(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: build_forbidden <design_id>"
	var result := build(StringName(args[0]))
	if not bool(result["success"]):
		return "Refused: %s%s" % [result["reason"], "" if (result.get("missing", []) as Array).is_empty() else " — missing: " + ", ".join(PackedStringArray(result["missing"]))]
	return "Built %s — consumed %s" % [args[0], result["consumed"]]


func _debug_conceal(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: conceal_graft <design_id>"
	var result := improve_graft_concealment(StringName(args[0]))
	return "Concealment now %s" % get_graft_concealment(StringName(args[0])) if bool(result["success"]) else "Refused: %s" % result["reason"]


func _debug_examine(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: examine_graft <design_id> [tier]"
	var tier := StringName(args[1].to_lower()) if args.size() > 1 else &"basic"
	var result := examine(StringName(args[0]), true, tier)
	return "Examination (%s): %s" % [tier, result["outcome"]]
