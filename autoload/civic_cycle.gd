extends Node
## Krater Civic Cycle / Pulse / Ritual (autoload: CivicCycle).
## Build Bible Spec 15 (docs/build-bible/specs/15-civic-cycle.md).
##
## The Pulse-driven rhythm (Rousing -> Working -> Gathering -> Ritual) as it
## actually touches gameplay, built ON TOP of Spec 04's Clock rather than
## duplicating it: this file owns no time. It listens to
## EventBus.phase_changed and does exactly two things —
##
## 1. District resolution timing. On the Ritual -> Rousing transition it
##    emits EventBus.cycle_resolved(cycle) exactly once per cycle (canon
##    §24: "around the transition from Ritual into the next Rousing"; the
##    spec: part of the phase_changed event, not a separate timer). The
##    actual economics hang off that event in Spec 22 (Districts) — this is
##    the hook, deliberately with no economic logic in it. The retired
##    Community "Harvest" timer still drives the retired districts.gd
##    apply_harvest() on its own clock until Spec 22 replaces both; nothing
##    here calls it, so there is no double resolution.
##
## 2. Ritual attendance, detected automatically (Spec 15, confirmed option
##    A) — never scripted per quest. When the Ritual phase begins, it
##    checks whether the player is physically on the Ritual ground at Mid
##    Heart (ritual_ground.gd reports the player body entering/leaving,
##    same live-overlap pattern as Rig's stations) and, if absent, logs ONE
##    `ritual_missed` fact through the Fact Log. It records only the fact:
##    canon §12 says missing Ritual is contextual, never an automatic stat
##    penalty — what it MEANS is Trust's (Spec 19) and NPCs' (Spec 21) call,
##    read back from the log. A present player gets no fact.
##
## The check runs at the START of Ritual (Gathering -> Ritual): Gathering is
## the "return home" window G3 gives the cycle, so arriving during Ritual
## itself is late. Sleeping from Gathering (G3) crosses that transition
## too, so sleeping through Ritual IS a missed Ritual — a true fact, and
## the contextual consequence is still someone else's to decide. The
## mid-rescue / forced-time-skip double-logging concern is Spec 30's
## forward dependency, exactly as the spec flags it.
##
## The Pulse has no autoload of its own (spec scoping note): mechanically
## it is the Clock; physically it is a world object at Mid Heart.
##
## Access via get_tree().root.get_node("CivicCycle") (no class_name,
## matching the existing project convention — see resources.gd).

const FACT_RITUAL_MISSED := &"ritual_missed"
const LOCATION_MID_HEART := &"mid_heart"

## Ended-cycle index of the last resolution emitted (0-based; -1 = none).
var _last_resolved_cycle: int = -1
## Cycle index of the last attendance check (-1 = none) and its result.
var _last_ritual_check_cycle: int = -1
var _last_ritual_attended: bool = false

## Live physical state only — the Ritual grounds the player body is inside
## right now. Never saved; self-corrects the moment a scene loads.
var _grounds_in_range: Array[Node] = []


func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and not bus.phase_changed.is_connected(_on_phase_changed):
		bus.phase_changed.connect(_on_phase_changed)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("civic", "civic — last cycle resolution, last Ritual check, whether the player is on a Ritual ground now.", _debug_civic)
	console.register_command("force_ritual_check", "force_ritual_check — run the Ritual attendance check now, as if Ritual just began.", _debug_force_ritual_check)


# --- Ritual grounds (live physical state) --------------------------------------

## Called by ritual_ground.gd when the player body enters its area.
func enter_ritual_ground(ground: Node) -> void:
	if ground == null or _grounds_in_range.has(ground):
		return
	_grounds_in_range.append(ground)


func leave_ritual_ground(ground: Node) -> void:
	_grounds_in_range.erase(ground)


## Whether the player is physically at Ritual right now.
func is_player_at_ritual() -> bool:
	_grounds_in_range = _grounds_in_range.filter(func(n: Node) -> bool: return is_instance_valid(n) and n.is_inside_tree())
	return not _grounds_in_range.is_empty()


# --- Reads ------------------------------------------------------------------------

func get_last_resolved_cycle() -> int:
	return _last_resolved_cycle


## {"cycle": int, "attended": bool} — cycle -1 if no check has run yet.
func get_last_ritual_check() -> Dictionary:
	return {"cycle": _last_ritual_check_cycle, "attended": _last_ritual_attended}


# --- The two hooks -------------------------------------------------------------------

func _on_phase_changed(old_phase: StringName, new_phase: StringName) -> void:
	var clock := get_tree().root.get_node_or_null("Clock")
	if clock == null:
		return
	if old_phase == clock.PHASE_RITUAL and new_phase == clock.PHASE_ROUSING:
		# Clock has already incremented cycles_elapsed for the new cycle;
		# the cycle that just ENDED is one less.
		_resolve_cycle(int(clock.get_cycles_elapsed()) - 1)
	if new_phase == clock.PHASE_RITUAL:
		_check_ritual_attendance(int(clock.get_cycles_elapsed()))


## Exactly once per ended cycle — a repeated phase event for the same cycle
## (a forced double transition, say) is ignored rather than resolved twice.
func _resolve_cycle(ended_cycle: int) -> void:
	if ended_cycle <= _last_resolved_cycle:
		return
	_last_resolved_cycle = ended_cycle
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.cycle_resolved.emit(ended_cycle)


## Once per cycle: present -> nothing logged; absent -> one ritual_missed
## fact carrying the cycle and the Ritual's location, so it can be read
## back later without re-querying anyone's current state (Spec 01).
func _check_ritual_attendance(cycle: int) -> void:
	if cycle == _last_ritual_check_cycle:
		return
	_last_ritual_check_cycle = cycle
	_last_ritual_attended = is_player_at_ritual()
	if not _last_ritual_attended:
		var fact_log := get_tree().root.get_node_or_null("FactLog")
		if fact_log != null and fact_log.has_method("record"):
			# Typed explicitly: a bare [] through a duck-typed call arrives as
			# an untyped Array and FactLog.record() requires Array[String].
			var witnesses: Array[String] = []
			fact_log.record(FACT_RITUAL_MISSED, fact_log.SUBJECT_PLAYER, LOCATION_MID_HEART, witnesses, {"phase": "ritual"}, cycle)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		bus.ritual_checked.emit(_last_ritual_attended, cycle)


# --- Build Bible Spec 02 uniform SaveLoad contract ------------------------------------

func save_state() -> Dictionary:
	return {
		"last_resolved_cycle": _last_resolved_cycle,
		"last_ritual_check_cycle": _last_ritual_check_cycle,
		"last_ritual_attended": _last_ritual_attended,
	}


func load_state(data: Dictionary) -> void:
	_last_resolved_cycle = int(data.get("last_resolved_cycle", -1))
	_last_ritual_check_cycle = int(data.get("last_ritual_check_cycle", -1))
	_last_ritual_attended = bool(data.get("last_ritual_attended", false))


func reset_all() -> void:
	_last_resolved_cycle = -1
	_last_ritual_check_cycle = -1
	_last_ritual_attended = false


# --- Debug -----------------------------------------------------------------------------

func _debug_civic(_args: Array[String]) -> String:
	var clock := get_tree().root.get_node_or_null("Clock")
	var lines: PackedStringArray = []
	if clock != null:
		lines.append("Phase %s, cycle %d" % [clock.get_phase(), clock.get_cycles_elapsed()])
	lines.append("Last cycle resolved: %s" % ("none" if _last_resolved_cycle < 0 else str(_last_resolved_cycle)))
	if _last_ritual_check_cycle < 0:
		lines.append("Last Ritual check: none")
	else:
		lines.append("Last Ritual check: cycle %d, %s" % [_last_ritual_check_cycle, "attended" if _last_ritual_attended else "MISSED"])
	lines.append("Player on a Ritual ground now: %s" % is_player_at_ritual())
	return "\n".join(lines)


func _debug_force_ritual_check(_args: Array[String]) -> String:
	var clock := get_tree().root.get_node_or_null("Clock")
	var cycle := int(clock.get_cycles_elapsed()) if clock != null else 0
	_last_ritual_check_cycle = -1  # allow a re-check this cycle
	_check_ritual_attendance(cycle)
	return "Ritual check for cycle %d: %s" % [cycle, "attended" if _last_ritual_attended else "missed (ritual_missed fact logged)"]
