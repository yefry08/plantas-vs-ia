class_name ArtParody
extends RefCounted
## Robots parodia de las grandes IA (evocan colores y temas, sin copiar logos)
## y las bioarmas IA. Usa las primitivas de Art.

const INK := Color(0.1, 0.09, 0.08, 1.0)
const SOFT_INK := Color(0.1, 0.09, 0.08, 0.55)


static func fish(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	Art._legs(ci, step, acc.darkened(0.3), 18.0)
	var c := Vector2(0, -12)
	var wag := sin(t * 6.0) * 5.0
	Art.poly(ci, [c + Vector2(24, 0), c + Vector2(46, -16 + wag), c + Vector2(40, 0), c + Vector2(46, 16 + wag)], acc)
	Art.fill_ellipse(ci, c, 32, 22, body)
	var belly := PackedVector2Array()
	for i in 13:
		var a := PI * float(i) / 12.0
		belly.append(c + Vector2(-cos(a) * 30.0, sin(a) * 20.0))
	ci.draw_colored_polygon(belly, body.lightened(0.35))
	Art.poly(ci, [c + Vector2(-6, -20), c + Vector2(10, -34), c + Vector2(14, -18)], acc)
	for i in 3:
		ci.draw_arc(c + Vector2(4 + i * 7, -2), 8, -0.8, 0.8, 6, body.darkened(0.25), 1.5)
	ci.draw_circle(c + Vector2(-16, -6), 7, Color.WHITE)
	ci.draw_circle(c + Vector2(-18, -6), 3.5, INK)
	ci.draw_circle(c + Vector2(-19, -8), 1.2, Color.WHITE)
	ci.draw_arc(c + Vector2(-26, 6), 5, PI * 0.1, PI * 0.8, 6, INK, 2.0)
	ci.draw_line(c + Vector2(0, -22), c + Vector2(0, -32), acc.darkened(0.2), 2.0)
	ci.draw_circle(c + Vector2(0, -34), 3, eye)


static func stripes(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float, thinking: bool) -> void:
	Art._legs(ci, step, acc)
	Art.rrect(ci, Rect2(-20, -14, 40, 34), 12, body, SOFT_INK)
	for i in 3:
		ci.draw_rect(Rect2(-19, -8 + i * 10, 38, 4), acc)
	ci.draw_line(Vector2(-18, -4), Vector2(-32, 6 + step), acc, 5.0)
	var c := Vector2(0, -34)
	ci.draw_circle(c, 19, body)
	ci.draw_arc(c, 19, 0, TAU, 28, acc, 3.0, true)
	ci.draw_arc(c, 13, 0, TAU, 24, acc, 2.0, true)
	Art.rrect(ci, Rect2(c + Vector2(-15, -5), Vector2(30, 10)), 5, acc)
	if fmod(t, 3.0) < 2.85:
		ci.draw_circle(c + Vector2(-6, 0), 3, eye)
		ci.draw_circle(c + Vector2(4, 0), 3, eye)
	if thinking:
		for i in 3:
			var big := 1.5 if int(t * 4.0) % 3 == i else 0.0
			ci.draw_circle(c + Vector2(-10 + i * 10, -28), 3.0 + big, acc)


static func rocket(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float, walking: bool) -> void:
	if walking:
		var fl := 10.0 + sin(t * 30.0) * 4.0
		Art.poly(ci, [Vector2(16, 8), Vector2(16 + fl, 12), Vector2(16, 16)], Color(1.0, 0.6, 0.15, 0.9))
	Art._legs(ci, step * 1.2, body.lightened(0.15))
	Art.poly(ci, [Vector2(-16, 18), Vector2(-26, 30), Vector2(-12, 20)], acc)
	Art.poly(ci, [Vector2(16, 18), Vector2(26, 30), Vector2(12, 20)], acc)
	var hull := PackedVector2Array([Vector2(-16, 20), Vector2(-16, -30), Vector2(0, -60), Vector2(16, -30), Vector2(16, 20)])
	ci.draw_colored_polygon(hull, body)
	hull.append(hull[0])
	ci.draw_polyline(hull, acc, 2.0, true)
	ci.draw_circle(Vector2(0, -28), 9, Color(0.8, 0.85, 0.95))
	ci.draw_circle(Vector2(0, -28), 9, Color(0.1, 0.1, 0.12, 0.35))
	ci.draw_line(Vector2(-6, -29), Vector2(6, -27), eye, 3.0)
	ci.draw_line(Vector2(-16, 0), Vector2(16, 0), acc, 2.0)
	ci.draw_line(Vector2(-14, -2), Vector2(-30, 6 + step), body.lightened(0.25), 5.0)


static func lobster(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float, grab: float) -> void:
	for k in 3:
		ci.draw_line(Vector2(-14 + k * 10, 14 + k * 6), Vector2(-20 + k * 10 + step * 0.5, 38), body.darkened(0.3), 3.0)
	for k in 4:
		Art.fill_ellipse(ci, Vector2(18 + k * 9, 6 - k * 2), 9 - k, 8 - k, body.darkened(0.08 * k))
	Art.poly(ci, [Vector2(50, -2), Vector2(62, -10), Vector2(62, 6)], acc)
	Art.fill_ellipse(ci, Vector2(-2, 0), 24, 18, body)
	ci.draw_line(Vector2(-12, -14), Vector2(-40, -58 + sin(t * 3.0) * 4.0), body.darkened(0.2), 1.5)
	ci.draw_line(Vector2(-6, -14), Vector2(-26, -64 + sin(t * 3.0 + 1.0) * 4.0), body.darkened(0.2), 1.5)
	ci.draw_line(Vector2(-14, -12), Vector2(-16, -24), body.darkened(0.2), 2.0)
	ci.draw_line(Vector2(-6, -12), Vector2(-4, -24), body.darkened(0.2), 2.0)
	ci.draw_circle(Vector2(-16, -26), 3.5, INK)
	ci.draw_circle(Vector2(-4, -26), 3.5, INK)
	var reach := 26.0 + grab * 50.0
	for k in 2:
		var base := Vector2(-18, -2 + k * 10)
		var hand := base + Vector2(-reach + k * 6.0, -10 + k * 8)
		ci.draw_line(base, hand, body.darkened(0.1), 5.0)
		var open := 0.3 + sin(t * 4.0 + k) * 0.15 + grab * 0.3
		Art.poly(ci, [hand, hand + Vector2(-14, -8).rotated(-open), hand + Vector2(-8, 0)], acc)
		Art.poly(ci, [hand, hand + Vector2(-14, 8).rotated(open), hand + Vector2(-8, 0)], acc)
	ci.draw_circle(Vector2(-8, 2), 3, eye)


static func crab(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	for k in 3:
		var x := -16.0 + k * 16.0
		ci.draw_line(Vector2(x - 4, 14), Vector2(x - 12 + step, 34), body.darkened(0.3), 3.0)
		ci.draw_line(Vector2(x + 4, 14), Vector2(x + 12 - step, 34), body.darkened(0.3), 3.0)
	Art.fill_ellipse(ci, Vector2(0, 8), 28, 16, body)
	Art.fill_ellipse(ci, Vector2(0, 4), 20, 8, body.lightened(0.2))
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		var cl := Vector2(30.0 * s, -14.0 + sin(t * 5.0 + s) * 4.0)
		ci.draw_line(Vector2(18.0 * s, 4), cl, body.darkened(0.1), 4.0)
		Art.fill_ellipse(ci, cl, 9, 7, acc)
		Art.poly(ci, [cl, cl + Vector2(6.0 * s, -12), cl + Vector2(10.0 * s, -2)], body.lightened(0.25))
	ci.draw_line(Vector2(-6, -4), Vector2(-8, -16), body.darkened(0.2), 2.0)
	ci.draw_line(Vector2(6, -4), Vector2(8, -16), body.darkened(0.2), 2.0)
	ci.draw_circle(Vector2(-8, -18), 4, Color.WHITE)
	ci.draw_circle(Vector2(8, -18), 4, Color.WHITE)
	ci.draw_circle(Vector2(-9, -18), 2, INK)
	ci.draw_circle(Vector2(7, -18), 2, INK)
	ci.draw_arc(Vector2(0, 8), 5, PI * 0.15, PI * 0.85, 6, eye, 1.5)


static func claudio(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	Art._legs(ci, step, acc, 20.0)
	Art.rrect(ci, Rect2(-22, -12, 44, 32), 14, body, acc.darkened(0.2), 2.0)
	ci.draw_circle(Vector2(0, 4), 6, acc)
	ci.draw_circle(Vector2(0, 4), 3, body.lightened(0.2))
	ci.draw_line(Vector2(-20, -2), Vector2(-34, 4 + step), body.darkened(0.08), 7.0)
	ci.draw_circle(Vector2(-35, 5 + step), 5, acc)
	var c := Vector2(0, -34)
	Art.rrect(ci, Rect2(c + Vector2(-22, -18), Vector2(44, 34)), 15, body, acc.darkened(0.2), 2.0)
	Art.rrect(ci, Rect2(c + Vector2(-17, -9), Vector2(34, 16)), 8, acc.darkened(0.35))
	var look := sin(t * 1.5) * 2.0
	ci.draw_circle(c + Vector2(-7 + look, -1), 3.5, eye)
	ci.draw_circle(c + Vector2(6 + look, -1), 3.5, eye)
	ci.draw_arc(c + Vector2(0, 8), 5, PI * 0.15, PI * 0.85, 6, acc.darkened(0.4), 2.0)
	ci.draw_circle(c + Vector2(-17, 7), 3.5, Color(1.0, 0.55, 0.45, 0.6))
	ci.draw_circle(c + Vector2(17, 7), 3.5, Color(1.0, 0.55, 0.45, 0.6))
	ci.draw_circle(c + Vector2(0, -20), 4, acc)


static func spore(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	Art._legs(ci, step, body.darkened(0.3), 20.0)
	Art.rrect(ci, Rect2(-18, -10, 36, 30), 10, body, SOFT_INK)
	ci.draw_circle(Vector2(0, 4), 6, eye.lerp(Color.WHITE, 0.2 + 0.2 * sin(t * 5.0)))
	var cap := PackedVector2Array()
	for i in 15:
		var a := PI + PI * float(i) / 14.0
		cap.append(Vector2(cos(a) * 30.0, -22.0 + sin(a) * 26.0))
	ci.draw_colored_polygon(cap, acc)
	for p in [Vector2(-14, -34), Vector2(6, -40), Vector2(16, -28), Vector2(-4, -28)]:
		ci.draw_circle(p, 4, Color(0.8, 1.0, 0.5, 0.85))
	Art.rrect(ci, Rect2(-12, -22, 24, 12), 5, body.darkened(0.3))
	ci.draw_circle(Vector2(-5, -16), 2.5, eye)
	ci.draw_circle(Vector2(5, -16), 2.5, eye)
	for i in 3:
		var k := fmod(t * 0.8 + i * 0.33, 1.0)
		ci.draw_circle(Vector2(-10 + i * 10, -48 - k * 24), 3.0 * (1.0 - k), Color(0.7, 1.0, 0.4, 0.7 * (1.0 - k)))


static func cordy(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	Art._legs(ci, step * 0.8, body.darkened(0.3))
	Art.rrect(ci, Rect2(-20, -14, 40, 34), 8, body, SOFT_INK)
	ci.draw_line(Vector2(-18, -4), Vector2(-34, 4 + step), body.lightened(0.1), 5.0)
	Art.rrect(ci, Rect2(-17, -44, 34, 30), 8, body.lightened(0.1), SOFT_INK)
	for k in 3:
		var bx := -10.0 + k * 10.0
		var sway := sin(t * 2.0 + k) * 4.0
		ci.draw_line(Vector2(bx, -44), Vector2(bx + sway, -64 - k * 4), acc, 3.0)
		ci.draw_circle(Vector2(bx + sway, -66 - k * 4), 4.5, acc.lightened(0.25))
	ci.draw_circle(Vector2(-7, -31), 4, eye)
	ci.draw_circle(Vector2(6, -31), 4, eye)
	ci.draw_line(Vector2(-8, -22), Vector2(8, -22), INK, 2.0)


static func chimera(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	Art._legs(ci, step * 0.6, body.darkened(0.35), 20.0)
	for k in 3:
		var x := 8.0 + k * 10.0
		Art.rrect(ci, Rect2(x, -44, 8, 26), 3, Color(0.85, 0.95, 0.9, 0.8))
		var lvl := 0.5 + 0.3 * sin(t * 3.0 + k)
		ci.draw_rect(Rect2(x + 1, -44 + 26 * (1.0 - lvl), 6, 26 * lvl - 1), acc)
	Art.rrect(ci, Rect2(-30, -24, 58, 46), 14, body, SOFT_INK)
	for k in 2:
		var pts := PackedVector2Array()
		for i in 7:
			pts.append(Vector2(-26 - i * 5.0, -2 + k * 14 + sin(t * 4.0 + i * 0.8 + k) * 5.0))
		ci.draw_polyline(pts, acc.darkened(0.2), 5.0, true)
	for i in 3:
		var p := Vector2(-16 + i * 12, -8)
		ci.draw_circle(p, 5, Color.WHITE)
		ci.draw_circle(p + Vector2(-1.5, 0), 2.5, eye)
	ci.draw_arc(Vector2(-4, 8), 10, PI * 0.1, PI * 0.9, 10, INK, 2.5)


## Compañeros de IA aliada que el jugador puede elegir.
static func ally(ci: CanvasItem, id: String, c: Vector2, s: float, t: float, excited: float) -> void:
	var bob := sin(t * 3.0) * 3.0 * s
	var p := c + Vector2(0, bob)
	var arm := excited * 18.0 * s
	match id:
		"llamita":
			Art.fill_ellipse(ci, p + Vector2(0, 8) * s, 24.0 * s, 18.0 * s, Color(0.97, 0.95, 0.9))
			for i in 6:
				ci.draw_circle(p + Vector2(-20 + i * 8, 20) * s, 5.0 * s, Color(0.95, 0.92, 0.86))
			Art.rrect(ci, Rect2(p + Vector2(-9, -34) * s, Vector2(18, 34) * s), 8.0 * s, Color(0.97, 0.95, 0.9))
			Art.poly(ci, [p + Vector2(-9, -30) * s, p + Vector2(-14, -44) * s, p + Vector2(-4, -34) * s], Color(0.9, 0.85, 0.78))
			Art.poly(ci, [p + Vector2(9, -30) * s, p + Vector2(14, -44) * s, p + Vector2(4, -34) * s], Color(0.9, 0.85, 0.78))
			Art.rrect(ci, Rect2(p + Vector2(-8, -26) * s, Vector2(16, 9) * s), 4.0 * s, Color(0.12, 0.2, 0.3))
			ci.draw_circle(p + Vector2(-4, -22) * s, 2.0 * s, Color(0.4, 0.9, 1.0))
			ci.draw_circle(p + Vector2(4, -22) * s, 2.0 * s, Color(0.4, 0.9, 1.0))
			Art.fill_ellipse(ci, p + Vector2(0, -12) * s, 5.0 * s, 3.5 * s, Color(0.85, 0.7, 0.6))
		"mistralito":
			for i in 3:
				var a := t * 2.0 + TAU * float(i) / 3.0
				ci.draw_arc(p + Vector2(cos(a), sin(a)) * 30.0 * s, 8.0 * s, a, a + 3.0, 8, Color(1.0, 0.7, 0.3, 0.6), 2.0 * s)
			ci.draw_circle(p, 24.0 * s, Color(1.0, 0.62, 0.2))
			ci.draw_circle(p + Vector2(-8, -8) * s, 10.0 * s, Color(1.0, 0.78, 0.35))
			ci.draw_circle(p + Vector2(10, -4) * s, 12.0 * s, Color(1.0, 0.72, 0.3))
			Art.rrect(ci, Rect2(p + Vector2(-15, -6) * s, Vector2(30, 14) * s), 6.0 * s, Color(0.3, 0.15, 0.05))
			ci.draw_arc(p + Vector2(-6, 1) * s, 3.5 * s, PI * 1.1, PI * 1.9, 8, Color(1, 0.95, 0.7), 2.0 * s)
			ci.draw_arc(p + Vector2(6, 1) * s, 3.5 * s, PI * 1.1, PI * 1.9, 8, Color(1, 0.95, 0.7), 2.0 * s)
		"perplejo":
			Art.fill_ellipse(ci, p + Vector2(-20, 0) * s, 16.0 * s, 6.0 * s, Color(0.3, 0.75, 0.75, 0.8), -0.4 + sin(t * 20.0) * 0.3)
			Art.fill_ellipse(ci, p + Vector2(20, 0) * s, 16.0 * s, 6.0 * s, Color(0.3, 0.75, 0.75, 0.8), 0.4 - sin(t * 20.0) * 0.3)
			Art.fill_ellipse(ci, p, 16.0 * s, 20.0 * s, Color(0.15, 0.5, 0.55))
			ci.draw_circle(p + Vector2(0, -12) * s, 12.0 * s, Color(0.2, 0.62, 0.66))
			ci.draw_line(p + Vector2(-12, -12) * s, p + Vector2(-26, -10) * s, Color(0.9, 0.9, 0.9), 2.0 * s)
			ci.draw_arc(p + Vector2(4, -13) * s, 6.0 * s, 0, TAU, 14, Color(0.95, 0.95, 1.0), 2.0 * s)
			ci.draw_circle(p + Vector2(4, -13) * s, 2.5 * s, INK)
			ci.draw_line(p + Vector2(8, -9) * s, p + Vector2(12, -4) * s, Color(0.95, 0.95, 1.0), 2.0 * s)
		_:
			# Transformer: el robot de la arquitectura de "atención".
			ci.draw_line(p + Vector2(-22, 2) * s, p + Vector2(-34, 8 - arm / s) * s, Color(0.45, 0.55, 0.85), 5.0 * s)
			ci.draw_line(p + Vector2(22, 2) * s, p + Vector2(34, 8 - arm / s) * s, Color(0.45, 0.55, 0.85), 5.0 * s)
			Art.rrect(ci, Rect2(p + Vector2(-24, -20) * s, Vector2(48, 44) * s), 8.0 * s, Color(0.3, 0.42, 0.78), Color(0.15, 0.2, 0.4), 2.0 * s)
			Art.rrect(ci, Rect2(p + Vector2(-18, -14) * s, Vector2(36, 18) * s), 5.0 * s, Color(0.08, 0.12, 0.2))
			for i in 4:
				for j in 2:
					var on := int(t * 5.0 + i + j * 2) % 4 == 0
					ci.draw_rect(Rect2(p + Vector2(-15 + i * 8, -11 + j * 7) * s, Vector2(6, 5) * s), Color(0.4, 0.9, 1.0) if on else Color(0.2, 0.4, 0.6))
			ci.draw_arc(p + Vector2(0, 12) * s, 6.0 * s, PI * 0.15, PI * 0.85, 8, Color(0.85, 0.95, 1.0), 2.0 * s)
			for i in 3:
				ci.draw_rect(Rect2(p + Vector2(-14 + i * 11, 18) * s, Vector2(6, 4) * s), Color(0.9, 0.3, 0.3))
	if excited > 0.0:
		Art.heart(ci, p + Vector2(0, -52) * s, 0.55 * s * (1.0 + excited * 0.5), Color(1.0, 0.4, 0.5))


## Musa: agente personal que compra cosas por ti (parodia, sin logo).
static func musa(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	Art._legs(ci, step, acc.darkened(0.2), 20.0)
	Art.rrect(ci, Rect2(-20, -12, 40, 32), 14, body, SOFT_INK)
	Art.rrect(ci, Rect2(-20, 4, 40, 16), 8, acc)
	# Bolsa de compras
	var sw := sin(t * 4.0) * 3.0
	ci.draw_line(Vector2(16, -4), Vector2(28, 6 + sw), body.darkened(0.2), 4.0)
	Art.rrect(ci, Rect2(20, 6 + sw, 18, 18), 3, Color(1.0, 0.6, 0.2))
	ci.draw_arc(Vector2(29, 7 + sw), 5, PI, TAU, 8, Color(0.6, 0.35, 0.1), 2.0)
	# Móvil en la otra mano
	ci.draw_line(Vector2(-18, -4), Vector2(-32, -10 + step), body.darkened(0.2), 4.0)
	Art.rrect(ci, Rect2(-40, -24 + step, 10, 16), 2, Color(0.12, 0.12, 0.16))
	ci.draw_rect(Rect2(-38, -22 + step, 6, 11), Color(0.5, 0.8, 1.0))
	var c := Vector2(0, -34)
	ci.draw_circle(c, 20, body.lightened(0.15))
	Art.rrect(ci, Rect2(c + Vector2(-15, -9), Vector2(30, 18)), 9, Color(0.08, 0.1, 0.2))
	ci.draw_arc(c + Vector2(-6, 0), 4, PI * 1.1, PI * 1.9, 8, eye, 2.5)
	ci.draw_arc(c + Vector2(6, 0), 4, PI * 1.1, PI * 1.9, 8, eye, 2.5)
	ci.draw_arc(c + Vector2(0, 3), 4, PI * 0.15, PI * 0.85, 6, eye, 2.0)


## Dotz: agente "siempre encendido" con su propio mini-ordenador.
static func dot(ci: CanvasItem, body: Color, acc: Color, eye: Color, step: float, t: float) -> void:
	for k in 2:
		ci.draw_line(Vector2(-8 + k * 16, 12), Vector2(-10 + k * 16 + (step if k == 0 else -step), 34), body.lightened(0.3), 3.0)
	var bob := sin(t * 8.0) * 2.0
	var c := Vector2(0, -4 + bob)
	ci.draw_circle(c, 22, body)
	ci.draw_arc(c, 22, 0, TAU, 28, acc, 2.0, true)
	for i in 3:
		var on := int(t * 3.0) % 3 == i
		ci.draw_circle(c + Vector2(-9 + i * 9, 0), 3.5, eye if on else acc)
	# Mini portátil
	var lp := c + Vector2(-34, 6)
	Art.poly(ci, [lp + Vector2(-10, 0), lp + Vector2(10, 0), lp + Vector2(12, 4), lp + Vector2(-12, 4)], Color(0.7, 0.72, 0.78))
	Art.poly(ci, [lp + Vector2(-9, 0), lp + Vector2(-7, -13), lp + Vector2(9, -13), lp + Vector2(9, 0)], Color(0.2, 0.22, 0.28))
	ci.draw_rect(Rect2(lp + Vector2(-6, -11), Vector2(13, 9)), Color(0.4, 0.9, 1.0, 0.8))
	ci.draw_line(c + Vector2(0, -22), c + Vector2(0, -30), acc, 2.0)
	ci.draw_circle(c + Vector2(0, -32), 3.5, eye if fmod(t, 1.0) < 0.6 else acc)
