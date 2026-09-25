class_name Ui
extends RefCounted
## Pixel UI kit: panels, bars, text with a 1px ink outline, buttons as hit rects. All
## screens draw themselves at the virtual resolution and read input in _input, so taps
## always land (lesson from Wandcraft: a 0x0 Control never gets GUI clicks).

const PANEL := Color("262b44")
const PANEL_LIGHT := Color("3a4466")
const TEXT := Color("ffffff")
const DIM := Color("8b9bb4")


static func small() -> Font:
	return Game.font("small")


static func bold() -> Font:
	return Game.font("bold")


static func body() -> Font:
	return Game.font("body")


static func text_w(f: Font, s: String, size: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Text with a 1 px ink outline. align: 0 left, 1 center, 2 right (around pos.x).
static func text(ci: CanvasItem, pos: Vector2, s: String, col: Color = TEXT, f: Font = null, size: int = 8, align: int = 0, outline: bool = true) -> void:
	if f == null:
		f = small()
	var p := pos.floor()
	if align != 0:
		var w := text_w(f, s, size)
		p.x -= floorf(w * (0.5 if align == 1 else 1.0))
	if outline:
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1)]:
			ci.draw_string(f, p + d, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Pal.INK, col.a))
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Wrapped text inside width, returns the height used.
static func para(ci: CanvasItem, pos: Vector2, s: String, width: float, col: Color = TEXT, f: Font = null, size: int = 8, line_h: int = 9) -> float:
	if f == null:
		f = small()
	var words := s.split(" ")
	var line := ""
	var y := pos.y
	for wd in words:
		var trial := wd if line == "" else line + " " + wd
		if text_w(f, trial, size) > width and line != "":
			text(ci, Vector2(pos.x, y), line, col, f, size)
			y += line_h
			line = wd
		else:
			line = trial
	if line != "":
		text(ci, Vector2(pos.x, y), line, col, f, size)
		y += line_h
	return y - pos.y


static func panel(ci: CanvasItem, r: Rect2, fill: Color = PANEL, border: Color = Pal.INK, hi: Color = PANEL_LIGHT) -> void:
	var rr := Rect2(r.position.floor(), r.size.floor())
	ci.draw_rect(Rect2(rr.position + Vector2(0, 2), rr.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(rr, border)
	ci.draw_rect(rr.grow(-1), fill)
	ci.draw_rect(Rect2(rr.position + Vector2(1, 1), Vector2(rr.size.x - 2, 1)), hi)
	# notched corners
	for c in [rr.position, rr.position + Vector2(rr.size.x - 1, 0), rr.position + Vector2(0, rr.size.y - 1), rr.end - Vector2.ONE]:
		ci.draw_rect(Rect2(c, Vector2.ONE), Color(0, 0, 0, 0))


static func bar(ci: CanvasItem, r: Rect2, frac: float, fill: Color, back: Color = Color("181425")) -> void:
	var rr := Rect2(r.position.floor(), r.size.floor())
	ci.draw_rect(rr, Pal.INK)
	ci.draw_rect(rr.grow(-1), back)
	var w := floorf((rr.size.x - 2) * clampf(frac, 0.0, 1.0))
	if w > 0:
		ci.draw_rect(Rect2(rr.position + Vector2(1, 1), Vector2(w, rr.size.y - 2)), fill)
		ci.draw_rect(Rect2(rr.position + Vector2(1, 1), Vector2(w, 1)), fill.lightened(0.3))


static func button(ci: CanvasItem, r: Rect2, label: String, col: Color, pressed: bool = false, enabled: bool = true, size: int = 8) -> void:
	var rr := Rect2(r.position.floor(), r.size.floor())
	var off := Vector2(0, 1) if pressed else Vector2.ZERO
	if not pressed:
		ci.draw_rect(Rect2(rr.position + Vector2(0, 2), rr.size), Pal.INK)
	var c := col if enabled else Color("5a6988")
	ci.draw_rect(Rect2(rr.position + off, rr.size), Pal.INK)
	ci.draw_rect(Rect2(rr.position + off + Vector2(1, 1), rr.size - Vector2(2, 2)), c)
	ci.draw_rect(Rect2(rr.position + off + Vector2(1, 1), Vector2(rr.size.x - 2, 1)), c.lightened(0.35))
	ci.draw_rect(Rect2(rr.position + off + Vector2(1, rr.size.y - 2), Vector2(rr.size.x - 2, 1)), c.darkened(0.3))
	var f := bold() if size >= 16 else small()
	var tc := Pal.INK if c.get_luminance() > 0.5 else TEXT
	text(ci, Vector2(rr.position.x + rr.size.x * 0.5, rr.position.y + rr.size.y * 0.5 + size * 0.36) + off, label, tc, f, size, 1, tc == TEXT)


## A creature texture at an integer scale, centered at c.
static func creature(ci: CanvasItem, look: Dictionary, c: Vector2, scale: int, frame: int = 0) -> void:
	var fr := Anatomy.frames(look)
	var tex: Texture2D = (fr["idle"] as Array)[frame % 2]
	var sz := tex.get_size() * scale
	ci.draw_texture_rect(tex, Rect2((c - sz * 0.5).floor(), sz), false)


## Simple affinity glyph: a colored gem.
static func gem(ci: CanvasItem, c: Vector2, aff: String) -> void:
	var col := Pal.c(String(Evolutions.AFF_RAMP.get(aff, "grey")), 3)
	var pts := PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0), c + Vector2(0, 3), c + Vector2(-3, 0)])
	ci.draw_colored_polygon(pts, col)
	ci.draw_rect(Rect2(c + Vector2(-1, -2), Vector2(1, 1)), Color.WHITE)
