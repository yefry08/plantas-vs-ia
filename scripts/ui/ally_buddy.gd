class_name AllyBuddy
extends Control
## El compañero de IA aliada en la esquina del HUD. Comenta la partida, se anima
## al usar cartas y, al tocarlo, activa su habilidad especial.

var level: Node
var ally: AllyData
var t := 0.0
var excited := 0.0
var line := ""
var line_timer := 0.0
var hover := false


func setup(lvl: Node, a: AllyData) -> void:
	level = lvl
	ally = a
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "%s\nPasiva: %s\nToca: %s — %s" % [a.display_name, a.passive_text, a.active_name, a.active_text]
	mouse_entered.connect(func(): hover = true)
	mouse_exited.connect(func(): hover = false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if level != null:
			level.use_ally_power()
		accept_event()


func perform(card: CardData) -> void:
	excited = 1.0
	say("¡%s!" % card.display_name, 2.2)


func perform_power(power_name: String) -> void:
	excited = 1.0
	say("¡%s!" % power_name, 2.5)


func say(s: String, time := 2.0) -> void:
	line = s
	line_timer = time


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	t += real
	excited = maxf(0.0, excited - real * 0.7)
	line_timer = maxf(0.0, line_timer - real)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y - 50)
	var id := ally.id if ally != null else "transformer"
	var col := ally.color if ally != null else Color(0.4, 1.0, 0.7)
	var ready := level != null and float(level.ally_cd) <= 0.0
	if excited > 0.0:
		draw_circle(c, 42.0 + excited * 10.0, Color(col.r, col.g, col.b, 0.25 * excited))
	# Anillo de recarga de la habilidad
	var ratio := 1.0
	if level != null and ally != null and ally.active_cooldown > 0.0:
		ratio = 1.0 - float(level.ally_cd) / ally.active_cooldown
	draw_arc(c, 40, -PI / 2.0, -PI / 2.0 + TAU, 40, Color(0, 0, 0, 0.35), 5.0, true)
	draw_arc(c, 40, -PI / 2.0, -PI / 2.0 + TAU * ratio, 40, col if ready else col.darkened(0.3), 5.0, true)
	if ready:
		draw_arc(c, 44.0 + sin(t * 5.0) * 2.0, 0, TAU, 40, Color(col.r, col.g, col.b, 0.5), 2.0, true)
	var s := 1.0 + excited * 0.15 + (0.05 if hover else 0.0)
	ArtParody.ally(self, id, c, s, t * (1.0 + excited * 3.0), excited)
	var label := ally.display_name if ally != null else "IA aliada"
	Art.text_c(self, c.x, size.y - 2, label, 12, Color(0.85, 1.0, 0.9), 3)
	if ready:
		Art.text_c(self, c.x, c.y - 52, "¡Tócame!", 12, Color(1.0, 1.0, 0.6), 3)
	if line_timer > 0.0:
		var f := Art.font()
		var tw: float = minf(f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, 360.0)
		var r := Rect2(c + Vector2(40, -86), Vector2(tw + 18.0, 28))
		Art.rrect(self, r, 9, Color(0.95, 1.0, 0.96, 0.96), col.darkened(0.3), 2)
		Art.poly(self, [r.position + Vector2(4, 18), r.position + Vector2(-12, 32), r.position + Vector2(16, 26)], Color(0.95, 1.0, 0.96, 0.96))
		Art.text(self, r.position + Vector2(9, 20), line, 15, Color(0.1, 0.25, 0.2), HORIZONTAL_ALIGNMENT_LEFT, 360.0)
