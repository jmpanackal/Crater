extends Area2D
## The Hollow — home settlement zone (placeholder geometry).
## While the player is here, personal upgrades can steal District production.
## Dig-site Salvage does nothing until they return here.

@export var upgrades_path: NodePath = NodePath("/root/Upgrades")

var _players_inside := 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	monitorable = false


func is_player_inside() -> bool:
	return _players_inside > 0


func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	_players_inside += 1
	if _players_inside == 1:
		_set_station_open(true)


func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	_players_inside = maxi(0, _players_inside - 1)
	if _players_inside == 0:
		_set_station_open(false)


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.name == "Player"


func _set_station_open(is_open: bool) -> void:
	var upgrades := get_node_or_null(upgrades_path)
	if upgrades and upgrades.has_method("set_theft_station_open"):
		upgrades.set_theft_station_open(is_open)
