class_name Attacks
extends RefCounted
## Numbers for attacks, ultimates and movement. Rank n: damage x(1 + 0.22(n-1)),
## cooldown x(1 - 0.05(n-1)). "scale" picks the stat the damage comes from.

const ATTACK := {
	"headbutt": {"cd": 0.8, "range": 14.0, "kind": "melee", "scale": "physical", "coef": 1.0, "sfx": "thud"},
	"jaws": {"cd": 0.85, "range": 16.0, "kind": "melee", "scale": "physical", "coef": 1.45, "sfx": "chomp"},
	"tail_whip": {"cd": 1.6, "range": 28.0, "kind": "spin", "scale": "physical", "coef": 0.8, "knock": 120.0, "sfx": "whip"},
	"spit": {"cd": 1.0, "range": 110.0, "kind": "proj", "scale": "ability", "coef": 0.9, "speed": 150.0, "ramp": "green", "sfx": "spit"},
	"charge": {"cd": 2.0, "range": 60.0, "kind": "lunge", "scale": "physical", "coef": 1.8, "sfx": "thud"},
	"stinger": {"cd": 1.2, "range": 105.0, "kind": "proj", "scale": "ability", "coef": 0.45, "speed": 190.0, "poison": 4.0, "ramp": "purple", "sfx": "spit"},
	"peck_flurry": {"cd": 1.3, "range": 18.0, "kind": "multi", "scale": "physical", "coef": 0.45, "hits": 3, "sfx": "peck"},
	"egg_toss": {"cd": 2.6, "range": 100.0, "kind": "lob", "scale": "ability", "coef": 1.4, "radius": 26.0, "sfx": "pop"},
	"mud_splash": {"cd": 2.4, "range": 34.0, "kind": "nova", "scale": "ability", "coef": 0.6, "slow": 0.5, "ramp": "brown", "sfx": "splash"},
	"pincer_snap": {"cd": 1.3, "range": 18.0, "kind": "melee", "scale": "physical", "coef": 1.5, "bleed": 5.0, "sfx": "snap"},
	"charm_song": {"cd": 4.5, "range": 70.0, "kind": "charm", "scale": "ability", "coef": 0.5, "sfx": "song"},
	"quack": {"cd": 2.6, "range": 62.0, "kind": "cone", "scale": "ability", "coef": 0.6, "stun": 0.9, "sfx": "quack"},
	"tentacle_lash": {"cd": 1.1, "range": 24.0, "kind": "multi", "scale": "ability", "coef": 0.55, "hits": 2, "slow": 0.4, "sfx": "whip"},
	"kick": {"cd": 1.0, "range": 16.0, "kind": "melee", "scale": "physical", "coef": 1.3, "knock": 150.0, "sfx": "thud"},
	"constrict": {"cd": 1.5, "range": 16.0, "kind": "melee", "scale": "physical", "coef": 1.1, "bleed": 4.0, "slow": 0.6, "sfx": "snap"},
	"feather_darts": {"cd": 1.5, "range": 115.0, "kind": "spread", "scale": "ability", "coef": 0.5, "count": 3, "speed": 210.0, "ramp": "duck", "sfx": "whip"},
}

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
