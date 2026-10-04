extends Control
## The stamina bar (canon: a fixed full width, never a shrinking "85 / 85"), built the way the best side-view games build
## a vital: a segmented gauge (Hollow Knight, Dead Cells), a pale "ghost" that trails behind when it drops so you see
## what a strenuous action just cost, and a red flash when it runs dry. The green fill is what you have now; the
## right-hand end carries what is blocked, each source hatched in its own tone: hauling (copper), Rig Strain (teal)
## and Fatigue (grey-violet). Quiet when full and idle. Reads the Stamina autoload; display only.

const SOURCES := [
	[&"hauling", Color(0.78, 0.5, 0.26)],
	[&"rig_strain", Color(0.36, 0.7, 0.68)],
	[&"fatigue", Color(0.58, 0.5, 0.7)],
]
const SEGMENTS := 10

var _ghost := -1.0
var _flash := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 14.0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = "Stamina. Hauling, Rig Strain and Fatigue each block part of it until they ease."
	var stamina := get_node_or_null("/root/Stamina")
	if stamina != null and stamina.has_signal("overexertion_triggered"):
		stamina.overexertion_triggered.connect(func(_f: float) -> void: _flash = 0.6)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	var stamina := get_node_or_null("/root/Stamina")
	if stamina != null and stamina.has_method("get_max_stamina"):
		var frac: float = clampf(float(stamina.get_current()) / maxf(float(stamina.get_max_stamina()), 1.0), 0.0, 1.0)
		if _ghost < 0.0 or frac >= _ghost:
			_ghost = frac
		else:
			_ghost = maxf(frac, _ghost - delta * 0.4)
	queue_redraw()


func _draw() -> void:
	var stamina := get_node_or_null("/root/Stamina")
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.02, 0.88))
	if stamina == null or not stamina.has_method("get_max_stamina"):
		draw_rect(Rect2(1, 1, w - 2, h - 2), Color(0.1, 0.1, 0.1, 0.8))
		return
	var max_s: float = maxf(float(stamina.get_max_stamina()), 1.0)
	var cur: float = clampf(float(stamina.get_current()), 0.0, max_s)
	var inner_w := w - 4.0
	var frac := cur / max_s
	var fill_col := Color(0.47, 0.74, 0.42)
	if frac < 0.3:
		fill_col = Color(0.88, 0.4, 0.3).lerp(Color(0.47, 0.74, 0.42), frac / 0.3)
	if _ghost > frac + 0.002:
		draw_rect(Rect2(2.0 + inner_w * frac, 2.0, inner_w * (_ghost - frac), h - 4.0), Color(0.85, 1.0, 0.8, 0.5))
	draw_rect(Rect2(2.0, 2.0, inner_w * frac, h - 4.0), fill_col)
	draw_rect(Rect2(2.0, 2.0, inner_w * frac, 2.0), Color(1, 1, 1, 0.22))
	# blocked segments, packed from the right end
	var right := w - 2.0
	for src in SOURCES:
		var blocked: float = float(stamina.get_block(src[0]))
		if blocked <= 0.0:
			continue
		var bw: float = inner_w * blocked / max_s
		var tone: Color = src[1]
		draw_rect(Rect2(right - bw, 2.0, bw, h - 4.0), Color(tone.r * 0.35, tone.g * 0.35, tone.b * 0.35, 0.95))
		var hx := right - bw
		while hx < right:
			draw_line(Vector2(hx, h - 2.0), Vector2(minf(hx + h - 4.0, right), 2.0), tone, 1.0)
			hx += 5.0
		right -= bw
	# segment ticks: the gauge reads in tenths, a fixed full width
	for q in range(1, SEGMENTS):
		var tx := 2.0 + inner_w * float(q) / float(SEGMENTS)
		draw_line(Vector2(tx, 2.0), Vector2(tx, h - 2.0), Color(0, 0, 0, 0.55), 1.0)
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0.95, 0.3, 0.25, 0.5 * (_flash / 0.6)))
	draw_rect(Rect2(0, 0, w, h), Color(0.64, 0.48, 0.27, 0.85), false, 1.0)
	var quiet := frac >= 0.999 and float(stamina.get_total_blocked()) <= 0.0 and _flash <= 0.0
	modulate.a = 0.5 if quiet else 1.0
