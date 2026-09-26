class_name Species
extends RefCounted
## The animals of the open world, built from the same parts as the player (Anatomy).
## Roles (Crab's ecosystem): prey (grazes, flees), hybrid (grazes, fights back),
## predator (hunts anything smaller, you included), scavenger (steals food drops),
## mimic (sleeps as a fruit bush until you get close). "night": bolder in the dark.
## "fish": drops fish (Piscivore food) instead of meat.

const BIOMES := ["grass", "lake", "sand", "snow"]
const BIOME_NAMES := {"grass": "Meadow", "lake": "The Lake", "sand": "Desert", "snow": "Snowfield"}

const ALL := {
	# ---------------------------------------------------------------- grass
	"beetle": {"name": "Beetle", "biome": "grass", "role": "hybrid", "hp": 14, "dmg": 3, "speed": 26, "xp": 3,
		"look": {"shape": "segmented", "ramp": "green", "accent": "gold", "size": 6, "mouth": "mandibles", "eyes": "compound", "head": "antennae", "legs": "bug", "armor": "plating"}},
	"snail": {"name": "Snail", "biome": "grass", "role": "prey", "hp": 26, "dmg": 2, "speed": 12, "xp": 4, "armor": 2,
		"look": {"shape": "flat", "ramp": "sandy", "accent": "coral", "size": 6, "mouth": "sucker", "eyes": "stalks", "armor": "shell"}},
	"pilfermouse": {"name": "Pilfermouse", "biome": "grass", "role": "scavenger", "hp": 12, "dmg": 2, "speed": 54, "xp": 3,
		"look": {"shape": "round", "ramp": "grey", "accent": "pink", "size": 6, "mouth": "snout", "eyes": "cute", "head": "ears", "legs": "stubby", "tail": "long"}},
	"frog": {"name": "Hopper Frog", "biome": "grass", "role": "hybrid", "hp": 30, "dmg": 6, "speed": 34, "xp": 6, "swim": true,
		"look": {"shape": "round", "ramp": "green", "accent": "gold", "size": 8, "mouth": "none", "eyes": "big", "legs": "frog", "pattern": "spots"}},
	"fox": {"name": "Fox", "biome": "grass", "role": "predator", "hp": 60, "dmg": 10, "speed": 50, "xp": 12, "night": true,
		"look": {"shape": "long", "ramp": "orange", "accent": "sandy", "size": 10, "mouth": "snout", "eyes": "angry", "head": "ears", "legs": "long", "tail": "fluffy"}},
	"spineapple": {"name": "Spineapple", "biome": "grass", "role": "mimic", "hp": 34, "dmg": 8, "speed": 44, "xp": 8,
		"look": {"shape": "round", "ramp": "gold", "accent": "green", "size": 8, "mouth": "fangs", "eyes": "glow", "armor": "spines", "legs": "stubby", "head": "crest"}},
	"capybara": {"name": "Capybara", "biome": "grass", "role": "prey", "hp": 70, "dmg": 5, "speed": 22, "xp": 10, "swim": true,
		"look": {"shape": "round", "ramp": "brown", "accent": "sandy", "size": 12, "mouth": "snout", "eyes": "dots", "head": "ears", "legs": "stubby", "tail": "nub"}},
	# ---------------------------------------------------------------- lake
	"tadpole": {"name": "Tadpole", "biome": "lake", "role": "prey", "hp": 6, "dmg": 1, "speed": 30, "xp": 2, "swim": true, "fish": true, "water_only": true,
		"look": {"shape": "blob", "ramp": "night", "accent": "teal", "size": 4, "mouth": "sucker", "eyes": "dots", "tail": "fin"}},
	"minnow": {"name": "Minnow", "biome": "lake", "role": "prey", "hp": 14, "dmg": 2, "speed": 44, "xp": 4, "swim": true, "fish": true, "water_only": true,
		"look": {"shape": "long", "ramp": "blue", "accent": "snow", "size": 5, "mouth": "none", "eyes": "dots", "back": "fin", "tail": "fin", "pattern": "scales"}},
	"newt": {"name": "Newt", "biome": "lake", "role": "hybrid", "hp": 22, "dmg": 5, "speed": 36, "xp": 5, "swim": true,
		"look": {"shape": "long", "ramp": "orange", "accent": "red", "size": 6, "mouth": "none", "eyes": "dots", "legs": "stubby", "tail": "long", "pattern": "spots"}},
	"dragonfly": {"name": "Dragonfly", "biome": "lake", "role": "predator", "hp": 14, "dmg": 5, "speed": 64, "xp": 6, "fly": true,
		"look": {"shape": "segmented", "ramp": "teal", "accent": "blue", "size": 5, "mouth": "mandibles", "eyes": "compound", "back": "wings_bug", "tail": "whip"}},
	"pike": {"name": "Pike", "biome": "lake", "role": "predator", "hp": 70, "dmg": 12, "speed": 48, "xp": 14, "swim": true, "fish": true, "water_only": true,
		"look": {"shape": "long", "ramp": "moss", "accent": "green", "size": 12, "mouth": "fangs", "eyes": "angry", "back": "fin", "tail": "fin", "pattern": "scales"}},
	"heron": {"name": "Heron", "biome": "lake", "role": "predator", "hp": 90, "dmg": 14, "speed": 40, "xp": 18, "wade": true,
		"look": {"shape": "tall", "ramp": "grey", "accent": "snow", "size": 12, "mouth": "beak", "eyes": "dots", "head": "crest", "legs": "stilts", "tail": "feathers", "back": "wings_bird"}},
	# ---------------------------------------------------------------- sand
	"crab": {"name": "Crab", "biome": "sand", "role": "hybrid", "hp": 40, "dmg": 8, "speed": 30, "xp": 8, "armor": 3,
		"look": {"shape": "flat", "ramp": "red", "accent": "coral", "size": 8, "mouth": "pincers", "eyes": "stalks", "legs": "crab", "arms": "claws", "armor": "plating"}},
	"scarab": {"name": "Scarab", "biome": "sand", "role": "hybrid", "hp": 28, "dmg": 6, "speed": 30, "xp": 6, "armor": 2,
		"look": {"shape": "segmented", "ramp": "sandy", "accent": "brown", "size": 6, "mouth": "mandibles", "eyes": "compound", "head": "horns", "legs": "bug"}},
	"gull": {"name": "Gull", "biome": "sand", "role": "scavenger", "hp": 30, "dmg": 7, "speed": 58, "xp": 8, "fly": true,
		"look": {"shape": "round", "ramp": "snow", "accent": "grey", "size": 8, "mouth": "beak", "eyes": "angry", "back": "wings_bird", "legs": "stubby", "tail": "feathers"}},
	"tortoise": {"name": "Tortoise", "biome": "sand", "role": "prey", "hp": 90, "dmg": 6, "speed": 16, "xp": 12, "armor": 5,
		"look": {"shape": "flat", "ramp": "moss", "accent": "coral", "size": 9, "mouth": "snout", "eyes": "dots", "armor": "shell", "legs": "stubby", "tail": "nub"}},
	"scorpion": {"name": "Scorpion", "biome": "sand", "role": "predator", "hp": 44, "dmg": 11, "speed": 42, "xp": 11, "night": true,
		"look": {"shape": "segmented", "ramp": "coral", "accent": "purple", "size": 8, "mouth": "mandibles", "eyes": "dots", "legs": "crab", "arms": "claws", "tail": "stinger"}},
	# ---------------------------------------------------------------- snow
	"hare": {"name": "Snow Hare", "biome": "snow", "role": "prey", "hp": 18, "dmg": 3, "speed": 60, "xp": 5,
		"look": {"shape": "round", "ramp": "snow", "accent": "pink", "size": 6, "mouth": "snout", "eyes": "cute", "head": "ears", "legs": "long", "tail": "fluffy"}},
	"stoat": {"name": "Stoat", "biome": "snow", "role": "predator", "hp": 40, "dmg": 9, "speed": 58, "xp": 10, "night": true,
		"look": {"shape": "long", "ramp": "snow", "accent": "brown", "size": 8, "mouth": "snout", "eyes": "angry", "head": "ears", "legs": "stubby", "tail": "long"}},
	"ice_toad": {"name": "Ice Toad", "biome": "snow", "role": "hybrid", "hp": 50, "dmg": 8, "speed": 30, "xp": 10, "swim": true,
		"look": {"shape": "round", "ramp": "blue", "accent": "snow", "size": 9, "mouth": "none", "eyes": "big", "legs": "frog", "pattern": "spots"}},
	"seal": {"name": "Seal Pup", "biome": "snow", "role": "hybrid", "hp": 80, "dmg": 8, "speed": 30, "xp": 14, "swim": true, "fish": true,
		"look": {"shape": "long", "ramp": "grey", "accent": "snow", "size": 12, "mouth": "snout", "eyes": "cute", "tail": "fin", "pattern": "spots"}},
	"yeti_crab": {"name": "Yeti Crab", "biome": "snow", "role": "predator", "hp": 60, "dmg": 12, "speed": 36, "xp": 14, "armor": 3,
		"look": {"shape": "flat", "ramp": "snow", "accent": "coral", "size": 9, "mouth": "pincers", "eyes": "stalks", "legs": "crab", "arms": "claws", "pattern": "down"}},
	# ---------------------------------------------------------------- summoned
	"duckling": {"name": "Duckling", "biome": "any", "role": "predator", "hp": 22, "dmg": 5, "speed": 56, "xp": 4, "swim": true,
		"look": {"shape": "round", "ramp": "chick", "accent": "orange", "size": 5, "mouth": "bill", "eyes": "beady", "legs": "webbed", "tail": "nub", "pattern": "down"}},
	# ---------------------------------------------------------------- bosses (duck hybrids, like Crab's crab hybrids)
	"duckodile": {"name": "Duckodile", "biome": "any", "role": "boss", "hp": 900, "dmg": 12, "speed": 44, "xp": 60, "swim": true, "boss": true,
		"look": {"shape": "long", "ramp": "moss", "accent": "gold", "size": 19, "mouth": "bill", "eyes": "angry", "armor": "plating", "legs": "stubby", "tail": "long", "pattern": "scales"}},
	"quackaconda": {"name": "Quackaconda", "biome": "any", "role": "boss", "hp": 1000, "dmg": 11, "speed": 40, "xp": 60, "swim": true, "boss": true,
		"look": {"shape": "long", "ramp": "teal", "accent": "gold", "size": 18, "mouth": "bill", "eyes": "glow", "tail": "long", "pattern": "stripes", "head": "crest_duck"}},
	"mother_goose": {"name": "Mother Goose", "biome": "any", "role": "boss", "hp": 1100, "dmg": 12, "speed": 50, "xp": 70, "swim": true, "boss": true,
		"look": {"shape": "tall", "ramp": "snow", "accent": "orange", "size": 19, "mouth": "bill", "eyes": "angry", "back": "wings_bird", "legs": "webbed", "tail": "feathers"}},
	"shelldrake": {"name": "Shelldrake", "biome": "any", "role": "boss", "hp": 1400, "dmg": 14, "speed": 30, "xp": 80, "armor": 8, "swim": true, "boss": true,
		"look": {"shape": "flat", "ramp": "moss", "accent": "coral", "size": 20, "mouth": "bill", "eyes": "angry", "armor": "spines", "legs": "stubby", "tail": "curl", "head": "horns"}},
	"duckaroo": {"name": "Duckaroo", "biome": "any", "role": "boss", "hp": 1200, "dmg": 13, "speed": 52, "xp": 70, "boss": true,
		"look": {"shape": "tall", "ramp": "orange", "accent": "sandy", "size": 19, "mouth": "bill", "eyes": "angry", "head": "ears", "legs": "frog", "tail": "long", "arms": "claws"}},
	"great_mallard": {"name": "THE GREAT MALLARD", "biome": "any", "role": "boss", "hp": 3000, "dmg": 14, "speed": 44, "xp": 200, "swim": true, "boss": true,
		"look": {"shape": "duck", "ramp": "duck", "accent": "gold", "size": 27, "mouth": "bill", "eyes": "glow", "back": "wings_duck", "legs": "webbed", "tail": "curl", "pattern": "down", "head": "crest_duck"}},
}

## Spawn weights per biome: [species, weight, minute it starts showing up].
const SPAWNS := {
	"grass": [["beetle", 5, 0], ["snail", 3, 0], ["pilfermouse", 4, 0], ["frog", 3, 1], ["capybara", 2, 2], ["spineapple", 1, 2], ["fox", 2, 4]],
	"lake": [["tadpole", 6, 0], ["minnow", 5, 0], ["newt", 3, 0], ["dragonfly", 3, 1], ["pike", 2, 3], ["heron", 1, 6]],
	"sand": [["crab", 4, 0], ["scarab", 4, 0], ["gull", 3, 1], ["tortoise", 2, 2], ["scorpion", 2, 4]],
	"snow": [["hare", 5, 0], ["ice_toad", 3, 1], ["stoat", 3, 2], ["seal", 2, 3], ["yeti_crab", 2, 5]],
}

const BOSS_POOL := ["duckodile", "quackaconda", "mother_goose", "shelldrake", "duckaroo"]


static func get_def(id: String) -> Dictionary:
	return ALL.get(id, {})


## Which hand-drawn rig each species uses (bosses are drawn at 2x).
const RIG := {
	"beetle": "bug", "snail": "flat", "pilfermouse": "quad_s", "frog": "frog", "fox": "quad_l", "spineapple": "chunk",
	"capybara": "quad_l", "tadpole": "fish", "minnow": "fish", "newt": "quad_s", "dragonfly": "bug", "pike": "fish_l",
	"heron": "bird", "crab": "flat", "scarab": "bug", "gull": "bird", "tortoise": "flat", "scorpion": "bug",
	"hare": "quad_s", "stoat": "quad_s", "ice_toad": "frog", "seal": "fish_l", "yeti_crab": "flat", "duckling": "duckling",
	"duckodile": "fish_l", "quackaconda": "fish_l", "mother_goose": "bird", "shelldrake": "flat", "duckaroo": "quad_l",
	"great_mallard": "duck",
}


static func look_of(id: String) -> Dictionary:
	var lk := (get_def(id).get("look", {}) as Dictionary).duplicate()
	lk["body"] = RIG.get(id, "mochi")
	lk.erase("shape")
	if lk.has("head"):
		lk["crown"] = lk["head"]
		lk.erase("head")
	if lk.has("pattern"):
		lk["hide"] = lk["pattern"]
		lk.erase("pattern")
	if get_def(id).get("boss", false):
		lk["scale"] = 2
	return lk


static func pick(biome: String, minute: float, night: bool, rng: RandomNumberGenerator) -> String:
	var table: Array = SPAWNS.get(biome, SPAWNS["grass"])
	var total := 0.0
	for e in table:
		if minute >= float(e[2]):
			total += float(e[1]) * (2.0 if night and get_def(String(e[0])).get("night", false) else 1.0)
	var roll := rng.randf() * total
	for e in table:
		if minute >= float(e[2]):
			roll -= float(e[1]) * (2.0 if night and get_def(String(e[0])).get("night", false) else 1.0)
			if roll <= 0.0:
				return String(e[0])
	return String(table[0][0])
