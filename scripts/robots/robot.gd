class_name Robot
extends Node2D
## Robot base. Las habilidades especiales heredan y sobreescriben los métodos
## virtuales (_behavior, _on_plant_hit, _on_death, _custom_damage_mult...).

signal died(robot: Robot)

const BEHAVIOR_SCRIPTS := {
	"basic": "res://scripts/robots/robot.gd",
	"forker": "res://scripts/robots/robot_forker.gd",
	"emoji": "res://scripts/robots/robot_emoji.gd",
	"dragon": "res://scripts/robots/robot_dragon.gd",
	"qilin": "res://scripts/robots/robot_qilin.gd",
	"reasoner": "res://scripts/robots/robot_reasoner.gd",
	"grok": "res://scripts/robots/robot_grok.gd",
	"gemini": "res://scripts/robots/robot_gemini.gd",
	"claw": "res://scripts/robots/robot_claw.gd",
	"fable": "res://scripts/robots/robot_fable.gd",
	"mythos": "res://scripts/robots/robot_mythos.gd",
	"astra": "res://scripts/robots/robot_astra.gd",
	"healer": "res://scripts/robots/robot_healer.gd",
	"crab": "res://scripts/robots/robot_crab.gd",
	"spore": "res://scripts/robots/robot_spore.gd",
	"cordy": "res://scripts/robots/robot_cordy.gd",
	"chimera": "res://scripts/robots/robot_chimera.gd",
	"agi": "res://scripts/robots/boss_agi.gd",
}

var data: RobotData
var level: Node
var lane := 2
var health: HealthComponent
var status: StatusEffectComponent
var hitbox: HitboxComponent
var shield := 0.0
var size_mult := 1.0
var is_illusion := false
var is_mini := false
var no_reward := false
var dead := false
var t := 0.0
var bite_timer := 0.0
var attacking := false
var speed_mult_extra := 1.0
var attack_mult := 1.0
var damage_by_type: Dictionary = {}
var last_plant_hit: Node = null
var extra_resist: Dictionary = {}
var bubble_text := ""
var bubble_timer := 0.0
var flash := 0.0
## Tiempo que el robot se queda quieto por decisión propia (pensar, burlarse...).
var holding := 0.0
var life_timer := -1.0
var lane_tween: Tween


static func create(rd: RobotData) -> Robot:
	var path := String(BEHAVIOR_SCRIPTS.get(rd.behavior, "res://scripts/robots/robot.gd"))
	var script: GDScript = load(path)
	return script.new()


func setup(rd: RobotData, lvl: Node, l: int, x: float) -> void:
	data = rd
	level = lvl
	lane = l
	position = Vector2(x, Grid.lane_y(l))
	size_mult = rd.size
	t = randf() * 5.0
	health = HealthComponent.new()
	health.name = "Health"
	add_child(health)
	health.setup(rd.health)
	health.died.connect(_on_health_died)
	status = StatusEffectComponent.new()
	status.name = "Status"
	add_child(status)
	status.stun_mult = float(rd.params.get("stun_mult", 1.0))
	status.aligned_changed.connect(_on_aligned_changed)
	hitbox = HitboxComponent.new()
	hitbox.name = "Hitbox"
	add_child(hitbox)
	hitbox.half_width = 26.0 * size_mult
	shield = rd.shield_health
	_init_behavior()


## Convierte al robot en una copia pequeña (fork del Abrazobot).
func make_mini(ratio: float) -> void:
	is_mini = true
	no_reward = true
	size_mult *= 0.62
	hitbox.half_width = 26.0 * size_mult
	health.setup(max(1.0, data.health * ratio))
	speed_mult_extra = 1.25


## Ilusión de Claude Fable: distrae a las plantas, no muerde, no da tokens.
func make_illusion(life: float) -> void:
	is_illusion = true
	no_reward = true
	shield = 0.0
	health.setup(80.0)
	life_timer = life
	modulate = Color(0.75, 0.85, 1.0, 0.55)


func _process(delta: float) -> void:
	if dead:
		return
	t += delta
	flash = max(0.0, flash - delta)
	if bubble_timer > 0.0:
		bubble_timer -= delta
	if life_timer > 0.0:
		life_timer -= delta
		if life_timer <= 0.0:
			vanish()
			return
	if not status.is_disabled():
		_behavior(delta)
		if dead:
			return
		if holding > 0.0:
			holding -= delta
			attacking = false
		elif is_aligned():
			_ally_step(delta)
		else:
			_enemy_step(delta)
	queue_redraw()


# --- Virtuales ---------------------------------------------------------------

func _init_behavior() -> void:
	pass


func _behavior(_delta: float) -> void:
	pass


func _on_plant_hit(_plant: Node) -> void:
	pass


func _on_death() -> void:
	pass


## Virtual: se llama tras cada mordisco a una planta o aliado.
func _on_bite(_target: Node) -> void:
	pass


func _custom_damage_mult(_dtype: String) -> float:
	return 1.0


## Expresión para los robots con cara emoji.
func _expr() -> String:
	return String(data.params.get("expr", "happy"))


func _draw_opts() -> Dictionary:
	return {}


# --- Movimiento y combate ---------------------------------------------------

func current_speed() -> float:
	return data.speed * status.speed_mult() * speed_mult_extra


func front_x() -> float:
	return position.x - 12.0 * size_mult


func occupies_lane(r: int) -> bool:
	return r == lane


func covered_lanes() -> Array:
	return [lane]


func is_aligned() -> bool:
	return status.is_aligned()


func is_armored() -> bool:
	return data.armored or shield > 0.0


func _enemy_step(delta: float) -> void:
	var blocker: Node = null
	if not is_illusion:
		blocker = level.lanes.find_blocker(self)
	attacking = blocker != null
	if blocker != null:
		bite_timer -= delta
		if bite_timer <= 0.0:
			bite_timer = 0.5 / attack_mult
			blocker.take_damage(data.bite_damage * 0.5, "bite", self)
			_on_bite(blocker)
			AudioManager.play("chomp")
	else:
		position.x -= current_speed() * delta
	if front_x() < Grid.HOUSE_X:
		if is_illusion:
			vanish()
		else:
			level.robot_reached_house(self)


func _ally_step(delta: float) -> void:
	var target: Node = level.lanes.find_enemy_for_ally(self)
	attacking = target != null
	if target != null:
		bite_timer -= delta
		if bite_timer <= 0.0:
			bite_timer = 0.5
			target.take_damage(max(60.0, data.bite_damage) * 0.75, "ally", self)
			AudioManager.play("chomp")
	else:
		position.x += current_speed() * 1.6 * delta
	if position.x > Grid.SPAWN_X + 60.0:
		no_reward = true
		vanish()


func change_lane(new_lane: int) -> void:
	if new_lane == lane or not level.is_lane_active(new_lane):
		return
	lane = new_lane
	if lane_tween:
		lane_tween.kill()
	lane_tween = create_tween()
	lane_tween.tween_property(self, "position:y", Grid.lane_y(new_lane), 0.45).set_trans(Tween.TRANS_SINE)


func resist_mult(dtype: String) -> float:
	if dtype == "mower":
		return 1.0
	var m := float(data.resistances.get(dtype, 1.0))
	m *= float(extra_resist.get(dtype, 1.0))
	return m * _custom_damage_mult(dtype)


func take_damage(amount: float, dtype: String, source: Node = null) -> void:
	if dead:
		return
	var m := resist_mult(dtype)
	if status.is_revealed():
		m *= 1.0 + status.reveal_bonus
	var final := amount * m
	if final <= 0.0:
		if randf() < 0.25:
			level.fx.float_text(position + Vector2(0, -60), "INMUNE", Color(0.8, 0.8, 1.0), 14)
		return
	damage_by_type[dtype] = float(damage_by_type.get(dtype, 0.0)) + final
	if source is Plant and is_instance_valid(source):
		last_plant_hit = source
		_on_plant_hit(source)
	flash = 0.07
	if shield > 0.0 and dtype != "mower":
		var absorbed: float = min(shield, final)
		shield -= absorbed
		final -= absorbed
		if shield <= 0.0:
			level.fx.burst(position + Vector2(-40, -10), Color(0.76, 0.6, 0.38), 8)
			say("¡Mi captcha!", 1.2)
	if final > 0.0:
		health.take_damage(final)


func hit_by_mower(_mower: Node) -> void:
	take_damage(99999.0, "mower")


func _on_health_died() -> void:
	die(true)


func die(give_reward := true) -> void:
	if dead:
		return
	dead = true
	if give_reward and not no_reward and not is_illusion and data.token_reward > 0 and randf() <= data.token_chance:
		level.spawn_pickup("token", data.token_reward, position + Vector2(0, -30), position + Vector2(randf_range(-20, 20), 20), true)
	_on_death()
	died.emit(self)
	GameState.robot_died.emit(self)
	level.fx.burst(position + Vector2(0, -10), data.body_color, 12)
	AudioManager.play("pop")
	queue_free()


## Desaparece sin premio (ilusiones, aliados que salen de la pantalla).
func vanish() -> void:
	if dead:
		return
	dead = true
	died.emit(self)
	level.fx.poof(position + Vector2(0, -10))
	queue_free()


func say(text: String, time := 1.6) -> void:
	bubble_text = text
	bubble_timer = time


func card_rule(card_id: String) -> String:
	return String(data.card_rules.get(card_id, ""))


# --- Efectos de cartas de IA aliada ------------------------------------------

func on_card_autodestruct(card: CardData) -> void:
	level.explode_area(lane, position.x, card.power, self)
	die(true)


func on_card_shutdown(duration: float) -> void:
	status.apply_shutdown(duration)
	say("Apagando...", 1.2)


func on_card_align(duration: float) -> void:
	status.apply_aligned(duration)


func on_card_reveal(duration: float, bonus: float) -> void:
	status.apply_reveal(duration, bonus)


func _on_aligned_changed(on: bool) -> void:
	if on:
		say("¡Ahora soy tu aliado!", 2.0)
		level.fx.float_text(position + Vector2(0, -70), "ALINEADO", Color(0.4, 1.0, 0.55))
	else:
		say("¿Dónde estaba?", 1.5)
	if lane_tween:
		lane_tween.kill()
	position.y = Grid.lane_y(lane)


# --- Dibujo -----------------------------------------------------------------

func _draw() -> void:
	var flip := -1.0 if is_aligned() else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size_mult * flip, size_mult))
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_overlays()


func _draw_body() -> void:
	var o := _draw_opts()
	o["flash"] = flash
	o["walk"] = not attacking and holding <= 0.0 and not status.is_disabled()
	o["shield"] = shield / max(1.0, data.shield_health)
	if not o.has("expr"):
		o["expr"] = _expr()
	Art.robot(self, data, t, o)


func _draw_overlays() -> void:
	var top := -70.0 * size_mult
	if is_aligned():
		draw_arc(Vector2(0, 0), 40.0 * size_mult, 0, TAU, 24, Color(0.35, 1.0, 0.5, 0.7), 3.0, true)
		Art.heart(self, Vector2(0, top - 6), 0.9, Color(0.35, 1.0, 0.5))
	if status.stun_timer > 0.0:
		for i in 3:
			var a := t * 5.0 + TAU * float(i) / 3.0
			draw_colored_polygon(Art.star_points(Vector2(cos(a) * 18.0, top + sin(a) * 5.0), 6, 2.5, 5), Color(1.0, 0.95, 0.3))
	if status.shutdown_timer > 0.0:
		Art.power_icon(self, Vector2(0, top - 4), 8.0, Color(1.0, 0.3, 0.3), 3.0)
		Art.text(self, Vector2(12, top - 10 - fmod(t * 10.0, 8.0)), "z", 16, Color(0.8, 0.9, 1.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	if status.is_slowed():
		draw_circle(Vector2(-10, -20 * size_mult), 4, Color(0.5, 0.8, 1.0, 0.8))
		draw_circle(Vector2(12, -8 * size_mult), 3, Color(0.5, 0.8, 1.0, 0.8))
	var hp_ratio := health.ratio()
	if (hp_ratio < 1.0 or status.is_revealed()) and not is_illusion:
		var w := 44.0 * maxf(size_mult, 0.8)
		draw_rect(Rect2(-w / 2.0, 46, w, 5), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(-w / 2.0, 46, w * hp_ratio, 5), Color(1.0, 0.3, 0.25))
		if shield > 0.0:
			draw_rect(Rect2(-w / 2.0, 52, w * shield / max(1.0, data.shield_health), 4), Color(0.85, 0.7, 0.4))
	if status.is_revealed():
		var label := data.display_name + ("  (ILUSIÓN)" if is_illusion else "")
		Art.text_c(self, 0, top - 20, label, 13, Color(1.0, 0.55, 0.5), 4)
		Art.text_c(self, 0, top - 6, "Débil: " + data.weakness, 11, Color(1.0, 0.9, 0.85), 3)
	if bubble_timer > 0.0 and bubble_text != "":
		_draw_bubble(bubble_text, Vector2(0, top - 34))


func _draw_bubble(s: String, at: Vector2) -> void:
	var f := Art.font()
	var tw: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var r := Rect2(at + Vector2(-tw / 2.0 - 8.0, -16.0), Vector2(tw + 16.0, 24.0))
	Art.rrect(self, r, 8, Color(1, 1, 1, 0.94), Color(0.2, 0.2, 0.25, 0.8), 1.5)
	Art.poly(self, [at + Vector2(-5, 7), at + Vector2(5, 7), at + Vector2(0, 14)], Color(1, 1, 1, 0.94))
	Art.text(self, Vector2(r.position.x + 8.0, at.y + 1.0), s, 13, Color(0.12, 0.12, 0.15))
