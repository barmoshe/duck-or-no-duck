class_name Pois
extends RefCounted
## Points of interest (Crab's "?" markers): walk in, pick one of the options, the rest
## are gone. Each kind only appears in certain terrains. Effects are read by
## World.apply_option: heal, bonus (permanent stats), buff (timed), xp, mutagen,
## hp_cost, ally, evo (open an evolution hand), random_evo, time (night/day), fruit,
## mushrooms, parent (an angry Alpha shows up), affinity, gamble.

const ALL := {
	"healing_pond": {"name": "Healing Pond", "terrain": ["grass", "snow"], "options": [
		{"name": "Drink", "desc": "Heal 50% HP.", "fx": {"heal": 0.5}},
		{"name": "Bathe", "desc": "+1 HP regeneration.", "fx": {"bonus": {"regen": 1.0}}},
		{"name": "Soak", "desc": "+15 Max HP.", "fx": {"bonus": {"max_hp": 15.0}}}]},
	"mud_pond": {"name": "Mud Pond", "terrain": ["grass", "sand"], "options": [
		{"name": "Mud Armor", "desc": "+2 Armor.", "fx": {"bonus": {"armor": 2.0}}},
		{"name": "Wallow", "desc": "Predators notice you 20% later. +4% dodge.", "fx": {"bonus": {"stealth": 20.0, "evasion": 4.0}}},
		{"name": "Mud Party", "desc": "+3 Social.", "fx": {"bonus": {"social": 3.0}}}]},
	"sun_dial": {"name": "Sun Dial", "terrain": ["sand", "grass"], "options": [
		{"name": "Sun Strength", "desc": "Lose 25% HP. +3 Physical.", "fx": {"hp_cost": 0.25, "bonus": {"physical": 3.0}}},
		{"name": "Sun Wisdom", "desc": "Lose 25% HP. +3 Ability.", "fx": {"hp_cost": 0.25, "bonus": {"ability": 3.0}}},
		{"name": "Sun Sprint", "desc": "Lose 25% HP. +1 Speed.", "fx": {"hp_cost": 0.25, "bonus": {"speed": 1.0}}}]},
	"oasis": {"name": "Oasis", "terrain": ["sand"], "options": [
		{"name": "Full Drink", "desc": "Heal to full.", "fx": {"heal": 1.0}},
		{"name": "Deep Roots", "desc": "+2 HP regeneration.", "fx": {"bonus": {"regen": 2.0}}},
		{"name": "Palm Shade", "desc": "+25 Max HP.", "fx": {"bonus": {"max_hp": 25.0}}}]},
	"frozen_specimen": {"name": "Frozen Specimen", "terrain": ["snow"], "options": [
		{"name": "Thaw It", "desc": "It wakes up on your side: a strong ally.", "fx": {"ally": "random"}},
		{"name": "Eat It", "desc": "A big frozen meal: lots of XP.", "fx": {"xp": 3.0}},
		{"name": "Study It", "desc": "Pick a Rare or better evolution.", "fx": {"evo": 1}}]},
	"unattended_nest": {"name": "Unattended Nest", "terrain": ["grass", "sand"], "options": [
		{"name": "Steal the Eggs", "desc": "Huge XP, but the parent comes back angry.", "fx": {"xp": 4.0, "parent": true}},
		{"name": "Adopt an Egg", "desc": "It hatches a duckling ally.", "fx": {"ally": "duckling"}},
		{"name": "Leave It", "desc": "Good karma: +2 Mutagen.", "fx": {"mutagen": 2}}]},
	"giant_mushroom": {"name": "Giant Mushroom", "terrain": ["grass", "snow"], "options": [
		{"name": "Eat the Cap", "desc": "Two random mushroom effects. Good or bad.", "fx": {"shroom": 2}},
		{"name": "Spore Cloud", "desc": "Skip ahead to night (or day).", "fx": {"time": true}},
		{"name": "Spore Field", "desc": "Mushrooms sprout all around.", "fx": {"mushrooms": 8}}]},
	"carved_tree": {"name": "Carved Tree", "terrain": ["grass"], "options": [
		{"name": "Predator Mark", "desc": "+3 Predator points: more Predator offers.", "fx": {"affinity": "predator"}},
		{"name": "Imposing Mark", "desc": "+3 Imposing points: more Imposing offers.", "fx": {"affinity": "imposing"}},
		{"name": "Trickster Mark", "desc": "+3 Trickster points: more Trickster offers.", "fx": {"affinity": "trickster"}}]},
	"growing_tree": {"name": "Growing Tree", "terrain": ["grass"], "options": [
		{"name": "Shake It", "desc": "A shower of fruit.", "fx": {"fruit": 12}},
		{"name": "Sprout", "desc": "+10% XP from everything.", "fx": {"bonus": {"xp": 10.0}}},
		{"name": "Old Wood", "desc": "+2 Luck: better food, more Mutagen.", "fx": {"bonus": {"luck": 2.0}}}]},
	"lotus_plant": {"name": "Lotus Plant", "terrain": ["lake"], "options": [
		{"name": "Bloom", "desc": "+3 Ability.", "fx": {"bonus": {"ability": 3.0}}},
		{"name": "Calm", "desc": "Cooldowns 8% faster.", "fx": {"bonus": {"cdr": 8.0}}},
		{"name": "Nectar", "desc": "Heal 30% and +0.5 regeneration.", "fx": {"heal": 0.3, "bonus": {"regen": 0.5}}}]},
	"algae_reef": {"name": "Algae Reef", "terrain": ["lake"], "options": [
		{"name": "Graze", "desc": "A slimy feast: XP.", "fx": {"xp": 2.0}},
		{"name": "Gills", "desc": "Swim at full speed.", "fx": {"bonus": {"swim": 1.0}}},
		{"name": "Slime Coat", "desc": "+6% dodge.", "fx": {"bonus": {"evasion": 6.0}}}]},
	"chaos_tree": {"name": "Chaos Tree", "terrain": ["grass", "sand", "snow", "lake"], "options": [
		{"name": "Random Evolution", "desc": "Get a random evolution. Any rarity.", "fx": {"random_evo": true}},
		{"name": "Mutagen Fever", "desc": "+5 Mutagen, lose 20% HP.", "fx": {"mutagen": 5, "hp_cost": 0.2}},
		{"name": "Coin Flip", "desc": "Win: a burst of XP. Lose: 40% HP.", "fx": {"gamble": true}}]},
}

## Mushroom effects: [name, good?, fx]
const SHROOMS := [
	["Tasty!", true, {"xp": 0.6}],
	["Refreshing", true, {"heal": 0.25}],
	["Zoomy", true, {"buff": {"speed": 2.0}, "secs": 20.0}],
	["Mighty", true, {"buff": {"physical": 5.0, "ability": 5.0}, "secs": 25.0}],
	["Lucky", true, {"mutagen": 1}],
	["Yuck", false, {"hp_cost": 0.15}],
	["Sleepy", false, {"buff": {"speed": -2.0}, "secs": 12.0}],
	["Dizzy", false, {"dizzy": 6.0}],
	["Tiny", false, {"buff": {"size": -30.0, "physical": -3.0}, "secs": 20.0}],
]


static func get_def(id: String) -> Dictionary:
	return ALL.get(id, {})


static func kinds_for(terrain: String) -> Array:
	var out: Array = []
	for id in ALL:
		if terrain in ALL[id]["terrain"]:
			out.append(id)
	return out
