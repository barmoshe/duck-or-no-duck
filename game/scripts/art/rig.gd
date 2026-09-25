class_name Rig
extends RefCounted
## The Evolution Graphics System. Creatures are hand-drawn pixel art (ASCII sheets in
## art/sheets/*.gd), composed per frame like Everything is Crab's Darwin:
##   * a BODY rig: frames for idle / move / attack, with socket markers painted into
##     each frame (where eyes, mouth, crown, back, armor, tail, limbs and arms attach)
##   * PARTS: small hand-drawn sprites per slot, each with its own pivot and frames
##     (legs walk, wings flap, tails wag, eyes blink), recolored from the body palette
##   * the compositor stacks the slots in a fixed z-order at the sockets of the current
##     body frame, so every part rides every bounce.
##
## Sheet characters:
##   .  clear            1 2 3 4  ramp steps (dark to light)   o  ramp step 0 (outline)
##   O  light outline (ramp 3, reads as jelly)    a b c d  accent ramp 1..4   x accent 0
##   k ink  w white  s mist  y lemon  Y amber  e orange  E rust  n bark  N leather
##   r red  R wine  p salmon  P rose  g leaf  G grass  t cyan  T sky  u navy  v grape
## Body socket markers (drawn as the body color around them):
##   * eye  <  mouth  ^  crown  #  back  =  armor  ~  tail  /  near front limb
##   :  near hind limb  %  arm  !  hide center

const FIXED := {
	"k": "ink", "w": "white", "s": "mist", "y": "lemon", "Y": "amber", "e": "orange", "E": "rust",
	"n": "bark", "N": "leather", "r": "red", "R": "wine", "p": "salmon", "P": "rose", "g": "leaf",
	"G": "grass", "t": "cyan", "T": "sky", "u": "navy", "v": "grape",
}
const MARKERS := {"*": "eye", "<": "mouth", "^": "crown", "#": "back", "=": "armor", "~": "tail",
	"/": "limb_f", ":": "limb_h", "%": "arm", "!": "hide"}

# z-order of the 11 slots (far pieces first)
const ORDER := ["limb_h_far", "limb_f_far", "back_far", "tail", "body", "hide", "armor", "limb_h", "limb_f",
	"back", "crown", "eye", "mouth", "arm"]

static var _parsed := {}


## Parses a sheet (Array of row strings) into {w, h, px: Array of chars, marks: {name: Vector2i}}.
static func parse(rows: Array) -> Dictionary:
	var key := "\n".join(rows)
	if _parsed.has(key):
		return _parsed[key]
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var px: Array = []
	var marks := {}
	for y in h:
		var r := String(rows[y])
		for x in w:
			var ch := r[x] if x < r.length() else "."
			if MARKERS.has(ch):
				marks[MARKERS[ch]] = Vector2i(x, y)
				ch = "M"
			px.append(ch)
	# a marker takes the color of its left or right neighbor
	for y in h:
		for x in w:
			if px[y * w + x] != "M":
				continue
			var fill := "2"
			for dx in [-1, 1, -2, 2]:
				var xx: int = x + dx
				if xx >= 0 and xx < w and not px[y * w + xx] in ["M", "."]:
					fill = px[y * w + xx]
					break
			px[y * w + x] = fill
	var out := {"w": w, "h": h, "px": px, "marks": marks}
	_parsed[key] = out
	return out


static func color_of(ch: String, ramp: String, accent: String) -> Color:
	match ch:
		"o":
			return Pal.c(ramp, 0)
		"O":
			return Pal.c(ramp, 3)
		"1", "2", "3", "4":
			return Pal.c(ramp, int(ch))
		"x":
			return Pal.c(accent, 0)
		"a", "b", "c", "d":
			return Pal.c(accent, "abcd".find(ch) + 1)
	if FIXED.has(ch):
		return Pal.e(FIXED[ch])
	return Color(0, 0, 0, 0)


## Blits a parsed sheet onto a Px canvas with its pivot at `at`. shade: -1 darker (far side).
static func blit(p: Px, sheet: Dictionary, pivot: Vector2i, at: Vector2i, ramp: String, accent: String,
		flip: bool = false, shade: int = 0) -> void:
	var w: int = sheet["w"]
	var h: int = sheet["h"]
	var px: Array = sheet["px"]
	for y in h:
		for x in w:
			var ch: String = px[y * w + x]
			if ch == ".":
				continue
			var c := color_of(ch, ramp, accent)
			if c.a <= 0.0:
				continue
			if shade < 0:
				c = c.darkened(0.28)
			var sx := (pivot.x - x) if flip else (x - pivot.x)
			p.put(at.x + sx, at.y + y - pivot.y, c)


## Paints a hide pattern only where the body is (a mask).
static func blit_masked(p: Px, sheet: Dictionary, pivot: Vector2i, at: Vector2i, ramp: String, accent: String, mask: PackedByteArray) -> void:
	var w: int = sheet["w"]
	var h: int = sheet["h"]
	var px: Array = sheet["px"]
	for y in h:
		for x in w:
			var ch: String = px[y * w + x]
			if ch == ".":
				continue
			var tx := at.x + x - pivot.x
			var ty := at.y + y - pivot.y
			if tx < 0 or ty < 0 or tx >= p.w or ty >= p.h or mask[ty * p.w + tx] == 0:
				continue
			p.put(tx, ty, color_of(ch, ramp, accent))
