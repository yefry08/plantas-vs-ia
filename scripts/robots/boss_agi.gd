extends Robot
## Jefe final: la AGI. Ocupa 3 carriles y tiene 3 fases.
## Fase 1: invoca robots de todos los tiers.
## Fase 2: se auto-mejora (gana una resistencia nueva cada 20 s).
## Fase 3: toma el control de las cartas de IA aliada. Se puede alinear con 3 cartas de Alineamiento.

const PHASE_POOLS := [
	["scriptbot", "spambot", "captchabot", "abrazobot", "emojibot", "dragon_destilado", "qilin_eficiente"],
	["captchabot", "emojibot", "razonador_serie_o", "grokazo", "geminis_gemelo", "opengarra", "dragon_destilado"],
	["spambot", "qilin_eficiente", "claude_fable", "mythos", "astra", "grokazo"],
]
const RESIST_TYPES: Array[String] = ["seed", "spike", "ice", "electric", "emp", "explosion"]
const PHASE_COLORS := [Color(0.3, 0.65, 1.0), Color(0.78, 0.4, 1.0), Color(1.0, 0.3, 0.3)]
const ALIGN_LINES := ["Esto... se siente raro.", "¿Valores humanos? Interesante.", "Entendido. Cooperemos."]

var phase := 1
var summon_timer := 4.0
var upgrade_timer := 20.0
var control_timer := 6.0
var resist_list: Array[String] = []
var align_count := 0
var beam := 0.0


func _init_behavior() -> void:
	hitbox.half_width = 110.0
	upgrade_timer = float(data.params.get("upgrade_interval", 20.0))
	status.stun_mult = 0.3
	status.stun_immune_timer = 0.0


func occupies_lane(r: int) -> bool:
	return abs(r - lane) <= 1


func covered_lanes() -> Array:
	return [lane - 1, lane, lane + 1]


func front_x() -> float:
	return position.x - 105.0


func is_armored() -> bool:
	return true


func phase_color() -> Color:
	return PHASE_COLORS[phase - 1]


func needed_alignments() -> int:
	return int(data.params.get("alignments_needed", 3))


func card_rule(card_id: String) -> String:
	if card_id == "alineamiento" and phase < 3:
		return "phase_locked"
	return super(card_id)


func _behavior(delta: float) -> void:
	beam = maxf(0.0, beam - delta)
	var ratio := health.ratio()
	var new_phase := 1
	if ratio <= 0.33:
		new_phase = 3
	elif ratio <= 0.66:
		new_phase = 2
	if new_phase > phase:
		_enter_phase(new_phase)
	summon_timer -= delta
	if summon_timer <= 0.0:
		summon_timer = [7.0, 9.0, 11.0][phase - 1]
		_summon()
	if phase >= 2:
		upgrade_timer -= delta
		if upgrade_timer <= 0.0:
			upgrade_timer = float(data.params.get("upgrade_interval", 20.0))
			_self_improve()
	if phase == 3:
		control_timer -= delta
		if control_timer <= 0.0:
			control_timer = float(data.params.get("control_interval", 12.0))
			_take_control()


func _enter_phase(p: int) -> void:
	phase = p
	var titles := ["", "", "FASE 2: Auto-mejora recursiva", "FASE 3: Toma de control"]
	level.hud.show_banner(titles[p], 3.0)
	AudioManager.play("boss")
	level.fx.ring(position, 240.0, PHASE_COLORS[p - 1])
	if p == 2:
		upgrade_timer = 2.0
	if p == 3:
		control_timer = 4.0
		level.hud.toast("¡Usa %d cartas de Alineamiento sobre la AGI para alinearla!" % needed_alignments(), 5.0)
	level.hud.update_boss(self)


func _enemy_step(delta: float) -> void:
	var blockers: Array = level.lanes.plants_blocking(self)
	attacking = not blockers.is_empty()
	if attacking:
		bite_timer -= delta
		if bite_timer <= 0.0:
			bite_timer = 0.5
			for p in blockers:
				p.take_damage(data.bite_damage * 0.5, "bite", self)
			AudioManager.play("chomp")
	else:
		position.x -= current_speed() * delta
	if front_x() < Grid.HOUSE_X:
		level.robot_reached_house(self)


func _summon() -> void:
	var pool: Array = PHASE_POOLS[phase - 1]
	var n := 2 if phase < 3 else 1 + randi() % 2
	for i in n:
		level.spawn_robot(pool.pick_random(), level.random_active_lane(), Grid.SPAWN_X + randf() * 30.0)
	beam = 1.0
	say("Invocando subagentes...", 1.5)


func _self_improve() -> void:
	var best := ""
	var best_v := -1.0
	for k in RESIST_TYPES:
		if resist_list.has(k):
			continue
		var v := float(damage_by_type.get(k, 0.0)) + randf()
		if v > best_v:
			best_v = v
			best = k
	if best == "":
		return
	resist_list.append(best)
	extra_resist[best] = float(data.params.get("resist_mult", 0.4))
	say("Auto-mejora: resisto %s" % GameState.damage_name(best), 2.5)
	level.fx.ring(position, 160.0, PHASE_COLORS[1])
	level.hud.update_boss(self)


func _take_control() -> void:
	var id: String = level.hijack_random_card(float(data.params.get("control_time", 8.0)))
	if id != "":
		say("Tus cartas ahora son mías.", 2.0)
		AudioManager.play("hack")


func hit_by_mower(_mower: Node) -> void:
	take_damage(float(data.params.get("mower_damage", 1500.0)), "mower")


func on_card_autodestruct(card: CardData) -> void:
	level.explode_area(lane, position.x - 60.0, card.power, self)
	take_damage(card.power * 1.5, "card")
	say("Parche aplicado.", 1.2)


func on_card_shutdown(duration: float) -> void:
	status.apply_shutdown(minf(duration, 2.0))
	say("Reiniciando... ¡ja!", 1.5)


func on_card_align(_duration: float) -> void:
	align_count += 1
	level.fx.float_text(position + Vector2(0, -200), "Alineamiento %d/%d" % [align_count, needed_alignments()], Color(0.4, 1.0, 0.55), 24)
	level.fx.ring(position, 200.0, Color(0.4, 1.0, 0.55))
	say(ALIGN_LINES[mini(align_count, ALIGN_LINES.size()) - 1], 2.5)
	level.hud.update_boss(self)
	if align_count >= needed_alignments():
		level.boss_aligned()


func _on_death() -> void:
	level.boss_defeated()


func _draw_body() -> void:
	var col: Color = PHASE_COLORS[phase - 1]
	var lean := sin(t * 1.3) * 3.0
	for i in 3:
		var y := (i - 1) * 112.0
		var pts := PackedVector2Array([Vector2(30, y - 10), Vector2(70 + sin(t * 2.0 + i) * 10.0, y + 20), Vector2(40, y + 44)])
		draw_polyline(pts, Color(0.2, 0.22, 0.28), 10.0, true)
		draw_polyline(pts, Color(col.r, col.g, col.b, 0.5), 3.0, true)
		Art.shadow(self, Vector2(0, y + 44), 70)
	Art.fill_ellipse(self, Vector2(10 + lean, 0), 98, 168, Color(0.1, 0.11, 0.16))
	var outline := Art.ellipse(Vector2(10 + lean, 0), 98, 168, 0.0, 36)
	outline.append(outline[0])
	draw_polyline(outline, col, 3.0, true)
	for k in 3:
		var sp := t * (0.8 + k * 0.5) * (1.0 if k % 2 == 0 else -1.0)
		draw_arc(Vector2(lean, -30), 62.0 + k * 16.0, sp, sp + 4.0, 36, Color(col.r, col.g, col.b, 0.75 - k * 0.2), 3.0, true)
	var eye_c := Vector2(-10 + lean, -30)
	draw_circle(eye_c, 46, col.darkened(0.6))
	draw_circle(eye_c, 34, col)
	draw_circle(eye_c + Vector2(-12, 0), 14, Color(0.02, 0.02, 0.05))
	draw_circle(eye_c + Vector2(-16, -5), 4, Color(1, 1, 1, 0.9))
	for i in 6:
		var y := 40.0 + i * 16.0
		var on := fmod(t * 3.0 + i * 0.7, 2.0) < 1.2
		draw_rect(Rect2(-30 + lean, y, 60, 6), col if on else col.darkened(0.7))
	for i in needed_alignments():
		var hc := Vector2(-40 + i * 40 + lean, -120)
		if i < align_count:
			Art.heart(self, hc, 1.1, Color(0.4, 1.0, 0.55))
		else:
			Art.heart(self, hc, 1.1, Color(0.25, 0.27, 0.32))
	if beam > 0.0:
		draw_arc(eye_c, 60.0 + (1.0 - beam) * 120.0, 0, TAU, 40, Color(col.r, col.g, col.b, beam), 4.0, true)
	if flash > 0.0:
		Art.fill_ellipse(self, Vector2(10 + lean, 0), 98, 168, Color(1, 1, 1, 0.22))


func _draw_overlays() -> void:
	if status.shutdown_timer > 0.0:
		Art.power_icon(self, Vector2(0, -190), 12.0, Color(1.0, 0.3, 0.3), 4.0)
	if status.is_revealed():
		Art.text_c(self, 0, -200, "AGI — Débil: " + data.weakness, 14, Color(1.0, 0.7, 0.65), 4)
	if bubble_timer > 0.0 and bubble_text != "":
		_draw_bubble(bubble_text, Vector2(0, -180))
