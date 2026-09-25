class_name Foods
extends RefCounted
## Food, as Everything is Crab does it: three types (fruit, meat, fish), four rarities
## each (common, rare, epic, legendary), plus heart drops that heal. Trees, bushes and
## cacti give fruit, fish pools give fish, animals give meat (fish-like animals give fish).
## Every piece rolls its rarity from the source's weights; luck tilts the roll.

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
const HEART_HEAL := 0.2  # of max HP
## the rarity glow around a piece of food
const GLOW := ["", "sky", "rose", "amber"]
## the text color for a type's pickup numbers
const TYPE_COL := {"fruit": "salmon", "meat": "peach", "fish": "cyan", "heart": "salmon"}
## which fruit grows where: grass + lake apples, desert prickly pears, snow berries
const FRUIT_OF_BIOME := ["apple", "apple", "pear", "snowberry"]
## base fruit XP (before rarity, food bonuses and the run's minute)
const FRUIT_XP := 2.5
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


## Common, rare and epic pieces may turn into a heart drop; legendary never does.
static func heart_chance(rar: int, hp_frac: float) -> float:
	if rar >= 3:
		return 0.0
	return 0.05 + (0.08 if hp_frac < 0.4 else 0.0)


static func sprite_name(type: String, variant: String, rar: int) -> String:
	if type == "heart":
		return "food_heart"
	return "food_%s_%d" % [variant if type == "fruit" else type, rar]
