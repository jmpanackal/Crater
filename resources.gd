extends Node
## Global resource wallet for Krater (autoload name: Resources).
## Stores named amounts in a dictionary so new resource types are just new ids.
##
## Salvage carried at the dig site is only useful once siphoned back at the Hollow.
## Access via get_tree().root.get_node("Resources") (no class_name on this autoload).

signal resource_changed(resource_id: StringName, new_amount: int)

# Personal haul from digging — spent only by siphoning at the Hollow (not at dig site).
const SALVAGE := &"salvage"

# Fallback dig payout if Upgrades is missing.
const SALVAGE_PER_TILE := 1

var _amounts: Dictionary = {
	SALVAGE: 0,
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
