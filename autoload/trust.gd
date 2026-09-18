extends Node
## Krater Trust (+ reasons view) (autoload: Trust).
## Build Bible Spec 19 (docs/build-bible/specs/19-trust.md).
##
## The single global Trust value (G16) and its human-readable reasons
## list, implementing canon §17 literally:
## - Trust changes ONLY through a submitted, reasoned event (confirmed
##   option A): submit_trust_event(type, delta, reason_text). No other
##   system writes the value. A reason is REQUIRED — an empty one is
##   refused loudly, enforcing the CUT list's ban on unexplained
##   modifiers at the contract level, not by convention.
## - The internal value is a plain scalar (option A), for tuning and
##   systemic logic only. The player-facing query get_trust() returns one
##   of a small number of qualitative STANDING STATES, never the number
##   (§17: no "73 / 100").
## - Standing thresholds live in the Tuning Registry (option A):
##   tuning/trust_tuning.tres.
## - The reasons list is a capped, recent-window display log (option A) —
##   "why does society (dis)trust me right now"; the permanent record is
##   the Fact Log (Spec 01).
## - get_trust(context) is context-aware from the start (G16) so group-
##   specific readings (Wardens vs. residents) can be added later without
##   breaking the contract; Act 1 only uses the global context.
##
## Who calls submit_trust_event: the systems that DETERMINE something
## Trust-worthy happened — Investigation resolving real evidence (Spec
## 20), Jobs' broken commitments (Spec 24), Dialogue's exposed lies (Spec
## 21). Ordinary job completion earns Tallies (Spec 23) and must never
## come through here (§17). Trust never suppresses evidence or suspicion
## and they never suppress it — independent by design.
##
## The retired community.gd Trust int (miss/theft penalties, the HUD's
## TrustLabel) is still the legacy owner of the retired mechanics until
## their own specs migrate them; this system does not reach into it.
##
## Access via get_tree().root.get_node("Trust") (no class_name, matching
## the existing project convention — see resources.gd).

const TUNING_DOMAIN := "trust_tuning"
const CONTEXT_GLOBAL := &"global"

var _value: float = 50.0
## Each entry: {"index": int, "type": StringName, "delta": float,
## "reason": String, "cycle": int}. Newest last, capped.
var _reasons: Array[Dictionary] = []
var _next_reason_index: int = 1


func _ready() -> void:
	_value = get_default_trust()
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("trust", "trust — standing, internal value, and the recent reasons list.", _debug_trust)
	console.register_command(
		"trust_event",
		"trust_event <type> <delta> <reason...> — submit a reasoned Trust event (the only way Trust moves).",
		_debug_trust_event
	)


# --- Tuning ---------------------------------------------------------------------

func get_default_trust() -> float:
	var tuning := _tuning()
	return float(tuning.default_trust) if tuning != null else 50.0


func get_min_trust() -> float:
	var tuning := _tuning()
	return float(tuning.min_trust) if tuning != null else 0.0


func get_max_trust() -> float:
	var tuning := _tuning()
	return float(tuning.max_trust) if tuning != null else 100.0


func get_reasons_capacity() -> int:
	var tuning := _tuning()
	return maxi(1, int(tuning.reasons_capacity)) if tuning != null else 8


## The standing ladder from tuning: [{"id", "label", "threshold"}], ascending.
func get_standing_ladder() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tuning := _tuning()
	if tuning == null:
		return [{"id": &"accepted", "label": "Accepted", "threshold": 0.0}]
	var ids: Array = tuning.standing_ids
	var labels: Array = tuning.standing_labels
	var thresholds: Array = tuning.standing_thresholds
	for i in range(ids.size()):
		out.append({
			"id": StringName(str(ids[i])),
			"label": str(labels[i]) if i < labels.size() else str(ids[i]).capitalize(),
			"threshold": float(thresholds[i]) if i < thresholds.size() else 0.0,
		})
	return out


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- The contract ------------------------------------------------------------------

## The ONLY way Trust moves. Applies `delta` (clamped to the tuned range),
## appends the reason, emits EventBus.trust_changed. Refuses — false, no
## mutation, loud in debug builds — when reason_text is empty: an
## unexplained modifier is exactly what §17 cuts. Returns whether applied.
func submit_trust_event(type: StringName, delta: float, reason_text: String) -> bool:
	var reason := reason_text.strip_edges()
	if reason == "":
		push_error("Trust: submit_trust_event(%s, %s) refused — reason_text is required (canon §17: no unexplained modifiers)" % [type, delta])
		return false
	if type == &"":
		push_error("Trust: submit_trust_event refused — event type is required")
		return false
	var before := _value
	_value = clampf(_value + delta, get_min_trust(), get_max_trust())
	var clock := get_tree().root.get_node_or_null("Clock")
	_reasons.append({
		"index": _next_reason_index,
		"type": type,
		"delta": delta,
		"reason": reason,
		"cycle": int(clock.get_cycles_elapsed()) if clock != null else -1,
	})
	_next_reason_index += 1
	_trim_reasons()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.trust_changed.emit(get_trust(), _value - before, reason)
	return true


## The player-facing query: a qualitative standing state id, never the
## number. `context` is accepted (G16) but only the global context is
## meaningful in Act 1 — every context reads the one global value today.
func get_trust(_context: StringName = CONTEXT_GLOBAL) -> StringName:
	return _standing_for(_value)["id"]


func get_standing_label(_context: StringName = CONTEXT_GLOBAL) -> String:
	return str(_standing_for(_value)["label"])


## Internal scalar for tuning/systemic logic (threshold modulation in
## Spec 20, access gates in Spec 31). Not for UI presentation.
func get_trust_value() -> float:
	return _value


## Copies of the recent reasons, oldest first.
func get_trust_reasons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in _reasons:
		out.append(entry.duplicate())
	return out


func _standing_for(value: float) -> Dictionary:
	var ladder := get_standing_ladder()
	var current: Dictionary = ladder[0]
	for step: Dictionary in ladder:
		if value >= float(step["threshold"]):
			current = step
	return current


func _trim_reasons() -> void:
	var capacity := get_reasons_capacity()
	while _reasons.size() > capacity:
		_reasons.pop_front()


# --- Build Bible Spec 02 uniform SaveLoad contract --------------------------------------

func save_state() -> Dictionary:
	var reasons: Array = []
	for entry: Dictionary in _reasons:
		reasons.append({
			"index": int(entry["index"]),
			"type": str(entry["type"]),
			"delta": float(entry["delta"]),
			"reason": str(entry["reason"]),
			"cycle": int(entry["cycle"]),
		})
	return {"value": _value, "reasons": reasons, "next_reason_index": _next_reason_index}


func load_state(data: Dictionary) -> void:
	_value = clampf(float(data.get("value", get_default_trust())), get_min_trust(), get_max_trust())
	_reasons.clear()
	var highest := 0
	var reasons: Variant = data.get("reasons", [])
	if typeof(reasons) == TYPE_ARRAY:
		for entry: Variant in (reasons as Array):
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var e: Dictionary = entry
			var index := int(e.get("index", 0))
			highest = maxi(highest, index)
			_reasons.append({
				"index": index,
				"type": StringName(str(e.get("type", ""))),
				"delta": float(e.get("delta", 0.0)),
				"reason": str(e.get("reason", "")),
				"cycle": int(e.get("cycle", -1)),
			})
	_trim_reasons()
	_next_reason_index = maxi(int(data.get("next_reason_index", 1)), highest + 1)


func reset_all() -> void:
	_value = get_default_trust()
	_reasons.clear()
	_next_reason_index = 1


# --- Debug ---------------------------------------------------------------------------------

func _debug_trust(_args: Array[String]) -> String:
	var lines: PackedStringArray = []
	lines.append("Standing: %s (%s) — internal %.1f" % [get_standing_label(), get_trust(), _value])
	if _reasons.is_empty():
		lines.append("No recent reasons.")
	for entry: Dictionary in _reasons:
		lines.append("  [%s, cycle %d] %+.1f — %s" % [entry["type"], int(entry["cycle"]), float(entry["delta"]), entry["reason"]])
	return "\n".join(lines)


func _debug_trust_event(args: Array[String]) -> String:
	if args.size() < 3:
		return "Usage: trust_event <type> <delta> <reason...>"
	var reason := " ".join(args.slice(2))
	if not submit_trust_event(StringName(args[0]), float(args[1]), reason):
		return "Refused — a type and a reason are required."
	return "Trust is now %s (%.1f): %s" % [get_standing_label(), _value, reason]
