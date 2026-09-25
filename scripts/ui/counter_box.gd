class_name CounterBox
extends Control
## Contador de energía solar o de tokens en el HUD.

var kind := "sun"
var value := 0
var pulse := 0.0
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == "sun":
		GameState.sun_changed.connect(_on_changed)
		value = GameState.sun
	else:
		GameState.tokens_changed.connect(_on_changed)
		value = GameState.tokens


func _on_changed(v: int) -> void:
	if v != value:
		pulse = 0.3
	value = v


func flash_error() -> void:
	pulse = -0.5


func _process(delta: float) -> void:
	t += delta
	if pulse > 0.0:
		pulse = maxf(0.0, pulse - delta)
	elif pulse < 0.0:
		pulse = minf(0.0, pulse + delta)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var bg := Color(0.2, 0.16, 0.08, 0.85) if kind == "sun" else Color(0.18, 0.14, 0.3, 0.85)
	var border := Color(0.9, 0.7, 0.25) if kind == "sun" else Color(0.95, 0.8, 0.3)
	if pulse < 0.0 and fmod(t, 0.2) < 0.1:
		border = Color(1, 0.2, 0.2)
	Art.rrect(self, r.grow(-2), 10, bg, border, 3)
	var s := 1.0 + maxf(pulse, 0.0) * 0.6
	var c := Vector2(size.x / 2.0, 36)
	if kind == "sun":
		Art.sun_icon(self, c, 17.0 * s, t)
	else:
		Art.token_icon(self, c, 17.0 * s)
	Art.text_c(self, size.x / 2.0, size.y - 12, str(value), 24, Color.WHITE, 5)
	if kind == "token":
		Art.text_c(self, size.x / 2.0, 12, "TOKENS", 10, Color(1, 0.9, 0.6), 2)
