# Duck or no duck ?! — local conventions

- Godot 4.7.2 project in game/, everything built in code (main.tscn is a script).
- Pixel art at an integer scale (Game.fit_pixels, short side ~225 px). Nearest filtering, no fractional scaling, no free rotation of sprites.
- Creature art = the Evolution Graphics System (research/design.md): bodies in game/scripts/art/sheets/bodies.gd (Puddle's bodies are authored through tools/art/author.py), parts in sheets/parts.gd, composed by Anatomy + Rig. Colors only from Pal ramps.
- sim/ and data/ never touch nodes; World emits signals, main.gd opens screens.
- Tools: tools/check.sh (parse), tools/test.sh (logic + bot runs), tools/shot.sh (Xvfb screenshots), tools/build_web.sh, tools/webtest.sh, tools/publish.sh (stages public/ for Vercel).
- Review art with tests/hero_sheet.gd and tests/zoom_sheet.gd before shipping it.
