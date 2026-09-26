class_name Projectile
extends Node2D
## Semillas, espinas y cristales de hielo (y disparos robados por el Dragón).

var level: Node
var row := 0
var speed := 480.0
var damage := 20.0
var dtype := "seed"
var pierce := 1
var hit: Array = []
var slow_factor := 1.0
var slow_time := 0.0
var source: Node = null
var hostile := false
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	if hostile:
		position.x -= speed * delta
		for p in level.lanes.plants_in_lane(row):
			if p == source:
				continue
			if abs(p.position.x - position.x) < 30.0:
				p.take_damage(damage, "bite", null)
				level.fx.spark(position, Color(1.0, 0.4, 0.3))
				queue_free()
				return
		if position.x < Grid.ORIGIN.x - 20.0:
			queue_free()
		return
	var prev_x := position.x
	position.x += speed * level.field_mult_at(position) * delta
	for r in level.lanes.enemies_in_lane(row):
		if hit.has(r):
			continue
		# Colisión "barrida": no atraviesa robots aunque el frame sea largo (velocidad x2, lag).
		var hw: float = r.hitbox.half_width
		if r.position.x - hw <= position.x and r.position.x + hw >= prev_x:
			var src: Node = source if is_instance_valid(source) else null
			r.take_damage(damage, dtype, src)
			if slow_time > 0.0 and is_instance_valid(r) and not r.dead:
				r.status.apply_slow(slow_factor, slow_time)
			hit.append(r)
			pierce -= 1
			level.fx.spark(position, _color())
			AudioManager.play("hit", 0.15)
			if pierce <= 0:
				queue_free()
				return
	if position.x > Grid.VISIBLE_X + 40.0:
		queue_free()
	if dtype == "spike":
		queue_redraw()


func _color() -> Color:
	match dtype:
		"spike":
			return Color(0.95, 0.95, 0.75)
		"ice":
			return Color(0.7, 0.92, 1.0)
	return Color(0.45, 0.85, 0.25)


func _draw() -> void:
	if hostile:
		draw_circle(Vector2.ZERO, 8, Color(0.9, 0.3, 0.2))
		draw_circle(Vector2(2, -2), 3, Color(1, 0.8, 0.6))
		return
	match dtype:
		"spike":
			Art.poly(self, [Vector2(-12, -3), Vector2(12, 0), Vector2(-12, 3)], Color(0.95, 0.95, 0.8))
			draw_line(Vector2(-12, 0), Vector2(-20, 0), Color(0.3, 0.6, 0.3), 2.0)
		"ice":
			draw_circle(Vector2.ZERO, 9, Color(0.7, 0.92, 1.0))
			draw_colored_polygon(Art.star_points(Vector2.ZERO, 7, 3, 6), Color.WHITE)
		_:
			draw_circle(Vector2.ZERO, 9, Color(0.4, 0.8, 0.22))
			draw_circle(Vector2(-3, -3), 3, Color(0.75, 1.0, 0.6))
			draw_arc(Vector2.ZERO, 9, 0, TAU, 14, Color(0.2, 0.45, 0.1), 1.5, true)
