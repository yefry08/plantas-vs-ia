extends Robot
## Astra: se teletransporta 2 columnas y deja un campo que ralentiza los disparos.

var tp_timer := 0.0


func _init_behavior() -> void:
	tp_timer = float(data.params.get("tp_interval", 8.0)) * 0.6


func _behavior(delta: float) -> void:
	if position.x > Grid.RIGHT_EDGE or is_aligned():
		return
	tp_timer -= delta
	if tp_timer > 0.0:
		return
	tp_timer = float(data.params.get("tp_interval", 8.0))
	var dist := float(data.params.get("tp_cols", 2)) * Grid.CELL.x
	var new_x := maxf(position.x - dist, Grid.HOUSE_X + 40.0)
	level.add_field(Rect2(position.x - 100.0, position.y - 52.0, 200.0, 104.0),
		float(data.params.get("field_time", 5.0)), float(data.params.get("field_mult", 0.5)))
	level.fx.poof(position + Vector2(0, -20))
	position.x = new_x
	level.fx.poof(position + Vector2(0, -20))
	say("¡Salto estelar!", 1.2)
	AudioManager.play("teleport")
