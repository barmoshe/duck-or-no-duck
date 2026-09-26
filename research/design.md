# Duck or no duck ?!: design (v2, faithful to Everything is Crab)

"Duck or no duck ?!" is a landscape mobile homage to *Everything is Crab: The Animal Evolution Roguelite*. It is Crab's loop in an open world, with a duck twist: crab parts become **duck parts**, an optional hidden affinity (anatification). **The world does not turn into ducks**, and neither does Crab's world turn into crabs. The final boss is the Great Mallard.

## Research (web, 2026-09-25)
Page fetches are blocked by the network policy, so everything below comes from search summaries. Sources:
- store.steampowered.com/app/3526710
- everythingiscrab.wiki.gg (Map, Evolution, Affinity, Animal)
- hinamizawa.ai/everything-is-crab (evolutions, POIs, bosses)
- Reviews: butwhytho.net, thegamer.com (review and beginner guide), dualshockers.com, thejimquisition.com, bonus-action.com, pcgamer.com, bigbossbattle.com, rogueliker.com
- Guides: gamerant.com, everythingiscrab.org

| Topic | Crab facts | Our version |
|---|---|---|
| Look | top-down pixel art; every mutation is animated on the body (snout type, leg count, eye count); 11 body slots: base body, hide, limbs, limb tips, mouth, eyes, tail, wings, accents, armor | layered pixel parts: shape, hide (pattern), legs, arms, mouth, eyes, tail, wings, head accent, armor |
| Start | Darwin, a blue blob; the only attack is a headbutt, plus a dash | Puddle, a blue blob: Headbutt + Scoot |
| Loop | forage fruit and mushrooms or kill animals and eat them; food fills an XP bar at the **bottom** of the screen; a level up offers 3 evolutions | same |
| Run | about 20 min; a **timer bar at the top** shows which bosses come and in what order; 3 bosses, then a final | a 15 min timer bar with boss icons; 3 bosses (drawn randomly from a pool of 5), then the final |
| Bosses | an arena forms around you, with its boundary and trees as terrain; if you survive long enough they give up and still drop boss food (pick a major mutation); you can hide in burrows | same, with a 75 s give-up clock; boss food is a Boss Fruit pick |
| Final | Krabken, plus a meteor shower cataclysm; survive 2 min and the meteors kill it | the Great Mallard, plus **Breadfall**; survive 2 min and it's over |
| Map | one open map, 4 terrains: grass (rain), desert (heat, mirages), snow (storms, low visibility, freezing), water; movement is slowest in water, then snow, then sand | open world 2560 px wide: grass, sand and snow regions, a big lake, rivers, a forest edge |
| Day/night | at night your visibility shrinks to a small circle and some animals behave differently | a 4 min cycle; night uses a pixel vision circle; hunters are bolder at night; fireflies |
| POIs | ~14 kinds, each limited to certain terrains; walk in, pick 1 of the options; e.g. Healing Pond (heal 50% or +1 regen), Mud Pond, Sun Dial (HP for long-term gains), Oasis, Frozen Specimen, Unattended Nest, Giant Mushroom, Carved Tree, Growing Tree, Lotus, Algae Reef, Chaos Tree | 12 POIs with option cards |
| Mushrooms | you must interact to eat; random good or bad effects; More Eyes identifies them | same |
| Burrows | holes on the map; inside you're immune and attackers lose interest | same |
| Diets | Carnivore (meat), Piscivore (fish), Herbivore (fruit), Scavenger (kills made by others) | same |
| Evolutions | ~121; types Passive / Attack (2 equipped) / Ultimate / Movement; 4 rarities; Mutagen from Alphas (★) buys rerolls and rarity upgrades; 5 affinities, +10% offer weight per point; crab is a hidden affinity: take more damage, find rarer food | same, with duck in place of crab; Total Anatification = all 8 duck parts |
| Social | charmed allies, up to 12 | Charm Song and Egg allies; cap from Social |
| Meta | Genetics (starting modifiers unlocked by goals), Selective Pressure difficulty, Codex | same |

Our additions for mobile:
- Landscape only: a floating joystick, auto-aimed attacks, and Dash and Ultimate buttons.
- The game pauses on every choice.
- Runs last 15 minutes.

## Visual direction
- **Resolution.** The short side of the screen is about 240 virtual pixels at an integer scale, so a landscape phone sees roughly 510×236. The camera is close, like Crab's.
- **Palette.** Endesga 32 ramps. Each sprite has a 1 px hue-shifted outline and top-left light, and the player gets big cute eyes.
- **Ground.** A shader draws it:
  - dithered terrain tones and wobbly borders;
  - **sand beaches** where land meets water;
  - water shimmer and shore foam, snow sparkle, ice;
  - a forest-canopy edge.
- **Props.** Foliage sways (shader, pixel-snapped) and trees drop shadows.
- **Light.** Day and night run through a CanvasModulate: warm dawn, blue night. At night a dithered vision circle surrounds the player and fireflies come out.
- **Juice.** Pixel particles, hit flashes, whole-pixel shake, numbers in Silkscreen, arena rings and boss telegraphs.

## Evolution Graphics System (the character art)
The research (web, 2026-09-25) covered Crab's Darwin rendering, paper-doll systems (Mana Seed, Crom's Paper Doll), and pivots and anchors in sprite sheets. Findings:
- In Crab, every body part is its own art layer in its own sprite sheets, plugged into the animations.
- There are 11 slots composed in z-order with pivot-aware alignment, about 2,000 player frames across 344 part prefixes.
- Pincers replace arms and the shell forms a back-piece.
- Paper-doll parts follow the base body's frame numbers.

Our version:
- **Body rigs.** Hand-drawn base frames, with socket markers painted into the pixels: `* < ^ # = ~ / : % !`.
  - Frames are made with pixel-safe transforms: squash drops a middle row and doubles the center column, stretch does the reverse, plus lift and lean. That's the same moves a pixel artist uses for a slime bounce.
  - Puddle: `slime` (hatchling, jelly outline, sheen, bubbles, drips) → `mochi` (4 bodily mutations) → an affinity body at 8: `beast` (predator/prey), `chunk` (imposing/social), `bug` (trickster), or `duck` (the mallard: Convergent Evolution).
- **Parts.** Hand-drawn per slot, with a pivot and their own frames: eyes (blink), mouths (attack frame), crowns, wings (flap), armor, tails (wag), limbs (4-frame walk, far side darkened), arms and hides. Hides are masked to the body.
- **Compositor.** `Anatomy` normalizes a look, then stacks the parts at the current frame's sockets in z-order: far limbs, far wing, tail, body, hide, armor, near limbs, wing, crown, eyes, mouth, arms.
  - Parts inherit the body's color ramp, so a metamorphosis recolors everything.
  - Bosses are the same rigs at 2x.

## v3 "reinvent" (2026-09-26)

**Research** (search snippets; most wiki sites are blocked by the proxy):
- Everything is Crab food: 3 types (fruit, meat, fish) x 4 rarities. Animal rolls are 75/19/5/1 and boss rolls 55/27/14/4. Common to epic food can turn into heart drops.
- Sources: bushes and trees give fruit, fish pools give fish, animals give meat.
- Diets: Carnivore, Piscivore, Herbivore, Vegan, Scavenger/Carrion, Ruminant, and a Feeding Speed stat.
- Evolutions have levels 1-5, and rarity rises with the level. Cards show "Unlocks / Bans". Boss Fruit gives Branching Evolutions: Wings, Tentacles, Legs, Arms, Slithery, Ruminant, Alpha, Pollinator.
- Genetics: pick 2 of 3 before a run.
- Critics say you level up too often, the start is weak, and bosses never change.

**What we changed:**
1. **Food web** (`data/foods.gd`, `world.gd`): rarity rolls, hearts, shaking fruit sources, fish pools, carcasses you chew, contested by scavengers.
2. **Evolution tree** (`data/evolutions.gd`): `locked`, `unlocks {level: [ids]}`, `excludes` (bans), and branches (`type: "branch"`). Branch parts are applied last in `Run._look`, so the body plan survives later picks.
3. **Evolution screen** (`ui/level_up.gd`, `art/portrait.gd`): portraits crop `Anatomy.render` around the evolution's slot on the player's own creature.
4. **Fewer, heavier level-ups:**
   - `xp_need = 10 + 9L + 1.8L²`
   - each level adds +6 HP, +0.6 Physical and +0.6 Ability
5. **Starts and bosses:** Gulp as the starter, a nursery first minute, bosses enrage in phase 2 with telegraphs, and an ally hard cap of 14.
6. **Meta:** Genetics pick 2 of 3, and the DUCK / NO DUCK verdict (5+ duck parts or Convergent).
