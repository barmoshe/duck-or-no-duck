# Duck or no duck ?! — STATUS

- Updated: 2026-09-25

## Where we are
v0.1 MVP playable end to end (headless tests + a browser webtest pass):
- Crab's loop: forage and kill, eat for XP, level up into 3 evolution cards (rarity, Mutagen reroll/upgrade), 5 affinities plus the hidden duck affinity, 71 evolutions.
- **Evolution Graphics System**: hand-drawn body rigs with socket markers plus hand-drawn parts per slot, composed per frame. Puddle hatches as a slime, firms into mochi, then metamorphoses into an affinity body (beast, chunk, bug, mallard).
- Open world: 4 terrains (grass, lake, sand, snow), a forest edge, beaches, burrows, mushrooms, 12 POI kinds, weather, day/night with a night vision circle.
- 26 species (prey, predator, hybrid, scavenger, mimic, Alphas) on 9 animal rigs.
- A timer bar with 3 random bosses from a pool of 5 plus the Great Mallard with Breadfall; arena, give-up clock, Boss Fruit.
- Meta: Genetics (7), Selective Pressure 0-5, Codex. Synth audio with day, night and boss music.

## Next action
- Deploy: the Vercel project serves public/ (git-linked); verify the live URL with tools/webtest.sh <url>.
- Playtest on a phone; tune the first boss (the test bot dies at it) and early XP.

## Blockers
- This container's network policy blocks vercel.com / api.vercel.com, so the Vercel CLI can't deploy from here; deploys go through the git-linked project (Vercel builds from GitHub).
