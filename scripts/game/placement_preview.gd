class_name PlacementPreview
extends Node2D
## Resalta la casilla bajo el cursor y muestra una planta fantasma / objetivo.

var level: Node
var t := 0.0
var ghost: Node2D
var ghost_id := ""


func _ready() -> void:
	ghost = Node2D.new()
	ghost.modulate = Color(1, 1, 1, 0.5)
	ghost.draw.connect(_draw_ghost)
	add_child(ghost)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	ghost.visible = false
	if level == null or level.state != "playing" or level.selected_kind != "plant":
		return
	var cell := Grid.cell_at(get_global_mouse_position())
	if cell.x >= 0 and level.can_place(level.selected_id, cell):
		ghost.visible = true
		ghost.position = Grid.cell_center(cell.x, cell.y)
		ghost_id = level.selected_id
		ghost.queue_redraw()


func _draw_ghost() -> void:
	if ghost_id != "":
		Art.plant(ghost, ghost_id, t)


func _draw() -> void:
	if level == null or level.state != "playing":
		return
	var mouse := get_global_mouse_position()
	var kind: String = level.selected_kind
	if kind == "":
		_draw_tutorial_hint()
		return
	if kind == "card":
		var r: Node = level.lanes.robot_near_point(mouse, 70.0)
		var target: Vector2 = mouse if r == null else r.position + Vector2(0, -12)
		var col := Color(0.4, 1.0, 0.7) if r != null else Color(1, 1, 1, 0.5)
		var rad := 34.0 + sin(t * 8.0) * 4.0
		if r != null and r.hitbox.half_width > 60.0:
			rad = 120.0
		draw_arc(target, rad, 0, TAU, 32, col, 3.0, true)
		draw_line(target + Vector2(-rad - 8, 0), target + Vector2(-rad + 10, 0), col, 3.0)
		draw_line(target + Vector2(rad - 10, 0), target + Vector2(rad + 8, 0), col, 3.0)
		return
	var cell := Grid.cell_at(mouse)
	if cell.x < 0:
		return
	var rect := Rect2(Grid.ORIGIN + Vector2(cell.x * Grid.CELL.x, cell.y * Grid.CELL.y), Grid.CELL)
	if kind == "shovel":
		var has_plant: bool = level.lanes.plant_at(cell) != null
		draw_rect(rect, Color(1.0, 0.3, 0.2, 0.3 if has_plant else 0.1))
		Art.shovel_icon(self, mouse + Vector2(16, -16), 1.0)
		return
	var ok: bool = level.can_place(level.selected_id, cell)
	draw_rect(rect, Color(1, 1, 1, 0.22) if ok else Color(1.0, 0.2, 0.2, 0.18))


func _draw_tutorial_hint() -> void:
	if level.data.number != 1 or level.lanes.plants.size() > 0:
		return
	var y := Grid.lane_y(2)
	var a := 0.15 + 0.1 * sin(t * 4.0)
	draw_rect(Rect2(Grid.ORIGIN.x, y - Grid.CELL.y / 2.0, Grid.CELL.x * 3.0, Grid.CELL.y), Color(1, 1, 0.6, a))
