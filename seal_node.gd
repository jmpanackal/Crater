extends Area2D
## Build Bible Spec 18 — exposed evidence in the world (a fresh cut in a
## restricted wall) as a Spec 10 Interactable whose interaction is the
## cancellable hold-to-SEAL. Created by TerrainLayer when a restricted dig
## leaves evidence, freed by it when a seal completes.
##
## Same hold shape as extraction (Spec 12) and theft: on_interact() begins
## the hold, _process() advances it only while the Interact input stays
## held, releasing early cancels with NO partial state — the evidence is
## exactly as it was (Spec 18's own failure case). Completing consumes the
## kit and records the tier (Terrain.complete_seal).
##
## Which kit: the best achievable tier among the kits owned, unless
## begin_seal(kit_id) named one. Owns no authoritative state — the
## evidence record is Terrain's; this owns only the hold in progress.

const InteractionScript := preload("res://interaction.gd")
const INTERACT_ACTION := "interact"
const INTERACT_RADIUS := 24.0

signal seal_started(kit_id: StringName)
signal seal_cancelled
signal seal_completed(tier: StringName)

var cell: Vector2i = Vector2i.ZERO

var _terrain: Node
var _sealing := false
var _progress := 0.0
var _kit_id: StringName = &""


func setup(terrain: Node, p_cell: Vector2i) -> void:
	_terrain = terrain
	cell = p_cell
	name = "Evidence_%d_%d" % [p_cell.x, p_cell.y]
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = INTERACT_RADIUS
		shape.shape = circle
		add_child(shape)
	if get_node_or_null("Mark") == null:
		# Placeholder: a pale scar so the fresh cut reads as "evidence".
		var mark := ColorRect.new()
		mark.name = "Mark"
		mark.size = Vector2(12, 12)
		mark.position = Vector2(-6, -6)
		mark.color = Color(0.86, 0.8, 0.62, 0.55)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mark)


func get_interact_prompt() -> String:
	if _sealing:
		return "Sealing... %d%%" % int(round(get_seal_progress() * 100.0))
	var evidence := _evidence()
	if evidence == null or (evidence.get_owned_kits() as Array).is_empty():
		return "Fresh cut — needs a seal kit"
	return "Seal evidence (hold)"


func on_interact(_player: Node) -> void:
	begin_seal()


## Starts the hold with `kit_id`, or the best kit owned when empty.
## Refuses (no hold) without a usable kit — the kit is the gate.
func begin_seal(kit_id: StringName = &"") -> bool:
	if _sealing:
		return true
	var evidence := _evidence()
	if evidence == null:
		return false
	if kit_id == &"":
		var kits: Array[StringName] = evidence.get_owned_kits()
		if kits.is_empty():
			return false
		kit_id = kits[0]
	elif not bool(evidence.is_seal_kit(kit_id)):
		return false
	_kit_id = kit_id
	_sealing = true
	_progress = 0.0
	seal_started.emit(kit_id)
	return true


## No partial concealment: cancelling resets to exactly untouched.
func cancel_seal() -> void:
	if not _sealing:
		return
	_sealing = false
	_progress = 0.0
	_kit_id = &""
	seal_cancelled.emit()


func is_sealing() -> bool:
	return _sealing


func get_seal_progress() -> float:
	var needed := hold_seconds()
	if needed <= 0.0:
		return 1.0 if _sealing else 0.0
	return clampf(_progress / needed, 0.0, 1.0)


func hold_seconds() -> float:
	var evidence := _evidence()
	return float(evidence.get_seal_hold_seconds()) if evidence != null else 1.5


func _process(delta: float) -> void:
	if not _sealing:
		return
	if not Input.is_action_pressed(INTERACT_ACTION):
		cancel_seal()
		return
	_progress += delta
	if _progress >= hold_seconds():
		_complete()


func _complete() -> void:
	var kit := _kit_id
	_sealing = false
	_progress = 0.0
	_kit_id = &""
	if _terrain == null or not _terrain.has_method("complete_seal"):
		return
	var result: Dictionary = _terrain.complete_seal(cell, kit)
	if bool(result["success"]):
		seal_completed.emit(result["tier"])


func _evidence() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Evidence")
