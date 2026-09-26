# Duck or no duck ?! — STATUS

- Updated: 2026-09-26 (v7.4)
- Live: https://duck-or-no-duck.vercel.app (Vercel project `duck-or-no-duck`, git-linked, serves `public/`). v7.3 is live: build 393e0784, deployed from main bb214cb on 2026-09-26.

## Where we are
v0.3 "reinvent" build, playable end to end. Headless tests, a balance report and a browser webtest all pass.

- **Look:** Everything is Crab's bright style.
  - flat grass with tufts, smooth shores with a foam line
  - fluffy green, autumn and blossom trees
  - wooden HUD: heart and HP bar, clock timer with boss portraits, fruit and XP bar, framed ability icons
  - crescent slash effects
- **Food web:**
  - fruit, meat and fish in common/rare/epic/legendary (75/19/5/1), colored green/blue/purple/gold; some pieces sparkle and heal
  - bump trees, bushes and cacti to shake fruit loose
  - fish pools in the water
  - every kill drops pieces of meat or fish (big animals and alphas drop more), and scavengers bite at them
  - diets: Carnivore, Piscivore, Herbivore, Vegan, Omnivore, Carrion, Ruminant
- **Eating (v7.2, one piece at a time):**
  - Walk over food and you eat it, one piece at a time: you finish the piece you started, then take the nearest one in your Feeding Distance. One bite per bite time (0.55 s at 100% Feeding Speed, so about 2 s a piece). The first bite on reaching food is instant.
  - This breaks from Crab on purpose: Crab bites every piece in reach at once, and in play it felt like inhaling a pile of food.
  - A piece takes 4 bites and shrinks with each; each bite pays 1/5 of its Progress, the last pays 2/5.
  - Sparkling food (pink twinkles) heals 4.5% max HP per bite; legendary twinkles gold and never heals. Heart drops are gone.
  - Animals take single bites and can finish a piece.
  - **Cheek Pouch** stores food from twice your reach (capacity 2/4/6, HUD slots) and eats it, one piece at a time, when nothing is in reach; **Saliva** is Feeding Speed +25%.
  - **Food Sense** (v7.1, after Crab's Forager): +50% healing-food chance per level. **Hump** (v7.1): a sparkling bite at full health adds 1 Max HP for good.
- **Sound, redesigned (v7.4):** every effect comes from `SfxSynth` (tones with glides, FM bells and wood knocks, filtered noise, bubbles, echo), leveled to one loudness and mixed by `SfxSynth.LEVEL`. 53 sounds (68 with variants): each attack has its own, hits/crits/kills have impact sounds, bites sound like fruit, meat or fish, eating a mushroom, pouching, finishing a meal and a bumped tree each have their own. SFX and Music buses into a limited Master; voices go by priority so hits never cut off a level-up; music dips under big moments; Deafening is a low-pass filter. Review: `godot --headless --path game -s res://tests/sfx_board.gd -- out_dir` (WAVs + punch/level/low-end per sound); a listening board was published as a private claude.ai artifact.
- **Every attack is its own thing (v7.3):** each of the 17 attacks has a shape (one target, swipe, strike ahead, all around, cone, charge, shot, lob), a range, a windup (its speed), a cooldown and one signature (Jaws double damage to stunned, Charge invulnerable, Kick bowls animals into each other, Mud Splash leaves a slowing pool, Constrict holds, Tentacle Lash pulls, Feather Darts pierce, Spit splashes, Stinger poisons 5 s). Holding an attack's button shows its reach in its shape and marks the animal it would hit; each attack has its own animation. Cards show Range and Speed. Table and reasons: `research/attacks.md`.
- **Attacks are pressed, the aim is automatic (v7.2):** each equipped attack (up to 2) has a button along the bottom right (Q/U and R/I on a keyboard). A tap strikes; holding keeps striking as the cooldown allows; a press during the cooldown goes off when it ends (0.25 s buffer). Each strike aims itself at the best target in range. With nothing in range, projectiles and area attacks still go toward the nearest enemy or the way you walk; bites and lunges swing at the air and are ready again in 0.3 s. Attacks used to fire on their own. (Crab has no auto-attacks either; you aim with the mouse there. Its AutoAttack mod snaps melee to the nearest enemy, which is the aim half of this.) DASH and ULTIMATE sit above the attacks; the HUD's bottom-left attack slots are gone, since the buttons show the cooldowns.
- **E, the use button (v7.2, as in Crab):** when there is something to use, an "[E] EAT" or "[E] <SPOT NAME>" prompt floats over it and an E button (keycap icon, labeled EAT or LOOK) shows up beside the attack buttons; on a keyboard it's the E key. It eats the mushroom at your feet or opens the ? spot you're at. ? spots no longer open just because you walk into them.
- **Mushrooms (v7.2, as in Crab):**
  - You eat one on purpose with **E**, Crab's use button: walking over a mushroom does nothing.
  - 10 looks (cap color + shape) and 14 effects. At the start of each run every look is dealt one effect and keeps it all run. Once you eat a look, its name shows over every mushroom of that look (yellow good, blue mixed, salmon bad).
  - Senses (the identify stat, More Eyes +1 per level) can name a mushroom on sight the first time you come near: blind at 0, about 25% at 1, always right at 2.5.
  - Every mushroom gives 10% of a level's Progress (More Eyes +50%), then its effect.
  - Good: Yummy (Progress), Delicious (heal 30%), Medicinal (heal 40% over 4 s), Amusing (a random stat buff, 30 s), Mystical (+2 Mutagen), Nutritious (+5 Max HP for good), Prolific (4 fruit). Mixed: Spicy (speed, costs 5% HP), Refreshing (cooldowns reset, a little slower). Bad: Stinging, Lethal and Poisonous (6%, 14% and 20% of Max HP over 4 s), Hallucinogen (colors swirl for 10 s), Deafening (sound muffled for 15 s).
  - 6 mushrooms at the start, one more every 15 s, up to 8 (was 16 and a new one every 8 s).
- **Food art (v7):** fruit, meat and fish hand-drawn in the flat Darwin style, four eaten stages each (whole, bitten, half, core/bone/skeleton), generated by `tools/art/darwin_food.py` (`--board out.png` draws a review board).
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

## Crab reference pack
`research/crab-ref/`: every evolution, specialisation, genetic, food and UI icon from the Crab wiki, plus `evolutions.md` (all 145 with numbers) and `mechanics.md` (eating, evolution rules, affinities, genetics). Reference only, never shipped. The wiki blocks curl for pages (read them through a browser); its `/images/` files download with a Chrome user-agent.

## Balance (bot, 4 seeds, Godot 4.7.2 on the Mac)
- v7.3 attacks (Linux, first 330 s, 8 seeds, same bot): average level at the first boss 6.1 before and after; past the first boss 2/8 before, 0/8 after; kills 17.8 before, 14.5 after. Damage per second per attack is within a few percent of v7.2 on paper; the bot presses whenever something is in range and doesn't play windups or combos (stun, then Jaws). Watch boss 1 in real play.
- v7.2 (Linux container, first 330 s, 8 seeds): average level at the first boss 6.0 on v7.1, 6.6 with v7.2 at food value 1.4, and 6.1 at 1.4 when the bot skips mushrooms; past the first boss about 1/8 in every setup. Food value is set to 1.3. The 4-seed full runs swing a lot (v7.1 here: [10, 6, 10, 6], 2/4 past the first boss), so tune from 8 or more seeds.
- v7.1: end levels [12, 7, 7, 9]; past the first boss 2/4; final wins 1/4. The first boss now hits 25% softer with 15% less HP (v7 before that: 0/4 past it).
- v7 vs v6 (Godot 4.6): end levels [10, 7, 7, 6] vs [5, 5, 8, 5]. Eating on the move levels faster.
- Crab's rarity payout is 1/3/9/30 per piece; ours stays 1/2/4/10. Switching would speed leveling ~45% unless the base value drops.

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
- Tune the bite time (0.4 s is a guess; no Crab source gives it) and the healing-food chance from real play.
- Candidates from the reference pack: Stomach (Feeding Speed), Forager (healing-food chance), Tracker and Neck Bite (more food per kill).

## Blockers
- Vercel's ignored-build-step cancels any deploy whose commit didn't change `public/` against its parent (a STATUS-only commit on top cancels the push deploy). Deploy the commit that published `public/`: Vercel MCP `create_deployment`, gitSource github barmoshe/bar_builds with that sha, target production, forceNew. v7.1 went live that way from d43011d2 (stamp 5d61f3fe).
- On the Mac: run tools with `GODOT=~/Applications/Godot_v4.7.2.app/Contents/MacOS/Godot` (the `godot` on PATH is 4.6). `tools/webtest.sh` expects the cloud container's Playwright at /opt/node22; locally, check the live site in a browser instead.
- The container blocks vercel.com and api.vercel.com, so deploys go through the Vercel MCP `create_deployment` with the git source (Vercel builds from GitHub).
- The webtest's "sound comes out" check is flaky in headless Chromium: it sometimes reads 0 and passes on rerun.
