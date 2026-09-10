extends Label
## Soft world placard — faint until the player is nearby.

@export var show_radius: float = 140.0
@export var near_alpha: float = 0.85
@export var far_alpha: float = 0.22

var _player: Node2D


func _ready() -> void:
	add_to_group("world_chrome")
	modulate.a = far_alpha
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		modulate.a = far_alpha
		return
	var near := global_position.distance_to(_player.global_position) <= show_radius
	modulate.a = near_alpha if near else far_alpha
