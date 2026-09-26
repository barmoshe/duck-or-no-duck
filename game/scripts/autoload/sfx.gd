extends Node
## Autoload "Sfx": every sound is synthesized into an AudioStreamWAV (no audio files).
## Three music loops (day, night, boss) are built a slice per frame after boot and
## crossfade with the game's state. Phone speakers can't play much below 250 Hz, so
## basses sit higher. Web uses Stream playback (project setting), which is what works.

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}
var _music := {}  # name -> AudioStreamPlayer
var _bufs := {}  # name -> PackedFloat32Array being built
var _pos := {}
var _want := "day"
var _order := ["day", "night", "boss"]
var muffle := 0.0  # dB added to every sound and the music (a Deafening mushroom)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build_all()
	for m in _order:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		add_child(mp)
		_music[m] = mp
		var b := PackedFloat32Array()
		b.resize(RATE * (16 if m != "boss" else 8))
		_bufs[m] = b
		_pos[m] = 0


func _process(dt: float) -> void:
	# build the music a slice at a time
	for m in _order:
		var b: PackedFloat32Array = _bufs[m]
		if int(_pos[m]) < b.size():
			_music_slice(m, 5000)
			if int(_pos[m]) >= b.size():
				(_music[m] as AudioStreamPlayer).stream = _wav(_bufs[m], true)
				(_music[m] as AudioStreamPlayer).play()
			break
	for m in _order:
		var mp: AudioStreamPlayer = _music[m]
		var target := (-13.0 + muffle) if (m == _want and Game.music and Game.sound) else -60.0
		mp.volume_db = move_toward(mp.volume_db, target, dt * 30.0)


func music(name: String) -> void:
	_want = name


func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not Game.sound or not _streams.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, 0)) < 40:
		return
	_last[name] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.volume_db = vol_db + muffle
	p.play()


func _build_all() -> void:
	_streams["chomp"] = _wav(_mix([_tone(260, 130, 0.09, 0.6, "sine"), _noise(0.05, 0.35, 0.6)]))
	_streams["thud"] = _wav(_mix([_tone(300, 150, 0.12, 0.7, "sine"), _noise(0.06, 0.3, 0.3)]))
	_streams["whip"] = _wav(_noise(0.14, 0.5, 0.15, true))
	_streams["spit"] = _wav(_mix([_tone(700, 300, 0.1, 0.35, "square"), _noise(0.08, 0.2, 0.5)]))
	_streams["peck"] = _wav(_tone(1400, 900, 0.04, 0.4, "square"))
	_streams["snap"] = _wav(_mix([_tone(900, 400, 0.05, 0.5, "square"), _noise(0.04, 0.4, 0.8)]))
	_streams["song"] = _wav(_arp([659.0, 784.0, 988.0], 0.07, 0.25))
	_streams["quack"] = _wav(_quack(1.0))
	_streams["quack_big"] = _wav(_quack(0.6))
	_streams["honk"] = _wav(_honk())
	_streams["pop"] = _wav(_tone(500, 1000, 0.08, 0.45, "sine"))
	_streams["slurp"] = _wav(_tone(350, 750, 0.1, 0.35, "sine"))
	_streams["hurt"] = _wav(_mix([_tone(420, 180, 0.16, 0.45, "square"), _noise(0.1, 0.25, 0.4)]))
	_streams["dash"] = _wav(_noise(0.18, 0.45, 0.2, true))
	_streams["flap"] = _wav(_noise(0.28, 0.5, 0.12, true))
	_streams["splash"] = _wav(_mix([_noise(0.3, 0.5, 0.5), _tone(600, 250, 0.2, 0.2, "sine")]))
	_streams["levelup"] = _wav(_arp([523.0, 659.0, 784.0, 1047.0], 0.07, 0.3))
	_streams["evolve"] = _wav(_arp([784.0, 988.0, 1175.0, 1568.0], 0.06, 0.3))
	_streams["stage"] = _wav(_arp([392.0, 523.0, 659.0, 784.0, 1047.0], 0.08, 0.3))
	_streams["mutagen"] = _wav(_arp([988.0, 1319.0], 0.05, 0.3))
	_streams["poi"] = _wav(_arp([659.0, 880.0, 1175.0], 0.08, 0.3))
	_streams["heal"] = _wav(_arp([523.0, 784.0, 1047.0], 0.1, 0.25))
	_streams["die"] = _wav(_tone(520, 120, 0.7, 0.45, "square"))
	_streams["click"] = _wav(_tone(1100, 1300, 0.03, 0.3, "square"))
	_streams["win"] = _wav(_arp([523.0, 659.0, 784.0, 1047.0, 784.0, 1047.0, 1319.0, 1568.0], 0.12, 0.3))
	_streams["hiss"] = _wav(_noise(0.3, 0.35, 0.9))
	_streams["boss"] = _wav(_mix([_tone(330, 250, 0.8, 0.4, "square"), _tone(495, 370, 0.8, 0.25, "square")]))
	_streams["night"] = _wav(_arp([440.0, 330.0, 262.0], 0.2, 0.25))
	_streams["wind"] = _wav(_noise(0.9, 0.35, 0.1, true))


# ------------------------------------------------------------------ synthesis
func _wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = buf.size()
	return w


func _env(t: float, dur: float, atk: float = 0.004) -> float:
	if t < atk:
		return t / atk
	return pow(maxf(0.0, 1.0 - (t - atk) / maxf(0.001, dur - atk)), 1.6)


func _osc(ph: float, kind: String) -> float:
	match kind:
		"square":
			return 1.0 if fposmod(ph, 1.0) < 0.5 else -1.0
		"saw":
			return fposmod(ph, 1.0) * 2.0 - 1.0
		"tri":
			return absf(fposmod(ph, 1.0) * 4.0 - 2.0) - 1.0
	return sin(ph * TAU)


func _tone(f0: float, f1: float, dur: float, amp: float, kind: String) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += lerpf(f0, f1, t / dur) / RATE
		b[i] = _osc(ph, kind) * _env(t, dur) * amp * (0.6 if kind == "square" else 1.0)
	return b


func _noise(dur: float, amp: float, bright: float, swell: bool = false) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var b := PackedFloat32Array()
	b.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * bright
		var e := sin(t / dur * PI) if swell else _env(t, dur, 0.002)
		b[i] = lp * e * amp * 2.0
	return b


func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, (p as PackedFloat32Array).size())
	var b := PackedFloat32Array()
	b.resize(n)
	for p in parts:
		var pb: PackedFloat32Array = p
		for i in pb.size():
			b[i] += pb[i]
	return b


func _arp(freqs: Array, step: float, amp: float) -> PackedFloat32Array:
	var note := step * 2.5
	var n := int(RATE * (step * freqs.size() + note))
	var b := PackedFloat32Array()
	b.resize(n)
	for k in freqs.size():
		var st := int(k * step * RATE)
		var f := float(freqs[k])
		for i in int(note * RATE):
			if st + i >= n:
				break
			var t := float(i) / RATE
			b[st + i] += (_osc(t * f, "square") * 0.35 + sin(t * f * TAU) * 0.65) * _env(t, note) * amp
	return b


func _quack(pitch: float) -> PackedFloat32Array:
	var dur := 0.26 / pitch
	var n := int(RATE * dur)
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		ph += (620.0 - 260.0 * u + 70.0 * sin(u * 10.0)) * pitch / RATE
		var nasal := _osc(ph, "saw") * (0.55 + 0.45 * sin(ph * TAU * 3.0))
		b[i] = nasal * minf(1.0, u * 25.0) * pow(maxf(0.0, 1.0 - u), 0.6) * 0.55
	return b


func _honk() -> PackedFloat32Array:
	var dur := 0.4
	var n := int(RATE * dur)
	var b := PackedFloat32Array()
	b.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		ph += (420.0 + 40.0 * sin(u * 30.0)) / RATE
		b[i] = (_osc(ph, "saw") * 0.6 + _osc(ph * 1.5, "square") * 0.3) * minf(1.0, u * 20.0) * pow(1.0 - u, 0.4) * 0.5
	return b


# A soft chiptune loop per mood: pentatonic plucks over a pad, bass kept above 110 Hz.
func _music_slice(m: String, count: int) -> void:
	var b: PackedFloat32Array = _bufs[m]
	var start := int(_pos[m])
	var end := mini(start + count, b.size())
	var chords: Array = {
		"day": [[262.0, 330.0, 392.0], [220.0, 262.0, 330.0], [175.0, 220.0, 262.0], [196.0, 247.0, 294.0]],
		"night": [[220.0, 262.0, 330.0], [175.0, 220.0, 262.0], [196.0, 233.0, 294.0], [165.0, 196.0, 247.0]],
		"boss": [[220.0, 262.0, 330.0], [233.0, 277.0, 349.0], [220.0, 262.0, 330.0], [196.0, 247.0, 294.0]],
	}[m]
	var scale := [523.0, 587.0, 659.0, 784.0, 880.0, 1047.0]
	var beat: float = {"day": 0.25, "night": 0.4, "boss": 0.125}[m]
	var bar_len := 4.0 if m != "boss" else 2.0
	for i in range(start, end):
		var t := float(i) / RATE
		var bar := int(t / bar_len) % 4
		var chord: Array = chords[bar]
		var v := 0.0
		for f in chord:
			v += _osc(t * float(f), "tri") * 0.05
		var bi := int(t / beat)
		var tb := fmod(t, beat)
		var root := float(chord[0]) * (0.5 if m != "boss" else 1.0)
		v += _osc(t * root, "square") * 0.05 * (1.0 if bi % 2 == 0 else 0.6) * exp(-tb * 6.0)
		var h := (bi * 7 + bar * 5) % 11
		if h < (5 if m == "day" else (3 if m == "night" else 7)):
			var f2: float = scale[(bi * 3 + bar * 2) % scale.size()] * (0.5 if m == "night" else 1.0)
			v += _osc(tb * f2, "square") * exp(-tb * 14.0) * 0.1 + sin(tb * f2 * TAU) * exp(-tb * 10.0) * 0.1
		if m == "boss" and bi % 4 == 0:
			v += (randf() * 2.0 - 1.0) * exp(-tb * 40.0) * 0.15
		b[i] = v
	_pos[m] = end
