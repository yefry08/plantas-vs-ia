class_name WaveProgress
extends Control
## Barra de progreso de oleadas con banderas en las oleadas grandes.

var waves: WaveManager
var shown := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if waves == null:
		return
	shown = move_toward(shown, waves.progress(), delta * 0.5)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Art.rrect(self, r, 8, Color(0.1, 0.1, 0.1, 0.75), Color(0.6, 0.6, 0.5), 2)
	var inner := r.grow(-4)
	# La barra se llena de derecha a izquierda, como avanzan los robots.
	var w := inner.size.x * shown
	if w > 2.0:
		Art.rrect(self, Rect2(inner.end.x - w, inner.position.y, w, inner.size.y), 5, Color(0.4, 0.8, 0.3))
	if waves == null:
		return
	for m in waves.huge_wave_marks():
		var x: float = inner.end.x - inner.size.x * float(m)
		draw_line(Vector2(x, 0), Vector2(x, -12), Color(0.3, 0.2, 0.1), 2.0)
		Art.poly(self, [Vector2(x, -12), Vector2(x + 12, -8), Vector2(x, -4)], Color(0.9, 0.2, 0.2))
	var hx := inner.end.x - w
	draw_circle(Vector2(hx, size.y / 2.0), 9, Color(0.6, 0.64, 0.7))
	draw_circle(Vector2(hx - 3, size.y / 2.0 - 1), 2.2, Color(0.3, 0.9, 1.0))
	draw_circle(Vector2(hx + 3, size.y / 2.0 - 1), 2.2, Color(0.3, 0.9, 1.0))
