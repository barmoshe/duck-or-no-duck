class_name Portrait
extends RefCounted
## Evolution card portraits: the evolution shown on YOUR creature, close up. Parts are
## rendered with the Evolution Graphics System and cropped around the slot they change
## (a bill crops to the face, legs to the feet); attacks, ultimates and moves show their
## hand-drawn icon. Everything sits on a vignette in the affinity's color.

const W := 60
const H := 50
## where on the creature each slot lives (fraction of its used rect, x from the tail)
const FOCUS := {
	"mouth": Vector2(0.85, 0.45), "eyes": Vector2(0.75, 0.3), "head": Vector2(0.7, 0.15), "crown": Vector2(0.7, 0.15),
	"back": Vector2(0.45, 0.2), "armor": Vector2(0.45, 0.35), "tail": Vector2(0.12, 0.55), "legs": Vector2(0.5, 0.92),
	"arms": Vector2(0.8, 0.7), "pattern": Vector2(0.5, 0.5), "hide": Vector2(0.5, 0.5), "shape": Vector2(0.5, 0.5),
}

static var _cache := {}


static func tex(run_look: Dictionary, id: String) -> Texture2D:
	var d := Evolutions.get_def(id)
	var lk: Dictionary = d.get("look", {})
	var key := id + "|" + (Anatomy.key_of(run_look) if not lk.is_empty() else "")
	if _cache.has(key):
		return _cache[key]
	var img := _backdrop(String(d.get("aff", "prey")))
	var t := String(d.get("type", "passive"))
	if lk.is_empty() or t in ["attack", "ultimate", "move"]:
		_icon(img, id, t)
	else:
		_close_up(img, run_look, lk)
	var tx := ImageTexture.create_from_image(img)
	_cache[key] = tx
	return tx


static func clear_cache() -> void:
	_cache.clear()


static func _backdrop(aff: String) -> Image:
	var ramp := String(Evolutions.AFF_RAMP.get(aff, "grey"))
	var lite := Pal.c(ramp, 4).lerp(Ui.PARCHMENT, 0.55)
	var mid := Pal.c(ramp, 3).lerp(Ui.PARCHMENT, 0.35)
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var dx := (x + 0.5 - W * 0.5) / (W * 0.5)
			var dy := (y + 0.5 - H * 0.45) / (H * 0.5)
			var d2 := dx * dx + dy * dy
			# a dithered two-tone vignette, lighter in the middle
			var bayer := float([0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5][(y % 4) * 4 + x % 4]) / 16.0
			img.set_pixel(x, y, lite if d2 + (bayer - 0.5) * 0.25 < 0.55 else mid)
	return img


static func _icon(img: Image, id: String, t: String) -> void:
	var ic := Icons.tex(id).get_image()
	var used := ic.get_used_rect()
	if used.size.x == 0:
		return
	ic = ic.get_region(used)
	var sc := 3 if ic.get_width() * 3 <= W - 6 and ic.get_height() * 3 <= H - 6 else 2
	ic.resize(ic.get_width() * sc, ic.get_height() * sc, Image.INTERPOLATE_NEAREST)
	var at := Vector2i((W - ic.get_width()) / 2, (H - ic.get_height()) / 2)
	_shadow(img, ic, at + Vector2i(1, 2))
	img.blend_rect(ic, Rect2i(Vector2i.ZERO, ic.get_size()), at)


static func _close_up(img: Image, run_look: Dictionary, lk: Dictionary) -> void:
	var look := run_look.duplicate()
	var focus := Vector2(0.5, 0.5)
	var n := 0
	for k in lk:
		if k == "shape":
			look["body"] = {"duck": "duck", "tall": "bird"}.get(String(lk[k]), look.get("body", "mochi"))
		else:
			look[Run.LOOK_KEY.get(k, k)] = lk[k]
		focus = focus + FOCUS.get(String(k), Vector2(0.5, 0.5)) if n > 0 else FOCUS.get(String(k), Vector2(0.5, 0.5))
		n += 1
	if n > 1:
		focus /= float(n)
	look["scale"] = 1
	var cr := Anatomy.render(look, "idle", 0)
	var used := cr.get_used_rect()
	if used.size.x == 0:
		return
	cr = cr.get_region(used)
	# a close-up at 3x around the part (whole-body changes at 2x)
	var sc := 2 if lk.has("shape") else 3
	var win := Vector2i(W / sc, H / sc)
	var c := Vector2(cr.get_width() * focus.x, cr.get_height() * focus.y)
	var x0 := clampi(int(c.x - win.x * 0.5), 0, maxi(0, cr.get_width() - win.x))
	var y0 := clampi(int(c.y - win.y * 0.5), 0, maxi(0, cr.get_height() - win.y))
	if cr.get_width() <= win.x:
		x0 = 0
	if cr.get_height() <= win.y:
		y0 = 0
	var reg := cr.get_region(Rect2i(x0, y0, mini(win.x, cr.get_width()), mini(win.y, cr.get_height())))
	reg.resize(reg.get_width() * sc, reg.get_height() * sc, Image.INTERPOLATE_NEAREST)
	var at := Vector2i((W - reg.get_width()) / 2, H - reg.get_height() - (2 if cr.get_height() <= win.y else 0))
	if cr.get_height() > win.y:
		at.y = (H - reg.get_height()) / 2
	_shadow(img, reg, at + Vector2i(1, 2))
	img.blend_rect(reg, Rect2i(Vector2i.ZERO, reg.get_size()), at)


## A soft drop shadow of a sprite's silhouette.
static func _shadow(img: Image, spr: Image, at: Vector2i) -> void:
	for y in spr.get_height():
		for x in spr.get_width():
			if spr.get_pixel(x, y).a > 0.5:
				var px := at + Vector2i(x, y)
				if px.x >= 0 and px.y >= 0 and px.x < W and px.y < H:
					img.set_pixel(px.x, px.y, img.get_pixel(px.x, px.y).darkened(0.25))
