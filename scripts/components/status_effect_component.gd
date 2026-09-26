class_name StatusEffectComponent
extends Node
## Efectos temporales: lentitud, aturdimiento (EMP), apagado (carta), hackeo,
## alineamiento (robot aliado) y revelado (Red Team).

signal aligned_changed(is_aligned: bool)

var slow_timer := 0.0
var slow_factor := 1.0
var stun_timer := 0.0
var shutdown_timer := 0.0
var hack_timer := 0.0
var aligned_timer := 0.0
var reveal_timer := 0.0
var reveal_bonus := 0.25
## Multiplicador de duración de aturdimientos (Qilin: 0.5).
var stun_mult := 1.0
var stun_immune_timer := 0.0
## Plantas: controladas por bioarmas IA (se vuelven contra ti).
var control_timer := 0.0
var control_immune_timer := 0.0
## Multiplicador de cadencia (habilidad "Atención total" del aliado).
var haste_timer := 0.0


func _process(delta: float) -> void:
	slow_timer = max(0.0, slow_timer - delta)
	stun_timer = max(0.0, stun_timer - delta)
	shutdown_timer = max(0.0, shutdown_timer - delta)
	hack_timer = max(0.0, hack_timer - delta)
	reveal_timer = max(0.0, reveal_timer - delta)
	stun_immune_timer = max(0.0, stun_immune_timer - delta)
	control_timer = max(0.0, control_timer - delta)
	control_immune_timer = max(0.0, control_immune_timer - delta)
	haste_timer = max(0.0, haste_timer - delta)
	if aligned_timer > 0.0:
		aligned_timer -= delta
		if aligned_timer <= 0.0:
			aligned_timer = 0.0
			aligned_changed.emit(false)


func apply_slow(factor: float, time: float) -> void:
	slow_factor = min(slow_factor, factor) if slow_timer > 0.0 else factor
	slow_timer = max(slow_timer, time)


func apply_stun(time: float) -> void:
	if stun_immune_timer > 0.0:
		return
	stun_timer = max(stun_timer, time * stun_mult)


func apply_shutdown(time: float) -> void:
	shutdown_timer = max(shutdown_timer, time)


func apply_hack(time: float) -> void:
	hack_timer = max(hack_timer, time)


func apply_aligned(time: float) -> void:
	var was := aligned_timer > 0.0
	aligned_timer = max(aligned_timer, time)
	if not was:
		aligned_changed.emit(true)


func apply_reveal(time: float, bonus := 0.25) -> void:
	reveal_timer = max(reveal_timer, time)
	reveal_bonus = bonus


func is_disabled() -> bool:
	return stun_timer > 0.0 or shutdown_timer > 0.0 or hack_timer > 0.0


func speed_mult() -> float:
	return slow_factor if slow_timer > 0.0 else 1.0


func is_slowed() -> bool:
	return slow_timer > 0.0


func is_aligned() -> bool:
	return aligned_timer > 0.0


func is_revealed() -> bool:
	return reveal_timer > 0.0


## Devuelve true si la planta quedó controlada.
func apply_control(time: float) -> bool:
	if control_immune_timer > 0.0:
		return false
	control_timer = max(control_timer, time)
	return true


func cure_control(immunity: float) -> void:
	control_timer = 0.0
	hack_timer = 0.0
	control_immune_timer = max(control_immune_timer, immunity)


func is_controlled() -> bool:
	return control_timer > 0.0
