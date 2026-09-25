class_name CardData
extends Resource
## Carta de IA aliada que se paga con tokens. Balance en data/cards/*.tres.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 3
@export var cooldown: float = 15.0
@export var needs_target: bool = true
## autodestruct, shutdown, chain_shutdown, align, reveal
@export var effect: String = "autodestruct"
@export var duration: float = 10.0
@export var power: float = 300.0
@export var color: Color = Color(0.45, 0.35, 0.9)
