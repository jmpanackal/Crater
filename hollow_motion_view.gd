extends Node2D
## The Hollow's moving parts (USER 2026-10-04: the lifts moving makes the society feel alive; more like that, as long
## as it fits the lore). Everything here is machinery or growth the lore already has, doing what it would do:
##   the Pulse's vent breathing steam, and the pressure pumps of the Cistern pumping, their valve wheels turning,
##   Mid Heart's pennants flapping, the freight dock's gantry crane carrying a crate across its beam and a hand cart
##   shuttling along the freight tier, lamps flickering, and the luminous fungi of Glowbeds slowly breathing light.
## Greybox, drawn in code, replaced by real animation later. Visual only, no collision. Only what is on screen is
## drawn, so it costs nothing elsewhere. The static dressing leaves out the moving bits (spokes, piston rods, pennant
## cloth, crane trolley) so nothing is drawn twice.

const SPOKE := Color(0.72, 0.46, 0.26)
const STEAM := Color(0.8, 0.84, 0.86)
const CLOTH := Color(0.55, 0.3, 0.24)
const CLOTH_TRIM := Color(0.62, 0.5, 0.3)
const STEEL := Color(0.2, 0.22, 0.25)
const STEEL_HI := Color(0.34, 0.37, 0.41)
const COPPER := Color(0.72, 0.46, 0.26)
const TIMBER := Color(0.36, 0.27, 0.19)
const GLOW := {
	&"warm": Color(1.0, 0.78, 0.45),
	&"cool": Color(0.55, 0.85, 0.88),
	&"amber": Color(1.0, 0.62, 0.2),
	&"red": Color(0.95, 0.28, 0.24),
}

var _t := 0.0
var _valves: Array[Dictionary] = []
var _pumps: Array[Dictionary] = []
var _fungi: Array[Dictionary] = []
var _lamps: Array[Dictionary] = []
var _vents: Array[Vector2] = []
var _pennants: Array[Dictionary] = []
var _crane := {}
var _carts: Array[Dictionary] = []


func _ready() -> void:
	z_index = -1
	for p in HollowDressing.props():
		var deck := HollowMap.deck_y_at(float(p["x"]), float(p["k"])) - float(p["y_off"])
		match p["kind"]:
			&"valve_wheel":
				_valves.append({"pos": Vector2(float(p["x"]), deck - float(p["h"]) * 0.5), "r": float(p["h"]) * 0.5, "ph": float(int(p["x"]) % 7)})
			&"pump":
				_pumps.append({"x": float(p["x"]), "deck": deck, "h": float(p["h"]), "w": float(p["w"]), "ph": float(int(p["x"]) % 5)})
				_vents.append(Vector2(float(p["x"]) + float(p["w"]) * 0.5 + 7.0, deck - 34.0))
			&"glow_fungi":
				_fungi.append({"pos": Vector2(float(p["x"]), deck - 30.0), "ph": float(int(p["x"]) % 11)})
	for l in HollowDressing.lamps():
		_lamps.append({"pos": Vector2(float(l["x"]), HollowMap.deck_y_at(float(l["x"]), float(l["k"])) - float(l["y_off"])), "tone": l["tone"], "ph": float(int(l["x"]) % 13)})
	_build_mid_heart()


func _build_mid_heart() -> void:
	var raft_y := HollowMap.lvl(7.5)
	# the Pulse's vent stack
	_vents.append(Vector2(HollowMap.RITUAL_LEFT + (HollowMap.RITUAL_RIGHT - HollowMap.RITUAL_LEFT) * 0.5, raft_y - 420.0 - 96.0))
	# pennants on the Ritual Raft's pillars (the static view draws only the poles)
	_pennants.append({"pole": Vector2(HollowMap.RITUAL_LEFT + 236.0 + 12.0, raft_y - 280.0), "dir": 1.0})
	_pennants.append({"pole": Vector2(HollowMap.RITUAL_RIGHT - 260.0 + 12.0, raft_y - 280.0), "dir": -1.0})
	# the freight dock's gantry crane
	for r in HollowMap.runs():
		if r["id"] == &"HM_LH":
			var mid := (float(r["x0"]) + float(r["x1"])) * 0.5
			_crane = {"mid": mid, "y": float(r["y"])}
		elif r["id"] == &"HM_F" or r["id"] == &"HM_F2":
			_carts.append({"x0": float(r["x0"]) + 40.0, "x1": float(r["x1"]) - 40.0, "y": float(r["y"]), "ph": float(_carts.size()) * 9.0})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _visible_rect() -> Rect2:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	return (inv * Rect2(Vector2.ZERO, vp.get_visible_rect().size)).grow(160.0)


func _draw() -> void:
	var view := _visible_rect()
	for v in _valves:
		if view.has_point(v["pos"]):
			_draw_valve(v)
	for p in _pumps:
		if view.has_point(Vector2(p["x"], p["deck"])):
			_draw_piston(p)
	for s in _vents:
		if view.has_point(s):
			_draw_steam(s)
	for l in _lamps:
		if view.has_point(l["pos"]):
			_draw_lamp_flicker(l)
	for f in _fungi:
		if view.has_point(f["pos"]):
			_draw_fungi_glow(f)
	for pn in _pennants:
		if view.has_point(pn["pole"]):
			_draw_pennant(pn)
	if not _crane.is_empty() and view.has_point(Vector2(_crane["mid"], _crane["y"] - 100.0)):
		_draw_crane()
	for c in _carts:
		if view.intersects(Rect2(c["x0"], c["y"] - 60.0, c["x1"] - c["x0"], 70.0)):
			_draw_cart(c)


## A valve wheel turning slowly, forward and then back, as someone trims a line.
func _draw_valve(v: Dictionary) -> void:
	var c: Vector2 = v["pos"]
	var r: float = v["r"]
	var a := sin(_t * 0.35 + float(v["ph"])) * 0.9
	for i in range(4):
		var ang := a + float(i) * PI * 0.5
		draw_line(c, c + Vector2(cos(ang), sin(ang)) * (r - 3.0), SPOKE, 2.5)
	draw_circle(c, r - 2.0, Color(0, 0, 0, 0.0))
	draw_circle(c, 4.0, SPOKE.lightened(0.15))


## A pump piston: the rod strokes up and down inside the housing.
func _draw_piston(p: Dictionary) -> void:
	var stroke := (sin(_t * 2.2 + float(p["ph"])) * 0.5 + 0.5) * 12.0
	var top: float = p["deck"] - float(p["h"]) + 22.0
	draw_rect(Rect2(float(p["x"]) - 3.0, top - stroke, 6.0, 22.0 + stroke), Color(0.72, 0.74, 0.74))
	draw_rect(Rect2(float(p["x"]) - 3.0, top - stroke, 6.0, 2.0), Color(1, 1, 1, 0.35))


## Steam from a vent: soft puffs that rise, widen and fade, a few in the air at once.
func _draw_steam(pos: Vector2) -> void:
	for i in range(4):
		var f := fposmod(_t * 0.45 + float(i) * 0.25 + pos.x * 0.001, 1.0)
		var p := pos + Vector2(sin(f * 5.0 + float(i)) * 6.0 * f, -f * 70.0)
		draw_circle(p, 3.0 + 9.0 * f, Color(STEAM.r, STEAM.g, STEAM.b, 0.16 * (1.0 - f)))


func _draw_lamp_flicker(l: Dictionary) -> void:
	var c: Color = GLOW.get(l["tone"], GLOW[&"warm"])
	var flick := 0.55 + 0.45 * sin(_t * 5.3 + float(l["ph"])) * sin(_t * 1.9 + float(l["ph"]) * 0.7)
	draw_circle(l["pos"], 36.0, Color(c.r, c.g, c.b, 0.035 * flick))


## Luminous fungi breathing: the glow swells and fades on a slow cycle, each stand out of step with the next.
func _draw_fungi_glow(f: Dictionary) -> void:
	var b := 0.5 + 0.5 * sin(_t * 0.8 + float(f["ph"]))
	draw_circle(f["pos"], 26.0 + 8.0 * b, Color(0.3, 0.8, 0.76, 0.05 + 0.07 * b))


## A pennant flapping in the draught that comes up the Mouth: a ribbon with a travelling wave.
func _draw_pennant(pn: Dictionary) -> void:
	var pole: Vector2 = pn["pole"]
	var dir: float = pn["dir"]
	draw_line(pole, pole + Vector2(0, 120.0), Color(0, 0, 0, 0.0), 1.0)
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var n := 8
	for i in range(n + 1):
		var f := float(i) / float(n)
		var wave := sin(_t * 3.4 - f * 5.0 + pole.x * 0.01) * 6.0 * f
		top.append(pole + Vector2(dir * f * 56.0, wave))
		bottom.append(pole + Vector2(dir * f * 56.0, 118.0 - 10.0 * f + wave))
	bottom.reverse()
	var poly := PackedVector2Array()
	poly.append_array(top)
	poly.append_array(bottom)
	draw_colored_polygon(poly, CLOTH)
	draw_polyline(top, CLOTH_TRIM, 2.0)


## The gantry crane: the trolley runs along the beam carrying a crate out, lowers it, and comes back for the next.
func _draw_crane() -> void:
	var mid: float = _crane["mid"]
	var y: float = _crane["y"]
	var cycle := fposmod(_t, 16.0) / 16.0
	var beam_y := y - 200.0 + 14.0
	var span := 170.0
	var tx := mid
	var drop := 30.0
	var carrying := false
	if cycle < 0.15:
		tx = mid - span
		drop = lerpf(30.0, 130.0, cycle / 0.15)
	elif cycle < 0.3:
		tx = mid - span
		drop = lerpf(130.0, 30.0, (cycle - 0.15) / 0.15)
		carrying = true
	elif cycle < 0.55:
		tx = lerpf(mid - span, mid + span, (cycle - 0.3) / 0.25)
		drop = 30.0
		carrying = true
	elif cycle < 0.7:
		tx = mid + span
		drop = lerpf(30.0, 130.0, (cycle - 0.55) / 0.15)
		carrying = cycle < 0.66
	elif cycle < 0.85:
		tx = mid + span
		drop = lerpf(130.0, 30.0, (cycle - 0.7) / 0.15)
	else:
		tx = lerpf(mid + span, mid - span, (cycle - 0.85) / 0.15)
		drop = 30.0
	draw_rect(Rect2(tx - 20.0, beam_y - 8.0, 40.0, 14.0), COPPER)
	var hook := Vector2(tx, beam_y + 6.0 + drop)
	draw_line(Vector2(tx, beam_y + 6.0), hook, STEEL_HI, 2.0)
	draw_rect(Rect2(hook.x - 6.0, hook.y, 12.0, 8.0), COPPER)
	if carrying:
		draw_rect(Rect2(hook.x - 17.0, hook.y + 8.0, 34.0, 26.0), TIMBER.lightened(0.05))
		draw_rect(Rect2(hook.x - 17.0, hook.y + 8.0, 34.0, 3.0), Color(0, 0, 0, 0.25))


## A hand cart shuttling along the freight tier, a crate in it, turning at each end.
func _draw_cart(c: Dictionary) -> void:
	var span: float = c["x1"] - c["x0"]
	var f := fposmod((_t + float(c["ph"])) * 38.0, span * 2.0)
	var going_right := f < span
	var x: float = float(c["x0"]) + (f if going_right else span * 2.0 - f)
	var y: float = c["y"]
	var dir := 1.0 if going_right else -1.0
	draw_rect(Rect2(x - 22.0, y - 22.0, 44.0, 12.0), TIMBER.darkened(0.15))
	draw_rect(Rect2(x - 16.0, y - 34.0, 26.0, 12.0), TIMBER.lightened(0.05))
	draw_line(Vector2(x - dir * 22.0, y - 20.0), Vector2(x - dir * 38.0, y - 28.0), STEEL_HI, 2.0)
	for wx in [-13.0, 13.0]:
		draw_circle(Vector2(x + wx, y - 6.0), 6.0, Color(0.1, 0.1, 0.11))
		draw_circle(Vector2(x + wx, y - 6.0), 2.5, STEEL_HI)
