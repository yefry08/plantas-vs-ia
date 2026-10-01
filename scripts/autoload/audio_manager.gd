extends Node
## Música original (audio/*.wav, compuesta por tools/generate_music.gd) y efectos
## suaves sintetizados al cargar: ondas senoidales/triangulares filtradas,
## volumen bajo y notas en escala pentatónica para que todo suene agradable.

const MIX_RATE := 22050
const POOL_SIZE := 14
const MUSIC := {
	"menu": "res://audio/music_menu.wav",
	"battle": "res://audio/music_battle.wav",
	"bio": "res://audio/music_bio.wav",
	"boss": "res://audio/music_boss.wav",
}
## Escala pentatónica mayor (semitonos): los soles recogidos seguidos suben por ella.
const PENTA := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
## Volumen relativo de cada efecto (los muy frecuentes, más bajos).
const SFX_GAIN := {
	"shoot": 0.35, "hit": 0.3, "chomp": 0.45, "click": 0.5, "pop": 0.6,
}

var sounds: Dictionary = {}
var chimes: Array[AudioStreamWAV] = []
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var last_played: Dictionary = {}
var muted := false
var music_muted := false
var volume := 0.7
var music_volume := 0.45
var music_player: AudioStreamPlayer
var music_fade: Tween
var current_music := ""
var combo := 0
var combo_time := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	_build_sounds()


# --- Efectos -------------------------------------------------------------------

func play(sound_name: String, pitch_jitter := 0.05) -> void:
	if muted:
		return
	var stream: AudioStreamWAV = null
	if sound_name == "sun":
		stream = _next_chime()
	elif sounds.has(sound_name):
		stream = sounds[sound_name]
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	var min_gap := 70 if sound_name in ["shoot", "hit", "chomp"] else 40
	if now - int(last_played.get(sound_name, -1000)) < min_gap:
		return
	last_played[sound_name] = now
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = stream
	p.volume_db = linear_to_db(maxf(volume * float(SFX_GAIN.get(sound_name, 1.0)), 0.0001))
	p.pitch_scale = 1.0 if sound_name == "sun" else 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## Combo: cada sol recogido en menos de 1.4 s sube una nota de la escala.
func _next_chime() -> AudioStreamWAV:
	var now := Time.get_ticks_msec()
	combo = mini(combo + 1, chimes.size() - 1) if now - combo_time < 1400 else 0
	combo_time = now
	return chimes[combo]


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)


# --- Música --------------------------------------------------------------------

func play_music(track: String) -> void:
	if track == current_music and music_player.playing:
		return
	current_music = track
	if music_muted or not MUSIC.has(track):
		music_player.stop()
		return
	var stream: AudioStream = load(MUSIC[track])
	if stream == null:
		return
	if music_fade:
		music_fade.kill()
	music_player.stream = stream
	music_player.volume_db = -40.0
	music_player.play()
	music_fade = create_tween()
	music_fade.tween_property(music_player, "volume_db", _music_db(), 1.5)


func stop_music() -> void:
	music_player.stop()


func set_music_muted(m: bool) -> void:
	music_muted = m
	if m:
		music_player.stop()
	else:
		var t := current_music
		current_music = ""
		play_music(t)


func _music_db() -> float:
	return linear_to_db(maxf(music_volume, 0.0001))


func _on_music_finished() -> void:
	if not music_muted and current_music != "":
		music_player.play()


# --- Síntesis ------------------------------------------------------------------

func _build_sounds() -> void:
	# Interfaz
	sounds["click"] = _tone([[880.0, 990.0, 0.035]], "sine", 0.35, 0.0, 0.5)
	sounds["error"] = _tone([[330.0, 262.0, 0.12]], "sine", 0.35, 0.0, 0.3)
	# Plantas
	sounds["plant"] = _tone([[196.0, 147.0, 0.14]], "sine", 0.55, 0.15, 0.25, [[392.0, 392.0, 0.08]])
	sounds["shoot"] = _tone([[520.0, 390.0, 0.06]], "sine", 0.3, 0.05, 0.4)
	sounds["hit"] = _tone([[300.0, 240.0, 0.04]], "tri", 0.25, 0.1, 0.25)
	sounds["pop"] = _tone([[392.0, 784.0, 0.09]], "sine", 0.4, 0.0, 0.5)
	sounds["gulp"] = _tone([[330.0, 220.0, 0.16]], "sine", 0.35, 0.0, 0.3)
	sounds["zap"] = _tone([[660.0, 440.0, 0.14]], "tri", 0.22, 0.25, 0.18)
	sounds["emp"] = _tone([[110.0, 330.0, 0.3]], "sine", 0.4, 0.15, 0.15)
	sounds["captcha"] = _tone([[659.0, 659.0, 0.06], [784.0, 784.0, 0.08]], "sine", 0.3, 0.0, 0.4)
	# Recursos
	for st in PENTA:
		chimes.append(_bell(hz(72 + st), 0.35, 0.4))
	sounds["token"] = _tone([[988.0, 988.0, 0.05], [1319.0, 1319.0, 0.14]], "tri", 0.22, 0.0, 0.35)
	# Robots
	sounds["chomp"] = _tone([[150.0, 110.0, 0.08]], "sine", 0.35, 0.3, 0.2)
	sounds["explode"] = _tone([[90.0, 40.0, 0.5]], "sine", 0.6, 0.55, 0.06)
	sounds["hack"] = _tone([[523.0, 392.0, 0.08], [392.0, 330.0, 0.1]], "tri", 0.25, 0.1, 0.2)
	sounds["teleport"] = _tone([[392.0, 1175.0, 0.22]], "sine", 0.3, 0.0, 0.4)
	sounds["think"] = _tone([[523.0, 523.0, 0.08], [0.0, 0.0, 0.06], [659.0, 659.0, 0.1]], "sine", 0.22, 0.0, 0.4)
	sounds["laugh"] = _tone([[294.0, 262.0, 0.08], [0.0, 0.0, 0.03], [330.0, 294.0, 0.08], [0.0, 0.0, 0.03], [349.0, 311.0, 0.1]], "tri", 0.22, 0.0, 0.2)
	sounds["boss"] = _tone([[73.0, 55.0, 1.0]], "tri", 0.6, 0.2, 0.08)
	sounds["mower"] = _tone([[220.0, 247.0, 0.5]], "tri", 0.3, 0.05, 0.2)
	# Avisos y finales (arpegios pentatónicos tipo campana)
	sounds["card"] = _arpeggio([60, 64, 67, 72, 76], 0.07, 0.3)
	sounds["win"] = _arpeggio([60, 64, 67, 72, 76, 79, 84], 0.11, 0.4)
	sounds["lose"] = _arpeggio([67, 63, 60, 55], 0.2, 0.32)
	sounds["siren"] = _tone([[220.0, 220.0, 0.35], [0.0, 0.0, 0.05], [262.0, 262.0, 0.35], [0.0, 0.0, 0.05], [330.0, 330.0, 0.6]], "saw", 0.28, 0.0, 0.06)


static func hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


## segs: [[freq_inicio, freq_fin, duración], ...]. `cutoff` < 1 suaviza (paso bajo).
## `extra` añade un segundo tono simultáneo (cuerpo/armónico).
func _tone(segs: Array, wave := "sine", vol := 0.4, noise := 0.0, cutoff := 0.35, extra: Array = []) -> AudioStreamWAV:
	var buf := _render(segs, wave, vol, noise, cutoff)
	if not extra.is_empty():
		var b2 := _render(extra, "sine", vol * 0.4, 0.0, cutoff)
		for i in mini(buf.size(), b2.size()):
			buf[i] += b2[i]
	return _to_stream(buf)


func _render(segs: Array, wave: String, vol: float, noise: float, cutoff: float) -> PackedFloat32Array:
	var total := 0
	for s in segs:
		total += int(float(s[2]) * MIX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(total + int(0.03 * MIX_RATE))
	var idx := 0
	var phase := 0.0
	var lp := 0.0
	var nz := 0.0
	for s in segs:
		var n := int(float(s[2]) * MIX_RATE)
		var f0 := float(s[0])
		var f1 := float(s[1])
		for i in n:
			var k := float(i) / float(maxi(1, n))
			var f: float = lerpf(f0, f1, k)
			phase += f / MIX_RATE
			var v := 0.0
			if f > 0.0:
				match wave:
					"tri":
						v = absf(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
					"saw":
						v = fmod(phase, 1.0) * 2.0 - 1.0
					_:
						v = sin(phase * TAU)
				if noise > 0.0:
					nz += ((randf() * 2.0 - 1.0) - nz) * 0.2
					v = lerpf(v, nz * 2.0, noise)
			lp += (v - lp) * cutoff
			var attack := minf(1.0, float(i) / (0.006 * MIX_RATE))
			var env := attack * pow(1.0 - k, 1.8)
			buf[idx] = lp * env * vol
			idx += 1
	return buf


## Campana suave: fundamental + armónicos que se apagan rápido.
func _bell(f: float, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * MIX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		var v := sin(t * f * TAU) + 0.4 * sin(t * f * 2.0 * TAU) * exp(-t * 12.0) + 0.2 * sin(t * f * 3.0 * TAU) * exp(-t * 18.0)
		var env := minf(1.0, t / 0.004) * exp(-t * 7.0)
		buf[i] = v * env * vol * 0.6
	return _to_stream(buf)


func _arpeggio(notes: Array, step: float, vol: float) -> AudioStreamWAV:
	var tail := 0.5
	var n := int((step * notes.size() + tail) * MIX_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for j in notes.size():
		var f := hz(float(notes[j]))
		var i0 := int(j * step * MIX_RATE)
		for i in int(tail * MIX_RATE):
			var idx := i0 + i
			if idx >= n:
				break
			var t := float(i) / MIX_RATE
			var v := sin(t * f * TAU) + 0.3 * sin(t * f * 2.0 * TAU) * exp(-t * 10.0)
			buf[idx] += v * minf(1.0, t / 0.004) * exp(-t * 6.0) * vol * 0.5
	return _to_stream(buf)


func _to_stream(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(tanh(buf[i]), -1.0, 1.0) * 30000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
