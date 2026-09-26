class_name Level
extends Node2D
## Escena de juego: construye el tablero, gestiona entrada, recursos,
## cartas de IA aliada, drones de emergencia, victoria/derrota y el modo autotest.

signal selection_changed(kind: String, id: String)

var data: LevelData
var active_lanes: PackedInt32Array
var lanes: LaneManager
var waves: WaveManager
var hud: HUD
var fx: FxLayer
var board: Board
var tutorial: Tutorial
var preview: PlacementPreview
var plants_layer: Node2D
var mowers_layer: Node2D
var robots_layer: Node2D
var projectiles_layer: Node2D
var pickups_layer: Node2D
var mowers: Dictionary = {}
var fields: Array = []
var selected_kind := ""
var selected_id := ""
var plant_cd: Dictionary = {}
var card_cd: Dictionary = {}
var card_locked: Dictionary = {}
var sky_timer := 5.0
var state := "playing"
var elapsed := 0.0
var boss: Node = null
var ally: AllyData
var ally_cd := 0.0
var ally_line_cd := 0.0
var ally_passive_timer := 0.0
var ally_check_timer := 1.0
var idle_sun_time := 0.0
var said_power_ready := false
var said_tokens_at := -100.0

var auto := false
var auto_timer := 0.0
var auto_end := 90.0
var auto_stats: Dictionary = {}
var shot_path := ""
var shot_time := -1.0


func _ready() -> void:
	data = GameState.get_level(GameState.current_level)
	active_lanes = data.active_lanes
	Engine.time_scale = 1.0
	_build()
	GameState.set_sun(data.start_sun)
	GameState.set_tokens(data.start_tokens)
	for id in GameState.loadout_plants:
		plant_cd[id] = 0.0
	for id in GameState.loadout_cards:
		card_cd[id] = 0.0
	ally = GameState.selected_ally()
	ally_cd = ally.active_cooldown * 0.5
	ally_passive_timer = float(ally.params.get("passive_interval", 25.0))
	waves.setup(self, data)
	waves.wave_started.connect(_on_wave_started)
	hud.setup(self)
	tutorial.setup(self, data.tutorial_steps)
	hud.show_banner("Nivel %d: %s" % [data.number, data.display_name], 3.0, GameState.ZONE_NAMES[data.zone])
	if data.intro_text != "" and data.tutorial_steps.is_empty():
		hud.toast(data.intro_text, 5.0)
	ally_say("greeting", true)
	_setup_autotest()


func _build() -> void:
	board = Board.new()
	board.zone = data.zone
	board.active = active_lanes
	add_child(board)
	preview = PlacementPreview.new()
	preview.level = self
	add_child(preview)
	plants_layer = Node2D.new()
	plants_layer.name = "Plants"
	add_child(plants_layer)
	mowers_layer = Node2D.new()
	mowers_layer.name = "Mowers"
	add_child(mowers_layer)
	for r in active_lanes:
		var m := Mower.new()
		m.setup(self, r)
		mowers_layer.add_child(m)
		mowers[r] = m
	robots_layer = Node2D.new()
	robots_layer.name = "Robots"
	robots_layer.y_sort_enabled = true
	add_child(robots_layer)
	projectiles_layer = Node2D.new()
	projectiles_layer.name = "Projectiles"
	add_child(projectiles_layer)
	fx = FxLayer.new()
	fx.level = self
	add_child(fx)
	pickups_layer = Node2D.new()
	pickups_layer.name = "Pickups"
	add_child(pickups_layer)
	lanes = LaneManager.new()
	lanes.name = "LaneManager"
	add_child(lanes)
	waves = WaveManager.new()
	waves.name = "WaveManager"
	add_child(waves)
	tutorial = Tutorial.new()
	tutorial.name = "Tutorial"
	add_child(tutorial)
	hud = HUD.new()
	hud.name = "HUD"
	add_child(hud)


# --- Bucle ---------------------------------------------------------------------

func _process(delta: float) -> void:
	if auto:
		_autoplay(delta)
	if state != "playing":
		return
	elapsed += delta
	for id in plant_cd.keys():
		plant_cd[id] = maxf(0.0, float(plant_cd[id]) - delta)
	for id in card_cd.keys():
		card_cd[id] = maxf(0.0, float(card_cd[id]) - delta)
	for id in card_locked.keys():
		card_locked[id] = maxf(0.0, float(card_locked[id]) - delta)
	for f in fields:
		f["time"] = float(f["time"]) - delta
	fields = fields.filter(func(f): return float(f["time"]) > 0.0)
	if data.sky_sun_interval > 0.0:
		sky_timer -= delta
		if sky_timer <= 0.0:
			sky_timer = data.sky_sun_interval * randf_range(0.85, 1.15) * float(ally.params.get("sky_mult", 1.0))
			var x := randf_range(Grid.ORIGIN.x + 40.0, Grid.RIGHT_EDGE - 40.0)
			var row: int = active_lanes[randi() % active_lanes.size()]
			spawn_pickup("sun", data.sky_sun_amount, Vector2(x, 110), Vector2(x, Grid.lane_y(row) + 26.0))
	_ally_process(delta)
	if not data.is_boss and waves.finished and lanes.real_enemy_count() == 0:
		_win()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event as InputEventKey)
		return
	if state != "playing" or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed:
		var p := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			clear_selection()
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if _try_collect(p):
			get_viewport().set_input_as_handled()
			return
		match selected_kind:
			"plant":
				_try_place(p)
			"shovel":
				_try_shovel(p)
			"card":
				_try_card_target(p)
			_:
				var cell := Grid.cell_at(p)
				if cell.x >= 0 and lanes.plant_at(cell) != null:
					var pd: PlantData = lanes.plant_at(cell).data
					hud.toast("%s: %s" % [pd.display_name, pd.description], 2.5)


func _handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		if selected_kind != "" and not get_tree().paused:
			clear_selection()
		elif state == "playing":
			toggle_pause()
		return
	if state != "playing" or get_tree().paused:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		var i := int(event.keycode - KEY_1)
		if i < GameState.loadout_plants.size():
			select_plant(GameState.loadout_plants[i])
	elif event.keycode == KEY_Q or event.keycode == KEY_W:
		var i := 0 if event.keycode == KEY_Q else 1
		if i < GameState.loadout_cards.size():
			select_card(GameState.loadout_cards[i])
	elif event.keycode == KEY_S:
		select_shovel()
	elif event.keycode == KEY_F:
		toggle_speed()


# --- Selección -----------------------------------------------------------------

func _set_selection(kind: String, id: String) -> void:
	selected_kind = kind
	selected_id = id
	selection_changed.emit(kind, id)


func clear_selection() -> void:
	if selected_kind != "":
		_set_selection("", "")


func select_plant(id: String) -> void:
	if state != "playing":
		return
	if selected_kind == "plant" and selected_id == id:
		clear_selection()
		return
	var pd: PlantData = GameState.plants[id]
	if float(plant_cd.get(id, 0.0)) > 0.0:
		hud.toast("%s se está recargando" % pd.display_name, 1.5)
		AudioManager.play("error")
		return
	if GameState.sun < pd.cost:
		hud.toast("Necesitas %d de energía solar" % pd.cost, 1.5)
		hud.flash_sun_error()
		AudioManager.play("error")
		return
	AudioManager.play("click")
	_set_selection("plant", id)


func select_shovel() -> void:
	if selected_kind == "shovel":
		clear_selection()
	else:
		AudioManager.play("click")
		_set_selection("shovel", "")


func select_card(id: String) -> void:
	if state != "playing":
		return
	if selected_kind == "card" and selected_id == id:
		clear_selection()
		return
	var cd: CardData = GameState.cards[id]
	if float(card_locked.get(id, 0.0)) > 0.0:
		hud.toast("¡La AGI controla esta carta! Espera a que se libere.", 2.0)
		AudioManager.play("error")
		return
	if float(card_cd.get(id, 0.0)) > 0.0:
		hud.toast("%s se está recargando" % cd.display_name, 1.5)
		AudioManager.play("error")
		return
	if GameState.tokens < cd.cost:
		hud.toast("Necesitas %d tokens (destruye robots o planta Tokenizadoras)" % cd.cost, 2.0)
		hud.flash_token_error()
		AudioManager.play("error")
		return
	if not cd.needs_target:
		apply_card(id, null)
		return
	AudioManager.play("click")
	_set_selection("card", id)
	hud.toast("%s: haz clic sobre un robot" % cd.display_name, 2.0)


# --- Plantas -------------------------------------------------------------------

func is_lane_active(l: int) -> bool:
	return active_lanes.has(l)


func random_active_lane() -> int:
	return active_lanes[randi() % active_lanes.size()]


func can_place(id: String, cell: Vector2i) -> bool:
	if cell.x < 0 or not is_lane_active(cell.y) or lanes.plant_at(cell) != null:
		return false
	var pd: PlantData = GameState.plants[id]
	return GameState.sun >= pd.cost and float(plant_cd.get(id, 0.0)) <= 0.0


func _try_place(p: Vector2) -> void:
	var cell := Grid.cell_at(p)
	if cell.x < 0:
		return
	if not can_place(selected_id, cell):
		AudioManager.play("error")
		if lanes.plant_at(cell) != null:
			hud.toast("Esa casilla ya está ocupada", 1.2)
		elif not is_lane_active(cell.y):
			hud.toast("Ese carril no está disponible en este nivel", 1.5)
		return
	place_plant(selected_id, cell)


func place_plant(id: String, cell: Vector2i, free := false) -> Node:
	var pd: PlantData = GameState.plants[id]
	var plant := Plant.create(pd)
	plant.setup(pd, self, cell)
	plants_layer.add_child(plant)
	lanes.add_plant(cell, plant)
	if not free:
		GameState.spend_sun(pd.cost)
		plant_cd[id] = pd.cooldown
		clear_selection()
	fx.burst(plant.position + Vector2(0, 30), Color(0.55, 0.4, 0.25), 6)
	AudioManager.play("plant")
	GameState.plant_placed.emit(plant)
	return plant


func _try_shovel(p: Vector2) -> void:
	var cell := Grid.cell_at(p)
	var plant: Node = lanes.plant_at(cell) if cell.x >= 0 else null
	if plant == null:
		return
	fx.burst(plant.position, Color(0.4, 0.7, 0.3), 6)
	plant.remove()
	AudioManager.play("plant")
	clear_selection()


func _try_collect(p: Vector2) -> bool:
	for pk in pickups_layer.get_children():
		if pk.can_collect_at(p):
			pk.collect()
			return true
	return false


# --- Robots, proyectiles y recogibles ---------------------------------------------

func spawn_robot(id: String, row: int, x: float, opts: Dictionary = {}) -> Node:
	if not GameState.robots.has(id):
		push_warning("Robot desconocido: %s" % id)
		return null
	var rd: RobotData = GameState.robots[id]
	var r := Robot.create(rd)
	r.setup(rd, self, row, x)
	if opts.has("mini"):
		r.make_mini(float(opts["mini"]))
	if opts.has("illusion"):
		r.make_illusion(float(opts["illusion"]))
	if opts.has("summoned"):
		r.no_reward = true
	robots_layer.add_child(r)
	lanes.add_robot(r)
	if rd.behavior == "agi":
		boss = r
		hud.show_boss(r)
		AudioManager.play("boss")
	if not opts.has("illusion") and not opts.has("mini") and GameState.mark_robot_seen(id):
		hud.show_robot_intro(rd)
	return r


func spawn_projectile(plant: Node, pos: Vector2, row: int) -> void:
	var pd: PlantData = plant.data
	var pr := Projectile.new()
	pr.level = self
	pr.row = row
	pr.position = pos
	pr.damage = pd.damage
	pr.dtype = pd.damage_type
	pr.pierce = pd.pierce
	pr.speed = pd.projectile_speed
	pr.source = plant
	if pd.slow_time > 0.0:
		pr.slow_factor = pd.slow_factor
		pr.slow_time = pd.slow_time
	projectiles_layer.add_child(pr)


func spawn_enemy_projectile(from: Node, pos: Vector2, row: int, dmg: float) -> void:
	var pr := Projectile.new()
	pr.source = from
	pr.level = self
	pr.row = row
	pr.position = pos
	pr.hostile = true
	pr.speed = 300.0
	pr.damage = dmg
	projectiles_layer.add_child(pr)


func spawn_pickup(kind: String, value: int, from: Vector2, to: Vector2, pop := false) -> void:
	var pk := Pickup.new()
	pk.setup(self, kind, value, from, to, pop)
	pickups_layer.add_child(pk)
	if auto:
		pk.collect()


func add_field(rect: Rect2, time: float, mult: float) -> void:
	fields.append({"rect": rect, "time": time, "mult": mult})


func field_mult_at(p: Vector2) -> float:
	for f in fields:
		if (f["rect"] as Rect2).has_point(p):
			return float(f["mult"])
	return 1.0


func explode_area(row: int, x: float, dmg: float, exclude: Node = null) -> void:
	for r in lanes.enemies_in_area(row - 1, row + 1, x - 150.0, x + 150.0):
		if r != exclude:
			r.take_damage(dmg, "card")
	fx.explosion(Vector2(x, Grid.lane_y(row)), 150.0)
	AudioManager.play("explode")


func robot_reached_house(robot: Node) -> void:
	if state != "playing":
		return
	for l in robot.covered_lanes():
		var m: Mower = mowers.get(l)
		if m == null:
			continue
		if m.state == "ready":
			m.trigger()
			ally_say("drone", true)
			return
		if m.state == "moving":
			return
	if robot.front_x() < Grid.LOSE_X:
		_lose()


func on_huge_wave_warning() -> void:
	hud.show_banner("¡Una gran oleada de robots se acerca!", 3.2)
	ally_say("huge", true)
	AudioManager.play("siren")


func _on_wave_started(index: int, is_huge: bool) -> void:
	if index == waves.total_waves() - 1 and is_huge:
		hud.toast("¡Oleada final!", 2.0)


# --- Cartas de IA aliada ---------------------------------------------------------

func _try_card_target(p: Vector2) -> void:
	var r: Node = lanes.robot_near_point(p, 70.0)
	if r == null:
		hud.toast("Haz clic sobre un robot (clic derecho para cancelar)", 1.5)
		return
	apply_card(selected_id, r)


func apply_card(id: String, target: Node, free := false) -> bool:
	var cd: CardData = GameState.cards[id]
	var cost := cd.cost
	if target != null:
		var rule: String = target.card_rule(id)
		if rule == "phase_locked":
			hud.toast("La AGI aún no puede alinearse: espera a la fase 3", 2.5)
			AudioManager.play("error")
			return false
		if rule == "immune":
			hud.toast("¡%s es inmune a %s!" % [target.data.display_name, cd.display_name], 2.5)
			fx.float_text(target.position + Vector2(0, -70), "INMUNE", Color(0.8, 0.8, 1.0))
			AudioManager.play("error")
			return false
		if rule == "double_cost":
			cost *= 2
			if not free and GameState.tokens < cost:
				hud.toast("%s requiere doble costo: %d tokens" % [target.data.display_name, cost], 2.5)
				hud.flash_token_error()
				AudioManager.play("error")
				return false
	if not free and not GameState.spend_tokens(cost):
		hud.flash_token_error()
		return false
	if not free:
		card_cd[id] = cd.cooldown * float(ally.params.get("card_cd_mult", 1.0))
	clear_selection()
	hud.buddy.perform(cd)
	AudioManager.play("card")
	var buddy_pos := Vector2(75, 650)
	if target != null:
		fx.beam(buddy_pos, target.position + Vector2(0, -12), cd.color)
		if target.is_illusion:
			fx.float_text(target.position + Vector2(0, -60), "¡Era una ilusión!", Color(0.8, 0.85, 1.0))
			target.vanish()
			GameState.card_used.emit(id)
			return true
	match cd.effect:
		"autodestruct":
			target.on_card_autodestruct(cd)
		"shutdown":
			target.on_card_shutdown(cd.duration)
		"chain_shutdown":
			fx.lightning(PackedVector2Array([Vector2(Grid.RIGHT_EDGE, Grid.lane_y(target.lane)), Vector2(Grid.ORIGIN.x, Grid.lane_y(target.lane))]), cd.color)
			for r in lanes.enemies_in_lane(target.lane):
				if r.card_rule(id) != "immune":
					r.on_card_shutdown(cd.duration)
		"align":
			target.on_card_align(cd.duration)
		"reveal":
			var all := lanes.all_enemies()
			for r in all:
				r.on_card_reveal(cd.duration, cd.power)
			hud.show_redteam(all, cd.duration)
		"cure":
			cure_all_plants(cd.duration)
	GameState.card_used.emit(id)
	return true


## La AGI "toma el control" de una carta del jugador durante unos segundos.
func hijack_random_card(time: float) -> String:
	var avail: Array = []
	for id in GameState.loadout_cards:
		if float(card_locked.get(id, 0.0)) <= 0.0:
			avail.append(id)
	if avail.is_empty():
		return ""
	var id: String = avail.pick_random()
	card_locked[id] = time
	if selected_kind == "card" and selected_id == id:
		clear_selection()
	hud.toast("¡La AGI tomó el control de %s!" % (GameState.cards[id] as CardData).display_name, 2.5)
	hud.buddy.say("¡Me hackearon una carta!", 2.0)
	return id


# --- Pausa, velocidad, fin -------------------------------------------------------

func toggle_pause() -> void:
	if state != "playing":
		return
	var p := not get_tree().paused
	get_tree().paused = p
	hud.show_pause(p)


func toggle_speed() -> void:
	Engine.time_scale = 2.0 if Engine.time_scale < 1.5 else 1.0
	hud.update_speed(Engine.time_scale)


func _freeze_world() -> void:
	for layer in [plants_layer, robots_layer, projectiles_layer, mowers_layer]:
		layer.process_mode = Node.PROCESS_MODE_DISABLED
	waves.process_mode = Node.PROCESS_MODE_DISABLED
	clear_selection()
	hud.hide_tutorial()
	Engine.time_scale = 1.0


func _win(ending := "") -> void:
	if state != "playing":
		return
	state = "won"
	for r in lanes.robots.duplicate():
		if is_instance_valid(r) and r.is_illusion:
			r.vanish()
	for pk in pickups_layer.get_children():
		pk.collect()
	_freeze_world()
	var unlock := GameState.complete_level(data.number, ending)
	AudioManager.play("win")
	if ending != "":
		GameState.pending_ending = ending
	hud.show_win(unlock, ending)
	ally_say("win", true)
	if auto:
		_auto_finish("victoria" + ("" if ending == "" else " (" + ending + ")"))


func _lose() -> void:
	if state != "playing":
		return
	state = "lost"
	_freeze_world()
	AudioManager.play("lose")
	hud.show_lose()
	ally_say("lose", true)
	if auto:
		_auto_finish("derrota")


func boss_defeated() -> void:
	boss = null
	for r in lanes.all_enemies():
		r.die(false)
	hud.hide_boss()
	fx.explosion(Vector2(900, Grid.lane_y(2)), 260.0)
	AudioManager.play("explode")
	_win("victory")


func boss_aligned() -> void:
	if state != "playing":
		return
	for r in lanes.all_enemies():
		if r != boss:
			r.die(false)
	if boss != null:
		boss.say("Desde hoy cuidaré este jardín.", 4.0)
		fx.ring(boss.position, 320.0, Color(0.4, 1.0, 0.55))
	hud.buddy.say("¡Lo logramos!", 3.0)
	_win("aligned")


# --- Autotest (--autotest=N) ---------------------------------------------------

func _setup_autotest() -> void:
	if GameState.autotest.is_empty():
		return
	auto = true
	auto_end = float(GameState.autotest.get("time", "90"))
	Engine.time_scale = float(GameState.autotest.get("speed", "4"))
	shot_path = String(GameState.autotest.get("shot", ""))
	shot_time = float(GameState.autotest.get("shot_at", "20"))
	if String(GameState.autotest.get("mode", "chaos")) == "chaos":
		waves.skip_wait()
	print("AUTOTEST nivel %d (%s) oleadas=%d" % [data.number, data.display_name, waves.total_waves()])


func _autoplay(delta: float) -> void:
	if shot_path != "" and elapsed >= shot_time:
		var tex := get_viewport().get_texture()
		var img: Image = tex.get_image() if tex != null else null
		if img != null:
			img.save_png(shot_path)
			print("AUTOTEST captura: ", shot_path)
		shot_path = ""
	if state != "playing":
		return
	if elapsed >= auto_end:
		_auto_finish("tiempo agotado")
		return
	auto_timer -= delta
	if auto_timer > 0.0:
		return
	auto_timer = 0.6
	if ally_cd <= 0.0 and lanes.real_enemy_count() >= 3:
		use_ally_power()
	var mode := String(GameState.autotest.get("mode", "chaos"))
	if mode == "chaos":
		GameState.add_sun(60)
		var id: String = GameState.PLANT_IDS.pick_random()
		var cell := Vector2i(randi() % 7, random_active_lane())
		if lanes.plant_at(cell) == null:
			place_plant(id, cell, true)
			auto_stats[id] = int(auto_stats.get(id, 0)) + 1
		if randf() < 0.2:
			var enemies := lanes.all_enemies()
			var cid: String = GameState.CARD_IDS.pick_random()
			var cd: CardData = GameState.cards[cid]
			if not enemies.is_empty() or not cd.needs_target:
				var target: Node = null if enemies.is_empty() or not cd.needs_target else enemies.pick_random()
				if apply_card(cid, target, true):
					auto_stats["card_" + cid] = int(auto_stats.get("card_" + cid, 0)) + 1
		if boss != null and GameState.autotest.get("ending", "") == "aligned" and boss.phase == 3:
			apply_card("alineamiento", boss, true)
		if randf() < 0.04:
			var all := lanes.all_plants()
			if not all.is_empty():
				all.pick_random().remove()
	else:
		# Modo "fair": juega con la selección real, como un jugador sencillo.
		for pk in pickups_layer.get_children():
			pk.collect()
		_fair_plant()
		for cid in GameState.loadout_cards:
			var enemies := lanes.all_enemies()
			if GameState.tokens >= (GameState.cards[cid] as CardData).cost and not enemies.is_empty() and float(card_cd.get(cid, 0.0)) <= 0.0:
				var target: Node = enemies[0]
				for e in enemies:
					if e.position.x < target.position.x:
						target = e
				apply_card(cid, target if (GameState.cards[cid] as CardData).needs_target else null)


## Estrategia sencilla y "justa" del bot de pruebas: productores atrás,
## atacantes en el carril más débil y muros cuando hay robots cerca.
func _fair_plant() -> void:
	var producers := 0
	var attackers := {}
	for l in active_lanes:
		attackers[l] = 0
	for p in lanes.all_plants():
		if p.data.behavior in ["producer", "token"]:
			producers += 1
		elif p.data.behavior in ["shooter", "lightning", "emp"]:
			attackers[p.row] = int(attackers[p.row]) + 1
	var weakest: int = active_lanes[0]
	var weakest_score := INF
	for l in active_lanes:
		var s := float(attackers[l]) * 100.0 - lanes.enemies_in_lane(l).size() * 60.0
		if s < weakest_score:
			weakest_score = s
			weakest = l
	var urgent := false
	for l in active_lanes:
		if int(attackers[l]) == 0:
			for e in lanes.enemies_in_lane(l):
				if e.position.x < 950.0:
					urgent = true
	var total_attackers := 0
	for l in active_lanes:
		total_attackers += int(attackers[l])
	var want: Array[String] = []
	if urgent:
		want.append("attack")
	else:
		if producers < mini(active_lanes.size() * 2, 8) and producers <= total_attackers + 4:
			want.append("producer")
		want.append("attack")
		var ahead := false
		for e in lanes.enemies_in_lane(weakest):
			if e.position.x > Grid.col_x(5) + 60.0:
				ahead = true
		if weakest_score < 0.0 and ahead:
			want.append("wall")
	for kind in want:
		for id in GameState.loadout_plants:
			var pd: PlantData = GameState.plants[id]
			var ok := false
			match kind:
				"producer":
					ok = pd.behavior == "producer"
				"attack":
					ok = pd.behavior in ["shooter", "lightning"]
				"wall":
					ok = pd.behavior == "wall"
			if not ok or GameState.sun < pd.cost or float(plant_cd.get(id, 0.0)) > 0.0:
				continue
			var cols: Array = [0, 1] if kind == "producer" else ([5, 6] if kind == "wall" else [2, 3, 4, 1])
			var rows: Array = [weakest] if kind != "producer" else Array(active_lanes)
			for c in cols:
				for r in rows:
					var cell := Vector2i(c, r)
					if can_place(id, cell):
						place_plant(id, cell)
						return


func _auto_finish(result: String) -> void:
	print("AUTOTEST FIN nivel %d: %s | t=%.1fs | oleada %d/%d | robots vivos=%d | stats=%s" % [
		data.number, result, elapsed, waves.wave_index + 1, waves.total_waves(), lanes.real_enemy_count(), str(auto_stats)])
	var board_desc := ""
	for l in active_lanes:
		var ids: Array = []
		for p in lanes.plants_in_lane(l):
			ids.append(String(p.data.id).substr(0, 4))
		var m: Mower = mowers.get(l)
		board_desc += "\n  carril %d [%s] dron=%s enemigos=%d" % [l, ",".join(ids), m.state if m else "-", lanes.enemies_in_lane(l).size()]
	print("  sol=%d tokens=%d%s" % [GameState.sun, GameState.tokens, board_desc])
	auto = false
	get_tree().paused = false
	get_tree().quit()


# --- IA aliada (compañero elegido por el jugador) ----------------------------

## Dice una frase del aliado. `key` busca en AllyData.lines; admite formato con args.
func ally_say(key: String, force := false, args: Array = []) -> void:
	if ally == null or hud == null:
		return
	if not force and ally_line_cd > 0.0:
		return
	var options: Variant = ally.lines.get(key, "")
	var line := ""
	if options is Array and not (options as Array).is_empty():
		line = String((options as Array).pick_random())
	elif options is String:
		line = options
	if line == "":
		return
	if not args.is_empty():
		line = line % args
	hud.buddy.say(line, 3.0)
	ally_line_cd = 7.0


func _ally_process(delta: float) -> void:
	ally_cd = maxf(0.0, ally_cd - delta)
	ally_line_cd = maxf(0.0, ally_line_cd - delta)
	# Pasivas
	match ally.id:
		"llamita", "perplejo":
			ally_passive_timer -= delta
			if ally_passive_timer <= 0.0:
				ally_passive_timer = float(ally.params.get("passive_interval", 25.0))
				if ally.id == "llamita":
					spawn_pickup("token", 1, Vector2(75, 600), Vector2(95, 560), true)
				else:
					for r in lanes.all_enemies():
						r.on_card_reveal(float(ally.params.get("scan_time", 4.0)), 0.0)
	# Comentarios según la situación (cada segundo)
	ally_check_timer -= delta
	if ally_check_timer > 0.0:
		return
	ally_check_timer = 1.0
	if ally_cd <= 0.0 and not said_power_ready:
		said_power_ready = true
		ally_say("power_ready", false, [ally.active_name])
		return
	for l in active_lanes:
		var defended := false
		for p in lanes.plants_in_lane(l):
			if p.data.behavior in ["shooter", "lightning", "emp"] and not p.status.is_controlled():
				defended = true
				break
		if defended:
			continue
		for e in lanes.enemies_in_lane(l):
			if not e.is_illusion and e.position.x < Grid.col_x(4):
				ally_say("danger", false, [l + 1])
				return
	idle_sun_time = idle_sun_time + 1.0 if GameState.sun >= 250 else 0.0
	if idle_sun_time >= 12.0:
		idle_sun_time = 0.0
		ally_say("idle_sun", false, [GameState.sun])
		return
	if elapsed - said_tokens_at > 30.0:
		for cid in GameState.loadout_cards:
			var cd: CardData = GameState.cards[cid]
			if GameState.tokens >= cd.cost and float(card_cd.get(cid, 0.0)) <= 0.0 and lanes.real_enemy_count() >= 3:
				said_tokens_at = elapsed
				ally_say("tokens", false, [cd.display_name])
				return


## Habilidad activa del aliado (tocar al compañero en la esquina).
func use_ally_power() -> void:
	if state != "playing" or get_tree().paused:
		return
	if ally_cd > 0.0:
		hud.buddy.say("%s se recarga: %ds" % [ally.active_name, ceili(ally_cd)], 1.8)
		AudioManager.play("error")
		return
	ally_cd = ally.active_cooldown
	said_power_ready = false
	var p := ally.params
	match ally.id:
		"llamita":
			GameState.add_tokens(int(p.get("tokens", 3)))
			GameState.add_sun(int(p.get("sun", 50)))
			fx.float_text(Vector2(150, 560), "+%d tokens  +%d sol" % [int(p.get("tokens", 3)), int(p.get("sun", 50))], Color(1.0, 0.9, 0.5), 20)
		"mistralito":
			var push := float(p.get("push", 120.0))
			for r in lanes.all_enemies():
				var amount := push * (0.25 if r.hitbox.half_width > 60.0 else 1.0)
				r.position.x = minf(r.position.x + amount, Grid.SPAWN_X)
				r.status.apply_slow(0.5, float(p.get("slow_time", 3.0)))
			for l in active_lanes:
				fx.beam(Vector2(Grid.ORIGIN.x, Grid.lane_y(l)), Vector2(Grid.RIGHT_EDGE, Grid.lane_y(l) - 20.0), Color(1.0, 0.75, 0.35))
		"perplejo":
			var all := lanes.all_enemies()
			for r in all:
				r.on_card_reveal(float(p.get("reveal_time", 10.0)), 0.25)
			hud.show_redteam(all, float(p.get("reveal_time", 10.0)))
			cure_all_plants(float(p.get("immunity", 6.0)))
		_:
			for pl in lanes.all_plants():
				pl.status.haste_timer = float(p.get("haste_time", 8.0))
				fx.spark(pl.position + Vector2(0, -30), Color(0.5, 0.8, 1.0))
	hud.buddy.perform_power(ally.active_name)
	AudioManager.play("card")


func cure_all_plants(immunity: float) -> void:
	for p in lanes.all_plants():
		p.cure(immunity)
	fx.ring(Vector2(660, 420), 520.0, Color(0.5, 1.0, 0.6))


func on_plant_controlled(_plant: Node) -> void:
	ally_say("controlled")
