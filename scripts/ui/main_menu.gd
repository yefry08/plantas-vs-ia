extends Control
## Menú principal.

var t := 0.0
var sound_btn: Button
var confirm_reset := false
var reset_btn: Button


func _ready() -> void:
	if not GameState.autotest.is_empty():
		_start_autotest.call_deferred()
		return
	var title := UI.label("Plantas vs IA", 76, Color(1.0, 0.92, 0.45), 14, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(title, Vector2(0, 40), Vector2(1280, 100))
	add_child(title)
	var sub := UI.label("Defiende tu jardín de los robots de inteligencia artificial", 22, Color(0.9, 1.0, 0.9), 6, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(sub, Vector2(0, 138), Vector2(1280, 30))
	add_child(sub)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	UI.place(box, Vector2(490, 230), Vector2(300, 330))
	add_child(box)
	var play := UI.button("Jugar", UI.GREEN, 28, Vector2(260, 64))
	play.pressed.connect(func(): GameState.goto(GameState.SCENE_LEVEL_SELECT))
	box.add_child(play)
	var credits := UI.button("Créditos", Color(0.35, 0.4, 0.6))
	credits.pressed.connect(func(): GameState.goto(GameState.SCENE_CREDITS))
	box.add_child(credits)
	sound_btn = UI.button("", Color(0.3, 0.45, 0.5))
	sound_btn.pressed.connect(_toggle_sound)
	box.add_child(sound_btn)
	reset_btn = UI.button("Borrar progreso", Color(0.55, 0.28, 0.22), 18, Vector2(220, 44))
	reset_btn.pressed.connect(_on_reset)
	box.add_child(reset_btn)
	_update_sound()

	var endings: Array[String] = []
	if GameState.has_ending("victory"):
		endings.append("Victoria sobre la AGI")
	if GameState.has_ending("aligned"):
		endings.append("AGI alineada")
	var done := (GameState.progress.get("completed", []) as Array).size()
	var info := "Niveles completados: %d/%d" % [done, GameState.LEVEL_COUNT]
	if not endings.is_empty():
		info += "   ·   Finales: " + ", ".join(endings)
	var status := UI.label(info, 16, Color(1, 1, 1, 0.85), 4, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(status, Vector2(0, 676), Vector2(1280, 24))
	add_child(status)


func _start_autotest() -> void:
	var n := clampi(int(GameState.autotest.get("autotest", "1")), 1, GameState.LEVEL_COUNT)
	GameState.current_level = n
	if String(GameState.autotest.get("mode", "")) == "fair":
		# Progreso realista: solo lo desbloqueado al jugar los niveles anteriores.
		GameState.progress = GameState._default_progress()
		for i in range(1, n):
			GameState.complete_level(i)
		GameState.auto_loadout()
		var pri := ["girasolar_doble", "girasolar", "bambu_pararrayos", "doble_commit", "lanzasemillas_crio", "cactus_antivirus", "lanzasemillas", "nuez_firewall_pro", "nuez_firewall", "hongo_emp"]
		var chosen: Array[String] = []
		for id in pri:
			if GameState.unlocked_plants().has(id) and chosen.size() < GameState.plant_slots():
				chosen.append(id)
		GameState.loadout_plants.assign(chosen)
		print("AUTOTEST loadout: ", chosen, " cartas: ", GameState.loadout_cards)
		GameState.goto(GameState.SCENE_LEVEL)
		return
	GameState.loadout_plants.assign(["girasolar", "lanzasemillas", "nuez_firewall", "cactus_antivirus", "bambu_pararrayos", "lanzasemillas_crio"])
	GameState.loadout_cards.assign(["autodestruccion", "alineamiento"])
	GameState.goto(GameState.SCENE_LEVEL)


func _toggle_sound() -> void:
	AudioManager.muted = not AudioManager.muted
	GameState.progress["muted"] = AudioManager.muted
	GameState.save()
	_update_sound()


func _update_sound() -> void:
	sound_btn.text = "Sonido: " + ("NO" if AudioManager.muted else "SÍ")


func _on_reset() -> void:
	if not confirm_reset:
		confirm_reset = true
		reset_btn.text = "¿Seguro? Clic otra vez"
		return
	GameState.reset_progress()
	GameState.goto(GameState.SCENE_MENU)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if GameState.robots.is_empty():
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.5, 0.75, 0.95))
	for i in 18:
		var y := i * 30.0
		draw_rect(Rect2(0, y, 1280, 30), Color(0.55, 0.8, 0.98).lerp(Color(0.88, 0.95, 1.0), i / 18.0))
	Art.sun_icon(self, Vector2(1140, 90), 40, t * 0.3)
	var hill := PackedVector2Array([Vector2(0, 520)])
	for i in 33:
		hill.append(Vector2(i * 40.0, 500.0 + sin(i * 0.4) * 18.0))
	hill.append(Vector2(1280, 720))
	hill.append(Vector2(0, 720))
	draw_colored_polygon(hill, Color(0.4, 0.7, 0.28))
	draw_rect(Rect2(0, 600, 1280, 120), Color(0.34, 0.6, 0.22))
	var plants := ["girasolar", "lanzasemillas", "nuez_firewall", "cactus_antivirus", "tokenizadora"]
	for i in plants.size():
		draw_set_transform(Vector2(90 + i * 85, 600 + (i % 2) * 30), 0.0, Vector2(1.1, 1.1))
		Art.plant(self, plants[i], t + i)
	var bots := ["scriptbot", "deepfish", "talkgpt", "claudio", "legend"]
	for i in bots.size():
		var rd: RobotData = GameState.robots[bots[i]]
		var x := 830.0 + i * 95.0 - fmod(t * 12.0, 30.0)
		draw_set_transform(Vector2(x, 600 + (i % 2) * 34), 0.0, Vector2(rd.size, rd.size))
		Art.robot(self, rd, t + i, {"walk": true, "shield": 1.0, "expr": "hug" if bots[i] == "abrazobot" else "happy"})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
