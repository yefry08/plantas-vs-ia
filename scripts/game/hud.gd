class_name HUD
extends CanvasLayer
## Interfaz del nivel: barra de semillas, contadores, cartas de IA aliada,
## progreso, mensajes, tutorial, pausa y pantallas de fin.

var level: Node
var root: Control
var plant_cards: Dictionary = {}
var ai_cards: Dictionary = {}
var shovel: SeedCard
var sun_box: CounterBox
var token_box: CounterBox
var progress: WaveProgress
var buddy: AllyBuddy
var boss_bar: BossBar
var banner: Label
var banner_sub: Label
var banner_timer := 0.0
var toast_label: Label
var toast_timer := 0.0
var tutorial_panel: PanelContainer
var tutorial_label: Label
var intro_panel: PanelContainer
var intro_portrait: RobotPortrait
var intro_title: Label
var intro_text: Label
var intro_timer := 0.0
var redteam_panel: PanelContainer
var redteam_label: Label
var redteam_timer := 0.0
var tutorial_timer := 0.0
var pause_overlay: Control
var end_overlay: Control
var speed_button: Button
var sound_button: Button


func setup(lvl: Node) -> void:
	level = lvl
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_bar()
	_build_panels()
	_build_messages()


func _build_top_bar() -> void:
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", UI.style(Color(0.26, 0.18, 0.1, 0.94), 0, Color(0.14, 0.09, 0.05), 3))
	UI.place(bar, Vector2(0, 0), Vector2(1280, 120))
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bar)

	sun_box = CounterBox.new()
	sun_box.kind = "sun"
	UI.place(sun_box, Vector2(8, 9), Vector2(90, 102))
	root.add_child(sun_box)

	var x := 106.0
	for id in GameState.loadout_plants:
		var card := SeedCard.new().setup("plant", id)
		card.position = Vector2(x, 10)
		card.pressed.connect(_on_plant_card)
		root.add_child(card)
		plant_cards[id] = card
		x += 82.0
	x = max(x, 106.0 + 82.0 * 2) + 6.0
	shovel = SeedCard.new().setup("shovel", "")
	shovel.position = Vector2(x, 10)
	shovel.size = Vector2(72, 100)
	shovel.pressed.connect(func(_c): level.select_shovel())
	root.add_child(shovel)
	x += 82.0

	token_box = CounterBox.new()
	token_box.kind = "token"
	UI.place(token_box, Vector2(x, 9), Vector2(90, 102))
	root.add_child(token_box)
	x += 98.0
	for id in GameState.loadout_cards:
		var card := SeedCard.new().setup("card", id)
		card.position = Vector2(x, 10)
		card.pressed.connect(_on_ai_card)
		root.add_child(card)
		ai_cards[id] = card
		x += 82.0

	var info := UI.label("Nivel %d · %s" % [level.data.number, level.data.display_name], 15, Color(1, 0.95, 0.8), 4)
	UI.place(info, Vector2(1000, 64), Vector2(272, 20))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.clip_text = true
	root.add_child(info)

	var pause_btn := UI.button("II", Color(0.35, 0.4, 0.5), 20, Vector2(62, 44))
	UI.place(pause_btn, Vector2(1128, 10), Vector2(62, 44))
	pause_btn.tooltip_text = "Pausa (Esc)"
	pause_btn.pressed.connect(func(): level.toggle_pause())
	root.add_child(pause_btn)
	speed_button = UI.button("x1", Color(0.3, 0.5, 0.35), 20, Vector2(72, 44))
	UI.place(speed_button, Vector2(1198, 10), Vector2(72, 44))
	speed_button.tooltip_text = "Velocidad x2"
	speed_button.pressed.connect(func(): level.toggle_speed())
	root.add_child(speed_button)

	progress = WaveProgress.new()
	progress.waves = level.waves
	UI.place(progress, Vector2(1040, 90), Vector2(230, 20))
	root.add_child(progress)

	buddy = AllyBuddy.new()
	UI.place(buddy, Vector2(0, 590), Vector2(150, 128))
	buddy.setup(level, level.ally)
	root.add_child(buddy)

	boss_bar = BossBar.new()
	UI.place(boss_bar, Vector2(370, 124), Vector2(540, 56))
	boss_bar.visible = false
	root.add_child(boss_bar)


func _build_messages() -> void:
	banner = UI.label("", 44, Color(1.0, 0.95, 0.7), 10, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(banner, Vector2(0, 300), Vector2(1280, 60))
	root.add_child(banner)
	banner_sub = UI.label("", 22, Color(0.85, 1.0, 0.85), 6, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(banner_sub, Vector2(0, 360), Vector2(1280, 30))
	root.add_child(banner_sub)
	toast_label = UI.label("", 20, Color.WHITE, 6, HORIZONTAL_ALIGNMENT_CENTER)
	UI.place(toast_label, Vector2(160, 662), Vector2(960, 30))
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(toast_label)


func _build_panels() -> void:
	tutorial_panel = UI.panel(Color(0.98, 0.95, 0.82, 0.96), 14, Color(0.5, 0.35, 0.15))
	UI.place(tutorial_panel, Vector2(220, 128), Vector2(660, 60))
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_label = UI.label("", 19, Color(0.2, 0.14, 0.05), 0, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.custom_minimum_size = Vector2(620, 0)
	tutorial_panel.add_child(tutorial_label)
	tutorial_panel.visible = false
	root.add_child(tutorial_panel)

	intro_panel = UI.panel(Color(0.08, 0.1, 0.14, 0.94), 14, Color(0.4, 0.7, 1.0, 0.8))
	UI.place(intro_panel, Vector2(900, 130), Vector2(370, 150))
	intro_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_panel.add_child(hb)
	intro_portrait = RobotPortrait.new()
	intro_portrait.custom_minimum_size = Vector2(100, 120)
	intro_portrait.scale_factor = 0.95
	hb.add_child(intro_portrait)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vb)
	var tag := UI.label("¡NUEVO ROBOT!", 13, Color(1.0, 0.6, 0.4), 3)
	vb.add_child(tag)
	intro_title = UI.label("", 20, Color.WHITE, 4)
	vb.add_child(intro_title)
	intro_text = UI.label("", 13, Color(0.85, 0.9, 1.0), 0)
	intro_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_text.custom_minimum_size = Vector2(230, 0)
	vb.add_child(intro_text)
	intro_panel.visible = false
	root.add_child(intro_panel)

	redteam_panel = UI.panel(Color(0.2, 0.05, 0.05, 0.9), 12, Color(1.0, 0.4, 0.35, 0.9))
	UI.place(redteam_panel, Vector2(220, 190), Vector2(420, 60))
	redteam_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	redteam_label = UI.label("", 14, Color(1.0, 0.92, 0.9), 0)
	redteam_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	redteam_label.custom_minimum_size = Vector2(390, 0)
	redteam_panel.add_child(redteam_label)
	redteam_panel.visible = false
	root.add_child(redteam_panel)


func _process(delta: float) -> void:
	if level == null:
		return
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	_refresh_cards()
	if banner_timer > 0.0:
		banner_timer -= real_delta
		var a := clampf(banner_timer * 2.0, 0.0, 1.0)
		banner.modulate.a = a
		banner_sub.modulate.a = a
	if toast_timer > 0.0:
		toast_timer -= real_delta
		toast_label.modulate.a = clampf(toast_timer * 2.0, 0.0, 1.0)
	if tutorial_timer > 0.0:
		tutorial_timer -= real_delta
		tutorial_panel.modulate.a = clampf(tutorial_timer * 1.5, 0.0, 1.0)
		if tutorial_timer <= 0.0:
			tutorial_panel.visible = false
	if intro_timer > 0.0 and not get_tree().paused:
		intro_timer -= real_delta
		if intro_timer <= 0.0:
			intro_panel.visible = false
	if redteam_timer > 0.0 and not get_tree().paused:
		redteam_timer -= delta
		if redteam_timer <= 0.0:
			redteam_panel.visible = false


func _refresh_cards() -> void:
	for id in plant_cards:
		var c: SeedCard = plant_cards[id]
		var pd: PlantData = GameState.plants[id]
		c.affordable = GameState.sun >= pd.cost
		c.cooldown_ratio = clampf(float(level.plant_cd.get(id, 0.0)) / pd.cooldown, 0.0, 1.0)
		c.selected = level.selected_kind == "plant" and level.selected_id == id
	for id in ai_cards:
		var c: SeedCard = ai_cards[id]
		var cd: CardData = GameState.cards[id]
		c.affordable = GameState.tokens >= cd.cost
		c.cooldown_ratio = clampf(float(level.card_cd.get(id, 0.0)) / cd.cooldown, 0.0, 1.0)
		c.locked = float(level.card_locked.get(id, 0.0))
		c.selected = level.selected_kind == "card" and level.selected_id == id
	shovel.selected = level.selected_kind == "shovel"


func _on_plant_card(card: SeedCard) -> void:
	level.select_plant(card.item_id)


func _on_ai_card(card: SeedCard) -> void:
	level.select_card(card.item_id)


func flash_sun_error() -> void:
	sun_box.flash_error()


func flash_token_error() -> void:
	token_box.flash_error()


# --- Mensajes ----------------------------------------------------------------

func show_banner(text: String, time := 2.5, sub := "") -> void:
	banner.text = text
	banner_sub.text = sub
	banner_timer = time
	banner.modulate.a = 1.0
	banner_sub.modulate.a = 1.0


func toast(text: String, time := 2.5) -> void:
	toast_label.text = text
	toast_timer = time
	toast_label.modulate.a = 1.0


func show_tutorial(text: String) -> void:
	tutorial_label.text = text
	tutorial_panel.visible = true
	tutorial_panel.reset_size()
	tutorial_panel.modulate.a = 1.0
	tutorial_timer = 9.0


func hide_tutorial() -> void:
	tutorial_panel.visible = false


func show_robot_intro(rd: RobotData) -> void:
	intro_portrait.robot_data = rd
	intro_title.text = rd.display_name
	intro_text.text = rd.abilities
	intro_panel.visible = true
	intro_panel.reset_size()
	intro_timer = 7.0


func show_redteam(robots: Array, duration: float) -> void:
	var seen := {}
	var lines: Array[String] = ["RED TEAM: defensas -25%"]
	for r in robots:
		if seen.has(r.data.id) or r.is_illusion:
			continue
		seen[r.data.id] = true
		lines.append("• %s — %s | Débil: %s" % [r.data.display_name, r.data.abilities.get_slice(".", 0), r.data.weakness])
		if lines.size() >= 7:
			break
	var ill := 0
	for r in robots:
		if r.is_illusion:
			ill += 1
	if ill > 0:
		lines.append("• %d ilusión(es) detectada(s)" % ill)
	redteam_label.text = "\n".join(lines)
	redteam_panel.visible = true
	redteam_panel.reset_size()
	redteam_timer = duration


func show_boss(boss: Node) -> void:
	boss_bar.boss = boss
	boss_bar.visible = true


func update_boss(_boss: Node) -> void:
	boss_bar.queue_redraw()


func hide_boss() -> void:
	boss_bar.visible = false


func update_speed(scale: float) -> void:
	speed_button.text = "x%d" % int(scale)


# --- Pausa y fin -------------------------------------------------------------

func show_pause(on: bool) -> void:
	if on and pause_overlay == null:
		pause_overlay = _overlay("Pausa", "Los robots esperan (educadamente).")
		var box: VBoxContainer = pause_overlay.get_node("Box")
		var b1 := UI.button("Continuar")
		b1.pressed.connect(func(): level.toggle_pause())
		box.add_child(b1)
		var b2 := UI.button("Reiniciar nivel", Color(0.55, 0.45, 0.2))
		b2.pressed.connect(func(): GameState.goto(GameState.SCENE_LEVEL))
		box.add_child(b2)
		sound_button = UI.button(_sound_text(), Color(0.3, 0.4, 0.55))
		sound_button.pressed.connect(_toggle_sound)
		box.add_child(sound_button)
		var mb := UI.button(_music_text(), Color(0.4, 0.35, 0.55))
		mb.pressed.connect(func():
			AudioManager.set_music_muted(not AudioManager.music_muted)
			GameState.progress["music_muted"] = AudioManager.music_muted
			GameState.save()
			mb.text = _music_text())
		box.add_child(mb)
		var b3 := UI.button("Salir al mapa", Color(0.55, 0.25, 0.2))
		b3.pressed.connect(func(): GameState.goto(GameState.SCENE_LEVEL_SELECT))
		box.add_child(b3)
	if pause_overlay:
		pause_overlay.visible = on


func _music_text() -> String:
	return "Música: " + ("NO" if AudioManager.music_muted else "SÍ")


func _sound_text() -> String:
	return "Sonido: " + ("NO" if AudioManager.muted else "SÍ")


func _toggle_sound() -> void:
	AudioManager.muted = not AudioManager.muted
	GameState.progress["muted"] = AudioManager.muted
	GameState.save()
	sound_button.text = _sound_text()


func show_win(unlock: Dictionary, ending := "") -> void:
	var title := "¡Nivel completado!"
	var sub := "Tu jardín sigue libre de robots."
	if ending == "victory":
		title = "¡La AGI ha sido derrotada!"
		sub = "El jardín está a salvo... por ahora."
	elif ending == "aligned":
		title = "¡AGI alineada!"
		sub = "La AGI decidió cuidar el jardín contigo."
	end_overlay = _overlay(title, sub)
	var box: VBoxContainer = end_overlay.get_node("Box")
	if unlock.has("bonus_ally"):
		var ad: AllyData = GameState.allies[unlock["bonus_ally"]]
		box.add_child(UI.label("¡Nuevo compañero de IA: %s!" % ad.display_name, 22, Color(0.6, 1.0, 0.8), 5, HORIZONTAL_ALIGNMENT_CENTER))
	if unlock.has("type"):
		var portrait := RobotPortrait.new()
		portrait.custom_minimum_size = Vector2(220, 110)
		portrait.scale_factor = 1.1
		match String(unlock["type"]):
			"plant":
				portrait.plant_id = String(unlock["id"])
			"card":
				portrait.card_id = String(unlock["id"])
		box.add_child(portrait)
		box.add_child(UI.label("Desbloqueado: " + GameState.unlock_label(unlock), 22, Color(1.0, 0.9, 0.4), 5, HORIZONTAL_ALIGNMENT_CENTER))
	if ending != "":
		var b := UI.button("Ver final", Color(0.5, 0.35, 0.7))
		b.pressed.connect(func(): GameState.goto(GameState.SCENE_CREDITS))
		box.add_child(b)
	else:
		var b := UI.button("Continuar")
		b.pressed.connect(func(): GameState.goto(GameState.SCENE_LEVEL_SELECT))
		box.add_child(b)
		if level.data.number < GameState.LEVEL_COUNT:
			var nb := UI.button("Siguiente nivel", Color(0.25, 0.45, 0.6))
			nb.pressed.connect(func(): GameState.start_level(level.data.number + 1))
			box.add_child(nb)


func show_lose() -> void:
	end_overlay = _overlay("Los robots tomaron tu jardín", "Prueba otra combinación de plantas y cartas.")
	var box: VBoxContainer = end_overlay.get_node("Box")
	var b1 := UI.button("Reintentar")
	b1.pressed.connect(func(): GameState.start_level(level.data.number))
	box.add_child(b1)
	var b2 := UI.button("Salir al mapa", Color(0.55, 0.25, 0.2))
	b2.pressed.connect(func(): GameState.goto(GameState.SCENE_LEVEL_SELECT))
	box.add_child(b2)


func _overlay(title: String, sub: String) -> Control:
	var o := ColorRect.new()
	o.color = Color(0, 0, 0, 0.62)
	UI.place(o, Vector2.ZERO, Vector2(1280, 720))
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(o)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	UI.place(box, Vector2(340, 90), Vector2(600, 560))
	o.add_child(box)
	box.add_child(UI.label(title, 40, Color(1.0, 0.95, 0.7), 10, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UI.label(sub, 20, Color(0.9, 0.95, 0.9), 5, HORIZONTAL_ALIGNMENT_CENTER))
	return o


func _unhandled_input(event: InputEvent) -> void:
	# El nivel está pausado y no recibe teclas: la HUD permite salir de la pausa.
	if get_tree().paused and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			level.toggle_pause()
			get_viewport().set_input_as_handled()
