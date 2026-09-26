class_name Pickup
extends Node2D
## Energía solar y tokens que se recogen con un clic / toque.

const SUN_TARGET := Vector2(52, 44)
const TOKEN_TARGET := Vector2(738, 44)

var level: Node
var kind := "sun"
var value := 25
var target := Vector2.ZERO
var fall_speed := 70.0
var life := 11.0
var auto_collect := -1.0
var collecting := false
var fly_t := 0.0
var fly_from := Vector2.ZERO
var t := 0.0
## Lanzamiento en arco (girasoles): 0..1, -1 = cae en línea recta.
var arc := -1.0
var arc_from := Vector2.ZERO


func setup(lvl: Node, k: String, v: int, from: Vector2, to: Vector2, pop := false) -> void:
	level = lvl
	kind = k
	value = v
	position = from
	target = to
	if pop:
		arc = 0.0
		arc_from = from
	if kind == "token":
		auto_collect = 2.5
		life = 99.0


func _process(delta: float) -> void:
	t += delta
	if collecting:
		fly_t = minf(1.0, fly_t + delta * 2.4)
		var dest := SUN_TARGET if kind == "sun" else TOKEN_TARGET
		position = fly_from.lerp(dest, ease(fly_t, 0.5))
		scale = Vector2.ONE * lerpf(1.0, 0.55, fly_t)
		if fly_t >= 1.0:
			if kind == "sun":
				GameState.add_sun(value)
			else:
				GameState.add_tokens(value)
			queue_free()
		queue_redraw()
		return
	if arc >= 0.0 and arc < 1.0:
		arc = minf(1.0, arc + delta * 1.6)
		position = arc_from.lerp(target, arc) + Vector2(0, -70.0 * sin(arc * PI))
	else:
		position = position.move_toward(target, fall_speed * delta)
	life -= delta
	if auto_collect >= 0.0:
		auto_collect -= delta
		if auto_collect < 0.0:
			collect()
	if life <= 0.0:
		queue_free()
		return
	modulate.a = 1.0 if life > 3.0 or fmod(life, 0.4) > 0.2 else 0.35
	queue_redraw()


func can_collect_at(p: Vector2) -> bool:
	return not collecting and p.distance_to(position) < 48.0


func collect() -> void:
	if collecting:
		return
	collecting = true
	fly_from = position
	modulate.a = 1.0
	AudioManager.play("sun" if kind == "sun" else "token")
	GameState.pickup_collected.emit(kind)


func _draw() -> void:
	if kind == "sun":
		Art.sun_icon(self, Vector2.ZERO, 20.0 if value >= 25 else 15.0, t)
		if value > 25:
			Art.text_c(self, 0, 6, str(value), 14, Color(0.5, 0.3, 0.0))
	else:
		Art.token_icon(self, Vector2.ZERO, 15.0)
		if value > 1:
			Art.text(self, Vector2(12, -10), "x%d" % value, 14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
