extends Node
## Krater Tallies (autoload: Wallet).
## Build Bible Spec 23 (docs/build-bible/specs/23-tallies-orders.md).
##
## The legitimate public-progression currency (canon §16): transactional
## compensation for useful civic work — explicitly NOT Trust. Its own small
## autoload, separate from Trust (Spec 23, confirmed option A), reusing
## Trust's exact contract shape (option A): earn(amount, reason) /
## spend(amount, reason) -> bool, called by whichever system determined
## Tallies should move (primarily Jobs, Spec 24, at settlement; Orders,
## Spec 23, on a purchase). Wallet never computes its own amounts or
## reaches into anyone's data. A reason is REQUIRED — an unexplained
## earn/spend fails loudly (Spec 23's failure case, carrying Spec 19's
## discipline over: "Tallies should remain understandable").
##
## The retired prototype wallet still
## pays the retired work-order loop and HUD until Spec 24 moves job
## settlement here; this system does not reach into it.
##
## Access via get_tree().root.get_node("Wallet") (no class_name, matching
## the existing project convention — see resources.gd).

const TUNING_DOMAIN := "wallet_tuning"

var _balance: int = 0
## Each entry: {"index": int, "delta": int, "reason": String, "cycle": int}.
var _reasons: Array[Dictionary] = []
var _next_reason_index: int = 1


func _ready() -> void:
	_balance = get_starting_tallies()
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("tallies", "tallies — balance and the recent earn/spend reasons.", _debug_tallies)
	console.register_command("earn_tallies", "earn_tallies <amount> <reason...> — earn Tallies with a reason (the only way they move).", _debug_earn)


# --- Tuning -----------------------------------------------------------------------

func get_starting_tallies() -> int:
	var tuning := _tuning()
	return maxi(0, int(tuning.starting_tallies)) if tuning != null else 0


func get_reasons_capacity() -> int:
	var tuning := _tuning()
	return maxi(1, int(tuning.reasons_capacity)) if tuning != null else 8


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


# --- The contract ----------------------------------------------------------------------

## Adds Tallies. Refused — false, no mutation, loud — for a non-positive
## amount or a missing reason.
func earn(amount: int, reason: String) -> bool:
	if not _valid(amount, reason, "earn"):
		return false
	_balance += amount
	_append(amount, reason.strip_edges())
	return true


## Removes Tallies, all or nothing. Refused for a missing reason, a
## non-positive amount, or an insufficient balance — never negative.
func spend(amount: int, reason: String) -> bool:
	if not _valid(amount, reason, "spend"):
		return false
	if amount > _balance:
		return false
	_balance -= amount
	_append(-amount, reason.strip_edges())
	return true


func can_afford(amount: int) -> bool:
	return amount <= _balance


func get_balance() -> int:
	return _balance


## Copies of the recent reasons, oldest first.
func get_reasons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in _reasons:
		out.append(entry.duplicate())
	return out


func _valid(amount: int, reason: String, verb: String) -> bool:
	if reason.strip_edges() == "":
		push_error("Wallet: %s(%d) refused — a reason is required (Tallies must stay understandable)" % [verb, amount])
		return false
	if amount <= 0:
		return false
	return true


func _append(delta: int, reason: String) -> void:
	var clock := get_tree().root.get_node_or_null("Clock")
	_reasons.append({
		"index": _next_reason_index, "delta": delta, "reason": reason,
		"cycle": int(clock.get_cycles_elapsed()) if clock != null else -1,
	})
	_next_reason_index += 1
	while _reasons.size() > get_reasons_capacity():
		_reasons.pop_front()
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("tallies_changed"):
		bus.tallies_changed.emit(_balance, delta, reason)


# --- Build Bible Spec 02 uniform SaveLoad contract -----------------------------------------

func save_state() -> Dictionary:
	var reasons: Array = []
	for entry: Dictionary in _reasons:
		reasons.append({"index": int(entry["index"]), "delta": int(entry["delta"]), "reason": str(entry["reason"]), "cycle": int(entry["cycle"])})
	return {"balance": _balance, "reasons": reasons, "next_reason_index": _next_reason_index}


func load_state(data: Dictionary) -> void:
	_balance = maxi(0, int(data.get("balance", 0)))
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
			_reasons.append({"index": index, "delta": int(e.get("delta", 0)), "reason": str(e.get("reason", "")), "cycle": int(e.get("cycle", -1))})
	while _reasons.size() > get_reasons_capacity():
		_reasons.pop_front()
	_next_reason_index = maxi(int(data.get("next_reason_index", 1)), highest + 1)


func reset_all() -> void:
	_balance = get_starting_tallies()
	_reasons.clear()
	_next_reason_index = 1


# --- Debug ----------------------------------------------------------------------------------

func _debug_tallies(_args: Array[String]) -> String:
	var lines: PackedStringArray = []
	lines.append("Tallies: %d" % _balance)
	if _reasons.is_empty():
		lines.append("No recent reasons.")
	for entry: Dictionary in _reasons:
		lines.append("  [cycle %d] %+d — %s" % [int(entry["cycle"]), int(entry["delta"]), entry["reason"]])
	return "\n".join(lines)


func _debug_earn(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: earn_tallies <amount> <reason...>"
	if not earn(int(args[0]), " ".join(args.slice(1))):
		return "Refused — amount must be positive and a reason is required."
	return "Tallies now %d" % _balance
