class_name WaveManager
extends Node
## Lee las WaveData del nivel y hace aparecer a los robots.

signal wave_started(index: int, is_huge: bool)

const HUGE_WARNING_TIME := 3.5

var level: Node
var data: LevelData
var wave_index := -1
var timer := 0.0
var since_wave := 0.0
var clock := 0.0
var queue: Array = []
var finished := false
var huge_pending := -1.0
var last_lane := -1


func setup(lvl: Node, d: LevelData) -> void:
	level = lvl
	data = d
	timer = d.first_wave_delay
	finished = d.waves.is_empty()


func total_waves() -> int:
	return data.waves.size()


func progress() -> float:
	if data.waves.is_empty():
		return 1.0
	return float(wave_index + 1) / float(data.waves.size())


func huge_wave_marks() -> Array:
	var out: Array = []
	for i in data.waves.size():
		if data.waves[i].is_huge:
			out.append(float(i + 1) / float(data.waves.size()))
	return out


func _process(delta: float) -> void:
	if level == null or level.state != "playing":
		return
	clock += delta
	_process_queue()
	if wave_index + 1 >= data.waves.size():
		finished = queue.is_empty()
		return
	if huge_pending >= 0.0:
		huge_pending -= delta
		if huge_pending < 0.0:
			_start_next()
		return
	timer -= delta
	since_wave += delta
	var cleared: bool = wave_index >= 0 and queue.is_empty() and since_wave > maxf(8.0, data.waves[wave_index].duration * 0.5) and level.lanes.real_enemy_count() == 0
	if timer <= 0.0 or cleared:
		var nxt: WaveData = data.waves[wave_index + 1]
		if nxt.is_huge:
			huge_pending = HUGE_WARNING_TIME
			level.on_huge_wave_warning()
		else:
			_start_next()


## Empieza la siguiente oleada ya (usado por el modo autotest).
func skip_wait() -> void:
	timer = 0.0


func _start_next() -> void:
	huge_pending = -1.0
	wave_index += 1
	var w: WaveData = data.waves[wave_index]
	since_wave = 0.0
	timer = w.duration
	var gap := 0.0
	for g in w.groups:
		var count := int(g.get("count", 1))
		var interval := float(g.get("interval", 1.5))
		var start := clock + float(g.get("delay", gap))
		for i in count:
			queue.append({"time": start + i * interval, "robot": String(g.get("robot", "scriptbot")), "lane": int(g.get("lane", -1))})
		gap += 1.2 if w.is_huge else 2.0
	queue.sort_custom(func(a, b): return a["time"] < b["time"])
	wave_started.emit(wave_index, w.is_huge)


func _process_queue() -> void:
	while not queue.is_empty() and float(queue[0]["time"]) <= clock:
		var e: Dictionary = queue.pop_front()
		var l := int(e["lane"])
		if not level.is_lane_active(l):
			l = _pick_lane()
		level.spawn_robot(String(e["robot"]), l, Grid.SPAWN_X + randf_range(0.0, 30.0))


func _pick_lane() -> int:
	var lanes: Array = Array(level.active_lanes)
	if lanes.size() > 1 and lanes.has(last_lane) and randf() < 0.7:
		lanes.erase(last_lane)
	last_lane = lanes.pick_random()
	return last_lane
