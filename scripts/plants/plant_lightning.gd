extends Plant
## Bambú Pararrayos: rayo en cadena, con bonus contra robots blindados.


func _init_behavior() -> void:
	act_timer = 0.8


func _behavior(delta: float) -> void:
	act_timer -= delta
	if act_timer > 0.0:
		return
	var first: Node = level.lanes.first_enemy_ahead(row, position.x)
	if first == null:
		act_timer = 0.2
		return
	act_timer = data.fire_interval
	var hit: Array = [first]
	var pts := PackedVector2Array([position + Vector2(0, -66), first.position + Vector2(0, -20)])
	var cur: Node = first
	while hit.size() < data.chain_count:
		var nxt: Node = level.lanes.nearest_enemy_to(cur.position, data.chain_range, hit)
		if nxt == null:
			break
		hit.append(nxt)
		pts.append(nxt.position + Vector2(0, -20))
		cur = nxt
	level.fx.lightning(pts)
	for r in hit:
		var dmg := data.damage
		if r.is_armored():
			dmg *= data.armored_bonus
		r.take_damage(dmg, data.damage_type, self)
	AudioManager.play("zap")


func _draw_opts() -> Dictionary:
	return {"charge": clamp(1.0 - act_timer / data.fire_interval, 0.0, 1.0)}
