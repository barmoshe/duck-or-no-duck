class_name Foods
extends RefCounted
## Food, as Everything is Crab does it: three types (fruit, meat, fish), four rarities
## each (common, rare, epic, legendary), shown by color: green, blue, purple, gold. Some
## pieces sparkle and heal as you eat them. Trees, bushes and cacti give fruit, fish pools
## give fish, animals drop meat when they die (fish-like animals drop fish), whoever
## killed them. Every piece rolls its rarity from the source's weights; luck tilts it.

const TYPES := ["fruit", "meat", "fish"]
const RARITY := ["common", "rare", "epic", "legendary"]
const XP_MULT := [1.0, 2.0, 4.0, 10.0]
const LIFE := [30.0, 36.0, 45.0, 60.0]  # seconds on the ground before it spoils
## rarity weights per source kind
const WEIGHTS := {
	"animal": [75.0, 19.0, 5.0, 1.0],
	"alpha": [55.0, 28.0, 13.0, 4.0],
	"boss": [55.0, 27.0, 14.0, 4.0],
	"plant": [82.0, 14.0, 3.5, 0.5],
	"pool": [70.0, 22.0, 6.5, 1.5],
}
## Sparkling food heals: every bite of it restores this share of max HP. Legendary food
## sparkles for its rarity and never heals, as in Crab.
const HEAL_BITE := 0.045
## the rarity glow around a piece of food
const GLOW := ["", "sky", "rose", "amber"]
## the text color for a type's pickup numbers
const TYPE_COL := {"fruit": "salmon", "meat": "peach", "fish": "cyan"}
## which fruit grows where (the leaf color a shaken source throws); the fruit itself is
## drawn by rarity: green apple, blue plum, purple mangosteen, golden grapes
const FRUIT_OF_BIOME := ["apple", "apple", "pear", "snowberry"]
## base fruit XP (before rarity, food bonuses and the run's minute)
const FRUIT_XP := 2.5
## Eating: every piece takes BITES bites, and you eat one piece at a time, one bite every
## BITE_TIME seconds at 100% Feeding Speed (a common piece is about two seconds). The
## first bite on reaching food is instant. Each bite pays one share of the piece, the
## last pays two (Crab: 2 + 2 + 2 + 4 = 10 for a common piece).
const BITES := 4
const BITE_TIME := 0.55
const SHARES := BITES + 1
## the piece's value is its Progress for all four bites; 1.3 since v7.2 makes up for
## eating one piece at a time (bots then reach the first boss at the old level)
const VALUE := 1.3
const FISH_POOL_XP := 3.0


## Roll a rarity index (0..3). luck shifts weight toward the rarer rows.
static func roll(rng: RandomNumberGenerator, source: String, luck: float = 0.0) -> int:
	var w: Array = WEIGHTS.get(source, WEIGHTS["animal"])
	var ws: Array[float] = []
	var total := 0.0
	for i in w.size():
		var v := float(w[i]) * (1.0 + maxf(0.0, luck) * 0.12 * i)
		ws.append(v)
		total += v
	var r := rng.randf() * total
	for i in ws.size():
		r -= ws[i]
		if r <= 0.0:
			return i
	return 0


## Common, rare and epic pieces may sparkle (healing food); legendary never does.
static func heal_chance(rar: int, hp_frac: float) -> float:
	if rar >= 3:
		return 0.0
	return 0.08 + (0.08 if hp_frac < 0.4 else 0.0)


## The sprite for a piece: its type, rarity and how many bites are gone (0..3).
static func sprite_name(type: String, rar: int, bitten: int = 0) -> String:
	return "food_%s_%d_%d" % [type, clampi(rar, 0, 3), clampi(bitten, 0, BITES - 1)]


## Seconds between bites at a Feeding Speed (100 = base).
static func bite_time(feed: float) -> float:
	return BITE_TIME / maxf(0.2, feed / 100.0)


## The share of a piece's Progress one bite pays: the last bite pays double.
static func bite_share(bites_left: int) -> float:
	return (2.0 if bites_left <= 1 else 1.0) / float(SHARES)
