extends Area2D
## Build Bible Spec 26 — a district's physical storage (a Wickwork rack, a
## Glowbeds culture shelf, a Cistern supply crate) as a Spec 10
## Interactable whose interaction is the cancellable HOLD-TO-TAKE (G9-A):
## on_interact() begins a take, _process() advances it only while Interact
## stays held, every noise tick re-checks witnesses through Diversion
## (Spec 17), releasing early cancels with nothing taken, and completing
## removes ONE unit (Diversion.complete_take). Hold again for the next.
##
## Owns only the hold in progress. Place one per district storage area.

const InteractionScript := preload("res://interaction.gd")
const INTERACT_ACTION := "interact"

signal take_started(district_id: StringName)
signal take_cancelled
signal take_completed(district_id: StringName)

@export var district_id: StringName = &"wickwork"
@export var interact_radius: float = 32.0

var _taking := false
var _progress := 0.0
var _tick_accum := 0.0


func _ready() -> void:
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = interact_radius
		shape.shape = circle
		add_child(shape)
	if get_node_or_null("Rack") == null:
		var rack := ColorRect.new()
		rack.name = "Rack"
		rack.size = Vector2(20, 14)
		rack.position = Vector2(-10, -14)
		rack.color = Color(0.5, 0.36, 0.22, 0.9)
		rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rack)


func get_interact_prompt() -> String:
	if _taking:
		return "Taking... %d%%" % int(round(get_take_progress() * 100.0))
	var diversion := _diversion()
	if diversion != null and not bool(diversion.can_take(district_id)["ok"]):
		return "%s stores (nothing to take)" % str(district_id).capitalize()
	return "Take from %s stores (hold)" % str(district_id).capitalize()


func on_interact(_player: Node) -> void:
	begin_take()


func begin_take() -> bool:
	if _taking:
		return true
	var diversion := _diversion()
	if diversion == null or not bool(diversion.can_take(district_id)["ok"]):
		return false
	_taking = true
	_progress = 0.0
	_tick_accum = 0.0
	take_started.emit(district_id)
	diversion.noise_tick(district_id, global_position)  # the first tick is the start
	return true


func cancel_take() -> void:
	if not _taking:
		return
	_taking = false
	_progress = 0.0
	_tick_accum = 0.0
	take_cancelled.emit()


func is_taking() -> bool:
	return _taking


func get_take_progress() -> float:
	var needed := hold_seconds()
	if needed <= 0.0:
		return 1.0 if _taking else 0.0
	return clampf(_progress / needed, 0.0, 1.0)


func hold_seconds() -> float:
	var diversion := _diversion()
	return float(diversion.get_take_hold_seconds()) if diversion != null else 1.6


func _process(delta: float) -> void:
	if not _taking:
		return
	if not Input.is_action_pressed(INTERACT_ACTION):
		cancel_take()
		return
	_progress += delta
	_tick_accum += delta
	var diversion := _diversion()
	if diversion != null and _tick_accum >= float(diversion.get_noise_tick_seconds()):
		_tick_accum = 0.0
		diversion.noise_tick(district_id, global_position)
	if _progress >= hold_seconds():
		_complete()


func _complete() -> void:
	_taking = false
	_progress = 0.0
	_tick_accum = 0.0
	var diversion := _diversion()
	if diversion == null:
		return
	var result: Dictionary = diversion.complete_take(district_id)
	if bool(result["success"]):
		take_completed.emit(district_id)


func _diversion() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Diversion")
