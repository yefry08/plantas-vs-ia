class_name BossBar
extends Control
## HUD del jefe: vida, fase, resistencias ganadas y progreso de Alineamiento.

var boss: Node = null
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var r := Rect2(Vector2.ZERO, size)
	var col: Color = boss.phase_color()
	Art.rrect(self, r, 10, Color(0.06, 0.05, 0.1, 0.85), col, 2)
	Art.text(self, Vector2(12, 20), "AGI — Fase %d/3" % boss.phase, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	var bar := Rect2(150, 8, size.x - 162, 14)
	draw_rect(bar, Color(0.2, 0.2, 0.25))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * boss.health.ratio(), bar.size.y)), col)
	for f in [0.33, 0.66]:
		var x: float = bar.position.x + bar.size.x * f
		draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), Color.WHITE, 2.0)
	var x0 := 12.0
	if boss.resist_list.is_empty():
		Art.text(self, Vector2(x0, 44), "Sin resistencias (aún)", 13, Color(0.7, 0.7, 0.8))
	else:
		Art.text(self, Vector2(x0, 44), "Resiste:", 13, Color(1, 0.8, 0.8))
		var x := x0 + 62.0
		for k in boss.resist_list:
			var label := GameState.damage_name(k)
			var w: float = Art.font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
			Art.rrect(self, Rect2(x, 31, w, 18), 6, Color(0.5, 0.15, 0.2))
			Art.text(self, Vector2(x + 6, 45), label, 12, Color.WHITE)
			x += w + 4.0
	var need: int = boss.needed_alignments()
	var hx := size.x - 20.0 - need * 26.0
	Art.text(self, Vector2(hx - 92, 45), "Alineamiento:", 12, Color(0.6, 1.0, 0.7) if boss.phase == 3 else Color(0.5, 0.5, 0.55))
	for i in need:
		var c := Color(0.4, 1.0, 0.55) if i < boss.align_count else Color(0.3, 0.32, 0.38)
		Art.heart(self, Vector2(hx + i * 26.0 + 10.0, 40), 0.9, c)
