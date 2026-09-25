extends Robot
## Razonador Serie-O: se detiene a "pensar" y salta al carril con menos defensas.

var think_timer := 0.0
var thinking := 0.0
var jumps := 0


func _init_behavior() -> void:
	think_timer = float(data.params.get("think_interval", 8.0)) * 0.5


func _behavior(delta: float) -> void:
	if thinking > 0.0:
		thinking -= delta
		if thinking <= 0.0:
			_decide()
		return
	if jumps >= int(data.params.get("max_jumps", 2)) or position.x > Grid.RIGHT_EDGE or is_aligned():
		return
	think_timer -= delta
	if think_timer <= 0.0:
		var tt := float(data.params.get("think_time", 2.0))
		thinking = tt
		holding = tt
		think_timer = float(data.params.get("think_interval", 8.0))
		say("Pensando...", tt)
		AudioManager.play("think")


func _decide() -> void:
	var best := lane
	var best_score := INF
	for l in level.active_lanes:
		var s: float = level.lanes.lane_defense(l, position.x) + (0.0 if l == lane else 30.0)
		if s < best_score:
			best_score = s
			best = l
	if best != lane:
		change_lane(best)
		say("Carril %d: óptimo" % (best + 1), 1.4)
		jumps += 1
	else:
		say("Sigo aquí. Óptimo.", 1.2)


func _draw_opts() -> Dictionary:
	return {"thinking": thinking > 0.0}
