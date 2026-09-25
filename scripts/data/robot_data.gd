class_name RobotData
extends Resource
## Datos de un robot enemigo. Todo el balance vive en data/robots/*.tres.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_multiline var abilities: String = ""
@export_multiline var weakness: String = ""
@export var tier: int = 1
## basic, forker, emoji, dragon, qilin, reasoner, grok, gemini, claw, fable, mythos, astra, agi
@export var behavior: String = "basic"

@export_group("Stats")
@export var health: float = 200.0
@export var shield_health: float = 0.0
## Píxeles por segundo.
@export var speed: float = 14.0
## Daño por segundo al morder plantas.
@export var bite_damage: float = 100.0
@export var token_reward: int = 1
## Probabilidad (0-1) de soltar tokens al morir.
@export var token_chance: float = 1.0
@export var armored: bool = false
@export var size: float = 1.0
## tipo_de_daño -> multiplicador (0 = inmune, 0.5 = resiste, 1.5 = débil)
@export var resistances: Dictionary = {}
## id_de_carta -> "immune" | "double_cost"
@export var card_rules: Dictionary = {}
## Parámetros específicos de la habilidad (intervalos, duraciones, forma...).
@export var params: Dictionary = {}

@export_group("Aspecto")
@export var body_color: Color = Color(0.6, 0.64, 0.7)
@export var accent_color: Color = Color(0.48, 0.52, 0.58)
@export var eye_color: Color = Color(0.3, 0.9, 1.0)
