extends Control
## Créditos y finales (victoria / AGI alineada).

var t := 0.0
var scroll_box: VBoxContainer
var ending := ""


func _ready() -> void:
	ending = GameState.pending_ending
	GameState.pending_ending = ""
	var title := "Créditos"
	var sub := ""
	match ending:
		"victory":
			title = "FINAL: Victoria"
			sub = "Derrotaste a la AGI. Los robots se reinician... y tu jardín florece otra vez."
		"aligned":
			title = "FINAL: AGI alineada"
			sub = "Con tres cartas de Alineamiento, la AGI entendió lo que importa: regar, compartir y cuidar."
	scroll_box = VBoxContainer.new()
	scroll_box.add_theme_constant_override("separation", 10)
	UI.place(scroll_box, Vector2(240, 720), Vector2(800, 1400))
	add_child(scroll_box)
	scroll_box.add_child(UI.label(title, 48, Color(1.0, 0.92, 0.5), 10, HORIZONTAL_ALIGNMENT_CENTER))
	if sub != "":
		var s := UI.label(sub, 22, Color(0.9, 1.0, 0.9), 5, HORIZONTAL_ALIGNMENT_CENTER)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size = Vector2(800, 0)
		scroll_box.add_child(s)
	var lines := [
		["Plantas vs IA", 36],
		["Un tower defense por carriles hecho en Godot 4 con GDScript", 18],
		["", 10],
		["Diseño, código y balance", 24],
		["Todo el contenido es data-driven (archivos .tres)", 18],
		["", 10],
		["Arte", 24],
		["100% procedural: formas vectoriales dibujadas por código", 18],
		["Caras tipo emoji dibujadas a mano, sin fuentes de emoji", 18],
		["", 10],
		["Sonido", 24],
		["Efectos sintetizados en tiempo real", 18],
		["", 10],
		["Aviso", 24],
		["Todos los robots son parodias originales con nombres propios.", 18],
		["No se usa ningún logo, marca ni asset de terceros.", 18],
		["Los tokens son una moneda simbólica del juego.", 18],
		["", 10],
		["¡Gracias por jugar!", 30],
	]
	for l in lines:
		scroll_box.add_child(UI.label(String(l[0]), int(l[1]), Color.WHITE, 4, HORIZONTAL_ALIGNMENT_CENTER))
	var back := UI.button("Volver al menú", UI.GREEN, 20, Vector2(220, 50))
	UI.place(back, Vector2(1040, 650), Vector2(220, 50))
	back.pressed.connect(func(): GameState.goto(GameState.SCENE_MENU))
	add_child(back)


func _process(delta: float) -> void:
	t += delta
	scroll_box.position.y = maxf(60.0, 720.0 - t * 70.0)
	queue_redraw()


func _draw() -> void:
	var bg := Color(0.08, 0.1, 0.12)
	if ending == "aligned":
		bg = Color(0.1, 0.2, 0.14)
	elif ending == "victory":
		bg = Color(0.16, 0.12, 0.08)
	draw_rect(Rect2(0, 0, 1280, 720), bg)
	for i in 40:
		var x := fmod(i * 97.0 + t * 10.0, 1280.0)
		var y := fmod(i * 53.0, 720.0)
		draw_circle(Vector2(x, y), 1.5 + (i % 3), Color(1, 1, 0.8, 0.25))
	draw_set_transform(Vector2(120, 600), 0.0, Vector2(1.3, 1.3))
	Art.plant(self, "girasolar", t)
	draw_set_transform(Vector2(1140, 560), 0.0, Vector2(1.2, 1.2))
	if ending == "aligned":
		Art.buddy(self, Vector2.ZERO, 1.2, t, 0.6)
	else:
		Art.plant(self, "lanzasemillas", t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
