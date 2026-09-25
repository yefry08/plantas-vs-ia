extends Node
## Guarda el progreso en user:// (en web se persiste en IndexedDB).

const SAVE_PATH := "user://plantas_vs_ia_save.json"

## Se desactiva en modo autotest para no pisar la partida real.
var enabled := true


func save_data(data: Dictionary) -> bool:
	if not enabled:
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida (error %d)" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true


func load_data() -> Dictionary:
	if not enabled or not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed
	return {}


func wipe() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
