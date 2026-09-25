extends Robot
## Qilin Eficiente: usa la mitad de cómputo (aturdimientos le duran la mitad)
## y acelera cuando va en manada.

var pack_check := 0.0


func _behavior(delta: float) -> void:
	pack_check -= delta
	if pack_check > 0.0:
		return
	pack_check = 0.5
	var n := 0
	for r in level.lanes.enemies_in_lane(lane):
		if r != self and r.data.id == data.id and abs(r.position.x - position.x) < 170.0:
			n += 1
	speed_mult_extra = float(data.params.get("pack_speed", 1.25)) if n >= 2 else 1.0
