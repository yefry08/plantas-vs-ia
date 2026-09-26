extends Plant
## Girasolar (energía) y Tokenizadora (tokens).

var glow := 0.0


func _init_behavior() -> void:
	act_timer = data.first_produce_delay


func _behavior(delta: float) -> void:
	glow = max(0.0, glow - delta)
	act_timer -= delta
	if act_timer <= 0.0:
		act_timer = data.produce_interval
		glow = 1.0
		var kind := "token" if data.behavior == "token" else "sun"
		for i in data.produce_count:
			var from := position + Vector2(0, -30)
			var spread := (float(i) - (data.produce_count - 1) / 2.0) * 34.0
			var to := position + Vector2(spread + randf_range(-10, 10), 26 + randf_range(-6, 6))
			level.spawn_pickup(kind, data.produce_amount, from, to, true)
		AudioManager.play("pop")


func _draw_opts() -> Dictionary:
	return {"glow": glow}
