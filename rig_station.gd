extends Area2D
## Build Bible Spec 14 — a proper Rig station in the world (canon §34: home,
## private workbench, Wickwork/approved facility, other proper stations),
## implemented as a Spec 10 Interactable AND as the physical range check
## the Rig autoload's station rule depends on.
##
## Two jobs, one area:
## - As an interactable (on Interaction.INTERACTABLE_LAYER): the player
##   walks up, Interact fires on_interact(), and `opened` is emitted for
##   whatever refit UI lands later. Nothing here assumes a presentation.
## - As a station: it monitors the player BODY (layer 1) and tells Rig
##   enter_station()/leave_station() as the player crosses its edge. That
##   live list is the ONLY thing Rig.can_equip_at_current_location() reads,
##   so "at a station" is real overlap, not a flag some UI might forget.
##
## station_kind decides what the station permits: any kind allows
## equip/unequip/Core Improvements; only Rig.STATION_WORKSPACE (the private
## Forbidden workspace, §47/§67) also allows grafting — and Rig still checks
## the residence tier on top of that. Usage: add to a scene, set
## station_kind/radius/prompt in the inspector. Standalone Area2D, like
## storage_access.gd.

const InteractionScript := preload("res://interaction.gd")
const PLAYER_BODY_LAYER := 1

## Fired when the player interacts. Carries this station and the Rig autoload.
signal opened(station: Node, rig: Node)

@export var station_kind: StringName = &"home"
@export var radius: float = 48.0
## Empty = a default prompt derived from station_kind.
@export var prompt: String = ""

var _players_inside := 0


func _ready() -> void:
	collision_layer = InteractionScript.INTERACTABLE_LAYER
	collision_mask = PLAYER_BODY_LAYER
	monitoring = true
	monitorable = true
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	_players_inside = 0
	var rig := get_rig()
	if rig != null:
		rig.leave_station(self)


func get_station_kind() -> StringName:
	return station_kind


func is_workspace() -> bool:
	return station_kind == &"workspace"


func get_interact_prompt() -> String:
	if prompt != "":
		return prompt
	match station_kind:
		&"workspace":
			return "Use workspace"
		&"wickwork":
			return "Refit Rig (Wickwork)"
		&"workbench":
			return "Refit Rig (workbench)"
		_:
			return "Refit Rig"


func on_interact(_player: Node) -> void:
	opened.emit(self, get_rig())


func get_rig() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("Rig")


func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	_players_inside += 1
	if _players_inside == 1:
		var rig := get_rig()
		if rig != null:
			rig.enter_station(self)


func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	_players_inside = maxi(0, _players_inside - 1)
	if _players_inside == 0:
		var rig := get_rig()
		if rig != null:
			rig.leave_station(self)


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.name == "Player"
