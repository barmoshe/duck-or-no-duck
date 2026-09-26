class_name Ui
extends RefCounted
## Pixel UI kit: panels, bars, text with a 1px ink outline, buttons as hit rects. All
## screens draw themselves at the virtual resolution and read input in _input, so taps
## always land (lesson from Wandcraft: a 0x0 Control never gets GUI clicks).

const PANEL := Color("262b44")
const PANEL_LIGHT := Color("3a4466")
const TEXT := Color("ffffff")
const DIM := Color("8b9bb4")
# the wooden HUD frames (Everything is Crab style)
const WOOD_OUT := Color("3e2731")
const WOOD := Color("b86f50")
const WOOD_HI := Color("e4a672")
const WOOD_LO := Color("733e39")
const WOOD_IN := Color("2a1c24")
const PARCHMENT := Color("ead4aa")


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
static func para(ci: CanvasItem, pos: Vector2, s: String, width: float, col: Color = TEXT, f: Font = null, size: int = 8, line_h: int = 9, outline: bool = true) -> float:
	if f == null:
		f = small()
	var words := s.split(" ")
	var line := ""
	var y := pos.y
	for wd in words:
		var trial := wd if line == "" else line + " " + wd
		if text_w(f, trial, size) > width and line != "":
			text(ci, Vector2(pos.x, y), line, col, f, size, 0, outline)
			y += line_h
			line = wd
		else:
			line = trial
	if line != "":
		text(ci, Vector2(pos.x, y), line, col, f, size, 0, outline)
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


## A wooden frame: dark outline with clipped corners, a tan board lit on top.
static func wood(ci: CanvasItem, r: Rect2) -> void:
	var rr := Rect2(r.position.floor(), r.size.floor())
	ci.draw_rect(Rect2(rr.position + Vector2(1, 2), rr.size - Vector2(2, 1)), Color(0, 0, 0, 0.3))
	ci.draw_rect(Rect2(rr.position + Vector2(1, 0), Vector2(rr.size.x - 2, rr.size.y)), WOOD_OUT)
	ci.draw_rect(Rect2(rr.position + Vector2(0, 1), Vector2(rr.size.x, rr.size.y - 2)), WOOD_OUT)
	var f := rr.grow(-1)
	ci.draw_rect(f, WOOD)
	ci.draw_rect(Rect2(f.position, Vector2(f.size.x, 1)), WOOD_HI)
	ci.draw_rect(Rect2(f.position + Vector2(0, f.size.y - 1), Vector2(f.size.x, 1)), WOOD_LO)


## A bar inside a wooden frame, with an optional label centered on it.
static func wood_bar(ci: CanvasItem, r: Rect2, frac: float, fill: Color, label: String = "") -> void:
	wood(ci, r)
	var rr := Rect2(r.position.floor(), r.size.floor())
	var inner := Rect2(rr.position + Vector2(2, 2), rr.size - Vector2(4, 4))
	ci.draw_rect(inner, WOOD_IN)
	var w := floorf(inner.size.x * clampf(frac, 0.0, 1.0))
	if w > 0:
		ci.draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), fill)
		ci.draw_rect(Rect2(inner.position, Vector2(w, 1)), fill.lightened(0.35))
		if inner.size.y > 3:
			ci.draw_rect(Rect2(inner.position + Vector2(0, inner.size.y - 1), Vector2(w, 1)), fill.darkened(0.3))
	if label != "":
		text(ci, Vector2(inner.get_center().x, floorf(rr.position.y + rr.size.y * 0.5 + 3.5)), label, TEXT, small(), 8, 1)


## A framed ability slot: icon on parchment, darkened from the top while cooling down.
static func slot(ci: CanvasItem, r: Rect2, icon: Texture2D, cd_frac: float) -> void:
	wood(ci, r)
	var rr := Rect2(r.position.floor(), r.size.floor())
	var inner := Rect2(rr.position + Vector2(2, 2), rr.size - Vector2(4, 4))
	ci.draw_rect(inner, PARCHMENT)
	ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), Color(1, 1, 1, 0.45))
	var isz := icon.get_size()
	ci.draw_texture(icon, (inner.get_center() - isz * 0.5).floor())
	if cd_frac > 0.0:
		var hgt := ceilf(inner.size.y * clampf(cd_frac, 0.0, 1.0))
		ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, hgt)), Color(0.09, 0.07, 0.14, 0.62))


## Crab's red title ribbon with folded tails, centered on c.x with its top at c.y.
static func ribbon(ci: CanvasItem, c: Vector2, label: String, dark: bool = false) -> void:
	var tw := text_w(bold(), label, 16) + 24.0
	var r := Rect2(floorf(c.x - tw * 0.5), c.y, floorf(tw), 19)
	var red := Color("be4a2f") if not dark else Color("a22633")
	for k in [-1, 1]:
		var tail_x := r.position.x - 8 if k < 0 else r.end.x
		ci.draw_rect(Rect2(tail_x, r.position.y + 4, 8, 13), WOOD_OUT)
		ci.draw_rect(Rect2(tail_x + (1 if k < 0 else 0), r.position.y + 5, 7, 11), red.darkened(0.3))
	wood(ci, r)
	ci.draw_rect(r.grow(-2), red)
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 1)), red.lightened(0.3))
	text(ci, Vector2(c.x, r.position.y + 15), label, TEXT, bold(), 16, 1)


## A wooden frame holding a parchment sheet.
static func board(ci: CanvasItem, r: Rect2) -> void:
	wood(ci, r)
	ci.draw_rect(r.grow(-3), PARCHMENT)
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 1)), Color(1, 1, 1, 0.4))


const INK_TEXT := Color("3e2731")


## A wooden button with a colored face and a centered label.
static func wood_button(ci: CanvasItem, r: Rect2, label: String, face: Color, down: bool = false, enabled: bool = true, size: int = 8) -> void:
	var rr := Rect2(r.position.floor() + Vector2(0, 1 if down else 0), r.size.floor())
	wood(ci, rr)
	var f := face if enabled else Color("5a3a35")
	ci.draw_rect(rr.grow(-3), f)
	ci.draw_rect(Rect2(rr.position + Vector2(3, 3), Vector2(rr.size.x - 6, 1)), f.lightened(0.3))
	var fnt := bold() if size >= 16 else small()
	text(ci, Vector2(rr.get_center().x, floorf(rr.get_center().y + size * 0.36)), label, TEXT if enabled else DIM, fnt, size, 1)
