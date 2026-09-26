class_name Fx
extends Node2D
## Pixel juice in world space: square particles, expanding rings, cones, falling-bread
## shadows and floating numbers in the pixel font. Everything snaps to whole pixels.

var bits: Array = []  # {p, v, life, max, c, s, g}
var rings: Array = []  # {p, r0, r1, t, dur, c}
var cones: Array = []  # {p, dir, len, arc, t, dur, c}
var texts: Array = []  # {p, s, t, dur, c, big}
var tags: Array = []  # {p, s, c, key} labels that stay put, refilled every frame (mushroom names, the E prompt); key draws a keycap before the text
var marks: Array = []  # {p, r, t, dur, c} telegraph circles
var stars: Array = []  # {p, t, dur, c} four-point twinkles (legendary and healing food)
var slashes: Array = []  # {p, dir, r, t, dur, c, flip} crescent swipes
var anims: Array = []  # {k, p, dir, t, dur, c, r, seed} each attack's own animation
var ranges: Array = []  # attack reach markers, refilled every frame by Combat
var font: Font


func _ready() -> void:
	font = Game.font("small")
	z_index = 60


func burst(p: Vector2, c: Color, n: int, spd: float = 60.0, size: float = 1.0, life: float = 0.5, grav: float = 0.0) -> void:
	for i in n:
		var v := Vector2.from_angle(randf() * TAU) * spd * randf_range(0.3, 1.0)
		bits.append({"p": p, "v": v, "life": life * randf_range(0.6, 1.0), "max": life, "c": c, "s": size, "g": grav})
	if bits.size() > 600:
		bits = bits.slice(bits.size() - 600)


func ring(p: Vector2, r0: float, r1: float, dur: float, c: Color) -> void:
	rings.append({"p": p, "r0": r0, "r1": r1, "t": 0.0, "dur": dur, "c": c})


func cone(p: Vector2, dir: Vector2, length: float, arc: float, dur: float, c: Color) -> void:
	cones.append({"p": p, "dir": dir, "len": length, "arc": arc, "t": 0.0, "dur": dur, "c": c})


## A crescent swipe centered on p, bulging toward dir, sweeping open over its life.
func slash(p: Vector2, dir: Vector2, r: float, c: Color = Color.WHITE, dur: float = 0.18) -> void:
	slashes.append({"p": p, "dir": dir, "r": r, "t": 0.0, "dur": dur, "c": c, "flip": randf() < 0.5})


## A four-point pixel star that grows and shrinks once: n of them scattered around p.
func twinkle(p: Vector2, c: Color, n: int = 1) -> void:
	for i in n:
		var q := p + (Vector2(randf_range(-6, 6), randf_range(-5, 5)) if n > 1 else Vector2.ZERO)
		stars.append({"p": q, "t": -randf() * 0.12 * i, "dur": randf_range(0.45, 0.6), "c": c})
	if stars.size() > 120:
		stars = stars.slice(stars.size() - 120)


## One attack's animation: k names it (see _anim), r is its size.
func anim(k: String, p: Vector2, dir: Vector2, dur: float, c: Color, r: float = 8.0) -> void:
	anims.append({"k": k, "p": p, "dir": dir if dir.length() > 0.01 else Vector2.RIGHT, "t": 0.0, "dur": maxf(0.05, dur), "c": c, "r": r, "seed": randi() % 1000})
	if anims.size() > 80:
		anims.pop_front()


func mark(p: Vector2, r: float, dur: float, c: Color) -> void:
	marks.append({"p": p, "r": r, "t": 0.0, "dur": dur, "c": c})


func text(p: Vector2, s: String, c: Color = Color.WHITE, big: bool = false, dur: float = 0.8) -> void:
	texts.append({"p": p, "s": s, "t": 0.0, "dur": dur, "c": c, "big": big})
	if texts.size() > 50:
		texts.pop_front()


func step(dt: float) -> void:
	for i in range(bits.size() - 1, -1, -1):
		var b: Dictionary = bits[i]
		b["life"] = float(b["life"]) - dt
		if float(b["life"]) <= 0.0:
			bits.remove_at(i)
			continue
		var v: Vector2 = b["v"]
		v.y += float(b["g"]) * dt
		v *= maxf(0.0, 1.0 - dt * 3.0)
		b["v"] = v
		b["p"] = (b["p"] as Vector2) + v * dt
	for arr in [rings, cones, texts, marks, slashes, stars, anims]:
		for i in range(arr.size() - 1, -1, -1):
			arr[i]["t"] = float(arr[i]["t"]) + dt
			if float(arr[i]["t"]) >= float(arr[i]["dur"]):
				arr.remove_at(i)
	queue_redraw()


func _px_circle(c: Vector2, r: float, col: Color) -> void:
	# a 1px pixel ring, stepped so it stays crisp
	var n := maxi(12, int(r * 1.6))
	for i in n:
		var a := TAU * i / n
		draw_rect(Rect2((c + Vector2(cos(a), sin(a)) * r).floor(), Vector2.ONE), col)


func _draw() -> void:
	for rg in ranges:
		_range(rg)
	for an in anims:
		_anim(an)
	for m in marks:
		var u := float(m["t"]) / float(m["dur"])
		var col: Color = m["c"]
		col.a = 0.35 + 0.35 * u
		draw_circle((m["p"] as Vector2).floor(), float(m["r"]) * (0.4 + 0.6 * u), Color(col, 0.25 + 0.2 * u))
		_px_circle(m["p"], float(m["r"]), col)
	for g in rings:
		var u := float(g["t"]) / float(g["dur"])
		var rr := lerpf(float(g["r0"]), float(g["r1"]), 1.0 - pow(1.0 - u, 2.0))
		var col2: Color = g["c"]
		col2.a *= 1.0 - u * 0.8
		_px_circle(g["p"], rr, col2)
		if rr > 6.0:
			_px_circle(g["p"], rr - 1.0, Color(col2, col2.a * 0.5))
	for cn in cones:
		var u := float(cn["t"]) / float(cn["dur"])
		var col3: Color = cn["c"]
		col3.a *= 1.0 - u
		var dir: Vector2 = cn["dir"]
		var ln := float(cn["len"]) * (0.4 + 0.6 * u)
		for k in 7:
			var a := dir.angle() + (k / 6.0 - 0.5) * float(cn["arc"])
			for j in 3:
				var d := ln * (0.5 + j * 0.25)
				draw_rect(Rect2(((cn["p"] as Vector2) + Vector2.from_angle(a) * d).floor(), Vector2(2, 2)), col3)
	for st in stars:
		var u := float(st["t"]) / float(st["dur"])
		if u < 0.0:
			continue
		# arm length 0 -> 2 -> 0: a dot, a plus, a bigger plus, back
		var arm := roundi(sin(u * PI) * 2.4)
		var sp := (st["p"] as Vector2).floor()
		var sc: Color = st["c"]
		draw_rect(Rect2(sp, Vector2.ONE), Color.WHITE if arm >= 2 else sc)
		for k in range(1, arm + 1):
			for dv in [Vector2(k, 0), Vector2(-k, 0), Vector2(0, k), Vector2(0, -k)]:
				draw_rect(Rect2(sp + dv, Vector2.ONE), sc)
	for sl in slashes:
		var u := float(sl["t"]) / float(sl["dur"])
		var r := float(sl["r"])
		var span := 2.3
		var n := int(r * 2.4)
		var reveal := minf(1.0, u * 2.2)
		var base_a := (sl["dir"] as Vector2).angle() - span * 0.5
		var cen: Vector2 = (sl["p"] as Vector2) - (sl["dir"] as Vector2) * r * 0.45
		var col6: Color = sl["c"]
		col6.a = 1.0 if u < 0.55 else (1.0 - u) / 0.45
		for k in int(n * reveal):
			var f := float(k) / n
			if sl["flip"]:
				f = 1.0 - f
			var thick := roundf(3.2 * sin(PI * f) * (1.0 - u * 0.5))
			if thick < 1.0:
				continue
			var a := base_a + span * f
			var v := Vector2.from_angle(a)
			for j in int(thick):
				var q := (cen + v * (r - j)).floor()
				draw_rect(Rect2(q, Vector2.ONE), col6 if j < thick - 1 else Color(Pal.c("red", 3), col6.a))
	for b in bits:
		var s := float(b["s"])
		var col4: Color = b["c"]
		if float(b["life"]) < float(b["max"]) * 0.3:
			col4.a *= 0.6
		draw_rect(Rect2((b["p"] as Vector2).floor(), Vector2(s, s)), col4)
	# labels never overlap: the first one listed wins its spot
	var taken: Array[Rect2] = []
	for tg in tags:
		var key := String(tg.get("key", ""))
		var tw := font.get_string_size(String(tg["s"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + (11.0 if key != "" else 0.0)
		var box := Rect2((tg["p"] as Vector2) - Vector2(tw * 0.5 + 2, 8), Vector2(tw + 4, 10))
		var free := true
		for r in taken:
			if r.intersects(box):
				free = false
				break
		if free:
			taken.append(box)
			var lp := (tg["p"] as Vector2).floor()
			if key != "":
				# a little keycap, then the action: "[E] EAT"
				var kp := (lp + Vector2(-floorf(tw * 0.5), -7)).floor()
				draw_rect(Rect2(kp, Vector2(9, 9)), Pal.INK)
				draw_rect(Rect2(kp + Vector2(1, 1), Vector2(7, 7)), Ui.PARCHMENT)
				draw_rect(Rect2(kp + Vector2(1, 7), Vector2(7, 1)), Ui.WOOD)
				draw_string(font, kp + Vector2(2, 7), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Pal.INK)
				lp.x += 6.0
			_label(lp, String(tg["s"]), tg["c"])
	for tx in texts:
		var u := float(tx["t"]) / float(tx["dur"])
		var p := ((tx["p"] as Vector2) + Vector2(0, -12.0 * u)).floor()
		var s2 := String(tx["s"])
		var fs := 16 if tx["big"] else 8
		var w := font.get_string_size(s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col5: Color = tx["c"]
		col5.a = 1.0 if u < 0.7 else (1.0 - u) / 0.3
		var o := Vector2(-floorf(w * 0.5), 0)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_string(font, p + o + d, s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Pal.INK, col5.a))
		draw_string(font, p + o, s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col5)


## A small label in the pixel font with an ink outline, centered on p.
func _label(p: Vector2, s: String, c: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var o := Vector2(-floorf(w * 0.5), 0)
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_string(font, p + o + d, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(Pal.INK, c.a))
	draw_string(font, p + o, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, c)


# ------------------------------------------------------------------ attack drawing
func _dot(p: Vector2, c: Color) -> void:
	draw_rect(Rect2(p.floor(), Vector2.ONE), c)


## A crisp pixel line, thick px wide, optionally dotted (every other gap px).
func _pline(a: Vector2, b: Vector2, c: Color, thick: int = 1, gap: int = 0) -> void:
	var n := maxi(1, int(a.distance_to(b)))
	for i in n + 1:
		if gap > 0 and (i / gap) % 2 == 1:
			continue
		var q := a.lerp(b, float(i) / n).floor()
		draw_rect(Rect2(q - Vector2(thick / 2, thick / 2), Vector2(thick, thick)), c)


## A pixel arc from angle a0 to a1 at radius r.
func _parc(ctr: Vector2, r: float, a0: float, a1: float, c: Color, thick: int = 1, gap: int = 0) -> void:
	var n := maxi(4, int(absf(a1 - a0) * r))
	for i in n + 1:
		if gap > 0 and (i / gap) % 2 == 1:
			continue
		var a := lerpf(a0, a1, float(i) / n)
		var q := (ctr + Vector2(cos(a), sin(a) * 0.75) * r).floor()
		draw_rect(Rect2(q - Vector2(thick / 2, thick / 2), Vector2(thick, thick)), c)


## An attack's reach, in its shape: what the button would hit from here.
func _range(rg: Dictionary) -> void:
	var c: Color = rg["c"]
	c.a = 0.75
	var o: Vector2 = rg["p"]
	var d: Vector2 = rg["dir"]
	var r := float(rg["r"])
	var ang := d.angle()
	match String(rg["shape"]):
		"bite", "circle":
			_parc(o, r, 0.0, TAU, c, 1, 2)
		"arc", "cone":
			var h := float(rg["arc"])
			_parc(o, r, ang - h, ang + h, c, 1, 2)
			_pline(o, o + Vector2(cos(ang - h), sin(ang - h) * 0.75) * r, c, 1, 2)
			_pline(o, o + Vector2(cos(ang + h), sin(ang + h) * 0.75) * r, c, 1, 2)
		"line", "lunge":
			var side := d.orthogonal() * float(rg["width"]) * 0.5
			_pline(o + side, o + side + d * r, c, 1, 2)
			_pline(o - side, o - side + d * r, c, 1, 2)
			_pline(o + side + d * r, o - side + d * r, c)
		"shot":
			_pline(o, o + d * r, c, 1, 3)
			var e := o + d * r
			_pline(e + d.orthogonal() * 3.0, e - d.orthogonal() * 3.0, c)
		"lob":
			var land: Vector2 = rg["target"] if rg["target"] != Vector2.INF else o + d * r * 0.8
			_pline(o, land, c, 1, 3)
			_parc(land, float(rg["blast"]), 0.0, TAU, c, 1, 2)
	# the one it would hit: blinking corner brackets
	if rg["target"] != Vector2.INF and int(Time.get_ticks_msec() / 150) % 3 != 0:
		var tp: Vector2 = (rg["target"] as Vector2).floor()
		var k := float(rg["tr"]) + 4.0
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner := tp + Vector2(sx * k, sy * k)
				_pline(corner, corner - Vector2(sx * 3.0, 0), rg["c"])
				_pline(corner, corner - Vector2(0, sy * 3.0), rg["c"])


func _tri(a: Vector2, b: Vector2, cc: Vector2, fill: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a.floor(), b.floor(), cc.floor()]), fill)


## Each attack's own animation (u runs 0 -> 1 over its life).
func _anim(an: Dictionary) -> void:
	var u := float(an["t"]) / float(an["dur"])
	var c: Color = an["c"]
	var p: Vector2 = an["p"]
	var d: Vector2 = an["dir"]
	var r := float(an["r"])
	var ink := Pal.INK
	var fade := 1.0 if u < 0.6 else (1.0 - u) / 0.4
	match String(an["k"]):
		"tell":
			# the lean before a heavy hit: a bright arc gathering in front
			var cc := Color(c, 0.3 + 0.6 * u)
			_parc(p, r + 6.0 - u * 3.0, d.angle() - 0.6, d.angle() + 0.6, cc, 1, 1)
		"chomp":
			# two jaws snap shut on the target, then crumbs
			var close := minf(1.0, u * 2.5)
			var gap := r * (1.0 - close) + 1.0
			var jc := Color(c, fade)
			_parc(p + Vector2(0, -gap), r * 0.8, PI, TAU, Color(ink, fade), 3)
			_parc(p + Vector2(0, -gap), r * 0.8, PI, TAU, jc, 1)
			_parc(p + Vector2(0, gap), r * 0.8, 0.0, PI, Color(ink, fade), 3)
			_parc(p + Vector2(0, gap), r * 0.8, 0.0, PI, jc, 1)
		"fangs":
			# rows of teeth close from above and below
			var close2 := minf(1.0, u * 3.0)
			var off := 8.0 * (1.0 - close2)
			for i in 3:
				var x := (i - 1) * 4.0
				var top := p + Vector2(x, -off - 3.0)
				var bot := p + Vector2(x + 2.0, off + 3.0)
				_tri(top + Vector2(-2, -1), top + Vector2(2, -1), top + Vector2(0, 4), Color(c, fade))
				_tri(bot + Vector2(-2, 1), bot + Vector2(2, 1), bot + Vector2(0, -4), Color(c, fade))
			if u > 0.3:
				_dot(p + Vector2(0, 5.0 + u * 6.0), Color(Pal.c("red", 3), fade))
		"bonk":
			# an impact star that bursts out
			var arm := roundf(r * (0.4 + u))
			var bc := Color(c, fade)
			for v in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				_pline(p, p + v * arm, bc, 2)
			for v2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				_pline(p + v2 * 2.0, p + v2 * arm * 0.55, bc)
			_dot(p, Color(1, 1, 1, fade))
		"dizzy":
			# little stars circling the head of a stunned animal
			for i in 3:
				var a := float(an["t"]) * 6.0 + i * TAU / 3.0
				var q := p + Vector2(cos(a) * (r + 2.0), sin(a) * 2.5)
				_dot(q, Color(c, fade))
				_dot(q + Vector2(1, 0), Color(c, fade * 0.6))
		"sweep":
			# the tail sweeps a full circle: a band chasing its own head
			var head := d.angle() + u * TAU * 1.1
			var sc := Color(c, fade)
			_parc(p, r * 0.9, head - 1.8, head, Color(ink, fade * 0.8), 3)
			_parc(p, r * 0.9, head - 1.8, head, sc, 1)
			_parc(p, r * 0.7, head - 1.2, head, Color(sc, fade * 0.5), 1, 1)
		"beak":
			# three quick jabs forward
			var k := int(u * 3.0)
			var f := fmod(u * 3.0, 1.0)
			var reach := r * (0.3 + 0.7 * sin(f * PI))
			var side := d.orthogonal() * ((k - 1) * 2.0)
			var tip := p + side + d * reach
			_tri(tip, tip - d * 4.0 + d.orthogonal() * 2.0, tip - d * 4.0 - d.orthogonal() * 2.0, Color(c, fade))
			_pline(p + side, tip - d * 4.0, Color(c, 0.3 * fade))
		"peck":
			var pc := Color(Color.WHITE, fade)
			_pline(p - Vector2(r, 0), p + Vector2(r, 0), pc)
			_pline(p - Vector2(0, r), p + Vector2(0, r), pc)
		"mud":
			# a mud pool on the ground, drying out at the end
			var mc := Color(Pal.c("brown", 1), 0.55 * (1.0 if u < 0.8 else (1.0 - u) / 0.2))
			draw_set_transform(p.floor(), 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, r * minf(1.0, u * 8.0 + 0.4), mc)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var rng := RandomNumberGenerator.new()
			rng.seed = int(an["seed"])
			for i in 10:
				var q2 := p + Vector2(rng.randf_range(-r, r) * 0.8, rng.randf_range(-r, r) * 0.35)
				_dot(q2, Color(Pal.c("brown", 3), mc.a))
		"snip":
			# two claw halves open, then snap shut
			var open := 1.0 - minf(1.0, u * 2.5)
			var ang2 := d.angle()
			var cc2 := Color(c, fade)
			_parc(p, r, ang2 - 0.2 - open * 1.2, ang2 + 1.3 - open * 1.2, Color(ink, fade), 3)
			_parc(p, r, ang2 - 0.2 - open * 1.2, ang2 + 1.3 - open * 1.2, cc2, 1)
			_parc(p, r, ang2 - 1.3 + open * 1.2, ang2 + 0.2 + open * 1.2, Color(ink, fade), 3)
			_parc(p, r, ang2 - 1.3 + open * 1.2, ang2 + 0.2 + open * 1.2, cc2, 1)
		"waves":
			# sound: three arcs rolling out through the cone
			for i in 3:
				var w := fmod(u * 1.3 + i * 0.25, 1.0)
				_parc(p, r * w, d.angle() - 0.6, d.angle() + 0.6, Color(c, (1.0 - w) * fade), 2)
		"lash":
			# a wavy tentacle whips out and back
			var ext := sin(minf(1.0, u * 1.4) * PI) * r
			var n := int(ext)
			var prev := p
			for i in n:
				var x := float(i)
				var q3 := p + d * x + d.orthogonal() * sin(x * 0.5 - u * 20.0) * 2.5 * (x / maxf(1.0, r))
				_pline(prev, q3, Color(ink, fade), 4)
				prev = q3
			prev = p
			for i in n:
				var x2 := float(i)
				var q4 := p + d * x2 + d.orthogonal() * sin(x2 * 0.5 - u * 20.0) * 2.5 * (x2 / maxf(1.0, r))
				_pline(prev, q4, Color(c, fade), 2)
				prev = q4
			# the tip, with a sucker
			draw_circle(prev.floor(), 2.5, Color(ink, fade))
			draw_circle(prev.floor(), 1.5, Color(Pal.e("rose"), fade))
		"kick":
			# a low swoosh along the ground
			var a0 := d.angle() - 1.0 + u * 0.6
			_parc(p, r, a0, a0 + 1.4 * minf(1.0, u * 3.0), Color(ink, fade), 3)
			_parc(p, r, a0, a0 + 1.4 * minf(1.0, u * 3.0), Color(c, fade), 1)
		"coil":
			# coils wrap the target and tighten
			var tight := r + 5.0 - minf(1.0, u * 4.0) * 3.0
			var pulse := 1.0 if int(float(an["t"]) * 8.0) % 2 == 0 else 0.0
			for i in 3:
				var y := (i - 1) * 3.0
				_parc(p + Vector2(0, y), tight - pulse, 0.0, PI, Color(ink, fade), 3)
				_parc(p + Vector2(0, y), tight - pulse, 0.0, PI, Color(c, fade), 1)
		"speed":
			# speed lines along the charge
			var len := minf(1.0, u * 1.5) * 70.0
			for i in 3:
				var so := d.orthogonal() * ((i - 1) * 5.0)
				_pline(p + so + Vector2(0, -4), p + so + Vector2(0, -4) + d * len, Color(c, fade * (0.8 - i % 2 * 0.3)), 1, 2)
		"notes":
			# music notes drift to the target
			for i in 4:
				var f2 := clampf(u * 1.4 - i * 0.2, 0.0, 1.0)
				if f2 <= 0.0 or f2 >= 1.0:
					continue
				var q5 := (p + d * r * f2 + Vector2(0, sin(f2 * 9.0 + i) * 4.0 - 2.0)).floor()
				var nc := Color(c, 1.0 - f2 * 0.5)
				draw_rect(Rect2(q5 - Vector2(1, 1), Vector2(5, 4)), Color(ink, nc.a))
				draw_rect(Rect2(q5, Vector2(3, 2)), nc)
				_pline(q5 + Vector2(2, 0), q5 + Vector2(2, -6), nc, 1)
				_pline(q5 + Vector2(3, -6), q5 + Vector2(5, -4), nc, 1)
		"hearts":
			for i in 3:
				var q6 := p + Vector2((i - 1) * 5.0, -u * 12.0 - i * 2.0)
				var hc := Color(c, fade)
				draw_rect(Rect2(q6.floor() + Vector2(-2, 0), Vector2(2, 1)), hc)
				draw_rect(Rect2(q6.floor() + Vector2(1, 0), Vector2(2, 1)), hc)
				draw_rect(Rect2(q6.floor() + Vector2(-2, 1), Vector2(5, 1)), hc)
				draw_rect(Rect2(q6.floor() + Vector2(-1, 2), Vector2(3, 1)), hc)
				_dot(q6 + Vector2(0, 3), hc)
		"splat":
			# the glob bursts: a blob and flying drops
			draw_circle(p.floor(), maxf(1.0, 4.0 * (1.0 - u)), Color(c, fade))
			for i in 6:
				var a3 := i * TAU / 6.0 + float(an["seed"])
				_dot(p + Vector2(cos(a3), sin(a3) * 0.7) * (3.0 + u * 10.0), Color(c, fade))
		"bubbles":
			# poison bubbles rising for as long as it lasts
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = int(an["seed"])
			for i in 5:
				var ph := fmod(float(an["t"]) * 1.2 + rng2.randf(), 1.0)
				var q7 := p + Vector2(rng2.randf_range(-r, r) * 0.6, -ph * 14.0)
				var bc2 := Color(c, (1.0 - ph) * fade)
				_parc(q7, 2.0, 0.0, TAU, Color(Pal.INK, bc2.a * 0.6), 2)
				_parc(q7, 2.0, 0.0, TAU, bc2)
		"yolk":
			# the egg bursts: yolk in the middle, white all around
			draw_set_transform(p.floor(), 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, r * (0.5 + u * 0.5), Color(1, 1, 1, 0.5 * fade))
			draw_circle(Vector2.ZERO, r * 0.3, Color(c, fade))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
