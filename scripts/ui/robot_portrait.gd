class_name RobotPortrait
extends Control
## Dibuja un robot (o planta / carta) como retrato dentro de la UI.

var robot_data: RobotData = null
var plant_id := ""
var card_id := ""
var scale_factor := 1.0
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0 + Vector2(0, 8)
	if robot_data != null:
		if robot_data.behavior == "agi":
			Art.fill_ellipse(self, c, 26 * scale_factor, 40 * scale_factor, Color(0.1, 0.11, 0.16))
			draw_circle(c + Vector2(0, -8) * scale_factor, 14 * scale_factor, Color(1.0, 0.3, 0.3))
			draw_circle(c + Vector2(-4, -8) * scale_factor, 5 * scale_factor, Color.BLACK)
			return
		var s := scale_factor * robot_data.size
		draw_set_transform(c, 0.0, Vector2(s, s))
		Art.robot(self, robot_data, t, {"walk": true, "shield": 1.0, "expr": String(robot_data.params.get("expr", "happy"))})
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif plant_id != "":
		draw_set_transform(c, 0.0, Vector2(scale_factor, scale_factor))
		Art.plant(self, plant_id, t, {"armed": true, "charge": 1.0})
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif card_id != "":
		Art.card_icon(self, card_id, size / 2.0, 2.0 * scale_factor)
