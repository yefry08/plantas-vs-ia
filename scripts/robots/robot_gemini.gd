extends Robot
## Géminis Gemelo: se divide al 50% de vida y se vuelve inmune (multimodal) al
## tipo de daño que más ha recibido.

const IGNORED_TYPES := ["mower", "card", "ally", "bite"]

var has_split := false
var immune_type := ""
var check := 0.0


func _behavior(delta: float) -> void:
	check -= delta
	if check <= 0.0:
		check = float(data.params.get("immune_check", 2.5))
		_update_immunity()
	if not has_split and not is_illusion and not is_aligned() and health.ratio() <= float(data.params.get("split_ratio", 0.5)):
		_split()


func _update_immunity() -> void:
	var best := ""
	var best_v := 0.0
	for k in damage_by_type.keys():
		if IGNORED_TYPES.has(k):
			continue
		var v := float(damage_by_type[k])
		if v > best_v:
			best_v = v
			best = k
	if best != "" and best_v >= 60.0 and best != immune_type:
		immune_type = best
		say("Multimodal: inmune a %s" % GameState.damage_name(best), 1.8)


func _custom_damage_mult(dtype: String) -> float:
	return 0.0 if dtype == immune_type else 1.0


func _split() -> void:
	has_split = true
	var options: Array = [lane]
	for l in [lane - 1, lane + 1]:
		if level.is_lane_active(l):
			options.append(l)
	var twin_lane: int = options.pick_random()
	var twin = level.spawn_robot(data.id, twin_lane, position.x + 36.0)
	if twin != null:
		twin.has_split = true
		twin.immune_type = immune_type
		twin.health.set_health(health.health)
	say("¡Nos dividimos!", 1.5)
	level.fx.float_text(position + Vector2(0, -60), "x2", Color(0.6, 0.7, 1.0))


func _draw_overlays() -> void:
	super()
	if immune_type != "":
		Art.text_c(self, 0, 62, "Inmune: " + GameState.damage_name(immune_type), 11, Color(0.75, 0.85, 1.0), 3)
