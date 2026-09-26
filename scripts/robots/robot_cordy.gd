extends Robot
## Cordybot (bioarma IA): su mordisco infecta a la planta y la controla un tiempo.

var infected: Array = []


func _on_bite(target: Node) -> void:
	if not (target is Plant) or infected.has(target):
		return
	infected.append(target)
	if target.take_control(float(data.params.get("control_time", 10.0))):
		say("Infección completada.", 1.4)
