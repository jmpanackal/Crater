extends Node
## Global upgrade / tech seed (autoload name: Upgrades).
## Personal upgrades are NOT a neutral shop — they are Salvage secretly diverted
## from the communal Harvest. Call siphon_for_upgrade() only at the Hollow.
## Future Social Standing / "caught siphoning" hooks attach here.

signal upgrade_changed(upgrade_id: StringName, new_level: int)
## Emitted when the Hollow siphon station opens/closes (player enters/leaves Hollow).
signal siphon_station_changed(is_open: bool)

const DIG_YIELD := &"dig_yield"

# true only while the player is physically in the Hollow (set by HollowZone).
var _siphon_station_open := false

var _defs: Dictionary = {
	DIG_YIELD: {
		"display_name": "Dig Yield",
		"base_cost": 5,
		"cost_growth": 1.5,
		# Salvage granted per dig at level 0, then +effect_per_level each siphon.
		"base_effect": 1,
		"effect_per_level": 1,
	},
}

var _levels: Dictionary = {
	DIG_YIELD: 0,
}


func is_siphon_station_open() -> bool:
	return _siphon_station_open


## HollowZone calls this when the player enters/leaves the Hollow.
func set_siphon_station_open(is_open: bool) -> void:
	if _siphon_station_open == is_open:
		return
	_siphon_station_open = is_open
	siphon_station_changed.emit(_siphon_station_open)


func get_level(upgrade_id: StringName) -> int:
	return int(_levels.get(upgrade_id, 0))


func get_def(upgrade_id: StringName) -> Dictionary:
	return _defs.get(upgrade_id, {})


func get_display_name(upgrade_id: StringName) -> String:
	return str(get_def(upgrade_id).get("display_name", upgrade_id))


## Next siphon cost. cost = ceil(base_cost * growth^times_purchased).
func get_next_cost(upgrade_id: StringName) -> int:
	var def := get_def(upgrade_id)
	if def.is_empty():
		return 0
	var base_cost := float(def.get("base_cost", 1))
	var growth := float(def.get("cost_growth", 1.5))
	var level := get_level(upgrade_id)
	return int(ceil(base_cost * pow(growth, level)))


## Salvage granted when a tile is destroyed (used by Terrain).
func get_dig_salvage_yield() -> int:
	var def := get_def(DIG_YIELD)
	var base_effect := int(def.get("base_effect", 1))
	var per_level := int(def.get("effect_per_level", 1))
	return base_effect + get_level(DIG_YIELD) * per_level


func can_siphon(upgrade_id: StringName) -> bool:
	if not _siphon_station_open:
		return false
	if not _defs.has(upgrade_id):
		return false
	var wallet := _wallet()
	if wallet == null:
		return false
	return wallet.get_amount(wallet.SALVAGE) >= get_next_cost(upgrade_id)


## Divert Salvage from the communal Harvest into a personal upgrade.
## Only works while the siphon station is open (player in the Hollow).
## Hook for later: Social Standing risk / getting caught when this succeeds.
func siphon_for_upgrade(upgrade_id: StringName) -> bool:
	if not can_siphon(upgrade_id):
		return false

	var cost := get_next_cost(upgrade_id)
	var wallet := _wallet()
	wallet.add(wallet.SALVAGE, -cost)
	_levels[upgrade_id] = get_level(upgrade_id) + 1
	upgrade_changed.emit(upgrade_id, get_level(upgrade_id))

	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load and save_load.has_method("save_game"):
		save_load.save_game()
	return true


## Snapshot of all upgrade levels for SaveLoad.
func get_levels_snapshot() -> Dictionary:
	var out := {}
	for key in _levels.keys():
		out[str(key)] = int(_levels[key])
	return out


## Restore levels from SaveLoad JSON.
func apply_levels_snapshot(data: Dictionary) -> void:
	for key in data.keys():
		var id := StringName(str(key))
		if _defs.has(id):
			set_level(id, int(data[key]))


## Test helper: force a level without siphoning.
func set_level(upgrade_id: StringName, level: int) -> void:
	if not _defs.has(upgrade_id):
		return
	_levels[upgrade_id] = maxi(0, level)
	upgrade_changed.emit(upgrade_id, get_level(upgrade_id))


func _wallet() -> Node:
	return get_tree().root.get_node_or_null("Resources")
