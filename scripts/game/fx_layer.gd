class_name FxLayer
extends Node2D
## Efectos visuales ligeros dibujados en una sola capa (texto flotante,
## explosiones, rayos, anillos EMP, garra, campos de Astra).

var items: Array = []
var level: Node
var had_items := false


func _process(delta: float) -> void:
	for it in items:
		it["t"] = float(it["t"]) + delta
	items = items.filter(func(it): return float(it["t"]) < float(it["dur"]))
	var has_fields: bool = level != null and not level.fields.is_empty()
	if not items.is_empty() or has_fields or had_items:
		queue_redraw()
	had_items = not items.is_empty() or has_fields


func _add(d: Dictionary) -> void:
	d["t"] = 0.0
	items.append(d)
	if items.size() > 160:
		items.pop_front()


func float_text(pos: Vector2, s: String, col := Color.WHITE, size := 18) -> void:
	_add({"type": "text", "pos": pos, "text": s, "col": col, "size": size, "dur": 1.2})


func burst(pos: Vector2, col: Color, n := 10) -> void:
	var parts: Array = []
	for i in n:
		parts.append({"dir": Vector2.from_angle(randf() * TAU) * randf_range(40.0, 120.0), "r": randf_range(3.0, 7.0)})
	_add({"type": "burst", "pos": pos, "col": col, "parts": parts, "dur": 0.5})


func spark(pos: Vector2, col: Color) -> void:
	_add({"type": "spark", "pos": pos, "col": col, "dur": 0.18})


func ring(pos: Vector2, radius: float, col: Color) -> void:
	_add({"type": "ring", "pos": pos, "radius": radius, "col": col, "dur": 0.5})


func explosion(pos: Vector2, radius: float) -> void:
	_add({"type": "explosion", "pos": pos, "radius": radius, "dur": 0.55})
	burst(pos, Color(1.0, 0.55, 0.15), 16)


func lightning(points: PackedVector2Array, col := Color(0.75, 0.9, 1.0)) -> void:
	var jag := PackedVector2Array()
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		jag.append(a)
		for k in range(1, 5):
			var p := a.lerp(b, k / 5.0)
			jag.append(p + Vector2(randf_range(-9, 9), randf_range(-9, 9)))
	if points.size() > 0:
		jag.append(points[points.size() - 1])
	_add({"type": "bolt", "pts": jag, "col": col, "dur": 0.25})


func claw(from: Vector2, to: Vector2) -> void:
	_add({"type": "claw", "from": from, "to": to, "dur": 0.45})


func poof(pos: Vector2) -> void:
	_add({"type": "poof", "pos": pos, "dur": 0.4})


func beam(from: Vector2, to: Vector2, col: Color) -> void:
	_add({"type": "beam", "from": from, "to": to, "col": col, "dur": 0.5})


func _draw() -> void:
	if level != null:
		for f in level.fields:
			var r: Rect2 = f["rect"]
			var a: float = clampf(float(f["time"]), 0.0, 1.0)
			Art.rrect(self, r, 14, Color(0.55, 0.85, 1.0, 0.16 * a), Color(0.6, 0.9, 1.0, 0.5 * a), 2.0)
			for i in 4:
				var sx: float = r.position.x + fmod(float(f["time"]) * 40.0 + i * 50.0, r.size.x)
				draw_colored_polygon(Art.star_points(Vector2(sx, r.position.y + 20 + i * 20), 5, 2, 4), Color(1, 1, 1, 0.5 * a))
	for it in items:
		var k: float = float(it["t"]) / float(it["dur"])
		match String(it["type"]):
			"text":
				var c: Color = it["col"]
				c.a = 1.0 - k * k
				var p: Vector2 = it["pos"] + Vector2(0, -40.0 * k)
				Art.text_c(self, p.x, p.y, String(it["text"]), int(it["size"]), c, 4)
			"burst":
				var c: Color = it["col"]
				c.a = 1.0 - k
				for part in it["parts"]:
					draw_circle(it["pos"] + part["dir"] * k, float(part["r"]) * (1.0 - k * 0.5), c)
			"spark":
				var c: Color = it["col"]
				c.a = 1.0 - k
				draw_circle(it["pos"], 6.0 + 10.0 * k, c)
			"ring":
				var c: Color = it["col"]
				c.a = 0.9 * (1.0 - k)
				draw_arc(it["pos"], float(it["radius"]) * (0.3 + 0.7 * k), 0, TAU, 40, c, 6.0 * (1.0 - k) + 1.0, true)
				draw_circle(it["pos"], float(it["radius"]) * (0.3 + 0.7 * k), Color(c.r, c.g, c.b, 0.15 * (1.0 - k)))
			"explosion":
				var rad: float = float(it["radius"]) * (0.4 + 0.8 * k)
				draw_circle(it["pos"], rad, Color(1.0, 0.55, 0.1, 0.6 * (1.0 - k)))
				draw_circle(it["pos"], rad * 0.6, Color(1.0, 0.9, 0.4, 0.8 * (1.0 - k)))
			"bolt":
				var c: Color = it["col"]
				c.a = 1.0 - k
				draw_polyline(it["pts"], Color(c.r, c.g, c.b, c.a * 0.4), 9.0, true)
				draw_polyline(it["pts"], c, 3.0, true)
			"claw":
				var from: Vector2 = it["from"]
				var to: Vector2 = it["to"]
				var reach: float = sin(k * PI)
				var tip := from.lerp(to, reach)
				draw_line(from, tip, Color(0.9, 0.5, 0.2), 6.0)
				draw_circle(tip, 10, Color(0.6, 0.3, 0.1))
			"poof":
				for i in 6:
					var d := Vector2.from_angle(TAU * i / 6.0) * 30.0 * k
					draw_circle(it["pos"] + d, 10.0 * (1.0 - k), Color(0.85, 0.85, 1.0, 0.7 * (1.0 - k)))
			"beam":
				var c: Color = it["col"]
				c.a = 1.0 - k
				draw_line(it["from"], it["to"], Color(c.r, c.g, c.b, c.a * 0.35), 14.0)
				draw_line(it["from"], it["to"], c, 4.0)
