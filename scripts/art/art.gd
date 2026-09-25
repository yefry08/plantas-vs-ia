class_name Art
extends RefCounted
## Dibujo procedural de todo el arte del juego (plantas, robots, caras, iconos).
## Todas las funciones dibujan en coordenadas locales del CanvasItem recibido.

const INK := Color(0.1, 0.09, 0.08, 1.0)
const SOFT_INK := Color(0.1, 0.09, 0.08, 0.55)
const SKIN_YELLOW := Color(1.0, 0.82, 0.22)


static func font() -> Font:
	return ThemeDB.fallback_font


static func text(ci: CanvasItem, pos: Vector2, s: String, size := 16, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0, outline_color := Color(0, 0, 0, 0.85)) -> void:
	if outline > 0:
		ci.draw_string_outline(font(), pos, s, align, width, size, outline, outline_color)
	ci.draw_string(font(), pos, s, align, width, size, color)


## Texto centrado horizontalmente en cx.
static func text_c(ci: CanvasItem, cx: float, y: float, s: String, size := 16, color := Color.WHITE, outline := 0) -> void:
	text(ci, Vector2(cx - 300.0, y), s, size, color, HORIZONTAL_ALIGNMENT_CENTER, 600.0, outline)


# --- Primitivas -------------------------------------------------------------

static func ellipse(c: Vector2, rx: float, ry: float, rot := 0.0, n := 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func fill_ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	ci.draw_colored_polygon(ellipse(c, rx, ry, rot), col)


static func rrect_points(r: Rect2, rad: float, seg := 3) -> PackedVector2Array:
	rad = min(rad, min(r.size.x, r.size.y) * 0.5 - 0.05)
	var pts := PackedVector2Array()
	if rad < 1.0:
		pts.append(r.position)
		pts.append(Vector2(r.end.x, r.position.y))
		pts.append(r.end)
		pts.append(Vector2(r.position.x, r.end.y))
		return pts
	var cs: Array[Vector2] = [
		Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.position.y + rad), Vector2(r.end.x - rad, r.position.y + rad),
	]
	for k in 4:
		for i in seg + 1:
			var a := PI * 0.5 * k + PI * 0.5 * float(i) / float(seg)
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func rrect(ci: CanvasItem, r: Rect2, rad: float, col: Color, border := Color(0, 0, 0, 0), bw := 2.0) -> void:
	var pts := rrect_points(r, rad)
	ci.draw_colored_polygon(pts, col)
	if border.a > 0.0:
		pts.append(pts[0])
		ci.draw_polyline(pts, border, bw, true)


static func poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), col)


static func star_points(c: Vector2, outer: float, inner: float, n := 5, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var r := outer if i % 2 == 0 else inner
		var a := rot + PI * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-5, -3) * s, 6.0 * s, col)
	ci.draw_circle(c + Vector2(5, -3) * s, 6.0 * s, col)
	poly(ci, [c + Vector2(-10.7, -0.8) * s, c + Vector2(10.7, -0.8) * s, c + Vector2(0, 11) * s], col)


static func power_icon(ci: CanvasItem, c: Vector2, r: float, col: Color, w := 3.0) -> void:
	ci.draw_arc(c, r, -PI / 2.0 + 0.65, PI * 1.5 - 0.65, 20, col, w, true)
	ci.draw_line(c, c + Vector2(0, -r * 1.15), col, w)


static func lock_icon(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_arc(c + Vector2(0, -4) * s, 6.0 * s, PI, TAU, 12, col, 3.0 * s)
	rrect(ci, Rect2(c + Vector2(-9, -4) * s, Vector2(18, 14) * s), 3.0 * s, col)
	ci.draw_circle(c + Vector2(0, 2) * s, 2.2 * s, INK)


static func bolt(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	poly(ci, [c + Vector2(-3, -14) * s, c + Vector2(7, -14) * s, c + Vector2(1, -3) * s, c + Vector2(8, -3) * s,
		c + Vector2(-6, 15) * s, c + Vector2(-2, 1) * s, c + Vector2(-9, 1) * s], col)


static func sun_icon(ci: CanvasItem, c: Vector2, r: float, t := 0.0) -> void:
	for i in 10:
		var a := t * 0.8 + TAU * float(i) / 10.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * r * 1.05, c + d * r * 1.5, Color(1.0, 0.78, 0.15), max(2.0, r * 0.16))
	ci.draw_circle(c, r * 1.12, Color(1.0, 0.75, 0.1, 0.35))
	ci.draw_circle(c, r, Color(1.0, 0.86, 0.25))
	ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.45, Color(1.0, 0.96, 0.7))


static func token_icon(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r, Color(0.78, 0.55, 0.1))
	ci.draw_circle(c, r * 0.84, Color(1.0, 0.8, 0.22))
	ci.draw_arc(c, r * 0.66, 0, TAU, 20, Color(0.85, 0.6, 0.12), max(1.0, r * 0.1))
	var s := r / 14.0
	rrect(ci, Rect2(c + Vector2(-6, -7) * s, Vector2(12, 3.5) * s), 1.0, Color(0.6, 0.38, 0.05))
	rrect(ci, Rect2(c + Vector2(-1.8, -7) * s, Vector2(3.6, 14) * s), 1.0, Color(0.6, 0.38, 0.05))


static func shovel_icon(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_line(c + Vector2(10, -22) * s, c + Vector2(-4, 6) * s, Color(0.55, 0.35, 0.18), 6.0 * s)
	rrect(ci, Rect2(c + Vector2(4, -30) * s, Vector2(16, 8) * s), 3.0 * s, Color(0.45, 0.28, 0.12))
	poly(ci, [c + Vector2(-2, 2) * s, c + Vector2(-12, -3) * s, c + Vector2(-20, 14) * s, c + Vector2(-12, 26) * s, c + Vector2(0, 16) * s], Color(0.72, 0.75, 0.8))


static func shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	fill_ellipse(ci, c, rx, rx * 0.25, Color(0, 0, 0, 0.22))


static func _col(c: Color, o: Dictionary) -> Color:
	var out := c
	if bool(o.get("hacked", false)):
		var g := (c.r + c.g + c.b) / 3.0
		out = c.lerp(Color(g, g, g * 1.05), 0.7)
	if float(o.get("flash", 0.0)) > 0.0:
		out = out.lerp(Color.WHITE, 0.55)
	return out


# --- Caras tipo emoji (dibujadas, sin fuentes de emoji) ---------------------

static func face(ci: CanvasItem, c: Vector2, r: float, expr: String, skin := SKIN_YELLOW, flash := false) -> void:
	var sk := skin.lerp(Color.WHITE, 0.5) if flash else skin
	ci.draw_circle(c, r, sk)
	if expr == "angry":
		ci.draw_circle(c + Vector2(0, r * 0.1), r * 0.9, Color(1.0, 0.25, 0.1, 0.35))
	ci.draw_arc(c, r, 0, TAU, 32, sk.darkened(0.45), 2.0, true)
	var ink := Color(0.28, 0.15, 0.05)
	var el := c + Vector2(-r * 0.36, -r * 0.16)
	var er := c + Vector2(r * 0.3, -r * 0.16)
	var w: float = max(2.0, r * 0.1)
	match expr:
		"happy", "hug":
			ci.draw_arc(el, r * 0.16, PI * 1.1, PI * 1.9, 8, ink, w, true)
			ci.draw_arc(er, r * 0.16, PI * 1.1, PI * 1.9, 8, ink, w, true)
			ci.draw_arc(c + Vector2(0, r * 0.08), r * 0.48, PI * 0.12, PI * 0.88, 14, ink, w + 0.5, true)
			ci.draw_circle(c + Vector2(-r * 0.6, r * 0.22), r * 0.15, Color(1.0, 0.45, 0.45, 0.55))
			ci.draw_circle(c + Vector2(r * 0.55, r * 0.22), r * 0.15, Color(1.0, 0.45, 0.45, 0.55))
		"angry":
			ci.draw_circle(el + Vector2(0, r * 0.05), r * 0.1, ink)
			ci.draw_circle(er + Vector2(0, r * 0.05), r * 0.1, ink)
			ci.draw_line(el + Vector2(-r * 0.22, -r * 0.26), el + Vector2(r * 0.2, -r * 0.1), ink, w)
			ci.draw_line(er + Vector2(-r * 0.2, -r * 0.1), er + Vector2(r * 0.22, -r * 0.26), ink, w)
			ci.draw_arc(c + Vector2(0, r * 0.68), r * 0.34, PI * 1.2, PI * 1.8, 10, ink, w + 0.5, true)
		"sleep":
			ci.draw_line(el + Vector2(-r * 0.14, 0), el + Vector2(r * 0.14, 0), ink, w)
			ci.draw_line(er + Vector2(-r * 0.14, 0), er + Vector2(r * 0.14, 0), ink, w)
			ci.draw_arc(c + Vector2(0, r * 0.4), r * 0.12, 0, TAU, 12, ink, w * 0.8, true)
		"shock":
			ci.draw_circle(el, r * 0.15, Color.WHITE)
			ci.draw_circle(er, r * 0.15, Color.WHITE)
			ci.draw_circle(el, r * 0.07, ink)
			ci.draw_circle(er, r * 0.07, ink)
			ci.draw_circle(c + Vector2(0, r * 0.42), r * 0.16, ink)
		"smirk":
			ci.draw_circle(el, r * 0.09, ink)
			ci.draw_circle(er, r * 0.09, ink)
			ci.draw_arc(c + Vector2(r * 0.12, r * 0.2), r * 0.3, PI * 0.05, PI * 0.6, 8, ink, w, true)
		_:
			ci.draw_circle(el, r * 0.1, ink)
			ci.draw_circle(er, r * 0.1, ink)
			ci.draw_line(c + Vector2(-r * 0.25, r * 0.4), c + Vector2(r * 0.25, r * 0.4), ink, w)


# --- Plantas ----------------------------------------------------------------

static func plant(ci: CanvasItem, id: String, t: float, o: Dictionary = {}) -> void:
	match id:
		"lanzasemillas":
			_shooter(ci, t, o, Color(0.38, 0.76, 0.26), Color(0.2, 0.48, 0.14), 1, false)
		"lanzasemillas_crio":
			_shooter(ci, t, o, Color(0.45, 0.78, 0.92), Color(0.2, 0.45, 0.6), 1, true)
		"doble_commit":
			_shooter(ci, t, o, Color(0.3, 0.66, 0.22), Color(0.14, 0.38, 0.1), 2, false)
		"girasolar":
			shadow(ci, Vector2(0, 38), 26)
			_stem(ci, Vector2(0, 38), Vector2(0, -8), o)
			_sunflower(ci, Vector2(sin(t * 1.6) * 2.0, -14), 1.0, t, o, Color(1.0, 0.8, 0.12))
		"brotecito_solar":
			shadow(ci, Vector2(0, 38), 18)
			_stem(ci, Vector2(0, 38), Vector2(0, 8), o)
			_sunflower(ci, Vector2(sin(t * 1.6) * 1.5, 6), 0.66, t, o, Color(1.0, 0.9, 0.35))
		"girasolar_doble":
			shadow(ci, Vector2(0, 38), 30)
			_stem(ci, Vector2(0, 38), Vector2(-14, -2), o)
			_stem(ci, Vector2(0, 38), Vector2(14, -18), o)
			_sunflower(ci, Vector2(-14, -4 + sin(t * 1.7) * 2.0), 0.78, t, o, Color(1.0, 0.62, 0.1))
			_sunflower(ci, Vector2(14, -22 + sin(t * 1.5) * 2.0), 0.78, t + 1.0, o, Color(1.0, 0.8, 0.12))
		"nuez_firewall":
			_wall(ci, t, o, false)
		"nuez_firewall_pro":
			_wall(ci, t, o, true)
		"cactus_antivirus":
			_cactus(ci, t, o)
		"hongo_emp":
			_mushroom(ci, t, o)
		"enredadera_captcha":
			_vine(ci, t, o)
		"tokenizadora":
			_token_flower(ci, t, o)
		"bambu_pararrayos":
			_bamboo(ci, t, o)
		"mina_bug":
			_mine(ci, t, o)
		_:
			ci.draw_circle(Vector2.ZERO, 30, Color.MAGENTA)


static func _stem(ci: CanvasItem, from: Vector2, to: Vector2, o: Dictionary) -> void:
	ci.draw_line(from, to, _col(Color(0.2, 0.5, 0.15), o), 6.0)
	var mid := from.lerp(to, 0.25)
	fill_ellipse(ci, mid + Vector2(-13, 0), 14, 6, _col(Color(0.34, 0.68, 0.22), o), -0.4)
	fill_ellipse(ci, mid + Vector2(13, 0), 14, 6, _col(Color(0.34, 0.68, 0.22), o), 0.4)


static func _shooter(ci: CanvasItem, t: float, o: Dictionary, main: Color, dark: Color, heads: int, crio: bool) -> void:
	var sway := sin(t * 2.0) * 2.0
	var rec := float(o.get("anim", 0.0)) * 30.0
	shadow(ci, Vector2(0, 38), 24)
	_stem(ci, Vector2(0, 38), Vector2(sway * 0.5, -2), o)
	if heads >= 2:
		_shooter_head(ci, Vector2(-12 + sway - rec * 0.5, 2), 0.82, main.darkened(0.18), dark, o, crio)
	_shooter_head(ci, Vector2(sway - rec, -16), 1.0, main, dark, o, crio)


static func _shooter_head(ci: CanvasItem, c: Vector2, s: float, main: Color, dark: Color, o: Dictionary, crio: bool) -> void:
	fill_ellipse(ci, c + Vector2(-22, -12) * s, 12.0 * s, 5.0 * s, _col(dark, o), -0.7)
	ci.draw_circle(c, 21.0 * s, _col(main, o))
	rrect(ci, Rect2(c + Vector2(10, -10) * s, Vector2(26, 18) * s), 6.0 * s, _col(main, o))
	ci.draw_circle(c + Vector2(37, -1) * s, 10.0 * s, _col(dark, o))
	ci.draw_circle(c + Vector2(38, -1) * s, 6.0 * s, Color(0.05, 0.1, 0.05))
	ci.draw_arc(c, 21.0 * s, 0, TAU, 24, _col(dark, o), 2.0, true)
	ci.draw_circle(c + Vector2(2, -8) * s, 6.5 * s, Color.WHITE)
	ci.draw_circle(c + Vector2(4.5, -8) * s, 3.4 * s, INK)
	if crio:
		for i in 3:
			var b := c + Vector2(-12 + i * 10, -17) * s
			poly(ci, [b + Vector2(-4, 2) * s, b + Vector2(0, -12) * s, b + Vector2(4, 2) * s], Color(0.85, 0.97, 1.0))


static func _sunflower(ci: CanvasItem, c: Vector2, s: float, t: float, o: Dictionary, petal: Color) -> void:
	var glow := float(o.get("glow", 0.0))
	if glow > 0.0:
		ci.draw_circle(c, 42.0 * s, Color(1.0, 0.9, 0.3, glow * 0.45))
	var rot := t * 0.4
	for i in 12:
		var a := rot + TAU * float(i) / 12.0
		fill_ellipse(ci, c + Vector2(cos(a), sin(a)) * 22.0 * s, 10.0 * s, 6.0 * s, _col(petal, o), a)
	ci.draw_circle(c, 17.0 * s, _col(Color(0.13, 0.2, 0.44), o))
	var grid_col := Color(0.35, 0.52, 0.9, 0.9)
	for k in [-6.0, 0.0, 6.0]:
		var hw := sqrt(max(0.0, 17.0 * 17.0 - k * k)) - 1.0
		ci.draw_line(c + Vector2(-hw, k) * s, c + Vector2(hw, k) * s, grid_col, 1.0)
		ci.draw_line(c + Vector2(k, -hw) * s, c + Vector2(k, hw) * s, grid_col, 1.0)
	ci.draw_circle(c + Vector2(-6, -3) * s, 3.4 * s, Color.WHITE)
	ci.draw_circle(c + Vector2(6, -3) * s, 3.4 * s, Color.WHITE)
	ci.draw_arc(c + Vector2(0, 2) * s, 7.0 * s, PI * 0.15, PI * 0.85, 10, Color.WHITE, 2.0, true)


static func _wall(ci: CanvasItem, t: float, o: Dictionary, pro: bool) -> void:
	var rx := 34.0
	var ry := 48.0 if pro else 40.0
	var c := Vector2(0, 38 - ry)
	var base := Color(0.72, 0.32, 0.2) if pro else Color(0.64, 0.42, 0.22)
	shadow(ci, Vector2(0, 38), 30)
	for i in 3:
		var fx := -14.0 + i * 14.0
		var fh := 12.0 + sin(t * 9.0 + i * 2.0) * 4.0
		var top := c.y - ry + 4.0
		poly(ci, [Vector2(fx - 7, top + 4), Vector2(fx + sin(t * 7.0 + i) * 2.0, top - fh), Vector2(fx + 7, top + 4)], Color(1.0, 0.55, 0.1, 0.9))
		poly(ci, [Vector2(fx - 3, top + 4), Vector2(fx, top - fh * 0.5), Vector2(fx + 3, top + 4)], Color(1.0, 0.9, 0.3))
	fill_ellipse(ci, c, rx, ry, _col(base, o), 0.0)
	var mortar := _col(base.darkened(0.35), o)
	for j in range(-3, 4):
		var y := c.y + j * 13.0
		var ny := (y - c.y) / ry
		if abs(ny) >= 0.95:
			continue
		var hw := rx * sqrt(1.0 - ny * ny) - 2.0
		ci.draw_line(Vector2(-hw, y), Vector2(hw, y), mortar, 2.0)
		var off := 0.0 if j % 2 == 0 else 11.0
		for k in range(-2, 3):
			var x := k * 22.0 + off - 11.0
			if abs(x) < hw - 4.0:
				ci.draw_line(Vector2(x, y), Vector2(x, y + 13.0), mortar, 2.0)
	if pro:
		rrect(ci, Rect2(-rx + 2, c.y + 6, rx * 2 - 4, 8), 3, _col(Color(0.6, 0.62, 0.66), o))
	var outline := ellipse(c, rx, ry, 0.0, 24)
	outline.append(outline[0])
	ci.draw_polyline(outline, SOFT_INK, 2.0, true)
	var hp := float(o.get("hp", 1.0))
	var ey := c.y - 8.0
	ci.draw_circle(Vector2(-10, ey), 7, Color.WHITE)
	ci.draw_circle(Vector2(10, ey), 7, Color.WHITE)
	ci.draw_circle(Vector2(-8, ey + 1), 3.5, INK)
	ci.draw_circle(Vector2(12, ey + 1), 3.5, INK)
	if hp < 0.66:
		ci.draw_polyline(PackedVector2Array([Vector2(-20, c.y - 20), Vector2(-12, c.y - 10), Vector2(-18, c.y), Vector2(-10, c.y + 12)]), INK, 2.0)
	if hp < 0.33:
		ci.draw_polyline(PackedVector2Array([Vector2(22, c.y - 12), Vector2(12, c.y), Vector2(20, c.y + 10), Vector2(14, c.y + 24)]), INK, 2.0)
		ci.draw_line(Vector2(-16, ey - 12), Vector2(-5, ey - 8), INK, 2.5)
		ci.draw_line(Vector2(16, ey - 12), Vector2(5, ey - 8), INK, 2.5)


static func _cactus(ci: CanvasItem, t: float, o: Dictionary) -> void:
	var green := _col(Color(0.3, 0.62, 0.32), o)
	var dark := _col(Color(0.16, 0.4, 0.2), o)
	shadow(ci, Vector2(0, 38), 24)
	var rec := float(o.get("anim", 0.0)) * 20.0
	rrect(ci, Rect2(-32 - rec * 0.3, -26, 12, 24), 6, green)
	rrect(ci, Rect2(-32 - rec * 0.3, -6, 20, 12), 6, green)
	rrect(ci, Rect2(-16 - rec * 0.3, -42 + sin(t * 2.0), 32, 80), 15, green, dark, 2.0)
	for i in 7:
		var y := -34.0 + i * 11.0
		ci.draw_line(Vector2(16, y), Vector2(23, y - 3), Color(0.95, 0.95, 0.8), 2.0)
		ci.draw_line(Vector2(-16, y), Vector2(-23, y - 3), Color(0.95, 0.95, 0.8), 2.0)
	poly(ci, [Vector2(-9, -8), Vector2(9, -8), Vector2(9, 3), Vector2(0, 13), Vector2(-9, 3)], Color(0.97, 0.97, 0.97))
	ci.draw_rect(Rect2(-2, -5, 4, 13), Color(0.85, 0.15, 0.15))
	ci.draw_rect(Rect2(-6, -1, 12, 4), Color(0.85, 0.15, 0.15))
	ci.draw_circle(Vector2(-5, -26), 4.5, Color.WHITE)
	ci.draw_circle(Vector2(7, -26), 4.5, Color.WHITE)
	ci.draw_circle(Vector2(-3.5, -26), 2.2, INK)
	ci.draw_circle(Vector2(8.5, -26), 2.2, INK)


static func _mushroom(ci: CanvasItem, t: float, o: Dictionary) -> void:
	var charge := float(o.get("charge", 0.0))
	shadow(ci, Vector2(0, 38), 26)
	if charge >= 0.99:
		ci.draw_circle(Vector2(0, -6), 44 + sin(t * 8.0) * 3.0, Color(0.7, 0.45, 1.0, 0.22))
	rrect(ci, Rect2(-12, 2, 24, 36), 8, _col(Color(0.95, 0.9, 0.78), o), SOFT_INK)
	var cap := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		cap.append(Vector2(cos(a) * 38.0, 6.0 + sin(a) * 36.0))
	ci.draw_colored_polygon(cap, _col(Color(0.5, 0.28, 0.72), o))
	ci.draw_circle(Vector2(-22, -8), 5, Color(1, 1, 1, 0.7))
	ci.draw_circle(Vector2(22, -6), 4, Color(1, 1, 1, 0.7))
	ci.draw_circle(Vector2(12, -22), 3.5, Color(1, 1, 1, 0.7))
	bolt(ci, Vector2(-2, -12), 0.9, Color(1.0, 0.9, 0.2).lerp(Color.WHITE, charge * 0.5))
	ci.draw_arc(Vector2(0, 6), 38, PI, TAU, 16, Color(0.3, 0.15, 0.45), 2.0, true)
	ci.draw_circle(Vector2(-5, 16), 2.6, INK)
	ci.draw_circle(Vector2(6, 16), 2.6, INK)
	if charge < 0.99:
		ci.draw_arc(Vector2(0, 26), 7, -PI / 2.0, -PI / 2.0 + TAU * charge, 16, Color(0.5, 0.28, 0.72), 2.0)


static func _vine(ci: CanvasItem, t: float, o: Dictionary) -> void:
	var g := _col(Color(0.22, 0.52, 0.18), o)
	var lg := _col(Color(0.4, 0.72, 0.26), o)
	for k in 2:
		var pts := PackedVector2Array()
		for i in 13:
			var x := -42.0 + i * 7.0
			pts.append(Vector2(x, 26.0 + k * 8.0 + sin(x * 0.2 + t * 2.0 + k * 2.0) * 5.0))
		ci.draw_polyline(pts, g, 4.0, true)
	for i in 5:
		fill_ellipse(ci, Vector2(-34 + i * 17, 22 + (i % 2) * 14), 7, 4, lg, 0.6 * (i % 2 * 2 - 1))
	ci.draw_line(Vector2(-4, 26), Vector2(-2, 6), g, 3.0)
	rrect(ci, Rect2(-15, -22, 30, 30), 4, Color(0.98, 0.98, 0.98), Color(0.55, 0.55, 0.6), 2.0)
	ci.draw_polyline(PackedVector2Array([Vector2(-8, -8), Vector2(-2, 0), Vector2(10, -16)]), Color(0.1, 0.65, 0.25), 4.0, true)


static func _token_flower(ci: CanvasItem, t: float, o: Dictionary) -> void:
	shadow(ci, Vector2(0, 38), 24)
	_stem(ci, Vector2(0, 38), Vector2(0, -8), o)
	var c := Vector2(sin(t * 1.4) * 2.0, -14)
	var glow := float(o.get("glow", 0.0))
	if glow > 0.0:
		ci.draw_circle(c, 40, Color(1.0, 0.85, 0.3, glow * 0.5))
	for i in 8:
		var a := -t * 0.3 + TAU * float(i) / 8.0
		fill_ellipse(ci, c + Vector2(cos(a), sin(a)) * 22.0, 11, 7, _col(Color(0.62, 0.36, 0.86), o), a)
	token_icon(ci, c, 16)


static func _bamboo(ci: CanvasItem, t: float, o: Dictionary) -> void:
	var charge := float(o.get("charge", 0.0))
	var g := _col(Color(0.58, 0.76, 0.3), o)
	var d := _col(Color(0.34, 0.5, 0.16), o)
	shadow(ci, Vector2(0, 38), 20)
	fill_ellipse(ci, Vector2(-18, -14), 12, 4, d, -0.5)
	fill_ellipse(ci, Vector2(18, 4), 12, 4, d, 0.5)
	for i in 3:
		var y := 14.0 - i * 26.0
		rrect(ci, Rect2(-12, y, 24, 25), 5, g, d, 2.0)
		ci.draw_line(Vector2(-12, y + 1), Vector2(12, y + 1), d, 3.0)
	ci.draw_line(Vector2(0, -38), Vector2(0, -64), Color(0.7, 0.72, 0.76), 3.0)
	ci.draw_circle(Vector2(0, -66), 5, Color(0.85, 0.87, 0.9))
	ci.draw_circle(Vector2(-5, 0), 2.8, INK)
	ci.draw_circle(Vector2(5, 0), 2.8, INK)
	ci.draw_arc(Vector2(0, 6), 4, PI * 0.1, PI * 0.9, 6, INK, 1.5)
	if charge > 0.75:
		var a := t * 20.0
		for k in 3:
			var dir := Vector2(cos(a + k * 2.1), sin(a + k * 2.1))
			ci.draw_line(Vector2(0, -66) + dir * 6.0, Vector2(0, -66) + dir * 14.0, Color(1.0, 0.95, 0.4), 2.0)


static func _mine(ci: CanvasItem, t: float, o: Dictionary) -> void:
	var armed := bool(o.get("armed", false))
	fill_ellipse(ci, Vector2(0, 30), 30, 10, _col(Color(0.45, 0.3, 0.18), o))
	if not armed:
		ci.draw_circle(Vector2(0, 24), 10, _col(Color(0.55, 0.12, 0.12), o))
		ci.draw_line(Vector2(-4, 16), Vector2(-9, 6), INK, 2.0)
		ci.draw_line(Vector2(4, 16), Vector2(9, 6), INK, 2.0)
		ci.draw_circle(Vector2(-3, 22), 2, Color.WHITE)
		ci.draw_circle(Vector2(3, 22), 2, Color.WHITE)
		return
	for k in 3:
		var y := 6.0 + k * 9.0
		ci.draw_line(Vector2(-20, y), Vector2(-30, y + 5), INK, 2.0)
		ci.draw_line(Vector2(20, y), Vector2(30, y + 5), INK, 2.0)
	fill_ellipse(ci, Vector2(0, 14), 23, 18, _col(Color(0.62, 0.1, 0.1), o))
	ci.draw_line(Vector2(0, -3), Vector2(0, 31), INK, 2.0)
	ci.draw_circle(Vector2(-10, 10), 4, INK)
	ci.draw_circle(Vector2(10, 18), 4, INK)
	ci.draw_circle(Vector2(0, -6), 9, _col(Color(0.2, 0.1, 0.1), o))
	var on := sin(t * 9.0) > 0.0
	ci.draw_circle(Vector2(0, -10), 4, Color(1.0, 0.2, 0.15) if on else Color(0.4, 0.05, 0.05))


# --- Robots -----------------------------------------------------------------

static func robot(ci: CanvasItem, rd: RobotData, t: float, o: Dictionary) -> void:
	var fl := float(o.get("flash", 0.0)) > 0.0
	var body := rd.body_color.lerp(Color.WHITE, 0.55) if fl else rd.body_color
	var acc := rd.accent_color.lerp(Color.WHITE, 0.55) if fl else rd.accent_color
	var eye := rd.eye_color
	var walking := bool(o.get("walk", true))
	var step := sin(t * 7.0) * 4.0 if walking else 0.0
	var shape := String(rd.params.get("shape", "box"))
	shadow(ci, Vector2(0, 42), 28)
	match shape:
		"box":
			_bot_box(ci, body, acc, eye, step, t)
		"spam":
			_bot_spam(ci, body, acc, eye, step, t)
		"captcha":
			_bot_box(ci, body, acc, eye, step, t)
			_captcha_shield(ci, float(o.get("shield", 0.0)))
		"emoji":
			_bot_emoji(ci, body, acc, step, String(o.get("expr", "happy")), fl)
		"dragon":
			_bot_dragon(ci, body, acc, eye, step, t)
		"qilin":
			_bot_qilin(ci, body, acc, eye, step, t)
		"orb":
			_bot_orb(ci, body, acc, eye, step, t, bool(o.get("thinking", false)))
		"rebel":
			_bot_rebel(ci, body, acc, eye, step, t)
		"twin":
			_bot_twin(ci, body, acc, eye, step)
		"claw":
			_bot_claw(ci, body, acc, eye, step, t, float(o.get("grab", 0.0)))
		"book":
			_bot_book(ci, body, acc, eye, t)
		"tank":
			_bot_tank(ci, body, acc, eye, t, walking)
		"star":
			_bot_star(ci, body, acc, eye, step, t, walking)
		_:
			_bot_box(ci, body, acc, eye, step, t)


static func _legs(ci: CanvasItem, step: float, col: Color, h := 22.0) -> void:
	var top := 38.0 - h
	rrect(ci, Rect2(-15 + step, top, 10, h - 2), 3, col)
	rrect(ci, Rect2(3 - step, top, 10, h - 2), 3, col)
	rrect(ci, Rect2(-19 + step, 34, 15, 6), 2, col.darkened(0.3))
	rrect(ci, Rect2(-1 - step, 34, 15, 6), 2, col.darkened(0.3))


static func _antenna(ci: CanvasItem, base: Vector2, col: Color, eye: Color, t: float) -> void:
	ci.draw_line(base, base + Vector2(0, -12), col.darkened(0.2), 3.0)
	var on := fmod(t, 1.6) < 1.2
	ci.draw_circle(base + Vector2(0, -14), 4, eye if on else eye.darkened(0.6))


static func _bot_box(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	_legs(ci, step, acc.darkened(0.25))
	rrect(ci, Rect2(-22, -14, 44, 34), 7, body, SOFT_INK)
	rrect(ci, Rect2(-14, -8, 28, 17), 3, Color(0.1, 0.14, 0.18))
	ci.draw_polyline(PackedVector2Array([Vector2(-6, -4), Vector2(-10, 0.5), Vector2(-6, 5)]), eye, 2.0)
	ci.draw_polyline(PackedVector2Array([Vector2(6, -4), Vector2(10, 0.5), Vector2(6, 5)]), eye, 2.0)
	ci.draw_line(Vector2(2, -5), Vector2(-2, 6), eye, 2.0)
	ci.draw_line(Vector2(-18, -4), Vector2(-34, 6 + step), acc, 6.0)
	ci.draw_circle(Vector2(-34, 6 + step), 4.5, acc.darkened(0.2))
	rrect(ci, Rect2(-18, -46, 36, 30), 7, acc, SOFT_INK)
	rrect(ci, Rect2(-15, -40, 26, 13), 4, Color(0.08, 0.1, 0.14))
	ci.draw_circle(Vector2(-9, -33.5), 3.5, eye)
	ci.draw_circle(Vector2(1, -33.5), 3.5, eye)
	_antenna(ci, Vector2(0, -46), acc, eye, t)


static func _bot_spam(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	_legs(ci, step * 1.4, acc.darkened(0.25), 18.0)
	rrect(ci, Rect2(-18, -8, 36, 28), 8, body, SOFT_INK)
	ci.draw_rect(Rect2(-11, -3, 22, 14), Color(0.98, 0.98, 1.0))
	ci.draw_polyline(PackedVector2Array([Vector2(-11, -3), Vector2(0, 5), Vector2(11, -3)]), Color(0.5, 0.5, 0.6), 1.5)
	rrect(ci, Rect2(-16, -38, 32, 28), 8, acc, SOFT_INK)
	rrect(ci, Rect2(-13, -31, 22, 11), 4, Color(0.15, 0.05, 0.12))
	ci.draw_circle(Vector2(-8, -25.5), 3, eye)
	ci.draw_circle(Vector2(1, -25.5), 3, eye)
	ci.draw_line(Vector2(0, -38), Vector2(0, -48), acc.darkened(0.2), 2.0)
	ci.draw_arc(Vector2(0, -52), 5, 0, TAU * 0.85, 12, eye, 2.0)
	ci.draw_circle(Vector2(0, -52), 1.8, eye)
	var wig := sin(t * 14.0) * 5.0
	ci.draw_line(Vector2(-16, 0), Vector2(-28, -8 + wig), acc, 4.0)


static func _captcha_shield(ci: CanvasItem, ratio: float) -> void:
	if ratio <= 0.0:
		return
	ci.draw_line(Vector2(-18, -2), Vector2(-34, -2), Color(0.45, 0.3, 0.15), 4.0)
	var card := Color(0.76, 0.6, 0.38)
	rrect(ci, Rect2(-52, -46, 22, 80), 3, card, Color(0.45, 0.32, 0.18), 2.0)
	for i in 4:
		var y := -36.0 + i * 18.0
		var pts := PackedVector2Array()
		for k in 6:
			pts.append(Vector2(-49 + k * 3.2, y + (4.0 if k % 2 == 0 else -2.0)))
		ci.draw_polyline(pts, Color(0.25, 0.2, 0.5), 2.0)
	if ratio < 0.5:
		ci.draw_polyline(PackedVector2Array([Vector2(-52, -10), Vector2(-44, -2), Vector2(-48, 8), Vector2(-38, 18)]), INK, 2.0)


static func _bot_emoji(ci: CanvasItem, body: Color, acc: Color, step: float, expr: String, fl: bool) -> void:
	_legs(ci, step, body.darkened(0.3), 20.0)
	rrect(ci, Rect2(-16, -6, 32, 26), 10, body, SOFT_INK)
	var c := Vector2(0, -28)
	if expr != "hug":
		ci.draw_line(Vector2(-14, 2), Vector2(-28, 10 + step), acc.darkened(0.1), 5.0)
	face(ci, c, 24, expr, acc, fl)
	if expr == "hug":
		for sx in [-1.0, 1.0]:
			var h: Vector2 = c + Vector2(17.0 * float(sx), 17.0)
			ci.draw_circle(h, 7.5, acc.darkened(0.05))
			ci.draw_arc(h, 7.5, 0, TAU, 14, acc.darkened(0.45), 1.5, true)


static func _bot_dragon(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	_legs(ci, step, body.darkened(0.3), 18.0)
	var tail := PackedVector2Array([Vector2(18, 6), Vector2(34, -4 + sin(t * 4.0) * 3.0), Vector2(46, 4), Vector2(56, -6 + sin(t * 4.0 + 1.0) * 4.0)])
	ci.draw_polyline(tail, body, 7.0, true)
	rrect(ci, Rect2(-24, -14, 48, 32), 12, body, SOFT_INK)
	fill_ellipse(ci, Vector2(-2, 6), 16, 8, acc)
	poly(ci, [Vector2(-46, -30), Vector2(-30, -44), Vector2(-6, -48), Vector2(12, -40), Vector2(12, -20), Vector2(-8, -16), Vector2(-30, -18), Vector2(-46, -22)], body)
	poly(ci, [Vector2(-4, -44), Vector2(4, -62), Vector2(8, -42)], acc)
	poly(ci, [Vector2(4, -42), Vector2(16, -56), Vector2(13, -38)], acc)
	ci.draw_circle(Vector2(-18, -34), 4.5, eye)
	ci.draw_line(Vector2(-18, -38), Vector2(-18, -30), INK, 1.5)
	ci.draw_circle(Vector2(-42, -26), 1.8, INK)
	var wh := sin(t * 3.0) * 3.0
	ci.draw_polyline(PackedVector2Array([Vector2(-42, -22), Vector2(-54, -16 + wh), Vector2(-62, -24 + wh)]), acc, 2.0, true)
	ci.draw_polyline(PackedVector2Array([Vector2(-40, -30), Vector2(-54, -38 - wh), Vector2(-62, -32 - wh)]), acc, 2.0, true)


static func _bot_qilin(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	_legs(ci, step * 1.3, body.darkened(0.35), 20.0)
	rrect(ci, Rect2(-22, -12, 44, 28), 12, body, SOFT_INK)
	for i in 3:
		ci.draw_arc(Vector2(-10 + i * 10, 0), 5, 0, PI, 6, acc, 1.5)
	for i in 3:
		var y := -42.0 + i * 8.0
		poly(ci, [Vector2(-2, y), Vector2(14 + sin(t * 6.0 + i) * 3.0, y - 6), Vector2(4, y + 6)], acc)
	poly(ci, [Vector2(-38, -26), Vector2(-26, -44), Vector2(-6, -46), Vector2(6, -34), Vector2(0, -20), Vector2(-20, -18), Vector2(-38, -20)], body)
	poly(ci, [Vector2(-24, -44), Vector2(-18, -66), Vector2(-13, -44)], Color(1.0, 0.82, 0.3))
	ci.draw_circle(Vector2(-18, -34), 3.5, eye)


static func _bot_orb(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float, thinking: bool) -> void:
	_legs(ci, step, body.lightened(0.15))
	rrect(ci, Rect2(-20, -14, 40, 34), 10, body, SOFT_INK)
	ci.draw_rect(Rect2(-20, 0, 40, 4), acc)
	var c := Vector2(0, -34)
	ci.draw_circle(c, 19, acc)
	ci.draw_circle(c, 12, body)
	var spin := t * (6.0 if thinking else 1.5)
	ci.draw_arc(c, 15.5, spin, spin + 4.2, 20, eye, 3.0, true)
	ci.draw_circle(c + Vector2(-4, 0), 3.5, eye)
	ci.draw_line(Vector2(-18, -4), Vector2(-30, 8 + step), acc, 5.0)


static func _bot_rebel(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	_legs(ci, step * 1.2, body.lightened(0.1))
	rrect(ci, Rect2(-22, -14, 44, 34), 6, body, SOFT_INK)
	rrect(ci, Rect2(-3, -8, 6, 14), 2, acc)
	ci.draw_circle(Vector2(0, 11), 3, acc)
	ci.draw_line(Vector2(-18, -4), Vector2(-34, -2 + step), body.lightened(0.2), 6.0)
	ci.draw_circle(Vector2(-35, -2 + step), 6, body.lightened(0.25))
	var mh := sin(t * 5.0) * 2.0
	poly(ci, [Vector2(-14, -45), Vector2(-10, -60 - mh), Vector2(-6, -46), Vector2(-2, -65 + mh), Vector2(2, -46), Vector2(6, -60 - mh), Vector2(10, -45)], acc)
	rrect(ci, Rect2(-18, -47, 36, 30), 6, body.lightened(0.12), SOFT_INK)
	ci.draw_rect(Rect2(-16, -40, 30, 9), Color(0.05, 0.05, 0.05))
	ci.draw_line(Vector2(-13, -38), Vector2(-5, -35), eye, 3.0)
	ci.draw_line(Vector2(0, -35), Vector2(8, -38), eye, 3.0)
	ci.draw_rect(Rect2(-12, -27, 18, 6), Color.WHITE)
	for i in 3:
		ci.draw_line(Vector2(-7 + i * 5, -27), Vector2(-7 + i * 5, -21), INK, 1.0)


static func _bot_twin(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float) -> void:
	_legs(ci, step, body.darkened(0.3))
	rrect(ci, Rect2(-22, -14, 23, 34), 8, body)
	rrect(ci, Rect2(-1, -14, 23, 34), 8, acc)
	ci.draw_line(Vector2(-18, -4), Vector2(-32, 6 + step), body.lightened(0.1), 5.0)
	var h1 := Vector2(-11, -35)
	var h2 := Vector2(11, -37)
	ci.draw_circle(h2, 12.5, acc.lightened(0.2))
	ci.draw_circle(h1, 12.5, body.lightened(0.2))
	for h in [h1, h2]:
		ci.draw_circle(h + Vector2(-5, -1), 2.8, eye)
		ci.draw_circle(h + Vector2(2, -1), 2.8, eye)
		ci.draw_arc(h + Vector2(-1, 3), 4, PI * 0.15, PI * 0.85, 6, eye, 1.5)


static func _bot_claw(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float, grab: float) -> void:
	_legs(ci, step, body.darkened(0.35))
	rrect(ci, Rect2(-20, -14, 40, 34), 8, body, SOFT_INK)
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		dome.append(Vector2(0, -14) + Vector2(cos(a) * 18.0, sin(a) * 20.0))
	ci.draw_colored_polygon(dome, acc)
	ci.draw_circle(Vector2(-7, -24), 6.5, Color(0.1, 0.1, 0.12))
	ci.draw_circle(Vector2(-8, -24), 3.2, eye)
	var reach := 22.0 + grab * 60.0
	var hand := Vector2(-16 - reach, -18)
	ci.draw_line(Vector2(-16, -4), hand, acc.darkened(0.15), 6.0)
	var open := 0.35 + sin(t * 3.0) * 0.15 + grab * 0.3
	poly(ci, [hand, hand + Vector2(-16, -10).rotated(-open), hand + Vector2(-10, 0)], acc.darkened(0.3))
	poly(ci, [hand, hand + Vector2(-16, 10).rotated(open), hand + Vector2(-10, 0)], acc.darkened(0.3))


static func _bot_book(ci: CanvasItem, body: Color, acc: Color, eye: Color, t: float) -> void:
	var glide := sin(t * 3.0) * 2.0
	poly(ci, [Vector2(-26, 38), Vector2(26, 38), Vector2(14, -14 + glide), Vector2(-14, -14 + glide)], body)
	ci.draw_line(Vector2(-26, 36), Vector2(26, 36), acc, 4.0)
	poly(ci, [Vector2(-18, -22 + glide), Vector2(0, -56 + glide), Vector2(18, -22 + glide)], body.darkened(0.2))
	var c := Vector2(0, -28 + glide)
	ci.draw_circle(c, 13, Color(0.97, 0.88, 0.75))
	ci.draw_circle(c + Vector2(-5, -1), 2.2, INK)
	ci.draw_circle(c + Vector2(3, -1), 2.2, INK)
	ci.draw_arc(c + Vector2(-1, 3), 4, PI * 0.15, PI * 0.85, 6, INK, 1.5)
	var y := -76.0 + sin(t * 2.0) * 3.0
	poly(ci, [Vector2(-20, y), Vector2(0, y + 4), Vector2(0, y + 18), Vector2(-20, y + 14)], Color(0.98, 0.96, 0.9))
	poly(ci, [Vector2(0, y + 4), Vector2(20, y), Vector2(20, y + 14), Vector2(0, y + 18)], Color(0.93, 0.9, 0.82))
	for i in 3:
		ci.draw_line(Vector2(-16, y + 5 + i * 3.5), Vector2(-4, y + 7 + i * 3.5), Color(0.5, 0.45, 0.4), 1.0)
		ci.draw_line(Vector2(4, y + 7 + i * 3.5), Vector2(16, y + 5 + i * 3.5), Color(0.5, 0.45, 0.4), 1.0)
	for i in 3:
		var a := t * 1.5 + TAU * float(i) / 3.0
		ci.draw_colored_polygon(star_points(Vector2(cos(a) * 30.0, -40 + sin(a) * 10.0), 5, 2, 4), eye)


static func _bot_tank(ci: CanvasItem, body: Color, acc: Color, eye: Color, t: float, walking: bool) -> void:
	rrect(ci, Rect2(-38, 18, 76, 22), 10, Color(0.18, 0.19, 0.22))
	var roll := fmod(t * 3.0, 1.0) * 13.0 if walking else 0.0
	for i in 6:
		var x := -32.0 + i * 13.0 + roll * 0.0
		ci.draw_circle(Vector2(x, 29), 6, Color(0.42, 0.44, 0.48))
		ci.draw_line(Vector2(x, 29), Vector2(x, 29) + Vector2(5, 0).rotated(t * 4.0 + i), Color(0.2, 0.2, 0.22), 1.5)
	rrect(ci, Rect2(-34, -28, 68, 50), 8, body, SOFT_INK)
	ci.draw_line(Vector2(-30, -12), Vector2(30, -12), acc, 2.0)
	ci.draw_line(Vector2(-30, 12), Vector2(30, 12), acc, 2.0)
	for x in [-26.0, 26.0]:
		ci.draw_circle(Vector2(x, -20), 2.2, acc.lightened(0.3))
		ci.draw_circle(Vector2(x, 18), 2.2, acc.lightened(0.3))
	lock_icon(ci, Vector2(0, 2), 1.2, Color(0.95, 0.75, 0.2))
	rrect(ci, Rect2(-20, -52, 40, 26), 6, acc, SOFT_INK)
	ci.draw_rect(Rect2(-16, -43, 24, 6), eye.lerp(Color.WHITE, 0.2 + sin(t * 5.0) * 0.2))
	ci.draw_line(Vector2(-20, -44), Vector2(-40, -44), acc.darkened(0.2), 5.0)


static func _bot_star(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float, walking: bool) -> void:
	if walking:
		for i in 3:
			var a := 0.5 - i * 0.15
			ci.draw_line(Vector2(18 + i * 10, -30 + i * 10), Vector2(44 + i * 14, -34 + i * 10), Color(acc.r, acc.g, acc.b, a), 3.0)
	_legs(ci, step * 1.5, body.darkened(0.2), 24.0)
	rrect(ci, Rect2(-14, -12, 28, 32), 10, body, SOFT_INK)
	ci.draw_line(Vector2(-12, -4), Vector2(-26, -12 + step), body, 4.0)
	var c := Vector2(0, -36)
	ci.draw_colored_polygon(star_points(c, 22, 10, 5, -PI / 2.0 + sin(t * 2.0) * 0.1), acc)
	ci.draw_colored_polygon(star_points(c, 14, 6.5, 5, -PI / 2.0 + sin(t * 2.0) * 0.1), acc.lightened(0.4))
	ci.draw_circle(c + Vector2(-5, 0), 2.6, INK)
	ci.draw_circle(c + Vector2(3, 0), 2.6, INK)


# --- Cartas de IA, aliado y podadora ------------------------------------------

static func card_icon(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	match id:
		"autodestruccion":
			ci.draw_circle(c + Vector2(0, 4) * s, 15.0 * s, Color(0.15, 0.15, 0.18))
			ci.draw_circle(c + Vector2(-5, -1) * s, 4.0 * s, Color(1, 1, 1, 0.35))
			ci.draw_line(c + Vector2(8, -8) * s, c + Vector2(14, -18) * s, Color(0.6, 0.45, 0.3), 3.0 * s)
			ci.draw_colored_polygon(star_points(c + Vector2(15, -20) * s, 7.0 * s, 3.0 * s, 6), Color(1.0, 0.6, 0.1))
		"boton_apagado":
			ci.draw_circle(c, 18.0 * s, Color(0.95, 0.95, 0.97))
			power_icon(ci, c + Vector2(0, 2) * s, 10.0 * s, Color(0.85, 0.15, 0.15), 3.5 * s)
		"apagado_cadena":
			for k in 3:
				var p := c + Vector2(-14 + k * 14, (k % 2) * 6 - 3) * s
				var e := ellipse(p, 9.0 * s, 5.5 * s, 0.0, 16)
				e.append(e[0])
				ci.draw_polyline(e, Color(0.75, 0.78, 0.85), 3.0 * s, true)
			power_icon(ci, c + Vector2(0, 14) * s, 6.0 * s, Color(0.95, 0.3, 0.3), 2.5 * s)
		"alineamiento":
			heart(ci, c + Vector2(0, -2) * s, 1.4 * s, Color(0.3, 0.85, 0.45))
			ci.draw_circle(c + Vector2(-5, -5) * s, 2.5 * s, INK)
			ci.draw_circle(c + Vector2(5, -5) * s, 2.5 * s, INK)
			ci.draw_arc(c + Vector2(0, 0) * s, 5.0 * s, PI * 0.15, PI * 0.85, 8, INK, 2.0 * s)
		"red_team":
			ci.draw_arc(c + Vector2(-3, -3) * s, 12.0 * s, 0, TAU, 20, Color(0.95, 0.25, 0.2), 4.0 * s, true)
			ci.draw_line(c + Vector2(6, 6) * s, c + Vector2(16, 16) * s, Color(0.95, 0.25, 0.2), 5.0 * s)
			fill_ellipse(ci, c + Vector2(-3, -3) * s, 7.0 * s, 4.0 * s, Color.WHITE)
			ci.draw_circle(c + Vector2(-3, -3) * s, 2.5 * s, INK)
		_:
			ci.draw_circle(c, 14.0 * s, Color.MAGENTA)


static func buddy(ci: CanvasItem, c: Vector2, s: float, t: float, excited: float) -> void:
	var bob := sin(t * 3.0) * 3.0 * s
	var p := c + Vector2(0, bob)
	var arm := excited * 18.0 * s
	ci.draw_line(p + Vector2(-20, 4) * s, p + Vector2(-32, 10 - arm), Color(0.7, 0.9, 0.85), 5.0 * s)
	ci.draw_line(p + Vector2(20, 4) * s, p + Vector2(32, 10 - arm), Color(0.7, 0.9, 0.85), 5.0 * s)
	ci.draw_circle(p, 26.0 * s, Color(0.92, 0.98, 0.96))
	ci.draw_arc(p, 26.0 * s, 0, TAU, 28, Color(0.35, 0.6, 0.55), 2.5 * s, true)
	rrect(ci, Rect2(p + Vector2(-17, -12) * s, Vector2(34, 22) * s), 7.0 * s, Color(0.1, 0.2, 0.22))
	var eye := Color(0.4, 1.0, 0.7)
	ci.draw_arc(p + Vector2(-7, -1) * s, 4.0 * s, PI * 1.1, PI * 1.9, 8, eye, 2.5 * s)
	ci.draw_arc(p + Vector2(7, -1) * s, 4.0 * s, PI * 1.1, PI * 1.9, 8, eye, 2.5 * s)
	ci.draw_arc(p + Vector2(0, 2) * s, 5.0 * s, PI * 0.2, PI * 0.8, 8, eye, 2.0 * s)
	ci.draw_line(p + Vector2(0, -26) * s, p + Vector2(0, -36) * s, Color(0.35, 0.6, 0.55), 2.5 * s)
	heart(ci, p + Vector2(0, -40) * s, 0.55 * s * (1.0 + excited * 0.5), Color(1.0, 0.4, 0.5))


static func mower(ci: CanvasItem, t: float, moving: bool) -> void:
	shadow(ci, Vector2(0, 16), 26)
	ci.draw_line(Vector2(10, -10), Vector2(26, -34), Color(0.3, 0.3, 0.32), 4.0)
	ci.draw_line(Vector2(20, -34), Vector2(32, -34), Color(0.3, 0.3, 0.32), 4.0)
	rrect(ci, Rect2(-26, -14, 44, 24), 6, Color(0.85, 0.2, 0.18), SOFT_INK)
	ci.draw_rect(Rect2(-22, -10, 14, 8), Color(0.2, 0.25, 0.3))
	ci.draw_circle(Vector2(-18, -6), 2, Color(0.4, 1.0, 0.9))
	ci.draw_circle(Vector2(-12, -6), 2, Color(0.4, 1.0, 0.9))
	var spin := t * 30.0 if moving else 0.0
	for x in [-16.0, 10.0]:
		ci.draw_circle(Vector2(x, 12), 7, Color(0.15, 0.15, 0.16))
		ci.draw_line(Vector2(x, 12), Vector2(x, 12) + Vector2(5, 0).rotated(spin), Color(0.6, 0.6, 0.6), 2.0)
	ci.draw_line(Vector2(-30, -8), Vector2(-30, 10), Color(0.75, 0.78, 0.8), 4.0)
