extends Area2D
## Build Bible Spec 12 — an EXPOSED deposit in the world, as a Spec 10
## Interactable. Created by TerrainLayer when digging opens a pocket
## (discover -> expose), freed by it when extraction completes.
##
## Exposing and extracting are two distinct steps (Spec 12, option A):
## this node existing means the Material is visible and interactable but
## not yet the player's. Extraction is a cancellable hold-to-interact
## (option A, the same shape confirmed for theft): on_interact() begins the
## hold, _process() advances it only while the Interact input stays held,
## and releasing early cancels with NO partial state — progress goes back
## to zero and the deposit is exactly as it was (Spec 12 failure case).
##
## Owns no authoritative state: which deposits exist, their amounts, and
## whether they're depleted is Terrain's (Spec 06/12). This node only owns
## the transient hold in progress.

const InteractionScript := preload("res://interaction.gd")

const TUNING_DOMAIN := "extraction_tuning"
const INTERACT_ACTION := "interact"

signal extraction_started
signal extraction_cancelled
signal extraction_completed(material_id: StringName, amount: int)

var cell: Vector2i = Vector2i.ZERO
var material_id: StringName = &""
var amount: int = 0

var _terrain: Node
var _extracting := false
var _progress := 0.0


func setup(terrain: Node, p_cell: Vector2i, p_material_id: StringName, p_amount: int, radius: float) -> void:
	_terrain = terrain
	cell = p_cell
	material_id = p_material_id
	amount = p_amount
	name = "Deposit_%d_%d" % [p_cell.x, p_cell.y]
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)


func get_interact_prompt() -> String:
	var display := str(material_id)
	var storage := get_tree().root.get_node_or_null("Storage") if is_inside_tree() else null
	if storage != null:
		display = str(storage.get_material_display_name(material_id))
	if _extracting:
		return "Extracting %s... %d%%" % [display, int(round(get_extraction_progress() * 100.0))]
	return "Extract %s (hold)" % display


func on_interact(_player: Node) -> void:
	begin_extraction()


func begin_extraction() -> void:
	if _extracting:
		return
	_extracting = true
	_progress = 0.0
	extraction_started.emit()


## No partial extraction state: cancelling resets to exactly untouched.
func cancel_extraction() -> void:
	if not _extracting:
		return
	_extracting = false
	_progress = 0.0
	extraction_cancelled.emit()


func is_extracting() -> bool:
	return _extracting


## 0.0 .. 1.0 of the required hold.
func get_extraction_progress() -> float:
	var needed := hold_seconds()
	if needed <= 0.0:
		return 1.0 if _extracting else 0.0
	return clampf(_progress / needed, 0.0, 1.0)


func hold_seconds() -> float:
	var registry := get_tree().root.get_node_or_null("TuningRegistry") if is_inside_tree() else null
	if registry == null:
		return 1.2
	var tuning: Resource = registry.get_domain(TUNING_DOMAIN)
	return float(tuning.hold_seconds) if tuning != null else 1.2


func _process(delta: float) -> void:
	if not _extracting:
		return
	if not Input.is_action_pressed(INTERACT_ACTION):
		cancel_extraction()
		return
	_progress += delta
	if _progress >= hold_seconds():
		_complete()


func _complete() -> void:
	_extracting = false
	_progress = 0.0
	if _terrain == null or not _terrain.has_method("complete_extraction"):
		return
	var granted: int = int(_terrain.complete_extraction(cell))
	if granted > 0:
		extraction_completed.emit(material_id, granted)
