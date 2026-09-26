# Everything is Crab: mechanics notes

Source: everythingiscrab.wiki.gg pages Food, Evolution, Affinity, Genetic, Darwin, Cheek
Pouch, Saliva, Slow Metabolism, Scavenger (read 2026-09-26); everythingiscrab.org
"Food Progress and Fast Leveling Guide" (updated 2026-09-07, patch 1.2.1).

## Food and eating

- **Three foods, four rarities.** Fruit (green apple, blue dragonfruit, purple
  mangosteen, golden grapes), fish and meat (each common / rare / epic / legendary).
  The rarity is a whole different sprite and color, not a tint.
- **Where it comes from.** Fruit grows on trees and cacti and drops to the ground over
  time. Fish drops from fish-like creatures and deep-water pools. Meat drops from any
  non-fish creature that dies, whoever killed it (even Darwin's own kind). Kills drop
  pieces directly: there is no carcass to chew.
- **Four bites per piece.** Every fruit, fish and meat takes 4 bites to finish, and the
  sprite shrinks through 4 stages (whole, bitten, mostly eaten, core or bones: see the
  `food/*_consumption.png` strips). Other animals can take single bites or finish it.
- **Eating is automatic and parallel.** Darwin eats by standing on or walking over food.
  Every piece in range is bitten at once: "the more pieces of food within range, the more
  Darwin eats at once". The first bite on reaching food is instant; later bites wait for
  the bite interval (Feeding Speed shortens it).
- **Progress per bite.** Common 2, rare 6, epic 18, legendary 60 per bite; the final bite
  pays double, so totals are 10 / 30 / 90 / 300.
- **Finish cue.** A sound and a visual sparkle when everything in range is eaten.
- **Healing food.** Some pieces sparkle; each bite of those heals. Golden (legendary)
  food always sparkles for rarity and does not heal. Forager raises the heal-food chance.
- **Mushrooms** are not eaten automatically: you interact, swallow it instantly, then
  digest it in bites like food; its effect starts when finished. All mushrooms give
  Progress scaled to the level.
- **Boss Fruit (Branching Berry)**: one bite, eaten instantly in range, finishes the
  level with a branching choice, heals a set amount.
- **Feeding Distance** (base 1 unit) scales with size. Arms +2..+6, Trunk +0.66..+5,
  Prehensile Tail +2..+9.
- **Feeding Speed** (base 100%). Beak/Jaws +10..+90%, Saliva +15..+120% (plus
  Regeneration), Stomach +25..+200%.
- **Cheek Pouch**: stores nearby food and eats it at the same rate; capacity +1..+5 by
  level and rarity. Guides: "lets you keep moving instead of stopping".
- **Rarity rises** with run time and with Carcinisation.
- **Diet bonuses** add up: Herbivore/Vegan (fruit), Piscivore (fish), Carnivore (meat),
  Scavenger (fish and meat you did not kill), Omnivore (all).

## Evolutions

- **Slots.** Passive (unlimited), Attack (2 equipped), Dash/Movement (1), Ultimate (1).
  Card marks: teeth = attack, paw = movement, lightning = ultimate.
- **Rarity** banner colors: common green, rare blue, epic purple, legendary gold. Branching
  is a fifth, parallel rarity from Boss Fruit.
- **Levels** are 1, 3 or 5 (endless ones are infinite), shown as dots on a track over the
  icon; a star marks the level that specialises.
- **Power = level + current rarity.** When the rarity was raised does not matter.
- **Specialisation** at the starred level: pick one of two, locked for the run.
- **Bans** (lock icon) and **unlocks** (open-lock icon, sometimes only at level 2-4).
- **Offers.** Once you own an evolution it is offered much more often. Maxed evolutions
  leave the pool.
- **Mutagen.** Rare from animals, common from alphas, always from bosses. At a level-up,
  a reroll costs 1 (+1 per use) and an upgrade of all options by one rarity costs 10 (+10
  per use); costs reset per level-up. Branching choices can only reroll, at 10.

## Affinities

Gregarious, Imposing, Predator, Prey and Trickster: each pick of an evolution adds 1 to
its affinities, and each point makes that affinity's evolutions 10% likelier to be
offered. Carcinisation is special: it does not stack, raises damage taken, and raises the
rarity of food.

## Genetics (pick before a run; splice 2 of 3 after beating Pressure 1)

| Genetic | Effect |
|---|---|
| Standard | +15 HP (the starting genetic) |
| Ambivalent | Bigger = rarer evolutions; smaller = more mutagen |
| Bullseye | Physical and Ability attacks use the higher of the two |
| Challenger | +30% damage to alphas, +30% alphas |
| Chosen | 3rd level-up offers 3 legendaries |
| Contrarian | Least-picked evolutions appear more, at higher rarity |
| Elitist | New legendary levels you up at once; a common costs 10% max HP |
| Envoy of Chaos | Random starting affinities |
| Expert | Specialisations one level earlier |
| Highborn | Physical and Ability -50%, nearby area +50%, nearby enemies take +50% |
| Independent | Every 12th level-up is branching; bosses drop no Boss Fruit |
| Minimalist | +15% damage and progress per empty attack/dash/ultimate slot; no starting dash |
| Opportunistic | Double stats from charmed allies and POI choices |
| Pacifist | -50% damage, 33% less progress to evolve |
| Patient | Skip evolutions; each skip raises next level's rarity chance |
| Picky | Rerolls cost 1 less |
| Pioneer | +50% Points of Interest |
| Precocious | First level-up is branching; first boss drops no Boss Fruit |
| Simple | -2 evolution choices, +200 starting mutagen |
| Spawn of Chaos | Random starting stats |
| Stubborn | One evolution/POI choice grants random mutagen |
| Underdog | -20% damage, HP, progress; after the 2nd boss it flips to +40% |
| Vegan | Start with the Vegan evolution |
| Darwin's Choice | A random unlocked genetic (single-pick mode only) |

## Darwin's base stats

Physical 10, Ability 10, Max HP 50, Social 5, Speed 5. Food Progress 100%, Feeding Speed
100%, Feeding Distance 1. Starts with BOP (0.6-0.8x Physical, 0.8 s) and Basic Dash
(4.5 units, 4.5 s, no invulnerability).
