extends Robot
## Emojibot Multitarea: feliz = avanza, enojado = ataca más rápido, dormido = aturdido.

var anger := 0.0


func _behavior(delta: float) -> void:
	if attacking:
		anger = minf(anger + delta, 3.0)
	else:
		anger = maxf(anger - delta * 0.5, 0.0)
	var angry := anger > 0.8
	attack_mult = float(data.params.get("angry_attack_mult", 2.0)) if angry else 1.0


func _expr() -> String:
	if status.is_disabled():
		return "sleep"
	if anger > 0.8:
		return "angry"
	if status.is_slowed():
		return "shock"
	return "happy"
