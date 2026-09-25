extends Plant
## Enredadera Captcha: el primer robot que la toca queda ralentizado.


func is_blocking() -> bool:
	return false


func _behavior(_delta: float) -> void:
	for r in level.lanes.enemies_in_lane(row):
		if r.is_illusion:
			continue
		if abs(r.front_x() - position.x) < 34.0:
			r.status.apply_slow(data.slow_factor, data.slow_time)
			r.say("¿Soy un robot?", 1.5)
			level.fx.float_text(position + Vector2(0, -40), "¡Captcha!", Color(0.6, 1.0, 0.6))
			AudioManager.play("captcha")
			remove()
			return
