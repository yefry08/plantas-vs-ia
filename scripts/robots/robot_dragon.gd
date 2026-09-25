extends Robot
## Dragón Destilado: copia ("destila") una habilidad de la última planta que lo dañó.

const ABILITY_NAMES := {"ranged": "Disparo", "armor": "Coraza", "haste": "Prisa", "heal": "Regeneración"}
const ABILITY_COLORS := {"ranged": Color(0.4, 1.0, 0.4), "armor": Color(0.9, 0.6, 0.3), "haste": Color(0.4, 0.8, 1.0), "heal": Color(1.0, 0.5, 0.8)}

var ability := ""
var ability_timer := 0.0
var shot_timer := 0.0


func _on_plant_hit(p: Node) -> void:
	if ability_timer > 0.0 or is_aligned():
		return
	match String(p.data.behavior):
		"shooter", "lightning":
			ability = "ranged"
		"wall", "mine", "trap":
			ability = "armor"
		"emp":
			ability = "haste"
		_:
			ability = "heal"
	ability_timer = float(data.params.get("distill_time", 5.0))
	shot_timer = 0.4
	say("Destilé: %s" % ABILITY_NAMES[ability], 1.6)


func _behavior(delta: float) -> void:
	if ability_timer <= 0.0:
		return
	ability_timer -= delta
	if ability_timer <= 0.0:
		ability = ""
		speed_mult_extra = 1.0
		return
	match ability:
		"ranged":
			shot_timer -= delta
			if shot_timer <= 0.0:
				shot_timer = 1.5
				if not is_aligned() and level.lanes.has_plant_ahead(lane, position.x):
					level.spawn_enemy_projectile(self, position + Vector2(-44, -30), lane, 20.0)
		"haste":
			speed_mult_extra = 1.6
		"heal":
			health.heal(15.0 * delta)


func _custom_damage_mult(_dtype: String) -> float:
	return 0.5 if ability == "armor" else 1.0


func _draw_overlays() -> void:
	if ability != "":
		var c: Color = ABILITY_COLORS[ability]
		draw_arc(Vector2(0, -8), 44.0 * size_mult, 0, TAU, 28, Color(c.r, c.g, c.b, 0.6), 3.0, true)
	super()
