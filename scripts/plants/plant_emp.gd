extends Plant
## Hongo EMP: pulso que aturde a los robots en un área 3x3.


func _init_behavior() -> void:
	act_timer = 1.5


func _behavior(delta: float) -> void:
	act_timer -= delta
	if act_timer > 0.0:
		return
	var reach := (data.area_cells + 0.5) * Grid.CELL.x
	var targets: Array = level.lanes.enemies_in_area(row - data.area_cells, row + data.area_cells, position.x - reach, position.x + reach)
	if targets.is_empty():
		act_timer = 0.2
		return
	act_timer = data.fire_interval
	for r in targets:
		r.status.apply_stun(data.stun_time)
		r.take_damage(data.damage, data.damage_type, self)
	level.fx.ring(position, reach, Color(0.7, 0.45, 1.0))
	AudioManager.play("emp")


func _draw_opts() -> Dictionary:
	return {"charge": clamp(1.0 - act_timer / data.fire_interval, 0.0, 1.0)}
