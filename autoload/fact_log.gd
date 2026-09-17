extends Node
## Krater core infrastructure — Fact Log (autoload: FactLog).
## Build Bible Spec 01 (docs/build-bible/specs/01-core-infrastructure.md).
##
## One shared, append-only record of what happened. Every domain writes
## through record(); many domains read back through the query helpers
## (Trust, Suspicion/Investigation, Dialogue's contradiction-checking, debug
## tools). Facts are never mutated or deleted once written — a fact that
## turns out to be wrong or superseded gets a NEW fact recorded (e.g.
## claim_exposed_as_lie referencing the original claim_made), not an edit.
##
## A fact must carry enough detail to be understood on its own, later,
## without re-querying other systems' CURRENT state — by the time something
## asks "was anyone in Wickwork storage that cycle," Wickwork's current
## state may no longer reflect that moment.
##
## Facts are data; derived state (Suspicion, Investigation stage, standing
## labels, ...) is never written back into this log as if it were something
## that happened — those systems compute FROM the log, they don't add to it.
##
## Access via get_tree().root.get_node("FactLog") (no class_name on this
## autoload, matching the existing project convention — see resources.gd).

const SUBJECT_PLAYER := "player"

var _facts: Array[Dictionary] = []


## Append a fact and emit EventBus.fact_recorded. Returns the stored record
## (including its assigned index) so a caller can reference it later if a
## future fact needs to point back at this one.
##
## cycle defaults to -1 ("unknown — Clock not wired yet") until Build Bible
## Spec 04 (World Clock) exists. Callers added after that should pass
## Clock.get_current_cycle() explicitly rather than relying on the default.
func record(
	type: StringName,
	subject: String = SUBJECT_PLAYER,
	location: StringName = StringName(),
	witnesses: Array[String] = [],
	context: Dictionary = {},
	cycle: int = -1
) -> Dictionary:
	var fact := {
		"index": _facts.size(),
		"type": type,
		"cycle": cycle,
		"subject": subject,
		"location": location,
		"witnesses": witnesses.duplicate(),
		"context": context.duplicate(true),
	}
	_facts.append(fact)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.fact_recorded.emit(fact)
	return fact


func get_all() -> Array[Dictionary]:
	return _facts.duplicate()


func get_by_type(type: StringName) -> Array[Dictionary]:
	return _facts.filter(func(f: Dictionary) -> bool: return f["type"] == type)


func get_by_subject(subject: String) -> Array[Dictionary]:
	return _facts.filter(func(f: Dictionary) -> bool: return f["subject"] == subject)


func get_by_location(location: StringName) -> Array[Dictionary]:
	return _facts.filter(func(f: Dictionary) -> bool: return f["location"] == location)


func get_in_cycle_range(from_cycle: int, to_cycle: int) -> Array[Dictionary]:
	return _facts.filter(func(f: Dictionary) -> bool: return f["cycle"] >= from_cycle and f["cycle"] <= to_cycle)


func count() -> int:
	return _facts.size()


## Save/load round-trip, matching the get_*_snapshot / apply_*_snapshot
## convention already used by resources.gd, districts.gd, journal.gd.
## Wired into the real SaveLoad system in Build Bible Spec 02.
func get_snapshot() -> Array:
	return _facts.duplicate(true)


func apply_snapshot(data: Array) -> void:
	_facts.clear()
	for entry: Variant in data:
		if typeof(entry) == TYPE_DICTIONARY:
			_facts.append(entry)


## Test / New Game helper.
func clear_all() -> void:
	_facts.clear()
