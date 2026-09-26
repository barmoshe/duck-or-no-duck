extends Node
## Autoload "Sfx": plays the sound effects (made by SfxSynth, no audio files) and the
## three music loops (day, night, boss), which are built a slice per frame after boot and
## crossfade with the game's state. Web uses Stream playback (project setting), so the
## engine mixes and the bus effects below work there too.
##
## Mixing: effects go to the "SFX" bus and music to "Music", both into Master, which has a
## limiter so a pile-up never crackles. Every sound has a level (LEVEL, dB) and a
## priority; a sound picks a free voice, else takes the voice of a lower-priority or older
## sound, so a flurry of hits never cuts off a level-up. A sound with variants plays a
## random one. Deafening runs everything through a low-pass filter; big moments lower the
## music for a moment (duck).

const RATE := SfxSynth.RATE
const VOICES := 16
var _streams := {}  # "name" or "name#v" -> AudioStreamWAV
var _todo: Array = []  # sounds still to build, a few per frame after boot
var _voices: Array = []  # {p: AudioStreamPlayer, name, prio, t}
var _last := {}
var _music := {}  # name -> AudioStreamPlayer
var _bufs := {}  # name -> PackedFloat32Array being built
var _pos := {}
var _want := "day"
var _order := ["day", "night", "boss"]
var _duck_db := 0.0
var _duck_t := 0.0
var _sfx_bus := 0
var _music_bus := 0
var deaf := false  # a Deafening mushroom: everything muffled


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_buses()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append({"p": p, "name": "", "prio": 0, "t": 0})
	# the sounds of the first seconds of play first, then the rest
	var first := ["click", "hit", "whiff", "gulp", "bite_fruit", "bite_meat", "bite_fish", "hurt", "kill", "pouch", "eat_done", "dash", "levelup"]
	for name in first + SfxSynth.ALL.keys():
		if name in first and _todo.any(func(j: Array) -> bool: return j[0] == name):
			continue
		for v in int(SfxSynth.VARIANTS.get(name, 1)):
			_todo.append([name, v])
	for m in _order:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		mp.bus = "Music"
		add_child(mp)
		_music[m] = mp
		var b := PackedFloat32Array()
		b.resize(RATE * (16 if m != "boss" else 8))
		_bufs[m] = b
		_pos[m] = 0


## SFX and Music buses into Master; a limiter on Master; a low-pass on each for Deafening.
func _buses() -> void:
	for bus_name in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
			var lp := AudioEffectLowPassFilter.new()
			lp.cutoff_hz = 650.0
			AudioServer.add_bus_effect(i, lp)
			AudioServer.set_bus_effect_enabled(i, 0, false)
	_sfx_bus = AudioServer.get_bus_index("SFX")
	_music_bus = AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim := AudioEffectHardLimiter.new()
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)


func _process(dt: float) -> void:
	# every frame: a slice of music (so it starts right away), then about 3 ms of sound effects
	for m in _order:
		var b: PackedFloat32Array = _bufs[m]
		if int(_pos[m]) < b.size():
			_music_slice(m, 5000)
			if int(_pos[m]) >= b.size():
				var w := SfxSynth.wav(_bufs[m])
				w.loop_mode = AudioStreamWAV.LOOP_FORWARD
				w.loop_end = b.size()
				(_music[m] as AudioStreamPlayer).stream = w
				(_music[m] as AudioStreamPlayer).play()
			break
	var t0 := Time.get_ticks_usec()
	while not _todo.is_empty() and Time.get_ticks_usec() - t0 < 3000:
		var job: Array = _todo.pop_front()
		_ensure(String(job[0]), int(job[1]))
	_duck_t = maxf(0.0, _duck_t - dt)
	if _duck_t <= 0.0:
		_duck_db = move_toward(_duck_db, 0.0, dt * 12.0)
	for m in _order:
		var mp: AudioStreamPlayer = _music[m]
		var target := (-13.0 + _duck_db) if (m == _want and Game.music and Game.sound) else -60.0
		mp.volume_db = move_toward(mp.volume_db, target, dt * 30.0)


func music(name: String) -> void:
	_want = name


## Build one sound now if it isn't built yet.
func _ensure(name: String, v: int) -> AudioStreamWAV:
	var key := name if v == 0 else "%s#%d" % [name, v]
	if not _streams.has(key):
		_streams[key] = SfxSynth.wav(SfxSynth.make(name, v))
	return _streams[key]


func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not Game.sound:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, 0)) < 40:
		return
	_last[name] = now
	var nv := int(SfxSynth.VARIANTS.get(name, 1))
	var stream := _ensure(name, randi() % nv if nv > 1 else 0)
	var prio := int(SfxSynth.PRIORITY.get(name, 1))
	var voice := _voice(name, prio)
	if voice.is_empty():
		return
	var p: AudioStreamPlayer = voice["p"]
	voice["name"] = name
	voice["prio"] = prio
	voice["t"] = now
	p.stream = stream
	p.pitch_scale = pitch * randf_range(0.96, 1.04)
	p.volume_db = float(SfxSynth.LEVEL.get(name, -6.0)) + vol_db
	p.play()
	if SfxSynth.DUCK.has(name):
		var dk: Array = SfxSynth.DUCK[name]
		_duck_db = minf(_duck_db, float(dk[0]))
		_duck_t = maxf(_duck_t, float(dk[1]))


## A voice for a new sound: a free one; else, past this sound's own voice limit, its
## oldest; else the oldest of the lowest priority, if that's not above this one.
func _voice(name: String, prio: int) -> Dictionary:
	var mine: Array = []
	var free := {}
	for vc in _voices:
		var p: AudioStreamPlayer = vc["p"]
		if not p.playing:
			if free.is_empty():
				free = vc
		elif vc["name"] == name:
			mine.append(vc)
	if mine.size() >= int(SfxSynth.MAX_VOICES.get(name, 3)):
		mine.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return int(a["t"]) < int(c["t"]))
		return mine[0]
	if not free.is_empty():
		return free
	var best := {}
	for vc in _voices:
		if int(vc["prio"]) > prio:
			continue
		if best.is_empty() or int(vc["prio"]) < int(best["prio"]) or (int(vc["prio"]) == int(best["prio"]) and int(vc["t"]) < int(best["t"])):
			best = vc
	return best


## Deafening: muffle the sound effects and the music (a low-pass filter), or clear it.
func set_deaf(on: bool) -> void:
	if on == deaf:
		return
	deaf = on
	AudioServer.set_bus_effect_enabled(_sfx_bus, 0, on)
	AudioServer.set_bus_effect_enabled(_music_bus, 0, on)
	AudioServer.set_bus_volume_db(_sfx_bus, -6.0 if on else 0.0)
	AudioServer.set_bus_volume_db(_music_bus, -6.0 if on else 0.0)


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
			v += SfxSynth.osc(t * float(f), "tri") * 0.05
		var bi := int(t / beat)
		var tb := fmod(t, beat)
		var root := float(chord[0]) * (0.5 if m != "boss" else 1.0)
		v += SfxSynth.osc(t * root, "pulse") * 0.05 * (1.0 if bi % 2 == 0 else 0.6) * exp(-tb * 6.0)
		var h := (bi * 7 + bar * 5) % 11
		if h < (5 if m == "day" else (3 if m == "night" else 7)):
			var f2: float = scale[(bi * 3 + bar * 2) % scale.size()] * (0.5 if m == "night" else 1.0)
			v += SfxSynth.osc(tb * f2, "pulse") * exp(-tb * 14.0) * 0.1 + sin(tb * f2 * TAU) * exp(-tb * 10.0) * 0.1
		if m == "boss" and bi % 4 == 0:
			v += (randf() * 2.0 - 1.0) * exp(-tb * 40.0) * 0.15
		b[i] = v
	_pos[m] = end
