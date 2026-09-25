extends Robot
## Grokazo: rebelde; cambia de carril al azar, se burla o entra en modo doble ataque.

var event_timer := 0.0
var wild := 0.0


func _init_behavior() -> void:
	event_timer = _next_delay()


func _next_delay() -> float:
	return randf_range(float(data.params.get("event_min", 4.0)), float(data.params.get("event_max", 7.0)))


func _behavior(delta: float) -> void:
	if wild > 0.0:
		wild -= delta
		if wild <= 0.0:
			attack_mult = 1.0
			speed_mult_extra = 1.0
	if position.x > Grid.RIGHT_EDGE or is_aligned():
		return
	event_timer -= delta
	if event_timer > 0.0:
		return
	event_timer = _next_delay()
	var roll := randf()
	if roll < 0.4:
		var options: Array = []
		for l in [lane - 1, lane + 1]:
			if level.is_lane_active(l):
				options.append(l)
		if not options.is_empty():
			change_lane(options.pick_random())
			say("¡Aquí mando yo!", 1.4)
	elif roll < 0.7:
		holding = 1.5
		say("¡Jajaja!", 1.5)
		AudioManager.play("laugh")
	else:
		wild = 4.0
		attack_mult = 2.0
		speed_mult_extra = 1.4
		say("¡Modo sin filtro!", 1.6)


func _draw_overlays() -> void:
	if wild > 0.0:
		draw_arc(Vector2(0, -10), 40.0, 0, TAU, 24, Color(1.0, 0.3, 0.2, 0.55), 3.0, true)
	super()
