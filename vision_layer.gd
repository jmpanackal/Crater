class_name VisionLayer
extends CanvasLayer
## Terraria-style light. Light is a value per 16px cell, spread outward from its sources and
## weakened as it goes: a little per cell of open air, a lot per cell of rock. So the Hollow, which is
## lit nearly everywhere (ambient light plus lamps), is easy to see in, while the rock is black a few
## cells in: when you dig, you see only the tiles right around you, and the dark closes in behind. The
## whole screen is darkened by (1 - light).
##
## Sources: the Hollow's cavity (HOLLOW_AMBIENT), every HollowDressing lamp, and the player's own light.
## The player's light is what a later mechanic raises: the Rig effect `vision_radius_bonus` (pixels
## of extra reach in open air; it also carries further into rock). No Gear grants it yet.
## Dev: V toggles it; it hides itself in the dev overview zooms.
##
## Cost: the grid covers the screen plus a margin (about 7k cells) and is re-solved ten times a second,
## in four small steps on separate frames, then uploaded as a tiny texture the shader samples.

const CELL := 16
const PLAYER_LIGHT := 0.9 ## the player's own light at their cell
const AIR_COST := 0.09 ## light lost per cell of open air (about ten cells of reach)
const ROCK_COST := 0.34 ## light lost per cell of rock (about two and a half cells of sight into stone)
const HOLLOW_AMBIENT := 0.85 ## the civic cavity: lit nearly everywhere
const WALK_LIGHT := 0.82 ## the authored walking areas (dug galleries, stair and shaft air): you can always see where you can go
const LAMP_LIGHT := 1.0
const MARGIN := 6 ## cells of grid beyond the screen on every side
const MAX_DARK := 0.97
const SOLVE_FRAMES := 6 ## physics frames between solves (each solve is spread over four of them)
const DEV_KEY := KEY_V

var enabled := true

var _rect: ColorRect
var _mat: ShaderMaterial
var _player: Node2D
var _terrain: TileMapLayer
var _lamp_cells: Array[Vector2i] = []
var _cavity: Rect2i
var _walk_rects: Array[Rect2i] = [] ## the map's dug galleries, stairs and shafts, in cells

var _gw := 0
var _gh := 0
var _ox := 0
var _oy := 0
var _light := PackedFloat32Array()
var _cost := PackedFloat32Array()
var _tex: ImageTexture
var _frame := 0
var _solved := false

const SHADER := """
shader_type canvas_item;
uniform sampler2D light_tex : filter_linear, repeat_disable;
uniform vec2 grid_origin = vec2(0.0);
uniform vec2 grid_world_size = vec2(1.0);
uniform vec2 cam_origin = vec2(0.0);
uniform vec2 view_size = vec2(1280.0, 720.0);
uniform float zoom = 1.0;
uniform float max_dark = 0.97;
uniform vec4 tint : source_color = vec4(0.006, 0.01, 0.03, 1.0);
void fragment() {
	vec2 world = cam_origin + UV * view_size / zoom;
	vec2 g = (world - grid_origin) / grid_world_size;
	float l = 0.0;
	if (g.x >= 0.0 && g.y >= 0.0 && g.x <= 1.0 && g.y <= 1.0) {
		l = texture(light_tex, g).r;
	}
	COLOR = vec4(tint.rgb, pow(clamp(1.0 - l, 0.0, 1.0), 1.1) * max_dark);
}
"""


func _ready() -> void:
	layer = 1
	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_rect = ColorRect.new()
	_rect.name = "Dark"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)
	var cav := HollowMap.cavity_rect()
	_cavity = Rect2i(int(cav.position.x) / CELL, int(cav.position.y) / CELL, int(cav.size.x) / CELL, int(cav.size.y) / CELL)
	var authored: Array[Rect2] = HollowMap.flank_air_rects(HollowMap.FLANK_CLEAR)
	authored.append_array(HollowMap.flank_stair_air(HollowMap.FLANK_CLEAR))
	for r in authored:
		var cx0 := int(floorf(r.position.x / float(CELL)))
		var cy0 := int(floorf(r.position.y / float(CELL)))
		_walk_rects.append(Rect2i(cx0, cy0, int(ceilf(r.end.x / float(CELL))) - cx0, int(ceilf(r.end.y / float(CELL))) - cy0))
	for l in HollowDressing.lamps():
		_lamp_cells.append(Vector2i(int(floorf(float(l["x"]) / float(CELL))), int(floorf((HollowMap.lvl(float(l["k"])) - float(l["y_off"])) / float(CELL)))))
	set_process_unhandled_key_input(true)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == DEV_KEY:
		enabled = not enabled
		get_viewport().set_input_as_handled()


## The player's own light for a given Gear bonus (extra pixels of reach in open air).
static func strength_for(bonus_px: float) -> float:
	return PLAYER_LIGHT + maxf(bonus_px, 0.0) / float(CELL) * AIR_COST


func player_strength() -> float:
	var bonus := 0.0
	var rig := get_tree().root.get_node_or_null("Rig") if is_inside_tree() else null
	if rig != null and rig.has_method("get_effect_sum"):
		bonus = float(rig.get_effect_sum(&"vision_radius_bonus"))
	return strength_for(bonus)


## Light (0..1) at a world position from the last solve; 0 outside the solved grid.
func light_at(world: Vector2) -> float:
	var cx := int(floorf(world.x / float(CELL))) - _ox
	var cy := int(floorf(world.y / float(CELL))) - _oy
	if cx < 0 or cy < 0 or cx >= _gw or cy >= _gh:
		return 0.0
	return clampf(_light[cy * _gw + cx], 0.0, 1.0)


func is_dark_visible() -> bool:
	return _rect != null and _rect.visible


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player != null:
			_terrain = _player.get("terrain") as TileMapLayer
	var vp := get_viewport()
	var xform := vp.get_canvas_transform()
	var zoom := xform.get_scale().x
	_rect.visible = enabled and zoom > 0.95 and _player != null and _terrain != null
	if not _rect.visible:
		return
	_frame = (_frame + 1) % SOLVE_FRAMES
	match _frame:
		0:
			_gather(xform, vp.get_visible_rect().size, zoom)
		1:
			_sweep_x()
		2:
			_sweep_y()
		3:
			_publish(xform, vp.get_visible_rect().size, zoom)


## Rebuild the grid for the current view: which cells are rock, the ambient and lamp light, the player.
func _gather(xform: Transform2D, view: Vector2, zoom: float) -> void:
	var cam_origin := -xform.origin / zoom
	var cells_w := int(ceilf(view.x / zoom / float(CELL))) + 2 * MARGIN + 1
	var cells_h := int(ceilf(view.y / zoom / float(CELL))) + 2 * MARGIN + 1
	_ox = int(floorf(cam_origin.x / float(CELL))) - MARGIN
	_oy = int(floorf(cam_origin.y / float(CELL))) - MARGIN
	if cells_w != _gw or cells_h != _gh:
		_gw = cells_w
		_gh = cells_h
		_light.resize(_gw * _gh)
		_cost.resize(_gw * _gh)
	var i := 0
	for cy in range(_oy, _oy + _gh):
		for cx in range(_ox, _ox + _gw):
			var cell := Vector2i(cx, cy)
			if _cavity.has_point(cell):
				_light[i] = HOLLOW_AMBIENT
				_cost[i] = AIR_COST
			elif _terrain.get_cell_source_id(cell) != -1:
				_light[i] = 0.0
				_cost[i] = ROCK_COST
			else:
				_light[i] = 0.0
				_cost[i] = AIR_COST
			i += 1
	# The paths you walk are always lit; only the rock around them (and anything you dig) is dark.
	var view_cells := Rect2i(_ox, _oy, _gw, _gh)
	for wr in _walk_rects:
		var part := wr.intersection(view_cells)
		if part.size.x <= 0 or part.size.y <= 0:
			continue
		for wy in range(part.position.y, part.end.y):
			var row := (wy - _oy) * _gw
			for wx in range(part.position.x, part.end.x):
				var wi := row + (wx - _ox)
				if _light[wi] < WALK_LIGHT:
					_light[wi] = WALK_LIGHT
	for lc in _lamp_cells:
		var lx := lc.x - _ox
		var ly := lc.y - _oy
		if lx >= 0 and ly >= 0 and lx < _gw and ly < _gh:
			_light[ly * _gw + lx] = maxf(_light[ly * _gw + lx], LAMP_LIGHT)
	var pc := Vector2i(int(floorf((_player.global_position.x + 16.0) / float(CELL))) - _ox, int(floorf((_player.global_position.y + 16.0) / float(CELL))) - _oy)
	if pc.x >= 0 and pc.y >= 0 and pc.x < _gw and pc.y < _gh:
		var pi := pc.y * _gw + pc.x
		_light[pi] = maxf(_light[pi], player_strength())
	_solved = false


func _sweep_x() -> void:
	if _gw == 0:
		return
	for y in _gh:
		var row := y * _gw
		for x in range(1, _gw):
			var v := _light[row + x - 1] - _cost[row + x]
			if v > _light[row + x]:
				_light[row + x] = v
		for x in range(_gw - 2, -1, -1):
			var v2 := _light[row + x + 1] - _cost[row + x]
			if v2 > _light[row + x]:
				_light[row + x] = v2


func _sweep_y() -> void:
	if _gw == 0:
		return
	for x in _gw:
		for y in range(1, _gh):
			var i := y * _gw + x
			var v := _light[i - _gw] - _cost[i]
			if v > _light[i]:
				_light[i] = v
		for y in range(_gh - 2, -1, -1):
			var j := y * _gw + x
			var v2 := _light[j + _gw] - _cost[j]
			if v2 > _light[j]:
				_light[j] = v2
	# one more horizontal pass so light turns corners
	_sweep_x()
	_solved = true


func _publish(xform: Transform2D, view: Vector2, zoom: float) -> void:
	if not _solved or _gw == 0:
		return
	var bytes := PackedByteArray()
	bytes.resize(_gw * _gh)
	for i in _gw * _gh:
		bytes[i] = int(clampf(_light[i], 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(_gw, _gh, false, Image.FORMAT_L8, bytes)
	if _tex == null or _tex.get_width() != _gw or _tex.get_height() != _gh:
		_tex = ImageTexture.create_from_image(img)
	else:
		_tex.update(img)
	_mat.set_shader_parameter("light_tex", _tex)
	_mat.set_shader_parameter("grid_origin", Vector2(float(_ox * CELL), float(_oy * CELL)))
	_mat.set_shader_parameter("grid_world_size", Vector2(float(_gw * CELL), float(_gh * CELL)))
	_mat.set_shader_parameter("max_dark", MAX_DARK)
	_update_view(xform, view, zoom)


func _update_view(xform: Transform2D, view: Vector2, zoom: float) -> void:
	_mat.set_shader_parameter("cam_origin", -xform.origin / zoom)
	_mat.set_shader_parameter("view_size", view)
	_mat.set_shader_parameter("zoom", zoom)


func _process(_delta: float) -> void:
	# The camera moves every frame; the light grid only every few. Keep the mapping current.
	if _rect == null or not _rect.visible or _tex == null:
		return
	var vp := get_viewport()
	var xform := vp.get_canvas_transform()
	_update_view(xform, vp.get_visible_rect().size, xform.get_scale().x)


## Test helper: run a whole solve at once.
func solve_now() -> void:
	var vp := get_viewport()
	var xform := vp.get_canvas_transform()
	var view := vp.get_visible_rect().size
	var zoom := xform.get_scale().x
	_gather(xform, view, zoom)
	_sweep_x()
	_sweep_y()
	_publish(xform, view, zoom)
