extends Robot
## Claudio: robot de plástico crema, servicial... con los otros robots.
## Repara cada pocos segundos a los robots cercanos.

const LINES := ["¡Te ayudo!", "Con gusto.", "¿Puedo ayudarte en algo más?", "Revisando tus daños..."]

var heal_timer := 0.0


func _init_behavior() -> void:
	heal_timer = float(data.params.get("heal_interval", 5.0)) * 0.5


func _behavior(delta: float) -> void:
	if is_aligned() or position.x > Grid.RIGHT_EDGE + 20.0:
		return
	heal_timer -= delta
	if heal_timer > 0.0:
		return
	heal_timer = float(data.params.get("heal_interval", 5.0))
	var amount := float(data.params.get("heal_amount", 60.0))
	var radius := float(data.params.get("heal_radius", 160.0))
	var healed := 0
	for r in level.lanes.all_enemies():
		if r == self or r.is_illusion:
			continue
		if r.position.distance_to(position) <= radius and r.health.health < r.health.max_health:
			r.health.heal(amount)
			level.fx.float_text(r.position + Vector2(0, -60), "+%d" % int(amount), Color(0.6, 1.0, 0.6), 14)
			healed += 1
	if healed > 0:
		level.fx.ring(position, radius, Color(0.95, 0.85, 0.6))
		say(LINES.pick_random(), 1.4)
