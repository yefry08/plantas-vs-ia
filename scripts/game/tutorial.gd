class_name Tutorial
extends Node
## Tutorial guiado por eventos. Los pasos vienen de LevelData.tutorial_steps.

var level: Node
var steps: Array = []
var index := -1
var timer := 0.0


func setup(lvl: Node, st: Array) -> void:
	level = lvl
	steps = st
	if steps.is_empty():
		return
	GameState.plant_placed.connect(_on_plant_placed)
	GameState.pickup_collected.connect(_on_pickup)
	GameState.card_used.connect(_on_card_used)
	GameState.tokens_changed.connect(_on_tokens)
	level.selection_changed.connect(_on_selection)
	_advance()


func _on_plant_placed(p: Node) -> void:
	_event("place", String(p.data.id))


func _on_pickup(kind: String) -> void:
	_event("collect", kind)


func _on_card_used(id: String) -> void:
	_event("card", id)


func _on_tokens(v: int) -> void:
	_event("tokens", str(v))


func _on_selection(kind: String, _id: String) -> void:
	_event("select", kind)


func active() -> bool:
	return index >= 0 and index < steps.size()


func _advance() -> void:
	index += 1
	timer = 0.0
	if index >= steps.size():
		level.hud.hide_tutorial()
		return
	level.hud.show_tutorial(String(steps[index].get("text", "")))
	var until := String(steps[index].get("until", ""))
	if until.begins_with("tokens:") and GameState.tokens >= int(until.get_slice(":", 1)):
		_advance()


func _process(delta: float) -> void:
	if not active():
		return
	var until := String(steps[index].get("until", ""))
	if until.begins_with("time:"):
		timer += delta
		if timer >= float(until.get_slice(":", 1)):
			_advance()


func _event(kind: String, arg: String) -> void:
	if not active():
		return
	var until := String(steps[index].get("until", ""))
	var done := false
	match kind:
		"select":
			done = (until == "select_plant" and arg == "plant") or (until == "shovel" and arg == "shovel")
		"place":
			done = until == "place_plant" or until == "place:" + arg
		"collect":
			done = until == "collect_sun" and arg == "sun"
		"card":
			done = until == "card_used"
		"tokens":
			done = until.begins_with("tokens:") and int(arg) >= int(until.get_slice(":", 1))
	if done:
		_advance()
