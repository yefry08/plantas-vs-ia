class_name Mower
extends Node2D
## Podadora de emergencia: una por carril, se activa una sola vez.

var level: Node
var row := 0
var state := "ready"
var hit: Array = []
var t := 0.0


func setup(lvl: Node, r: int) -> void:
	level = lvl
	row = r
	position = Vector2(Grid.MOWER_X, Grid.lane_y(r) + 18.0)


func trigger() -> void:
	if state != "ready":
		return
	state = "moving"
	AudioManager.play("mower")
	level.fx.float_text(position + Vector2(40, -50), "¡Podadora de emergencia!", Color(1.0, 0.5, 0.4), 18)


func _process(delta: float) -> void:
	t += delta
	if state != "moving":
		return
	position.x += 560.0 * delta
	for r in level.lanes.enemies_in_lane(row):
		if hit.has(r):
			continue
		if abs(r.position.x - position.x) < r.hitbox.half_width + 24.0:
			hit.append(r)
			r.hit_by_mower(self)
	if position.x > Grid.VISIBLE_X + 60.0:
		state = "done"
		hide()
	queue_redraw()


func _draw() -> void:
	Art.mower(self, t, state == "moving")
