class_name Genome
extends RefCounted
## A creature's body as numbers: the "living clay" the Sculptor draws. Every creature in
## the game (Puddle, every animal, every boss) is one of these. Evolution nudges the
## numbers (longer legs, a longer neck, one more pair of eyes) so the body grows instead of
## swapping parts. Sizes are in pixels at 1x.
##
## plan:   blob | quad | bug | fish | bird | frog | flat | duck | serpent
## body:   len, h, segs (1-3), hump, jelly (0 firm .. 1 slime), sink
## head:   head (radius), neck, neck_up (radians), head_fwd; head == 0 means the face is on the body
## tail:   tail (length), tail_w, tail_tip, tail_up
## legs:   legs (pairs), leg_len, leg_w, leg_kind
## arms:   arms (kind), arm_n, arm_size
## back:   back (kind), back_size
## crown:  crown (kind), crown_n, crown_size
## face:   eyes (style), eye_n, eye_size, mouth (kind), mouth_size
## skin:   ramp, belly, accent, head_ramp, pattern, fuzz
## scale:  2 for bosses (drawn with more pixels, not upscaled)

const PLAN_OF_BODY := {
	"slime": "blob", "mochi": "blob", "beast": "quad", "chunk": "quad", "bug": "bug", "duck": "duck",
	"quad_s": "quad", "quad_l": "quad", "fish": "fish", "fish_l": "fish", "bird": "bird", "frog": "frog",
	"flat": "flat", "duckling": "duck", "serpent": "serpent",
}

## What each old leg part means for the new legs: [kind, pairs, length factor, width]
const LEGS := {
	"none": ["none", 0, 0.0, 0.0], "cilia": ["cilia", 3, 0.12, 1.0], "stubby": ["stub", 2, 0.35, 3.0],
	"long": ["digi", 2, 0.6, 2.0], "legs_tall": ["digi", 2, 0.85, 2.0], "bug": ["insect", 3, 0.45, 1.0],
	"frog": ["frog", 2, 0.45, 3.0], "crab": ["crab", 3, 0.5, 1.0], "webbed": ["webbed", 1, 0.35, 2.0],
	"stilts": ["stilt", 1, 1.0, 1.0],
}


static func base() -> Dictionary:
	return {
		"plan": "blob", "size": 8.0, "len": 14.0, "h": 10.0, "segs": 1, "hump": 0.0, "jelly": 1.0, "sink": 2.0,
		"head": 0.0, "neck": 0.0, "neck_up": 0.6, "head_fwd": 0.0,
		"tail": 0.0, "tail_w": 2.0, "tail_tip": "none", "tail_up": 0.2,
		"legs": 0, "leg_len": 0.0, "leg_w": 2.0, "leg_kind": "none",
		"arms": "none", "arm_n": 2, "arm_size": 1.0,
		"back": "none", "back_size": 1.0,
		"crown": "none", "crown_n": 2, "crown_size": 1.0,
		"eyes": "cute", "eye_n": 2, "eye_size": 1.0, "mouth": "none", "mouth_size": 1.0,
		"ramp": "slime", "belly": "", "accent": "gold", "head_ramp": "", "pattern": "none", "fuzz": 0.0,
		"scale": 1,
	}


## Body proportions per plan, from the creature's size (its collision size, 4..27).
static func _shape(g: Dictionary, plan: String, s: float, body: String) -> void:
	g["plan"] = plan
	g["size"] = s
	match plan:
		"blob":
			g["len"] = s * 1.75
			g["h"] = s * 1.3
			g["jelly"] = 1.0 if body == "slime" else 0.55
			g["sink"] = 0.0
		"quad":
			g["len"] = s * 2.1
			g["h"] = s * 1.05
			g["segs"] = 2
			g["head"] = s * 0.62
			g["neck"] = s * 0.25
			g["neck_up"] = 0.55
			g["tail"] = s * 0.7
			g["legs"] = 2
			g["leg_len"] = s * 0.55
			g["leg_w"] = maxf(2.0, s * 0.28)
			g["leg_kind"] = "digi"
			g["jelly"] = 0.0
			if body == "chunk":
				g["len"] = s * 1.9
				g["h"] = s * 1.35
				g["hump"] = s * 0.25
				g["leg_kind"] = "stub"
				g["leg_len"] = s * 0.35
				g["leg_w"] = maxf(3.0, s * 0.38)
				g["neck"] = s * 0.05
				g["head"] = s * 0.6
		"bug":
			g["len"] = s * 2.3
			g["h"] = s * 0.85
			g["segs"] = 3
			g["head"] = s * 0.45
			g["neck"] = 0.0
			g["legs"] = 3
			g["leg_len"] = s * 0.45
			g["leg_w"] = 1.0
			g["leg_kind"] = "insect"
			g["jelly"] = 0.0
		"fish":
			g["len"] = s * 2.4
			g["h"] = s * 1.05
			g["segs"] = 1
			g["tail"] = s * 0.8
			g["tail_tip"] = "fin"
			g["tail_up"] = 0.0
			g["jelly"] = 0.0
			g["sink"] = -s * 0.25  # swims a little above the ground
		"bird":
			g["len"] = s * 1.5
			g["h"] = s * 1.15
			g["head"] = s * 0.45
			g["neck"] = s * 0.7
			g["neck_up"] = 1.2
			g["legs"] = 1
			g["leg_len"] = s * 0.9
			g["leg_w"] = 1.0
			g["leg_kind"] = "stilt"
			g["tail"] = s * 0.45
			g["tail_tip"] = "feathers"
			g["jelly"] = 0.0
		"frog":
			g["len"] = s * 1.8
			g["h"] = s * 1.15
			g["head"] = s * 0.62
			g["neck"] = 0.0
			g["head_fwd"] = s * 0.1
			g["legs"] = 2
			g["leg_len"] = s * 0.45
			g["leg_w"] = 3.0
			g["leg_kind"] = "frog"
			g["jelly"] = 0.0
		"flat":
			g["len"] = s * 2.1
			g["h"] = s * 0.85
			g["head"] = 0.0
			g["legs"] = 3
			g["leg_len"] = s * 0.35
			g["leg_w"] = 1.0
			g["leg_kind"] = "crab"
			g["jelly"] = 0.0
		"duck":
			g["len"] = s * 1.9
			g["h"] = s * 1.05
			g["head"] = s * 0.55
			g["neck"] = s * 0.55
			g["neck_up"] = 1.25
			g["legs"] = 1
			g["leg_len"] = s * 0.3
			g["leg_w"] = 2.0
			g["leg_kind"] = "webbed"
			g["tail"] = s * 0.3
			g["tail_tip"] = "curl_duck"
			g["tail_up"] = 0.9
			g["jelly"] = 0.0
			if body == "duckling":
				g["len"] = s * 1.6
				g["h"] = s * 1.2
				g["head"] = s * 0.7
				g["neck"] = s * 0.25
		"serpent":
			g["len"] = s * 2.8
			g["h"] = s * 0.7
			g["segs"] = 3
			g["head"] = s * 0.5
			g["tail"] = s * 1.2
			g["tail_up"] = 0.0
			g["jelly"] = 0.0


## The old "look" dictionaries (every species, and the player's run) as a genome.
static func from_look(look: Dictionary) -> Dictionary:
	var g := base()
	var body := String(look.get("body", "slime"))
	var plan := String(PLAN_OF_BODY.get(body, "blob"))
	var s := clampf(float(look.get("size", 8)), 4.0, 30.0)
	_shape(g, plan, s, body)
	g["scale"] = int(look.get("scale", 1))
	var ramp := String(look.get("ramp", ""))
	if ramp == "":
		ramp = "slime" if plan == "blob" else "grey"
	g["ramp"] = ramp
	g["accent"] = String(look.get("accent", "gold"))
	# legs
	var lg := String(look.get("legs", "none"))
	if lg != "none" and LEGS.has(lg):
		var spec: Array = LEGS[lg]
		g["leg_kind"] = spec[0]
		if int(g["legs"]) == 0 or lg in ["crab", "bug", "cilia", "stilts", "webbed"]:
			g["legs"] = int(spec[1])
		g["leg_len"] = maxf(float(g["leg_len"]), s * float(spec[2]))
		g["leg_w"] = maxf(1.0, float(spec[3]) * (1.0 if s < 12 else 1.4))
		if lg == "legs_tall":
			g["leg_len"] = s * 0.85
	elif plan == "blob":
		g["legs"] = 0
	# tails
	var tl := String(look.get("tail", "none"))
	if tl != "none":
		g["tail_tip"] = tl
		g["tail"] = maxf(float(g["tail"]), s * {"nub": 0.25, "long": 0.8, "whip": 1.0, "fin": 0.7, "stinger": 0.9, "fluffy": 0.7,
			"curl": 0.35, "feathers": 0.55, "fan": 0.6, "serpent": 1.4}.get(tl, 0.6))
		if tl in ["stinger", "fan", "fluffy", "curl", "feathers"]:
			g["tail_up"] = 0.9
		elif tl in ["long", "whip", "serpent"]:
			g["tail_up"] = 0.15
	# head top, face
	g["crown"] = String(look.get("crown", look.get("head", "none")))
	if g["crown"] == "crest_duck":
		g["head_ramp"] = "green"
	g["eyes"] = String(look.get("eyes", "cute"))
	g["eye_n"] = {"many": 4, "compound": 2, "stalks": 2}.get(g["eyes"], 2)
	g["mouth"] = String(look.get("mouth", "none"))
	# back, armor and arms share the back / front zones
	var bk := String(look.get("back", "none"))
	var ar := String(look.get("armor", "none"))
	if bk.begins_with("shell"):
		g["back"] = "shell"
		g["back_size"] = 1.4
	elif bk != "none":
		g["back"] = {"wings_big": "wings_bird", "wings_bee": "wings_bug"}.get(bk, bk)
		g["back_size"] = 1.35 if bk in ["wings_big", "wings_bee"] else 1.0
	elif ar != "none":
		g["back"] = ar
	var am := String(look.get("arms", "none"))
	if am != "none":
		g["arms"] = "tentacle" if am.begins_with("tentacle") else "pincer"
		g["arm_size"] = 1.35 if am.ends_with("_big") else 1.0
		g["arm_n"] = 3 if am.begins_with("tentacle") else 1
	g["pattern"] = String(look.get("hide", look.get("pattern", "none")))
	if g["pattern"] == "down":
		g["fuzz"] = 1.0
	# a soft belly on warm-blooded bodies
	if plan in ["quad", "bird", "duck", "frog"]:
		g["belly"] = {"orange": "sandy", "brown": "sandy", "grey": "snow", "red": "sandy", "snow": "snow", "green": "gold",
			"blue": "snow", "duck": "sandy", "chick": "chick", "gold": "sandy"}.get(ramp, "")
	return g


## A stable cache key.
static func key(g: Dictionary) -> String:
	var ks := g.keys()
	ks.sort()
	var parts: Array[String] = []
	for k in ks:
		var v = g[k]
		parts.append("%s=%s" % [k, ("%.1f" % v) if v is float else str(v)])
	return "|".join(parts)


## Linear blend between two genomes (numbers only; kinds switch at the halfway point):
## used to animate an evolution growing in.
static func lerp_g(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var out := {}
	for k in b:
		var va = a.get(k, b[k])
		var vb = b[k]
		if (va is float or va is int) and (vb is float or vb is int) and not (va is int and vb is int and k in ["legs", "segs", "eye_n", "arm_n", "crown_n", "scale"]):
			out[k] = lerpf(float(va), float(vb), t)
		elif va is int and vb is int:
			out[k] = int(roundf(lerpf(float(va), float(vb), t)))
		else:
			out[k] = vb if t >= 0.5 else va
	return out


# ------------------------------------------------------------------ evolution grows the body
## Fields measured in pixels: a GROW delta for these is in "size-8 pixels" and scales
## with the creature's size, so a big creature grows proportionally.
const PX := ["len", "h", "head", "neck", "tail", "leg_len", "leg_w", "hump", "head_fwd", "tail_w"]
const CAPS := {"eye_n": [1, 6], "crown_n": [1, 2], "arm_n": [1, 4], "back_size": [0.6, 2.0], "arm_size": [0.6, 2.0],
	"crown_size": [0.6, 2.2], "eye_size": [0.6, 2.0], "mouth_size": [0.6, 2.2], "fuzz": [0.0, 1.0], "neck_up": [0.1, 1.5]}

## What each evolution does to the body, per level. Parts (a bill, wings, a shell) come
## from the evolution's look; these are the continuous changes on top: every pick shows.
const GROW := {
	"gulp": {"mouth_size": 0.1}, "headbutt": {"head": 0.4, "crown_size": 0.1}, "tail_whip": {"tail": 1.5, "tail_w": 0.2},
	"spit": {"mouth_size": 0.15, "head": 0.2}, "charge": {"crown_size": 0.2, "h": 0.3}, "jaws": {"head": 0.5, "mouth_size": 0.2},
	"stinger": {"tail": 1.0}, "peck_flurry": {"mouth_size": 0.2, "neck": 0.5}, "egg_toss": {"h": 0.4},
	"mud_splash": {"h": 0.3, "len": 0.3}, "pincer_snap": {"arm_size": 0.15}, "charm_song": {"crown_size": 0.15, "head": 0.2},
	"quack": {"mouth_size": 0.15}, "feather_darts": {"back_size": 0.1}, "mega_quack": {"mouth_size": 0.2, "head": 0.3},
	"body_slam": {"h": 0.8, "len": 0.5}, "duck_dive": {"neck": 0.8, "tail": 0.4}, "hibernate": {"h": 0.6, "fuzz": 0.3},
	"duckling_parade": {"tail": 0.5, "h": 0.3}, "molt_storm": {"back_size": 0.1, "fuzz": 0.3}, "leap": {"leg_len": 1.0},
	"paddle": {"leg_w": 0.2}, "burrow": {"mouth_size": 0.2, "len": 0.3}, "glide": {"back_size": 0.15},
	"sharp_teeth": {"mouth_size": 0.15, "head": 0.2}, "hunter_eyes": {"eye_size": 0.15, "head_fwd": 0.3},
	"lean_muscle": {"len": 0.8, "leg_len": 0.4, "h": -0.2}, "bloodlust": {"head_fwd": 0.3, "len": 0.2},
	"killer_instinct": {"eye_size": 0.2}, "carnivore": {"head": 0.3, "mouth_size": 0.1}, "piscivore": {"tail": 0.6, "len": 0.3},
	"night_vision": {"eye_size": 0.3}, "skittish": {"crown_size": 0.2, "leg_len": 0.3}, "long_legs": {"leg_len": 1.2, "legs_min": 1},
	"efficient_gut": {"h": 0.5}, "keen_nose": {"mouth_size": 0.2}, "camouflage": {"len": 0.2}, "playing_dead": {"h": 0.3},
	"herbivore": {"h": 0.4, "head": 0.2}, "scavenger": {"neck": 0.8}, "vegan": {"h": 0.5, "fuzz": 0.2},
	"omnivore": {"h": 0.4, "mouth_size": 0.1}, "more_eyes": {"eye_n": 2, "eye_size": 0.1}, "pheromones": {"crown_size": 0.2},
	"bright_colors": {"fuzz": 0.2}, "pack_call": {"crown_size": 0.2, "head": 0.2}, "soothing_hum": {"h": 0.3, "fuzz": 0.2},
	"herd_instinct": {"h": 0.5, "leg_w": 0.2}, "thick_hide": {"h": 0.6, "len": 0.3}, "big_bones": {"leg_w": 0.4, "h": 0.5, "len": 0.5},
	"horns": {"crown_size": 0.25, "crown_n": 0.34}, "shell": {"back_size": 0.12}, "spines": {"back_size": 0.15},
	"plating": {"back_size": 0.1, "h": 0.2}, "colossal": {"len": 1.5, "h": 1.5, "leg_w": 0.5},
	"quick_wit": {"eye_size": 0.1, "head": 0.3}, "venom_glands": {"tail_w": 0.2}, "echo": {"crown_size": 0.1, "head": 0.2},
	"mutant_luck": {"eye_n": 1}, "big_brain": {"head": 0.8}, "duck_bill": {"mouth_size": 0.2}, "webbed_feet": {"leg_w": 0.2},
	"down_feathers": {"fuzz": 0.6}, "duck_wings": {"back_size": 0.2}, "tail_curl": {"tail": 0.4}, "beady_eyes": {"eye_size": -0.1},
	"green_crest": {"crown_size": 0.2}, "convergent": {"neck": 1.0, "h": 0.5}, "swan_neck": {"neck": 5.0, "neck_up": 0.3},
	"goose_temper": {"eye_size": 0.2, "neck": 1.0}, "turtle_shell": {"back_size": 0.4}, "heron_stilts": {"leg_len": 3.0, "legs_min": 1},
	"pike_jaw": {"head": 0.6, "mouth_size": 0.4}, "tentacle_lash": {"arm_n": 1, "arm_size": 0.1}, "kick": {"leg_w": 0.3, "leg_len": 0.4},
	"constrict": {"tail": 1.0, "tail_w": 0.3}, "sprint": {"leg_len": 0.8}, "suckers": {"arm_size": 0.15}, "grip": {"arm_size": 0.15},
	"carapace": {"back_size": 0.2}, "eel_skin": {"len": 0.6, "h": -0.2}, "fleet_foot": {"leg_len": 0.6}, "four_stomachs": {"h": 0.8},
	"sweet_nectar": {"fuzz": 0.3, "back_size": 0.1},
	"branch_wings": {"back_size": 0.3}, "branch_tentacles": {"arm_n": 1}, "branch_legs": {"leg_len": 2.0, "legs_min": 2},
	"branch_arms": {"arm_size": 0.3}, "branch_shell": {"back_size": 0.3}, "branch_slithery": {"tail": 3.0, "len": 1.0},
	"branch_ruminant": {"h": 0.8, "crown_size": 0.3}, "branch_alpha": {"crown_size": 0.4, "head": 0.4},
	"branch_pollinator": {"back_size": 0.2, "fuzz": 0.4}, "branch_bill": {"mouth_size": 0.3},
}

## How each affinity point reshapes the body (continuous; capped at 12 points).
const DRIFT := {
	"predator": {"len": 0.25, "h": -0.08, "head_fwd": 0.12, "neck": 0.08},
	"prey": {"head": 0.1, "eye_size": 0.04, "len": -0.08, "crown_size": 0.04},
	"imposing": {"h": 0.2, "hump": 0.12, "leg_w": 0.08},
	"trickster": {"eye_n": 0.25, "tail": 0.15},
	"gregarious": {"fuzz": 0.08, "h": 0.1},
}


static func _add(g: Dictionary, delta: Dictionary, times: float, s: float) -> void:
	for k in delta:
		if k == "legs_min":
			if int(g["legs"]) < int(delta[k]):
				g["legs"] = int(delta[k])
				if String(g["leg_kind"]) == "none":
					g["leg_kind"] = "digi"
				g["leg_len"] = maxf(float(g["leg_len"]), s * 0.3)
				g["leg_w"] = maxf(float(g["leg_w"]), 2.0)
			continue
		if String(g["plan"]) == "blob" and k in ["head", "neck", "head_fwd"]:
			continue  # a blob's face stays on its body
		var v := float(delta[k]) * times
		if k in PX:
			v *= s / 8.0
		if g[k] is int:
			g[k] = int(g[k]) + int(roundf(v)) if k != "crown_n" else int(g[k])
		else:
			g[k] = float(g[k]) + v
	if delta.has("crown_n"):
		g["crown_n"] = 1 + int(float(delta["crown_n"]) * times)


## The player's body: the look's parts, then the metamorphosis form, affinity drift and
## every evolution's growth, then the readability caps.
static func of_run(run: Run) -> Dictionary:
	var lk: Dictionary = run.look
	var g := from_look(lk)
	var s := float(g["size"])
	var n := run.bodily_mutations()
	var pts := run.affinity_points()
	var dom := run.dominant_affinity()
	# the goo firms up: slime -> mochi -> a body
	if String(g["plan"]) == "blob":
		g["jelly"] = 1.0 if n < Run.MOCHI_AT else lerpf(0.55, 0.3, clampf(float(n - Run.MOCHI_AT) / 4.0, 0.0, 1.0))
		if int(g["legs"]) > 1 and String(g["leg_kind"]) != "cilia":
			g["legs"] = 1
		# the face grows out of the goo once it firms
		if n >= Run.MOCHI_AT:
			g["h"] = float(g["h"]) * 1.08
	elif String(lk.get("body", "")) in ["beast", "chunk", "bug"]:
		match dom:
			"prey":
				g["len"] = float(g["len"]) * 0.82
				g["h"] = float(g["h"]) * 1.15
				g["head"] = float(g["head"]) * 1.25
				g["leg_kind"] = "stub" if String(lk.get("legs", "stubby")) == "stubby" else g["leg_kind"]
				g["tail_tip"] = "fluffy" if String(g["tail_tip"]) == "none" else g["tail_tip"]
				g["tail"] = maxf(float(g["tail"]), s * 0.45)
			"gregarious":
				g["hump"] = 0.0
				g["fuzz"] = maxf(float(g["fuzz"]), 0.6)
				g["head"] = float(g["head"]) * 1.15
				g["tail_tip"] = "fluffy"
				g["tail"] = maxf(float(g["tail"]), s * 0.5)
		g["belly"] = {"red": "sandy", "green": "gold", "pink": "snow", "orange": "sandy", "purple": "pink"}.get(String(g["ramp"]), g["belly"])
	# affinity drift
	for a in DRIFT:
		var p := minf(12.0, float(pts.get(a, 0)))
		if p > 0.0:
			_add(g, DRIFT[a], p, s)
	# every evolution grows the body a little, per level
	for id in run.order:
		if GROW.has(id):
			_add(g, GROW[id], float(run.rank(id)), s)
	_clamp(g)
	return g


## Readability limits: at 20 px a creature has to stay a clear silhouette.
static func _clamp(g: Dictionary) -> void:
	var s := float(g["size"])
	for k in CAPS:
		var c: Array = CAPS[k]
		if g[k] is int:
			g[k] = clampi(int(g[k]), int(c[0]), int(c[1]))
		else:
			g[k] = clampf(float(g[k]), float(c[0]), float(c[1]))
	g["len"] = clampf(float(g["len"]), s * 1.2, s * 3.2)
	g["h"] = clampf(float(g["h"]), s * 0.6, s * 1.9)
	g["leg_len"] = clampf(float(g["leg_len"]), 0.0, s * 1.4)
	g["leg_w"] = clampf(float(g["leg_w"]), 1.0, maxf(2.0, s * 0.5))
	g["neck"] = clampf(float(g["neck"]), 0.0, s * 1.3)
	g["tail"] = clampf(float(g["tail"]), 0.0, s * 2.2)
	g["tail_w"] = clampf(float(g["tail_w"]), 1.0, s * 0.35)
	g["hump"] = clampf(float(g["hump"]), 0.0, s * 0.6)
	if float(g["head"]) > 0.0:
		g["head"] = clampf(float(g["head"]), s * 0.35, s * 0.95)
	g["legs"] = clampi(int(g["legs"]), 0, 4 if String(g["leg_kind"]) == "crab" else 3)


## An animal's genome: its look turned into a genome, then its species touches.
static func of_species(id: String) -> Dictionary:
	var lk := Species.look_of_raw(id)
	var g := from_look(lk)
	var tweak: Dictionary = SPECIES.get(id, {})
	for k in tweak:
		var key := String(k)
		if key.ends_with("*"):
			key = key.trim_suffix("*")
			g[key] = float(g[key]) * float(tweak[k])
		else:
			g[key] = tweak[k]
	_clamp(g)
	return g


## Hand-tuned touches per species on top of what its look says ("key*" multiplies).
const SPECIES := {
	"duckodile": {"plan": "quad", "segs": 2, "legs": 2, "leg_kind": "stub", "leg_len*": 0.3, "leg_w*": 1.6, "h*": 0.8,
		"len*": 1.15, "head": 9.0, "neck": 1.0, "mouth_size": 1.6, "tail_up": 0.05, "tail_w": 4.0},
	"quackaconda": {"plan": "serpent", "segs": 3, "h*": 0.75, "len*": 1.2, "tail*": 1.4, "tail_up": 0.05, "tail_tip": "long", "head": 8.0},
	"shelldrake": {"back": "shell", "back_size": 1.3, "h*": 1.3, "head": 7.0, "neck": 3.0, "legs": 2, "leg_kind": "stub", "leg_len*": 1.4, "leg_w": 4.0},
	"duckaroo": {"leg_kind": "frog", "legs": 1, "leg_len*": 1.3, "tail_w": 4.0, "tail_up": 0.1},
	"great_mallard": {"head*": 0.72, "neck*": 1.3, "leg_w": 4.0, "leg_len*": 1.3, "tail*": 1.3},
	"scorpion": {"tail_up": 1.2, "arm_size": 1.3, "arm_n": 1},
	"crab": {"arm_size": 1.4},
	"duckling": {"head*": 1.1},
	"beetle": {"h*": 1.2},
}
