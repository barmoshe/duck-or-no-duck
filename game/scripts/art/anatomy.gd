class_name Anatomy
extends RefCounted
## Builds creature frames from a "look" with the Evolution Graphics System (Rig):
## a hand-drawn body rig + hand-drawn parts per slot, composed at the rig's sockets for
## every frame. Looks use these keys:
##   body (rig id), ramp, accent, eyes, mouth, crown, back, armor, tail, legs, arms,
##   hide, scale (1, or 2 for bosses), size (collision size, not drawing)
## frames(look) -> {"idle": [4 tex], "walk": [4 tex], "bite": [1 tex], "size": Vector2i, "foot": Vector2}

const M := 12  # margin around the body for parts that stick out
const DEFAULT := {
	"body": "slime", "ramp": "", "accent": "gold", "eyes": "cute", "mouth": "none", "crown": "none",
	"back": "none", "armor": "none", "tail": "none", "legs": "none", "arms": "none", "hide": "none", "scale": 1,
}
## Older look keys still used around the game, mapped to rig slots.
const SHAPE_TO_BODY := {"slime": "slime", "blob": "mochi", "round": "chunk", "long": "beast", "segmented": "bug",
	"duck": "duck", "tall": "bird", "flat": "flat"}

static var _cache := {}


static func normalize(look: Dictionary) -> Dictionary:
	var lk := DEFAULT.duplicate()
	for k in look:
		lk[k] = look[k]
	if not look.has("body") and look.has("shape"):
		lk["body"] = SHAPE_TO_BODY.get(String(look["shape"]), "mochi")
	if look.has("head") and not look.has("crown"):
		lk["crown"] = look["head"]
	if look.has("pattern") and not look.has("hide"):
		lk["hide"] = look["pattern"]
	if String(lk["ramp"]) == "":
		lk["ramp"] = String(Bodies.get_def(String(lk["body"]))["ramp"])
	return lk


static func key_of(look: Dictionary) -> String:
	var lk := normalize(look)
	var parts: Array[String] = []
	for k in DEFAULT:
		parts.append(str(lk[k]))
	return "|".join(parts)


static func frames(look: Dictionary) -> Dictionary:
	var key := key_of(look)
	if _cache.has(key):
		return _cache[key]
	var lk := normalize(look)
	var out := {"idle": [], "walk": [], "bite": []}
	var body := Bodies.get_def(String(lk["body"]))
	var idle: Array = body["idle"]
	# idle: rest, the idle pose, rest, rest with a blink
	var idle_specs := [idle[0], idle[1 % idle.size()], idle[0], idle[0]]
	for i in 4:
		out["idle"].append(ImageTexture.create_from_image(render(lk, "idle", i, idle_specs[i], i == 3)))
	var mv: Array = body["move"]
	for i in 4:
		out["walk"].append(ImageTexture.create_from_image(render(lk, "move", i, mv[i % mv.size()], false)))
	out["bite"].append(ImageTexture.create_from_image(render(lk, "attack", 0, (body["attack"] as Array)[0], false)))
	var sz := _canvas_size(lk)
	out["size"] = sz
	out["foot"] = _foot(lk)
	_cache[key] = out
	return out


static func clear_cache() -> void:
	_cache.clear()


static func _canvas_size(lk: Dictionary) -> Vector2i:
	var body := Bodies.get_def(String(lk["body"]))
	var rows: Array = body["rows"]
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var sc := int(lk["scale"])
	return Vector2i(w + M * 2 + 6, rows.size() + M * 2 + 6) * sc


static func _foot(lk: Dictionary) -> Vector2:
	var body := Bodies.get_def(String(lk["body"]))
	var f: Vector2i = body["foot"]
	return Vector2(f.x + M, f.y + M) * int(lk["scale"])


# ------------------------------------------------------------------ body transforms
static func _has_marker(row: String) -> bool:
	for ch in Rig.MARKERS:
		if row.contains(ch):
			return true
	return false


static func _transform(rows: Array, foot: Vector2i, spec: Dictionary) -> Dictionary:
	# three spare rows on top so a stretch has room to grow
	var r: Array = ["", "", ""] + rows.duplicate()
	var f := foot + Vector2i(0, 3)
	var sq := int(spec.get("sq", 0))
	var st := int(spec.get("st", 0))
	var top := 0
	while top < r.size() and String(r[top]).replace(".", "").strip_edges() == "":
		top += 1
	var mid := int((top + f.y) / 2)
	for k in sq:
		# drop a middle row with no socket in it, widen by doubling the center column
		var drop := -1
		for dy in [0, 1, -1, 2, -2]:
			var i: int = mid + dy
			if i > top and i < f.y - 1 and not _has_marker(String(r[i])):
				drop = i
				break
		if drop >= 0:
			r.remove_at(drop)
			r.insert(0, "")
		for i in r.size():
			var row := String(r[i])
			if row.length() > f.x:
				r[i] = row.substr(0, f.x) + row[f.x] + row.substr(f.x)
	for k in st:
		var dup := -1
		for dy in [0, 1, -1, 2, -2]:
			var i2: int = mid + dy
			if i2 > top and i2 < f.y - 1 and not _has_marker(String(r[i2])):
				dup = i2
				break
		if dup >= 0 and r.size() > 0 and String(r[0]).replace(".", "") == "":
			r.remove_at(0)
			r.insert(dup, r[dup - 1])
		# narrow: drop a center column if it holds no socket
		var col_ok := true
		for row in r:
			var rs := String(row)
			if rs.length() > f.x and Rig.MARKERS.has(rs[f.x]):
				col_ok = false
		if col_ok:
			for i in r.size():
				var row2 := String(r[i])
				if row2.length() > f.x:
					r[i] = row2.substr(0, f.x) + row2.substr(f.x + 1)
	var lean := int(spec.get("lean", 0))
	if lean > 0:
		for i in r.size():
			if i < mid:
				r[i] = ".".repeat(lean) + String(r[i])
			elif i < f.y - 2:
				r[i] = ".".repeat(int(lean / 2)) + String(r[i])
	return {"rows": r, "lift": int(spec.get("lift", 0)), "pad": 3}


# ------------------------------------------------------------------ composing one frame
static func _part(slot: String, id: String) -> Dictionary:
	return PartSheets.get_part(slot, id)


static func _draw_part(p: Px, slot: String, id: String, at: Vector2i, frame: int, lk: Dictionary, shade: int = 0) -> void:
	if id == "none" or id == "":
		return
	var d := _part(slot, id)
	if d.is_empty():
		return
	var fr: Array = d["frames"]
	var rows: Array = fr[frame % fr.size()]
	var sheet := Rig.parse(rows)
	var ramp := String(d.get("ramp", lk["ramp"]))
	if ramp == "body":
		ramp = String(lk["ramp"])
	Rig.blit(p, sheet, d["pivot"], at, ramp, String(lk["accent"]), false, shade)


## anim: idle | move | attack. frame: index in that animation. blink: close the eyes.
static func render(look: Dictionary, anim: String, frame: int, spec: Dictionary = {}, blink: bool = false) -> Image:
	var lk := normalize(look)
	var body := Bodies.get_def(String(lk["body"]))
	var t := _transform(body["rows"], body["foot"], spec)
	var bsheet := Rig.parse(t["rows"])
	var base_foot: Vector2i = body["foot"]
	var cs := _canvas_size(lk) / int(lk["scale"])
	var p := Px.make(cs.x, cs.y)
	# the body's foot always lands on the canvas foot; lift raises it
	# squash and stretch keep the row count, so the feet stay on the ground; lift raises it
	var origin := Vector2i(M, M - int(t["pad"]) - int(t["lift"]))
	var marks: Dictionary = bsheet["marks"]
	var sock := {}
	for k in marks:
		sock[k] = origin + (marks[k] as Vector2i)
	# sensible fallbacks for rigs without a socket
	var eye: Vector2i = sock.get("eye", origin + Vector2i(base_foot.x + 4, 3))
	sock["eye"] = eye
	sock["mouth"] = sock.get("mouth", eye + Vector2i(2, 2))
	sock["crown"] = sock.get("crown", eye + Vector2i(-2, -3))
	sock["back"] = sock.get("back", origin + Vector2i(base_foot.x - 4, 2))
	sock["armor"] = sock.get("armor", sock["back"] + Vector2i(3, 0))
	sock["tail"] = sock.get("tail", origin + Vector2i(1, base_foot.y - 4))
	sock["limb_h"] = sock.get("limb_h", origin + Vector2i(base_foot.x - 5, base_foot.y - 1))
	sock["limb_f"] = sock.get("limb_f", origin + Vector2i(base_foot.x + 4, base_foot.y - 1))
	sock["arm"] = sock.get("arm", sock["mouth"] + Vector2i(0, 3))
	sock["hide"] = sock.get("hide", origin + Vector2i(base_foot.x, base_foot.y - 5))
	var walk := frame if anim == "move" else 0
	var flap := 1 if (anim == "move" and frame % 2 == 1) else 0
	var wag := 1 if (frame % 2 == 1) else 0
	var legs := String(lk["legs"])
	var far := Vector2i(2, -1)
	# far side (darker)
	_draw_part(p, "limb", legs, sock["limb_h"] + far, (walk + 2) % 4, lk, -1)
	_draw_part(p, "limb", legs, sock["limb_f"] + far, walk, lk, -1)
	if String(lk["back"]).begins_with("wings"):
		_draw_part(p, "back", String(lk["back"]), sock["back"] + far + Vector2i(1, 0), 1 - flap, lk, -1)
	_draw_part(p, "tail", String(lk["tail"]), sock["tail"], wag, lk)
	# body
	Rig.blit(p, bsheet, Vector2i.ZERO, origin, String(lk["ramp"]), String(lk["accent"]))
	var mask := PackedByteArray()
	mask.resize(p.w * p.h)
	for i in p.px.size():
		mask[i] = 1 if p.px[i].a > 0.5 else 0
	var hide := String(lk["hide"])
	if hide != "none":
		var hd := _part("hide", hide)
		if not hd.is_empty():
			Rig.blit_masked(p, Rig.parse((hd["frames"] as Array)[0]), hd["pivot"], sock["hide"], String(lk["ramp"]), String(lk["accent"]), mask)
	_draw_part(p, "armor", String(lk["armor"]), sock["armor"], 0, lk)
	# near side
	_draw_part(p, "limb", legs, sock["limb_h"], walk, lk)
	_draw_part(p, "limb", legs, sock["limb_f"], (walk + 2) % 4, lk)
	_draw_part(p, "back", String(lk["back"]), sock["back"], flap, lk)
	_draw_part(p, "crown", String(lk["crown"]), sock["crown"], wag, lk)
	_draw_part(p, "eye", String(lk["eyes"]), sock["eye"], 1 if blink else 0, lk)
	_draw_part(p, "mouth", String(lk["mouth"]), sock["mouth"], 1 if anim == "attack" else 0, lk)
	_draw_part(p, "arm", String(lk["arms"]), sock["arm"], 1 if anim == "attack" else 0, lk)
	var img := p.to_image()
	var sc := int(lk["scale"])
	if sc > 1:
		img.resize(img.get_width() * sc, img.get_height() * sc, Image.INTERPOLATE_NEAREST)
	return img
