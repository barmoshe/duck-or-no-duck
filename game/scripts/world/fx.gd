class_name Fx
extends Node2D
## Pixel juice in world space: square particles, expanding rings, cones, falling-bread
## shadows and floating numbers in the pixel font. Everything snaps to whole pixels.

var bits: Array = []  # {p, v, life, max, c, s, g}
var rings: Array = []  # {p, r0, r1, t, dur, c}
var cones: Array = []  # {p, dir, len, arc, t, dur, c}
var texts: Array = []  # {p, s, t, dur, c, big}
var marks: Array = []  # {p, r, t, dur, c} telegraph circles
var chew_on := false  # the chewing ring over a carcass
var chew_p := Vector2.ZERO
var chew_frac := 0.0
var slashes: Array = []  # {p, dir, r, t, dur, c, flip} crescent swipes
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
	for arr in [rings, cones, texts, marks, slashes]:
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
	if chew_on:
		var cp := chew_p.floor()
		draw_circle(cp, 5.0, Color(Pal.INK, 0.6))
		draw_arc(cp, 3.5, -PI * 0.5, -PI * 0.5 + TAU * clampf(chew_frac, 0.0, 1.0), 16, Pal.e("salmon"), 2.0)
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
