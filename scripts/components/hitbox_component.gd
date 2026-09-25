class_name HitboxComponent
extends Node
## Caja de impacto horizontal. El juego es por carriles, así que basta con
## comparar distancias en X dentro del mismo carril (más barato que física en web).

var half_width := 26.0


func contains_x(owner_x: float, x: float, margin := 0.0) -> bool:
	return abs(owner_x - x) <= half_width + margin
