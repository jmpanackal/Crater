extends Node
## Global upgrade / tech seed (autoload name: Upgrades).
## Upgrade defs live in a dictionary so new tech entries are data, not new buy APIs.
## Access via get_tree().root.get_node("Upgrades") (no class_name — same reason as Resources).

signal upgrade_changed(upgrade_id: StringName, new_level: int)

# First real upgrade: more Ore per destroyed tile.
const DIG_YIELD := &"dig_yield"

# base_cost * cost_growth^level = next purchase price (ceil'd to an int).
var _defs: Dictionary = {
	DIG_YIELD: {
		"display_name": "Dig Yield",
		"base_cost": 5,
		"cost_growth": 1.5,
		# Ore granted per dig at level 0, then +effect_per_level each purchase.
		"base_effect": 1,
		"effect_per_level": 1,
	},
}

var _levels: Dictionary = {
	DIG_YIELD: 0,
}


func get_level(upgrade_id: StringName) -> int:
	return int(_levels.get(upgrade_id, 0))


func get_def(upgrade_id: StringName) -> Dictionary:
	return _defs.get(upgrade_id, {})


func get_display_name(upgrade_id: StringName) -> String:
	return str(get_def(upgrade_id).get("display_name", upgrade_id))


## Next purchase cost for this upgrade. cost = ceil(base_cost * growth^times_purchased).
func get_next_cost(upgrade_id: StringName) -> int:
	var def := get_def(upgrade_id)
	if def.is_empty():
		return 0
	var base_cost := float(def.get("base_cost", 1))
	var growth := float(def.get("cost_growth", 1.5))
	var level := get_level(upgrade_id)
	return int(ceil(base_cost * pow(growth, level)))


## Current Ore granted when a tile is destroyed (used by Terrain).
func get_dig_ore_yield() -> int:
	var def := get_def(DIG_YIELD)
	var base_effect := int(def.get("base_effect", 1))
	var per_level := int(def.get("effect_per_level", 1))
	return base_effect + get_level(DIG_YIELD) * per_level


func can_buy(upgrade_id: StringName) -> bool:
	if not _defs.has(upgrade_id):
		return false
	var wallet := _wallet()
	if wallet == null:
		return false
	return wallet.get_amount(wallet.ORE) >= get_next_cost(upgrade_id)


## Spend Ore and increase level by 1. Returns false if unaffordable / unknown.
func try_buy(upgrade_id: StringName) -> bool:
	if not can_buy(upgrade_id):
		return false

	var cost := get_next_cost(upgrade_id)
	var wallet := _wallet()
	wallet.add(wallet.ORE, -cost)
	_levels[upgrade_id] = get_level(upgrade_id) + 1
	upgrade_changed.emit(upgrade_id, get_level(upgrade_id))
	return true


## Test helper: force a level without spending (keeps production tests simple).
func set_level(upgrade_id: StringName, level: int) -> void:
	if not _defs.has(upgrade_id):
		return
	_levels[upgrade_id] = maxi(0, level)
	upgrade_changed.emit(upgrade_id, get_level(upgrade_id))


func _wallet() -> Node:
	return get_tree().root.get_node_or_null("Resources")
