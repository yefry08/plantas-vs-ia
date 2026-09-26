class_name AllyData
extends Resource
## Compañero de IA aliada que elige el jugador. Balance en data/allies/*.tres.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var passive_text: String = ""
@export var active_name: String = ""
@export_multiline var active_text: String = ""
@export var active_cooldown: float = 60.0
## Valores de las habilidades (duraciones, cantidades...).
@export var params: Dictionary = {}
@export var color: Color = Color(0.4, 1.0, 0.7)
## Frases: greeting, danger, idle_sun, tokens, controlled, drone, power_ready, huge, win, lose, tip
@export var lines: Dictionary = {}
