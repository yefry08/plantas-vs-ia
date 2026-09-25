extends Robot
## Mythos: tanque de ciberseguridad; hackea la planta más fuerte de su carril.

var hack_timer := 0.0


func _init_behavior() -> void:
	hack_timer = float(data.params.get("hack_interval", 8.0)) * 0.5


func _behavior(delta: float) -> void:
	if position.x > Grid.RIGHT_EDGE or is_aligned():
		return
	hack_timer -= delta
	if hack_timer > 0.0:
		return
	var p: Node = level.lanes.strongest_plant_in_lane(lane, position.x + 40.0)
	if p == null:
		hack_timer = 1.0
		return
	hack_timer = float(data.params.get("hack_interval", 8.0))
	p.hack(float(data.params.get("hack_time", 6.0)))
	level.fx.lightning(PackedVector2Array([position + Vector2(0, -50), p.position + Vector2(0, -30)]), Color(1.0, 0.3, 0.35))
	level.fx.float_text(p.position + Vector2(0, -60), "HACKEADA", Color(1.0, 0.4, 0.4))
	say("Acceso concedido.", 1.4)
	AudioManager.play("hack")
