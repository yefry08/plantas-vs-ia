class_name Grid
extends RefCounted
## Geometría del tablero: 5 carriles x 9 columnas.

const ROWS := 5
const COLS := 9
const ORIGIN := Vector2(210, 140)
const CELL := Vector2(100, 112)
const RIGHT_EDGE := 1110.0
const SPAWN_X := 1235.0
const VISIBLE_X := 1262.0
const MOWER_X := 172.0
## Un robot que cruza esta X activa la podadora del carril.
const HOUSE_X := 196.0
## Si cruza esta X sin podadora disponible, se pierde el nivel.
const LOSE_X := 128.0


static func cell_center(col: int, row: int) -> Vector2:
	return ORIGIN + Vector2((col + 0.5) * CELL.x, (row + 0.5) * CELL.y)


static func lane_y(row: int) -> float:
	return ORIGIN.y + (row + 0.5) * CELL.y


static func col_x(col: int) -> float:
	return ORIGIN.x + (col + 0.5) * CELL.x


static func cell_at(p: Vector2) -> Vector2i:
	var c := int(floor((p.x - ORIGIN.x) / CELL.x))
	var r := int(floor((p.y - ORIGIN.y) / CELL.y))
	if c < 0 or c >= COLS or r < 0 or r >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(c, r)


static func row_at(y: float) -> int:
	return clampi(int(floor((y - ORIGIN.y) / CELL.y)), 0, ROWS - 1)


static func board_rect() -> Rect2:
	return Rect2(ORIGIN, Vector2(COLS * CELL.x, ROWS * CELL.y))
