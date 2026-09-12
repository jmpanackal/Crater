extends Node
## Hollow District production (autoload: Districts).
## Named communal goods are filled by Materials queued for the next Harvest.
## Theft diverts named goods (never below the protected civic reserve).
## Cover is local: 70% target good + 30% sibling, from production above reserve.

signal district_changed(district_id: StringName)
signal cover_changed(cover_health: float)
signal production_changed(good_id: StringName)
signal material_queued(material_id: StringName)

const GLOWBEDS := &"farms"
const FARMS := GLOWBEDS  ## Legacy id alias.
const WICKWORK := &"wickwork"
const CISTERN := &"cistern"

const GLOWRATIONS := &"glowrations"
const GLOWFIBER := &"glowfiber"
const WICKLAMPS := &"wicklamps"
const BINDCORD := &"bindcord"
const PRESSWATER := &"presswater"
const SEALBRINE := &"sealbrine"

const PROTECTED_RESERVE := 1
const CAPACITY := 6
const THIN_PRODUCTION_THRESHOLD := 3
const COVER_TARGET_WEIGHT := 0.7
const COVER_SIBLING_WEIGHT := 0.3
const MAX_ABOVE_RESERVE := CAPACITY - PROTECTED_RESERVE
const MIN_COVER := 0.12
const MAX_THEFT_NOTICE := 0.42
const MIN_THEFT_NOTICE := 0.03

## Kept for older efficiency math / tests that still read rates.
const HEALTHY_TOTAL_RATE := 4.5

var _defs: Dictionary = {
	GLOWBEDS: {
		"display_name": "Glowbeds",
		"goods": [GLOWRATIONS, GLOWFIBER],
		"primary": GLOWRATIONS,
		"blurb": "Glowrations and Glowfiber for the Hollow.",
	},
	WICKWORK: {
		"display_name": "The Wickwork",
		"goods": [WICKLAMPS, BINDCORD],
		"primary": WICKLAMPS,
		"blurb": "Wicklamps and Bindcord for light and repair.",
	},
	CISTERN: {
		"display_name": "The Cistern",
		"goods": [PRESSWATER, SEALBRINE],
		"primary": PRESSWATER,
		"blurb": "Presswater and Sealbrine for lifts and seals.",
	},
}

var _good_defs: Dictionary = {
	GLOWRATIONS: {"display_name": "Glowrations", "district": GLOWBEDS, "sibling": GLOWFIBER},
	GLOWFIBER: {"display_name": "Glowfiber", "district": GLOWBEDS, "sibling": GLOWRATIONS},
	WICKLAMPS: {"display_name": "Wicklamps", "district": WICKWORK, "sibling": BINDCORD},
	BINDCORD: {"display_name": "Bindcord", "district": WICKWORK, "sibling": WICKLAMPS},
	PRESSWATER: {"display_name": "Presswater", "district": CISTERN, "sibling": SEALBRINE},
	SEALBRINE: {"display_name": "Sealbrine", "district": CISTERN, "sibling": PRESSWATER},
}

## Material → District production recipe. Verdigris Mid Heart is a separate path.
var _material_recipes: Dictionary = {
	&"sporemeal": {
		"district": GLOWBEDS,
		"outputs": {GLOWRATIONS: 2, GLOWFIBER: 1},
		"primary": GLOWRATIONS,
		"tallies": 1,
	},
	&"lampwick": {
		"district": WICKWORK,
		"outputs": {WICKLAMPS: 1, BINDCORD: 2},
		"primary": WICKLAMPS,
		"tallies": 1,
	},
	&"brinecrystal": {
		"district": CISTERN,
		"outputs": {PRESSWATER: 2, SEALBRINE: 1},
		"primary": PRESSWATER,
		"tallies": 1,
	},
	&"verdigris": {
		"district": WICKWORK,
		"outputs": {WICKLAMPS: 2, BINDCORD: 1},
		"primary": WICKLAMPS,
		"tallies": 0,
	},
}

var _goods: Dictionary = {}
var _queue: Dictionary = {}
var _paused := false


func _ready() -> void:
	reset_production()


func reset_production() -> void:
	_goods.clear()
	_queue.clear()
	for good_id in _good_defs.keys():
		_goods[good_id] = PROTECTED_RESERVE
		_queue[good_id] = 0
	for id in _defs.keys():
		district_changed.emit(id)
	cover_changed.emit(get_cover_health())


func get_district_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _defs.keys():
		out.append(id)
	return out


func get_good_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in _good_defs.keys():
		out.append(id)
	return out


func get_goods_for_district(district_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var def := get_def(district_id)
	for g in def.get("goods", []):
		out.append(g)
	return out


func get_def(district_id: StringName) -> Dictionary:
	return _defs.get(district_id, {})


func get_good_def(good_id: StringName) -> Dictionary:
	return _good_defs.get(good_id, {})


func get_display_name(district_id: StringName) -> String:
	return str(get_def(district_id).get("display_name", district_id))


func get_good_display_name(good_id: StringName) -> String:
	return str(get_good_def(good_id).get("display_name", good_id))


func get_resource_name(district_id: StringName) -> String:
	var goods := get_goods_for_district(district_id)
	if goods.is_empty():
		return "Goods"
	var parts: PackedStringArray = PackedStringArray()
	for g in goods:
		parts.append(get_good_display_name(g))
	return " / ".join(parts)


func get_blurb(district_id: StringName) -> String:
	return str(get_def(district_id).get("blurb", ""))


func get_sibling(good_id: StringName) -> StringName:
	return StringName(str(get_good_def(good_id).get("sibling", "")))


func get_district_for_good(good_id: StringName) -> StringName:
	return StringName(str(get_good_def(good_id).get("district", "")))


func get_good_amount(good_id: StringName) -> int:
	return int(_goods.get(good_id, 0))


func set_good_amount(good_id: StringName, amount: int) -> void:
	if not _good_defs.has(good_id):
		return
	_goods[good_id] = clampi(amount, 0, CAPACITY)
	production_changed.emit(good_id)
	var district_id := get_district_for_good(good_id)
	if district_id != StringName():
		district_changed.emit(district_id)
	cover_changed.emit(get_cover_health())


func get_queued(good_id: StringName) -> int:
	return int(_queue.get(good_id, 0))


func set_queued(good_id: StringName, amount: int) -> void:
	if not _good_defs.has(good_id):
		return
	_queue[good_id] = maxi(0, amount)
	production_changed.emit(good_id)
	var district_id := get_district_for_good(good_id)
	if district_id != StringName():
		district_changed.emit(district_id)


## Amount expected after the next Harvest applies the queue (before civic demand).
func get_next_harvest_forecast(good_id: StringName) -> int:
	return mini(CAPACITY, get_good_amount(good_id) + get_queued(good_id))


func is_production_thin(good_id: StringName) -> bool:
	return get_good_amount(good_id) < THIN_PRODUCTION_THRESHOLD


## Legacy: primary-good amount as float for older callers/tests.
func get_stock(district_id: StringName) -> float:
	var primary: Variant = get_def(district_id).get("primary", null)
	if primary == null:
		return 0.0
	return float(get_good_amount(primary))


func set_stock(district_id: StringName, amount: float) -> void:
	var primary: Variant = get_def(district_id).get("primary", null)
	if primary == null:
		return
	set_good_amount(primary, int(round(amount)))


## Efficiency still exposes a "rate" for older UI; base rates are illustrative only.
func get_rate(district_id: StringName) -> float:
	var base := 1.0
	match district_id:
		GLOWBEDS:
			base = 1.0
		WICKWORK:
			base = 0.85
		CISTERN:
			base = 0.9
		_:
			return 0.0
	var per := 0.45 if district_id == GLOWBEDS else 0.4
	return base + per * float(_efficiency_level(district_id))


func get_total_rate() -> float:
	var total := 0.0
	for id in _defs.keys():
		total += get_rate(id)
	return total


## Global Cover chip: mean of all named-good covers.
func get_cover_health() -> float:
	var total := 0.0
	var count := 0
	for good_id in _good_defs.keys():
		total += get_cover_for_good(good_id)
		count += 1
	if count <= 0:
		return MIN_COVER
	return clampf(total / float(count), MIN_COVER, 1.0)


## Cover for diverting a specific named good (70% target + 30% sibling, above reserve).
func get_cover_for_good(good_id: StringName) -> float:
	if not _good_defs.has(good_id):
		return MIN_COVER
	var target_above := float(maxi(0, get_good_amount(good_id) - PROTECTED_RESERVE))
	var sibling_id := get_sibling(good_id)
	var sibling_above := float(maxi(0, get_good_amount(sibling_id) - PROTECTED_RESERVE))
	var raw := COVER_TARGET_WEIGHT * target_above + COVER_SIBLING_WEIGHT * sibling_above
	var denom := float(MAX_ABOVE_RESERVE)
	if denom <= 0.0:
		return MIN_COVER
	return clampf(raw / denom, MIN_COVER, 1.0)


func get_theft_notice_chance(good_id: StringName = StringName()) -> float:
	var cover := get_cover_health()
	if good_id != StringName() and _good_defs.has(good_id):
		cover = get_cover_for_good(good_id)
	return lerpf(MAX_THEFT_NOTICE, MIN_THEFT_NOTICE, cover)


func can_divert(good_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or not _good_defs.has(good_id):
		return false
	return get_good_amount(good_id) - amount >= PROTECTED_RESERVE


func divert_good(good_id: StringName, amount: int = 1) -> bool:
	if not can_divert(good_id, amount):
		return false
	set_good_amount(good_id, get_good_amount(good_id) - amount)
	return true


## Consume one Material from the wallet and queue District production for next Harvest.
func queue_material(material_id: StringName) -> bool:
	var recipe: Dictionary = _material_recipes.get(material_id, {})
	if recipe.is_empty():
		return false
	var wallet := _wallet()
	if wallet == null or wallet.get_amount(material_id) < 1:
		return false

	wallet.add(material_id, -1)
	var district_id: StringName = recipe.get("district", StringName())
	var eff := _efficiency_level(district_id)
	var primary: StringName = recipe.get("primary", StringName())
	var outputs: Dictionary = recipe.get("outputs", {})
	for good_key in outputs.keys():
		var good_id := StringName(str(good_key))
		var add_amt := int(outputs[good_key])
		if good_id == primary:
			add_amt += eff
		set_queued(good_id, get_queued(good_id) + add_amt)

	var tallies := int(recipe.get("tallies", 0))
	if tallies > 0 and wallet.has_method("add"):
		wallet.add(wallet.TALLIES, tallies)
	material_queued.emit(material_id)
	return true


## Mid Heart public turn-in: Verdigris → Tallies, no District production.
func turn_in_verdigris_for_tallies() -> bool:
	var wallet := _wallet()
	if wallet == null or wallet.get_amount(wallet.VERDIGRIS) < 1:
		return false
	wallet.add(wallet.VERDIGRIS, -1)
	wallet.add(wallet.TALLIES, 3)
	return true


## Apply queued output up to capacity, civic demand, then clear the queue.
func apply_harvest() -> void:
	for good_id in _good_defs.keys():
		var next_amt := mini(CAPACITY, get_good_amount(good_id) + get_queued(good_id))
		# Civic demand: consume 1 above the protected reserve when available.
		if next_amt > PROTECTED_RESERVE:
			next_amt -= 1
		_goods[good_id] = next_amt
		_queue[good_id] = 0
		production_changed.emit(good_id)
	for id in _defs.keys():
		district_changed.emit(id)
	cover_changed.emit(get_cover_health())


func get_production_snapshot() -> Dictionary:
	var goods_out := {}
	var queue_out := {}
	for key in _goods.keys():
		goods_out[str(key)] = int(_goods[key])
	for key in _queue.keys():
		queue_out[str(key)] = int(_queue[key])
	return {"goods": goods_out, "queue": queue_out}


func apply_production_snapshot(data: Dictionary) -> void:
	if data.has("goods") and typeof(data["goods"]) == TYPE_DICTIONARY:
		for key in data["goods"].keys():
			var id := StringName(str(key))
			if _good_defs.has(id):
				set_good_amount(id, int(data["goods"][key]))
	if data.has("queue") and typeof(data["queue"]) == TYPE_DICTIONARY:
		for key in data["queue"].keys():
			var id := StringName(str(key))
			if _good_defs.has(id):
				set_queued(id, int(data["queue"][key]))


## Legacy SaveLoad key: map district float stocks onto primary named goods.
func get_stocks_snapshot() -> Dictionary:
	var out := {}
	for id in _defs.keys():
		out[str(id)] = get_stock(id)
	return out


func apply_stocks_snapshot(data: Dictionary) -> void:
	for key in data.keys():
		var id := StringName(str(key))
		if _defs.has(id):
			set_stock(id, float(data[key]))
			# Sibling goods stay at reserve unless already set by a newer snapshot.
			for good_id in get_goods_for_district(id):
				if good_id == get_def(id).get("primary"):
					continue
				if get_good_amount(good_id) <= 0:
					set_good_amount(good_id, PROTECTED_RESERVE)


func set_paused(paused: bool) -> void:
	_paused = paused


func _efficiency_level(district_id: StringName) -> int:
	var upgrades := get_tree().root.get_node_or_null("Upgrades")
	if upgrades == null or not upgrades.has_method("get_district_efficiency_level"):
		return 0
	return int(upgrades.get_district_efficiency_level(district_id))


func _wallet() -> Node:
	return get_tree().root.get_node_or_null("Resources")
