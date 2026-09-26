extends Plant
## Rosa Antídoto: cura cada pocos segundos a las plantas controladas o hackeadas
## en un área 3x3 y las protege un rato.


func _init_behavior() -> void:
	act_timer = 1.0


func _behavior(delta: float) -> void:
	act_timer -= delta
	if act_timer > 0.0:
		return
	act_timer = data.fire_interval
	var reach := (data.area_cells + 0.5) * Grid.CELL.x
	var cured := 0
	for p in level.lanes.all_plants():
		if abs(p.row - row) <= data.area_cells and abs(p.position.x - position.x) <= reach:
			if p.status.is_controlled() or p.status.hack_timer > 0.0:
				cured += 1
			p.cure(data.stun_time)
	if cured > 0:
		level.fx.ring(position, reach, Color(0.5, 1.0, 0.6))
		AudioManager.play("gulp")
