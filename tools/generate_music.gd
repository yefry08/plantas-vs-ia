extends SceneTree
## Compone y renderiza la música ORIGINAL del juego a audio/*.wav (se ejecuta una vez).
## Estilo: épica de apocalipsis — ostinato tenso en menor, tambores de guerra,
## pads graves y un motivo que crece. Todo sintetizado aquí, sin samples externos.
## Uso: godot --headless --path . --script res://tools/generate_music.gd

const RATE := 22050

# Notas MIDI -> Hz
static func hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


class Track:
	const RATE := 22050

	static func hz(m: float) -> float:
		return 440.0 * pow(2.0, (m - 69.0) / 12.0)

	var buf := PackedFloat32Array()
	var bpm := 120.0
	var beat := 0.5

	func _init(bars: int, tempo: float) -> void:
		bpm = tempo
		beat = 60.0 / tempo
		buf.resize(int(bars * 4 * beat * RATE) + RATE)

	func secs(beats: float) -> float:
		return beats * beat

	## Nota con forma de onda suave, envolvente y filtro paso bajo de un polo.
	func note(start: float, dur: float, m: float, vol: float, wave := "tri", attack := 0.01, release := 0.12, cutoff := 0.25, vibrato := 0.0) -> void:
		var f := hz(m)
		var i0 := int(start * RATE)
		var n := int((dur + release) * RATE)
		var phase := randf()
		var lp := 0.0
		for i in n:
			var idx := i0 + i
			if idx < 0 or idx >= buf.size():
				break
			var tt := float(i) / RATE
			var ff := f * (1.0 + vibrato * sin(tt * TAU * 5.5) * minf(1.0, tt * 2.0))
			phase += ff / RATE
			var p := fmod(phase, 1.0)
			var v := 0.0
			match wave:
				"saw":
					v = p * 2.0 - 1.0
				"square":
					v = 1.0 if p < 0.5 else -1.0
				"sine":
					v = sin(phase * TAU)
				"bell":
					v = sin(phase * TAU) + 0.35 * sin(phase * TAU * 2.0) * exp(-tt * 6.0) + 0.15 * sin(phase * TAU * 3.01) * exp(-tt * 9.0)
				_:
					v = absf(p * 4.0 - 2.0) - 1.0
			lp += (v - lp) * cutoff
			var env := minf(1.0, tt / maxf(attack, 0.001))
			if tt > dur:
				env *= maxf(0.0, 1.0 - (tt - dur) / release)
			buf[idx] += lp * env * vol

	func kick(start: float, vol := 0.8) -> void:
		var i0 := int(start * RATE)
		var phase := 0.0
		for i in int(0.35 * RATE):
			var idx := i0 + i
			if idx >= buf.size():
				break
			var tt := float(i) / RATE
			phase += (45.0 + 110.0 * exp(-tt * 28.0)) / RATE
			buf[idx] += sin(phase * TAU) * exp(-tt * 9.0) * vol

	## Tambor de guerra / tom: tono grave + ruido filtrado.
	func tom(start: float, m: float, vol := 0.6) -> void:
		var i0 := int(start * RATE)
		var phase := 0.0
		var lp := 0.0
		var f := hz(m)
		for i in int(0.5 * RATE):
			var idx := i0 + i
			if idx >= buf.size():
				break
			var tt := float(i) / RATE
			phase += f * (1.0 + 0.5 * exp(-tt * 20.0)) / RATE
			lp += ((randf() * 2.0 - 1.0) - lp) * 0.08
			buf[idx] += (sin(phase * TAU) * 0.8 + lp * 0.6) * exp(-tt * 6.0) * vol

	func snare(start: float, vol := 0.35) -> void:
		var i0 := int(start * RATE)
		var lp := 0.0
		for i in int(0.22 * RATE):
			var idx := i0 + i
			if idx >= buf.size():
				break
			var tt := float(i) / RATE
			lp += ((randf() * 2.0 - 1.0) - lp) * 0.35
			buf[idx] += (lp * 0.8 + sin(tt * TAU * 190.0) * 0.4) * exp(-tt * 18.0) * vol

	func hat(start: float, vol := 0.08) -> void:
		var i0 := int(start * RATE)
		var prev := 0.0
		for i in int(0.05 * RATE):
			var idx := i0 + i
			if idx >= buf.size():
				break
			var tt := float(i) / RATE
			var nz := randf() * 2.0 - 1.0
			buf[idx] += (nz - prev) * 0.5 * exp(-tt * 60.0) * vol
			prev = nz

	## Barrido de ruido ascendente (transición antes de una sección).
	func riser(start: float, dur: float, vol := 0.15) -> void:
		var i0 := int(start * RATE)
		var lp := 0.0
		for i in int(dur * RATE):
			var idx := i0 + i
			if idx >= buf.size():
				break
			var k := float(i) / (dur * RATE)
			lp += ((randf() * 2.0 - 1.0) - lp) * (0.02 + 0.3 * k)
			buf[idx] += lp * k * k * vol

	func save(path: String, length_beats: float) -> void:
		var frames := int(length_beats * beat * RATE)
		var peak := 0.001
		for i in frames:
			peak = maxf(peak, absf(buf[i]))
		var gain := 0.85 / peak
		var data := PackedByteArray()
		data.resize(frames * 2)
		# Pequeño fundido al final y al inicio para que el bucle no haga clic.
		var fade := int(0.02 * RATE)
		for i in frames:
			var v := tanh(buf[i] * gain * 1.2)
			if i < fade:
				v *= float(i) / fade
			elif i > frames - fade:
				v *= float(frames - i) / fade
			data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
		var s := AudioStreamWAV.new()
		s.format = AudioStreamWAV.FORMAT_16_BITS
		s.mix_rate = RATE
		s.stereo = false
		s.data = data
		var err := s.save_to_wav(path)
		print("Guardado %s (%.1f s) err=%d" % [path, frames / float(RATE), err])


# Progresión en menor: i - VI - III - VII (raíces relativas a la tónica)
const PROG := [0, -4, 3, -2]
const CHORDS := [[0, 3, 7], [-4, 0, 3], [3, 7, 10], [-2, 2, 5]]


func _init() -> void:
	seed(20261001)
	DirAccess.make_dir_recursive_absolute("res://audio")
	_battle("res://audio/music_battle.wav", 50, 128.0)   # D menor
	_battle("res://audio/music_bio.wav", 52, 124.0, true)   # E menor, más oscura
	_boss("res://audio/music_boss.wav", 50, 146.0)
	_menu("res://audio/music_menu.wav", 50, 84.0)
	quit()


## Batalla: 16 compases. A = ostinato + tambores; B = entra el motivo y los toms de guerra.
func _battle(path: String, tonic: int, bpm: float, dark := false) -> void:
	var tr := Track.new(16, bpm)
	for bar in 16:
		var chord_i: int = bar % 4
		var root: int = tonic - 12 + PROG[chord_i]
		var b0 := bar * 4.0
		var section_b := bar >= 8
		# Ostinato de semicorcheas (cuerdas "spiccato"): raíz, raíz, quinta, octava...
		var pattern := [0, 0, 7, 0, 12, 0, 7, 3] if not dark else [0, 0, 6, 0, 12, 0, 7, 1]
		for s in 16:
			var m: int = root + 12 + pattern[s % 8]
			var accent := 1.0 if s % 4 == 0 else 0.6
			tr.note(tr.secs(b0 + s * 0.25), tr.secs(0.18), m, 0.11 * accent, "saw", 0.004, 0.05, 0.12)
		# Bajo pulsante en corcheas
		for e in 8:
			tr.note(tr.secs(b0 + e * 0.5), tr.secs(0.4), root, 0.22, "tri", 0.005, 0.08, 0.2)
		# Pad del acorde
		for iv in CHORDS[chord_i]:
			tr.note(tr.secs(b0), tr.secs(3.8), tonic + iv, 0.05, "saw", 0.4, 0.6, 0.04)
		# Batería
		tr.kick(tr.secs(b0))
		tr.kick(tr.secs(b0 + 2.0), 0.7)
		if section_b:
			tr.kick(tr.secs(b0 + 2.75), 0.5)
		tr.snare(tr.secs(b0 + 1.0))
		tr.snare(tr.secs(b0 + 3.0))
		for h in 8:
			tr.hat(tr.secs(b0 + h * 0.5 + 0.25), 0.06)
		if section_b or bar % 4 == 3:
			tr.tom(tr.secs(b0 + 3.0), tonic - 17, 0.5)
			tr.tom(tr.secs(b0 + 3.5), tonic - 19, 0.5)
			tr.tom(tr.secs(b0 + 3.75), tonic - 22, 0.6)
	# Motivo heroico original (sección B): sube, duda, cae, vuelve a subir.
	var motif := [[0, 1.5, 0], [1.5, 0.5, 2], [2, 2, 3], [4, 1.5, 7], [5.5, 0.5, 5], [6, 2, 3],
		[8, 1.5, 0], [9.5, 0.5, 3], [10, 2, 7], [12, 3, 10], [15, 1, 8]]
	for rep in 2:
		for mt in motif:
			var start: float = 32.0 + rep * 16.0 + float(mt[0])
			tr.note(tr.secs(start), tr.secs(float(mt[1]) * 0.95), tonic + 12 + int(mt[2]), 0.13, "square", 0.03, 0.25, 0.07, 0.006)
			tr.note(tr.secs(start), tr.secs(float(mt[1]) * 0.95), tonic + int(mt[2]), 0.08, "tri", 0.03, 0.25, 0.15)
	tr.riser(tr.secs(28.0), tr.secs(4.0))
	tr.save(path, 64.0)


func _boss(path: String, tonic: int, bpm: float) -> void:
	var tr := Track.new(16, bpm)
	for bar in 16:
		var chord_i: int = [0, 0, 1, 3][bar % 4]
		var root: int = tonic - 12 + PROG[chord_i]
		var b0 := bar * 4.0
		for s in 16:
			var m: int = root + 12 + [0, 1, 0, 7, 0, 1, 12, 6][s % 8]
			tr.note(tr.secs(b0 + s * 0.25), tr.secs(0.16), m, 0.12, "saw", 0.003, 0.04, 0.14)
		for e in 8:
			tr.note(tr.secs(b0 + e * 0.5), tr.secs(0.42), root - 12, 0.25, "tri", 0.004, 0.06, 0.25)
		for k in [0.0, 0.75, 1.5, 2.0, 2.75, 3.5]:
			tr.kick(tr.secs(b0 + k), 0.75)
		tr.snare(tr.secs(b0 + 1.0), 0.4)
		tr.snare(tr.secs(b0 + 3.0), 0.4)
		for t16 in 4:
			tr.tom(tr.secs(b0 + 3.0 + t16 * 0.25), tonic - 15 - t16 * 2, 0.45)
		for iv in CHORDS[chord_i]:
			tr.note(tr.secs(b0), tr.secs(3.8), tonic - 12 + iv, 0.06, "saw", 0.2, 0.5, 0.05)
		if bar >= 8:
			var lead := [0, 3, 1, 0] if bar % 2 == 0 else [7, 6, 3, 1]
			for q in 4:
				tr.note(tr.secs(b0 + q), tr.secs(0.9), tonic + 12 + lead[q], 0.12, "square", 0.02, 0.15, 0.08, 0.008)
	tr.riser(tr.secs(28.0), tr.secs(4.0), 0.2)
	tr.save(path, 64.0)


## Menú: más calmado pero con tensión — arpegio de campanas, pad y tambor lejano.
func _menu(path: String, tonic: int, bpm: float) -> void:
	var tr := Track.new(16, bpm)
	for bar in 16:
		var chord_i: int = bar % 4
		var b0 := bar * 4.0
		var ch: Array = CHORDS[chord_i]
		for e in 8:
			var iv: int = ch[[0, 1, 2, 1, 0, 2, 1, 2][e]] + (12 if e >= 4 else 0)
			tr.note(tr.secs(b0 + e * 0.5), tr.secs(0.45), tonic + 12 + iv, 0.1, "bell", 0.005, 0.5, 0.35)
		for iv in ch:
			tr.note(tr.secs(b0), tr.secs(3.9), tonic - 12 + iv, 0.07, "saw", 0.8, 0.8, 0.03)
		tr.note(tr.secs(b0), tr.secs(3.5), tonic - 24 + PROG[chord_i], 0.18, "sine", 0.05, 0.4, 0.3)
		tr.tom(tr.secs(b0), tonic - 24, 0.35)
		if bar % 2 == 1:
			tr.tom(tr.secs(b0 + 2.5), tonic - 26, 0.25)
		if bar >= 8:
			tr.hat(tr.secs(b0 + 1.0), 0.05)
			tr.hat(tr.secs(b0 + 3.0), 0.05)
	tr.save(path, 64.0)
