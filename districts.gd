extends Node
## Hollow production districts (autoload: Districts).
## Passive communal stocks tick every frame. Efficiency/"safe magic" upgrades
## raise rates; healthier total output increases siphon cover (safer diversion).

signal district_changed(district_id: StringName)
signal cover_changed(cover_health: float)

const FARMS := &"farms"
const WICKWORK := &"wickwork"
const CISTERN := &"cistern"

## Cover uses this "thriving" total rate as 1.0. Base rates alone sit mid-cover.
const HEALTHY_TOTAL_RATE := 4.5
const MIN_COVER := 0.12
const MAX_SIPHON_NOTICE := 0.42
const MIN_SIPHON_NOTICE := 0.03

var _defs: Dictionary = {
	FARMS: {
		"display_name": "The Farms",
		"resource_name": "Mushrooms",
		"base_rate": 1.0,
		"rate_per_eff": 0.45,
		"blurb": "Glowcap beds. Food for Harvest.",
	},
	WICKWORK: {
		"display_name": "The Wickwork",
		"resource_name": "Wickgoods",
		"base_rate": 0.85,
		"rate_per_eff": 0.4,
		"blurb": "Lanterns, rope, tools for the terraces.",
	},
	CISTERN: {
		"display_name": "The Cistern",
		"resource_name": "Water",
		"base_rate": 0.9,
		"rate_per_eff": 0.4,
		"blurb": "Seepage collected and shared.",
	},
}

var _stocks: Dictionary = {
	FARMS: 0.0,
	WICKWORK: 0.0,
	CISTERN: 0.0,
}

var _paused := false


func _process(delta: float) -> void:
	if _paused:
		return
	for id in _defs.keys():
		var rate := get_rate(id)
		if rate <= 0.0:
			continue
		_stocks[id] = float(_stocks[id]) + rate * delta
		district_changed.emit(id)
	cover_changed.emit(get_cover_health())


func get_district_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _defs.keys():
		out.append(id)
	return out


func get_def(district_id: StringName) -> Dictionary:
	return _defs.get(district_id, {})


func get_display_name(district_id: StringName) -> String:
	return str(get_def(district_id).get("display_name", district_id))


func get_resource_name(district_id: StringName) -> String:
	return str(get_def(district_id).get("resource_name", "Goods"))


func get_blurb(district_id: StringName) -> String:
	return str(get_def(district_id).get("blurb", ""))


func get_stock(district_id: StringName) -> float:
	return float(_stocks.get(district_id, 0.0))


func set_stock(district_id: StringName, amount: float) -> void:
	if not _defs.has(district_id):
		return
	_stocks[district_id] = maxf(0.0, amount)
	district_changed.emit(district_id)


## Units per second, including efficiency upgrade levels from Upgrades.
func get_rate(district_id: StringName) -> float:
	var def := get_def(district_id)
	if def.is_empty():
		return 0.0
	var base := float(def.get("base_rate", 0.0))
	var per := float(def.get("rate_per_eff", 0.0))
	return base + per * float(_efficiency_level(district_id))


func get_total_rate() -> float:
	var total := 0.0
	for id in _defs.keys():
		total += get_rate(id)
	return total


## 0..1 — healthier districts = higher cover = safer forbidden siphons.
func get_cover_health() -> float:
	return clampf(get_total_rate() / HEALTHY_TOTAL_RATE, MIN_COVER, 1.0)


## Chance (0..1) that a forbidden siphon is noticed.
func get_siphon_notice_chance() -> float:
	var cover := get_cover_health()
	return lerpf(MAX_SIPHON_NOTICE, MIN_SIPHON_NOTICE, cover)


func get_stocks_snapshot() -> Dictionary:
	var out := {}
	for key in _stocks.keys():
		out[str(key)] = float(_stocks[key])
	return out


func apply_stocks_snapshot(data: Dictionary) -> void:
	for key in data.keys():
		var id := StringName(str(key))
		if _defs.has(id):
			set_stock(id, float(data[key]))


func set_paused(paused: bool) -> void:
	_paused = paused


func _efficiency_level(district_id: StringName) -> int:
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	if upgrades == null or not upgrades.has_method("get_district_efficiency_level"):
		return 0
	return int(upgrades.get_district_efficiency_level(district_id))
