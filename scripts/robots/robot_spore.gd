extends Robot
## Esporabot (bioarma IA): lanza esporas que toman el control de una planta.

var spore_timer := 0.0


func _init_behavior() -> void:
	spore_timer = float(data.params.get("spore_interval", 7.0)) * 0.6


func _behavior(delta: float) -> void:
	if is_aligned() or position.x > Grid.RIGHT_EDGE:
		return
	spore_timer -= delta
	if spore_timer > 0.0:
		return
	var target: Node = level.lanes.plant_in_reach(lane, position.x, float(data.params.get("spore_range", 520.0)))
	if target == null or target.status.is_controlled():
		spore_timer = 1.0
		return
	spore_timer = float(data.params.get("spore_interval", 7.0))
	level.fx.beam(position + Vector2(0, -40), target.position + Vector2(0, -20), Color(0.7, 1.0, 0.35))
	level.fx.burst(target.position + Vector2(0, -20), Color(0.7, 0.4, 1.0), 10)
	if target.take_control(float(data.params.get("control_time", 8.0))):
		say("¡Esa planta es mía!", 1.4)
	AudioManager.play("hack")
