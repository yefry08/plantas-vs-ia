extends Node
## Efectos de sonido sintetizados en tiempo de carga (sin assets externos).

const MIX_RATE := 22050
const POOL_SIZE := 12

var sounds: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var last_played: Dictionary = {}
var muted := false
var volume := 0.7


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	_build_sounds()


func play(sound_name: String, pitch_jitter := 0.06) -> void:
	if muted or not sounds.has(sound_name):
		return
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(sound_name, -1000)) < 45:
		return
	last_played[sound_name] = now
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = sounds[sound_name]
	p.volume_db = linear_to_db(max(volume, 0.001))
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func set_volume(v: float) -> void:
	volume = clamp(v, 0.0, 1.0)


func _build_sounds() -> void:
	sounds["click"] = _synth([[900.0, 700.0, 0.04]], "square", 0.25)
	sounds["plant"] = _synth([[180.0, 90.0, 0.12]], "sine", 0.7, 0.25)
	sounds["shoot"] = _synth([[520.0, 260.0, 0.06]], "tri", 0.35)
	sounds["hit"] = _synth([[300.0, 160.0, 0.05]], "square", 0.18, 0.4)
	sounds["sun"] = _synth([[660.0, 660.0, 0.06], [990.0, 990.0, 0.1]], "sine", 0.4)
	sounds["token"] = _synth([[1200.0, 1200.0, 0.05], [1600.0, 1600.0, 0.12]], "square", 0.2)
	sounds["chomp"] = _synth([[140.0, 90.0, 0.07]], "saw", 0.3, 0.5)
	sounds["explode"] = _synth([[120.0, 40.0, 0.45]], "saw", 0.6, 0.85)
	sounds["pop"] = _synth([[400.0, 120.0, 0.12]], "sine", 0.45, 0.3)
	sounds["zap"] = _synth([[1400.0, 300.0, 0.18]], "square", 0.25, 0.55)
	sounds["emp"] = _synth([[80.0, 600.0, 0.3]], "sine", 0.5, 0.2)
	sounds["card"] = _synth([[523.0, 523.0, 0.07], [659.0, 659.0, 0.07], [784.0, 784.0, 0.07], [1047.0, 1047.0, 0.14]], "tri", 0.4)
	sounds["error"] = _synth([[180.0, 150.0, 0.14]], "square", 0.25)
	sounds["mower"] = _synth([[90.0, 140.0, 0.6]], "saw", 0.45, 0.35)
	sounds["siren"] = _synth([[500.0, 900.0, 0.35], [900.0, 500.0, 0.35], [500.0, 900.0, 0.35]], "tri", 0.4)
	sounds["win"] = _synth([[523.0, 523.0, 0.12], [659.0, 659.0, 0.12], [784.0, 784.0, 0.12], [1047.0, 1047.0, 0.4]], "tri", 0.5)
	sounds["lose"] = _synth([[400.0, 380.0, 0.25], [300.0, 280.0, 0.25], [200.0, 120.0, 0.6]], "saw", 0.4)
	sounds["gulp"] = _synth([[260.0, 520.0, 0.14]], "sine", 0.45)
	sounds["captcha"] = _synth([[700.0, 700.0, 0.05], [500.0, 500.0, 0.05], [700.0, 700.0, 0.05]], "square", 0.2)
	sounds["hack"] = _synth([[1000.0, 200.0, 0.25]], "square", 0.22, 0.6)
	sounds["teleport"] = _synth([[200.0, 1800.0, 0.2]], "sine", 0.4)
	sounds["think"] = _synth([[440.0, 440.0, 0.08], [0.0, 0.0, 0.05], [440.0, 440.0, 0.08]], "sine", 0.25)
	sounds["laugh"] = _synth([[300.0, 250.0, 0.08], [0.0, 0.0, 0.03], [320.0, 260.0, 0.08], [0.0, 0.0, 0.03], [340.0, 270.0, 0.1]], "saw", 0.25)
	sounds["boss"] = _synth([[60.0, 45.0, 0.9]], "saw", 0.6, 0.3)


## segs: [[freq_inicio, freq_fin, duración], ...]
func _synth(segs: Array, wave := "sine", vol := 0.5, noise := 0.0) -> AudioStreamWAV:
	var total := 0
	for s in segs:
		total += int(float(s[2]) * MIX_RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var idx := 0
	var phase := 0.0
	for s in segs:
		var n := int(float(s[2]) * MIX_RATE)
		var f0 := float(s[0])
		var f1 := float(s[1])
		for i in n:
			var k := float(i) / float(max(1, n))
			var f: float = lerp(f0, f1, k)
			phase += f / MIX_RATE
			var v := 0.0
			if f > 0.0:
				match wave:
					"square":
						v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
					"saw":
						v = fmod(phase, 1.0) * 2.0 - 1.0
					"tri":
						v = abs(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
					_:
						v = sin(phase * TAU)
				if noise > 0.0:
					v = lerp(v, randf() * 2.0 - 1.0, noise)
			var attack: float = min(1.0, float(i) / (0.004 * MIX_RATE))
			var env: float = attack * pow(1.0 - k, 1.4)
			var sample := int(clamp(v * env * vol, -1.0, 1.0) * 32767.0)
			data.encode_s16(idx * 2, sample)
			idx += 1
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
