extends Robot
## OpenGarra: agente autónomo; arranca una planta cercana cada cierto tiempo y roba tokens.

var grab_timer := 0.0
var grab_anim := 0.0


func _init_behavior() -> void:
	grab_timer = float(data.params.get("grab_interval", 10.0)) * 0.5


func _behavior(delta: float) -> void:
	grab_anim = maxf(0.0, grab_anim - delta * 1.5)
	if position.x > Grid.RIGHT_EDGE or is_aligned():
		return
	grab_timer -= delta
	if grab_timer > 0.0:
		return
	var target: Node = level.lanes.plant_in_reach(lane, position.x, float(data.params.get("grab_range", 260.0)))
	if target == null:
		grab_timer = 1.0
		return
	grab_timer = float(data.params.get("grab_interval", 10.0))
	grab_anim = 1.0
	level.fx.claw(position + Vector2(-36, -18), target.position)
	level.fx.burst(target.position, Color(0.4, 0.75, 0.3), 8)
	target.remove()
	var steal := int(data.params.get("steal", 1))
	if GameState.tokens > 0 and steal > 0:
		GameState.add_tokens(-steal)
		level.fx.float_text(position + Vector2(0, -80), "-%d token" % steal, Color(1.0, 0.8, 0.3))
	say("¡Tarea completada!", 1.4)
	AudioManager.play("hack")


func _draw_opts() -> Dictionary:
	return {"grab": grab_anim}
