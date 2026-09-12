extends Node
## Global Materials wallet for Krater (autoload name: Resources).
## Stores named amounts in a dictionary so new resource types are just new ids.
##
## Materials from digs feed District production when turned in at the Hollow.
## Salvage remains a transitional dig haul id used by older efficiency spend paths.
## Access via get_tree().root.get_node("Resources") (no class_name on this autoload).

signal resource_changed(resource_id: StringName, new_amount: int)

# Transitional dig haul / efficiency spend (not player-facing Materials label).
const SALVAGE := &"salvage"

# Diggable Materials (Act 1 demo set).
const SPOREMEAL := &"sporemeal"
const LAMPWICK := &"lampwick"
const BRINECRYSTAL := &"brinecrystal"
const VERDIGRIS := &"verdigris"
const HULLBIT := &"hullbit"

# Personal work pay for open requisition.
const TALLIES := &"tallies"

# Fallback dig payout if Upgrades is missing.
const SALVAGE_PER_TILE := 1

## Common Materials cycle granted on dig (plus Salvage for transitional spend).
const DIG_MATERIAL_CYCLE: Array[StringName] = [SPOREMEAL, LAMPWICK, BRINECRYSTAL]

var _amounts: Dictionary = {
	SALVAGE: 0,
	SPOREMEAL: 0,
	LAMPWICK: 0,
	BRINECRYSTAL: 0,
	VERDIGRIS: 0,
	HULLBIT: 0,
	TALLIES: 0,
}

var _dig_material_index := 0


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


func get_materials_snapshot() -> Dictionary:
	var out := {}
	for key in _amounts.keys():
		out[str(key)] = int(_amounts[key])
	return out


func apply_materials_snapshot(data: Dictionary) -> void:
	for key in data.keys():
		var id := StringName(str(key))
		set_amount(id, int(data[key]))


## Grant dig haul: Salvage (transitional) + one cycling Material per successful dig.
func grant_dig_haul(yield_amt: int) -> void:
	if yield_amt <= 0:
		return
	add(SALVAGE, yield_amt)
	if DIG_MATERIAL_CYCLE.is_empty():
		return
	var material_id: StringName = DIG_MATERIAL_CYCLE[_dig_material_index % DIG_MATERIAL_CYCLE.size()]
	_dig_material_index = (_dig_material_index + 1) % DIG_MATERIAL_CYCLE.size()
	add(material_id, yield_amt)


func get_material_display_name(resource_id: StringName) -> String:
	match resource_id:
		SPOREMEAL:
			return "Sporemeal"
		LAMPWICK:
			return "Lampwick"
		BRINECRYSTAL:
			return "Brinecrystal"
		VERDIGRIS:
			return "Verdigris"
		HULLBIT:
			return "Hullbit"
		TALLIES:
			return "Tallies"
		SALVAGE:
			return "Materials"
		_:
			return str(resource_id)


func reset_all() -> void:
	for key in _amounts.keys():
		set_amount(key, 0)
	_dig_material_index = 0
