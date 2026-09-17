extends Node
## Krater World Clock (autoload: Clock).
## Build Bible Spec 04 (docs/build-bible/specs/04-world-clock.md).
##
## The sole owner of "what time it is." Nothing else is permitted to move
## time forward directly — other systems REQUEST an advance (sleep, forced
## rescue, failure); only the Clock actually mutates the phase, and emits
## EventBus.phase_changed exactly once per actual transition.
##
## Access via get_tree().root.get_node("Clock") (no class_name, matching
## the existing project convention — see resources.gd).

const PHASE_ROUSING := &"rousing"
const PHASE_WORKING := &"working"
const PHASE_GATHERING := &"gathering"
const PHASE_RITUAL := &"ritual"
const PHASE_ORDER: Array[StringName] = [PHASE_ROUSING, PHASE_WORKING, PHASE_GATHERING, PHASE_RITUAL]

const TUNING_DOMAIN := "clock_tuning"

var _phase: StringName = PHASE_ROUSING
var _cycles_elapsed: int = 0
var _seconds_in_phase: float = 0.0

## Reference-counted pause reasons: pause("menu") + pause("dialogue") both
## have to individually resume() before time moves again, and calling
## pause() twice for the SAME reason (e.g. two code paths that both think
## they opened "menu") correctly needs two resume() calls to clear it —
## a plain boolean-set would let either one wrongly clear the other's pause.
var _pause_reasons: Dictionary = {}


func _process(delta: float) -> void:
	if is_paused():
		return
	_seconds_in_phase += delta
	var phase_length := _phase_length_seconds(_phase)
	# Single if, not while: a delta large enough to cross more than one
	# phase boundary in a single frame is not a real scenario this game
	# produces (phase lengths are real minutes; frame deltas are not), so
	# this deliberately doesn't try to handle skipping multiple phases in
	# one _process call the way request_advance_to_next_rousing() does.
	if phase_length > 0.0 and _seconds_in_phase >= phase_length:
		_seconds_in_phase -= phase_length
		_advance_phase()


func get_phase() -> StringName:
	return _phase


func get_cycles_elapsed() -> int:
	return _cycles_elapsed


func get_seconds_remaining_in_phase() -> float:
	return maxf(0.0, _phase_length_seconds(_phase) - _seconds_in_phase)


## 0..1 progress through the current phase, for a UI countdown/progress bar.
func get_phase_progress() -> float:
	var length := _phase_length_seconds(_phase)
	if length <= 0.0:
		return 0.0
	return clampf(_seconds_in_phase / length, 0.0, 1.0)


func is_paused() -> bool:
	return not _pause_reasons.is_empty()


func pause(reason: String) -> void:
	_pause_reasons[reason] = int(_pause_reasons.get(reason, 0)) + 1


func resume(reason: String) -> void:
	if not _pause_reasons.has(reason):
		return
	var count: int = int(_pause_reasons[reason]) - 1
	if count <= 0:
		_pause_reasons.erase(reason)
	else:
		_pause_reasons[reason] = count


func get_pause_reasons() -> Array[String]:
	var out: Array[String] = []
	for key: Variant in _pause_reasons.keys():
		out.append(str(key))
	return out


## Sleep-style advance to the next Rousing. Per G3/Spec 04 (confirmed option
## B), only valid from Gathering onward (Gathering or Ritual) — the Clock
## itself refuses an out-of-phase request rather than only relying on the
## UI to prevent it. Fires one real phase_changed event per phase actually
## crossed (Gathering→Ritual→Rousing is two events, Ritual→Rousing is one)
## — "exactly one event per transition" means per transition, not per
## request.
func request_advance_to_next_rousing() -> bool:
	if _phase != PHASE_GATHERING and _phase != PHASE_RITUAL:
		return false
	while _phase != PHASE_ROUSING:
		_advance_phase()
	return true


func _phase_length_seconds(phase: StringName) -> float:
	var tuning := _tuning()
	var cycle_minutes := 35.0
	var proportion := 0.25
	if tuning != null:
		cycle_minutes = float(tuning.cycle_length_minutes)
		match phase:
			PHASE_ROUSING:
				proportion = float(tuning.rousing_proportion)
			PHASE_WORKING:
				proportion = float(tuning.working_proportion)
			PHASE_GATHERING:
				proportion = float(tuning.gathering_proportion)
			PHASE_RITUAL:
				proportion = float(tuning.ritual_proportion)
	return cycle_minutes * 60.0 * proportion


func _advance_phase() -> void:
	var old_phase := _phase
	var old_index := PHASE_ORDER.find(old_phase)
	var new_index := (old_index + 1) % PHASE_ORDER.size()
	_phase = PHASE_ORDER[new_index]
	if new_index == 0:
		_cycles_elapsed += 1
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.phase_changed.emit(old_phase, _phase)


func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


## Build Bible Spec 02 uniform SaveLoad contract.
func save_state() -> Dictionary:
	return {
		"phase": str(_phase),
		"cycles_elapsed": _cycles_elapsed,
		"seconds_in_phase": _seconds_in_phase,
	}


func load_state(data: Dictionary) -> void:
	if data.has("phase"):
		var p := StringName(str(data["phase"]))
		if PHASE_ORDER.has(p):
			_phase = p
	if data.has("cycles_elapsed"):
		_cycles_elapsed = int(data["cycles_elapsed"])
	if data.has("seconds_in_phase"):
		_seconds_in_phase = float(data["seconds_in_phase"])


func reset_all() -> void:
	_phase = PHASE_ROUSING
	_cycles_elapsed = 0
	_seconds_in_phase = 0.0
	_pause_reasons.clear()


## Build Bible Spec 03 debug hooks — registered here (by the domain that
## owns this state) rather than built generically into DebugConsole.
func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command(
		"force_phase",
		"force_phase <rousing|working|gathering|ritual> — jump directly to a phase.",
		_debug_force_phase
	)
	console.register_command(
		"force_advance",
		"force_advance [n] — force-advance n phases (default 1).",
		_debug_force_advance
	)
	console.register_command(
		"force_pause",
		"force_pause <on|off> — pause/unpause directly, bypassing the reason stack.",
		_debug_force_pause
	)


func _debug_force_phase(args: Array[String]) -> String:
	if args.is_empty():
		return "Usage: force_phase <rousing|working|gathering|ritual>"
	var target := StringName(args[0].to_lower())
	if not PHASE_ORDER.has(target):
		return "Unknown phase '%s' — expected one of %s" % [args[0], PHASE_ORDER]
	while _phase != target:
		_advance_phase()
	return "Phase is now %s" % _phase


func _debug_force_advance(args: Array[String]) -> String:
	var n := 1
	if not args.is_empty():
		n = maxi(1, int(args[0]))
	for i in range(n):
		_advance_phase()
	return "Advanced %d phase(s) — now %s (cycle %d)" % [n, _phase, _cycles_elapsed]


func _debug_force_pause(args: Array[String]) -> String:
	if args.is_empty() or args[0].to_lower() != "off":
		pause("debug")
		return "Paused (debug)"
	resume("debug")
	return "Resumed debug pause" if not is_paused() else "Debug pause cleared; still paused by: %s" % get_pause_reasons()
