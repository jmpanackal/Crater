extends Control
## The tool belt: the Rig's Gear sockets as a hotbar at the bottom-centre, where Terraria, Core Keeper and most
## side-view games keep what you carry. One large socket per Gear slot with its number in the corner, the fitted Gear's
## mark inside (or an empty notch), and the Rig's capacity as a row of pips underneath: lit amber for what the Rig
## carries, hollow for room left, red past capacity (that is Rig Strain, the block on the stamina bar). Read-only: the
## Rig is refitted at a station ([G] opens it), never from here. Reads the Rig autoload. Display only.

## PLACEHOLDER (USER 2026-10-04: "put some placeholder start tools in the hotbar to see what it looks like"): while nothing
## is mounted, the sockets preview the Approved Gear that exists, dimmed. This does not touch the Rig; the real starting
## loadout is not decided (canon: baseline move, dig and tether are never Gear-gated). Set false to show the real,
## empty belt.
const PLACEHOLDER_PREVIEW := true
const PREVIEW_TOOLS: Array[StringName] = [&"fracture_pick", &"load_harness", &"dampening_wrap", &"counterweight_frame"]
const SOCKET := 44.0
const GAP := 8.0
const PIP := 7.0

var _sig := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_sync(true)


func _process(_delta: float) -> void:
	_sync(false)


func _rig() -> Node:
	return get_node_or_null("/root/Rig")


func _sync(force: bool) -> void:
	var rig := _rig()
	if rig == null or not rig.has_method("get_slot_count"):
		return
	var sig := "%s|%d|%d|%d" % [str(rig.get_equipped()), rig.get_slot_count(), rig.get_capacity(), rig.get_capacity_used()]
	if not force and sig == _sig:
		return
	_sig = sig
	var slots: int = rig.get_slot_count()
	custom_minimum_size = Vector2(float(slots) * SOCKET + float(maxi(slots - 1, 0)) * GAP, SOCKET + 14.0)
	size = custom_minimum_size
	var lines := PackedStringArray()
	var eq: Array = rig.get_equipped()
	for i in range(eq.size()):
		lines.append("%d: %s" % [i + 1, rig.get_gear_display_name(eq[i]) if eq[i] != &"" else "empty"])
	lines.append("Capacity %d of %d%s" % [rig.get_capacity_used(), rig.get_capacity(), "  (over: Rig Strain)" if rig.get_overcapacity() > 0 else ""])
	lines.append("Refit at a station.  [G] Rig")
	tooltip_text = "\n".join(lines)
	queue_redraw()


func _any_mounted(eq: Array) -> bool:
	for g in eq:
		if g != &"":
			return true
	return false


## Placeholder marks for the Approved Gear that exists, drawn from simple shapes: a pick, a harness, a wrap, a frame.
func _gear_icon(gear: StringName, r: Rect2, a: float) -> void:
	var c := r.get_center()
	var amber := Color(1.0, 0.82, 0.48, a)
	var steel := Color(0.72, 0.78, 0.82, a)
	var dark := Color(0.3, 0.22, 0.12, a)
	match gear:
		&"fracture_pick":
			draw_line(c + Vector2(-11.0, 12.0), c + Vector2(8.0, -9.0), dark.lightened(0.25), 3.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2.0, -14.0), c + Vector2(15.0, -6.0), c + Vector2(11.0, -2.0), c + Vector2(4.0, -8.0), c + Vector2(-9.0, -3.0)]), steel)
		&"load_harness":
			draw_line(c + Vector2(-8.0, -13.0), c + Vector2(-8.0, 13.0), amber, 3.0)
			draw_line(c + Vector2(8.0, -13.0), c + Vector2(8.0, 13.0), amber, 3.0)
			draw_line(c + Vector2(-8.0, -6.0), c + Vector2(8.0, 4.0), amber, 2.0)
			draw_arc(c + Vector2(0.0, 12.0), 5.0, 0.0, TAU, 12, steel, 2.0)
		&"dampening_wrap":
			for i in range(4):
				draw_arc(c, 5.0 + float(i) * 3.2, 0.3, TAU - 0.3, 18, amber if i % 2 == 0 else dark.lightened(0.3), 2.0)
		&"counterweight_frame":
			draw_line(c + Vector2(-12.0, 13.0), c + Vector2(0.0, -13.0), steel, 3.0)
			draw_line(c + Vector2(12.0, 13.0), c + Vector2(0.0, -13.0), steel, 3.0)
			draw_line(c + Vector2(-7.0, 3.0), c + Vector2(7.0, 3.0), steel, 2.0)
			draw_rect(Rect2(c.x - 5.0, c.y + 5.0, 10.0, 8.0), amber)
		_:
			var mark: String = str(_rig().get_gear_display_name(gear)).substr(0, 1).to_upper()
			draw_string(ThemeDB.fallback_font, Vector2(c.x - 8.0, c.y + 11.0), mark, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, amber)


func _draw() -> void:
	var rig := _rig()
	if rig == null or not rig.has_method("get_slot_count"):
		return
	var eq: Array = rig.get_equipped()
	var slots: int = rig.get_slot_count()
	var x := 0.0
	for i in range(slots):
		var r := Rect2(x, 0.0, SOCKET, SOCKET)
		draw_rect(r.grow(2.0), Color(0.02, 0.02, 0.02, 0.9))
		draw_rect(r, Color(0.085, 0.08, 0.07, 0.94))
		draw_rect(Rect2(r.position, Vector2(SOCKET, 2.0)), Color(1, 0.86, 0.6, 0.1))
		var gear: StringName = eq[i] if i < eq.size() else &""
		var preview := false
		if gear == &"" and PLACEHOLDER_PREVIEW and not _any_mounted(eq) and i < PREVIEW_TOOLS.size():
			gear = PREVIEW_TOOLS[i]
			preview = true
		if gear != &"":
			draw_rect(r.grow(-3.0), Color(0.17, 0.125, 0.07, 0.96 if not preview else 0.7))
			_gear_icon(gear, r, 1.0 if not preview else 0.72)
		else:
			draw_rect(Rect2(x + 12.0, SOCKET * 0.5 - 1.0, SOCKET - 24.0, 2.0), Color(0.24, 0.21, 0.17, 0.9))
		draw_rect(r, Color(0.62, 0.47, 0.27, 0.85), false, 1.5)
		# the key number in the corner, like a hotbar
		draw_string(ThemeDB.fallback_font, Vector2(x + 4.0, 12.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.95, 0.85, 0.65, 0.8))
		x += SOCKET + GAP
	# capacity pips, centred under the belt
	var cap: int = rig.get_capacity()
	var used: int = rig.get_capacity_used()
	var pips := maxi(cap, used)
	var total_w := float(pips) * (PIP + 3.0) - 3.0
	var px := (custom_minimum_size.x - total_w) * 0.5
	for p in range(pips):
		var pr := Rect2(px + float(p) * (PIP + 3.0), SOCKET + 6.0, PIP, PIP)
		var col := Color(0.1, 0.1, 0.1)
		if p < mini(used, cap):
			col = Color(1.0, 0.76, 0.4)
		elif p >= cap and p < used:
			col = Color(0.88, 0.34, 0.28)
		draw_rect(pr.grow(1.0), Color(0.02, 0.02, 0.02, 0.9))
		draw_rect(pr, col)
