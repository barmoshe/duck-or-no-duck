class_name Sculptor
extends RefCounted
## Draws a Genome as pixel art, "living clay" style. The body is built from soft blobs and
## tapered capsules (body, neck, head, tail, legs, arms) that melt into each other with a
## smooth union, so new parts grow out of the body instead of being stuck on. Four layers:
## FAR (the far legs and wing, one shade darker), BODY, NEAR (near legs, arms, wing) and
## HARD (beak, bill, horns, claws, shell, stinger: crisp, in the accent ramp).
## Each layer gets a distance grid; the grid gives the bevel light (top-left, 4 cel steps),
## the mochi sheen, rim light, inner contour lines and the outline. Faces (eyes, mouth) are
## hand-made pixel stamps so they stay crisp and cute. All on the CPU, cached per genome.

const L_FAR := 0
const L_BODY := 1
const L_NEAR := 2
const L_HARD := 3

# materials
const M_BODY := 0
const M_ACCENT := 1
const M_HEAD := 2  # the head (duck green on a mallard)
const M_GLASS := 3  # insect wings
const M_PINK := 4  # tentacles, inner ears
const M_DARK := 5  # mouths

const LIGHT := Vector2(-0.6, -0.8)
const IDLE_N := 4
const WALK_N := 4

static var _cache := {}


# ------------------------------------------------------------------ public
## {"idle": [4 tex], "walk": [6 tex], "bite": [1 tex], "size": Vector2i, "foot": Vector2}
static func frames(g: Dictionary) -> Dictionary:
	var k := Genome.key(g)
	if _cache.has(k):
		return _cache[k]
	var poses: Array = []
	for i in IDLE_N:
		poses.append({"anim": "idle", "i": i, "breathe": 1 if i == 1 else 0, "blink": i == 3})
	for i in WALK_N:
		poses.append({"anim": "walk", "i": i, "ph": float(i) / WALK_N})
	poses.append({"anim": "bite", "i": 0, "lunge": 1.0})
	var rigs: Array = []
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for ps in poses:
		var rg := rig(g, ps)
		rigs.append(rg)
		var bb: Rect2 = rg["bounds"]
		lo = lo.min(bb.position)
		hi = hi.max(bb.end)
	var pad := 3.0
	var origin := Vector2(floorf(-lo.x + pad), floorf(-lo.y + pad))
	var size := Vector2i(int(ceilf(hi.x - lo.x + pad * 2)), int(ceilf(hi.y - lo.y + pad * 2)))
	var out := {"idle": [], "walk": [], "bite": [], "size": size, "foot": origin}
	var rest_tex: ImageTexture = null
	for i in poses.size():
		var tex: ImageTexture
		if String(poses[i]["anim"]) == "idle" and int(poses[i]["i"]) == 2 and rest_tex != null:
			tex = rest_tex  # the idle loop returns to rest: same frame
		else:
			tex = ImageTexture.create_from_image(draw(g, rigs[i], size, origin))
		if String(poses[i]["anim"]) == "idle" and int(poses[i]["i"]) == 0:
			rest_tex = tex
		match String(poses[i]["anim"]):
			"idle":
				out["idle"].append(tex)
			"walk":
				out["walk"].append(tex)
			_:
				out["bite"].append(tex)
	_cache[k] = out
	return out


static func clear_cache() -> void:
	_cache.clear()
	_stills.clear()


static var _stills := {}


## Just the rest pose (one render instead of eight): portraits, UI previews and the
## in-between bodies of a morph. {"tex", "size", "foot"}; uses the full set if cached.
static func single(g: Dictionary) -> Dictionary:
	var k := Genome.key(g)
	if _cache.has(k):
		var fr: Dictionary = _cache[k]
		return {"tex": fr["idle"][0], "size": fr["size"], "foot": fr["foot"]}
	if _stills.has(k):
		return _stills[k]
	var rg := rig(g, {"anim": "idle", "i": 0})
	var bb: Rect2 = rg["bounds"]
	var pad := 3.0
	var origin := Vector2(floorf(-bb.position.x + pad), floorf(-bb.position.y + pad))
	var size := Vector2i(int(ceilf(bb.size.x + pad * 2)), int(ceilf(bb.size.y + pad * 2)))
	var out := {"tex": ImageTexture.create_from_image(draw(g, rg, size, origin)), "size": size, "foot": origin}
	if _stills.size() > 256:
		_stills.clear()
	_stills[k] = out
	return out


## One still image (idle pose), for portraits and UI.
static func still(g: Dictionary) -> Image:
	return (single(g)["tex"] as Texture2D).get_image()


# ------------------------------------------------------------------ primitives
static func _e(layer: int, mat: int, c: Vector2, rx: float, ry: float, k: float = 2.5, gloss: bool = false) -> Dictionary:
	return {"t": 0, "l": layer, "m": mat, "a": c, "rx": maxf(0.6, rx), "ry": maxf(0.6, ry), "k": k, "gloss": gloss}


static func _c(layer: int, mat: int, a: Vector2, b: Vector2, ra: float, rb: float, k: float = 2.0) -> Dictionary:
	return {"t": 1, "l": layer, "m": mat, "a": a, "b": b, "ra": maxf(0.5, ra), "rb": maxf(0.5, rb), "k": k, "gloss": false}


## Build the primitives for one pose. Local space: x forward, y down, ground at y = 0,
## body center at x = 0. Returns {prims, decals, anchors, bounds}.
static func rig(g: Dictionary, pose: Dictionary) -> Dictionary:
	var prims: Array = []
	var dec: Array = []
	var plan := String(g["plan"])
	var ln := float(g["len"])
	var h := float(g["h"])
	var ph := float(pose.get("ph", 0.0))
	var walking := String(pose.get("anim", "")) == "walk"
	var lunge := float(pose.get("lunge", 0.0))
	var breathe := int(pose.get("breathe", 0))
	var leg_len := float(g["leg_len"]) if int(g["legs"]) > 0 else 0.0
	var bob := 0.0
	if walking:
		bob = -1.0 if (int(pose["i"]) % 3) == 1 else 0.0
	var sq := 0.0  # squash for blobs
	if plan == "blob" and walking:
		sq = [0.0, -1.5, -1.0, 0.0, 1.0, 0.5][int(pose["i"]) % 6]
		bob = [0.0, -2.0, -3.0, -1.0, 0.0, 0.0][int(pose["i"]) % 6]
	var hh := h + breathe - sq
	var cy := -(leg_len + hh * 0.5 - float(g["sink"])) + bob
	if plan == "blob":
		cy = -hh * 0.5 + bob
	var C := Vector2(lunge * 1.0, cy)
	var jelly := float(g["jelly"])
	# ---- body
	match plan:
		"blob":
			var w := ln * 0.5 + sq * 0.6
			prims.append(_e(L_BODY, M_BODY, C, w, hh * 0.5, 3.0, true))
			# the puddle skirt: a wide flat base so a slime sits like a drop
			prims.append(_e(L_BODY, M_BODY, Vector2(C.x, -hh * 0.2 + bob * 0.3), w * 1.08, hh * 0.24, 3.0))
		"bug", "serpent":
			var n := int(g["segs"])
			for i in n:
				var t := float(i) / maxf(1, n - 1) - 0.5
				var sx := C.x - t * ln * 0.7
				var wave := sin(ph * TAU + i * 1.4) * (1.0 if plan == "serpent" else 0.0)
				var r := h * (0.5 + (0.12 if i == n - 1 else 0.0))
				prims.append(_e(L_BODY, M_BODY, Vector2(sx, C.y + wave), ln / (n * 1.6), r, 1.2 if plan == "bug" else 3.0, true))
		"fish":
			prims.append(_e(L_BODY, M_BODY, C, ln * 0.5, h * 0.5, 2.5, true))
			prims.append(_e(L_BODY, M_BODY, C + Vector2(ln * 0.2, 0), ln * 0.3, h * 0.55, 3.0))
		"flat":
			prims.append(_e(L_BODY, M_BODY, C, ln * 0.5, h * 0.5, 2.5, true))
		"duck":
			prims.append(_e(L_BODY, M_BODY, C, ln * 0.5, h * 0.5, 3.0, true))
			prims.append(_e(L_BODY, M_BODY, C + Vector2(-ln * 0.25, -h * 0.12), ln * 0.3, h * 0.38, 3.0))
		_:
			# quad, bird, frog: chest + hips (+ hump)
			var segs := int(g["segs"])
			if segs >= 2:
				prims.append(_e(L_BODY, M_BODY, C + Vector2(ln * 0.18, -float(g["hump"]) * 0.5), ln * 0.33, hh * 0.5, 3.0, true))
				prims.append(_e(L_BODY, M_BODY, C + Vector2(-ln * 0.2, 0), ln * 0.31, hh * 0.46, 3.0))
				if float(g["hump"]) > 0.5:
					prims.append(_e(L_BODY, M_BODY, C + Vector2(0, -hh * 0.3 - float(g["hump"]) * 0.5), ln * 0.25, float(g["hump"]) + 2.0, 3.0))
			else:
				prims.append(_e(L_BODY, M_BODY, C, ln * 0.5, hh * 0.5, 3.0, true))
	# ---- head
	var head := float(g["head"])
	var H := C + Vector2(ln * 0.18, -hh * 0.08)
	var face_r := minf(ln, hh) * 0.5
	if head > 0.0:
		var nb := C + Vector2(ln * (0.42 if plan != "duck" else 0.36), -hh * 0.25)
		var nu := float(g["neck_up"])
		var nk := float(g["neck"])
		var bob_head := (-1.0 if walking and int(pose["i"]) % 2 == 1 else 0.0)
		H = nb + Vector2(cos(nu) * nk + float(g["head_fwd"]) + head * 0.35 + lunge * 2.0, -sin(nu) * nk - head * 0.2 + bob_head)
		if plan == "bug":
			H = C + Vector2(ln * 0.5 + head * 0.4 + lunge * 2.0, -hh * 0.05)
		if nk > 0.5:
			prims.append(_c(L_BODY, M_BODY, nb, H, head * 0.62, head * 0.55, 2.0))
		prims.append(_e(L_BODY, M_HEAD, H, head * 1.08, head, 2.0 if plan != "bug" else 1.0, true))
		face_r = head
	# ---- tail
	var tail := float(g["tail"])
	var tip := String(g["tail_tip"])
	if tail > 0.5:
		var t0 := C + Vector2(-ln * 0.45, -hh * 0.12)
		var up := float(g["tail_up"])
		var sway := sin(ph * TAU) * 1.5 if walking else 0.0
		var t1 := t0 + Vector2(-tail * 0.55, -tail * 0.3 * up + sway * 0.5)
		var t2 := t1 + Vector2(-tail * 0.45 * (1.0 - up * 0.4), -tail * 0.6 * up + sway)
		var tw := float(g["tail_w"]) * (1.0 + float(g["size"]) / 20.0)
		match tip:
			"fin":
				prims.append(_c(L_BODY, M_BODY, t0, t1, hh * 0.3, 1.2, 2.5))
				prims.append(_c(L_NEAR, M_BODY, t1, t1 + Vector2(-tail * 0.45, -tail * 0.45 + sway), 1.2, 1.6, 1.0))
				prims.append(_c(L_NEAR, M_BODY, t1, t1 + Vector2(-tail * 0.45, tail * 0.4 + sway), 1.2, 1.6, 1.0))
			"fluffy":
				prims.append(_c(L_BODY, M_BODY, t0, t1, 1.5, 1.8, 2.0))
				prims.append(_e(L_BODY, M_BODY, t2 + Vector2(1, 1), tail * 0.35, tail * 0.45, 3.0, true))
			"feathers", "fan":
				for f in 3:
					var ang := PI + 0.35 - f * 0.35 - up * 0.5
					prims.append(_c(L_BODY if f != 1 else L_NEAR, M_BODY, t0, t0 + Vector2.from_angle(ang) * tail * (1.0 if f == 1 else 0.8), 1.8, 1.0, 1.5))
			"curl_duck", "curl":
				prims.append(_c(L_BODY, M_BODY, t0, t0 + Vector2(-tail * 0.6, -tail * 0.4), 2.0, 1.4, 2.0))
				dec.append({"k": "curl", "p": t0 + Vector2(-tail * 0.55, -tail * 0.9)})
			"stinger":
				prims.append(_c(L_BODY, M_BODY, t0, t1, tw * 0.8, tw * 0.7, 2.0))
				prims.append(_c(L_BODY, M_BODY, t1, t2, tw * 0.7, tw * 0.6, 2.0))
				prims.append(_c(L_HARD, M_ACCENT, t2, t2 + Vector2(tail * 0.3, -tail * 0.1), 1.6, 0.5, 0.0))
			"nub":
				prims.append(_e(L_BODY, M_BODY, t0 + Vector2(-1, 0), 2.0, 1.8, 2.0))
			_:
				prims.append(_c(L_BODY, M_BODY, t0, t1, tw, tw * 0.75, 2.5))
				prims.append(_c(L_BODY, M_BODY, t1, t2, tw * 0.75, 0.7, 2.0))
	# ---- legs
	var pairs := int(g["legs"])
	var kind := String(g["leg_kind"])
	if pairs > 0 and leg_len > 0.3:
		var lw := float(g["leg_w"])
		for i in pairs:
			var fx := 0.0 if pairs == 1 else lerpf(ln * 0.3, -ln * 0.3, float(i) / (pairs - 1))
			for side in 2:
				var far := side == 0
				var layer := L_FAR if far else L_NEAR
				var phase := ph * TAU + (PI if (i + side) % 2 == 0 else 0.0)
				var swing := sin(phase) * leg_len * 0.45 if walking else 0.0
				var lift := maxf(0.0, cos(phase)) * 1.5 if walking else 0.0
				var off := Vector2(1.5, -1.0) if far else Vector2.ZERO
				var hip := Vector2(C.x + fx, C.y + hh * 0.3) + off
				var foot := Vector2(C.x + fx + swing, -lift) + off
				_leg(prims, layer, kind, hip, foot, lw, leg_len, float(g["size"]))
	elif plan == "blob" and walking:
		pass
	# ---- arms (front, near side)
	var arms := String(g["arms"])
	if arms != "none":
		var a0 := C + Vector2(ln * 0.38, hh * 0.1)
		var asz := float(g["arm_size"]) * float(g["size"]) / 8.0
		if arms == "pincer":
			var open_ := lunge > 0.0
			var a1 := a0 + Vector2(3.0 * asz + lunge * 2.0, 1.5 * asz)
			prims.append(_c(L_NEAR, M_BODY, a0, a1, 1.4 * asz, 1.8 * asz, 1.5))
			prims.append(_e(L_HARD, M_ACCENT, a1 + Vector2(1.5 * asz, 0), 2.6 * asz, 2.0 * asz, 0.0))
			prims.append(_c(L_HARD, M_ACCENT, a1 + Vector2(2.5 * asz, -1.0 * asz), a1 + Vector2(5.0 * asz, (-2.8 if open_ else -1.2) * asz), 1.1 * asz, 0.5, 0.0))
			prims.append(_c(L_HARD, M_ACCENT, a1 + Vector2(2.5 * asz, 1.0 * asz), a1 + Vector2(4.6 * asz, (1.8 if open_ else 0.6) * asz), 0.9 * asz, 0.5, 0.0))
		else:
			var n := int(g["arm_n"])
			for i in n:
				var bx := a0.x - i * 2.5 * asz
				var wv := sin(ph * TAU + i * 1.7) * 1.5 if walking else sin(i * 1.3) * 0.8
				var p1 := Vector2(bx + 1.0, a0.y + 3.0 * asz)
				var p2 := Vector2(bx + 1.0 + wv, maxf(-1.0, a0.y + 6.0 * asz))
				prims.append(_c(L_NEAR, M_PINK, Vector2(bx, a0.y), p1, 1.4 * asz, 1.1 * asz, 1.5))
				prims.append(_c(L_NEAR, M_PINK, p1, p2, 1.1 * asz, 0.6, 1.5))
	# ---- back
	var back := String(g["back"])
	var bs := float(g["back_size"])
	var sh := C + Vector2(-ln * 0.02, -hh * 0.42)
	var flap := (1 if walking and int(pose["i"]) % 2 == 1 else 0)
	match back:
		"wings_bird", "wings_duck":
			for side in 2:
				var layer2 := L_FAR if side == 0 else L_NEAR
				var o := Vector2(2.0, -1.0) if side == 0 else Vector2.ZERO
				var span := (ln * 0.55 + 3.0) * bs
				var lift2 := (-span * 0.35) if flap == 1 else 0.0
				var tipp := sh + o + Vector2(-span * 0.8, -span * 0.25 + lift2)
				prims.append(_c(layer2, M_BODY, sh + o, tipp, hh * 0.28 * bs, 1.2, 2.0))
				for f in 3:
					var fe := tipp + Vector2(f * span * 0.18, span * 0.12 + f * 0.8)
					prims.append(_c(layer2, M_BODY, sh + o + Vector2(-span * 0.2 * f, hh * 0.05), fe, 1.3, 0.8, 1.2))
		"wings_bug":
			for side in 2:
				var o2 := Vector2(2.0, -1.0) if side == 0 else Vector2.ZERO
				var up2 := -2.0 if flap == 1 else 0.0
				prims.append(_e(L_HARD if side == 1 else L_FAR, M_GLASS, sh + o2 + Vector2(-ln * 0.25 * bs, -hh * 0.35 + up2), ln * 0.3 * bs, hh * 0.25 * bs, 0.0))
		"shell":
			var bsc := minf(bs, 1.3)
			var sc := C + Vector2(-ln * 0.12, -hh * 0.32)
			prims.append(_e(L_HARD, M_ACCENT, sc, ln * 0.33 * bsc, hh * 0.42 * bsc, 0.0, true))
			dec.append({"k": "spiral", "p": sc, "r": minf(ln * 0.33 * bsc, hh * 0.42 * bsc)})
		"spines":
			for i in 4:
				var sx := C.x + ln * (0.25 - i * 0.17)
				var top := C.y - hh * 0.45
				prims.append(_c(L_HARD, M_ACCENT, Vector2(sx, top + 1.5), Vector2(sx - 1.0, top - 3.0 * bs), 1.4, 0.4, 0.0))
		"plating":
			for i in 3:
				var px := C.x + ln * (0.2 - i * 0.2)
				prims.append(_e(L_HARD, M_ACCENT, Vector2(px, C.y - hh * 0.38), ln * 0.13, hh * 0.18, 0.0))
		"fin":
			prims.append(_c(L_BODY, M_BODY, C + Vector2(0, -hh * 0.4), C + Vector2(-ln * 0.15, -hh * 0.75 - 2.0), 2.2, 0.6, 2.0))
	# ---- crown (on the head, or on the body's front-top for faces on bodies)
	var top_p := H + Vector2(0, -face_r * 0.85)
	var cs := minf(float(g["crown_size"]), 1.6) * clampf(face_r / 5.0, 0.8, 1.3)
	match String(g["crown"]):
		"ears":
			for side in 2:
				var ox := -face_r * (0.35 if side == 0 else 0.0)
				var el := minf(4.0 * cs, face_r * 0.9)
				prims.append(_c(L_FAR if side == 0 else L_BODY, M_BODY, top_p + Vector2(ox, 1.0), top_p + Vector2(ox - el * 0.25, -el), minf(1.8 * cs, face_r * 0.4), minf(1.0 * cs, face_r * 0.25), 1.5))
		"horns", "horns_ram":
			var n2 := clampi(int(g["crown_n"]), 1, 2)
			for i in n2:
				var hx := top_p + Vector2(-i * face_r * 0.5, 1.0)
				if String(g["crown"]) == "horns_ram":
					prims.append(_c(L_HARD, M_ACCENT, hx, hx + Vector2(-3.0 * cs, -1.5 * cs), 1.6 * cs, 1.2 * cs, 0.0))
					prims.append(_c(L_HARD, M_ACCENT, hx + Vector2(-3.0 * cs, -1.5 * cs), hx + Vector2(-3.5 * cs, 1.5 * cs), 1.2 * cs, 0.7, 0.0))
				else:
					prims.append(_c(L_HARD, M_ACCENT, hx, hx + Vector2(-1.5 * cs, -4.5 * cs), 1.5 * cs, 0.5, 0.0))
		"antennae":
			for i in 2:
				var ax := top_p + Vector2(-i * 2.0, 0.5)
				var tipa := ax + Vector2(2.0 - i * 1.5, -5.0 * cs)
				prims.append(_c(L_HARD, M_ACCENT, ax, tipa, 0.5, 0.5, 0.0))
				prims.append(_e(L_HARD, M_ACCENT, tipa, 1.2, 1.2, 0.0))
		"crest", "mane", "frill", "crest_duck":
			var n3 := 3
			for i in n3:
				var cx := top_p + Vector2(-i * 1.6 * cs + 1.0, 1.0)
				prims.append(_c(L_HARD if String(g["crown"]) != "crest_duck" else L_BODY, M_ACCENT if String(g["crown"]) != "crest_duck" else M_HEAD,
					cx, cx + Vector2(-2.0 * cs, -3.5 * cs + i * 0.8), 1.1 * cs, 0.5, 0.0 if String(g["crown"]) != "crest_duck" else 1.5))
	# ---- mouth (hard parts are primitives, the rest are stamps)
	var mouth := String(g["mouth"])
	var mp := H + Vector2(face_r * 0.85, face_r * 0.2)
	var ms := minf(float(g["mouth_size"]), 1.6) * clampf(face_r / 5.0, 0.8, 1.3)
	match mouth:
		"beak":
			var open2 := lunge > 0.0
			prims.append(_c(L_HARD, M_ACCENT, mp + Vector2(-1.0, -1.0), mp + Vector2(4.0 * ms, -0.2 + (-1.0 if open2 else 0.0)), 1.5 * ms, 0.5, 0.0))
			if open2:
				prims.append(_c(L_HARD, M_ACCENT, mp + Vector2(-1.0, 0.5), mp + Vector2(3.0 * ms, 1.5), 1.0 * ms, 0.4, 0.0))
		"bill":
			var open3 := lunge > 0.0
			prims.append(_c(L_HARD, M_ACCENT, mp + Vector2(-1.5, -0.8), mp + Vector2(3.5 * ms, -0.5 + (-0.8 if open3 else 0.0)), 1.5 * ms, 1.4 * ms, 0.0))
			if open3:
				prims.append(_c(L_HARD, M_ACCENT, mp + Vector2(-1.0, 1.2), mp + Vector2(3.0 * ms, 1.6), 1.0 * ms, 1.0 * ms, 0.0))
		"snout":
			prims.append(_c(L_BODY, M_HEAD, mp + Vector2(-2.0, -0.5), mp + Vector2(2.5 * ms, 0.0), 1.9 * ms, 1.5 * ms, 1.5))
			dec.append({"k": "nose", "p": mp + Vector2(2.5 * ms + 1.0, -0.8)})
		"mandibles", "pincers":
			for sgn in [-1.0, 1.0]:
				prims.append(_c(L_HARD, M_ACCENT, mp + Vector2(0.5, sgn * 1.0), mp + Vector2(3.0 * ms, sgn * (1.6 + lunge)), 0.9 * ms, 0.4, 0.0))
		_:
			dec.append({"k": "mouth_" + mouth, "p": mp + Vector2(-1.0, 0.0), "open": lunge > 0.0})
	# ---- eyes
	var en := clampi(int(g["eye_n"]), 1, 6)
	var eye_style := String(g["eyes"])
	var ep := H + Vector2(face_r * 0.35, -face_r * 0.22)
	if eye_style == "stalks":
		for i in 2:
			var sb := H + Vector2(face_r * 0.2 - i * 2.5, -face_r * 0.7)
			var st := sb + Vector2(0.5, -4.0)
			prims.append(_c(L_BODY if i == 1 else L_FAR, M_HEAD, sb, st, 0.8, 0.8, 1.0))
			dec.append({"k": "eye", "s": "beady", "p": st + Vector2(0, -1), "blink": pose.get("blink", false), "near": i == 0})
	else:
		for i in en:
			var row := i / 2
			var col := i % 2
			var p := ep + Vector2(-col * maxf(2.5, face_r * 0.5) - row * 1.0, -row * 2.5)
			dec.append({"k": "eye", "s": eye_style, "p": p, "blink": pose.get("blink", false), "near": col == 0, "size": float(g["eye_size"])})
	# ---- bounds
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for pr in prims:
		var bb := _bbox(pr)
		lo = lo.min(bb.position)
		hi = hi.max(bb.end)
	for d in dec:
		lo = lo.min((d["p"] as Vector2) - Vector2(3, 3))
		hi = hi.max((d["p"] as Vector2) + Vector2(3, 3))
	hi.y = maxf(hi.y, 0.0)
	return {"prims": prims, "decals": dec, "bounds": Rect2(lo, hi - lo), "head": H, "face_r": face_r, "body": C}


static func _leg(prims: Array, layer: int, kind: String, hip: Vector2, foot: Vector2, lw: float, ll: float, size: float) -> void:
	match kind:
		"stub":
			prims.append(_c(layer, M_BODY, hip, foot + Vector2(0, -lw * 0.5), lw, lw * 0.9, 2.0))
			prims.append(_e(layer, M_BODY, foot + Vector2(0.8, -lw * 0.45), lw * 1.05, lw * 0.5, 1.5))
		"digi":
			var knee := hip.lerp(foot, 0.5) + Vector2(-ll * 0.25, 0)
			prims.append(_c(layer, M_BODY, hip, knee, lw * 1.2, lw * 0.8, 2.0))
			prims.append(_c(layer, M_BODY, knee, foot + Vector2(0, -1.0), lw * 0.8, lw * 0.6, 1.5))
			prims.append(_e(layer, M_BODY, foot + Vector2(1.0, -0.6), lw * 0.9, 0.9, 1.0))
		"insect", "crab":
			var knee2 := hip + Vector2((foot.x - hip.x) * 0.5 + 1.5, -ll * 0.35)
			var m := M_ACCENT if kind == "crab" else M_BODY
			prims.append(_c(layer, m, hip, knee2, 0.9, 0.7, 0.8))
			prims.append(_c(layer, m, knee2, foot + Vector2(1.5, -0.3), 0.7, 0.5, 0.8))
		"frog":
			var th := hip + Vector2(-ll * 0.4, ll * 0.5)
			prims.append(_e(layer, M_BODY, th, lw * 1.2, ll * 0.45, 2.0))
			prims.append(_c(layer, M_BODY, th, foot + Vector2(-1.0, -0.8), lw * 0.7, lw * 0.5, 1.5))
			prims.append(_e(layer, M_BODY, foot + Vector2(0.5, -0.5), lw * 0.9, 0.8, 1.0))
		"webbed":
			prims.append(_c(layer, M_ACCENT, hip, foot + Vector2(0, -1.0), 0.9, 0.8, 0.5))
			prims.append(_c(L_HARD if layer == L_NEAR else layer, M_ACCENT, foot + Vector2(-1.0, -0.8), foot + Vector2(2.5, -0.6), 1.1, 1.0, 0.0))
		"stilt":
			prims.append(_c(layer, M_ACCENT, hip, foot + Vector2(0, -1.0), 0.8, 0.6, 0.5))
			prims.append(_c(layer, M_ACCENT, foot + Vector2(-1.5, -0.6), foot + Vector2(2.0, -0.6), 0.6, 0.6, 0.0))
		"cilia":
			prims.append(_c(layer, M_BODY, hip, foot + Vector2(0, -0.5), 0.8, 0.6, 1.5))
		_:
			prims.append(_c(layer, M_BODY, hip, foot, lw, lw * 0.8, 2.0))


static func _bbox(p: Dictionary) -> Rect2:
	var k := float(p["k"]) + 1.0
	if int(p["t"]) == 0:
		var r := Vector2(float(p["rx"]), float(p["ry"])) + Vector2(k, k)
		return Rect2((p["a"] as Vector2) - r, r * 2.0)
	var a: Vector2 = p["a"]
	var b: Vector2 = p["b"]
	var rr := maxf(float(p["ra"]), float(p["rb"])) + k
	var lo := a.min(b) - Vector2(rr, rr)
	var hi := a.max(b) + Vector2(rr, rr)
	return Rect2(lo, hi - lo)


static func _sdf(p: Dictionary, q: Vector2) -> float:
	if int(p["t"]) == 0:
		var rx := float(p["rx"])
		var ry := float(p["ry"])
		var d := q - (p["a"] as Vector2)
		var l := Vector2(d.x / rx, d.y / ry).length()
		return (l - 1.0) * minf(rx, ry)
	# uneven capsule (Inigo Quilez), in the segment's frame
	var a: Vector2 = p["a"]
	var b: Vector2 = p["b"]
	var r1 := float(p["ra"])
	var r2 := float(p["rb"])
	var ab := b - a
	var hl := ab.length()
	if hl < 0.001:
		return (q - a).length() - maxf(r1, r2)
	var ay := ab / hl
	var ax := Vector2(ay.y, -ay.x)
	var pl := Vector2(absf((q - a).dot(ax)), (q - a).dot(ay))
	var bb := (r1 - r2) / hl
	var aa := sqrt(maxf(0.0, 1.0 - bb * bb))
	var kk := pl.dot(Vector2(-bb, aa))
	if kk < 0.0:
		return pl.length() - r1
	if kk > aa * hl:
		return (pl - Vector2(0.0, hl)).length() - r2
	return pl.dot(Vector2(aa, bb)) - r1


# ------------------------------------------------------------------ drawing
static func _ramps(g: Dictionary) -> Dictionary:
	var body := String(g["ramp"])
	return {
		M_BODY: Pal.ramp(body),
		M_ACCENT: Pal.ramp(String(g["accent"])),
		M_HEAD: Pal.ramp(String(g["head_ramp"]) if String(g["head_ramp"]) != "" else body),
		M_GLASS: Pal.ramp("snow"),
		M_PINK: Pal.ramp("pink"),
		M_DARK: Pal.ramp("night"),
	}


static func draw(g: Dictionary, rg: Dictionary, size: Vector2i, origin: Vector2) -> Image:
	var W := size.x
	var Hh := size.y
	var n := W * Hh
	var grids: Array = []
	var mats: Array = []
	for l in 4:
		var gr := PackedFloat32Array()
		gr.resize(n)
		gr.fill(99.0)
		grids.append(gr)
		var mt := PackedByteArray()
		mt.resize(n)
		mats.append(mt)
	var prims: Array = rg["prims"]
	for pr in prims:
		var l2 := int(pr["l"])
		var gr2: PackedFloat32Array = grids[l2]
		var mt2: PackedByteArray = mats[l2]
		var bb := _bbox(pr)
		var x0 := maxi(0, int(floorf(bb.position.x + origin.x)))
		var x1 := mini(W - 1, int(ceilf(bb.end.x + origin.x)))
		var y0 := maxi(0, int(floorf(bb.position.y + origin.y)))
		var y1 := mini(Hh - 1, int(ceilf(bb.end.y + origin.y)))
		var k := float(pr["k"])
		var smooth := k > 0.01
		var ik := 1.0 / maxf(0.01, k)
		var m := int(pr["m"])
		var a: Vector2 = (pr["a"] as Vector2) + origin
		if int(pr["t"]) == 0:
			var rx := float(pr["rx"])
			var ry := float(pr["ry"])
			var irx := 1.0 / rx
			var iry := 1.0 / ry
			var mr := minf(rx, ry)
			for y in range(y0, y1 + 1):
				var ny := (y + 0.5 - a.y) * iry
				var ny2 := ny * ny
				var row := y * W
				for x in range(x0, x1 + 1):
					var nx := (x + 0.5 - a.x) * irx
					var d := (sqrt(nx * nx + ny2) - 1.0) * mr
					var i := row + x
					var old := gr2[i]
					if d < old:
						mt2[i] = m
					if smooth and old < 90.0:
						var hk := maxf(k - absf(old - d), 0.0) * ik
						gr2[i] = minf(old, d) - hk * hk * k * 0.25
					elif d < old:
						gr2[i] = d
		else:
			var b: Vector2 = (pr["b"] as Vector2) + origin
			var r1 := float(pr["ra"])
			var r2 := float(pr["rb"])
			var ab := b - a
			var hl := ab.length()
			var ayx := 0.0
			var ayy := 1.0
			if hl > 0.001:
				ayx = ab.x / hl
				ayy = ab.y / hl
			var bb2 := (r1 - r2) / maxf(hl, 0.001)
			var aa := sqrt(maxf(0.0, 1.0 - bb2 * bb2))
			var ahl := aa * hl
			for y in range(y0, y1 + 1):
				var qy := y + 0.5 - a.y
				var row2 := y * W
				for x in range(x0, x1 + 1):
					var qx := x + 0.5 - a.x
					var d2: float
					if hl < 0.001:
						d2 = sqrt(qx * qx + qy * qy) - maxf(r1, r2)
					else:
						var px_ := absf(qx * ayy - qy * ayx)
						var py_ := qx * ayx + qy * ayy
						var kk := -bb2 * px_ + aa * py_
						if kk < 0.0:
							d2 = sqrt(px_ * px_ + py_ * py_) - r1
						elif kk > ahl:
							var dy2 := py_ - hl
							d2 = sqrt(px_ * px_ + dy2 * dy2) - r2
						else:
							d2 = aa * px_ + bb2 * py_ - r1
					var i2 := row2 + x
					var old2 := gr2[i2]
					if d2 < old2:
						mt2[i2] = m
					if smooth and old2 < 90.0:
						var hk2 := maxf(k - absf(old2 - d2), 0.0) * ik
						gr2[i2] = minf(old2, d2) - hk2 * hk2 * k * 0.25
					elif d2 < old2:
						gr2[i2] = d2
	var ramps := _ramps(g)
	var jelly := float(g["jelly"])
	var C: Vector2 = rg["body"]
	var hh := float(g["h"])
	var belly_ramp: Array = Pal.ramp(String(g["belly"])) if String(g["belly"]) != "" else []
	var px := PackedColorArray()
	px.resize(n)
	px.fill(Color(0, 0, 0, 0))
	var layer_at := PackedByteArray()
	layer_at.resize(n)
	layer_at.fill(255)
	var g0: PackedFloat32Array = grids[0]
	var g1: PackedFloat32Array = grids[1]
	var g2: PackedFloat32Array = grids[2]
	var g3: PackedFloat32Array = grids[3]
	var mats_l: Array = mats
	for y in Hh:
		for x in W:
			var i := y * W + x
			var top := -1
			if g3[i] < 0.0:
				top = 3
			elif g2[i] < 0.0:
				top = 2
			elif g1[i] < 0.0:
				top = 1
			elif g0[i] < 0.0:
				top = 0
			if top < 0:
				continue
			layer_at[i] = top
			var gr3: PackedFloat32Array = g3 if top == 3 else (g2 if top == 2 else (g1 if top == 1 else g0))
			var d0 := gr3[i]
			# bevel light from the distance gradient
			var dx := _gd(gr3, x + 1, y, W, Hh, d0) - _gd(gr3, x - 1, y, W, Hh, d0)
			var dy := _gd(gr3, x, y + 1, W, Hh, d0) - _gd(gr3, x, y - 1, W, Hh, d0)
			var gv := Vector2(dx, dy)
			var facing := gv.normalized().dot(LIGHT) if gv.length() > 0.01 else 0.0
			var edge := clampf(1.0 - (-d0) / 3.2, 0.0, 1.0)
			var s := 0.56 + 0.5 * facing * edge
			var ly := float(y) - origin.y
			if ly > C.y + hh * 0.3 and top != L_HARD:
				s -= 0.12
			var mat := int((mats_l[top] as PackedByteArray)[i])
			var ramp: Array = ramps.get(mat, ramps[M_BODY])
			if mat == M_BODY and not belly_ramp.is_empty() and top == L_BODY and ly > C.y + hh * 0.12 and d0 < -1.2:
				ramp = belly_ramp
				s += 0.1
			var step := 1
			if s > 0.84:
				step = 4
			elif s > 0.58:
				step = 3
			elif s > 0.3:
				step = 2
			if top == L_FAR:
				step = maxi(1, step - 1)
			if jelly > 0.5 and top == L_BODY and mat == M_BODY:
				# jelly: a light body with a glowing lower rim (light passing through)
				step = maxi(2, step)
				if d0 > -2.4 and d0 < -1.0 and ly > C.y and facing < 0.2:
					step = 4
			px[i] = ramp[step]
	# inner contours: a near part over the body, the body over a far part, hard edges
	var src := px.duplicate()
	for y in Hh:
		for x in W:
			var i := y * W + x
			var top2 := int(layer_at[i])
			if top2 == 255:
				continue
			var d1 := g3[i] if top2 == 3 else (g2[i] if top2 == 2 else (g1[i] if top2 == 1 else g0[i]))
			if d1 < -1.0:
				continue
			var under := (top2 > 0 and g0[i] < 0.0) or (top2 > 1 and g1[i] < 0.0) or (top2 > 2 and g2[i] < 0.0)
			if under or top2 == L_HARD:
				var c: Color = src[i]
				px[i] = Color(c.darkened(0.42), c.a)
	# pattern on the body
	_pattern(g, px, layer_at, grids, W, Hh, origin, C)
	# mochi sheen: a highlight on each glossy blob
	for pr2 in prims:
		if not pr2["gloss"]:
			continue
		var cc: Vector2 = (pr2["a"] as Vector2) + origin
		var rx := float(pr2["rx"])
		var ry := float(pr2["ry"])
		var hp := cc + Vector2(-rx * 0.42, -ry * 0.5)
		var hr := maxf(0.8, minf(rx, ry) * (0.2 if jelly > 0.5 else 0.12))
		var rmp: Array = ramps.get(int(pr2["m"]), ramps[M_BODY])
		for yy in range(int(hp.y - hr - 1), int(hp.y + hr + 2)):
			for xx in range(int(hp.x - hr * 1.4 - 1), int(hp.x + hr * 1.4 + 2)):
				if xx < 0 or yy < 0 or xx >= W or yy >= Hh:
					continue
				var j := yy * W + xx
				if px[j].a <= 0.0:
					continue
				var dd := Vector2((xx + 0.5 - hp.x) / (hr * 1.4), (yy + 0.5 - hp.y) / hr)
				if dd.length() <= 1.0:
					px[j] = Color.WHITE if jelly > 0.5 else (rmp[4] as Color)
		if jelly > 0.5:
			var h2 := cc + Vector2(-rx * 0.1, -ry * 0.72)
			if int(h2.x) >= 0 and int(h2.y) >= 0 and int(h2.x) < W and int(h2.y) < Hh and px[int(h2.y) * W + int(h2.x)].a > 0.0:
				px[int(h2.y) * W + int(h2.x)] = Color.WHITE
	# decals: eyes, mouths, nose, curls, shell spiral
	for d in rg["decals"]:
		_decal(px, W, Hh, d, origin, g)
	# outline: dark, tinted toward the color it hugs; softer on jelly
	var src2 := px.duplicate()
	for y in Hh:
		for x in W:
			var i := y * W + x
			if src2[i].a > 0.0:
				continue
			var best := Color(0, 0, 0, 0)
			var below := false
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var xx2: int = x + o.x
				var yy2: int = y + o.y
				if xx2 < 0 or yy2 < 0 or xx2 >= W or yy2 >= Hh:
					continue
				var c2 := src2[yy2 * W + xx2]
				if c2.a > 0.0:
					best = c2
					below = o.y == -1
			if best.a > 0.0:
				var ink := Pal.INK.lerp(best.darkened(0.55), 0.35)
				if jelly > 0.5:
					ink = (ramps[M_BODY][1] as Color).lerp(Pal.INK, 0.35)
				if below:
					ink = ink.darkened(0.2)
				px[i] = ink
	var bytes := PackedByteArray()
	bytes.resize(n * 4)
	for i in n:
		var c3 := px[i]
		bytes[i * 4] = int(c3.r * 255.0 + 0.5)
		bytes[i * 4 + 1] = int(c3.g * 255.0 + 0.5)
		bytes[i * 4 + 2] = int(c3.b * 255.0 + 0.5)
		bytes[i * 4 + 3] = int(c3.a * 255.0 + 0.5)
	return Image.create_from_data(W, Hh, false, Image.FORMAT_RGBA8, bytes)


static func _gd(gr: PackedFloat32Array, x: int, y: int, W: int, Hh: int, fallback: float) -> float:
	if x < 0 or y < 0 or x >= W or y >= Hh:
		return fallback + 1.0
	return clampf(gr[y * W + x], -8.0, 3.0)


static func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


static func _pattern(g: Dictionary, px: PackedColorArray, layer_at: PackedByteArray, grids: Array, W: int, Hh: int, origin: Vector2, C: Vector2) -> void:
	var pat := String(g["pattern"])
	if pat == "none" or pat == "":
		return
	var body_ramp := Pal.ramp(String(g["ramp"]))
	var acc := Pal.ramp(String(g["accent"]))
	var gr: PackedFloat32Array = grids[L_BODY]
	for y in Hh:
		for x in W:
			var i := y * W + x
			if int(layer_at[i]) != L_BODY or gr[i] > -1.3:
				continue
			var lx := x - int(origin.x)
			var ly := y - int(origin.y)
			var c := px[i]
			match pat:
				"spots":
					if _hash(lx / 3, ly / 3) > 0.72 and (lx % 3) != 2 and (ly % 3) != 2:
						px[i] = c.darkened(0.22)
				"stripes":
					if ((lx + 64) / 2) % 3 == 0 and ly < C.y + 2:
						px[i] = c.darkened(0.25)
				"scales":
					if (lx + ly * 2) % 4 == 0 and (ly % 2) == 0:
						px[i] = c.lightened(0.18)
				"toxic":
					if _hash(lx, ly) > 0.93 and (lx + ly) % 2 == 0:
						px[i] = acc[3]
				"feathers", "down":
					if (lx + (ly / 2) * 2) % 4 == 0 and (ly % 2) == 0:
						px[i] = c.lightened(0.12)
	if float(g["fuzz"]) > 0.0:
		# a soft fuzzy edge on top
		var src := px.duplicate()
		for y in range(1, Hh):
			for x in W:
				var i2 := y * W + x
				if src[i2].a > 0.0 and src[i2 - W].a <= 0.0 and _hash(x, y) > 0.55:
					px[i2 - W] = src[i2]


# ------------------------------------------------------------------ face stamps
static func _put(px: PackedColorArray, W: int, Hh: int, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < Hh:
		px[y * W + x] = c


static func _decal(px: PackedColorArray, W: int, Hh: int, d: Dictionary, origin: Vector2, g: Dictionary) -> void:
	var p: Vector2 = (d["p"] as Vector2) + origin
	var x := int(floorf(p.x))
	var y := int(floorf(p.y))
	var ink := Color("181425")
	var wht := Color.WHITE
	match String(d["k"]):
		"eye":
			var s := String(d.get("s", "cute"))
			var blink: bool = d.get("blink", false)
			var near: bool = d.get("near", true)
			var big := float(d.get("size", 1.0)) > 1.4 or (float(g["size"]) >= 14.0 and near)
			if blink and s != "compound":
				_put(px, W, Hh, x, y, ink)
				_put(px, W, Hh, x + 1, y, ink)
				return
			match s:
				"dots", "beady", "many":
					_put(px, W, Hh, x, y, ink)
					if s == "beady" or big:
						_put(px, W, Hh, x + 1, y, ink)
						_put(px, W, Hh, x, y - 1, wht if s == "beady" else ink)
				"big":
					for yy in range(-1, 2):
						for xx in range(-1, 2):
							_put(px, W, Hh, x + xx, y + yy, wht)
					_put(px, W, Hh, x + 1, y, ink)
					_put(px, W, Hh, x + 1, y + 1, ink)
					_put(px, W, Hh, x, y + 1, ink)
				"angry":
					_put(px, W, Hh, x, y, ink)
					_put(px, W, Hh, x + 1, y, ink)
					_put(px, W, Hh, x, y + 1, ink)
					_put(px, W, Hh, x + 1, y + 1, Color("e43b44") if big else ink)
					_put(px, W, Hh, x - 1, y - 1, ink)
					_put(px, W, Hh, x, y - 1, ink)
				"compound":
					var cm := Color("68386c")
					for yy2 in range(-1, 2):
						for xx2 in range(0, 2):
							_put(px, W, Hh, x + xx2, y + yy2, cm)
					_put(px, W, Hh, x, y - 1, Color("f6757a"))
					_put(px, W, Hh, x + 1, y + 1, Color("b55088"))
				"glow":
					_put(px, W, Hh, x, y, Color("feae34"))
					_put(px, W, Hh, x + 1, y, Color("fee761"))
					_put(px, W, Hh, x, y + 1, Color("f77622"))
					_put(px, W, Hh, x + 1, y + 1, Color("feae34"))
				_:
					# cute: a tall black eye with a white shine (the Crab look)
					_put(px, W, Hh, x, y, ink)
					_put(px, W, Hh, x, y + 1, ink)
					_put(px, W, Hh, x, y - 1, wht)
					if big or near:
						_put(px, W, Hh, x + 1, y, ink)
						_put(px, W, Hh, x + 1, y + 1, ink)
						_put(px, W, Hh, x + 1, y - 1, ink)
		"mouth_smile":
			_put(px, W, Hh, x, y, ink)
			_put(px, W, Hh, x + 1, y + 1, ink)
			_put(px, W, Hh, x + 2, y, ink)
		"mouth_fangs":
			for i in 4:
				_put(px, W, Hh, x - i, y, ink)
			_put(px, W, Hh, x, y + 1, wht)
			_put(px, W, Hh, x - 2, y + 1, wht)
			if d.get("open", false):
				_put(px, W, Hh, x - 1, y + 1, Color("a22633"))
		"mouth_sucker":
			_put(px, W, Hh, x + 1, y, ink)
			_put(px, W, Hh, x + 1, y + 1, Color("b55088"))
		"mouth_none":
			if d.get("open", false):
				_put(px, W, Hh, x, y, ink)
				_put(px, W, Hh, x + 1, y, ink)
		"nose":
			_put(px, W, Hh, x, y, ink)
		"curl":
			var col := Color("181425")
			_put(px, W, Hh, x, y, col)
			_put(px, W, Hh, x + 1, y - 1, col)
			_put(px, W, Hh, x + 2, y, col)
		"spiral":
			var r := float(d.get("r", 4.0))
			for a in 14:
				var t := float(a) / 14.0
				var rr := r * (0.15 + 0.6 * t)
				var q := p + Vector2.from_angle(t * TAU * 1.4) * rr
				var qi := Vector2i(int(q.x), int(q.y))
				if qi.x >= 0 and qi.y >= 0 and qi.x < W and qi.y < Hh and px[qi.y * W + qi.x].a > 0.0:
					px[qi.y * W + qi.x] = px[qi.y * W + qi.x].darkened(0.3)
