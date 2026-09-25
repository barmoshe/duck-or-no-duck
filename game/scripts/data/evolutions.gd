class_name Evolutions
extends RefCounted
## Every evolution. type: passive | attack | ultimate | move | fruit (boss only).
## aff: predator | prey | gregarious | imposing | trickster | duck.
## rarity: 0 common, 1 rare, 2 epic, 3 legendary. max: how many ranks.
## stats: added per rank. look: body parts it shows. Duck parts also make you take
## +4% damage each but find better food (the Crab carcinisation trade, as anatification).

const RARITY_NAMES := ["Common", "Rare", "Epic", "Legendary"]
const RARITY_RAMP := ["grey", "blue", "purple", "gold"]
const AFFINITIES := ["predator", "prey", "gregarious", "imposing", "trickster", "duck"]
const AFF_NAMES := {"predator": "Predator", "prey": "Prey", "gregarious": "Gregarious", "imposing": "Imposing", "trickster": "Trickster", "duck": "Duck"}
const AFF_RAMP := {"predator": "red", "prey": "green", "gregarious": "pink", "imposing": "orange", "trickster": "purple", "duck": "gold"}
const TYPE_NAMES := {"passive": "Passive", "attack": "Attack", "ultimate": "Ultimate", "move": "Movement", "fruit": "Boss Fruit"}

const ALL := {
	# ------------------------------------------------------------ starters
	"headbutt": {"name": "Headbutt", "type": "attack", "aff": "imposing", "rarity": 0, "max": 5, "starter": true,
		"desc": "Bonk the nearest thing. Every blob starts here."},
	"scoot": {"name": "Scoot", "type": "move", "aff": "prey", "rarity": 0, "max": 1, "starter": true,
		"desc": "A quick wiggle-dash."},
	# ------------------------------------------------------------ attacks
	"tail_whip": {"name": "Tail Whip", "type": "attack", "aff": "imposing", "rarity": 0, "max": 5, "look": {"tail": "whip"},
		"desc": "Spin and smack everything around you. Knocks back."},
	"spit": {"name": "Spit", "type": "attack", "aff": "trickster", "rarity": 0, "max": 5,
		"desc": "Spit a glob at range. Scales with Ability."},
	"charge": {"name": "Charge", "type": "attack", "aff": "imposing", "rarity": 1, "max": 5, "look": {"head": "horns"},
		"desc": "Lunge into a target for heavy Physical damage."},
	"jaws": {"name": "Jaws", "type": "attack", "aff": "predator", "rarity": 0, "max": 5, "look": {"mouth": "fangs"},
		"desc": "A real bite. Hits harder than a headbutt."},
	"stinger": {"name": "Stinger", "type": "attack", "aff": "trickster", "rarity": 1, "max": 5, "look": {"tail": "stinger"},
		"desc": "Fire a dart that poisons."},
	"peck_flurry": {"name": "Peck Flurry", "type": "attack", "aff": "predator", "rarity": 1, "max": 5, "look": {"mouth": "beak"},
		"desc": "Three fast pecks."},
	"egg_toss": {"name": "Egg Toss", "type": "attack", "aff": "gregarious", "rarity": 1, "max": 5,
		"desc": "Lob an egg that bursts in an area."},
	"mud_splash": {"name": "Mud Splash", "type": "attack", "aff": "prey", "rarity": 0, "max": 5,
		"desc": "Splash mud around you: damage and slow."},
	"pincer_snap": {"name": "Pincer Snap", "type": "attack", "aff": "predator", "rarity": 2, "max": 5, "look": {"arms": "claws"},
		"desc": "Huge snap that makes targets bleed. Wrong game, still great."},
	"charm_song": {"name": "Charm Song", "type": "attack", "aff": "gregarious", "rarity": 1, "max": 5, "look": {"head": "frill"},
		"desc": "Sing to a weakened animal: it joins you as an ally."},
	"quack": {"name": "Quack", "type": "attack", "aff": "duck", "rarity": 1, "max": 5, "look": {"mouth": "bill"},
		"desc": "A cone of QUACK. Damages and stuns."},
	"feather_darts": {"name": "Feather Darts", "type": "attack", "aff": "duck", "rarity": 2, "max": 5, "look": {"back": "wings_duck"},
		"desc": "Fire a spread of sharp feathers."},
	# ------------------------------------------------------------ ultimates
	"mega_quack": {"name": "Mega Quack", "type": "ultimate", "aff": "duck", "rarity": 2, "max": 3, "look": {"mouth": "bill"},
		"desc": "A screen-shaking QUACK: big damage, long stun."},
	"body_slam": {"name": "Body Slam", "type": "ultimate", "aff": "imposing", "rarity": 1, "max": 3,
		"desc": "Jump and crash down. Bigger you = bigger slam."},
	"duck_dive": {"name": "Duck Dive", "type": "ultimate", "aff": "duck", "rarity": 2, "max": 3,
		"desc": "Dive under: untouchable, then burst up in a splash."},
	"hibernate": {"name": "Hibernate", "type": "ultimate", "aff": "prey", "rarity": 1, "max": 3,
		"desc": "Curl up: heal a lot and harden for a moment."},
	"duckling_parade": {"name": "Duckling Parade", "type": "ultimate", "aff": "gregarious", "rarity": 2, "max": 3,
		"desc": "Call a line of ducklings to fight for you."},
	"molt_storm": {"name": "Molt Storm", "type": "ultimate", "aff": "trickster", "rarity": 2, "max": 3, "look": {"pattern": "feathers"},
		"desc": "Shed a whirling storm of feathers around you."},
	# ------------------------------------------------------------ movement
	"leap": {"name": "Leap", "type": "move", "aff": "predator", "rarity": 0, "max": 1, "look": {"legs": "frog"},
		"desc": "A long jump over anything."},
	"paddle": {"name": "Paddle", "type": "move", "aff": "duck", "rarity": 1, "max": 1, "look": {"legs": "webbed"},
		"desc": "Short, fast dash with a tiny cooldown. Faster in water."},
	"burrow": {"name": "Burrow", "type": "move", "aff": "prey", "rarity": 1, "max": 1, "look": {"mouth": "snout"},
		"desc": "Dig under and pop out. Untouchable while under."},
	"glide": {"name": "Glide", "type": "move", "aff": "duck", "rarity": 2, "max": 1, "look": {"back": "wings_duck"},
		"desc": "Flap and glide far. Untouchable in the air."},
	# ------------------------------------------------------------ predator
	"sharp_teeth": {"name": "Sharp Teeth", "type": "passive", "aff": "predator", "rarity": 0, "max": 3, "look": {"mouth": "fangs"},
		"stats": {"physical": 3.0}, "desc": "+3 Physical."},
	"hunter_eyes": {"name": "Hunter Eyes", "type": "passive", "aff": "predator", "rarity": 0, "max": 3, "look": {"eyes": "angry"},
		"stats": {"crit": 7.0}, "desc": "+7% critical chance."},
	"lean_muscle": {"name": "Lean Muscle", "type": "passive", "aff": "predator", "rarity": 0, "max": 3, "look": {"legs": "long"},
		"stats": {"physical": 2.0, "speed": 0.6}, "desc": "+2 Physical, +0.6 Speed."},
	"bloodlust": {"name": "Bloodlust", "type": "passive", "aff": "predator", "rarity": 1, "max": 3, "look": {"pattern": "stripes"},
		"stats": {"heal_kill": 3.0}, "desc": "Heal 3 HP for every kill."},
	"killer_instinct": {"name": "Killer Instinct", "type": "passive", "aff": "predator", "rarity": 2, "max": 2, "look": {"eyes": "glow"},
		"stats": {"execute": 30.0}, "desc": "+30% damage to targets under half HP."},
	"carnivore": {"name": "Carnivore", "type": "passive", "aff": "predator", "rarity": 0, "max": 3,
		"stats": {"meat_xp": 30.0}, "desc": "Meat gives +30% XP."},
	"piscivore": {"name": "Piscivore", "type": "passive", "aff": "predator", "rarity": 0, "max": 3,
		"stats": {"fish_xp": 50.0, "swim": 0.34}, "desc": "Fish give +50% XP. Better at swimming."},
	"night_vision": {"name": "Night Vision", "type": "passive", "aff": "predator", "rarity": 1, "max": 2, "look": {"eyes": "glow"},
		"stats": {"vision": 60.0, "crit": 3.0}, "desc": "See much further at night. +3% crit."},
	# ------------------------------------------------------------ prey
	"skittish": {"name": "Skittish", "type": "passive", "aff": "prey", "rarity": 0, "max": 3, "look": {"head": "ears"},
		"stats": {"evasion": 6.0}, "desc": "+6% chance to dodge a hit."},
	"long_legs": {"name": "Long Legs", "type": "passive", "aff": "prey", "rarity": 0, "max": 3, "look": {"legs": "long"},
		"stats": {"speed": 1.2}, "desc": "+1.2 Speed."},
	"efficient_gut": {"name": "Efficient Gut", "type": "passive", "aff": "prey", "rarity": 0, "max": 3,
		"stats": {"xp": 15.0}, "desc": "+15% XP from food."},
	"keen_nose": {"name": "Keen Nose", "type": "passive", "aff": "prey", "rarity": 0, "max": 3, "look": {"mouth": "snout"},
		"stats": {"magnet": 14.0}, "desc": "Food flies to you from further away."},
	"camouflage": {"name": "Camouflage", "type": "passive", "aff": "prey", "rarity": 1, "max": 2, "look": {"pattern": "spots"},
		"stats": {"stealth": 30.0, "evasion": 4.0}, "desc": "Predators notice you 30% later. +4% dodge."},
	"playing_dead": {"name": "Playing Dead", "type": "passive", "aff": "prey", "rarity": 2, "max": 1,
		"stats": {"revive": 1.0}, "desc": "Once per run, survive a killing blow with 40% HP."},
	"herbivore": {"name": "Herbivore", "type": "passive", "aff": "prey", "rarity": 0, "max": 3,
		"stats": {"fruit_xp": 40.0, "fruit_heal": 2.0}, "desc": "Fruit gives +40% XP and heals 2."},
	"scavenger": {"name": "Scavenger", "type": "passive", "aff": "prey", "rarity": 0, "max": 3, "look": {"mouth": "beak"},
		"stats": {"scav_xp": 60.0, "magnet": 6.0}, "desc": "+60% XP from animals killed by others."},
	"more_eyes": {"name": "More Eyes", "type": "passive", "aff": "prey", "rarity": 1, "max": 2, "look": {"eyes": "compound"},
		"stats": {"vision": 30.0, "identify": 1.0, "crit": 3.0}, "desc": "Tell good mushrooms from bad. See further at night."},
	# ------------------------------------------------------------ gregarious
	"pheromones": {"name": "Pheromones", "type": "passive", "aff": "gregarious", "rarity": 0, "max": 3, "look": {"head": "antennae"},
		"stats": {"social": 3.0}, "desc": "+3 Social: stronger, more allies."},
	"bright_colors": {"name": "Bright Colors", "type": "passive", "aff": "gregarious", "rarity": 0, "max": 3, "look": {"pattern": "spots"},
		"stats": {"ally_dmg": 25.0}, "desc": "Allies deal +25% damage."},
	"pack_call": {"name": "Pack Call", "type": "passive", "aff": "gregarious", "rarity": 1, "max": 2,
		"stats": {"ally_cap": 1.0, "social": 1.0}, "desc": "+1 ally slot."},
	"soothing_hum": {"name": "Soothing Hum", "type": "passive", "aff": "gregarious", "rarity": 1, "max": 3,
		"stats": {"regen": 0.5, "ally_regen": 1.0}, "desc": "You and your allies regenerate."},
	"herd_instinct": {"name": "Herd Instinct", "type": "passive", "aff": "gregarious", "rarity": 2, "max": 2,
		"stats": {"herd": 1.0}, "desc": "+1 Armor for each ally near you."},
	# ------------------------------------------------------------ imposing
	"thick_hide": {"name": "Thick Hide", "type": "passive", "aff": "imposing", "rarity": 0, "max": 3, "look": {"pattern": "scales"},
		"stats": {"max_hp": 20.0}, "desc": "+20 Max HP."},
	"big_bones": {"name": "Big Bones", "type": "passive", "aff": "imposing", "rarity": 0, "max": 3,
		"stats": {"size": 15.0, "max_hp": 12.0, "speed": -0.3}, "desc": "+15% Size, +12 HP. Heavier."},
	"horns": {"name": "Horns", "type": "passive", "aff": "imposing", "rarity": 1, "max": 3, "look": {"head": "horns"},
		"stats": {"physical": 3.0, "ram": 40.0}, "desc": "+3 Physical. Touching animals hurts them."},
	"shell": {"name": "Shell", "type": "passive", "aff": "imposing", "rarity": 1, "max": 3, "look": {"armor": "shell"},
		"stats": {"armor": 3.0, "speed": -0.2}, "desc": "+3 Armor."},
	"spines": {"name": "Spines", "type": "passive", "aff": "imposing", "rarity": 1, "max": 3, "look": {"armor": "spines"},
		"stats": {"thorns": 35.0}, "desc": "Biters take 35% of the damage back."},
	"plating": {"name": "Plating", "type": "passive", "aff": "imposing", "rarity": 0, "max": 3, "look": {"armor": "plating"},
		"stats": {"armor": 2.0, "max_hp": 8.0}, "desc": "+2 Armor, +8 HP."},
	"colossal": {"name": "Colossal", "type": "passive", "aff": "imposing", "rarity": 2, "max": 1,
		"stats": {"size": 35.0, "max_hp": 40.0, "physical": 4.0}, "desc": "+35% Size, +40 HP, +4 Physical."},
	# ------------------------------------------------------------ trickster
	"quick_wit": {"name": "Quick Wit", "type": "passive", "aff": "trickster", "rarity": 0, "max": 3, "look": {"head": "antennae"},
		"stats": {"cdr": 8.0}, "desc": "Cooldowns 8% faster."},
	"venom_glands": {"name": "Venom Glands", "type": "passive", "aff": "trickster", "rarity": 1, "max": 3, "look": {"pattern": "toxic"},
		"stats": {"poison": 3.0}, "desc": "Every hit poisons (3 damage/s)."},
	"echo": {"name": "Echo", "type": "passive", "aff": "trickster", "rarity": 1, "max": 3,
		"stats": {"echo": 15.0}, "desc": "Attacks have a 15% chance to repeat."},
	"mutant_luck": {"name": "Mutant Luck", "type": "passive", "aff": "trickster", "rarity": 1, "max": 3, "look": {"eyes": "compound"},
		"stats": {"luck": 2.0}, "desc": "Better food, more Mutagen."},
	"big_brain": {"name": "Big Brain", "type": "passive", "aff": "trickster", "rarity": 0, "max": 3,
		"stats": {"ability": 3.0}, "desc": "+3 Ability."},
	# ------------------------------------------------------------ duck (anatification)
	"duck_bill": {"name": "Duck Bill", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"mouth": "bill"},
		"stats": {"food": 25.0, "ability": 2.0}, "desc": "Food is worth 25% more. +2 Ability."},
	"webbed_feet": {"name": "Webbed Feet", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"legs": "webbed"},
		"stats": {"swim": 1.0, "speed": 0.6}, "desc": "Swim at full speed (and faster). +0.6 Speed."},
	"down_feathers": {"name": "Down Feathers", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"pattern": "down"},
		"stats": {"max_hp": 20.0, "regen": 0.6}, "desc": "+20 HP and warm regeneration."},
	"duck_wings": {"name": "Duck Wings", "type": "passive", "aff": "duck", "rarity": 1, "max": 1, "duck_part": true, "look": {"back": "wings_duck"},
		"stats": {"speed": 0.8, "evasion": 5.0}, "desc": "+0.8 Speed, +5% dodge."},
	"tail_curl": {"name": "Tail Curl", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"tail": "curl"},
		"stats": {"luck": 2.0, "speed": 0.4}, "desc": "The drake's curl. Luckier food."},
	"beady_eyes": {"name": "Beady Eyes", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"eyes": "beady"},
		"stats": {"area": 15.0, "magnet": 8.0}, "desc": "+15% attack range and area."},
	"green_crest": {"name": "Green Crest", "type": "passive", "aff": "duck", "rarity": 1, "max": 1, "duck_part": true, "look": {"head": "crest_duck"},
		"stats": {"ability": 3.0, "social": 3.0}, "desc": "The mallard hood. +3 Ability, +3 Social."},
	"convergent": {"name": "Convergent Evolution", "type": "passive", "aff": "duck", "rarity": 3, "max": 1, "duck_part": true, "needs_ducks": 5,
		"look": {"shape": "duck"}, "stats": {"all": 20.0}, "grants": "mega_quack",
		"desc": "Become a Mallard. All stats +20%. Learn Mega Quack."},
	# ------------------------------------------------------------ boss fruits
	"swan_neck": {"name": "Swan Neck", "type": "fruit", "aff": "duck", "rarity": 3, "max": 1, "look": {"shape": "tall"},
		"stats": {"area": 50.0}, "desc": "Attack range and area +50%."},
	"goose_temper": {"name": "Goose Temper", "type": "fruit", "aff": "predator", "rarity": 3, "max": 1, "look": {"eyes": "angry"},
		"stats": {"temper": 40.0, "physical": 4.0}, "desc": "+40% damage while under half HP. +4 Physical."},
	"turtle_shell": {"name": "Turtle Shell", "type": "fruit", "aff": "imposing", "rarity": 3, "max": 1, "look": {"armor": "shell"},
		"stats": {"armor": 8.0, "max_hp": 30.0}, "desc": "+8 Armor, +30 HP."},
	"heron_stilts": {"name": "Heron Stilts", "type": "fruit", "aff": "prey", "rarity": 3, "max": 1, "look": {"legs": "stilts"},
		"stats": {"speed": 2.0, "swim": 1.0}, "desc": "+2 Speed. Wade through water freely."},
	"pike_jaw": {"name": "Pike Jaw", "type": "fruit", "aff": "predator", "rarity": 3, "max": 1, "look": {"mouth": "fangs"},
		"stats": {"physical": 8.0, "crit": 10.0}, "desc": "+8 Physical, +10% critical chance."},
}

## What each duck part looks like on the body (the full mallard, slot by slot).
const DUCK_LOOK := {
	"mouth": "bill", "eyes": "beady", "legs": "webbed", "pattern": "down", "tail": "curl",
	"back": "wings_duck", "head": "crest_duck", "shape": "duck",
}

const DUCK_PARTS := ["duck_bill", "webbed_feet", "down_feathers", "duck_wings", "tail_curl", "beady_eyes", "green_crest", "convergent"]


static func get_def(id: String) -> Dictionary:
	return ALL.get(id, {})


## One-line stat summary for a card ("+3 Physical").
static func stat_line(id: String) -> String:
	var d := get_def(id)
	return String(d.get("desc", ""))
