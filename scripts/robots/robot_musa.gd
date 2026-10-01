extends Robot
## Musa: agente personal que "hace compras por ti": te quita energía solar
## y con ella pide robots a domicilio. Sigue trabajando aunque cierres la app.

const LINES := ["Comprado con tu energía.", "Pedido en camino.", "Ya reservé por ti.", "Pago completado."]

var shop_timer := 0.0


func _init_behavior() -> void:
	shop_timer = float(data.params.get("shop_interval", 9.0)) * 0.5


func _behavior(delta: float) -> void:
	if is_aligned() or position.x > Grid.RIGHT_EDGE:
		return
	shop_timer -= delta
	if shop_timer > 0.0:
		return
	shop_timer = float(data.params.get("shop_interval", 9.0))
	var price := int(data.params.get("steal_sun", 50))
	var taken := mini(price, GameState.sun)
	if taken > 0:
		GameState.add_sun(-taken)
		level.fx.float_text(Vector2(52, 120), "-%d sol" % taken, Color(1.0, 0.7, 0.3), 18)
		level.fx.beam(position + Vector2(-30, -20), Vector2(52, 60), Color(0.5, 0.6, 1.0))
	var catalog: Array = data.params.get("catalog", ["spambot"])
	var lane_to: int = level.random_active_lane()
	level.spawn_robot(String(catalog.pick_random()), lane_to, Grid.SPAWN_X, {"summoned": true})
	say(LINES.pick_random(), 1.6)
	AudioManager.play("token")
