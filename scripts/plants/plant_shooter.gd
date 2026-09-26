extends Plant
## Lanzasemillas, Cactus Antivirus, Lanzasemillas Crio y Doble Commit.


func _init_behavior() -> void:
	act_timer = 0.5


func _behavior(delta: float) -> void:
	act_timer -= delta
	if act_timer > 0.0:
		return
	if level.lanes.has_enemy_ahead(row, position.x):
		_fire()
		act_timer = data.fire_interval
	else:
		act_timer = 0.15


func _fire() -> void:
	anim = 0.2
	for i in data.shots_per_volley:
		level.spawn_projectile(self, position + Vector2(38.0 - i * 26.0, -17.0), row)
	AudioManager.play("shoot")


## Controlada por una bioarma: dispara hacia atrás, contra tus propias plantas.
func _controlled_behavior(delta: float) -> void:
	act_timer -= delta
	if act_timer > 0.0:
		return
	act_timer = data.fire_interval * 1.3
	if level.lanes.has_plant_ahead(row, position.x - 30.0):
		anim = 0.2
		level.spawn_enemy_projectile(self, position + Vector2(-30, -17), row, data.damage)
