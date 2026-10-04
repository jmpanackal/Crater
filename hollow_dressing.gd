class_name HollowDressing
extends Object
## What lives in the Hollow's rooms, as data: buildings (backdrop interiors and facades), props,
## lamps, ambient people and the few things you can use. Like hollow_map.gd, it is declared once and
## everything else derives from it: HollowDressingBuilder draws and instances it, HollowMapLint
## (rule "dress") judges it. See docs/hollow-slice-opening-route.md for the intent of each place.
##
## The first slice is the opening route (docs/hollow-chunk-map.md): Home Court, Lower Switchback,
## West Dispatch Yard, the Worker Stair hall, the Lower Landing, the Bottom-West Approach, the
## Threshold, the First Expansion Gallery and the Collapsed Side Chamber. Everything is greybox:
## flat coloured shapes that read at player scale, no art. Nothing here is collision, so the map's
## walkability (and the lint's reach rule) is untouched.
##
## Positions: x is the centre of the thing in world pixels; k is the level (deck) it stands on;
## y_off lifts it off the deck (a lamp on a wall, a shelf). All sizes are in pixels.

const LAYER_BACK := &"back" ## behind the player: interiors, furniture, lamps
const LAYER_FRONT := &"front" ## in front of the player: railings, brace posts, hanging cloth

## Default size (w, h) per prop kind. A prop may override either.
const SIZES := {
	&"bed": Vector2(64, 26), &"lockbox": Vector2(32, 24), &"workbench": Vector2(64, 34), &"hook": Vector2(20, 44),
	&"pot": Vector2(16, 20), &"rug": Vector2(80, 4), &"fungal_mat": Vector2(28, 10), &"stove": Vector2(48, 60),
	&"basin": Vector2(40, 34), &"laundry": Vector2(96, 90), &"crate": Vector2(30, 24), &"barrel": Vector2(22, 28),
	&"rack": Vector2(60, 56), &"shift_board": Vector2(64, 76), &"scale": Vector2(40, 44), &"beam_stack": Vector2(64, 30),
	&"turntable": Vector2(96, 8), &"cart": Vector2(58, 30), &"dais": Vector2(96, 24), &"arch": Vector2(96, 148),
	&"rail": Vector2(96, 36), &"pillar": Vector2(112, 200), &"overhang": Vector2(96, 80), &"fracture": Vector2(10, 96),
	&"rubble": Vector2(56, 22), &"fallen_beam": Vector2(96, 56), &"warning_sign": Vector2(28, 40), &"ore_pile": Vector2(40, 18),
	&"fragment": Vector2(14, 10), &"supply_rack": Vector2(72, 72), &"gauge": Vector2(40, 40), &"pipe": Vector2(160, 11),
	&"bench": Vector2(60, 22), &"sort_table": Vector2(64, 32), &"sealed_hatch": Vector2(48, 96), &"observation_window": Vector2(48, 32),
	&"notice": Vector2(28, 36), &"brace": Vector2(64, 128), &"step": Vector2(48, 10),
	&"furnace": Vector2(88, 76), &"anvil": Vector2(36, 26), &"forge_wheel": Vector2(96, 96), &"smokestack": Vector2(36, 200),
	&"planter": Vector2(96, 40), &"glow_fungi": Vector2(70, 64), &"fiber_rack": Vector2(64, 74), &"harvest_basket": Vector2(30, 22), &"culture_shelf": Vector2(72, 84),
	&"pump": Vector2(56, 120), &"valve_wheel": Vector2(40, 40), &"awning": Vector2(170, 64), &"niche": Vector2(26, 44), &"herbs": Vector2(48, 38), &"crystal": Vector2(28, 20),
}

## A civic building fills its room: the whole 256px of air. The map's floor slab above it (the
## rest of the gap up to the next deck) is drawn as structure, so the cut-away is solid from
## one floor to the next.
const FULL := HollowMap.ROOM_HEIGHT

## Ambient people. role -> {body, accent, height}. They only stand, work and walk about.
const ROLES := {
	&"resident": {"body": Color(0.62, 0.5, 0.38), "accent": Color(0.82, 0.7, 0.5)},
	&"worker": {"body": Color(0.5, 0.45, 0.36), "accent": Color(0.78, 0.6, 0.3)},
	&"craftsperson": {"body": Color(0.45, 0.4, 0.5), "accent": Color(0.8, 0.55, 0.3)},
	&"digger": {"body": Color(0.48, 0.42, 0.34), "accent": Color(0.7, 0.72, 0.74)},
	&"foreman": {"body": Color(0.55, 0.42, 0.3), "accent": Color(0.9, 0.78, 0.4)},
	&"warden": {"body": Color(0.34, 0.4, 0.46), "accent": Color(0.78, 0.82, 0.88)},
	&"courier": {"body": Color(0.5, 0.52, 0.4), "accent": Color(0.7, 0.6, 0.35)},
	&"sorter": {"body": Color(0.5, 0.44, 0.4), "accent": Color(0.7, 0.55, 0.35)},
}

## Zones the first slice covers, and the least each must hold. The lint fails a zone that thins out.
const SLICE_ZONES := {
	&"home_court": {"props": 8, "lamps": 2, "actors": 1},
	&"lower_switchback": {"props": 5, "lamps": 2, "actors": 2},
	&"west_dispatch_yard": {"props": 8, "lamps": 2, "actors": 3},
	&"worker_return_ascent": {"props": 3, "lamps": 2, "actors": 1},
	&"lower_lift_landing": {"props": 3, "lamps": 1, "actors": 0},
	&"bottom_west_approach": {"props": 6, "lamps": 3, "actors": 2},
	&"bottom_west_threshold": {"props": 6, "lamps": 2, "actors": 2},
	&"first_expansion_gallery": {"props": 6, "lamps": 3, "actors": 3},
	&"collapsed_side_chamber": {"props": 4, "lamps": 1, "actors": 0},
}

## The generated, evenly spread placeholder dressing (tools/generate_dressing_fill.gd), appended to the hand-authored lists.
const Fill := preload("res://hollow_dressing_fill.gd")

static var _cache: Dictionary = {}


static func lvl(k: int) -> float:
	return HollowMap.lvl(float(k))


static func size_of(kind: StringName) -> Vector2:
	return SIZES.get(kind, Vector2(32, 32))


## ---------------------------------------------------------------- builders

static func _prop(zone: StringName, kind: StringName, x: float, k: int, extra: Dictionary = {}) -> Dictionary:
	var size := size_of(kind)
	var d := {
		"zone": zone, "kind": kind, "x": x, "k": k, "y_off": 0.0, "w": size.x, "h": size.y,
		"layer": LAYER_BACK, "flip": 1.0,
	}
	d.merge(extra, true)
	return d


static func _lamp(zone: StringName, x: float, k: int, y_off: float, color_name: StringName) -> Dictionary:
	return {"zone": zone, "x": x, "k": k, "y_off": y_off, "tone": color_name}


static func _building(id: StringName, zone: StringName, kind: StringName, x0: float, x1: float, k: int, height: float, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "zone": zone, "kind": kind, "x0": x0, "x1": x1, "k": k, "height": height, "doors": [], "windows": [], "y_off": 0.0}
	d.merge(extra, true)
	return d


static func _actor(id: StringName, zone: StringName, role: StringName, activity: StringName, x: float, k: int, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "zone": zone, "role": role, "activity": activity, "x": x, "k": k, "y_off": 0.0, "face": 1.0, "range": 0.0, "talk": false, "name": "", "lines": PackedStringArray()}
	d.merge(extra, true)
	return d


static func _station(id: StringName, zone: StringName, kind: StringName, x: float, k: int, prompt: String, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "zone": zone, "kind": kind, "x": x, "k": k, "prompt": prompt, "radius": 30.0}
	d.merge(extra, true)
	return d


## ---------------------------------------------------------------- buildings

static func buildings() -> Array[Dictionary]:
	if _cache.has("all_buildings"):
		return _cache["all_buildings"]
	var all: Array[Dictionary] = authored_buildings()
	all.append_array(Fill.BUILDINGS)
	_cache["all_buildings"] = all
	return all


static func authored_buildings() -> Array[Dictionary]:
	if _cache.has("buildings"):
		return _cache["buildings"]
	var out: Array[Dictionary] = [
		# Home Court: the private unit, and the neighbours' doors onto the shared court.
		_building(&"home_unit", &"home_court", &"unit", -320.0, -96.0, 12, FULL, {"doors": [-112.0], "windows": [-250.0], "warm": 1.0}),
		_building(&"court_wall", &"home_court", &"facade", -96.0, 160.0, 12, FULL, {"doors": [-40.0, 104.0], "windows": [16.0], "homely": true}),
		# Lower Switchback: a family doorway and the maker nook cut into the wall.
		_building(&"switchback_wall", &"lower_switchback", &"facade", -800.0, -320.0, 12, FULL, {"doors": [-480.0], "windows": [-700.0, -600.0], "homely": true}),
		_building(&"maker_nook", &"lower_switchback", &"nook", -450.0, -350.0, 12, 120.0),
		# West Dispatch Yard: the crew hall and the steward's office along the back wall.
		_building(&"dispatch_wall", &"west_dispatch_yard", &"facade", -1600.0, -800.0, 12, FULL, {"doors": [-1520.0, -1000.0], "windows": [-1420.0, -1100.0]}),
		# Worker Stair hall.
		_building(&"stair_hall_wall", &"worker_return_ascent", &"facade", 160.0, 640.0, 12, FULL, {"doors": [240.0], "windows": [420.0]}),
		# Bottom-West Approach: older worker homes the corridor is threaded through.
		_building(&"approach_wall", &"bottom_west_approach", &"facade", -2800.0, -1984.0, 13, FULL, {"windows": [-2540.0, -2200.0]}),
		_building(&"old_home_a", &"bottom_west_approach", &"unit", -2760.0, -2600.0, 13, 150.0, {"doors": [-2690.0], "windows": [-2630.0], "overlay": true}),
		_building(&"old_home_b", &"bottom_west_approach", &"unit", -2440.0, -2290.0, 13, 160.0, {"doors": [-2370.0], "windows": [-2310.0], "overlay": true}),
		_building(&"old_home_c", &"bottom_west_approach", &"unit", -2170.0, -2030.0, 13, 140.0, {"doors": [-2100.0], "windows": [], "overlay": true}),
		# Threshold: the shift hut by the tunnel mouth.
		_building(&"shift_hut", &"bottom_west_threshold", &"unit", -4100.0, -3940.0, 14, 130.0, {"doors": [-4020.0], "windows": [-3960.0]}),
		# Cistern pump house: a facade of pressure doors along the back wall, the pumps standing in front of it.
		_building(&"pump_house", &"cistern", &"facade", 6704.0, 6960.0, 13, FULL, {"doors": [6720.0], "windows": [6850.0]}),
	]
	_cache["buildings"] = out
	return out


## ---------------------------------------------------------------- props

static func props() -> Array[Dictionary]:
	if _cache.has("all_props"):
		return _cache["all_props"]
	var all: Array[Dictionary] = authored_props().duplicate()
	var base := all.size()
	for i in Fill.PROPS.size():
		var p: Dictionary = Fill.PROPS[i].duplicate()
		p["id"] = StringName("%s_%s_%d" % [str(p["zone"]), str(p["kind"]), base + i])
		all.append(p)
	_cache["all_props"] = all
	return all


static func authored_props() -> Array[Dictionary]:
	if _cache.has("props"):
		return _cache["props"]
	var hc := &"home_court"
	var sb := &"lower_switchback"
	var dy := &"west_dispatch_yard"
	var sh := &"worker_return_ascent"
	var ll := &"lower_lift_landing"
	var ap := &"bottom_west_approach"
	var th := &"bottom_west_threshold"
	var gl := &"first_expansion_gallery"
	var ch := &"collapsed_side_chamber"
	var out: Array[Dictionary] = [
		# ---- Home Court: the private unit (bed/rest, lockbox, work surface, delivery hook, personal details)
		_prop(hc, &"bed", -272.0, 12),
		_prop(hc, &"rug", -240.0, 12),
		_prop(hc, &"lockbox", -204.0, 12),
		_prop(hc, &"hook", -176.0, 12, {"y_off": 40.0}),
		_prop(hc, &"workbench", -150.0, 12),
		_prop(hc, &"pot", -306.0, 12),
		_prop(hc, &"pot", -128.0, 12, {"w": 14.0, "h": 16.0}),
		_prop(hc, &"step", -112.0, 12),
		# ... and the shared court: stove, wash basin, laundry, fungal mats, neighbour doors above.
		_prop(hc, &"stove", -8.0, 12),
		_prop(hc, &"basin", 56.0, 12),
		_prop(hc, &"laundry", 112.0, 12, {"layer": LAYER_FRONT, "y_off": 60.0}),
		_prop(hc, &"fungal_mat", 28.0, 12),
		_prop(hc, &"fungal_mat", 144.0, 12, {"w": 20.0}),
		_prop(hc, &"pipe", 20.0, 12, {"y_off": 150.0, "w": 240.0}),
		_prop(hc, &"niche", -66.0, 12, {"y_off": 56.0}),
		_prop(hc, &"herbs", 34.0, 12, {"y_off": 80.0, "layer": LAYER_FRONT}),
		_prop(hc, &"crystal", -312.0, 12, {"w": 16.0}),
		# ---- Lower Switchback: carved support mass, railings, a projecting room, the maker nook
		_prop(sb, &"pillar", -560.0, 12, {"w": 112.0, "h": 190.0}),
		_prop(sb, &"overhang", -690.0, 12, {"y_off": 110.0}),
		_prop(sb, &"fracture", -420.0, 12, {"y_off": 70.0}),
		_prop(sb, &"rail", -768.0, 12, {"layer": LAYER_FRONT}),
		_prop(sb, &"rail", -672.0, 12, {"layer": LAYER_FRONT}),
		_prop(sb, &"rail", -464.0, 12, {"layer": LAYER_FRONT}),
		_prop(sb, &"workbench", -410.0, 12, {"w": 56.0}),
		_prop(sb, &"crate", -352.0, 12),
		_prop(sb, &"barrel", -496.0, 12),
		_prop(sb, &"pot", -616.0, 12),
		# ---- West Dispatch Yard: crew board, tool racks, cart turntable, scales, beams, foreman's dais
		_prop(dy, &"shift_board", -1500.0, 12),
		_prop(dy, &"rack", -1428.0, 12),
		_prop(dy, &"rack", -1372.0, 12, {"w": 52.0}),
		_prop(dy, &"turntable", -1200.0, 12),
		_prop(dy, &"cart", -1200.0, 12, {"y_off": 8.0}),
		_prop(dy, &"scale", -1124.0, 12),
		_prop(dy, &"beam_stack", -1060.0, 12),
		_prop(dy, &"beam_stack", -996.0, 12, {"h": 40.0}),
		_prop(dy, &"dais", -900.0, 12),
		_prop(dy, &"crate", -1560.0, 12),
		_prop(dy, &"barrel", -1540.0, 12, {"w": 18.0}),
		_prop(dy, &"notice", -836.0, 12, {"y_off": 70.0}),
		_prop(dy, &"awning", -1470.0, 12, {"y_off": 150.0}),
		# ---- Worker Stair hall: broad rails, delivery hooks, a rest bench, the lift gauge and bell
		_prop(sh, &"hook", 196.0, 12, {"y_off": 40.0}),
		_prop(sh, &"hook", 224.0, 12, {"y_off": 40.0}),
		_prop(sh, &"bench", 330.0, 12),
		_prop(sh, &"gauge", 480.0, 12, {"y_off": 110.0}),
		_prop(sh, &"rail", 400.0, 12, {"layer": LAYER_FRONT}),
		_prop(sh, &"rail", 496.0, 12, {"layer": LAYER_FRONT}),
		_prop(sh, &"rail", 592.0, 12, {"layer": LAYER_FRONT}),
		_prop(sh, &"barrel", 268.0, 12),
		# ---- Lower Landing: a notice, a parked cart, a rack, crates
		_prop(ll, &"notice", -3396.0, 13, {"y_off": 66.0}),
		_prop(ll, &"supply_rack", -3330.0, 13),
		_prop(ll, &"bench", -3230.0, 13),
		_prop(ll, &"cart", -3110.0, 13),
		_prop(ll, &"crate", -3030.0, 13),
		_prop(ll, &"crate", -3000.0, 13, {"h": 30.0}),
		# ---- Bottom-West Approach: braces, supply racks, cart grooves, residence extension overhead
		_prop(ll, &"brace", -2860.0, 13, {"layer": LAYER_FRONT}),
		_prop(ap, &"supply_rack", -2740.0, 13, {"w": 64.0, "h": 64.0}),
		_prop(ap, &"brace", -2580.0, 13, {"layer": LAYER_FRONT}),
		_prop(ap, &"cart", -2510.0, 13),
		_prop(ap, &"brace", -2400.0, 13, {"layer": LAYER_FRONT}),
		_prop(ap, &"overhang", -2330.0, 13, {"y_off": 120.0, "w": 140.0}),
		_prop(ap, &"crate", -2270.0, 13),
		_prop(ap, &"barrel", -2250.0, 13),
		_prop(ap, &"brace", -2190.0, 13, {"layer": LAYER_FRONT}),
		_prop(ap, &"supply_rack", -2080.0, 13, {"w": 56.0, "h": 60.0}),
		_prop(ap, &"pot", -2640.0, 13),
		_prop(ap, &"crystal", -2470.0, 13),
		_prop(ap, &"crystal", -2000.0, 13, {"w": 20.0}),
		# ---- Bottom-West Threshold: tunnel mouth, shift board, tool check, crates, observation window
		_prop(th, &"arch", -4592.0, 14, {"layer": LAYER_FRONT}),
		_prop(th, &"shift_board", -4500.0, 14),
		_prop(th, &"rack", -4350.0, 14),
		_prop(th, &"crate", -4260.0, 14),
		_prop(th, &"crate", -4230.0, 14, {"h": 30.0}),
		_prop(th, &"crate", -4228.0, 14, {"y_off": 26.0, "w": 24.0, "h": 20.0}),
		_prop(th, &"observation_window", -3960.0, 14, {"y_off": 90.0}),
		_prop(th, &"bench", -4170.0, 14),
		_prop(gl, &"warning_sign", -4690.0, 14),
		# ---- First Expansion Gallery: braces going west, sorting table, cart, ore piles, the unstable end
		_prop(gl, &"brace", -4720.0, 14, {"layer": LAYER_FRONT}),
		_prop(gl, &"brace", -4840.0, 14, {"layer": LAYER_FRONT}),
		_prop(gl, &"sort_table", -4930.0, 14),
		_prop(gl, &"cart", -5300.0, 14),
		_prop(gl, &"ore_pile", -5228.0, 14, {"tone": &"ravel"}),
		_prop(gl, &"ore_pile", -5380.0, 14, {"tone": &"sutral", "w": 34.0}),
		_prop(gl, &"brace", -5000.0, 14, {"layer": LAYER_FRONT}),
		_prop(gl, &"brace", -5470.0, 14, {"layer": LAYER_FRONT}),
		_prop(gl, &"barrel", -5560.0, 14),
		_prop(gl, &"warning_sign", -5724.0, 14, {"w": 32.0}),
		_prop(gl, &"crate", -4790.0, 14),
		_prop(gl, &"crystal", -5440.0, 14),
		_prop(gl, &"crystal", -5680.0, 14, {"w": 20.0}),
		# ---- Collapsed Side Chamber: rubble, fallen supports, an overturned cart, the sealed way on
		_prop(ch, &"rubble", -5690.0, 15),
		_prop(ch, &"rubble", -5560.0, 15, {"w": 44.0, "h": 30.0}),
		_prop(ch, &"fallen_beam", -5380.0, 15),
		_prop(ch, &"cart", -5260.0, 15, {"flip": -1.0, "tone": &"wreck"}),
		_prop(ch, &"fragment", -5470.0, 15),
		_prop(ch, &"rubble", -4660.0, 15, {"w": 40.0}),
		_prop(&"bottom_west_deep", &"sealed_hatch", -4420.0, 15),
		_prop(ch, &"warning_sign", -4540.0, 15),
		_prop(ch, &"crystal", -5600.0, 15),
		_prop(ch, &"crystal", -4760.0, 15, {"w": 18.0}),
		# ---- Cistern (AI, 2026-10-03): the hydraulic district's pump house, valve runs and freight landing
		_prop(&"cistern", &"pump", 6740.0, 13),
		_prop(&"cistern", &"valve_wheel", 6810.0, 13, {"y_off": 36.0}),
		_prop(&"cistern", &"pump", 6880.0, 13, {"h": 100.0}),
		_prop(&"cistern", &"gauge", 6940.0, 13, {"y_off": 70.0}),
		_prop(&"cistern", &"pipe", 6820.0, 13, {"y_off": 150.0}),
		_prop(&"cistern", &"barrel", 7200.0, 13, {"w": 20.0}),
		_prop(&"cistern", &"crate", 7240.0, 13),
		_prop(&"cistern", &"valve_wheel", 7140.0, 13, {"y_off": 40.0}),
		_prop(&"cistern", &"notice", 7280.0, 13, {"y_off": 60.0}),
		_prop(&"cistern_freight", &"cart", 5820.0, 12),
		_prop(&"cistern_freight", &"crate", 5900.0, 12),
		_prop(&"cistern_freight", &"crate", 5930.0, 12, {"h": 30.0}),
		_prop(&"cistern_freight", &"supply_rack", 6120.0, 12),
		_prop(&"cistern_freight", &"notice", 6240.0, 12, {"y_off": 70.0}),
		_prop(&"cistern_freight", &"barrel", 5990.0, 12),
		_prop(&"cistern_freight", &"cart", 6980.0, 12),
		_prop(&"cistern_freight", &"valve_wheel", 7300.0, 12, {"y_off": 44.0}),
		_prop(&"cistern_tanks", &"pump", 7520.0, 14),
		_prop(&"cistern_tanks", &"gauge", 7440.0, 14, {"y_off": 60.0}),
		_prop(&"cistern_tanks", &"pipe", 8060.0, 14, {"y_off": 120.0}),
		_prop(&"cistern_tanks", &"barrel", 8140.0, 14),
		_prop(&"seep_threshold", &"warning_sign", 8560.0, 15),
		_prop(&"seep_threshold", &"rubble", 8500.0, 15),
		# ---- Growth rooms behind their bulkheads (AI, 2026-10-03): a little furniture so they do not read as bare rock
		_prop(&"wickwork_annex", &"workbench", -5300.0, 8),
		_prop(&"wickwork_annex", &"rack", -5200.0, 8),
		_prop(&"wickwork_annex", &"crate", -5120.0, 8),
		_prop(&"wickwork_annex", &"workbench", -4700.0, 8),
		_prop(&"wickwork_annex", &"crate", -3900.0, 8),
		_prop(&"glowbeds_annex", &"fungal_mat", 8960.0, 5),
		_prop(&"glowbeds_annex", &"fungal_mat", 9020.0, 5),
		_prop(&"glowbeds_annex", &"herbs", 9100.0, 5),
		_prop(&"glowbeds_annex", &"crystal", 9170.0, 5),
		_prop(&"cistern_annex", &"pump", 9950.0, 14),
		_prop(&"cistern_annex", &"valve_wheel", 10150.0, 14, {"y_off": 40.0}),
		_prop(&"cistern_annex", &"gauge", 10050.0, 14, {"y_off": 60.0}),
		_prop(&"cistern_annex", &"pipe", 10300.0, 14, {"y_off": 110.0}),
		_prop(&"cistern_annex", &"barrel", 10440.0, 14),
		# ---- Glowbeds (USER 2026-10-04: make it read as the lore: tidy cultivation, stepped planters, fibre racks, harvest
		# baskets, luminous fungi, recovery; amber and muted teal, never neon or a pristine greenhouse). AI-placed greybox.
		_prop(&"glowbeds_hang", &"planter", 5860.0, 6),
		_prop(&"glowbeds_hang", &"planter", 5980.0, 6),
		_prop(&"glowbeds_hang", &"glow_fungi", 6100.0, 6),
		_prop(&"glowbeds_hang", &"fiber_rack", 6220.0, 6),
		_prop(&"glowbeds_hang", &"harvest_basket", 6300.0, 6),
		_prop(&"glowbeds_hang", &"planter", 6620.0, 6),
		_prop(&"glowbeds_hang", &"planter", 6860.0, 6),
		_prop(&"glowbeds_hang", &"glow_fungi", 6960.0, 6),
		_prop(&"glowbeds_wing", &"bed", 5560.0, 7),
		_prop(&"glowbeds_wing", &"bed", 5660.0, 7),
		_prop(&"glowbeds_wing", &"bed", 5760.0, 7),
		_prop(&"glowbeds_wing", &"culture_shelf", 5860.0, 7),
		_prop(&"glowbeds_wing", &"culture_shelf", 5950.0, 7),
		_prop(&"glowbeds_wing", &"basin", 6030.0, 7),
		_prop(&"glowbeds_wing", &"glow_fungi", 6110.0, 7),
		_prop(&"glowbeds_wing", &"herbs", 6180.0, 7),
		_prop(&"glowbeds_wing", &"harvest_basket", 6240.0, 7),
	]
	for i in out.size():
		out[i]["id"] = StringName("%s_%s_%d" % [str(out[i]["zone"]), str(out[i]["kind"]), i])
	_cache["props"] = out
	return out


## ---------------------------------------------------------------- lamps

## tone: warm (a wicklamp niche), cool (a work lamp), amber / red (a warning lamp).
static func lamps() -> Array[Dictionary]:
	if _cache.has("all_lamps"):
		return _cache["all_lamps"]
	var all: Array[Dictionary] = authored_lamps().duplicate()
	all.append_array(Fill.LAMPS)
	_cache["all_lamps"] = all
	return all


static func authored_lamps() -> Array[Dictionary]:
	if _cache.has("lamps"):
		return _cache["lamps"]
	var out: Array[Dictionary] = [
		_lamp(&"home_court", -300.0, 12, 120.0, &"warm"), _lamp(&"home_court", -110.0, 12, 130.0, &"warm"),
		_lamp(&"home_court", 40.0, 12, 130.0, &"warm"), _lamp(&"home_court", 130.0, 12, 120.0, &"warm"),
		_lamp(&"lower_switchback", -740.0, 12, 130.0, &"warm"), _lamp(&"lower_switchback", -540.0, 12, 150.0, &"cool"),
		_lamp(&"lower_switchback", -380.0, 12, 120.0, &"warm"),
		_lamp(&"west_dispatch_yard", -1560.0, 12, 130.0, &"warm"), _lamp(&"west_dispatch_yard", -1280.0, 12, 160.0, &"cool"),
		_lamp(&"west_dispatch_yard", -1000.0, 12, 130.0, &"warm"), _lamp(&"west_dispatch_yard", -840.0, 12, 120.0, &"warm"),
		_lamp(&"worker_return_ascent", 220.0, 12, 130.0, &"warm"), _lamp(&"worker_return_ascent", 420.0, 12, 150.0, &"warm"),
		_lamp(&"worker_return_ascent", 590.0, 12, 130.0, &"warm"),
		_lamp(&"lower_lift_landing", -3350.0, 13, 130.0, &"cool"), _lamp(&"lower_lift_landing", -3050.0, 13, 130.0, &"cool"),
		_lamp(&"bottom_west_approach", -2650.0, 13, 120.0, &"cool"), _lamp(&"bottom_west_approach", -2480.0, 13, 140.0, &"cool"),
		_lamp(&"bottom_west_approach", -2320.0, 13, 130.0, &"warm"), _lamp(&"bottom_west_approach", -2110.0, 13, 130.0, &"cool"),
		_lamp(&"bottom_west_threshold", -4640.0, 14, 130.0, &"amber"), _lamp(&"bottom_west_threshold", -4545.0, 14, 130.0, &"red"),
		_lamp(&"bottom_west_threshold", -4300.0, 14, 130.0, &"cool"), _lamp(&"bottom_west_threshold", -4020.0, 14, 120.0, &"warm"),
		_lamp(&"first_expansion_gallery", -4800.0, 14, 130.0, &"cool"), _lamp(&"first_expansion_gallery", -5000.0, 14, 130.0, &"cool"),
		_lamp(&"first_expansion_gallery", -5260.0, 14, 130.0, &"cool"), _lamp(&"first_expansion_gallery", -5600.0, 14, 130.0, &"amber"),
		_lamp(&"collapsed_side_chamber", -5200.0, 15, 100.0, &"amber"),
		_lamp(&"cistern", 6730.0, 13, 140.0, &"cool"), _lamp(&"cistern", 6930.0, 13, 140.0, &"cool"),
		_lamp(&"cistern", 7200.0, 13, 130.0, &"cool"),
		_lamp(&"cistern_freight", 5860.0, 12, 140.0, &"warm"), _lamp(&"cistern_freight", 6200.0, 12, 140.0, &"cool"),
		_lamp(&"cistern_tanks", 7560.0, 14, 130.0, &"cool"), _lamp(&"cistern_tanks", 8160.0, 14, 130.0, &"amber"),
		_lamp(&"seep_threshold", 8540.0, 15, 120.0, &"red"),
		_lamp(&"wickwork_annex", -5250.0, 8, 130.0, &"cool"), _lamp(&"wickwork_annex", -4700.0, 8, 130.0, &"warm"),
		_lamp(&"glowbeds_annex", 9040.0, 5, 130.0, &"cool"), _lamp(&"glowbeds_annex", 9180.0, 5, 120.0, &"warm"),
		_lamp(&"glowbeds_hang", 5900.0, 6, 140.0, &"warm"), _lamp(&"glowbeds_hang", 6140.0, 6, 130.0, &"cool"),
		_lamp(&"glowbeds_hang", 6660.0, 6, 140.0, &"warm"), _lamp(&"glowbeds_hang", 6900.0, 6, 130.0, &"cool"),
		_lamp(&"glowbeds_wing", 5610.0, 7, 130.0, &"warm"), _lamp(&"glowbeds_wing", 5900.0, 7, 130.0, &"cool"), _lamp(&"glowbeds_wing", 6150.0, 7, 120.0, &"warm"),
		_lamp(&"cistern_annex", 9960.0, 14, 130.0, &"cool"), _lamp(&"cistern_annex", 10320.0, 14, 130.0, &"amber"),
	]
	_cache["lamps"] = out
	return out


## ---------------------------------------------------------------- people

static func actors() -> Array[Dictionary]:
	if _cache.has("actors"):
		return _cache["actors"]
	var out: Array[Dictionary] = [
		# Home Court
		_actor(&"hc_cook", &"home_court", &"resident", &"cook", -24.0, 12, {"face": 1.0}),
		_actor(&"hc_neighbour", &"home_court", &"resident", &"hang_laundry", 126.0, 12, {"face": -1.0}),
		# Lower Switchback: a family at the doorway, a maker at the nook, food delivery
		_actor(&"sb_parent", &"lower_switchback", &"resident", &"idle", -500.0, 12, {"face": 1.0}),
		_actor(&"sb_maker", &"lower_switchback", &"craftsperson", &"hammer", -388.0, 12, {"face": -1.0}),
		_actor(&"sb_courier", &"lower_switchback", &"courier", &"patrol", -760.0, 12, {"range": 120.0}),
		# West Dispatch Yard: waiting crews, a sorter at the scales, a courier, the foreman (talks)
		_actor(&"dy_crew_a", &"west_dispatch_yard", &"worker", &"idle", -1488.0, 12, {"face": 1.0}),
		_actor(&"dy_crew_b", &"west_dispatch_yard", &"worker", &"idle", -1466.0, 12, {"face": 1.0}),
		_actor(&"dy_sorter", &"west_dispatch_yard", &"sorter", &"sort", -1160.0, 12, {"face": 1.0}),
		_actor(&"dy_hauler", &"west_dispatch_yard", &"courier", &"patrol", -1040.0, 12, {"range": 110.0}),
		_actor(&"dy_foreman", &"west_dispatch_yard", &"foreman", &"point", -900.0, 12, {"y_off": 24.0, "face": -1.0, "talk": true, "name": "Foreman",
			"lines": PackedStringArray(["Crews check the board before they go west.", "The gallery's your shift, same as everyone's. Haul what the Steward asks for."])}),
		# Worker Stair hall
		_actor(&"sh_climber", &"worker_return_ascent", &"worker", &"patrol", 250.0, 12, {"range": 200.0}),
		_actor(&"sh_rester", &"worker_return_ascent", &"resident", &"sit", 318.0, 12, {"y_off": 0.0}),
		# Bottom-West Approach
		_actor(&"ap_resident", &"bottom_west_approach", &"resident", &"idle", -2650.0, 13, {"face": -1.0}),
		_actor(&"ap_hauler", &"bottom_west_approach", &"courier", &"patrol", -2540.0, 13, {"range": 140.0}),
		# Threshold: the Warden (talks), a queue of crew waiting to go in
		_actor(&"th_warden", &"bottom_west_threshold", &"warden", &"stand", -4430.0, 14, {"face": 1.0, "talk": true, "name": "Warden",
			"lines": PackedStringArray(["Tools checked, names on the board. Then in.", "Nothing leaves the gallery unlogged."])}),
		_actor(&"th_queue_a", &"bottom_west_threshold", &"worker", &"idle", -4150.0, 14, {"face": -1.0}),
		_actor(&"th_queue_b", &"bottom_west_threshold", &"worker", &"idle", -4120.0, 14, {"face": -1.0}),
		# First Expansion Gallery: crew digging at the face, a sorter, a hauler
		_actor(&"gl_digger_a", &"first_expansion_gallery", &"digger", &"dig", -5640.0, 14, {"face": -1.0}),
		_actor(&"gl_digger_b", &"first_expansion_gallery", &"digger", &"dig", -5590.0, 14, {"face": -1.0}),
		_actor(&"gl_sorter", &"first_expansion_gallery", &"sorter", &"sort", -4962.0, 14, {"face": 1.0}),
		_actor(&"gl_hauler", &"first_expansion_gallery", &"courier", &"patrol", -5330.0, 14, {"range": 70.0}),
	]
	_cache["actors"] = out
	return out


## ---------------------------------------------------------------- things you can use

## kind: rest (sleep until Rousing), storage (the one Storage pool), rig (refit station),
## fragment (a Journal record). The Opening Duty dispatcher and the gallery collection point are
## nodes in main.tscn already.
static func stations() -> Array[Dictionary]:
	if _cache.has("stations"):
		return _cache["stations"]
	var out: Array[Dictionary] = [
		_station(&"home_bed", &"home_court", &"rest", -272.0, 12, "Sleep until Rousing", {"radius": 30.0}),
		_station(&"home_lockbox", &"home_court", &"storage", -204.0, 12, "Open storage", {"radius": 24.0}),
		_station(&"home_workbench", &"home_court", &"rig", -150.0, 12, "Refit Rig (workbench)", {"radius": 24.0, "station": &"home"}),
		_station(&"chamber_fragment", &"collapsed_side_chamber", &"fragment", -5470.0, 15, "Examine the corroded fragment", {"radius": 32.0}),
	]
	_cache["stations"] = out
	return out


## ---------------------------------------------------------------- derived

static func zone_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for z in SLICE_ZONES.keys():
		out.append(z)
	return out


## Counts per zone: {"props", "lamps", "actors", "buildings", "stations"}.
static func counts(zone: StringName) -> Dictionary:
	var c := {"props": 0, "lamps": 0, "actors": 0, "buildings": 0, "stations": 0}
	for p in props():
		if p["zone"] == zone:
			c["props"] += 1
	for l in lamps():
		if l["zone"] == zone:
			c["lamps"] += 1
	for a in actors():
		if a["zone"] == zone:
			c["actors"] += 1
	for b in buildings():
		if b["zone"] == zone:
			c["buildings"] += 1
	for s in stations():
		if s["zone"] == zone:
			c["stations"] += 1
	return c
