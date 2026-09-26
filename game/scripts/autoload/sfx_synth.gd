class_name SfxSynth
extends RefCounted
## Every sound effect in the game, synthesized from code (no audio files). Sfx plays them;
## tests/sfx_board.gd renders them all to WAV for review.
##
## The kit: tones with exponential pitch glides, FM (bells, wood knocks, bonks), noise
## through a state-variable filter (whooshes, crunches, water), and an echo. Each recipe
## layers a transient (the click you hear first), a body (the pitch) and a tail. finish()
## sets every sound to the same loudness under a peak ceiling, so Sfx.LEVEL alone mixes
## them. Phone speakers barely play below 250 Hz: bodies sit above that, with harmonics
## where a thump needs weight. Same name and variant always give the same sound.

const RATE := 22050

## How many versions a sound has; Sfx picks one at random so repeats don't sound identical.
const VARIANTS := {
	"hit": 3, "bite_fruit": 3, "bite_meat": 3, "bite_fish": 2, "crunch": 2, "bonk": 2, "kick": 2,
	"peck": 2, "whiff": 2, "fwip": 2, "gulp": 2, "hurt": 2, "click": 1,
}

## Mix level of each sound, in dB. Sounds are built equally loud; this is the mix.
const LEVEL := {
	"click": -5.0, "levelup": -3.0, "evolve": -3.0, "stage": -3.0, "win": -2.0, "die": -2.0, "poi": -4.0,
	"mutagen": -6.0, "heal": -7.0, "night": -5.0, "boss": -2.0,
	"bite_fruit": -6.5, "bite_meat": -10.0, "bite_fish": -7.0, "eat_done": -8.0, "pouch": -10.0, "rustle": -9.0,
	"splash": -7.5, "shroom": -6.5,
	"gulp": -6.5, "bonk": -4.0, "crunch": -5.0, "swoosh": -6.0, "spit": -6.0, "charge": -4.0, "zip": -5.0,
	"peck": -6.0, "toss": -6.0, "mud": -5.0, "snip": -4.0, "song": -5.0, "lash": -6.0, "kick": -2.5,
	"squeeze": -6.0, "fwip": -6.0, "quack": -4.0, "quack_big": -2.0, "honk": -3.0,
	"tell": -10.0, "whiff": -10.5, "hit": -7.5, "crit": -2.0, "kill": -4.5, "hurt": -2.0, "crack": -4.0,
	"splat": -9.0, "poison": -10.0, "stun": -11.0,
	"dash": -8.0, "flap": -8.0, "hiss": -8.0, "wind": -10.0, "thud": -4.0,
}
## Who keeps a voice when all are busy: higher wins.
const PRIORITY := {
	"levelup": 3, "evolve": 3, "stage": 3, "win": 3, "die": 3, "boss": 3, "poi": 3, "night": 2, "hurt": 2,
	"crit": 2, "kill": 2, "heal": 2, "mutagen": 2, "click": 3,
}
## Most voices one sound may hold at once (default 3).
const MAX_VOICES := {"hit": 3, "whiff": 2, "tell": 1, "stun": 1, "poison": 2, "fwip": 3, "peck": 3}
## Stingers that lower the music while they play: dB and seconds.
const DUCK := {"levelup": [-8.0, 1.0], "evolve": [-8.0, 1.0], "stage": [-8.0, 1.0], "win": [-12.0, 2.0],
	"die": [-12.0, 1.2], "boss": [-10.0, 1.3], "poi": [-6.0, 0.8]}

## Every sound, with what it's for (the board prints these).
const ALL := {
	# ui and moments
	"click": "a button: a soft wood block",
	"levelup": "level up: a rising bell arpeggio with a shimmer",
	"evolve": "an evolution taken: a swoop up into a bright chord",
	"stage": "metamorphosis: a marimba run",
	"win": "the final boss is down: a little fanfare",
	"die": "you died: a sad falling wobble",
	"poi": "a ? spot opens: three magic chimes",
	"mutagen": "mutagen picked up: two sparkles",
	"heal": "healing: a warm rising pair",
	"night": "nightfall: low bells falling",
	"boss": "a boss arrives: an ominous horn",
	# eating
	"bite_fruit": "a bite of fruit: a crisp crunch",
	"bite_meat": "a bite of meat: a juicy chomp",
	"bite_fish": "a bite of fish: a wet slurp",
	"eat_done": "nothing left to eat: a gulp and a ding",
	"pouch": "food into the Cheek Pouch: a cheeky pop",
	"rustle": "a bumped tree drops fruit: leaves and a pop",
	"splash": "water: a splash with bubbles",
	"shroom": "a mushroom eaten: a squishy gulp",
	# player attacks (Attacks.ATTACK sfx)
	"gulp": "Gulp: a quick boing-gulp",
	"bonk": "Headbutt: a hollow wooden bonk",
	"crunch": "Jaws: a crunchy bite",
	"swoosh": "Tail Whip: a wide whoosh",
	"spit": "Spit: a wet ptoo",
	"charge": "Charge: a rushing rumble",
	"zip": "Stinger: a fast zip",
	"peck": "Peck Flurry: a woodpecker tik",
	"toss": "Egg Toss: an underhand throw",
	"mud": "Mud Splash: a squelch",
	"snip": "Pincer Snap: two sharp snips",
	"song": "Charm Song: a lullaby",
	"lash": "Tentacle Lash: a wet whip",
	"kick": "Kick: a thwack",
	"squeeze": "Constrict: a creaking squeeze",
	"fwip": "Feather Darts: a soft fwip",
	"quack": "Quack: the quack",
	# combat feedback
	"tell": "a heavy attack winding up: a short rising blip",
	"whiff": "an attack that hits nothing: a light swish",
	"hit": "your attack lands: a punchy impact",
	"crit": "a critical hit: impact and a bright ping",
	"kill": "an animal falls: a pop and a sparkle",
	"hurt": "you get hurt: a squishy oof",
	"crack": "the egg lands: a crack and a splat",
	"splat": "the spit glob lands: a splat",
	"poison": "a poison dart lands: bubbling",
	"stun": "something is stunned: tweeting birds",
	# movement, animals, world
	"dash": "a dash: a whoosh",
	"flap": "wings: three flaps",
	"quack_big": "a big quack (the Great Mallard, Mega Quack)",
	"honk": "a goose honk",
	"hiss": "a hiss (a predator notices you)",
	"wind": "a gust (weather)",
	"thud": "something heavy lands: a thud",
}


# ------------------------------------------------------------------ building blocks
static func buf(dur: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(RATE * dur))
	return b


static func env(t: float, dur: float, atk: float = 0.004, curve: float = 1.6) -> float:
	if t < atk:
		return t / atk
	return pow(maxf(0.0, 1.0 - (t - atk) / maxf(0.001, dur - atk)), curve)


## Wave shapes. "pulse" is a rounded square: chiptune colour without the buzz.
static func osc(ph: float, wave: String) -> float:
	match wave:
		"pulse":
			return tanh(sin(ph * TAU) * 3.0) * 1.0037
		"saw":
			return fposmod(ph, 1.0) * 2.0 - 1.0
		"tri":
			return absf(fposmod(ph, 1.0) * 4.0 - 2.0) - 1.0
	return sin(ph * TAU)


## A tone gliding from f0 to f1 (exponentially: it sounds even), optional vibrato.
static func tone(b: PackedFloat32Array, at: float, dur: float, f0: float, f1: float, amp: float,
		wave: String = "sine", atk: float = 0.004, curve: float = 1.6, vib: float = 0.0, vib_hz: float = 0.0) -> void:
	var s0 := int(at * RATE)
	var n := int(dur * RATE)
	var ph := 0.0
	for i in n:
		var k := s0 + i
		if k >= b.size():
			break
		var t := float(i) / RATE
		var f := f0 * pow(f1 / f0, t / dur)
		if vib > 0.0:
			f *= 1.0 + vib * sin(TAU * vib_hz * t)
		ph += f / RATE
		b[k] += osc(ph, wave) * env(t, dur, atk, curve) * amp


## FM: a carrier bent by a modulator whose depth dies away fast. Low index = soft bell,
## ratio 1.4-2.4 with a quick index decay = wood and hollow knocks.
static func fm(b: PackedFloat32Array, at: float, dur: float, fc: float, ratio: float, index: float, amp: float,
		decay: float = 10.0, idecay: float = 14.0, fc_end: float = 0.0) -> void:
	var s0 := int(at * RATE)
	var n := int(dur * RATE)
	var cph := 0.0
	var mph := 0.0
	for i in n:
		var k := s0 + i
		if k >= b.size():
			break
		var t := float(i) / RATE
		var f := fc if fc_end <= 0.0 else fc * pow(fc_end / fc, t / dur)
		cph += f / RATE
		mph += f * ratio / RATE
		var m := sin(mph * TAU) * index * exp(-t * idecay)
		var a := minf(1.0, t / 0.0015) * exp(-t * decay) * minf(1.0, (dur - t) / 0.01)
		b[k] += sin(cph * TAU + m) * a * amp


## Noise through a state-variable filter ("lp", "bp", "hp"); the cutoff can sweep f0 -> f1.
## q is damping: lower rings more. swell fades in and out instead of hitting at once.
static func noise(b: PackedFloat32Array, at: float, dur: float, amp: float, mode: String = "bp", f0: float = 1000.0,
		f1: float = 0.0, q: float = 0.8, seed: int = 1, swell: bool = false, atk: float = 0.002, curve: float = 1.6) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var s0 := int(at * RATE)
	var n := int(dur * RATE)
	var low := 0.0
	var band := 0.0
	for i in n:
		var k := s0 + i
		if k >= b.size():
			break
		var t := float(i) / RATE
		var u := t / dur
		var fc := clampf(f0 if f1 <= 0.0 else f0 * pow(f1 / f0, u), 40.0, 3600.0)
		var fq := 2.0 * sin(PI * fc / RATE)
		var x := rng.randf() * 2.0 - 1.0
		low += fq * band
		var high := x - low - q * band
		band += fq * high
		var y := band if mode == "bp" else (low if mode == "lp" else high)
		var e := sin(u * PI) if swell else env(t, dur, atk, curve)
		b[k] += y * e * amp


## A few quick bubbles: short sine chirps upward at random pitches.
static func bubbles(b: PackedFloat32Array, at: float, span: float, count: int, amp: float, lo: float, hi: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in count:
		var f := rng.randf_range(lo, hi)
		tone(b, at + rng.randf() * span, 0.035, f, f * 1.8, amp * rng.randf_range(0.6, 1.0), "sine", 0.002, 1.2)


## A feedback echo, mixed in (the buffer needs room for the tail).
static func echo(b: PackedFloat32Array, delay: float, fb: float, mix: float) -> void:
	var d := int(delay * RATE)
	var wet := PackedFloat32Array()
	wet.resize(b.size())
	for i in range(d, b.size()):
		wet[i] = (b[i - d] + wet[i - d] * fb)
	for i in b.size():
		b[i] += wet[i] * mix


## Clean up and level: DC removed, short fades at both ends, then scaled so its loudness
## (RMS) is rms but its peak never passes peak.
static func finish(b: PackedFloat32Array, rms: float = 0.2, peak: float = 0.89) -> PackedFloat32Array:
	var y := 0.0
	var px := 0.0
	for i in b.size():
		var x := b[i]
		y = x - px + 0.995 * y
		px = x
		b[i] = y
	var fi := mini(22, b.size())
	for i in fi:
		b[i] *= float(i) / fi
	var fo := mini(80, b.size())
	for i in fo:
		b[b.size() - 1 - i] *= float(i) / fo
	var mx := 0.0
	var sq := 0.0
	for v in b:
		mx = maxf(mx, absf(v))
		sq += v * v
	if mx <= 0.0:
		return b
	var r := sqrt(sq / b.size())
	var g := minf(peak / mx, rms / maxf(0.0001, r))
	for i in b.size():
		b[i] *= g
	return b


static func wav(b: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(b.size() * 2)
	for i in b.size():
		bytes.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	return w


static func _arp(b: PackedFloat32Array, at: float, notes: Array, step: float, note: float, amp: float, ratio: float = 3.5, index: float = 1.2) -> void:
	for k in notes.size():
		fm(b, at + k * step, note, float(notes[k]), ratio, index, amp, 7.0, 10.0)
		tone(b, at + k * step, note * 0.8, float(notes[k]), float(notes[k]), amp * 0.35, "tri", 0.003, 2.0)


# ------------------------------------------------------------------ the sounds
## One sound (variant v) as samples, ready for wav().
static func make(name: String, v: int = 0) -> PackedFloat32Array:
	var s := 7919 * (v + 1) + name.hash() % 1000
	var b: PackedFloat32Array
	var rms := 0.2
	match name:
		"click":
			b = buf(0.07)
			fm(b, 0.0, 0.07, 1250.0, 1.5, 2.0, 0.8, 55.0, 60.0)
			noise(b, 0.0, 0.01, 0.3, "hp", 2500.0, 0.0, 0.8, s)
			rms = 0.12
		"levelup":
			b = buf(0.95)
			_arp(b, 0.0, [523.0, 659.0, 784.0, 1047.0], 0.075, 0.45, 0.45)
			fm(b, 0.3, 0.6, 1568.0, 3.5, 0.8, 0.3, 4.0, 6.0)
			noise(b, 0.25, 0.5, 0.12, "hp", 3000.0, 0.0, 0.6, s, true)
			echo(b, 0.11, 0.35, 0.3)
			rms = 0.16
		"evolve":
			b = buf(1.0)
			tone(b, 0.0, 0.3, 300.0, 1200.0, 0.35, "tri", 0.02, 0.6)
			noise(b, 0.0, 0.3, 0.2, "bp", 600.0, 3000.0, 0.5, s, true)
			for f in [784.0, 988.0, 1175.0, 1568.0]:
				fm(b, 0.28, 0.65, f, 3.5, 1.0, 0.22, 5.0, 8.0)
			echo(b, 0.09, 0.3, 0.25)
			rms = 0.16
		"stage":
			b = buf(1.0)
			_arp(b, 0.0, [392.0, 523.0, 659.0, 784.0, 1047.0], 0.085, 0.35, 0.4, 4.0, 2.0)
			echo(b, 0.12, 0.3, 0.3)
			rms = 0.15
		"win":
			b = buf(1.9)
			var mel := [523.0, 659.0, 784.0, 1047.0, 0.0, 784.0, 1047.0, 1319.0, 1568.0]
			for k in mel.size():
				if float(mel[k]) > 0.0:
					_arp(b, k * 0.12, [mel[k]], 0.12, 0.5 if k < mel.size() - 1 else 0.9, 0.4)
			for f in [523.0, 659.0, 784.0]:
				tone(b, 0.96, 0.9, f, f, 0.12, "tri", 0.05, 1.2, 0.01, 5.0)
			echo(b, 0.13, 0.3, 0.25)
			rms = 0.15
		"die":
			b = buf(1.1)
			tone(b, 0.0, 0.9, 620.0, 170.0, 0.5, "tri", 0.01, 1.1, 0.04, 7.0)
			tone(b, 0.0, 0.9, 930.0, 255.0, 0.15, "sine", 0.01, 1.1, 0.04, 7.0)
			fm(b, 0.85, 0.25, 220.0, 1.0, 1.5, 0.5, 18.0, 20.0)
			rms = 0.17
		"poi":
			b = buf(1.0)
			for k in 3:
				fm(b, k * 0.09, 0.5, [880.0, 1175.0, 1480.0][k], 2.76, 1.6, 0.4, 6.0, 9.0)
			noise(b, 0.05, 0.5, 0.1, "hp", 3200.0, 0.0, 0.5, s, true)
			echo(b, 0.14, 0.4, 0.3)
			rms = 0.14
		"mutagen":
			b = buf(0.45)
			fm(b, 0.0, 0.3, 1976.0, 3.5, 1.4, 0.45, 12.0, 14.0)
			fm(b, 0.06, 0.35, 2637.0, 3.5, 1.2, 0.4, 10.0, 12.0)
			echo(b, 0.07, 0.3, 0.25)
			rms = 0.12
		"heal":
			b = buf(0.6)
			tone(b, 0.0, 0.3, 523.0, 587.0, 0.4, "tri", 0.02, 1.4)
			tone(b, 0.12, 0.4, 784.0, 880.0, 0.35, "tri", 0.02, 1.4)
			noise(b, 0.1, 0.4, 0.08, "hp", 3000.0, 0.0, 0.5, s, true)
			rms = 0.13
		"night":
			b = buf(1.3)
			for k in 3:
				fm(b, k * 0.22, 0.8, [659.0, 494.0, 392.0][k], 2.0, 1.2, 0.35, 4.0, 5.0)
			echo(b, 0.2, 0.4, 0.3)
			rms = 0.13
		"boss":
			b = buf(1.3)
			tone(b, 0.0, 1.2, 220.0, 207.0, 0.45, "saw", 0.08, 0.9, 0.012, 5.5)
			tone(b, 0.0, 1.2, 233.0, 220.0, 0.35, "saw", 0.08, 0.9, 0.012, 5.0)
			tone(b, 0.0, 1.2, 440.0, 415.0, 0.2, "pulse", 0.1, 1.0)
			noise(b, 0.0, 1.2, 0.15, "lp", 700.0, 300.0, 0.7, s, true)
			rms = 0.2
		# ---------------------------------------------------------- eating
		"bite_fruit":
			b = buf(0.14)
			for k in 3:
				noise(b, k * 0.022 + v * 0.004, 0.035, 0.5, "bp", 2400.0 + v * 300.0, 1800.0, 0.5, s + k, false, 0.001, 2.5)
			fm(b, 0.0, 0.08, 700.0 + v * 60.0, 1.4, 2.0, 0.35, 40.0, 50.0)
			rms = 0.16
		"bite_meat":
			b = buf(0.17)
			tone(b, 0.0, 0.1, 350.0 + v * 20.0, 200.0, 0.55, "sine", 0.002, 1.8)
			tone(b, 0.0, 0.1, 700.0 + v * 40.0, 400.0, 0.3, "sine", 0.002, 1.8)
			noise(b, 0.01, 0.12, 0.45, "bp", 900.0 + v * 150.0, 600.0, 0.6, s, false, 0.004, 1.4)
			rms = 0.18
		"bite_fish":
			b = buf(0.2)
			tone(b, 0.0, 0.16, 330.0 + v * 30.0, 760.0, 0.45, "sine", 0.01, 1.2, 0.05, 30.0)
			noise(b, 0.0, 0.16, 0.3, "bp", 1400.0, 2400.0, 0.4, s, true)
			bubbles(b, 0.05, 0.1, 2, 0.2, 700.0, 1100.0, s)
			rms = 0.15
		"eat_done":
			b = buf(0.4)
			tone(b, 0.0, 0.1, 500.0, 260.0, 0.45, "sine", 0.004, 1.4)
			fm(b, 0.1, 0.3, 1568.0, 3.5, 1.0, 0.4, 10.0, 12.0)
			fm(b, 0.16, 0.25, 2093.0, 3.5, 0.8, 0.3, 12.0, 14.0)
			rms = 0.13
		"pouch":
			b = buf(0.12)
			tone(b, 0.0, 0.09, 420.0, 980.0, 0.55, "sine", 0.002, 1.6)
			noise(b, 0.0, 0.012, 0.3, "hp", 2500.0, 0.0, 0.8, s)
			rms = 0.13
		"rustle":
			b = buf(0.35)
			noise(b, 0.0, 0.3, 0.45, "hp", 1800.0, 2600.0, 0.5, s, true)
			noise(b, 0.05, 0.2, 0.25, "bp", 2800.0, 0.0, 0.3, s + 3, true)
			tone(b, 0.2, 0.08, 500.0, 900.0, 0.3, "sine", 0.002, 1.6)
			rms = 0.13
		"splash":
			b = buf(0.5)
			noise(b, 0.0, 0.45, 0.6, "lp", 3200.0, 500.0, 0.6, s, false, 0.003, 1.3)
			noise(b, 0.0, 0.08, 0.3, "hp", 2500.0, 0.0, 0.7, s + 1)
			bubbles(b, 0.1, 0.3, 6, 0.25, 500.0, 1300.0, s)
			rms = 0.17
		"shroom":
			b = buf(0.35)
			fm(b, 0.0, 0.25, 320.0, 0.5, 3.0, 0.5, 9.0, 8.0, 220.0)
			tone(b, 0.0, 0.25, 280.0, 560.0, 0.3, "sine", 0.01, 1.4, 0.08, 18.0)
			noise(b, 0.0, 0.18, 0.2, "bp", 700.0, 1400.0, 0.5, s, true)
			bubbles(b, 0.15, 0.15, 2, 0.2, 500.0, 800.0, s)
			rms = 0.16
		# ---------------------------------------------------------- attacks
		"gulp":
			b = buf(0.2)
			tone(b, 0.0, 0.16, 560.0 - v * 40.0, 190.0, 0.55, "sine", 0.002, 1.3)
			tone(b, 0.0, 0.16, 1120.0 - v * 80.0, 380.0, 0.15, "sine", 0.002, 1.3)
			noise(b, 0.0, 0.1, 0.3, "bp", 900.0, 500.0, 0.6, s, false, 0.003, 1.6)
			rms = 0.19
		"bonk":
			b = buf(0.25)
			fm(b, 0.0, 0.25, 620.0 + v * 40.0, 2.37, 4.0, 0.7, 14.0, 30.0, 470.0 + v * 30.0)
			tone(b, 0.0, 0.07, 330.0, 200.0, 0.4, "sine", 0.001, 2.0)
			noise(b, 0.0, 0.015, 0.4, "hp", 2000.0, 0.0, 0.8, s)
			rms = 0.2
		"crunch":
			b = buf(0.2)
			for k in 4:
				noise(b, k * 0.018 + v * 0.003, 0.03, 0.55, "bp", 1500.0 + k * 250.0, 900.0, 0.45, s + k, false, 0.001, 2.2)
			tone(b, 0.0, 0.09, 280.0, 160.0, 0.45, "sine", 0.002, 1.6)
			rms = 0.2
		"swoosh":
			b = buf(0.3)
			noise(b, 0.0, 0.28, 0.8, "bp", 500.0, 2600.0, 0.35, s, true)
			noise(b, 0.0, 0.28, 0.3, "bp", 1200.0, 3400.0, 0.3, s + 1, true)
			rms = 0.17
		"spit":
			b = buf(0.17)
			noise(b, 0.0, 0.025, 0.6, "bp", 1800.0, 1000.0, 0.6, s)
			tone(b, 0.01, 0.12, 950.0, 380.0, 0.45, "sine", 0.002, 1.5)
			noise(b, 0.03, 0.1, 0.25, "bp", 1200.0, 700.0, 0.4, s + 1)
			rms = 0.17
		"charge":
			b = buf(0.45)
			noise(b, 0.0, 0.42, 0.7, "bp", 300.0, 1600.0, 0.5, s, true)
			tone(b, 0.0, 0.42, 150.0, 260.0, 0.35, "saw", 0.08, 0.6)
			tone(b, 0.0, 0.42, 300.0, 520.0, 0.15, "pulse", 0.08, 0.6)
			rms = 0.2
		"zip":
			b = buf(0.12)
			tone(b, 0.0, 0.09, 1600.0, 3400.0, 0.45, "sine", 0.002, 1.2)
			noise(b, 0.0, 0.07, 0.3, "hp", 2500.0, 3400.0, 0.5, s, true)
			fm(b, 0.085, 0.03, 2600.0, 1.4, 2.0, 0.3, 80.0, 90.0)
			rms = 0.13
		"peck":
			b = buf(0.05)
			fm(b, 0.0, 0.045, 1900.0 + v * 220.0, 1.41, 3.0, 0.8, 70.0, 80.0)
			noise(b, 0.0, 0.008, 0.4, "hp", 3000.0, 0.0, 0.8, s)
			rms = 0.15
		"toss":
			b = buf(0.28)
			noise(b, 0.0, 0.22, 0.5, "bp", 700.0, 1800.0, 0.4, s, true)
			fm(b, 0.18, 0.08, 850.0, 1.5, 2.0, 0.35, 40.0, 45.0)
			rms = 0.13
		"mud":
			b = buf(0.45)
			var mb := buf(0.45)
			noise(mb, 0.0, 0.4, 1.0, "lp", 1400.0, 260.0, 0.3, s, false, 0.005, 1.2)
			for i in mb.size():
				var t := float(i) / RATE
				b[i] += mb[i] * (0.6 + 0.4 * sin(t * 55.0))
			bubbles(b, 0.08, 0.3, 5, 0.25, 280.0, 600.0, s)
			rms = 0.19
		"snip":
			b = buf(0.14)
			for k in 2:
				fm(b, k * 0.065, 0.06, 3000.0 - k * 200.0, 1.41, 2.5, 0.6, 55.0, 60.0)
				noise(b, k * 0.065, 0.02, 0.4, "hp", 2800.0, 0.0, 0.7, s + k)
			rms = 0.15
		"song":
			b = buf(0.9)
			for k in 3:
				var f: float = [659.0, 784.0, 988.0][k]
				tone(b, k * 0.14, 0.4, f, f, 0.35, "tri", 0.03, 1.3, 0.015, 6.0)
				tone(b, k * 0.14, 0.4, f * 2.0, f * 2.0, 0.08, "sine", 0.03, 1.5)
			echo(b, 0.15, 0.35, 0.3)
			rms = 0.13
		"lash":
			b = buf(0.22)
			noise(b, 0.0, 0.14, 0.7, "bp", 900.0, 3000.0, 0.35, s, true)
			tone(b, 0.1, 0.1, 700.0, 380.0, 0.35, "sine", 0.003, 1.5, 0.1, 40.0)
			noise(b, 0.12, 0.08, 0.3, "bp", 1100.0, 600.0, 0.5, s + 1)
			rms = 0.17
		"kick":
			b = buf(0.18)
			noise(b, 0.0, 0.02, 0.6, "hp", 2200.0, 0.0, 0.7, s)
			tone(b, 0.0, 0.12, 340.0 + v * 20.0, 135.0, 0.55, "sine", 0.001, 1.8)
			tone(b, 0.0, 0.12, 680.0 + v * 40.0, 270.0, 0.35, "sine", 0.001, 1.8)
			noise(b, 0.0, 0.08, 0.35, "bp", 1000.0, 500.0, 0.5, s + 1)
			rms = 0.2
		"squeeze":
			b = buf(0.4)
			var cb := buf(0.4)
			tone(cb, 0.0, 0.38, 170.0, 150.0, 1.0, "saw", 0.02, 0.8)
			var rng := RandomNumberGenerator.new()
			rng.seed = s
			var jit := 1.0
			for i in cb.size():
				if i % 180 == 0:
					jit = rng.randf_range(0.2, 1.0)
				b[i] += cb[i] * jit * 0.5
			tone(b, 0.25, 0.14, 900.0, 1400.0, 0.2, "sine", 0.01, 1.2)
			noise(b, 0.0, 0.38, 0.25, "bp", 900.0, 1200.0, 0.4, s + 1, true)
			rms = 0.16
		"fwip":
			b = buf(0.09)
			noise(b, 0.0, 0.08, 0.7, "bp", 1400.0 + v * 200.0, 3300.0, 0.35, s, true)
			rms = 0.12
		"quack":
			b = _quack(1.0)
			rms = 0.19
		"quack_big":
			b = _quack(0.6)
			rms = 0.21
		"honk":
			b = _honk()
			rms = 0.2
		# ---------------------------------------------------------- feedback
		"tell":
			b = buf(0.09)
			tone(b, 0.0, 0.08, 480.0, 820.0, 0.4, "tri", 0.01, 1.2)
			rms = 0.09
		"whiff":
			b = buf(0.1)
			noise(b, 0.0, 0.09, 0.6, "bp", 1300.0 + v * 250.0, 2600.0, 0.4, s, true)
			rms = 0.08
		"hit":
			b = buf(0.12)
			tone(b, 0.0, 0.08, 330.0 + v * 25.0, 150.0, 0.55, "sine", 0.001, 1.8)
			tone(b, 0.0, 0.06, 660.0 + v * 50.0, 300.0, 0.3, "sine", 0.001, 2.0)
			noise(b, 0.0, 0.03, 0.45, "bp", 1800.0 + v * 300.0, 900.0, 0.6, s, false, 0.001, 2.0)
			rms = 0.18
		"crit":
			b = buf(0.35)
			tone(b, 0.0, 0.09, 300.0, 120.0, 0.6, "sine", 0.001, 1.8)
			noise(b, 0.0, 0.035, 0.5, "hp", 2000.0, 0.0, 0.7, s)
			fm(b, 0.01, 0.32, 1760.0, 3.5, 1.5, 0.35, 12.0, 14.0)
			rms = 0.17
		"kill":
			b = buf(0.4)
			tone(b, 0.0, 0.1, 380.0, 900.0, 0.5, "sine", 0.002, 1.5)
			noise(b, 0.0, 0.02, 0.35, "hp", 2400.0, 0.0, 0.8, s)
			fm(b, 0.07, 0.3, 1976.0, 3.5, 1.0, 0.3, 11.0, 13.0)
			rms = 0.14
		"hurt":
			b = buf(0.2)
			tone(b, 0.0, 0.16, 520.0 - v * 40.0, 240.0, 0.5, "tri", 0.004, 1.4)
			noise(b, 0.0, 0.14, 0.4, "bp", 900.0, 600.0, 0.5, s, false, 0.004, 1.4)
			tone(b, 0.0, 0.05, 250.0, 150.0, 0.4, "sine", 0.001, 2.0)
			rms = 0.2
		"crack":
			b = buf(0.35)
			noise(b, 0.0, 0.03, 0.8, "hp", 2600.0, 0.0, 0.6, s)
			fm(b, 0.0, 0.05, 1400.0, 1.41, 3.0, 0.4, 60.0, 70.0)
			noise(b, 0.03, 0.3, 0.5, "lp", 2000.0, 400.0, 0.6, s + 1, false, 0.004, 1.4)
			bubbles(b, 0.06, 0.15, 3, 0.2, 500.0, 900.0, s)
			rms = 0.18
		"splat":
			b = buf(0.18)
			noise(b, 0.0, 0.16, 0.6, "lp", 2400.0, 500.0, 0.5, s, false, 0.002, 1.5)
			tone(b, 0.0, 0.07, 500.0, 250.0, 0.3, "sine", 0.002, 1.6)
			rms = 0.15
		"poison":
			b = buf(0.3)
			bubbles(b, 0.0, 0.25, 5, 0.4, 350.0, 700.0, s)
			noise(b, 0.0, 0.25, 0.1, "bp", 600.0, 0.0, 0.5, s + 1, true)
			rms = 0.12
		"stun":
			b = buf(0.4)
			for k in 3:
				tone(b, k * 0.11, 0.08, 2200.0, 2900.0, 0.35, "sine", 0.004, 1.2, 0.04, 40.0)
			rms = 0.1
		# ---------------------------------------------------------- movement and world
		"dash":
			b = buf(0.2)
			noise(b, 0.0, 0.18, 0.7, "bp", 700.0, 2400.0, 0.4, s, true)
			rms = 0.15
		"flap":
			b = buf(0.36)
			for k in 3:
				noise(b, k * 0.11, 0.1, 0.7, "bp", 900.0, 500.0, 0.5, s + k, true)
			rms = 0.15
		"hiss":
			b = buf(0.4)
			noise(b, 0.0, 0.38, 0.6, "hp", 2600.0, 3200.0, 0.6, s, true)
			rms = 0.13
		"wind":
			b = buf(1.0)
			noise(b, 0.0, 0.95, 0.6, "bp", 400.0, 900.0, 0.4, s, true)
			noise(b, 0.2, 0.7, 0.2, "bp", 1500.0, 1100.0, 0.3, s + 1, true)
			rms = 0.13
		"thud":
			b = buf(0.22)
			tone(b, 0.0, 0.18, 220.0, 95.0, 0.6, "sine", 0.001, 1.6)
			tone(b, 0.0, 0.14, 440.0, 190.0, 0.3, "sine", 0.001, 1.8)
			noise(b, 0.0, 0.1, 0.4, "lp", 900.0, 300.0, 0.6, s)
			rms = 0.2
		_:
			b = buf(0.05)
			tone(b, 0.0, 0.05, 800.0, 800.0, 0.3)
	return finish(b, rms)


static func _quack(pitch: float) -> PackedFloat32Array:
	var dur := 0.26 / pitch
	var b := buf(dur + 0.02)
	var ph := 0.0
	var n := int(RATE * dur)
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		ph += (620.0 - 260.0 * u + 70.0 * sin(u * 10.0)) * pitch / RATE
		var nasal := osc(ph, "saw") * (0.55 + 0.45 * sin(ph * TAU * 3.0))
		b[i] = nasal * minf(1.0, u * 25.0) * pow(maxf(0.0, 1.0 - u), 0.6) * 0.55
	# the bill: a short nasal buzz on top
	noise(b, 0.0, dur * 0.6, 0.12, "bp", 1400.0 * pitch, 0.0, 0.3, 17)
	return b


static func _honk() -> PackedFloat32Array:
	var dur := 0.4
	var b := buf(dur + 0.02)
	var ph := 0.0
	var n := int(RATE * dur)
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		ph += (420.0 + 40.0 * sin(u * 30.0)) / RATE
		b[i] = (osc(ph, "saw") * 0.6 + osc(ph * 1.5, "pulse") * 0.3) * minf(1.0, u * 20.0) * pow(1.0 - u, 0.4) * 0.5
	return b
