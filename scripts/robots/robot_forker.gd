extends Robot
## Abrazobot: al morir se "forkea" en copias pequeñas.


func _on_death() -> void:
	if is_mini or is_illusion:
		return
	var n := int(data.params.get("fork_count", 2))
	var ratio := float(data.params.get("fork_ratio", 0.3))
	for i in n:
		var offset := (float(i) - (n - 1) / 2.0) * 34.0
		level.spawn_robot(data.id, lane, position.x + offset, {"mini": ratio})
	level.fx.float_text(position + Vector2(0, -60), "git fork!", Color(1.0, 0.9, 0.4))
