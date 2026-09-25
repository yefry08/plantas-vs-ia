extends Control
## Selección de semillas: hasta N plantas + M cartas de IA aliada antes del nivel.

var ld: LevelData
var chosen_plants: Array[String] = []
var chosen_cards: Array[String] = []
var plant_bar: HBoxContainer
var card_bar: HBoxContainer
var plant_grid: GridContainer
var card_grid: GridContainer
var start_btn: Button
var plant_title: Label
var card_title: Label


func _ready() -> void:
	ld = GameState.get_level(GameState.current_level)
	var title := UI.label("Nivel %d: %s" % [ld.number, ld.display_name], 34, Color(1.0, 0.92, 0.5), 8)
	UI.place(title, Vector2(30, 14), Vector2(900, 44))
	add_child(title)
	var zone := UI.label(GameState.ZONE_NAMES[ld.zone] + ("" if ld.intro_text == "" else "  —  " + ld.intro_text), 16, Color(0.9, 1.0, 0.9), 4)
	UI.place(zone, Vector2(32, 58), Vector2(1220, 24))
	zone.clip_text = true
	add_child(zone)
	_build_robot_list()
	_build_picker()
	_preselect()
	_refresh()


func _level_robot_ids() -> Array[String]:
	var ids: Array[String] = []
	for w in ld.waves:
		for g in w.groups:
			var id := String(g.get("robot", ""))
			if id != "" and not ids.has(id):
				ids.append(id)
	if ld.is_boss:
		for id in GameState.ROBOT_IDS:
			if not ids.has(id):
				ids.append(id)
	return ids


func _build_robot_list() -> void:
	var p := UI.panel(Color(0.08, 0.1, 0.14, 0.9))
	UI.place(p, Vector2(30, 92), Vector2(440, 540))
	add_child(p)
	var vb := VBoxContainer.new()
	p.add_child(vb)
	vb.add_child(UI.label("Robots en este nivel", 20, Color(1.0, 0.7, 0.55), 4))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(410, 480)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for id in _level_robot_ids():
		var rd: RobotData = GameState.robots[id]
		var row := HBoxContainer.new()
		var portrait := RobotPortrait.new()
		portrait.robot_data = rd
		portrait.scale_factor = 0.7
		portrait.custom_minimum_size = Vector2(80, 86)
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.add_child(UI.label(rd.display_name, 17, Color.WHITE, 3))
		var ab := UI.label(rd.abilities, 12, Color(0.85, 0.9, 1.0), 0)
		ab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ab.custom_minimum_size = Vector2(300, 0)
		info.add_child(ab)
		var wk := UI.label("Débil a: " + rd.weakness, 12, Color(0.7, 1.0, 0.7), 0)
		wk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wk.custom_minimum_size = Vector2(300, 0)
		info.add_child(wk)
		row.add_child(info)
		list.add_child(row)


func _build_picker() -> void:
	var p := UI.panel(Color(0.3, 0.22, 0.12, 0.92), 14, Color(0.9, 0.75, 0.4, 0.6))
	UI.place(p, Vector2(490, 92), Vector2(760, 540))
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	plant_title = UI.label("", 19, Color(1.0, 0.95, 0.8), 4)
	vb.add_child(plant_title)
	plant_bar = HBoxContainer.new()
	plant_bar.custom_minimum_size = Vector2(0, 104)
	vb.add_child(plant_bar)
	plant_grid = GridContainer.new()
	plant_grid.columns = 8
	vb.add_child(plant_grid)
	for id in GameState.unlocked_plants():
		var c := SeedCard.new().setup("plant", id)
		c.pressed.connect(_toggle_plant)
		plant_grid.add_child(c)
	card_title = UI.label("", 19, Color(0.85, 0.8, 1.0), 4)
	vb.add_child(card_title)
	card_bar = HBoxContainer.new()
	card_bar.custom_minimum_size = Vector2(0, 104)
	vb.add_child(card_bar)
	card_grid = GridContainer.new()
	card_grid.columns = 8
	vb.add_child(card_grid)
	for id in GameState.unlocked_cards():
		var c := SeedCard.new().setup("card", id)
		c.pressed.connect(_toggle_card)
		card_grid.add_child(c)

	start_btn = UI.button("¡A defender!", UI.GREEN, 26, Vector2(260, 58))
	UI.place(start_btn, Vector2(990, 646), Vector2(260, 58))
	start_btn.pressed.connect(_start)
	add_child(start_btn)
	var back := UI.button("Volver", Color(0.4, 0.4, 0.45), 20, Vector2(150, 50))
	UI.place(back, Vector2(30, 652), Vector2(150, 50))
	back.pressed.connect(func(): GameState.goto(GameState.SCENE_LEVEL_SELECT))
	add_child(back)
	var hint := UI.label("Toca una carta para añadirla o quitarla.", 15, Color(1, 1, 1, 0.8), 4)
	UI.place(hint, Vector2(200, 664), Vector2(700, 24))
	add_child(hint)


func _preselect() -> void:
	var unlocked := GameState.unlocked_plants()
	for id in GameState.loadout_plants:
		if unlocked.has(id) and chosen_plants.size() < GameState.plant_slots():
			chosen_plants.append(id)
	if chosen_plants.is_empty():
		for id in unlocked:
			if chosen_plants.size() < GameState.plant_slots():
				chosen_plants.append(id)
	var ucards := GameState.unlocked_cards()
	for id in GameState.loadout_cards:
		if ucards.has(id) and chosen_cards.size() < GameState.card_slots():
			chosen_cards.append(id)
	if chosen_cards.is_empty():
		for id in ucards:
			if chosen_cards.size() < GameState.card_slots():
				chosen_cards.append(id)


func _toggle_plant(card: SeedCard) -> void:
	var id := card.item_id
	if chosen_plants.has(id):
		chosen_plants.erase(id)
	elif chosen_plants.size() < GameState.plant_slots():
		chosen_plants.append(id)
	else:
		AudioManager.play("error")
		return
	AudioManager.play("click")
	_refresh()


func _toggle_card(card: SeedCard) -> void:
	var id := card.item_id
	if chosen_cards.has(id):
		chosen_cards.erase(id)
	elif chosen_cards.size() < GameState.card_slots():
		chosen_cards.append(id)
	else:
		AudioManager.play("error")
		return
	AudioManager.play("click")
	_refresh()


func _refresh() -> void:
	plant_title.text = "Plantas (%d/%d)" % [chosen_plants.size(), GameState.plant_slots()]
	card_title.text = "Cartas de IA aliada (%d/%d) — se pagan con tokens" % [chosen_cards.size(), GameState.card_slots()]
	_fill_bar(plant_bar, "plant", chosen_plants, GameState.plant_slots(), _toggle_plant)
	_fill_bar(card_bar, "card", chosen_cards, GameState.card_slots(), _toggle_card)
	for c in plant_grid.get_children():
		c.dimmed = chosen_plants.has(c.item_id)
	for c in card_grid.get_children():
		c.dimmed = chosen_cards.has(c.item_id)
	start_btn.disabled = chosen_plants.is_empty()


func _fill_bar(bar: HBoxContainer, kind: String, chosen: Array[String], slots: int, cb: Callable) -> void:
	for c in bar.get_children():
		c.queue_free()
	for i in slots:
		if i < chosen.size():
			var c := SeedCard.new().setup(kind, chosen[i])
			c.selected = true
			c.pressed.connect(cb)
			bar.add_child(c)
		else:
			var empty := Panel.new()
			empty.custom_minimum_size = Vector2(78, 100)
			empty.add_theme_stylebox_override("panel", UI.style(Color(0, 0, 0, 0.25), 9, Color(1, 1, 1, 0.25), 2))
			bar.add_child(empty)


func _start() -> void:
	GameState.loadout_plants.assign(chosen_plants)
	GameState.loadout_cards.assign(chosen_cards)
	GameState.goto(GameState.SCENE_LEVEL)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.18, 0.24, 0.16))
	for i in 12:
		draw_rect(Rect2(0, i * 60.0, 1280, 30), Color(1, 1, 1, 0.02))
