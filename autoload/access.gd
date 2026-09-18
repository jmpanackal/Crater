extends Node
## Krater Access / Gates (autoload: Access).
## Build Bible Spec 31 (docs/build-bible/specs/31-access-gates.md — AI draft
## pending USER review).
##
## What higher Trust, status and story clearance BUY (canon §17): a gate
## (access_gate.gd, a solid StaticBody2D in the scene) declares its own
## requirements — a Trust standing, a story flag, a residence tier — and
## this system decides, on every event that could change the answer
## (trust_changed, story_flag_set, residence_changed), whether it stands
## open. No polling. Owns no persistent state: open/closed is derived.
##
## Explanation without numbers (§17): can_pass() carries a human-readable
## reason the gate's prompt shows — never "Trust 70/100".
##
## Bypassing a closed gate (digging around it, dropping in) is a
## restricted entry: the gate's "beyond" area reports it here, which logs
## a restricted_entry fact and hands the witness question to Perception
## (Spec 17) — canon §19's "seen entering restricted tunnel".
##
## Access via get_tree().root.get_node("Access") (no class_name).

const FACT_RESTRICTED_ENTRY := &"restricted_entry"
const FACT_SEEN_ENTERING := &"seen_entering_restricted_area"

var _gates: Dictionary = {}  # gate_id -> gate node


func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		for sig in ["trust_changed", "story_flag_set", "residence_changed"]:
			if bus.has_signal(sig):
				bus.connect(sig, _on_anything_changed)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("gates", "gates — every registered gate, open or closed, and why.", _debug_gates)


func _on_anything_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	refresh()


# --- Gates -----------------------------------------------------------------------------

func register_gate(gate: Node) -> void:
	var id := StringName(str(gate.get("gate_id")))
	if id == &"":
		push_warning("Access: gate '%s' has no gate_id — not registered" % gate.name)
		return
	_gates[id] = gate
	_apply(gate)


func unregister_gate(gate: Node) -> void:
	var id := StringName(str(gate.get("gate_id")))
	if _gates.get(id, null) == gate:
		_gates.erase(id)


func get_gate_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in _gates.keys():
		if is_instance_valid(_gates[key]):
			out.append(key)
	return out


func get_gate(gate_id: StringName) -> Node:
	var gate: Variant = _gates.get(gate_id, null)
	return gate if gate != null and is_instance_valid(gate) else null


## Re-evaluates every gate against current Trust / Story / Homes state.
func refresh() -> void:
	for key: Variant in _gates.keys():
		var gate: Variant = _gates[key]
		if gate != null and is_instance_valid(gate):
			_apply(gate)


func _apply(gate: Node) -> void:
	var verdict := evaluate(_requirements_of(gate))
	if gate.has_method("set_open"):
		gate.set_open(bool(verdict["ok"]))


func is_open(gate_id: StringName) -> bool:
	return bool(can_pass(gate_id)["ok"])


## {"ok", "reason", "explanation"} for a registered gate.
func can_pass(gate_id: StringName) -> Dictionary:
	var gate := get_gate(gate_id)
	if gate == null:
		return {"ok": false, "reason": "unknown_gate", "explanation": "There is no such way."}
	return evaluate(_requirements_of(gate))


func _requirements_of(gate: Node) -> Dictionary:
	return {
		"trust": StringName(str(gate.get("required_trust"))),
		"flag": StringName(str(gate.get("required_flag"))),
		"residence": StringName(str(gate.get("required_residence"))),
		"explanation": str(gate.get("explanation")),
	}


## The rule itself, usable without a gate node: requirements =
## {"trust": standing id, "flag": story flag, "residence": tier} ("" =
## none). Reasons: trust_too_low / clearance_missing / residence_too_low.
func evaluate(requirements: Dictionary) -> Dictionary:
	var trust_needed := StringName(str(requirements.get("trust", "")))
	if trust_needed != &"":
		var trust := get_tree().root.get_node_or_null("Trust")
		if trust != null and not _standing_at_least(trust, trust_needed):
			return {"ok": false, "reason": "trust_too_low", "explanation": _explain(requirements, "The Wardens don't pass anyone the Hollow doesn't yet rely on.")}
	var flag := StringName(str(requirements.get("flag", "")))
	if flag != &"":
		var story := get_tree().root.get_node_or_null("Story")
		if story == null or not bool(story.has_flag(flag)):
			return {"ok": false, "reason": "clearance_missing", "explanation": _explain(requirements, "You have no clearance for this way.")}
	var residence := StringName(str(requirements.get("residence", "")))
	if residence != &"":
		var homes := get_tree().root.get_node_or_null("Homes")
		if homes == null or not bool(homes.has_at_least(residence)):
			return {"ok": false, "reason": "residence_too_low", "explanation": _explain(requirements, "Residents only — this ward isn't yours to enter.")}
	return {"ok": true, "reason": "", "explanation": ""}


func _explain(requirements: Dictionary, fallback: String) -> String:
	var authored := str(requirements.get("explanation", ""))
	return authored if authored != "" else fallback


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


# --- Restricted entry (the gate's "beyond" area reports it) -------------------------------

## The player got past a CLOSED gate. Logs the fact and lets Perception
## decide whether anyone saw (canon §19: "seen entering restricted tunnel").
## Returns who witnessed it.
func report_restricted_entry(gate_id: StringName, world_pos: Vector2) -> Array[StringName]:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	var zones := get_tree().root.get_node_or_null("Zones")
	var location := StringName(str(zones.get_zone_at(world_pos))) if zones != null else StringName()
	if fact_log != null:
		var witnesses: Array[String] = []
		fact_log.record(FACT_RESTRICTED_ENTRY, fact_log.SUBJECT_PLAYER, location, witnesses, {"gate_id": str(gate_id), "position": [world_pos.x, world_pos.y]}, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var perception := get_tree().root.get_node_or_null("Perception")
	if perception == null:
		return []
	return perception.flag_witnessable("restricted_entry:%s" % str(gate_id), world_pos, FACT_SEEN_ENTERING, {"gate_id": str(gate_id)})


# --- Build Bible Spec 02 uniform SaveLoad contract — nothing to save --------------------------

func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass


func reset_all() -> void:
	refresh()


# --- Debug -------------------------------------------------------------------------------------

func _debug_gates(_args: Array[String]) -> String:
	if _gates.is_empty():
		return "No gates registered in the current scene."
	var lines: PackedStringArray = []
	for id: StringName in get_gate_ids():
		var verdict := can_pass(id)
		lines.append("  %s — %s%s" % [id, "OPEN" if bool(verdict["ok"]) else "closed", "" if bool(verdict["ok"]) else " (%s: %s)" % [verdict["reason"], verdict["explanation"]]])
	return "\n".join(lines)
