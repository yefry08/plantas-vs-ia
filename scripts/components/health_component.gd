class_name HealthComponent
extends Node
## Vida reutilizable para plantas y robots.

signal damaged(amount: float)
signal died

var max_health := 100.0
var health := 100.0
var is_dead := false


func setup(max_hp: float) -> void:
	max_health = max(1.0, max_hp)
	health = max_health
	is_dead = false


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health -= amount
	damaged.emit(amount)
	if health <= 0.0:
		health = 0.0
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if not is_dead:
		health = min(max_health, health + amount)


func set_health(value: float) -> void:
	health = clamp(value, 1.0, max_health)


func ratio() -> float:
	return health / max_health
