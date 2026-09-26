class_name Portrait
extends RefCounted
## Evolution card portraits: the evolution shown on YOUR creature, close up. The body is
## the Sculptor's render of your genome after taking the card (Run.preview), cropped
## around the zone it changes (a bill crops to the face, legs to the feet, a passive that
## reshapes you shows your whole body); attacks, ultimates and moves show their
## hand-drawn icon. Everything sits on a vignette in the affinity's color.

const W := 60
const H := 50
const ZONE := {"mouth": "face", "eyes": "face", "head": "crown", "crown": "crown", "back": "back", "armor": "back",
	"tail": "tail", "legs": "legs", "arms": "arms", "pattern": "body", "hide": "body", "shape": "body"}

static var _cache := {}


static func tex(run: Run, id: String) -> Texture2D:
	var d := Evolutions.get_def(id)
	var lk: Dictionary = d.get("look", {})
	var t := String(d.get("type", "passive"))
	var icon_only := t in ["attack", "ultimate", "move"] and Icons.ALL.has(id)
	var key := id + "|" + ("" if icon_only else Anatomy.key_of(run.look))
	if _cache.has(key):
		return _cache[key]
	var img := _backdrop(String(d.get("aff", "prey")))
	if icon_only:
		_icon(img, id, t)
	else:
		var zone := "body"
		for k in lk:
			zone = String(ZONE.get(String(k), "body"))
			break
		_close_up(img, run.preview(id), zone)
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


## Where each zone sits on Darwin-style Puddle (DarwinArt body anchors).
const DARWIN_ZONE := {"face": "face", "crown": "top", "back": "back", "tail": "tail", "legs": "feet", "arms": "arm"}


static func _close_up(img: Image, look: Dictionary, zone: String) -> void:
	if Anatomy.is_darwin(look):
		var dimg := (DarwinArt.frames(look)["idle"][0] as Texture2D).get_image()
		var used := dimg.get_used_rect()
		var dc := Vector2(used.get_center())
		var dsc := 2
		if DARWIN_ZONE.has(zone):
			dc = Vector2(DarwinArt.BODY_AT + (DarwinArt.BODY["anchors"][DARWIN_ZONE[zone]] as Vector2i))
			dc = dc.lerp(Vector2(used.get_center()), 0.35)
		_blit(img, dimg, dc, dsc)
		return
	var g := Anatomy.genome(look)
	var fr := Sculptor.single(g)
	var cr := (fr["tex"] as Texture2D).get_image()
	var origin: Vector2 = fr["foot"]
	var rg := Sculptor.rig(g, {"anim": "idle", "i": 0})
	var hd: Vector2 = rg["head"]
	var bd: Vector2 = rg["body"]
	var fr_r := float(rg["face_r"])
	var ln := float(g["len"])
	var hh := float(g["h"])
	var c := bd
	var sc := 3
	match zone:
		"face":
			c = hd + Vector2(fr_r * 0.4, 0.0)
		"crown":
			c = hd + Vector2(0.0, -fr_r * 0.9)
		"back":
			c = bd + Vector2(-ln * 0.1, -hh * 0.45)
		"tail":
			c = bd + Vector2(-ln * 0.55, -hh * 0.1)
		"legs":
			c = Vector2(bd.x, -float(g["leg_len"]) * 0.5 - 1.0)
		"arms":
			c = bd + Vector2(ln * 0.45, hh * 0.35)
		_:
			sc = 2
			var used := cr.get_used_rect()
			c = Vector2(used.get_center()) - origin
			if used.size.x * 2 > W or used.size.y * 2 > H:
				sc = 1
	_blit(img, cr, c + origin, sc)


## Crops a window of cr around cp, scales it by sc and centers it on img with a shadow.
static func _blit(img: Image, cr: Image, cp: Vector2, sc: int) -> void:
	var win := Vector2i(W / sc, H / sc)
	var x0 := clampi(int(cp.x - win.x * 0.5), 0, maxi(0, cr.get_width() - win.x))
	var y0 := clampi(int(cp.y - win.y * 0.5), 0, maxi(0, cr.get_height() - win.y))
	var reg := cr.get_region(Rect2i(x0, y0, mini(win.x, cr.get_width()), mini(win.y, cr.get_height())))
	reg.resize(reg.get_width() * sc, reg.get_height() * sc, Image.INTERPOLATE_NEAREST)
	var at := Vector2i((W - reg.get_width()) / 2, (H - reg.get_height()) / 2)
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
