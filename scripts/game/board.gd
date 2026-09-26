class_name Board
extends Node2D
## Fondo del nivel: casa, tablero de 5x9 y calle, con paleta por zona.

const PALETTES := {
	1: {"bg": Color(0.55, 0.78, 0.95), "house": Color(0.93, 0.87, 0.72), "a": Color(0.45, 0.72, 0.3), "b": Color(0.4, 0.66, 0.26), "street": Color(0.42, 0.42, 0.45), "dead": Color(0.55, 0.42, 0.28), "line": Color(0, 0, 0, 0)},
	2: {"bg": Color(0.14, 0.17, 0.2), "house": Color(0.2, 0.24, 0.28), "a": Color(0.3, 0.55, 0.34), "b": Color(0.27, 0.5, 0.31), "street": Color(0.07, 0.09, 0.09), "dead": Color(0.2, 0.2, 0.22), "line": Color(0.5, 1.0, 0.6, 0.08)},
	3: {"bg": Color(0.12, 0.14, 0.2), "house": Color(0.25, 0.28, 0.35), "a": Color(0.56, 0.61, 0.69), "b": Color(0.5, 0.55, 0.63), "street": Color(0.14, 0.15, 0.19), "dead": Color(0.28, 0.3, 0.35), "line": Color(0.3, 0.4, 0.6, 0.35)},
	4: {"bg": Color(0.86, 0.88, 0.94), "house": Color(0.78, 0.8, 0.9), "a": Color(0.83, 0.85, 0.93), "b": Color(0.77, 0.79, 0.89), "street": Color(0.55, 0.5, 0.75), "dead": Color(0.6, 0.6, 0.68), "line": Color(0.55, 0.45, 0.85, 0.35)},
	5: {"bg": Color(0.05, 0.09, 0.07), "house": Color(0.12, 0.2, 0.16), "a": Color(0.2, 0.32, 0.26), "b": Color(0.17, 0.28, 0.23), "street": Color(0.06, 0.1, 0.07), "dead": Color(0.1, 0.12, 0.1), "line": Color(0.5, 1.0, 0.3, 0.2)},
	6: {"bg": Color(0.07, 0.03, 0.07), "house": Color(0.16, 0.08, 0.12), "a": Color(0.26, 0.12, 0.18), "b": Color(0.22, 0.1, 0.15), "street": Color(0.1, 0.02, 0.04), "dead": Color(0.12, 0.08, 0.1), "line": Color(1.0, 0.3, 0.4, 0.25)},
}

var zone := 1
var active: PackedInt32Array = PackedInt32Array([0, 1, 2, 3, 4])


func _draw() -> void:
	var p: Dictionary = PALETTES.get(zone, PALETTES[1])
	draw_rect(Rect2(0, 0, 1280, 720), p["bg"])
	draw_rect(Rect2(0, 120, Grid.ORIGIN.x, 600), p["house"])
	_draw_house(p)
	var street := Rect2(Grid.RIGHT_EDGE, 120, 1280 - Grid.RIGHT_EDGE, 600)
	draw_rect(street, p["street"])
	_draw_street(p, street)
	for r in Grid.ROWS:
		for c in Grid.COLS:
			var rect := Rect2(Grid.ORIGIN + Vector2(c * Grid.CELL.x, r * Grid.CELL.y), Grid.CELL)
			var col: Color = p["a"] if (r + c) % 2 == 0 else p["b"]
			if not active.has(r):
				col = p["dead"].lerp(col, 0.15 if (r + c) % 2 == 0 else 0.05)
			draw_rect(rect, col)
			var line: Color = p["line"]
			if line.a > 0.0:
				draw_rect(rect, line, false, 1.0)
	for r in Grid.ROWS:
		if not active.has(r):
			var y := Grid.ORIGIN.y + r * Grid.CELL.y
			for i in 6:
				var x := Grid.ORIGIN.x + 40.0 + i * 150.0
				draw_line(Vector2(x, y + 30), Vector2(x + 40, y + 34), Color(0, 0, 0, 0.15), 3.0)
				draw_line(Vector2(x + 60, y + 80), Vector2(x + 110, y + 76), Color(0, 0, 0, 0.12), 3.0)
	draw_rect(Grid.board_rect(), Color(0, 0, 0, 0.3), false, 3.0)


func _draw_house(p: Dictionary) -> void:
	var w := Grid.ORIGIN.x
	match zone:
		1:
			for i in 5:
				var y := 150.0 + i * 112.0
				draw_rect(Rect2(20, y, 60, 50), Color(0.55, 0.75, 0.9))
				draw_rect(Rect2(20, y, 60, 50), Color(0.45, 0.32, 0.2), false, 4.0)
				draw_line(Vector2(50, y), Vector2(50, y + 50), Color(0.45, 0.32, 0.2), 3.0)
			draw_rect(Rect2(w - 22, 120, 22, 600), Color(0.55, 0.4, 0.25))
		2:
			var pts := PackedVector2Array()
			for i in 12:
				pts.append(Vector2(40 + sin(i * 0.9) * 18.0, 150 + i * 48.0))
			draw_polyline(pts, Color(0.4, 0.9, 0.5, 0.6), 4.0)
			for i in 12:
				draw_circle(pts[i], 8, Color(0.4, 0.9, 0.5))
				if i % 3 == 1:
					draw_line(pts[i], pts[i] + Vector2(60, 20), Color(0.95, 0.6, 0.3, 0.6), 4.0)
					draw_circle(pts[i] + Vector2(60, 20), 7, Color(0.95, 0.6, 0.3))
		3:
			for i in 5:
				var y := 145.0 + i * 112.0
				Art.rrect(self, Rect2(16, y, 110, 96), 6, Color(0.12, 0.13, 0.17), Color(0.35, 0.4, 0.5), 2)
				for k in 6:
					draw_rect(Rect2(24, y + 8 + k * 14, 94, 9), Color(0.2, 0.22, 0.28))
					draw_circle(Vector2(110, y + 12 + k * 14), 2.5, Color(0.3, 1.0, 0.5) if (i + k) % 3 else Color(1.0, 0.7, 0.2))
		4:
			for i in 5:
				var y := 145.0 + i * 112.0
				Art.rrect(self, Rect2(16, y, 120, 96), 10, Color(0.95, 0.97, 1.0, 0.8), Color(0.6, 0.55, 0.85), 2)
				draw_circle(Vector2(76, y + 48), 26, Color(0.7, 0.62, 0.95, 0.5))
				draw_arc(Vector2(76, y + 48), 34, 0, TAU, 32, Color(0.55, 0.45, 0.85, 0.6), 2.0)
		5:
			for i in 5:
				var y := 150.0 + i * 112.0
				Art.rrect(self, Rect2(22, y, 28, 80), 10, Color(0.8, 0.95, 0.85, 0.5), Color(0.5, 0.8, 0.6), 2)
				draw_rect(Rect2(26, y + 30, 20, 46), Color(0.5, 1.0, 0.3, 0.7))
				Art.rrect(self, Rect2(70, y + 10, 28, 70), 10, Color(0.8, 0.95, 0.85, 0.5), Color(0.5, 0.8, 0.6), 2)
				draw_rect(Rect2(74, y + 40, 20, 36), Color(0.7, 0.4, 1.0, 0.7))
		6:
			for i in 8:
				var y := 130.0 + i * 76.0
				draw_line(Vector2(0, y), Vector2(w, y + 30), Color(1.0, 0.25, 0.35, 0.25), 2.0)


func _draw_street(p: Dictionary, street: Rect2) -> void:
	match zone:
		1:
			for i in 8:
				draw_rect(Rect2(street.position.x + 70, 140 + i * 72, 8, 36), Color(0.95, 0.95, 0.8, 0.7))
		2:
			for i in 26:
				var y := 132.0 + i * 22.0
				var w := 20.0 + fmod(i * 37.0, 90.0)
				draw_rect(Rect2(street.position.x + 14, y, w, 6), Color(0.3, 0.9, 0.45, 0.35))
		3:
			for i in 5:
				var y := 140.0 + i * 112.0
				Art.rrect(self, Rect2(street.position.x + 20, y, 130, 100), 6, Color(0.08, 0.09, 0.12), Color(0.3, 0.35, 0.45), 2)
				for k in 5:
					draw_circle(Vector2(street.position.x + 36 + k * 22, y + 20), 3, Color(0.2, 0.8, 1.0))
		4:
			for i in 6:
				draw_line(Vector2(street.position.x + i * 30, 120), Vector2(street.position.x + i * 30 + 60, 720), Color(1, 1, 1, 0.2), 6.0)
		5:
			for i in 14:
				draw_circle(Vector2(street.position.x + fmod(i * 53.0, 150.0) + 10.0, 140.0 + i * 40.0), 6.0 + (i % 3) * 3.0, Color(0.5, 1.0, 0.3, 0.25))
		6:
			for i in 10:
				var y := 130.0 + i * 60.0
				draw_line(Vector2(street.position.x, y), Vector2(1280, y + 20), Color(1.0, 0.2, 0.3, 0.3), 2.0)
