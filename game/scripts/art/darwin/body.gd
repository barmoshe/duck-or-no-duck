class_name DarwinArt
extends RefCounted
## Puddle, drawn by hand after Everything is Crab's Darwin: a front-facing gumdrop blob
## that slumps a little to the left, a blue body, an aqua face on the upper right with dot
## eyes, a navy collar line under the chin, a 1 px ink outline and flat colors. Evolutions
## add hand-drawn parts on top (horns, antennae, a shell, antlers, wings, claws...), each
## at an anchor of the body. Key: k ink, w white, B body, b body shade, F face, f face
## shade, c collar, e eye.

const KEY := {
	"k": "ink", "w": "white", "B": "puddle", "b": "puddle_d", "F": "aqua", "f": "aqua_d", "c": "navy", "e": "eye",
	# parts
	"h": "tan", "H": "leather", "d": "bark", "D": "plum", "g": "leaf", "G": "grass", "j": "pine", "y": "lemon",
	"Y": "amber", "o": "orange", "O": "rust", "r": "red", "R": "wine", "p": "salmon", "P": "rose", "v": "grape",
	"s": "mist", "S": "slate", "l": "steel", "t": "cyan", "q": "peach", "n": "sand", "m": "night", "u": "sky",
	# animals
	"C": "clay", "a": "cocoa", "x": "dusk", "T": "sea", "E": "fern", "A": "sprout",
}

## The body. Anchors: top (between the horns), face (mouth), eye_l / eye_r, back (the
## left flank, for shells and wings), tail (lower left), feet (bottom center), arm (right
## side, the front claw), arm_b (left side, the back claw).
const BODY := {
	"rows": [
		"........kkkk......",
		".......kFwFFk.....",
		"......kFFFFFFk....",
		"......kFFFFFFFk...",
		".....kFFFFFFFFFk..",
		".....kFFFFFFFFFk..",
		".....kbFFcccccck..",
		"....kBBBBBBBBBk...",
		"....kBBBBBBBBBBk..",
		"...kBBBBBBBBBBBk..",
		"..kBBBBBBBBBBBBk..",
		"..kBBBBBBBBBBBBBk.",
		".kBBBBBBBBBBBBBBk.",
		".kBBBBBBBBBBBBBBk.",
		"kBBBBBBBBBBBBBBBk.",
		"kbBBBBBBBBBBBBBbk.",
		".kkkkkkkkkkkkkkk..",
	],
	"eyes": [Vector2i(8, 3), Vector2i(12, 3)],
	"mouth": Vector2i(10, 5),
	"anchors": {
		"top": Vector2i(10, 1), "face": Vector2i(15, 4), "back": Vector2i(3, 10), "tail": Vector2i(1, 14),
		"feet": Vector2i(8, 16), "arm": Vector2i(15, 11), "arm_b": Vector2i(2, 11),
	},
}


# ------------------------------------------------------------------ composing
static var _colors := {}


static func col(ch: String) -> Color:
	if not _colors.has(ch):
		_colors[ch] = Pal.e(String(KEY.get(ch, "ink")))
	return _colors[ch]


## Stamp ASCII rows onto an image at pos (top-left). "." is clear.
static func stamp(img: Image, rows: Array, pos: Vector2i) -> void:
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var px := pos + Vector2i(x, y)
			if px.x >= 0 and px.y >= 0 and px.x < img.get_width() and px.y < img.get_height():
				img.set_pixel(px.x, px.y, col(ch))


## Which part a look slot value means (slot values are shared names across slots).
const SLOT_PART := {
	"crown": {"horns": "horns", "horns_ram": "horns_ram", "antennae": "antennae", "ears": "ears", "crest": "crest",
		"crest_duck": "crest_duck", "frill": "frill", "mane": "mane", "antlers": "antlers"},
	"back": {"wings_bird": "wings_bird", "wings_duck": "wings_duck", "wings_big": "wings_big", "wings_bug": "wings_bug",
		"wings_bee": "wings_bee", "fin": "fin", "shell_big": "shell_big"},
	"armor": {"shell": "shell", "spines": "spines", "plating": "plating"},
	"tail": {"long": "long", "whip": "whip", "stinger": "stinger", "fluffy": "fluffy", "curl": "curl", "feathers": "feathers",
		"fin": "fin_tail", "nub": "nub", "fan": "fan", "serpent": "serpent"},
	"legs": {"stubby": "stubby", "long": "legs_long", "legs_tall": "legs_tall", "webbed": "webbed", "bug": "bug", "crab": "crab",
		"frog": "frog", "stilts": "stilts", "cilia": "cilia"},
	"arms": {"claws": "claws", "claws_big": "claws_big", "tentacles": "tentacles", "tentacles_big": "tentacles_big"},
	"cheeks": {"pouch": "cheeks"},
	"mouth": {"bill": "bill", "beak": "beak", "snout": "snout", "mandibles": "mandibles", "pincers": "pincers", "sucker": "sucker"},
}


## The parts and face of a look (the player's run look).
static func spec_of(look: Dictionary) -> Dictionary:
	var parts: Array = []
	for slot in ["crown", "back", "armor", "tail", "legs", "arms", "cheeks", "mouth"]:
		var v := String(look.get(slot, look.get("head", "none") if slot == "crown" else "none"))
		var m: Dictionary = SLOT_PART[slot]
		if m.has(v) and not m[v] in parts:
			parts.append(m[v])
	return {
		"parts": parts, "eyes": String(look.get("eyes", "cute")), "eye_n": int(look.get("eye_n", 2)),
		"mouth": String(look.get("mouth", "none")), "hide": String(look.get("hide", "none")),
		"duck": String(look.get("body", "")) == "duck", "hood": String(look.get("crown", "")) == "crest_duck",
		"tall": 3 if String(look.get("body", "")) == "bird" else 0,
	}


const SQUASH_ROW := 11
const NECK_ROW := 7


## One frame of Puddle. pose: {"squash": -1|0|1, "lift": px, "step": 0..3, "flap": 0|1,
## "blink": bool, "open": bool}. Returns the image; the canvas is the same for every pose.
static func compose_spec(sp: Dictionary, pose: Dictionary) -> Image:
	var rows: Array = (BODY["rows"] as Array).duplicate()
	var sq := int(pose.get("squash", 0))
	if sq > 0:
		rows.remove_at(SQUASH_ROW)
	elif sq < 0:
		rows.insert(SQUASH_ROW, rows[SQUASH_ROW])
	# a long neck (Swan Neck): the rows under the collar repeat, the head rises
	var tall := int(sp.get("tall", 0))
	for i in tall:
		rows.insert(NECK_ROW, rows[NECK_ROW])
	var img := Image.create_empty(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var lift := int(pose.get("lift", 0))
	var at := BODY_AT + Vector2i(0, sq - lift - tall)
	var anchors: Dictionary = BODY["anchors"]
	var parts: Array = sp["parts"]
	var duck: bool = sp["duck"]
	# where a body anchor lands this frame (rows above the squash row move with the top)
	var place := func(name: String) -> Vector2i:
		var a: Vector2i = anchors[name]
		var p := at + a
		if a.y >= NECK_ROW:
			p.y += tall
		if a.y >= SQUASH_ROW:
			p.y -= sq  # below the removed/added row: back where it was
		return p
	# back layer
	for id in parts:
		var d: Dictionary = DarwinParts.ALL.get(id, {})
		if d.is_empty() or String(d["layer"]) != "back":
			continue
		var fr: Array = d["frames"]
		var fi := 0
		if fr.size() == 4:
			fi = int(pose.get("step", 0)) % 4
		elif fr.size() == 2:
			fi = int(pose.get("flap", 0)) % 2
		var pa: Vector2i = place.call(String(d["at"]))
		stamp(img, fr[fi], pa - (d["anchor"] as Vector2i))
	# the body (a mallard's colors after Convergent Evolution)
	if duck:
		_stamp_recolor(img, rows, at, {"B": "leather", "b": "bark", "F": "grass", "f": "pine"})
		var cy: int = at.y + 6
		for x in range(at.x + 5, at.x + 15):
			if img.get_pixel(x, cy).a > 0.0 and img.get_pixel(x, cy) != col("k"):
				img.set_pixel(x, cy, col("w"))
	elif sp["hood"]:
		_stamp_recolor(img, rows, at, {"F": "grass", "f": "pine"})
	else:
		stamp(img, rows, at)
	_pattern(img, rows, at, String(sp["hide"]))
	# face
	var eyes: Array = BODY["eyes"]
	var shift := Vector2i(0, 0)
	_eyes(img, at + (eyes[0] as Vector2i) + shift, at + (eyes[1] as Vector2i) + shift, String(sp["eyes"]), int(sp["eye_n"]), bool(pose.get("blink", false)))
	var mouth := String(sp["mouth"])
	var mp: Vector2i = at + (BODY["mouth"] as Vector2i)
	if not mouth in ["bill", "beak", "snout", "mandibles", "pincers", "sucker"]:
		img.set_pixel(mp.x, mp.y, col("e"))
		img.set_pixel(mp.x + 1, mp.y, col("e"))
		if pose.get("open", false):
			img.set_pixel(mp.x, mp.y + 1, col("R"))
			img.set_pixel(mp.x + 1, mp.y + 1, col("e"))
		if mouth == "fangs":
			img.set_pixel(mp.x - 1, mp.y + 1, col("w"))
			img.set_pixel(mp.x + 2, mp.y + 1, col("w"))
	# front layer
	for id in parts:
		var d2: Dictionary = DarwinParts.ALL.get(id, {})
		if d2.is_empty() or String(d2["layer"]) != "front":
			continue
		var fr2: Array = d2["frames"]
		var fi2 := 0
		if fr2.size() >= 2 and (pose.get("open", false) or int(pose.get("flap", 0)) == 1 and String(d2["at"]) != "face"):
			fi2 = 1
		var pa2: Vector2i = place.call(String(d2["at"]))
		stamp(img, fr2[fi2], pa2 - (d2["anchor"] as Vector2i))
	return img


static func _stamp_recolor(img: Image, rows: Array, pos: Vector2i, remap: Dictionary) -> void:
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var c := col(ch) if not remap.has(ch) else Pal.e(String(remap[ch]))
			img.set_pixel(pos.x + x, pos.y + y, c)


static func _eyes(img: Image, a: Vector2i, b: Vector2i, style: String, n: int, blink: bool) -> void:
	var dark := col("e")
	var spots: Array = [a, b]
	if n >= 3:
		spots.append(a + Vector2i(2, -1))
	if n >= 4:
		spots.append(b + Vector2i(-2, 2))
	if n >= 5:
		spots.append(a + Vector2i(-2, 1))
	if n >= 6:
		spots.append(b + Vector2i(1, -2))
	for i in spots.size():
		var p: Vector2i = spots[i]
		if blink:
			img.set_pixel(p.x, p.y, dark)
			img.set_pixel(p.x + 1, p.y, dark)
			continue
		match style:
			"compound":
				img.set_pixel(p.x, p.y, dark)
				img.set_pixel(p.x, p.y - 1, col("v"))
			"glow":
				img.set_pixel(p.x, p.y, col("Y"))
				img.set_pixel(p.x, p.y - 1, col("y"))
			"angry":
				img.set_pixel(p.x, p.y, dark)
				img.set_pixel(p.x + (1 if i == 0 else -1), p.y - 1, dark)
			"big":
				img.set_pixel(p.x, p.y, dark)
				img.set_pixel(p.x - 1, p.y, col("w"))
				img.set_pixel(p.x, p.y - 1, col("w"))
			_:
				img.set_pixel(p.x, p.y, dark)


static func _pattern(img: Image, rows: Array, at: Vector2i, hide: String) -> void:
	if hide == "none" or hide == "":
		return
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if row[x] != "B":
				continue
			var p := at + Vector2i(x, y)
			var c := img.get_pixel(p.x, p.y)
			match hide:
				"spots":
					if (x * 7 + y * 13) % 11 == 0:
						img.set_pixel(p.x, p.y, col("b"))
				"stripes":
					if x % 4 == 1:
						img.set_pixel(p.x, p.y, col("b"))
				"scales":
					if (x + y) % 3 == 0 and y % 2 == 0:
						img.set_pixel(p.x, p.y, c.lightened(0.2))
				"toxic":
					if (x * 5 + y * 3) % 13 == 0:
						img.set_pixel(p.x, p.y, col("y"))
				"down", "feathers":
					if (x + y * 2) % 5 == 0:
						img.set_pixel(p.x, p.y, c.lightened(0.25))


## The canvas every pose shares, and where the body sits in it.
const CANVAS := Vector2i(46, 44)
const BODY_AT := Vector2i(14, 16)


## Test/preview helper: Puddle with a list of part ids.
static func compose(parts: Array, opts: Dictionary) -> Image:
	var sp := {"tall": int(opts.get("tall", 0)), "parts": parts, "eyes": String(opts.get("eyes", "cute")), "eye_n": int(opts.get("eye_n", 2)),
		"mouth": String(opts.get("mouth", "none")), "hide": String(opts.get("hide", "none")), "duck": opts.get("duck", false),
		"hood": opts.get("hood", false)}
	return compose_spec(sp, opts)


static var _cache := {}


static func clear_cache() -> void:
	_cache.clear()


## Animation frames for a look: {"idle": [4], "walk": [4], "bite": [1], "size", "foot"}.
static func frames(look: Dictionary) -> Dictionary:
	var sp := spec_of(look)
	var key := JSON.stringify(sp)
	if _cache.has(key):
		return _cache[key]
	var poses := [
		{"a": "idle"}, {"a": "idle", "squash": 1}, {"a": "idle"}, {"a": "idle", "blink": true},
		{"a": "walk", "squash": 1, "step": 0}, {"a": "walk", "squash": -1, "lift": 2, "step": 1, "flap": 1},
		{"a": "walk", "lift": 1, "step": 2}, {"a": "walk", "squash": -1, "lift": 2, "step": 3, "flap": 1},
		{"a": "bite", "open": true, "lift": 1},
	]
	var out := {"idle": [], "walk": [], "bite": [], "size": CANVAS}
	var ground := BODY_AT.y + (BODY["rows"] as Array).size()
	for ps in poses:
		var img := compose_spec(sp, ps)
		if ps["a"] == "idle" and not ps.has("squash") and not ps.has("blink"):
			var used := img.get_used_rect()
			ground = maxi(ground, used.end.y)
		(out[ps["a"]] as Array).append(ImageTexture.create_from_image(img))
	out["foot"] = Vector2(BODY_AT.x + 8, ground)
	_cache[key] = out
	return out


# ------------------------------------------------------------------ animals
## Animation frames for an animal or boss (DarwinAnimals.ALL[id]), the same contract as
## frames(): idle 4 (rest, squash, rest, blink), walk 4 (legs step, hop, alt body), bite 1.
static func species_frames(id: String) -> Dictionary:
	var key := "s:" + id
	if _cache.has(key):
		return _cache[key]
	var d: Dictionary = DarwinAnimals.ALL.get(id, DarwinAnimals.ALL["beetle"])
	var rows: Array = d["rows"]
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var legs: Array = d["legs"]
	var la: Vector2i = d["legs_at"]
	var bottom := rows.size()
	for f in legs:
		bottom = maxi(bottom, la.y + (f as Array).size())
		for r in f:
			w = maxi(w, la.x + String(r).length())
	var canvas := Vector2i(w + 4, bottom + 5)
	var at := Vector2i(1, 4)
	var poses := [
		{"a": "idle"}, {"a": "idle", "squash": 1}, {"a": "idle"}, {"a": "idle", "blink": true},
		{"a": "walk", "step": 0}, {"a": "walk", "step": 1, "lift": 1, "alt": true},
		{"a": "walk", "step": 0, "squash": 1}, {"a": "walk", "step": 1, "lift": 1, "alt": true},
		{"a": "bite", "open": true},
	]
	var zoom := int(d.get("zoom", 1))
	var out := {"idle": [], "walk": [], "bite": [], "size": canvas * zoom}
	for ps in poses:
		var img := compose_species(d, ps, canvas, at)
		if zoom > 1:
			img.resize(canvas.x * zoom, canvas.y * zoom, Image.INTERPOLATE_NEAREST)
		(out[ps["a"]] as Array).append(ImageTexture.create_from_image(img))
	out["foot"] = Vector2(at.x + w * 0.5, at.y + bottom) * zoom
	_cache[key] = out
	return out


static func compose_species(d: Dictionary, pose: Dictionary, canvas: Vector2i, at: Vector2i) -> Image:
	var rows: Array = d["rows"]
	if pose.get("alt", false) and not (d["alt"] as Array).is_empty():
		rows = d["alt"]
	rows = rows.duplicate()
	var sr := int(d["squash"])
	var sq := int(pose.get("squash", 0))
	if sq > 0 and sr > 0 and sr < rows.size():
		rows.remove_at(sr)
	else:
		sq = 0
	var lift := int(pose.get("lift", 0))
	var lunge := 1 if pose.get("open", false) else 0
	var img := Image.create_empty(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	var remap: Dictionary = d["recolor"]
	var legs: Array = d["legs"]
	if not legs.is_empty():
		var lf: Array = legs[int(pose.get("step", 0)) % legs.size()]
		_stamp_recolor(img, lf, at + (d["legs_at"] as Vector2i) - Vector2i(0, lift), remap)
	var bat := at + Vector2i(lunge, sq - lift)
	_stamp_recolor(img, rows, bat, remap)
	var fix := func(p: Vector2i) -> Vector2i:
		var q := bat + p
		if sq > 0 and p.y >= sr:
			q.y -= sq
		return q
	if pose.get("blink", false):
		for e in d["eyes"]:
			var q: Vector2i = fix.call(e)
			img.set_pixel(q.x, q.y, img.get_pixel(q.x - 1, q.y))
	if pose.get("open", false):
		var m: Vector2i = fix.call(d["mouth"])
		if m.x >= 0 and m.y + 1 < canvas.y and m.x < canvas.x:
			img.set_pixel(m.x, m.y, col("R"))
			img.set_pixel(m.x, m.y + 1, col("k"))
	return img
