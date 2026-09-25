extends Node
## Estado global: catálogo de contenido, recursos de la partida y progreso.

signal sun_changed(value: int)
signal tokens_changed(value: int)
signal robot_died(robot: Node)
signal plant_placed(plant: Node)
signal plant_removed(plant: Node)
signal card_used(card_id: String)
signal pickup_collected(kind: String)

const PLANT_IDS: Array[String] = [
	"lanzasemillas", "girasolar", "nuez_firewall", "tokenizadora", "enredadera_captcha",
	"mina_bug", "cactus_antivirus", "brotecito_solar", "hongo_emp", "lanzasemillas_crio",
	"doble_commit", "bambu_pararrayos", "nuez_firewall_pro", "girasolar_doble",
]
const ROBOT_IDS: Array[String] = [
	"scriptbot", "spambot", "captchabot", "abrazobot", "emojibot",
	"dragon_destilado", "qilin_eficiente", "razonador_serie_o", "grokazo", "geminis_gemelo",
	"opengarra", "claude_fable", "mythos", "astra", "agi",
]
const CARD_IDS: Array[String] = ["autodestruccion", "boton_apagado", "apagado_cadena", "alineamiento", "red_team"]
const LEVEL_COUNT := 21
const MAX_PLANT_SLOTS := 6
const MAX_CARD_SLOTS := 2

const ZONE_NAMES := ["", "Jardín Local", "Repositorio Abierto", "Centro de Datos", "Laboratorio Frontera", "Núcleo de la AGI"]
const DAMAGE_NAMES := {
	"seed": "Semilla", "spike": "Espina", "ice": "Hielo", "electric": "Rayo", "emp": "EMP",
	"explosion": "Explosión", "ally": "Aliado", "card": "Carta", "mower": "Podadora", "bite": "Mordida",
}

const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_LEVEL_SELECT := "res://scenes/level_select.tscn"
const SCENE_SEED_SELECT := "res://scenes/seed_select.tscn"
const SCENE_LEVEL := "res://scenes/level.tscn"
const SCENE_CREDITS := "res://scenes/credits.tscn"

var plants: Dictionary = {}
var robots: Dictionary = {}
var cards: Dictionary = {}
var levels: Array[LevelData] = []

var sun := 0
var tokens := 0
var current_level := 1
var loadout_plants: Array[String] = []
var loadout_cards: Array[String] = []
var progress: Dictionary = {}
## "victory" o "aligned" tras vencer a la AGI; vacío para los créditos normales.
var pending_ending := ""
## Opciones de prueba automática (ver README): --autotest=N --time=S --speed=X --shot=ruta
var autotest: Dictionary = {}


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--check-scripts"):
		_check_scripts.call_deferred()
		return
	_parse_args()
	_load_catalog()
	if not autotest.is_empty():
		SaveManager.enabled = false
	progress = _default_progress()
	var saved := SaveManager.load_data()
	for k in saved.keys():
		progress[k] = saved[k]
	if not autotest.is_empty():
		_unlock_everything()
	AudioManager.set_volume(float(progress.get("volume", 0.7)))
	AudioManager.muted = bool(progress.get("muted", false))


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--") or not arg.contains("="):
			continue
		var kv := arg.substr(2).split("=", true, 1)
		autotest[kv[0]] = kv[1]
	if not autotest.has("autotest"):
		autotest.clear()


func _load_catalog() -> void:
	for id in PLANT_IDS:
		plants[id] = load("res://data/plants/%s.tres" % id)
	for id in ROBOT_IDS:
		robots[id] = load("res://data/robots/%s.tres" % id)
	for id in CARD_IDS:
		cards[id] = load("res://data/cards/%s.tres" % id)
	levels.clear()
	for n in range(1, LEVEL_COUNT + 1):
		levels.append(load("res://data/levels/level_%02d.tres" % n))


func _default_progress() -> Dictionary:
	return {
		"unlocked_level": 1,
		"completed": [],
		"plants": ["lanzasemillas"],
		"cards": ["autodestruccion"],
		"plant_slots": 4,
		"card_slots": 1,
		"endings": [],
		"seen_robots": [],
		"volume": 0.7,
		"muted": false,
	}


func _unlock_everything() -> void:
	progress["unlocked_level"] = LEVEL_COUNT
	progress["plants"] = PLANT_IDS.duplicate()
	progress["cards"] = CARD_IDS.duplicate()
	progress["plant_slots"] = MAX_PLANT_SLOTS
	progress["card_slots"] = MAX_CARD_SLOTS


func save() -> void:
	SaveManager.save_data(progress)


func reset_progress() -> void:
	SaveManager.wipe()
	var vol: float = float(progress.get("volume", 0.7))
	var muted: bool = bool(progress.get("muted", false))
	progress = _default_progress()
	progress["volume"] = vol
	progress["muted"] = muted
	save()


# --- Consultas de progreso -------------------------------------------------

func get_level(n: int) -> LevelData:
	return levels[clamp(n, 1, LEVEL_COUNT) - 1]


func is_level_unlocked(n: int) -> bool:
	return n <= int(progress.get("unlocked_level", 1))


func is_level_completed(n: int) -> bool:
	return _int_array(progress.get("completed", [])).has(n)


func unlocked_plants() -> Array[String]:
	var out: Array[String] = []
	var owned: Array = progress.get("plants", [])
	for id in PLANT_IDS:
		if owned.has(id):
			out.append(id)
	return out


func unlocked_cards() -> Array[String]:
	var out: Array[String] = []
	var owned: Array = progress.get("cards", [])
	for id in CARD_IDS:
		if owned.has(id):
			out.append(id)
	return out


func plant_slots() -> int:
	return int(progress.get("plant_slots", 4))


func card_slots() -> int:
	return int(progress.get("card_slots", 1))


func has_ending(e: String) -> bool:
	return (progress.get("endings", []) as Array).has(e)


## Devuelve true si es la primera vez que el jugador ve este robot.
func mark_robot_seen(id: String) -> bool:
	var seen: Array = progress.get("seen_robots", [])
	if seen.has(id):
		return false
	seen.append(id)
	progress["seen_robots"] = seen
	save()
	return true


## Marca el nivel como completado, aplica el desbloqueo y devuelve {type, id} del premio nuevo.
func complete_level(n: int, ending := "") -> Dictionary:
	var result := {}
	var completed := _int_array(progress.get("completed", []))
	var first_time := not completed.has(n)
	if first_time:
		completed.append(n)
		progress["completed"] = completed
	progress["unlocked_level"] = max(int(progress.get("unlocked_level", 1)), min(n + 1, LEVEL_COUNT))
	var ld := get_level(n)
	if first_time and ld.unlock_type != "":
		result = {"type": ld.unlock_type, "id": ld.unlock_id}
		match ld.unlock_type:
			"plant":
				_append_unique("plants", ld.unlock_id)
			"card":
				_append_unique("cards", ld.unlock_id)
			"plant_slot":
				progress["plant_slots"] = min(MAX_PLANT_SLOTS, plant_slots() + 1)
			"card_slot":
				progress["card_slots"] = min(MAX_CARD_SLOTS, card_slots() + 1)
	if ending != "":
		_append_unique("endings", ending)
	save()
	return result


func _append_unique(key: String, value: String) -> void:
	var arr: Array = progress.get(key, [])
	if not arr.has(value):
		arr.append(value)
	progress[key] = arr


func _int_array(a: Variant) -> Array[int]:
	var out: Array[int] = []
	if a is Array:
		for v in a:
			out.append(int(v))
	return out


# --- Flujo de escenas ------------------------------------------------------

func goto(path: String) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


## Entra al nivel: tutoriales van directo, el resto pasa por la selección de semillas.
func start_level(n: int) -> void:
	current_level = n
	var ld := get_level(n)
	if ld.skip_seed_select:
		auto_loadout()
		goto(SCENE_LEVEL)
	else:
		goto(SCENE_SEED_SELECT)


func auto_loadout() -> void:
	loadout_plants.clear()
	loadout_cards.clear()
	for id in unlocked_plants():
		if loadout_plants.size() < plant_slots():
			loadout_plants.append(id)
	for id in unlocked_cards():
		if loadout_cards.size() < card_slots():
			loadout_cards.append(id)


# --- Recursos de la partida ------------------------------------------------

func set_sun(v: int) -> void:
	sun = max(0, v)
	sun_changed.emit(sun)


func add_sun(v: int) -> void:
	set_sun(sun + v)


func spend_sun(v: int) -> bool:
	if sun < v:
		return false
	set_sun(sun - v)
	return true


func set_tokens(v: int) -> void:
	tokens = max(0, v)
	tokens_changed.emit(tokens)


func add_tokens(v: int) -> void:
	set_tokens(tokens + v)


func spend_tokens(v: int) -> bool:
	if tokens < v:
		return false
	set_tokens(tokens - v)
	return true


func damage_name(dtype: String) -> String:
	return String(DAMAGE_NAMES.get(dtype, dtype))


func unlock_label(unlock: Dictionary) -> String:
	match String(unlock.get("type", "")):
		"plant":
			return (plants[unlock["id"]] as PlantData).display_name
		"card":
			return "Carta: " + (cards[unlock["id"]] as CardData).display_name
		"plant_slot":
			return "+1 espacio de planta"
		"card_slot":
			return "+1 espacio de carta IA"
	return ""


# --- Verificación (godot --headless --path . -- --check-scripts) -------------

func _check_scripts() -> void:
	var bad := 0
	var files := _collect_scripts("res://scripts")
	for f in files:
		var s: GDScript = ResourceLoader.load(f)
		if s == null or not s.can_instantiate():
			print("FALLO: ", f)
			bad += 1
	for n in range(1, LEVEL_COUNT + 1):
		if load("res://data/levels/level_%02d.tres" % n) == null:
			bad += 1
	print("CHECK: scripts=%d errores=%d" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)


func _collect_scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_collect_scripts(dir + "/" + d))
	return out
