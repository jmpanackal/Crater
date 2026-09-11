extends RefCounted
class_name UiStyle
## Shared Krater UI chrome — ink panels, copper/teal accents, quiet INMOST tone.
## Use for HUD / journal / dialogue / title; keep play camera clear of stacked rails.

const INK := Color(0.05, 0.08, 0.09, 0.88)
const INK_SOLID := Color(0.06, 0.09, 0.1, 0.96)
const INK_SOFT := Color(0.05, 0.08, 0.09, 0.72)
const BORDER_COPPER := Color(0.62, 0.42, 0.28, 0.85)
const BORDER_TEAL := Color(0.28, 0.52, 0.5, 0.75)
const BORDER_DIM := Color(0.35, 0.38, 0.36, 0.55)
const TEXT_PRIMARY := Color(0.9, 0.9, 0.86, 0.95)
const TEXT_MUTED := Color(0.68, 0.72, 0.7, 0.82)
const TEXT_COPPER := Color(0.86, 0.68, 0.48, 0.95)
const TEXT_TEAL := Color(0.62, 0.82, 0.78, 0.92)
const TEXT_AMBER := Color(0.95, 0.82, 0.55, 0.95)
const BTN_BG := Color(0.1, 0.14, 0.15, 0.95)
const BTN_HOVER := Color(0.14, 0.2, 0.2, 1.0)
const BTN_PRESSED := Color(0.08, 0.11, 0.12, 1.0)
const BTN_DISABLED := Color(0.08, 0.1, 0.1, 0.55)

## Target width for primary + Hollow chips (keeps pit visible).
const HUD_CHIP_WIDTH := 248.0


static func panel_style(accent: StringName = &"copper", soft: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = INK_SOFT if soft else INK
	box.border_color = BORDER_TEAL if accent == &"teal" else BORDER_COPPER
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 1)
	return box


static func modal_panel_style() -> StyleBoxFlat:
	var box := panel_style(&"copper", false)
	box.bg_color = INK_SOLID
	box.set_corner_radius_all(5)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.shadow_size = 5
	return box


static func button_style(state: StringName = &"normal", compact: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	match state:
		&"hover":
			box.bg_color = BTN_HOVER
			box.border_color = BORDER_COPPER
		&"pressed":
			box.bg_color = BTN_PRESSED
			box.border_color = Color(0.72, 0.5, 0.32, 0.95)
		&"disabled":
			box.bg_color = BTN_DISABLED
			box.border_color = BORDER_DIM
		_:
			box.bg_color = BTN_BG
			box.border_color = BORDER_DIM
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	var pad_x := 8 if compact else 10
	var pad_y := 3 if compact else 5
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


static func apply_panel(panel: PanelContainer, accent: StringName = &"copper", modal: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", modal_panel_style() if modal else panel_style(accent))


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
		&"primary":
			label.add_theme_font_size_override("font_size", 15)
			label.add_theme_color_override("font_color", TEXT_PRIMARY)
		&"stat":
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", TEXT_PRIMARY)
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
