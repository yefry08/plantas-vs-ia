extends Robot
## Claude Fable: crea ilusiones de robots falsos y cuenta "una historia" en 3 fases:
## Inicio (avanza), Nudo (cambia de carril) y Desenlace (acelera y cambia de nuevo).

const CHAPTERS := ["Había una vez...", "Pero entonces...", "Y al final..."]
const ILLUSION_POOL := ["scriptbot", "spambot", "abrazobot", "captchabot"]

var illusion_timer := 3.0
var chapter := 0
var chapter_timer := 0.0


func _init_behavior() -> void:
	chapter_timer = float(data.params.get("chapter_time", 5.0))


func _behavior(delta: float) -> void:
	if position.x > Grid.RIGHT_EDGE + 20.0 or is_aligned():
		return
	illusion_timer -= delta
	if illusion_timer <= 0.0:
		illusion_timer = float(data.params.get("illusion_interval", 8.0))
		_spawn_illusions()
	chapter_timer -= delta
	if chapter_timer <= 0.0:
		chapter = (chapter + 1) % CHAPTERS.size()
		chapter_timer = float(data.params.get("chapter_time", 5.0))
		_apply_chapter()


func _apply_chapter() -> void:
	say(CHAPTERS[chapter], 2.0)
	match chapter:
		0:
			speed_mult_extra = 1.0
		1:
			_hop_lane()
		2:
			speed_mult_extra = 1.6
			_hop_lane()


func _hop_lane() -> void:
	var options: Array = []
	for l in [lane - 1, lane + 1]:
		if level.is_lane_active(l):
			options.append(l)
	if not options.is_empty():
		change_lane(options.pick_random())


func _spawn_illusions() -> void:
	var n := int(data.params.get("illusions", 2))
	for i in n:
		var l := lane
		var options: Array = [lane]
		for k in [lane - 1, lane + 1]:
			if level.is_lane_active(k):
				options.append(k)
		l = options.pick_random()
		level.spawn_robot(ILLUSION_POOL.pick_random(), l, position.x + 50.0 + i * 30.0, {"illusion": 12.0})
	level.fx.poof(position + Vector2(0, -50))
	say("Imagina que...", 1.2)
