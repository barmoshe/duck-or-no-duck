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

## Next: Crab-faithful eating and food art (handed to a local agent with a browser)
Bar (26/09): "the eating is not like in Everything is Crab; improve the eating logic and all the food assets and looks". The cloud container blocks every Crab wiki and guide page (wiki.gg, hinamizawa.ai, everythingiscrab.org, thegamer, neoseeker, sportskeeda), so the research moves to a local agent.

**Research so far** (search snippets only):
- **Drops:** killed animals (by Darwin, another animal or a boss) drop a number of food pieces, meat or fish, and other animals can eat them. The snippets never mention chewing a carcass.
- **Food items:** 12 basic foods, fruit, meat and fish in 4 rarities each (common, rare, epic, legendary). Rarity is shown by tier, not by name.
- **Heart drops** are "HpFood heal-on-bite" versions of each food type ("sparkling food heals").
  - Common, rare and epic pieces can turn into a heart drop, at a chance set by the "Food Into Health" stat. Legendary pieces never do.
  - Regular enemies roll legendary 1% of the time; bosses 4%.
- **Feeding stats:** Darwin's base Feeding Distance is 1 (world units). Feeding Speed, Cheek Pouch ("store nearby food, eaten at the same rate", capacity 2), Saliva (for when feeding speed is the bottleneck) and Slow Metabolism exist.
- **What guides say:** Cheek Pouch "lets you keep moving instead of stopping for every food pickup". Mushrooms give food progress. Carcinisation raises the quality of food that spawns.

**Open questions for the browser** (wiki pages plus gameplay video):
- How does a bite look and play? Does Darwin stop? Does one piece take several bites and shrink? How long is a bite?
- How far is Feeding Distance in practice? What does the food look like on the ground (sprites, sizes, the sparkle and rarity glow)?

**Pages to read:**
- everythingiscrab.wiki.gg: Food, Darwin, Cheek Pouch, Saliva, Slow Metabolism
- hinamizawa.ai/everything-is-crab/items
- everythingiscrab.org/mechanics

**What the game has now** (v6):
- The meal slot in `World._feed`, with `Foods.eat_time`: stand still, chew 0.35-0.5 s, heal a little.
- Cheek Pouch and Saliva.
- Carcass bites, which may need to become plain meat drops.
- Food sprites from `Props` (`food_<type>_<rarity>`), hearts, and the chew ring in `fx.gd`.

**Still to do:** redraw all the food art in the flat Darwin style.

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
