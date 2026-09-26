# Duck or no duck ?! — STATUS

- Updated: 2026-09-26
- Live: https://duck-or-no-duck.vercel.app (Vercel project `duck-or-no-duck`, git-linked, serves `public/`)

## Where we are
v0.3 "reinvent" build, playable end to end. Headless tests, a balance report and a browser webtest all pass.

- **Look:** Everything is Crab's bright style.
  - flat grass with tufts, smooth shores with a foam line
  - fluffy green, autumn and blossom trees
  - wooden HUD: heart and HP bar, clock timer with boss portraits, fruit and XP bar, framed ability icons
  - crescent slash effects
- **Food web:**
  - fruit, meat and fish in common/rare/epic/legendary (75/19/5/1), plus heart drops
  - bump trees, bushes and cacti to shake fruit loose
  - fish pools in the water
  - big kills leave carcasses you chew (Feeding Speed), and scavengers compete for them
  - diets: Carnivore, Piscivore, Herbivore, Vegan, Omnivore, Carrion, Ruminant; mushrooms give Progress
- **Eating (v6, Crab's feeding model):**
  - You stand still next to food and chew it, one piece at a time.
  - Eating takes 0.35-0.5 s by type, longer for rarer pieces, and runs faster with more Feeding Speed. Every piece heals a little.
  - Reach is Feeding Distance: the old "Pickup Range" vacuum is gone. Only hearts and mutagen are grabbed on touch.
  - Moving pauses chewing, walking off drops the piece, and animals can steal it.
  - Carcasses are eaten bite by bite, and each bite goes straight to Progress.
  - New evolutions: **Cheek Pouch** (stores food in reach and eats it on the move; capacity 2/4/6, shown as HUD slots) and **Saliva** (Feeding Speed +25%).
- **Evolution:**
  - levels 1-5, with rarity rising by level
  - an evolution tree: unlocks and bans
  - Boss Fruit gives Branching Evolutions (Wings, Tentacles, Legs, Arms, Shell, Slithery, Ruminant, Alpha, Pollinator, Bill), which set the body plan and open families of evolutions
- **Character art (v5):**
  - Puddle is redrawn by hand in the flat style of Crab's Darwin: a blue gumdrop body with an aqua face and a 1 px ink outline.
  - Each evolution adds a hand-drawn part (horns, ram horns, antlers, goggles/stalks, antennae, shell, wings, tails, legs, claws, bill and so on) at a fixed anchor, with idle, walk and bite poses. Convergent recolors Puddle as a mallard.
  - All 24 animals and 6 bosses are hand-drawn in the same flat style (side view, walk legs, blink, bite); the Great Mallard is shown at 2x as a giant. The v4 Sculptor/Genome is gone.
- **Evolution screen, Crab-style for phones:**
  - affinity panel with emblems and a live preview
  - rarity-framed cards with portraits of the evolution on your own creature, now -> next numbers, unlock and ban chips
  - Upgrade, Reroll and Evolve; tap to select, tap again to evolve
- **Combat:**
  - Puddle starts with Gulp; crit hit-stop
  - a nursery first minute with no predators
  - bosses enrage at half HP with telegraphed attacks
- **Meta:**
  - pick 2 of 3 Genetics before every run (11 genetics)
  - the DUCK / NO DUCK verdict at the end
  - Selective Pressure 0-5; Codex
  - every screen in wood and parchment

## Balance (bot, 4 seeds, `godot --headless --path game -- --test --balance=4`)
- About half the bots get past the first boss.
- About half the level-25 bots beat the final boss.
- Level-ups were a bit below the 14-16 target, so the XP curve was eased on 2026-09-26.

## Next action
- Playtest on a phone and tune from real play, especially:
  - boss damage
  - how quickly food spoils
  - the XP curve
- Candidates:
  - real per-evolution portrait art for the most common cards
  - more animal rigs
  - a save of the run in progress

- Playtest the flat-art build on a phone: check silhouettes at 1x, and whether any evolution should add a visible part it doesn't yet.

## Blockers
- The container blocks vercel.com and api.vercel.com, so deploys go through the Vercel MCP `create_deployment` with the git source (Vercel builds from GitHub).
- The webtest's "sound comes out" check is flaky in headless Chromium: it sometimes reads 0 and passes on rerun.
