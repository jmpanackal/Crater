extends Node
## Krater Stamina + Blocks (autoload: Stamina).
## Build Bible Spec 08 (docs/build-bible/specs/08-stamina.md).
##
## The fixed stamina bar: strenuous actions draw it down; it regenerates
## normally whenever nothing is actively suppressing that; hauling/Rig
## Strain/fatigue can each block part of it. Blocks are tracked by named
## source, not one aggregate number (Spec 08, confirmed option A) — each of
## hauling/rig_strain/fatigue holds its own independent amount, summed for
## the total blocked portion, so e.g. depositing a haul load releases
## exactly the hauling block without touching the others.
##
## Access via get_tree().root.get_node("Stamina") (no class_name, matching
## the existing project convention — see resources.gd).

const SOURCE_HAULING := &"hauling"
const SOURCE_RIG_STRAIN := &"rig_strain"
const SOURCE_FATIGUE := &"fatigue"

const TUNING_DOMAIN := "stamina_tuning"

signal overexertion_triggered(fatigue_added: float)

var _current: float = 100.0
var _blocks: Dictionary = {}  # source_id (StringName) -> float

## Reference-counted regen suppression, same pattern as Clock's pause
## reason stack — e.g. a sustained strenuous action (sprinting) calls
## pause_regen("sprint") while held, resume_regen("sprint") on release.
## Walking is free and never calls this at all, so it never blocks regen.
var _regen_pause_reasons: Dictionary = {}


func _ready() -> void:
	_current = get_max_stamina()
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command(
		"set_stamina", "set_stamina <amount> — set current usable stamina directly.", _debug_set_stamina
	)
	console.register_command(
		"set_stamina_block",
		"set_stamina_block <hauling|rig_strain|fatigue> <amount> — force a block source to a value.",
		_debug_set_block
	)
	console.register_command(
		"force_overexert",
		"force_overexert <cost> — force an Overexertion event to inspect its fatigue conversion.",
		_debug_force_overexert
	)


func _process(delta: float) -> void:
	if not _regen_pause_reasons.is_empty():
		return
	var ceiling := get_available_max()
	if _current < ceiling:
		_current = minf(ceiling, _current + get_regen_rate() * delta)
	elif _current > ceiling:
		# A block just shrank the ceiling below what's currently held —
		# clamp down rather than let usable stamina exceed its new max.
		_current = ceiling


func get_max_stamina() -> float:
	var tuning := _tuning()
	return float(tuning.max_stamina) if tuning != null else 100.0


func get_regen_rate() -> float:
	var tuning := _tuning()
	return float(tuning.regen_rate) if tuning != null else 20.0


## Sum of every named block — how much of the fixed bar is currently
## unavailable, regardless of current usable stamina.
func get_total_blocked() -> float:
	var total := 0.0
	for key: Variant in _blocks.keys():
		total += float(_blocks[key])
	return total


## The ceiling current usable stamina can regenerate toward — max minus
## every current block.
func get_available_max() -> float:
	return maxf(0.0, get_max_stamina() - get_total_blocked())


func get_current() -> float:
	return _current


func get_block(source_id: StringName) -> float:
	return float(_blocks.get(source_id, 0.0))


## Sets source_id's block to exactly `amount` (not additive) — called by
## Hauling, Rig, Fatigue whenever THEIR OWN computed block changes. Clamps
## current usable stamina down if the new total blocked now exceeds it.
func request_block(source_id: StringName, amount: float) -> void:
	_blocks[source_id] = maxf(0.0, amount)
	_current = minf(_current, get_available_max())


## Fully clears source_id's block back to zero — e.g. depositing a haul
## load releases exactly the hauling block, untouched by rig_strain/fatigue.
func release_block(source_id: StringName) -> void:
	_blocks.erase(source_id)


func can_afford(cost: float) -> bool:
	return _current >= cost


## Spends cost from current usable stamina for an already-affordable
## strenuous action. Clamps at zero rather than going negative if called
## without checking can_afford() first — overexert() is the controlled path
## for continuing past zero (G2: blocked/spent-past-zero is only reachable
## through Overexertion, never a silent state).
func spend(cost: float) -> void:
	_current = maxf(0.0, _current - cost)


## Continuing a strenuous action past zero usable stamina (G21: automatic
## at zero stamina while holding the action, with a strong warning — the
## warning/first-time-prompt UI itself belongs to whatever calls this, not
## to Stamina). The shortfall between cost and what's actually available
## converts into fatigue block, exactly (G2) — current usable stamina is
## left at zero, never negative. Returns the fatigue amount added so the
## caller can drive its own warning UI.
func overexert(cost: float) -> float:
	var shortfall := maxf(0.0, cost - _current)
	_current = 0.0
	if shortfall > 0.0:
		request_block(SOURCE_FATIGUE, get_block(SOURCE_FATIGUE) + shortfall)
		overexertion_triggered.emit(shortfall)
	return shortfall


## True specifically when fatigue's OWN block alone has filled the bar
## (canon: "if fatigue alone fills the bar, the player is Exhausted") — not
## the more general "every block combined happens to fill the bar" case,
## which get_available_max() <= 0.0 already covers for "can I do anything
## strenuous right now" regardless of which source caused it.
func is_exhausted() -> bool:
	return get_block(SOURCE_FATIGUE) >= get_max_stamina()


func pause_regen(reason: String) -> void:
	_regen_pause_reasons[reason] = int(_regen_pause_reasons.get(reason, 0)) + 1


func resume_regen(reason: String) -> void:
	if not _regen_pause_reasons.has(reason):
		return
	var count: int = int(_regen_pause_reasons[reason]) - 1
	if count <= 0:
		_regen_pause_reasons.erase(reason)
	else:
		_regen_pause_reasons[reason] = count


func is_regen_paused() -> bool:
	return not _regen_pause_reasons.is_empty()


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


## Build Bible Spec 02 uniform SaveLoad contract.
func save_state() -> Dictionary:
	return {
		"current": _current,
		"blocks": _blocks.duplicate(),
	}


func load_state(data: Dictionary) -> void:
	if data.has("current"):
		_current = float(data["current"])
	if data.has("blocks") and typeof(data["blocks"]) == TYPE_DICTIONARY:
		_blocks = (data["blocks"] as Dictionary).duplicate()


func reset_all() -> void:
	_blocks.clear()
	_regen_pause_reasons.clear()
	_current = get_max_stamina()


func _debug_set_stamina(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: set_stamina <amount>"
	_current = clampf(float(args[0]), 0.0, get_available_max())
	return "Current stamina set to %s" % _current


func _debug_set_block(args: Array[String]) -> String:
	if args.size() < 2:
		return "Usage: set_stamina_block <hauling|rig_strain|fatigue> <amount>"
	var source := StringName(args[0].to_lower())
	if source != SOURCE_HAULING and source != SOURCE_RIG_STRAIN and source != SOURCE_FATIGUE:
		return "Unknown source '%s' — expected hauling, rig_strain, or fatigue" % args[0]
	request_block(source, float(args[1]))
	return "%s block set to %s (total blocked now %s)" % [source, get_block(source), get_total_blocked()]


func _debug_force_overexert(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: force_overexert <cost>"
	var fatigue_added := overexert(float(args[0]))
	return "Overexerted for cost %s — fatigue added: %s (current stamina now %s)" % [args[0], fatigue_added, _current]
