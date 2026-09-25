class_name UI
extends RefCounted
## Utilidades para construir interfaces con estilo coherente desde código.

const GREEN := Color(0.3, 0.6, 0.25)
const DARK := Color(0.12, 0.14, 0.13)
const PAPER := Color(0.96, 0.93, 0.84)


static func style(bg: Color, radius := 10, border := Color(0, 0, 0, 0), bw := 0, pad := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	return s


static func button(text: String, color := GREEN, font_size := 22, min_size := Vector2(220, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(0.75, 0.75, 0.75))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_stylebox_override("normal", style(color, 12, color.darkened(0.4), 3))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.15), 12, color.darkened(0.4), 3))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.15), 12, color.darkened(0.5), 3))
	b.add_theme_stylebox_override("disabled", style(Color(0.35, 0.37, 0.36), 12, Color(0.2, 0.2, 0.2), 3))
	b.pressed.connect(func(): AudioManager.play("click"))
	return b


static func label(text: String, font_size := 18, color := Color.WHITE, outline := 5, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func panel(bg := Color(0.1, 0.12, 0.11, 0.9), radius := 14, border := Color(1, 1, 1, 0.15)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, radius, border, 2, 14))
	return p


static func place(c: Control, pos: Vector2, size: Vector2) -> Control:
	c.position = pos
	c.size = size
	return c
