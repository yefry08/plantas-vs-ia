extends Control
## Mapa de la campaña: 4 zonas x 5 niveles + el nivel final de la AGI.

const ZONE_COLORS := [Color(0.3, 0.6, 0.25), Color(0.25, 0.5, 0.45), Color(0.3, 0.38, 0.6), Color(0.5, 0.38, 0.7), Color(0.35, 0.55, 0.2)]
const ZONE_LEVELS := [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21, 22, 23]]


func _ready() -> void:
	var title := UI.label("Campaña", 46, Color(1.0, 0.92, 0.5), 10, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(title, Vector2(0, 16), Vector2(1280, 60))
	add_child(title)
	for z in ZONE_LEVELS.size():
		_build_zone(z)
	var boss_n := GameState.LEVEL_COUNT
	var boss_ld := GameState.get_level(boss_n)
	var unlocked := GameState.is_level_unlocked(boss_n)
	var boss_btn := UI.button("%d · %s" % [boss_n, boss_ld.display_name] if unlocked else "%d · ???  (bloqueado)" % boss_n,
		Color(0.7, 0.18, 0.2), 26, Vector2(520, 64))
	UI.place(boss_btn, Vector2(380, 606), Vector2(520, 64))
	boss_btn.disabled = not unlocked
	boss_btn.pressed.connect(func(): GameState.start_level(boss_n))
	if GameState.is_level_completed(boss_n):
		boss_btn.text += "  (superado)"
	add_child(boss_btn)
	var back := UI.button("Menú", Color(0.4, 0.4, 0.45), 20, Vector2(140, 48))
	UI.place(back, Vector2(24, 616), Vector2(140, 48))
	back.pressed.connect(func(): GameState.goto(GameState.SCENE_MENU))
	add_child(back)
	var hint := UI.label("Cada nivel desbloquea una planta, una carta o un espacio nuevo.", 15, Color(1, 1, 1, 0.8), 4, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(hint, Vector2(0, 684), Vector2(1280, 24))
	add_child(hint)


func _build_zone(z: int) -> void:
	var x := 16.0 + z * 251.0
	var p := UI.panel(Color(ZONE_COLORS[z].r, ZONE_COLORS[z].g, ZONE_COLORS[z].b, 0.85), 16, Color(1, 1, 1, 0.35))
	UI.place(p, Vector2(x, 90), Vector2(242, 496))
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	vb.add_child(UI.label("Zona %d" % (z + 1), 16, Color(1, 1, 1, 0.75), 3, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.label(GameState.ZONE_NAMES[z + 1], 20, Color.WHITE, 5, HORIZONTAL_ALIGNMENT_CENTER))
	for n in ZONE_LEVELS[z]:
		var ld := GameState.get_level(n)
		var unlocked := GameState.is_level_unlocked(n)
		var done := GameState.is_level_completed(n)
		var col := Color(0.2, 0.55, 0.3) if done else (Color(0.25, 0.45, 0.65) if unlocked else Color(0.3, 0.3, 0.32))
		var txt := "%d. %s" % [n, ld.display_name] if unlocked else "%d. (bloqueado)" % n
		var b := UI.button(txt, col, 15, Vector2(212, 48))
		b.disabled = not unlocked
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		if ld.unlock_type != "":
			b.tooltip_text = ("Premio: " if not done else "Conseguido: ") + GameState.unlock_label({"type": ld.unlock_type, "id": ld.unlock_id})
		b.pressed.connect(func(): GameState.start_level(n))
		vb.add_child(b)
		var reward := UI.label(("Conseguido: " if done else "Premio: ") + GameState.unlock_label({"type": ld.unlock_type, "id": ld.unlock_id}) if unlocked else "", 12, Color(1, 1, 0.8, 0.85), 3)
		reward.custom_minimum_size = Vector2(212, 14)
		reward.clip_text = true
		vb.add_child(reward)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.16, 0.2, 0.17))
	for i in 20:
		draw_line(Vector2(i * 70.0, 0), Vector2(i * 70.0 - 200.0, 720), Color(1, 1, 1, 0.03), 18.0)
