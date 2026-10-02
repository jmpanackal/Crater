extends Area2D
## Build Bible Spec 15 — the Ritual ground at Mid Heart (canon §11/§12: the
## Pulse's civic centerpiece, where crowds gather for Ritual). Purely a
## presence sensor: it watches the player BODY (layer 1) and tells the
## CivicCycle autoload enter_ritual_ground()/leave_ritual_ground() as the
## player crosses its edge. That live list is the only thing
## CivicCycle.is_player_at_ritual() reads, so "at Ritual" is real overlap
## with the actual Mid Heart deck, not a flag some quest sets.
##
## Not an interactable (Ritual is attended by being there, not by pressing
## a button) — same shape as hollow_zone.gd. Placed in main.tscn over the
## Mid Heart bridge; a future zone scene for Mid Heart carries its own.

const PLAYER_BODY_LAYER := 1

@export var ground_id: StringName = &"mid_heart"

var _players_inside := 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_BODY_LAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	_players_inside = 0
	var civic := _civic()
	if civic != null:
		civic.leave_ritual_ground(self)


func is_player_inside() -> bool:
	return _players_inside > 0


func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	_players_inside += 1
	if _players_inside == 1:
		var civic := _civic()
		if civic != null:
			civic.enter_ritual_ground(self)


func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	_players_inside = maxi(0, _players_inside - 1)
	if _players_inside == 0:
		var civic := _civic()
		if civic != null:
			civic.leave_ritual_ground(self)


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.name == "Player"


func _civic() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null("CivicCycle")
