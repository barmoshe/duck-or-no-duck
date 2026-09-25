class_name Pal
extends RefCounted
## The palette: Endesga 32 (lospec.com/palette-list/endesga-32) arranged as dark-to-light
## ramps. All art picks colors from here: Pal.c("green", 3) or Pal.ramp("gold").

const E := {
	"rust": "be4a2f", "clay": "d77643", "sand": "ead4aa", "tan": "e4a672", "leather": "b86f50",
	"bark": "733e39", "plum": "3e2731", "wine": "a22633", "red": "e43b44", "orange": "f77622",
	"amber": "feae34", "lemon": "fee761", "leaf": "63c74d", "grass": "3e8948", "pine": "265c42",
	"deep": "193c3e", "navy": "124e89", "sky": "0099db", "cyan": "2ce8f5", "white": "ffffff",
	"mist": "c0cbdc", "slate": "8b9bb4", "steel": "5a6988", "dusk": "3a4466", "night": "262b44",
	"ink": "181425", "hot": "ff0044", "foam": "8fe3f0", "sea": "39b8e0", "grape": "68386c", "rose": "b55088", "salmon": "f6757a",
	"peach": "e8b796", "cocoa": "c28569",
	# foliage extras for the fluffy tree crowns
	"fern": "4fa845", "sprout": "95d65e", "ochre": "e0913a", "mauve": "8e4a5e", "dusty": "c46f7f",
	"blush": "e39aa4", "petal": "f7cbd0", "stone": "9aa3b5",
}

const RAMPS := {
	"green": ["deep", "pine", "grass", "leaf", "lemon"],
	"moss": ["plum", "pine", "grass", "leaf", "sand"],
	"gold": ["bark", "orange", "amber", "lemon", "white"],
	"duck": ["plum", "bark", "leather", "cocoa", "peach"],
	"brown": ["plum", "bark", "leather", "cocoa", "peach"],
	"sandy": ["bark", "leather", "tan", "sand", "white"],
	"red": ["plum", "wine", "red", "salmon", "peach"],
	"coral": ["wine", "rust", "clay", "tan", "sand"],
	"blue": ["ink", "navy", "sky", "cyan", "white"],
	"water": ["night", "navy", "sky", "cyan", "white"],
	"grey": ["ink", "dusk", "steel", "slate", "mist"],
	"snow": ["dusk", "steel", "slate", "mist", "white"],
	"purple": ["ink", "plum", "grape", "rose", "salmon"],
	"pink": ["grape", "rose", "salmon", "peach", "white"],
	"night": ["ink", "night", "dusk", "steel", "slate"],
	"orange": ["plum", "rust", "orange", "amber", "lemon"],
	"teal": ["ink", "deep", "pine", "sky", "cyan"],
	"slime": ["night", "navy", "sea", "cyan", "foam"],
	"chick": ["bark", "orange", "amber", "lemon", "lemon"],
	# tree crowns: rim, base, mid, light, speck
	"crown_green": ["pine", "grass", "fern", "leaf", "sprout"],
	"crown_autumn": ["bark", "clay", "ochre", "amber", "lemon"],
	"crown_blossom": ["mauve", "dusty", "blush", "petal", "white"],
}

const INK := Color("181425")

static var _cache := {}


static func e(name: String) -> Color:
	if not _cache.has(name):
		_cache[name] = Color("#" + String(E.get(name, "ff00ff")))
	return _cache[name]


static func c(ramp: String, step: int) -> Color:
	var r: Array = RAMPS.get(ramp, RAMPS["grey"])
	return e(String(r[clampi(step, 0, r.size() - 1)]))


static func ramp(name: String) -> Array[Color]:
	var out: Array[Color] = []
	for n in RAMPS.get(name, RAMPS["grey"]):
		out.append(e(String(n)))
	return out
