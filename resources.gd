extends Node
## Global resource wallet for Krater (autoload name: Resources).
## Stores named amounts in a dictionary so new resource types are just new ids —
## no need for a new variable per resource when the tech tree grows.
##
## Note: this script is an autoload only (no class_name) so other class_name
## scripts can safely reach it via get_tree().root.get_node("Resources").

signal resource_changed(resource_id: StringName, new_amount: int)

# Stable ids for known resources. Add more consts here as types appear.
const ORE := &"ore"

# Placeholder dig yield: fixed +1 keeps early balancing/tests predictable.
# Later, tile types can request different amounts (or roll ranges) via add().
const ORE_PER_TILE := 1

var _amounts: Dictionary = {
	ORE: 0,
}


func get_amount(resource_id: StringName) -> int:
	return int(_amounts.get(resource_id, 0))


## Add (or subtract with a negative) amount. Clamps at zero for now.
func add(resource_id: StringName, amount: int) -> void:
	var next := maxi(0, get_amount(resource_id) + amount)
	_amounts[resource_id] = next
	resource_changed.emit(resource_id, next)


func set_amount(resource_id: StringName, amount: int) -> void:
	var next := maxi(0, amount)
	_amounts[resource_id] = next
	resource_changed.emit(resource_id, next)
