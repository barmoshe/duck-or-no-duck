class_name Evolutions
extends RefCounted
## Every evolution. type: passive | attack | ultimate | move | branch (Boss Fruit only).
## aff: predator | prey | gregarious | imposing | trickster | duck.
## rarity: the base rarity (0 common, 1 rare, 2 epic, 3 legendary; branches are 4).
##   A card's rarity rises with the level it offers: +1 at level 3, +1 at level 5.
## max: how many levels (1-5). stats: added per level. look: body parts it shows.
## locked: only offered once something unlocks it. unlocks: {level: [ids]} opened by
##   holding this evolution at that level. excludes: bans, both ways.
## Duck parts make you take +4% damage each but find better food (anatification).

const RARITY_NAMES := ["Common", "Rare", "Epic", "Legendary", "Branching"]
const RARITY_RAMP := ["green", "blue", "purple", "gold", "red"]
const AFFINITIES := ["predator", "prey", "gregarious", "imposing", "trickster", "duck"]
const AFF_NAMES := {"predator": "Predator", "prey": "Prey", "gregarious": "Gregarious", "imposing": "Imposing", "trickster": "Trickster", "duck": "Duck"}
const AFF_RAMP := {"predator": "red", "prey": "green", "gregarious": "pink", "imposing": "orange", "trickster": "purple", "duck": "gold"}
const TYPE_NAMES := {"passive": "Passive", "attack": "Attack", "ultimate": "Ultimate", "move": "Movement", "branch": "Branching"}

const ALL := {
	# ------------------------------------------------------------ starters
	"gulp": {"name": "Gulp", "type": "attack", "aff": "predator", "rarity": 0, "max": 5, "starter": true,
		"desc": "Lunge and gulp the nearest thing. A kill heals you a little. Every blob starts here."},
	"headbutt": {"name": "Headbutt", "type": "attack", "aff": "imposing", "rarity": 0, "max": 5,
		"desc": "Bonk hard and knock things back."},
	"scoot": {"name": "Scoot", "type": "move", "aff": "prey", "rarity": 0, "max": 1, "starter": true,
		"desc": "A quick wiggle-dash."},
	# ------------------------------------------------------------ attacks
	"tail_whip": {"name": "Tail Whip", "type": "attack", "aff": "imposing", "rarity": 0, "max": 5, "look": {"tail": "whip"},
		"desc": "Spin and smack everything around you. Knocks back."},
	"spit": {"name": "Spit", "type": "attack", "aff": "trickster", "rarity": 0, "max": 5, "unlocks": {3: ["venom_glands"]},
		"desc": "Spit a glob at range. Scales with Ability."},
	"charge": {"name": "Charge", "type": "attack", "aff": "imposing", "rarity": 1, "max": 5, "look": {"head": "horns"},
		"desc": "Lunge into a target for heavy Physical damage."},
	"jaws": {"name": "Jaws", "type": "attack", "aff": "predator", "rarity": 0, "max": 5, "unlocks": {3: ["bloodlust"]}, "look": {"mouth": "fangs"},
		"desc": "A real bite. Hits harder than a headbutt."},
	"stinger": {"name": "Stinger", "type": "attack", "aff": "trickster", "rarity": 1, "max": 5, "unlocks": {2: ["venom_glands"]}, "look": {"tail": "stinger"},
		"desc": "Fire a dart that poisons."},
	"peck_flurry": {"name": "Peck Flurry", "type": "attack", "aff": "predator", "rarity": 1, "max": 5, "look": {"mouth": "beak"},
		"desc": "Three fast pecks."},
	"egg_toss": {"name": "Egg Toss", "type": "attack", "aff": "gregarious", "rarity": 1, "max": 5,
		"desc": "Lob an egg that bursts in an area."},
	"mud_splash": {"name": "Mud Splash", "type": "attack", "aff": "prey", "rarity": 0, "max": 5,
		"desc": "Splash mud around you: damage and slow."},
	"pincer_snap": {"name": "Pincer Snap", "type": "attack", "aff": "predator", "rarity": 2, "max": 5, "locked": true, "look": {"arms": "claws"},
		"desc": "Huge snap that makes targets bleed. Wrong game, still great."},
	"charm_song": {"name": "Charm Song", "type": "attack", "aff": "gregarious", "rarity": 1, "max": 5, "unlocks": {2: ["pack_call"]}, "look": {"head": "frill"},
		"desc": "Sing to a weakened animal: it joins you as an ally."},
	"quack": {"name": "Quack", "type": "attack", "aff": "duck", "rarity": 1, "max": 5, "locked": true, "look": {"mouth": "bill"},
		"desc": "A cone of QUACK. Damages and stuns."},
	"feather_darts": {"name": "Feather Darts", "type": "attack", "aff": "duck", "rarity": 2, "max": 5, "locked": true, "look": {"back": "wings_duck"},
		"desc": "Fire a spread of sharp feathers."},
	# ------------------------------------------------------------ ultimates
	"mega_quack": {"name": "Mega Quack", "type": "ultimate", "aff": "duck", "rarity": 2, "max": 3, "locked": true, "look": {"mouth": "bill"},
		"desc": "A screen-shaking QUACK: big damage, long stun."},
	"body_slam": {"name": "Body Slam", "type": "ultimate", "aff": "imposing", "rarity": 1, "max": 3,
		"desc": "Jump and crash down. Bigger you = bigger slam."},
	"duck_dive": {"name": "Duck Dive", "type": "ultimate", "aff": "duck", "rarity": 2, "max": 3, "locked": true,
		"desc": "Dive under: untouchable, then burst up in a splash."},
	"hibernate": {"name": "Hibernate", "type": "ultimate", "aff": "prey", "rarity": 1, "max": 3,
		"desc": "Curl up: heal a lot and harden for a moment."},
	"duckling_parade": {"name": "Duckling Parade", "type": "ultimate", "aff": "gregarious", "rarity": 2, "max": 3, "locked": true,
		"desc": "Call a line of ducklings to fight for you."},
	"molt_storm": {"name": "Molt Storm", "type": "ultimate", "aff": "trickster", "rarity": 2, "max": 3, "look": {"pattern": "feathers"},
		"desc": "Shed a whirling storm of feathers around you."},
	# ------------------------------------------------------------ movement
	"leap": {"name": "Leap", "type": "move", "aff": "predator", "rarity": 0, "max": 1, "look": {"legs": "frog"},
		"desc": "A long jump over anything."},
	"paddle": {"name": "Paddle", "type": "move", "aff": "duck", "rarity": 1, "max": 1, "locked": true, "look": {"legs": "webbed"},
		"desc": "Short, fast dash with a tiny cooldown. Faster in water."},
	"burrow": {"name": "Burrow", "type": "move", "aff": "prey", "rarity": 1, "max": 1, "look": {"mouth": "snout"},
		"desc": "Dig under and pop out. Untouchable while under."},
	"glide": {"name": "Glide", "type": "move", "aff": "duck", "rarity": 2, "max": 1, "locked": true, "look": {"back": "wings_duck"},
		"desc": "Flap and glide far. Untouchable in the air."},
	# ------------------------------------------------------------ predator
	"sharp_teeth": {"name": "Sharp Teeth", "type": "passive", "aff": "predator", "rarity": 0, "max": 5, "unlocks": {3: ["pincer_snap"]}, "look": {"mouth": "fangs"},
		"stats": {"physical": 3.0}, "desc": "+3 Physical."},
	"hunter_eyes": {"name": "Hunter Eyes", "type": "passive", "aff": "predator", "rarity": 0, "max": 5, "look": {"eyes": "angry"},
		"stats": {"crit": 7.0}, "desc": "+7% critical chance."},
	"lean_muscle": {"name": "Lean Muscle", "type": "passive", "aff": "predator", "rarity": 0, "max": 5, "look": {"legs": "long"},
		"stats": {"physical": 2.0, "speed": 0.6}, "desc": "+2 Physical, +0.6 Speed."},
	"bloodlust": {"name": "Bloodlust", "type": "passive", "aff": "predator", "rarity": 1, "max": 5, "locked": true, "look": {"pattern": "stripes"},
		"stats": {"heal_kill": 3.0}, "desc": "Heal 3 HP for every kill."},
	"killer_instinct": {"name": "Killer Instinct", "type": "passive", "aff": "predator", "rarity": 2, "max": 3, "locked": true, "look": {"eyes": "glow"},
		"stats": {"execute": 30.0}, "desc": "+30% damage to targets under half HP."},
	"carnivore": {"name": "Carnivore", "type": "passive", "aff": "predator", "rarity": 0, "max": 5, "unlocks": {2: ["killer_instinct"]}, "excludes": ["vegan"],
		"stats": {"meat_xp": 30.0}, "desc": "Meat gives +30% XP."},
	"piscivore": {"name": "Piscivore", "type": "passive", "aff": "predator", "rarity": 0, "max": 5, "excludes": ["vegan"],
		"stats": {"fish_xp": 50.0, "swim": 0.34}, "desc": "Fish give +50% XP. Better at swimming."},
	"night_vision": {"name": "Night Vision", "type": "passive", "aff": "predator", "rarity": 1, "max": 3, "look": {"eyes": "glow"},
		"stats": {"vision": 60.0, "crit": 3.0}, "desc": "See much further at night. +3% crit."},
	# ------------------------------------------------------------ prey
	"skittish": {"name": "Skittish", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "look": {"head": "ears"},
		"stats": {"evasion": 6.0}, "desc": "+6% chance to dodge a hit."},
	"long_legs": {"name": "Long Legs", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "look": {"legs": "long"},
		"stats": {"speed": 1.2}, "desc": "+1.2 Speed."},
	"efficient_gut": {"name": "Efficient Gut", "type": "passive", "aff": "prey", "rarity": 0, "max": 5,
		"stats": {"xp": 15.0}, "desc": "+15% XP from food."},
	"keen_nose": {"name": "Keen Nose", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "look": {"mouth": "snout"},
		"stats": {"magnet": 6.0, "feed": 20.0}, "desc": "Reach food from further away. Feeding Speed +20%."},
	"camouflage": {"name": "Camouflage", "type": "passive", "aff": "prey", "rarity": 1, "max": 3, "look": {"pattern": "spots"},
		"stats": {"stealth": 30.0, "evasion": 4.0}, "desc": "Predators notice you 30% later. +4% dodge."},
	"playing_dead": {"name": "Playing Dead", "type": "passive", "aff": "prey", "rarity": 2, "max": 1,
		"stats": {"revive": 1.0}, "desc": "Once per run, survive a killing blow with 40% HP."},
	"herbivore": {"name": "Herbivore", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "unlocks": {2: ["vegan"]},
		"stats": {"fruit_xp": 40.0, "fruit_heal": 2.0}, "desc": "Fruit gives +40% XP and heals 2. Bump trees to shake fruit loose."},
	"cheek_pouch": {"name": "Cheek Pouch", "type": "passive", "aff": "prey", "rarity": 0, "max": 3, "look": {"cheeks": "pouch"},
		"stats": {"pouch": 2.0}, "desc": "Store food from further away inside your cheeks. Stored food is bitten along with the rest, even on the move."},
	"saliva": {"name": "Saliva", "type": "passive", "aff": "prey", "rarity": 0, "max": 5,
		"stats": {"feed": 25.0}, "desc": "Bite faster. Feeding Speed +25%."},
	"food_sense": {"name": "Food Sense", "type": "passive", "aff": "prey", "rarity": 1, "max": 3,
		"stats": {"forage": 50.0}, "desc": "More food sparkles: +50% chance a piece heals you with every bite."},
	"hump": {"name": "Hump", "type": "passive", "aff": "imposing", "rarity": 2, "max": 3,
		"stats": {"hump": 1.0}, "desc": "A bite of sparkling food at full health raises your Max HP by 1 for good."},
	"scavenger": {"name": "Carrion", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "look": {"mouth": "beak"}, "excludes": ["vegan"],
		"stats": {"scav_xp": 50.0, "feed": 15.0}, "desc": "Food from animals not killed by you grants +50% Progress. Feeding Speed +15%."},
	"vegan": {"name": "Vegan", "type": "passive", "aff": "prey", "rarity": 2, "max": 1, "locked": true,
		"excludes": ["carnivore", "piscivore", "scavenger", "omnivore"],
		"stats": {"vegan": 1.0}, "desc": "Fruit gives +150% XP and heals 4. You can't eat meat or fish."},
	"omnivore": {"name": "Omnivore", "type": "passive", "aff": "prey", "rarity": 1, "max": 3, "excludes": ["vegan"],
		"stats": {"omni": 1.0}, "desc": "+12% XP from all food. Food lasts 25% longer on the ground."},
	"more_eyes": {"name": "More Eyes", "type": "passive", "aff": "prey", "rarity": 1, "max": 3, "look": {"eyes": "compound"},
		"stats": {"vision": 30.0, "identify": 1.0, "crit": 3.0, "shroom_xp": 50.0}, "desc": "Name mushrooms on sight more often (+1 Senses), and they give +50% Progress. See further at night."},
	# ------------------------------------------------------------ gregarious
	"pheromones": {"name": "Pheromones", "type": "passive", "aff": "gregarious", "rarity": 0, "max": 5, "unlocks": {2: ["pack_call"]}, "look": {"head": "antennae"},
		"stats": {"social": 3.0}, "desc": "+3 Social: stronger, more allies."},
	"bright_colors": {"name": "Bright Colors", "type": "passive", "aff": "gregarious", "rarity": 0, "max": 5, "look": {"pattern": "spots"},
		"stats": {"ally_dmg": 25.0}, "desc": "Allies deal +25% damage."},
	"pack_call": {"name": "Pack Call", "type": "passive", "aff": "gregarious", "rarity": 1, "max": 3, "unlocks": {2: ["herd_instinct"]}, "locked": true,
		"stats": {"ally_cap": 1.0, "social": 1.0}, "desc": "+1 ally slot."},
	"soothing_hum": {"name": "Soothing Hum", "type": "passive", "aff": "gregarious", "rarity": 1, "max": 5,
		"stats": {"regen": 0.5, "ally_regen": 1.0}, "desc": "You and your allies regenerate."},
	"herd_instinct": {"name": "Herd Instinct", "type": "passive", "aff": "gregarious", "rarity": 2, "max": 3, "locked": true,
		"stats": {"herd": 1.0}, "desc": "+1 Armor for each ally near you."},
	# ------------------------------------------------------------ imposing
	"thick_hide": {"name": "Thick Hide", "type": "passive", "aff": "imposing", "rarity": 0, "max": 5, "unlocks": {3: ["colossal"]}, "look": {"pattern": "scales"},
		"stats": {"max_hp": 20.0}, "desc": "+20 Max HP."},
	"big_bones": {"name": "Big Bones", "type": "passive", "aff": "imposing", "rarity": 0, "max": 5, "unlocks": {2: ["colossal"]},
		"stats": {"size": 15.0, "max_hp": 12.0, "speed": -0.3}, "desc": "+15% Size, +12 HP. Heavier."},
	"horns": {"name": "Horns", "type": "passive", "aff": "imposing", "rarity": 1, "max": 5, "look": {"head": "horns"},
		"stats": {"physical": 3.0, "ram": 40.0}, "desc": "+3 Physical. Touching animals hurts them."},
	"shell": {"name": "Shell", "type": "passive", "aff": "imposing", "rarity": 1, "max": 5, "unlocks": {3: ["carapace"]}, "look": {"armor": "shell"},
		"stats": {"armor": 3.0, "speed": -0.2}, "desc": "+3 Armor."},
	"spines": {"name": "Spines", "type": "passive", "aff": "imposing", "rarity": 1, "max": 5, "look": {"armor": "spines"},
		"stats": {"thorns": 35.0}, "desc": "Biters take 35% of the damage back."},
	"plating": {"name": "Plating", "type": "passive", "aff": "imposing", "rarity": 0, "max": 5, "look": {"armor": "plating"},
		"stats": {"armor": 2.0, "max_hp": 8.0}, "desc": "+2 Armor, +8 HP."},
	"colossal": {"name": "Colossal", "type": "passive", "aff": "imposing", "rarity": 2, "max": 1, "locked": true,
		"stats": {"size": 35.0, "max_hp": 40.0, "physical": 4.0}, "desc": "+35% Size, +40 HP, +4 Physical."},
	# ------------------------------------------------------------ trickster
	"quick_wit": {"name": "Quick Wit", "type": "passive", "aff": "trickster", "rarity": 0, "max": 5, "unlocks": {2: ["echo"]}, "look": {"head": "antennae"},
		"stats": {"cdr": 8.0}, "desc": "Cooldowns 8% faster."},
	"venom_glands": {"name": "Venom Glands", "type": "passive", "aff": "trickster", "rarity": 1, "max": 5, "locked": true, "look": {"pattern": "toxic"},
		"stats": {"poison": 3.0}, "desc": "Every hit poisons (3 damage/s)."},
	"echo": {"name": "Echo", "type": "passive", "aff": "trickster", "rarity": 1, "max": 5, "locked": true,
		"stats": {"echo": 15.0}, "desc": "Attacks have a 15% chance to repeat."},
	"mutant_luck": {"name": "Mutant Luck", "type": "passive", "aff": "trickster", "rarity": 1, "max": 5, "look": {"eyes": "compound"},
		"stats": {"luck": 2.0}, "desc": "Better food, more Mutagen."},
	"big_brain": {"name": "Big Brain", "type": "passive", "aff": "trickster", "rarity": 0, "max": 5,
		"stats": {"ability": 3.0}, "desc": "+3 Ability."},
	# ------------------------------------------------------------ duck (anatification)
	"duck_bill": {"name": "Duck Bill", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "unlocks": {1: ["quack", "mega_quack"]}, "duck_part": true, "look": {"mouth": "bill"},
		"stats": {"food": 25.0, "ability": 2.0}, "desc": "Food is worth 25% more. +2 Ability."},
	"webbed_feet": {"name": "Webbed Feet", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "unlocks": {1: ["paddle", "duck_dive"]}, "duck_part": true, "look": {"legs": "webbed"},
		"stats": {"swim": 1.0, "speed": 0.6}, "desc": "Swim at full speed (and faster). +0.6 Speed."},
	"down_feathers": {"name": "Down Feathers", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"pattern": "down"},
		"stats": {"max_hp": 20.0, "regen": 0.6}, "desc": "+20 HP and warm regeneration."},
	"duck_wings": {"name": "Duck Wings", "type": "passive", "aff": "duck", "rarity": 1, "max": 1, "unlocks": {1: ["glide", "feather_darts"]}, "duck_part": true, "look": {"back": "wings_duck"},
		"stats": {"speed": 0.8, "evasion": 5.0}, "desc": "+0.8 Speed, +5% dodge."},
	"tail_curl": {"name": "Tail Curl", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"tail": "curl"},
		"stats": {"luck": 2.0, "speed": 0.4}, "desc": "The drake's curl. Luckier food."},
	"beady_eyes": {"name": "Beady Eyes", "type": "passive", "aff": "duck", "rarity": 0, "max": 1, "duck_part": true, "look": {"eyes": "beady"},
		"stats": {"area": 15.0, "magnet": 4.0}, "desc": "+15% attack range and area. Reach food from further away."},
	"green_crest": {"name": "Green Crest", "type": "passive", "aff": "duck", "rarity": 1, "max": 1, "duck_part": true, "look": {"head": "crest_duck"},
		"stats": {"ability": 3.0, "social": 3.0}, "desc": "The mallard hood. +3 Ability, +3 Social."},
	"convergent": {"name": "Convergent Evolution", "type": "passive", "aff": "duck", "rarity": 3, "max": 1, "duck_part": true, "needs_ducks": 5,
		"look": {"shape": "duck"}, "stats": {"all": 20.0}, "grants": "mega_quack",
		"desc": "Become a Mallard. All stats +20%. Learn Mega Quack."},
	# ------------------------------------------------------------ legendary (were boss fruits)
	"swan_neck": {"name": "Swan Neck", "type": "passive", "aff": "duck", "rarity": 3, "max": 1, "look": {"shape": "tall"},
		"stats": {"area": 50.0}, "desc": "Attack range and area +50%."},
	"goose_temper": {"name": "Goose Temper", "type": "passive", "aff": "predator", "rarity": 3, "max": 1, "look": {"eyes": "angry"},
		"stats": {"temper": 40.0, "physical": 4.0}, "desc": "+40% damage while under half HP. +4 Physical."},
	"turtle_shell": {"name": "Turtle Shell", "type": "passive", "aff": "imposing", "rarity": 3, "max": 1, "look": {"armor": "shell"},
		"stats": {"armor": 8.0, "max_hp": 30.0}, "desc": "+8 Armor, +30 HP."},
	"heron_stilts": {"name": "Heron Stilts", "type": "passive", "aff": "prey", "rarity": 3, "max": 1, "look": {"legs": "stilts"},
		"stats": {"speed": 2.0, "swim": 1.0}, "desc": "+2 Speed. Wade through water freely."},
	"pike_jaw": {"name": "Pike Jaw", "type": "passive", "aff": "predator", "rarity": 3, "max": 1, "look": {"mouth": "fangs"},
		"stats": {"physical": 8.0, "crit": 10.0}, "desc": "+8 Physical, +10% critical chance."},
	# ------------------------------------------------------------ unlocked by branches
	"tentacle_lash": {"name": "Tentacle Lash", "type": "attack", "aff": "trickster", "rarity": 1, "max": 5, "locked": true, "look": {"arms": "tentacles_big"},
		"desc": "Two quick lashes that slow what they hit."},
	"kick": {"name": "Kick", "type": "attack", "aff": "predator", "rarity": 0, "max": 5, "locked": true, "look": {"legs": "long"},
		"desc": "A strong kick that sends targets flying."},
	"constrict": {"name": "Constrict", "type": "attack", "aff": "imposing", "rarity": 1, "max": 5, "locked": true, "look": {"tail": "serpent"},
		"desc": "Squeeze: damage, bleed and a heavy slow."},
	"sprint": {"name": "Sprint", "type": "move", "aff": "predator", "rarity": 0, "max": 1, "locked": true, "look": {"legs": "long"},
		"desc": "A long, fast dash."},
	"suckers": {"name": "Suckers", "type": "passive", "aff": "trickster", "rarity": 1, "max": 5, "locked": true, "look": {"arms": "tentacles_big"},
		"stats": {"lifesteal": 4.0}, "desc": "Heal 4% of the damage you deal."},
	"grip": {"name": "Grip", "type": "passive", "aff": "predator", "rarity": 0, "max": 5, "locked": true, "look": {"arms": "claws"},
		"stats": {"physical": 2.0, "crit": 4.0}, "desc": "+2 Physical, +4% crit."},
	"carapace": {"name": "Carapace", "type": "passive", "aff": "imposing", "rarity": 2, "max": 3, "locked": true, "look": {"armor": "plating"},
		"stats": {"armor": 3.0, "thorns": 20.0}, "desc": "+3 Armor. Biters take 20% back."},
	"eel_skin": {"name": "Eel Skin", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "locked": true, "look": {"pattern": "scales"},
		"stats": {"swim": 0.5, "evasion": 4.0}, "desc": "Slippery: better swimming, +4% dodge."},
	"fleet_foot": {"name": "Fleet Foot", "type": "passive", "aff": "prey", "rarity": 0, "max": 5, "locked": true, "look": {"legs": "long"},
		"stats": {"speed": 1.0, "evasion": 2.0}, "desc": "+1 Speed, +2% dodge."},
	"four_stomachs": {"name": "Four Stomachs", "type": "passive", "aff": "prey", "rarity": 1, "max": 5, "locked": true,
		"stats": {"fruit_xp": 30.0, "feed": 20.0}, "desc": "Fruit gives +30% Progress. Feeding Speed +20%."},
	"sweet_nectar": {"name": "Sweet Nectar", "type": "passive", "aff": "gregarious", "rarity": 1, "max": 5, "locked": true, "look": {"head": "antennae"},
		"stats": {"fruit_heal": 2.0, "ally_regen": 1.0}, "desc": "Fruit heals 2. Allies regenerate."},
	# ------------------------------------------------------------ branching evolutions (Boss Fruit)
	"branch_wings": {"name": "Wings", "type": "branch", "aff": "prey", "rarity": 4, "max": 1, "look": {"back": "wings_big"},
		"excludes": ["branch_shell"], "unlocks": {1: ["glide", "feather_darts", "duck_dive"]},
		"stats": {"terrain_res": 80.0, "evasion": 5.0}, "desc": "Terrain Penalty -80%. Opens flight: Glide, Feather Darts, Duck Dive."},
	"branch_tentacles": {"name": "Tentacles", "type": "branch", "aff": "trickster", "rarity": 4, "max": 1, "look": {"arms": "tentacles_big"},
		"excludes": ["branch_arms"], "unlocks": {1: ["tentacle_lash", "suckers"]},
		"stats": {"ability": 2.0, "speed": 0.75}, "desc": "+2 Ability, +0.75 Speed. Opens Tentacle Lash and Suckers."},
	"branch_legs": {"name": "Legs", "type": "branch", "aff": "predator", "rarity": 4, "max": 1, "look": {"legs": "legs_tall"},
		"excludes": ["branch_slithery"], "unlocks": {1: ["kick", "sprint", "fleet_foot"]},
		"stats": {"speed": 1.0}, "desc": "+1 Speed. Opens Kick, Sprint and Fleet Foot."},
	"branch_arms": {"name": "Arms", "type": "branch", "aff": "predator", "rarity": 4, "max": 1, "look": {"arms": "claws_big"},
		"excludes": ["branch_tentacles"], "unlocks": {1: ["pincer_snap", "grip"]},
		"stats": {"physical": 3.0}, "desc": "+3 Physical. Opens Pincer Snap and Grip."},
	"branch_shell": {"name": "Shell", "type": "branch", "aff": "imposing", "rarity": 4, "max": 1, "look": {"back": "shell_big"},
		"excludes": ["branch_wings"], "unlocks": {1: ["carapace", "colossal"]},
		"stats": {"armor": 4.0, "max_hp": 20.0, "speed": -0.3}, "desc": "+4 Armor, +20 HP. Opens Carapace and Colossal."},
	"branch_slithery": {"name": "Slithery", "type": "branch", "aff": "imposing", "rarity": 4, "max": 1, "look": {"tail": "serpent"},
		"excludes": ["branch_legs"], "unlocks": {1: ["constrict", "eel_skin"]},
		"stats": {"swim": 0.6, "speed": 0.5}, "desc": "Swim better, +0.5 Speed. Opens Constrict and Eel Skin."},
	"branch_ruminant": {"name": "Ruminant", "type": "branch", "aff": "prey", "rarity": 4, "max": 1, "look": {"head": "horns_ram"},
		"unlocks": {1: ["four_stomachs", "vegan"]},
		"stats": {"ruminant": 1.0}, "desc": "Every 10 calm seconds, gain Progress equal to 4x your Prey Affinity. Getting hit pauses it for 15s."},
	"branch_alpha": {"name": "Alpha", "type": "branch", "aff": "gregarious", "rarity": 4, "max": 1, "look": {"head": "mane"},
		"unlocks": {1: ["pack_call", "herd_instinct", "duckling_parade"]},
		"stats": {"ally_cap": 2.0, "social": 3.0}, "desc": "+2 ally slots, +3 Social. Opens Pack Call, Herd Instinct, Duckling Parade."},
	"branch_pollinator": {"name": "Pollinator", "type": "branch", "aff": "gregarious", "rarity": 4, "max": 1, "look": {"back": "wings_bee", "head": "antennae"},
		"unlocks": {1: ["sweet_nectar"]},
		"stats": {"pollen": 1.0}, "desc": "Trees, bushes and cacti regrow fruit 60% faster and drop 1 more when bumped. Opens Sweet Nectar."},
	"branch_bill": {"name": "Bill", "type": "branch", "aff": "duck", "rarity": 4, "max": 1, "duck_part": true, "look": {"mouth": "bill"},
		"excludes": ["duck_bill"], "unlocks": {1: ["quack", "mega_quack"]},
		"stats": {"food": 25.0, "ability": 2.0}, "desc": "Counts as a duck part. Food +25%, +2 Ability. Opens Quack and Mega Quack."},
}

## What each duck part looks like on the body (the full mallard, slot by slot).
const DUCK_LOOK := {
	"mouth": "bill", "eyes": "beady", "legs": "webbed", "pattern": "down", "tail": "curl",
	"back": "wings_duck", "head": "crest_duck", "shape": "duck",
}

const DUCK_PARTS := ["duck_bill", "webbed_feet", "down_feathers", "duck_wings", "tail_curl", "beady_eyes", "green_crest", "convergent", "branch_bill"]


static func get_def(id: String) -> Dictionary:
	return ALL.get(id, {})


## One-line stat summary for a card ("+3 Physical").
static func stat_line(id: String) -> String:
	var d := get_def(id)
	return String(d.get("desc", ""))


## The rarity a card shows when it offers this level: base, +1 at level 3, +1 at level 5.
static func offered_rarity(id: String, level: int) -> int:
	var d := get_def(id)
	if String(d.get("type", "")) == "branch":
		return 4
	var r := int(d.get("rarity", 0))
	if level >= 3:
		r += 1
	if level >= 5:
		r += 1
	return mini(r, 3)


## Stat names for the cards: key -> [label, suffix]
const STAT_LABEL := {
	"physical": ["Physical", ""], "ability": ["Ability", ""], "max_hp": ["Max HP", ""], "speed": ["Speed", ""],
	"social": ["Social", ""], "size": ["Size", "%"], "armor": ["Armor", ""], "regen": ["Regen", "/s"],
	"crit": ["Crit", "%"], "evasion": ["Dodge", "%"], "magnet": ["Feeding Distance", ""], "pouch": ["Pouch Capacity", ""], "luck": ["Luck", ""],
	"xp": ["Progress", "%"], "food": ["Food Value", "%"], "thorns": ["Thorns", "%"], "poison": ["Poison", "/s"],
	"heal_kill": ["Heal on Kill", ""], "execute": ["Execute", "%"], "stealth": ["Stealth", "%"], "revive": ["Extra Life", ""],
	"ally_cap": ["Ally Slots", ""], "ally_dmg": ["Ally Damage", "%"], "ally_regen": ["Ally Regen", "/s"], "herd": ["Armor per Ally", ""],
	"ram": ["Ram", "%"], "echo": ["Echo", "%"], "swim": ["Swimming", ""], "temper": ["Temper", "%"], "all": ["All Stats", "%"],
	"vision": ["Night Vision", ""], "identify": ["Senses", ""], "meat_xp": ["Meat Progress", "%"], "fish_xp": ["Fish Progress", "%"],
	"fruit_xp": ["Fruit Progress", "%"], "fruit_heal": ["Fruit Heal", ""], "scav_xp": ["Carrion Progress", "%"],
	"feed": ["Feeding Speed", "%"], "shroom_xp": ["Mushroom Progress", "%"], "cdr": ["Cooldowns", "%"], "area": ["Area", "%"],
	"lifesteal": ["Lifesteal", "%"], "terrain_res": ["Terrain Penalty", "-%"], "forage": ["Healing Food", "%"],
	"hump": ["Max HP per Full Bite", ""],
}


static func _num(v: float) -> String:
	return str(int(v)) if absf(v - roundf(v)) < 0.01 else "%.1f" % v


## Card lines at the current level: [[label, now, next]] (now is "" for a new evolution).
static func lines(id: String, cur: int) -> Array:
	var d := get_def(id)
	var out: Array = []
	var t := String(d.get("type", ""))
	if t == "attack" and Attacks.ATTACK.has(id):
		var a: Dictionary = Attacks.ATTACK[id]
		out.append(["Damage", "" if cur == 0 else "x%.2f" % Attacks.rank_dmg(cur), "x%.2f" % Attacks.rank_dmg(cur + 1)])
		out.append(["Cooldown", "" if cur == 0 else "%.2fs" % (float(a["cd"]) * Attacks.rank_cd(cur)), "%.2fs" % (float(a["cd"]) * Attacks.rank_cd(cur + 1))])
	elif t == "ultimate" and Attacks.ULT.has(id):
		var ucd := float(Attacks.ULT[id]["cd"])
		out.append(["Cooldown", "" if cur == 0 else "%ds" % int(ucd * (1.0 - 0.08 * (cur - 1))), "%ds" % int(ucd * (1.0 - 0.08 * cur))])
	elif t == "move" and Attacks.MOVE.has(id):
		out.append(["Cooldown", "", "%.1fs" % float(Attacks.MOVE[id]["cd"])])
	var st: Dictionary = d.get("stats", {})
	for k in st:
		if not STAT_LABEL.has(k):
			continue
		var lab: Array = STAT_LABEL[k]
		var v := float(st[k])
		var sgn := "+" if v >= 0.0 else ""
		var suf := String(lab[1])
		out.append([String(lab[0]), "" if cur == 0 else sgn + _num(v * cur) + suf, sgn + _num(v * (cur + 1)) + suf])
	return out


## Ids this evolution opens up, over all its levels.
static func unlocks_of(id: String) -> Array:
	var out: Array = []
	var u: Dictionary = get_def(id).get("unlocks", {})
	for lvl in u:
		for x in u[lvl]:
			out.append(x)
	return out


## Ids banned by holding this one (its excludes, plus anything that excludes it).
static func bans_of(id: String) -> Array:
	var out: Array = (get_def(id).get("excludes", []) as Array).duplicate()
	for other in ALL:
		if id in (ALL[other] as Dictionary).get("excludes", []) and not other in out:
			out.append(other)
	return out
