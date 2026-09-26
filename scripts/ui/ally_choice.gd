class_name AllyChoice
extends Control
## Botón dibujado para elegir compañero de IA aliada.

signal chosen(id: String)

var ally_id := ""
var selected := false
var locked := false
var t := 0.0


func setup(id: String, is_locked: bool) -> AllyChoice:
	ally_id = id
	locked = is_locked
	custom_minimum_size = Vector2(92, 92)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var a: AllyData = GameState.allies[id]
	tooltip_text = "Se desbloquea más adelante en la campaña" if locked else "%s\nPasiva: %s\nHabilidad: %s — %s" % [a.display_name, a.passive_text, a.active_name, a.active_text]
	return self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not locked:
			chosen.emit(ally_id)
		else:
			AudioManager.play("error")
		accept_event()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var a: AllyData = GameState.allies[ally_id]
	var r := Rect2(Vector2.ZERO, size)
	Art.rrect(self, r.grow(-2), 10, Color(0.12, 0.2, 0.2, 0.9), a.color if selected else Color(1, 1, 1, 0.2), 4 if selected else 2)
	if locked:
		Art.lock_icon(self, size / 2.0, 2.0, Color(0.6, 0.6, 0.65))
		return
	ArtParody.ally(self, ally_id, size / 2.0 + Vector2(0, 6), 0.8, t, 0.4 if selected else 0.0)
