extends Node
## Global upgrade / tech seed (autoload name: Upgrades).
## Forbidden upgrades steal District production at the Hollow.
## Efficiency = sanctioned/"safe magic" (boosts districts; still spends Salvage until Tallies UI lands).

signal upgrade_changed(upgrade_id: StringName, new_level: int)
## Emitted when the Hollow theft station opens/closes (player enters/leaves Hollow).
signal theft_station_changed(is_open: bool)
signal theft_result(upgrade_id: StringName, noticed: bool)

const CATEGORY_EFFICIENCY := &"efficiency"
const CATEGORY_FORBIDDEN := &"forbidden"

const DIG_YIELD := &"dig_yield"
const QUIET_DIG := &"quiet_dig"
const FARMS_EFF := &"farms_eff"
const WICKWORK_EFF := &"wickwork_eff"
const CISTERN_EFF := &"cistern_eff"

# true only while the player is physically in the Hollow (set by HollowZone).
var _theft_station_open := false

## When true, forbidden thefts skip RNG (tests). Null = use cover chance.
var force_theft_notice: Variant = null

var _defs: Dictionary = {
	DIG_YIELD: {
		"display_name": "Dig Yield",
		"category": CATEGORY_FORBIDDEN,
		"divert_good": &"bindcord",
		"divert_amount": 1,
		"base_effect": 1,
		"effect_per_level": 1,
		"blurb": "More Materials per dig — diverted Bindcord for your secret work.",
	},
	QUIET_DIG: {
		"display_name": "Quiet Dig",
		"category": CATEGORY_FORBIDDEN,
		"divert_good": &"sealbrine",
		"divert_amount": 1,
		"base_effect": 0,
		"effect_per_level": 1,
		"blurb": "Softer Firmament strikes. Harder to notice upward digs.",
		## Knowledge gate — Firmament note must be found before this can be siphoned.
		"requires_record": &"firmament_note",
	},
	FARMS_EFF: {
		"display_name": "Glowbed Tending",
		"category": CATEGORY_EFFICIENCY,
		"district": &"farms",
		"base_cost": 4,
		"cost_growth": 1.45,
		"blurb": "Safe magic for the glowcap beds. Raises Glowbeds Harvest output.",
	},
	WICKWORK_EFF: {
		"display_name": "Wickcraft",
		"category": CATEGORY_EFFICIENCY,
		"district": &"wickwork",
		"base_cost": 4,
		"cost_growth": 1.45,
		"blurb": "Lantern-and-rope know-how. Raises Wickwork Harvest output.",
	},
	CISTERN_EFF: {
		"display_name": "Cistern Flow",
		"category": CATEGORY_EFFICIENCY,
		"district": &"cistern",
		"base_cost": 4,
		"cost_growth": 1.45,
		"blurb": "Filtration charms. Raises Cistern Harvest output.",
	},
}

var _levels: Dictionary = {
	DIG_YIELD: 0,
	QUIET_DIG: 0,
	FARMS_EFF: 0,
	WICKWORK_EFF: 0,
	CISTERN_EFF: 0,
}


func is_theft_station_open() -> bool:
	return _theft_station_open


## HollowZone calls this when the player enters/leaves the Hollow.
func set_theft_station_open(is_open: bool) -> void:
	if _theft_station_open == is_open:
		return
	_theft_station_open = is_open
	theft_station_changed.emit(_theft_station_open)


func get_upgrade_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _defs.keys():
		out.append(id)
	return out


func get_level(upgrade_id: StringName) -> int:
	return int(_levels.get(upgrade_id, 0))


func get_def(upgrade_id: StringName) -> Dictionary:
	return _defs.get(upgrade_id, {})


func get_display_name(upgrade_id: StringName) -> String:
	return str(get_def(upgrade_id).get("display_name", upgrade_id))


func get_category(upgrade_id: StringName) -> StringName:
	return StringName(str(get_def(upgrade_id).get("category", CATEGORY_FORBIDDEN)))


func is_efficiency(upgrade_id: StringName) -> bool:
	return get_category(upgrade_id) == CATEGORY_EFFICIENCY


func is_forbidden(upgrade_id: StringName) -> bool:
	return get_category(upgrade_id) == CATEGORY_FORBIDDEN


func get_divert_good(upgrade_id: StringName) -> StringName:
	var raw: Variant = get_def(upgrade_id).get("divert_good", null)
	if raw == null or str(raw) == "":
		return StringName()
	return StringName(str(raw))


func get_divert_amount(upgrade_id: StringName) -> int:
	return maxi(1, int(get_def(upgrade_id).get("divert_amount", 1)))


## Next cost. Efficiency uses Salvage curve; forbidden shows divert amount.
func get_next_cost(upgrade_id: StringName) -> int:
	if is_forbidden(upgrade_id):
		return get_divert_amount(upgrade_id)
	var def := get_def(upgrade_id)
	if def.is_empty():
		return 0
	var base_cost := float(def.get("base_cost", 1))
	var growth := float(def.get("cost_growth", 1.5))
	var level := get_level(upgrade_id)
	return int(ceil(base_cost * pow(growth, level)))


## Materials granted when a tile is destroyed (used by Terrain).
func get_dig_salvage_yield() -> int:
	var def := get_def(DIG_YIELD)
	var base_effect := int(def.get("base_effect", 1))
	var per_level := int(def.get("effect_per_level", 1))
	return base_effect + get_level(DIG_YIELD) * per_level


func get_quiet_dig_level() -> int:
	return get_level(QUIET_DIG)


func get_district_efficiency_level(district_id: StringName) -> int:
	match district_id:
		&"farms":
			return get_level(FARMS_EFF)
		&"wickwork":
			return get_level(WICKWORK_EFF)
		&"cistern":
			return get_level(CISTERN_EFF)
		_:
			return 0


## True when any required Record has been unlocked (or none is required).
func is_unlocked(upgrade_id: StringName) -> bool:
	if not _defs.has(upgrade_id):
		return false
	var req: Variant = get_def(upgrade_id).get("requires_record", null)
	if req == null or str(req) == "":
		return true
	var journal := get_tree().root.get_node_or_null("Journal")
	if journal == null or not journal.has_method("has_record"):
		return false
	return bool(journal.has_record(StringName(str(req))))


func get_required_record(upgrade_id: StringName) -> StringName:
	var req: Variant = get_def(upgrade_id).get("requires_record", null)
	if req == null or str(req) == "":
		return StringName()
	return StringName(str(req))


func can_steal(upgrade_id: StringName) -> bool:
	if not _theft_station_open:
		return false
	if not _defs.has(upgrade_id):
		return false
	if not is_unlocked(upgrade_id):
		return false
	if is_forbidden(upgrade_id):
		var districts := _districts()
		var good_id := get_divert_good(upgrade_id)
		var amt := get_divert_amount(upgrade_id)
		if districts == null or good_id == StringName():
			return false
		return districts.can_divert(good_id, amt)
	var wallet := _wallet()
	if wallet == null:
		return false
	return wallet.get_amount(wallet.SALVAGE) >= get_next_cost(upgrade_id)


## Efficiency spends Salvage; forbidden upgrades steal District production and roll Cover notice.
func steal_for_upgrade(upgrade_id: StringName) -> bool:
	if not can_steal(upgrade_id):
		return false

	var divert_good := get_divert_good(upgrade_id)
	if is_forbidden(upgrade_id):
		var districts := _districts()
		var amt := get_divert_amount(upgrade_id)
		if districts == null or not districts.divert_good(divert_good, amt):
			return false
	else:
		var cost := get_next_cost(upgrade_id)
		var wallet := _wallet()
		wallet.add(wallet.SALVAGE, -cost)

	_levels[upgrade_id] = get_level(upgrade_id) + 1
	upgrade_changed.emit(upgrade_id, get_level(upgrade_id))

	var noticed := false
	if is_forbidden(upgrade_id):
		noticed = _roll_theft_notice(divert_good)
		if noticed:
			var community := get_tree().root.get_node_or_null("Community")
			if community and community.has_method("on_theft_noticed"):
				community.on_theft_noticed()

	theft_result.emit(upgrade_id, noticed)

	var save_load := get_tree().root.get_node_or_null("SaveLoad")
	if save_load and save_load.has_method("save_game"):
		save_load.save_game()
	return true


func _roll_theft_notice(good_id: StringName = StringName()) -> bool:
	if force_theft_notice != null:
		return bool(force_theft_notice)
	var districts := _districts()
	var chance := 0.25
	if districts and districts.has_method("get_theft_notice_chance"):
		chance = float(districts.get_theft_notice_chance(good_id))
	return randf() < chance


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


## Test helper: force a level without theft.
func set_level(upgrade_id: StringName, level: int) -> void:
	if not _defs.has(upgrade_id):
		return
	_levels[upgrade_id] = maxi(0, level)
	upgrade_changed.emit(upgrade_id, get_level(upgrade_id))


func _wallet() -> Node:
	return get_tree().root.get_node_or_null("Resources")


func _districts() -> Node:
	return get_tree().root.get_node_or_null("Districts")
