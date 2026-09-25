class_name LevelData
extends Resource
## Un nivel de la campaña. Balance en data/levels/level_XX.tres.

@export var number: int = 1
@export var zone: int = 1
@export var display_name: String = ""
@export_multiline var intro_text: String = ""
@export var active_lanes: PackedInt32Array = PackedInt32Array([0, 1, 2, 3, 4])
@export var start_sun: int = 50
@export var start_tokens: int = 0
@export var sky_sun_interval: float = 9.0
@export var sky_sun_amount: int = 25
@export var first_wave_delay: float = 20.0
@export var waves: Array[WaveData] = []
## plant, card, plant_slot, card_slot o vacío.
@export var unlock_type: String = ""
@export var unlock_id: String = ""
@export var skip_seed_select: bool = false
@export var is_boss: bool = false
## Pasos del tutorial: { "text": "...", "until": "select_plant|place_plant|place:ID|collect_sun|tokens:N|card_used|shovel|time:N" }
@export var tutorial_steps: Array = []
