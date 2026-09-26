# Duck or no duck ?! — local conventions

- Godot 4.7.2 project in game/, everything built in code (main.tscn is a script).
- Pixel art at an integer scale (Game.fit_pixels, short side ~225 px). Nearest filtering, no fractional scaling, no free rotation of sprites.
- Creature art = "living clay" (research/design.md, v4): every creature is a Genome (game/scripts/art/sculpt/genome.gd: from_look, of_run with GROW per evolution + affinity DRIFT + readability caps, of_species with SPECIES touches) drawn by the Sculptor (sculpt/sculptor.gd: smooth-union blobs in 4 layers, cel bevel light, mochi sheen, outlines, pixel face stamps). Anatomy is the facade (frames/genome/key_of/render). Colors only from Pal ramps.
- sim/ and data/ never touch nodes; World emits signals, main.gd opens screens.
- Tools: tools/check.sh (parse), tools/test.sh (logic + bot runs), tools/shot.sh (Xvfb screenshots), tools/build_web.sh, tools/webtest.sh, tools/publish.sh (stages public/ for Vercel).
- Review art with tests/sculpt_board.gd (puddle | animals | bosses) before shipping it.
