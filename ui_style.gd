extends RefCounted
class_name UiStyle
## Shared Krater UI chrome — ink panels, copper/teal accents, quiet INMOST tone.
## Use for HUD / journal / dialogue / title; keep play camera clear of stacked rails.

const INK := Color(0.05, 0.08, 0.09, 0.88)
const INK_SOLID := Color(0.06, 0.09, 0.1, 0.96)
const INK_SOFT := Color(0.05, 0.08, 0.09, 0.72)
## Always-visible HUD — quieter than world so the Hollow breathes.
const INK_QUIET := Color(0.035, 0.055, 0.06, 0.42)
const BORDER_COPPER := Color(0.62, 0.42, 0.28, 0.85)
const BORDER_TEAL := Color(0.28, 0.52, 0.5, 0.75)
const BORDER_DIM := Color(0.35, 0.38, 0.36, 0.55)
const BORDER_QUIET := Color(0.32, 0.3, 0.26, 0.28)
const TEXT_PRIMARY := Color(0.94, 0.9, 0.8, 0.97)
const TEXT_MUTED := Color(0.7, 0.74, 0.72, 0.86)
const TEXT_COPPER := Color(0.9, 0.7, 0.45, 0.97)
const TEXT_TEAL := Color(0.62, 0.82, 0.78, 0.92)
const TEXT_AMBER := Color(0.95, 0.82, 0.55, 0.95)
const TEXT_QUIET := Color(0.82, 0.8, 0.74, 0.88)
## Consistent HUD row height at 1920×1080 play framing.
const HUD_ROW_HEIGHT := 16.0
const BTN_BG := Color(0.1, 0.14, 0.15, 0.95)
const BTN_HOVER := Color(0.14, 0.2, 0.2, 1.0)
const BTN_PRESSED := Color(0.08, 0.11, 0.12, 1.0)
const BTN_DISABLED := Color(0.08, 0.1, 0.1, 0.55)

## Target width for primary + Hollow chips (keeps pit / district labels visible).
const HUD_CHIP_WIDTH := 226.0


const PlateStyle := preload("res://ui_plate_style.gd")
## Iron plate fills, a touch warmer than the old ink so the trim and the lamp amber read like the Hollow's own light.
const IRON_FILL := Color(0.085, 0.08, 0.072, 0.92)
const IRON_FILL_QUIET := Color(0.06, 0.058, 0.054, 0.5)
const IRON_FILL_SOLID := Color(0.07, 0.066, 0.06, 0.97)
const BRASS := Color(0.66, 0.5, 0.28, 0.92)
const BRASS_DIM := Color(0.5, 0.4, 0.26, 0.55)
const OXIDE_TEAL := Color(0.3, 0.55, 0.52, 0.85)
const LAMP_AMBER := Color(1.0, 0.76, 0.4, 1.0)
const LAMP_TEAL := Color(0.42, 0.85, 0.8, 1.0)
const LAMP_OFF := Color(0.1, 0.1, 0.1, 1.0)
const ALERT_RED := Color(0.86, 0.34, 0.28, 1.0)


static func panel_style(accent: StringName = &"copper", soft: bool = false) -> StyleBox:
	var box := PlateStyle.new()
	box.fill = IRON_FILL if not soft else Color(IRON_FILL.r, IRON_FILL.g, IRON_FILL.b, 0.8)
	box.trim = OXIDE_TEAL if accent == &"teal" else BRASS
	box.rivet = box.trim
	box.chamfer = 4.0
	box.set_content_margin_all(9.0)
	box.content_margin_top = 7.0
	box.content_margin_bottom = 7.0
	return box


static func quiet_panel_style() -> StyleBox:
	## Top-left always-on chrome: readable, secondary to the cavern.
	var box := PlateStyle.new()
	box.fill = IRON_FILL_QUIET
	box.inner = Color(0.03, 0.03, 0.03, 0.3)
	box.trim = BRASS_DIM
	box.rivet = BRASS_DIM
	box.highlight = Color(1.0, 0.86, 0.6, 0.08)
	box.chamfer = 3.0
	box.trim_width = 1.0
	box.set_content_margin_all(6.0)
	return box


static func modal_panel_style() -> StyleBox:
	var box := PlateStyle.new()
	box.fill = IRON_FILL_SOLID
	box.trim = BRASS
	box.rivet = BRASS
	box.chamfer = 7.0
	box.trim_width = 2.0
	box.set_content_margin_all(14.0)
	return box


static func button_style(state: StringName = &"normal", compact: bool = false) -> StyleBox:
	var box := PlateStyle.new()
	box.rivets = false
	box.chamfer = 3.0
	box.shadow = state != &"pressed"
	match state:
		&"hover":
			box.fill = Color(0.13, 0.115, 0.09, 0.98)
			box.trim = LAMP_AMBER
			box.glow = Color(LAMP_AMBER.r, LAMP_AMBER.g, LAMP_AMBER.b, 0.16)
		&"pressed":
			box.fill = Color(0.05, 0.048, 0.044, 1.0)
			box.trim = Color(0.78, 0.55, 0.3, 0.95)
		&"disabled":
			box.fill = Color(0.06, 0.06, 0.058, 0.6)
			box.trim = BORDER_DIM
			box.highlight = Color(1, 1, 1, 0.0)
		_:
			box.fill = Color(0.105, 0.098, 0.088, 0.96)
			box.trim = BRASS_DIM
	var pad_x := 9.0 if compact else 12.0
	var pad_y := 4.0 if compact else 6.0
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


static func apply_panel(
	panel: PanelContainer, accent: StringName = &"copper", modal: bool = false, quiet: bool = false
) -> void:
	if panel == null:
		return
	if quiet:
		panel.add_theme_stylebox_override("panel", quiet_panel_style())
	elif modal:
		panel.add_theme_stylebox_override("panel", modal_panel_style())
	else:
		panel.add_theme_stylebox_override("panel", panel_style(accent))


static func apply_button(btn: Button, compact: bool = false) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", button_style(&"normal", compact))
	btn.add_theme_stylebox_override("hover", button_style(&"hover", compact))
	btn.add_theme_stylebox_override("pressed", button_style(&"pressed", compact))
	btn.add_theme_stylebox_override("disabled", button_style(&"disabled", compact))
	btn.add_theme_stylebox_override("focus", button_style(&"hover", compact))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", TEXT_AMBER)
	btn.add_theme_color_override("font_pressed_color", TEXT_COPPER)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.52, 0.5, 0.55))
	btn.add_theme_font_size_override("font_size", 11 if compact else 12)


static func apply_label(label: Label, role: StringName = &"body") -> void:
	if label == null:
		return
	match role:
		&"title":
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", TEXT_COPPER)
		&"hud":
			## Always-visible Materials line — strong contrast, compact.
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", TEXT_QUIET)
			label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 0.75))
			label.add_theme_constant_override("outline_size", 2)
			label.add_theme_constant_override("line_spacing", 0)
		&"primary":
			label.add_theme_font_size_override("font_size", 15)
			label.add_theme_color_override("font_color", TEXT_PRIMARY)
		&"stat":
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", TEXT_PRIMARY)
			label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 0.7))
			label.add_theme_constant_override("outline_size", 2)
			label.add_theme_constant_override("line_spacing", 0)
		&"muted":
			label.add_theme_font_size_override("font_size", 10)
			label.add_theme_color_override("font_color", TEXT_MUTED)
		&"accent":
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", TEXT_COPPER)
		&"teal":
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", TEXT_TEAL)
		_:
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", TEXT_PRIMARY)


static func tip(control: Control, text: String) -> void:
	if control == null:
		return
	control.tooltip_text = text
