extends Robot
## Dotz: agentes "siempre encendidos". No se pueden apagar con cartas y cada uno
## se asigna nuevos dots hasta formar un enjambre (con tope global).

var task_timer := 0.0


func _init_behavior() -> void:
	task_timer = randf_range(4.0, float(data.params.get("spawn_interval", 9.0)))


func _behavior(delta: float) -> void:
	if is_aligned() or is_mini or position.x > Grid.RIGHT_EDGE:
		return
	task_timer -= delta
	if task_timer > 0.0:
		return
	task_timer = float(data.params.get("spawn_interval", 9.0))
	var count := 0
	for r in level.lanes.all_enemies():
		if r.data.id == data.id:
			count += 1
	if count >= int(data.params.get("swarm_cap", 12)):
		return
	level.spawn_robot(data.id, lane, position.x + 34.0, {"summoned": true})
	say("Nueva tarea asignada.", 1.2)
