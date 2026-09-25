class_name AllyBuddy
extends Control
## El pequeño robot de IA aliada en la esquina del HUD. Se anima cada vez que
## el jugador usa una carta.

var t := 0.0
var excited := 0.0
var line := ""
var line_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func perform(card: CardData) -> void:
	excited = 1.0
	line = "¡%s!" % card.display_name
	line_timer = 2.2


func say(s: String, time := 2.0) -> void:
	line = s
	line_timer = time


func _process(delta: float) -> void:
	t += delta
	excited = maxf(0.0, excited - delta * 0.7)
	line_timer = maxf(0.0, line_timer - delta)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y - 46)
	if excited > 0.0:
		draw_circle(c, 40.0 + excited * 10.0, Color(0.4, 1.0, 0.7, 0.25 * excited))
	Art.buddy(self, c, 1.0 + excited * 0.15, t * (1.0 + excited * 3.0), excited)
	Art.text_c(self, c.x, size.y - 4, "IA aliada", 12, Color(0.75, 1.0, 0.85), 3)
	if line_timer > 0.0:
		var f := Art.font()
		var tw: float = f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var r := Rect2(c + Vector2(34, -70), Vector2(tw + 18.0, 28))
		Art.rrect(self, r, 9, Color(0.92, 1.0, 0.95, 0.95), Color(0.3, 0.6, 0.5), 2)
		Art.poly(self, [r.position + Vector2(4, 18), r.position + Vector2(-10, 30), r.position + Vector2(16, 26)], Color(0.92, 1.0, 0.95, 0.95))
		Art.text(self, r.position + Vector2(9, 20), line, 15, Color(0.1, 0.25, 0.2))
