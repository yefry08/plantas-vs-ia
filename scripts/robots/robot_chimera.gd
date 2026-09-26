extends Robot
## Quimera Bio (élite bioarma IA): pulso que controla todas las plantas en 3x3.

var pulse_timer := 0.0


func _init_behavior() -> void:
	pulse_timer = float(data.params.get("pulse_interval", 12.0)) * 0.5


func _behavior(delta: float) -> void:
	if is_aligned() or position.x > Grid.RIGHT_EDGE:
		return
	pulse_timer -= delta
	if pulse_timer > 0.0:
		return
	pulse_timer = float(data.params.get("pulse_interval", 12.0))
	var reach := 1.5 * Grid.CELL.x
	var n := 0
	for p in level.lanes.all_plants():
		if abs(p.row - lane) <= 1 and abs(p.position.x - position.x) <= reach:
			if p.take_control(float(data.params.get("control_time", 6.0))):
				n += 1
	level.fx.ring(position, reach, Color(0.7, 1.0, 0.35))
	if n > 0:
		say("Mutación en %d plantas." % n, 1.6)
		AudioManager.play("emp")
