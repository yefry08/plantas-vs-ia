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
		var from := position + Vector2(randf_range(-12, 12), -30)
		var to := position + Vector2(randf_range(-26, 26), 22)
		level.spawn_pickup(kind, data.produce_amount, from, to, true)


func _draw_opts() -> Dictionary:
	return {"glow": glow}
