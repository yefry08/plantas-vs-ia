class_name LaneManager
extends Node
## Registro de plantas y robots por carril, con las consultas que usan
## plantas, robots y proyectiles.

var robots: Array = []
var plants: Dictionary = {}


func add_robot(r: Node) -> void:
	robots.append(r)
	r.died.connect(_on_robot_died)


func _on_robot_died(r: Node) -> void:
	robots.erase(r)


func add_plant(cell: Vector2i, p: Node) -> void:
	plants[cell] = p
	p.tree_exiting.connect(_on_plant_exiting.bind(cell, p))


func _on_plant_exiting(cell: Vector2i, p: Node) -> void:
	if plants.get(cell) == p:
		plants.erase(cell)


func plant_at(cell: Vector2i) -> Node:
	var p: Node = plants.get(cell)
	if p != null and is_instance_valid(p) and not p.removed:
		return p
	return null


func _valid_plant(p: Node) -> bool:
	return p != null and is_instance_valid(p) and not p.removed


func plants_in_lane(row: int) -> Array:
	var out: Array = []
	for c in plants.keys():
		if c.y == row and _valid_plant(plants[c]):
			out.append(plants[c])
	return out


func all_plants() -> Array:
	var out: Array = []
	for p in plants.values():
		if _valid_plant(p):
			out.append(p)
	return out


# --- Robots enemigos ---------------------------------------------------------

func _is_enemy(r: Node) -> bool:
	return is_instance_valid(r) and not r.dead and not r.is_aligned()


func all_enemies() -> Array:
	var out: Array = []
	for r in robots:
		if _is_enemy(r):
			out.append(r)
	return out


func real_enemy_count() -> int:
	var n := 0
	for r in robots:
		if _is_enemy(r) and not r.is_illusion:
			n += 1
	return n


func enemies_in_lane(row: int) -> Array:
	var out: Array = []
	for r in robots:
		if _is_enemy(r) and r.occupies_lane(row):
			out.append(r)
	return out


func enemies_in_area(row_min: int, row_max: int, x_min: float, x_max: float) -> Array:
	var out: Array = []
	for r in robots:
		if not _is_enemy(r):
			continue
		var in_rows := false
		for l in range(row_min, row_max + 1):
			if r.occupies_lane(l):
				in_rows = true
				break
		if in_rows and r.position.x + r.hitbox.half_width >= x_min and r.position.x - r.hitbox.half_width <= x_max:
			out.append(r)
	return out


func first_enemy_ahead(row: int, x: float) -> Node:
	var best: Node = null
	var best_x := INF
	for r in robots:
		if not _is_enemy(r) or not r.occupies_lane(row):
			continue
		var rx: float = r.position.x - r.hitbox.half_width * 0.5
		if r.position.x + r.hitbox.half_width >= x and rx <= Grid.VISIBLE_X and rx < best_x:
			best_x = rx
			best = r
	return best


func has_enemy_ahead(row: int, x: float) -> bool:
	return first_enemy_ahead(row, x) != null


func nearest_enemy_to(p: Vector2, max_dist: float, exclude: Array) -> Node:
	var best: Node = null
	var best_d := max_dist
	for r in robots:
		if not _is_enemy(r) or exclude.has(r) or r.position.x > Grid.VISIBLE_X:
			continue
		var d: float = p.distance_to(r.position)
		if d < best_d:
			best_d = d
			best = r
	return best


## Planta o robot aliado que frena a este robot enemigo.
func find_blocker(robot: Node) -> Node:
	var front: float = robot.front_x()
	var best: Node = null
	var best_x := -INF
	for p in plants_in_lane(robot.lane):
		if not p.is_blocking():
			continue
		if front <= p.position.x + 40.0 and robot.position.x >= p.position.x - 20.0 and p.position.x > best_x:
			best_x = p.position.x
			best = p
	if best != null:
		return best
	for r in robots:
		if r == robot or not is_instance_valid(r) or r.dead or not r.is_aligned() or r.lane != robot.lane:
			continue
		if r.position.x <= robot.position.x and robot.position.x - r.position.x < 56.0:
			return r
	return null


## Plantas que bloquean a un robot que ocupa varios carriles (la AGI).
func plants_blocking(robot: Node) -> Array:
	var out: Array = []
	var front: float = robot.front_x()
	for l in robot.covered_lanes():
		for p in plants_in_lane(l):
			if p.is_blocking() and front <= p.position.x + 40.0 and robot.position.x >= p.position.x - 20.0:
				out.append(p)
	return out


func find_enemy_for_ally(ally: Node) -> Node:
	var best: Node = null
	var best_d := 60.0
	for r in robots:
		if not _is_enemy(r) or not r.occupies_lane(ally.lane):
			continue
		var d: float = (r.position.x - r.hitbox.half_width * 0.5) - ally.position.x
		if d >= -20.0 and d < best_d:
			best_d = d
			best = r
	return best


func has_plant_ahead(row: int, x: float) -> bool:
	for p in plants_in_lane(row):
		if p.position.x < x:
			return true
	return false


func plant_in_reach(row: int, x: float, reach: float) -> Node:
	var best: Node = null
	var best_x := -INF
	for p in plants_in_lane(row):
		if p.position.x <= x + 20.0 and p.position.x >= x - reach and p.position.x > best_x:
			best_x = p.position.x
			best = p
	return best


func strongest_plant_in_lane(row: int, max_x: float) -> Node:
	var best: Node = null
	var best_v := -1.0
	for p in plants_in_lane(row):
		if p.position.x > max_x or p.status.hack_timer > 0.0:
			continue
		var v: float = p.threat()
		if v > best_v:
			best_v = v
			best = p
	return best


## Defensa del carril delante de x (usada por el Razonador Serie-O).
func lane_defense(row: int, x: float) -> float:
	var s := 0.0
	for p in plants_in_lane(row):
		if p.position.x < x:
			s += p.threat()
	return s


## Robot bajo el cursor (para apuntar cartas). Incluye ilusiones: ¡pueden engañarte!
func robot_near_point(pt: Vector2, radius: float) -> Node:
	var best: Node = null
	var best_d := radius
	for r in robots:
		if not _is_enemy(r):
			continue
		var d: float
		if r.hitbox.half_width > 60.0:
			var dx: float = max(0.0, abs(pt.x - r.position.x) - r.hitbox.half_width)
			var dy: float = max(0.0, abs(pt.y - r.position.y) - 168.0)
			d = Vector2(dx, dy).length()
		else:
			d = pt.distance_to(r.position + Vector2(0, -12))
		if d < best_d:
			best_d = d
			best = r
	return best
