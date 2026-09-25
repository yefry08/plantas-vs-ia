class_name SeedCard
extends Control
## Carta de semilla / carta de IA / pala, dibujada por código.

signal pressed(card: SeedCard)

var kind := "plant"
var item_id := ""
var cost := 0
var cooldown_ratio := 0.0
var affordable := true
var selected := false
var locked := 0.0
var dimmed := false
var t := 0.0


func setup(k: String, id: String) -> SeedCard:
	kind = k
	item_id = id
	custom_minimum_size = Vector2(78, 100)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	match kind:
		"plant":
			var pd: PlantData = GameState.plants[id]
			cost = pd.cost
			tooltip_text = "%s (%d energía)\n%s" % [pd.display_name, pd.cost, pd.description]
		"card":
			var cd: CardData = GameState.cards[id]
			cost = cd.cost
			tooltip_text = "%s (%d tokens)\n%s" % [cd.display_name, cd.cost, cd.description]
		"shovel":
			tooltip_text = "Pala: quita una planta"
	return self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
		accept_event()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var bg := Color(0.93, 0.9, 0.78)
	var border := Color(0.45, 0.36, 0.2)
	if kind == "card":
		bg = Color(0.24, 0.2, 0.42)
		border = Color(0.6, 0.5, 1.0)
	elif kind == "shovel":
		bg = Color(0.55, 0.42, 0.28)
		border = Color(0.32, 0.22, 0.12)
	Art.rrect(self, r.grow(-2), 9, bg, border, 3)
	var c := Vector2(size.x / 2.0, 42)
	match kind:
		"plant":
			draw_set_transform(c + Vector2(-4, 4), 0.0, Vector2(0.62, 0.62))
			Art.plant(self, item_id, t)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"card":
			Art.card_icon(self, item_id, c, 1.3)
		"shovel":
			Art.shovel_icon(self, c + Vector2(0, 4), 1.2)
	if kind == "plant":
		Art.sun_icon(self, Vector2(18, size.y - 16), 7.0)
		Art.text(self, Vector2(28, size.y - 9), str(cost), 18, Color(0.2, 0.15, 0.05))
	elif kind == "card":
		Art.token_icon(self, Vector2(18, size.y - 16), 8.0)
		Art.text(self, Vector2(30, size.y - 9), str(cost), 18, Color.WHITE)
	if not affordable or dimmed:
		Art.rrect(self, r.grow(-2), 9, Color(0, 0, 0, 0.45))
	if cooldown_ratio > 0.0:
		draw_rect(Rect2(4, 4, size.x - 8, (size.y - 8) * cooldown_ratio), Color(0, 0, 0, 0.5))
	if locked > 0.0:
		for i in 5:
			var y := fmod(t * 80.0 + i * 22.0, size.y)
			draw_line(Vector2(4, y), Vector2(size.x - 4, y), Color(1.0, 0.2, 0.3, 0.6), 3.0)
		Art.lock_icon(self, c, 1.6, Color(1.0, 0.35, 0.35))
		Art.text_c(self, size.x / 2.0, size.y - 30, "AGI", 14, Color(1, 0.6, 0.6), 3)
	if selected:
		var sel := r.grow(-1)
		Art.rrect(self, sel, 10, Color(1, 1, 0.5, 0.12), Color(1.0, 0.95, 0.2), 4)
