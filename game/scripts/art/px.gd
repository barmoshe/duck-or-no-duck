class_name Px
extends RefCounted
## A tiny raster library for building pixel-art sprites in code: filled ellipses,
## polygons, thick lines and dots, then an automatic top-left light pass and a 1 px
## hue-shifted outline so every generated sprite shares one style. Works on a
## PackedColorArray (fast in GDScript) and converts to an Image once at the end.

var px := PackedColorArray()
var w := 0
var h := 0
var img: Image:
	get:
		return to_image()


static func make(width: int, height: int) -> Px:
	var p := Px.new()
	p.w = width
	p.h = height
	p.px.resize(width * height)
	p.px.fill(Color(0, 0, 0, 0))
	return p


func put(x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	var i := y * w + x
	if c.a >= 1.0:
		px[i] = c
	elif c.a > 0.0:
		var under := px[i]
		if under.a <= 0.0:
			px[i] = c
		else:
			px[i] = Color(under.lerp(c, c.a), maxf(under.a, c.a))


func get_c(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h:
		return Color(0, 0, 0, 0)
	return px[y * w + x]


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var x0 := maxi(0, floori(cx - rx - 1))
	var x1 := mini(w - 1, ceili(cx + rx + 1))
	var y0 := maxi(0, floori(cy - ry - 1))
	var y1 := mini(h - 1, ceili(cy + ry + 1))
	var irx := 1.0 / maxf(0.5, rx)
	var iry := 1.0 / maxf(0.5, ry)
	var opaque := c.a >= 1.0
	for y in range(y0, y1 + 1):
		var dy := (y + 0.5 - cy) * iry
		var dy2 := dy * dy
		if dy2 > 1.0:
			continue
		var row := y * w
		for x in range(x0, x1 + 1):
			var dx := (x + 0.5 - cx) * irx
			if dx * dx + dy2 <= 1.0:
				if opaque:
					px[row + x] = c
				else:
					put(x, y, c)


func circle(cx: float, cy: float, r: float, c: Color) -> void:
	ellipse(cx, cy, r, r, c)


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(maxi(0, y), mini(h, y + rh)):
		for xx in range(maxi(0, x), mini(w, x + rw)):
			put(xx, yy, c)


func poly(pts: PackedVector2Array, c: Color) -> void:
	if pts.size() < 3:
		return
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	for y in range(maxi(0, floori(y0)), mini(h - 1, ceili(y1)) + 1):
		var sy := y + 0.5
		var xs: Array[float] = []
		for i in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			for x in range(roundi(xs[k]), roundi(xs[k + 1])):
				put(x, y, c)
			k += 2


func line(ax: float, ay: float, bx: float, by: float, c: Color, thick: float = 1.0) -> void:
	var d := Vector2(bx - ax, by - ay)
	var n := maxi(1, ceili(d.length() * 1.5))
	for i in n + 1:
		var u := float(i) / n
		var qx := ax + d.x * u
		var qy := ay + d.y * u
		if thick <= 1.0:
			put(floori(qx), floori(qy), c)
		else:
			circle(qx, qy, thick * 0.5, c)


func polyline(pts: PackedVector2Array, c: Color, thick: float = 1.0) -> void:
	for i in pts.size() - 1:
		line(pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y, c, thick)


func _a(src: PackedColorArray, x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= w or y >= h:
		return 0.0
	return src[y * w + x].a


## Light from the top-left: pixels on an upper edge get lighter, lower edges darker.
func shade(light: float = 0.18, dark: float = 0.22) -> void:
	var src := px.duplicate()
	for y in h:
		for x in w:
			var i := y * w + x
			var c := src[i]
			if c.a < 0.5:
				continue
			var ul := _a(src, x - 1, y - 1) < 0.5 or _a(src, x, y - 1) < 0.5
			var dr := _a(src, x + 1, y + 1) < 0.5 or _a(src, x, y + 1) < 0.5
			if ul and not dr:
				px[i] = Color(c.lightened(light), c.a)
			elif dr and not ul:
				px[i] = Color(c.darkened(dark), c.a)


## A 1 px outline in a darkened version of the neighboring color (hue-shifted, not black).
func outline(ink: Color = Color(0.08, 0.06, 0.12), tint: float = 0.35) -> void:
	var src := px.duplicate()
	for y in h:
		for x in w:
			var i := y * w + x
			if src[i].a >= 0.5:
				continue
			var best := Color(0, 0, 0, 0)
			if x + 1 < w and src[i + 1].a >= 0.5:
				best = src[i + 1]
			elif x > 0 and src[i - 1].a >= 0.5:
				best = src[i - 1]
			elif y + 1 < h and src[i + w].a >= 0.5:
				best = src[i + w]
			elif y > 0 and src[i - w].a >= 0.5:
				best = src[i - w]
			if best.a >= 0.5:
				px[i] = ink.lerp(best.darkened(0.6), tint)


## Outline with a dark color below split_y and a light one above (reads as jelly).
func outline_split(dark: Color, light: Color, split_y: int) -> void:
	var src := px.duplicate()
	for y in h:
		for x in w:
			var i := y * w + x
			if src[i].a >= 0.5:
				continue
			var hit := (x + 1 < w and src[i + 1].a >= 0.5) or (x > 0 and src[i - 1].a >= 0.5) \
				or (y + 1 < h and src[i + w].a >= 0.5) or (y > 0 and src[i - w].a >= 0.5)
			if hit:
				px[i] = light if y < split_y else dark


func to_image() -> Image:
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for i in px.size():
		var c := px[i]
		var j := i * 4
		bytes[j] = int(c.r * 255.0 + 0.5)
		bytes[j + 1] = int(c.g * 255.0 + 0.5)
		bytes[j + 2] = int(c.b * 255.0 + 0.5)
		bytes[j + 3] = int(c.a * 255.0 + 0.5)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(to_image())
