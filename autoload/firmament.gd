extends Node
## Krater Firmament Progression (autoload: Firmament).
## Build Bible Spec 32 (docs/build-bible/specs/32-firmament-progression.md
## — AI draft pending USER review).
##
## The Act 1 long game as one tracked, MONOTONIC stage (the dependency
## map's draft state machine): Inaccessible -> Foreshadowed (an authored
## story flag) -> Reachable (the Ashram Heights residence, Spec 27 — the
## Firmament is that home's ceiling, canon §62) -> Excavation started ->
## Partial breach -> Breached. Progress is Firmament cells dug (Terrain's
## terrain_dug with is_firmament); the thresholds are tuning and meant to
## be multi-session. Curiosity digs before Ashram count toward the tally
## but cannot carry the stage past Foreshadowed — sustained excavation is
## an Ashram capability. Breached sets the story flag the Act 1 ending
## beat hooks; the surface reveal is Act 2.
##
## Nothing here gates digging or adds a stealth meter (§62 forbids one):
## hardness, noise, evidence and witnesses are the existing Terrain /
## Perception / Evidence rules on the east_firmament restricted zone.
##
## Access via get_tree().root.get_node("Firmament") (no class_name).

const TUNING_DOMAIN := "firmament_tuning"
const STAGE_INACCESSIBLE := &"inaccessible"
const STAGE_FORESHADOWED := &"foreshadowed"
const STAGE_REACHABLE := &"reachable"
const STAGE_EXCAVATION_STARTED := &"excavation_started"
const STAGE_PARTIAL_BREACH := &"partial_breach"
const STAGE_BREACHED := &"breached"
const STAGE_ORDER: Array[StringName] = [STAGE_INACCESSIBLE, STAGE_FORESHADOWED, STAGE_REACHABLE, STAGE_EXCAVATION_STARTED, STAGE_PARTIAL_BREACH, STAGE_BREACHED]
const FACT_STAGE := &"firmament_stage"

var _stage: StringName = STAGE_INACCESSIBLE
var _cells_dug: int = 0


func _ready() -> void:
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null:
		if not bus.terrain_dug.is_connected(_on_terrain_dug):
			bus.terrain_dug.connect(_on_terrain_dug)
		for sig in ["story_flag_set", "residence_changed"]:
			if bus.has_signal(sig):
				bus.connect(sig, _on_world_changed)
	var console := get_tree().root.get_node_or_null("DebugConsole")
	if console == null:
		return
	console.register_command("firmament", "firmament — stage and excavation progress.", _debug_firmament)


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


# --- Reads -----------------------------------------------------------------------------

func get_stage() -> StringName:
	return _stage


func stage_rank(stage: StringName) -> int:
	return STAGE_ORDER.find(stage)


func is_reachable() -> bool:
	var homes := get_tree().root.get_node_or_null("Homes")
	return homes != null and homes.has_method("has_at_least") and bool(homes.has_at_least(&"ashram_heights"))


func is_foreshadowed() -> bool:
	var story := get_tree().root.get_node_or_null("Story")
	return story != null and bool(story.has_flag(StringName(str(_tune("foreshadow_flag", &"firmament_foreshadowed")))))


func get_progress() -> Dictionary:
	var breach := maxi(1, int(_tune("breach_cells", 64)))
	return {
		"cells_dug": _cells_dug,
		"partial_threshold": int(_tune("partial_breach_cells", 24)),
		"breach_threshold": breach,
		"ratio": clampf(float(_cells_dug) / float(breach), 0.0, 1.0),
	}


# --- Derivation (monotonic) --------------------------------------------------------------

func _on_terrain_dug(_cell: Vector2i, _direction: Vector2i, is_firmament: bool, _is_mouth: bool) -> void:
	if not is_firmament:
		return
	_cells_dug += 1
	_reevaluate()


func _on_world_changed(_a: Variant = null) -> void:
	_reevaluate()


## The stage the world state EARNS right now; the stored stage only ever
## rises to meet it.
func _earned_stage() -> StringName:
	var earned := STAGE_INACCESSIBLE
	if is_foreshadowed():
		earned = STAGE_FORESHADOWED
	if not is_reachable():
		return earned
	earned = STAGE_REACHABLE
	if _cells_dug <= 0:
		return earned
	earned = STAGE_EXCAVATION_STARTED
	if _cells_dug >= int(_tune("partial_breach_cells", 24)):
		earned = STAGE_PARTIAL_BREACH
	if _cells_dug >= int(_tune("breach_cells", 64)):
		earned = STAGE_BREACHED
	return earned


func _reevaluate() -> void:
	var earned := _earned_stage()
	if stage_rank(earned) <= stage_rank(_stage):
		return
	var old := _stage
	_stage = earned
	var fact_log := get_tree().root.get_node_or_null("FactLog")
	var clock := get_tree().root.get_node_or_null("Clock")
	if fact_log != null:
		var witnesses: Array[String] = []
		fact_log.record(FACT_STAGE, fact_log.SUBJECT_PLAYER, &"east_firmament", witnesses, {"from": str(old), "to": str(_stage), "cells_dug": _cells_dug}, int(clock.get_cycles_elapsed()) if clock != null else -1)
	var bus := get_tree().root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("firmament_stage_changed"):
		bus.firmament_stage_changed.emit(old, _stage)
	if _stage == STAGE_BREACHED:
		var story := get_tree().root.get_node_or_null("Story")
		if story != null:
			story.set_flag(StringName(str(_tune("breached_flag", &"firmament_breached"))), "The Firmament is breached")


# --- Build Bible Spec 02 uniform SaveLoad contract -----------------------------------------

func save_state() -> Dictionary:
	return {"stage": str(_stage), "cells_dug": _cells_dug}


func load_state(data: Dictionary) -> void:
	var stage := StringName(str(data.get("stage", "inaccessible")))
	_stage = stage if STAGE_ORDER.has(stage) else STAGE_INACCESSIBLE
	_cells_dug = maxi(0, int(data.get("cells_dug", 0)))
	_reevaluate()  # a load never lowers the stage; it may raise it if the world moved on


func reset_all() -> void:
	_stage = STAGE_INACCESSIBLE
	_cells_dug = 0


# --- Debug ---------------------------------------------------------------------------------

func _debug_firmament(_args: Array[String]) -> String:
	var p := get_progress()
	return "Firmament: %s — %d cell(s) dug (partial at %d, breach at %d) — foreshadowed %s, reachable %s" % [_stage, int(p["cells_dug"]), int(p["partial_threshold"]), int(p["breach_threshold"]), is_foreshadowed(), is_reachable()]
