class_name Plant
extends Node2D
## Planta base. Los comportamientos concretos heredan de esta clase y se eligen
## según PlantData.behavior.

const BEHAVIOR_SCRIPTS := {
	"shooter": "res://scripts/plants/plant_shooter.gd",
	"producer": "res://scripts/plants/plant_producer.gd",
	"token": "res://scripts/plants/plant_producer.gd",
	"wall": "res://scripts/plants/plant.gd",
	"trap": "res://scripts/plants/plant_trap.gd",
	"emp": "res://scripts/plants/plant_emp.gd",
	"lightning": "res://scripts/plants/plant_lightning.gd",
	"mine": "res://scripts/plants/plant_mine.gd",
	"cleanser": "res://scripts/plants/plant_cleanser.gd",
}

var data: PlantData
var level: Node
var cell := Vector2i.ZERO
var row := 0
var health: HealthComponent
var status: StatusEffectComponent
var t := 0.0
var act_timer := 0.0
var flash := 0.0
var anim := 0.0
var removed := false


static func create(pd: PlantData) -> Plant:
	var path := String(BEHAVIOR_SCRIPTS.get(pd.behavior, "res://scripts/plants/plant.gd"))
	var script: GDScript = load(path)
	return script.new()


func setup(pd: PlantData, lvl: Node, c: Vector2i) -> void:
	data = pd
	level = lvl
	cell = c
	row = c.y
	position = Grid.cell_center(c.x, c.y)
	t = randf() * 10.0
	health = HealthComponent.new()
	health.name = "Health"
	add_child(health)
	health.setup(pd.health)
	health.died.connect(_on_died)
	status = StatusEffectComponent.new()
	status.name = "Status"
	add_child(status)
	_init_behavior()


func _process(delta: float) -> void:
	if removed:
		return
	t += delta
	flash = max(0.0, flash - delta)
	anim = max(0.0, anim - delta)
	if status.is_controlled():
		_controlled_behavior(delta)
	elif not status.is_disabled():
		_behavior(delta * (1.5 if status.haste_timer > 0.0 else 1.0))
	queue_redraw()


## Virtual: inicializa temporizadores del comportamiento.
func _init_behavior() -> void:
	pass


## Virtual: lógica por frame (no se llama mientras la planta está hackeada).
func _behavior(_delta: float) -> void:
	pass


## Virtual: qué hace la planta mientras una bioarma IA la controla.
func _controlled_behavior(_delta: float) -> void:
	pass


## Una bioarma IA toma el control de la planta durante `time` segundos.
func take_control(time: float) -> bool:
	if removed or not status.apply_control(time):
		return false
	level.fx.float_text(position + Vector2(0, -56), "¡CONTROLADA!", Color(0.8, 0.4, 1.0), 16)
	level.on_plant_controlled(self)
	return true


func cure(immunity := 8.0) -> void:
	var was := status.is_controlled() or status.hack_timer > 0.0
	status.cure_control(immunity)
	if was:
		level.fx.float_text(position + Vector2(0, -56), "¡Curada!", Color(0.5, 1.0, 0.6), 16)


## Virtual: parámetros extra para Art.plant().
func _draw_opts() -> Dictionary:
	return {}


func is_blocking() -> bool:
	return data.blocks_robots and not status.is_controlled()


## Valor ofensivo usado por el Razonador y Mythos para elegir objetivos.
func threat() -> float:
	var v := float(data.cost)
	if data.behavior in ["shooter", "lightning", "emp"]:
		v += 100.0
	return v


func take_damage(amount: float, _dtype := "bite", _source: Node = null) -> void:
	if removed:
		return
	flash = 0.08
	health.take_damage(amount)


func hack(time: float) -> void:
	status.apply_hack(time)


func remove() -> void:
	if removed:
		return
	removed = true
	GameState.plant_removed.emit(self)
	queue_free()


func _on_died() -> void:
	AudioManager.play("gulp")
	level.fx.burst(position, Color(0.35, 0.7, 0.25), 8)
	remove()


func _draw() -> void:
	var o := _draw_opts()
	o["flash"] = flash
	o["anim"] = anim
	o["hp"] = health.ratio()
	o["hacked"] = status.hack_timer > 0.0
	o["controlled"] = status.is_controlled()
	Art.plant(self, data.id, t, o)
	if status.hack_timer > 0.0:
		for i in 3:
			var y := -30.0 + fmod(t * 60.0 + i * 20.0, 60.0)
			draw_line(Vector2(-30, y), Vector2(30, y), Color(1.0, 0.2, 0.3, 0.55), 2.0)
		Art.lock_icon(self, Vector2(0, -50), 1.2, Color(1.0, 0.3, 0.3))
	if status.is_controlled():
		for i in 5:
			var a := t * 2.0 + TAU * float(i) / 5.0
			draw_circle(Vector2(cos(a) * 26.0, -10.0 + sin(a) * 14.0 - fmod(t * 20.0 + i * 7.0, 20.0)), 3.5, Color(0.75, 0.35, 1.0, 0.8))
		draw_arc(Vector2(0, -52), 9, t * 4.0, t * 4.0 + 4.5, 12, Color(0.8, 0.4, 1.0), 3.0, true)
		draw_circle(Vector2(0, -52), 3, Color(0.8, 0.4, 1.0))
	elif status.control_immune_timer > 0.0:
		draw_arc(Vector2(0, 0), 44, 0, TAU, 28, Color(0.5, 1.0, 0.6, 0.45), 2.0, true)
	if health.health < health.max_health and data.health >= 300.0:
		var w := 50.0
		draw_rect(Rect2(-w / 2.0, 42, w, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-w / 2.0, 42, w * health.ratio(), 5), Color(0.3, 0.9, 0.3).lerp(Color(1, 0.2, 0.2), 1.0 - health.ratio()))
