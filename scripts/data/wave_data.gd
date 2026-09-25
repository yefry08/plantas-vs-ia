class_name WaveData
extends Resource
## Una oleada. `groups` es una lista de diccionarios:
## { "robot": "scriptbot", "count": 2, "interval": 2.0, "lane": -1, "delay": 0.0 }
## lane = -1 elige un carril activo al azar.

## Segundos hasta que la siguiente oleada empieza sola (si no se limpió antes).
@export var duration: float = 25.0
@export var is_huge: bool = false
@export var groups: Array = []
