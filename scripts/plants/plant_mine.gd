extends Plant
## Mina Bug: tarda en armarse; luego explota al contacto.

var armed := false


func _init_behavior() -> void:
	act_timer = data.arm_time


func is_blocking() -> bool:
	return not armed


func _behavior(delta: float) -> void:
	if not armed:
		act_timer -= delta
		if act_timer <= 0.0:
			armed = true
			level.fx.float_text(position + Vector2(0, -30), "¡Armada!", Color(1, 0.5, 0.4))
			AudioManager.play("pop")
		return
	for r in level.lanes.enemies_in_lane(row):
		if not r.is_illusion and abs(r.front_x() - position.x) < 44.0:
			_explode()
			return


func _explode() -> void:
	for r in level.lanes.enemies_in_area(row, row, position.x - 90.0, position.x + 90.0):
		r.take_damage(data.damage, data.damage_type, self)
	level.fx.explosion(position, 90.0)
	AudioManager.play("explode")
	remove()


func _draw_opts() -> Dictionary:
	return {"armed": armed}
