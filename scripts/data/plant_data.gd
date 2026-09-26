class_name PlantData
extends Resource
## Datos de una planta. Todo el balance vive en data/plants/*.tres.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 100
@export var cooldown: float = 7.5
@export var health: float = 300.0
## producer, token, shooter, wall, trap, emp, lightning, mine
@export var behavior: String = "shooter"
@export var blocks_robots: bool = true

@export_group("Ataque")
@export var damage: float = 20.0
## seed, spike, ice, electric, emp, explosion
@export var damage_type: String = "seed"
@export var fire_interval: float = 1.4
@export var shots_per_volley: int = 1
@export var pierce: int = 1
@export var projectile_speed: float = 480.0

@export_group("Producción")
@export var produce_amount: int = 25
## Cuántos soles / tokens lanza por ciclo.
@export var produce_count: int = 1
@export var produce_interval: float = 24.0
@export var first_produce_delay: float = 7.0

@export_group("Efectos")
@export var stun_time: float = 0.0
@export var slow_factor: float = 1.0
@export var slow_time: float = 0.0
@export var chain_count: int = 1
@export var chain_range: float = 260.0
@export var armored_bonus: float = 1.0
@export var arm_time: float = 0.0
@export var area_cells: int = 1
