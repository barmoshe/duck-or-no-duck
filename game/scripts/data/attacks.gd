class_name Attacks
extends RefCounted
## Numbers for attacks, ultimates and movement. Rank n: damage x(1 + 0.22(n-1)),
## cooldown x(1 - 0.05(n-1)). "scale" picks the stat the damage comes from.

## Every attack has its own shape, reach, windup and cooldown, and one thing only it does.
## shape: bite (one target in reach), arc (everything in a wedge, "arc" = half angle in
## degrees), line (a narrow strip, "width" px), circle (all around you), cone (a long wide
## wedge), lunge (you dash along a line), shot (projectiles, "speed" px/s, stop at their
## range), lob (lands after "flight" s and bursts in "radius"). range is in px (10 px =
## 1 u on the cards). windup: seconds from the press to the hit. "col" colors its range
## marker and effects; the attack's own animation is drawn by Fx under its id.
const ATTACK := {
	"gulp": {"cd": 0.75, "range": 20.0, "shape": "bite", "windup": 0.0, "scale": "physical", "coef": 1.1, "sfx": "chomp", "col": "leaf"},
	"headbutt": {"cd": 1.0, "range": 18.0, "shape": "line", "width": 12.0, "windup": 0.12, "scale": "physical", "coef": 1.4, "knock": 130.0, "stun": 0.4, "sfx": "thud", "col": "amber"},
	"jaws": {"cd": 0.85, "range": 18.0, "shape": "arc", "arc": 35.0, "windup": 0.08, "scale": "physical", "coef": 1.45, "sfx": "chomp", "col": "white"},
	"tail_whip": {"cd": 1.6, "range": 30.0, "shape": "circle", "windup": 0.1, "scale": "physical", "coef": 0.8, "knock": 140.0, "sfx": "whip", "col": "peach"},
	"spit": {"cd": 0.9, "range": 120.0, "shape": "shot", "speed": 170.0, "windup": 0.0, "scale": "ability", "coef": 0.8, "splash": 14.0, "ramp": "green", "sfx": "spit", "col": "leaf"},
	"charge": {"cd": 2.2, "range": 70.0, "shape": "lunge", "width": 14.0, "windup": 0.15, "scale": "physical", "coef": 1.9, "knock": 180.0, "sfx": "thud", "col": "orange"},
	"stinger": {"cd": 2.0, "range": 140.0, "shape": "shot", "speed": 240.0, "windup": 0.0, "scale": "ability", "coef": 0.6, "poison": 3.0, "poison_t": 5.0, "ramp": "purple", "sfx": "spit", "col": "grape"},
	"peck_flurry": {"cd": 1.2, "range": 26.0, "shape": "line", "width": 8.0, "windup": 0.0, "scale": "physical", "coef": 0.45, "hits": 3, "crit_bonus": 10.0, "sfx": "peck", "col": "lemon"},
	"egg_toss": {"cd": 2.6, "range": 110.0, "shape": "lob", "flight": 0.5, "windup": 0.0, "scale": "ability", "coef": 1.4, "radius": 28.0, "sfx": "pop", "col": "lemon"},
	"mud_splash": {"cd": 2.6, "range": 36.0, "shape": "circle", "windup": 0.05, "scale": "ability", "coef": 0.6, "slow": 0.5, "pool": 2.5, "ramp": "brown", "sfx": "splash", "col": "bark"},
	"pincer_snap": {"cd": 1.3, "range": 20.0, "shape": "arc", "arc": 25.0, "windup": 0.1, "scale": "physical", "coef": 0.9, "hits": 2, "bleed": 5.0, "sfx": "snap", "col": "red"},
	"charm_song": {"cd": 4.5, "range": 80.0, "shape": "bite", "windup": 0.3, "scale": "ability", "coef": 0.5, "sfx": "song", "col": "rose"},
	"quack": {"cd": 2.6, "range": 64.0, "shape": "cone", "arc": 35.0, "windup": 0.1, "scale": "ability", "coef": 0.6, "stun": 0.9, "sfx": "quack", "col": "amber"},
	"tentacle_lash": {"cd": 1.2, "range": 40.0, "shape": "line", "width": 10.0, "windup": 0.08, "scale": "ability", "coef": 0.55, "hits": 2, "slow": 0.4, "pull": 150.0, "sfx": "whip", "col": "grape"},
	"kick": {"cd": 1.0, "range": 16.0, "shape": "arc", "arc": 50.0, "windup": 0.06, "scale": "physical", "coef": 1.3, "knock": 190.0, "bowl": 0.5, "sfx": "thud", "col": "sand"},
	"constrict": {"cd": 1.6, "range": 18.0, "shape": "bite", "windup": 0.1, "scale": "physical", "coef": 0.35, "hits": 4, "hold": 1.2, "bleed": 4.0, "sfx": "snap", "col": "pine"},
	"feather_darts": {"cd": 1.5, "range": 130.0, "shape": "shot", "speed": 230.0, "windup": 0.0, "scale": "ability", "coef": 0.5, "count": 3, "pierce": 1, "ramp": "duck", "sfx": "whip", "col": "white"},
}
## What only this attack does, for its card.
const TRAIT := {
	"gulp": "A small lunge; a kill heals you.",
	"headbutt": "Knocks back and stuns for a moment.",
	"jaws": "Double damage to stunned animals.",
	"tail_whip": "Hits and knocks back everything around you.",
	"spit": "The glob splashes what's next to the target.",
	"charge": "You can't be hurt while charging; hits all in your path.",
	"stinger": "Poisons for 5 seconds.",
	"peck_flurry": "Three pecks, each +10% crit chance.",
	"egg_toss": "Shows where it lands; bursts in an area.",
	"mud_splash": "Leaves a mud pool that slows for 2.5 s.",
	"pincer_snap": "Snips twice; makes targets bleed.",
	"charm_song": "A weakened animal joins you.",
	"quack": "Stuns everything in the cone.",
	"tentacle_lash": "Two lashes that slow and pull targets to you.",
	"kick": "Sends targets flying into others.",
	"constrict": "Holds the target and squeezes four times.",
	"feather_darts": "Each feather goes through one animal.",
}
const SHAPE_NAME := {"bite": "Single", "arc": "Swipe", "line": "Ahead", "circle": "Around",
	"cone": "Cone", "lunge": "Charge", "shot": "Shot", "lob": "Lob"}


## Range in units for a card (10 px = 1 u).
static func range_u(id: String) -> float:
	return float(ATTACK[id]["range"]) / 10.0


## How quickly an attack lands after the press.
static func speed_name(id: String) -> String:
	var a: Dictionary = ATTACK[id]
	var w := float(a.get("windup", 0.0)) + float(a.get("flight", 0.0))
	if String(a["shape"]) == "shot":
		return "Fast shot" if float(a["speed"]) >= 200.0 else "Shot"
	if w <= 0.01:
		return "Instant"
	if w <= 0.1:
		return "Quick"
	if w <= 0.2:
		return "Heavy"
	return "Slow"


const ULT := {
	"mega_quack": {"cd": 16.0, "radius": 115.0, "scale": "ability", "coef": 2.2, "stun": 2.2},
	"body_slam": {"cd": 11.0, "radius": 46.0, "scale": "physical", "coef": 2.6},
	"duck_dive": {"cd": 13.0, "radius": 60.0, "scale": "physical", "coef": 2.0, "dur": 1.2},
	"hibernate": {"cd": 20.0, "heal": 0.45, "armor": 10.0, "dur": 3.0},
	"duckling_parade": {"cd": 22.0, "count": 3, "dur": 18.0},
	"molt_storm": {"cd": 18.0, "radius": 55.0, "scale": "ability", "coef": 0.35, "dur": 4.0},
}

const MOVE := {
	"scoot": {"cd": 4.0, "dist": 55.0, "time": 0.2, "invuln": false},
	"leap": {"cd": 4.5, "dist": 95.0, "time": 0.4, "invuln": true, "air": true},
	"paddle": {"cd": 1.8, "dist": 48.0, "time": 0.18, "invuln": false},
	"burrow": {"cd": 5.0, "dist": 80.0, "time": 1.0, "invuln": true, "under": true},
	"sprint": {"cd": 3.0, "dist": 80.0, "time": 0.28, "invuln": false},
	"glide": {"cd": 5.0, "dist": 125.0, "time": 0.55, "invuln": true, "air": true},
}


static func rank_dmg(rank: int) -> float:
	return 1.0 + 0.22 * (rank - 1)


static func rank_cd(rank: int) -> float:
	return 1.0 - 0.05 * (rank - 1)
