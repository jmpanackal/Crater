extends Node
## Krater Failure / Rescue (autoload: Rescue).
## Build Bible Spec 30 (docs/build-bible/specs/30-failure-rescue.md — AI
## draft pending USER review).
##
## Canon §54's graduated failure as state — no permadeath, no resets; the
## world continues in a changed state. Owns no persistent state: the
## failure state is DERIVED (Strained: stamina heavily blocked; Exhausted:
## Fatigue says so; Stranded: Exhausted outside the Hollow), the stranded
## grace timer is transient.
##
## G22-B: a severe fall (the player's void soft-respawn reports it)
## adds fatigue through Fatigue (the fatigue slot's one writer), leaves
## the towed bundle as a cache at the last safe ground (recoverable),
## REQUESTS lost time from the Clock (the sole mover of time), logs a
## severe_fall fact. Stored/cached resources, Components and Records are
## never touched.
##
## Rescue: voluntary while Exhausted, forced after the grace period while
## stranded. Rescuers see where the player was and what they carried: a
## rescued fact (zone, restricted?), rescued_from_restricted_area when it
## was restricted excavation, stolen units on the person confiscated with
## a found_evidence fact and ONE Trust event; the haul cached at the
## site; wake at home with fatigue partially recovered; the Clock advanced
## to the next Rousing — Ritual and deadlines fall out of that naturally
## (CivicCycle/Jobs), never marked here.
##
## Access via get_tree().root.get_node("Rescue") (no class_name).

const TUNING_DOMAIN := "rescue_tuning"
const STATE_NONE := &"none"
const STATE_STRAINED := &"strained"
const STATE_EXHAUSTED := &"exhausted"
const STATE_STRANDED := &"stranded"
const FACT_SEVERE_FALL := &"severe_fall"
const FACT_RESCUED := &"rescued"
const FACT_RESCUED_RESTRICTED := &"rescued_from_restricted_area"
const FACT_FOUND_EVIDENCE := &"found_evidence"

var _stranded_seconds := 0.0
var _last_state: StringName = STATE_NONE
## Tests/debug: when true, _process never forces a rescue on its own.
var suspend_forced_rescue := false


func _ready() -> void:
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("failure", "failure — current failure state and the stranded timer.", _debug_failure)
	console.register_command("rescue", "rescue — request a rescue now (as if help was called).", _debug_rescue)
	console.register_command("fall", "fall — report a severe fall at the player's position.", _debug_fall)


func _process(delta: float) -> void:
	var state := get_failure_state()
	if state != _last_state:
		_last_state = state
		var bus := get_tree().root.get_node_or_null("EventBus")
		if bus != null and bus.has_signal("strain_state_changed"):
			bus.strain_state_changed.emit(state)
	if state == STATE_STRANDED:
		_stranded_seconds += delta
		if not suspend_forced_rescue and _stranded_seconds >= get_stranded_grace_seconds():
			request_rescue(true)
	else:
		_stranded_seconds = 0.0


# --- Tuning ---------------------------------------------------------------------

func _tuning() -> Resource:
	var registry := get_tree().root.get_node_or_null("TuningRegistry")
	if registry == null:
		return null
	return registry.get_domain(TUNING_DOMAIN)


func _tune(name: String, fallback: float) -> float:
	var tuning := _tuning()
	return float(tuning.get(name)) if tuning != null else fallback


func get_stranded_grace_seconds() -> float:
	return _tune("stranded_grace_seconds", 45.0)


# --- Derived failure state (canon §54's ladder) ---------------------------------------

func get_failure_state() -> StringName:
	var fatigue := get_tree().root.get_node_or_null("Fatigue")
	var stamina := get_tree().root.get_node_or_null("Stamina")
	if fatigue != null and bool(fatigue.is_exhausted()):
		return STATE_STRANDED if not _player_in_hollow() else STATE_EXHAUSTED
	if stamina != null and float(stamina.get_available_max()) <= float(stamina.get_max_stamina()) * 0.35:
		return STATE_STRAINED
	return STATE_NONE


func is_stranded() -> bool:
	return get_failure_state() == STATE_STRANDED


func get_stranded_seconds() -> float:
	return _stranded_seconds


func _player_in_hollow() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	return HollowLayout.in_hollow(player.global_position)


# --- Severe fall (G22-B) ----------------------------------------------------------------

## Called by the player controller when a void fall soft-respawns it.
## Returns the record: {"fatigue_added", "haul_cached", "phases_lost"}.
func report_severe_fall(fall_pos: Vector2, safe_pos: Vector2) -> Dictionary:
	var fatigue := get_tree().root.get_node_or_null("Fatigue")
	var added := 0.0
	if fatigue != null and fatigue.has_method("add_fatigue"):
		added = float(fatigue.add_fatigue(_tune("fall_fatigue", 20.0)))
	var cached := _leave_haul_at(safe_pos)
	var phases := int(_tune("fall_lost_phases", 1.0))
	var clock := get_tree().root.get_node_or_null("Clock")
	if phases > 0 and clock != null and clock.has_method("request_forced_advance"):
		clock.request_forced_advance(phases, "severe fall")
	_record(FACT_SEVERE_FALL, fall_pos, {"fatigue_added": added, "haul_cached": cached, "phases_lost": phases})
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("severe_fall"):
		bus.severe_fall.emit(fall_pos, safe_pos)
	return {"fatigue_added": added, "haul_cached": cached, "phases_lost": phases}


# --- Rescue ------------------------------------------------------------------------------

## {"ok", "reason"}: a rescue can be requested while Exhausted (voluntary)
## or forced while stranded.
func can_request_rescue() -> Dictionary:
	var state := get_failure_state()
	if state == STATE_EXHAUSTED or state == STATE_STRANDED:
		return {"ok": true, "reason": ""}
	return {"ok": false, "reason": "not_exhausted"}


## The rescue. Returns the record; {} if it wasn't allowed.
func request_rescue(forced: bool = false) -> Dictionary:
	if not forced and not bool(can_request_rescue()["ok"]):
		return {}
	_stranded_seconds = 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var where: Vector2 = player.global_position if player != null else Vector2.ZERO
	var zones := get_tree().root.get_node_or_null("Zones")
	var zone_id := str(zones.get_zone_at(where)) if zones != null else ""
	var restricted := zones != null and bool(zones.is_restricted_at(where))
	var cached := _leave_haul_at(where)
	var contraband := 0
	var trust_delta := 0.0
	# What the rescuers find on the player.
	var diversion := get_tree().root.get_node_or_null("Diversion")
	if diversion != null and diversion.has_method("confiscate_carried"):
		var taken: Dictionary = diversion.confiscate_carried()
		for key: Variant in taken.keys():
			contraband += int(taken[key])
		if contraband > 0:
			for key: Variant in taken.keys():
				_record(FACT_FOUND_EVIDENCE, where, {"investigation_context": "residence", "what": "stolen_output", "district_id": str(key), "units": int(taken[key]), "source": "rescue"}, StringName(zone_id))
				var district := get_tree().root.get_node_or_null("District")
				if district != null and district.has_method("explain_loss"):
					district.explain_loss(StringName(str(key)), float(taken[key]))
	_record(FACT_RESCUED, where, {"zone_id": zone_id, "restricted": restricted, "forced": forced, "contraband_units": contraband, "haul_cached": cached}, StringName(zone_id))
	if restricted:
		_record(FACT_RESCUED_RESTRICTED, where, {"zone_id": zone_id, "forced": forced}, StringName(zone_id))
	var trust := get_tree().root.get_node_or_null("Trust")
	if contraband > 0 and trust != null:
		trust_delta = _tune("contraband_found_trust_delta", -8.0)
		trust.submit_trust_event(&"caught_with_stolen_output", trust_delta, "The crew that carried you home found %d unit%s of diverted district output on you" % [contraband, "" if contraband == 1 else "s"])
	# Home, partially recovered, and a lot of civic time gone.
	var fatigue := get_tree().root.get_node_or_null("Fatigue")
	if fatigue != null and fatigue.has_method("set_fatigue"):
		fatigue.set_fatigue(_tune("fatigue_after_rescue", 30.0))
	if player != null:
		player.global_position = HollowLayout.player_spawn_point()
		player.reset_physics_interpolation()
		if player is CharacterBody2D:
			(player as CharacterBody2D).velocity = Vector2.ZERO
	var clock := get_tree().root.get_node_or_null("Clock")
	if clock != null and clock.has_method("request_forced_advance_to_next_rousing"):
		clock.request_forced_advance_to_next_rousing("rescue")
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("rescued"):
		bus.rescued.emit(forced, restricted, contraband)
	return {"forced": forced, "zone_id": zone_id, "restricted": restricted, "contraband_units": contraband, "haul_cached": cached, "trust_delta": trust_delta}


## The towed bundle stays behind as a cache, recoverable (§54: hauled
## bulk may need to be abandoned/recovered). A forced cache — the
## frontier-only rule for player-chosen caches doesn't apply to a load
## dropped by a fall or a rescue.
func _leave_haul_at(pos: Vector2) -> bool:
	var hauling := get_tree().root.get_node_or_null("Hauling")
	if hauling == null or not bool(hauling.is_loaded()) or not hauling.has_method("force_cache_at"):
		return false
	var result: Dictionary = hauling.force_cache_at(pos)
	return bool(result.get("success", false))


func _record(type: StringName, pos: Vector2, context: Dictionary, location: StringName = StringName()) -> void:
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log == null:
		return
	var witnesses: Array[String] = []
	var ctx := context.duplicate(true)
	ctx["position"] = [pos.x, pos.y]
	fact_log.record(type, fact_log.SUBJECT_PLAYER, location, witnesses, ctx, int(clock.get_cycles_elapsed()) if clock != null else -1)


# --- Build Bible Spec 02 uniform SaveLoad contract — nothing to save --------------------------

func save_state() -> Dictionary:
	return {}


func load_state(_data: Dictionary) -> void:
	pass


func reset_all() -> void:
	_stranded_seconds = 0.0
	_last_state = STATE_NONE


# --- Debug ------------------------------------------------------------------------------------

func _debug_failure(_args: Array[String]) -> String:
	return "Failure state: %s%s" % [get_failure_state(), " (stranded %.0fs / %.0fs)" % [_stranded_seconds, get_stranded_grace_seconds()] if is_stranded() else ""]


func _debug_rescue(_args: Array[String]) -> String:
	var record := request_rescue(false)
	return "Rescued: %s" % [record] if not record.is_empty() else "Not exhausted — nobody needs to carry you yet."


func _debug_fall(_args: Array[String]) -> String:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return "No player in the scene."
	return "Fall: %s" % [report_severe_fall(player.global_position, HollowLayout.nearest_safe_stand(player.global_position))]
