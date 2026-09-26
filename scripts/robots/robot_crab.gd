extends Robot
## Cangrejo de OpenGarra: pequeño y rápido; de vez en cuando camina de lado a otro carril.

var side_timer := 0.0


func _init_behavior() -> void:
	side_timer = randf_range(3.0, 6.0)


func _behavior(delta: float) -> void:
	if is_aligned() or position.x > Grid.RIGHT_EDGE:
		return
	side_timer -= delta
	if side_timer > 0.0:
		return
	side_timer = randf_range(4.0, 7.0)
	var options: Array = []
	for l in [lane - 1, lane + 1]:
		if level.is_lane_active(l):
			options.append(l)
	if not options.is_empty():
		change_lane(options.pick_random())
