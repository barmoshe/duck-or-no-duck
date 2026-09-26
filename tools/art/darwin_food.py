# Hand-drawn food in the Darwin style (flat fills, 1 px ink outline), after Everything is
# Crab's food: fruit, meat and fish in four rarities shown by color (common green, rare
# blue, epic purple, legendary gold), each in four stages as it's eaten (whole, bitten,
# half gone, core or bones).  python3 tools/art/darwin_food.py [--board out.png]
# regenerates game/scripts/art/darwin/food.gd (and draws a review board with --board).
#
# Shapes are drawn as fills only: the ink outline is added around them. M, N and L are
# the rarity's main, shade and light colors; every other char is a DarwinArt.KEY color.
# Bites are carved out of the whole shape (the cut shows flesh, then the outline); the
# last stage keeps only the core, the bone or the skeleton.
import math
import os
import re
import sys

# rarity -> (L light, M main, N shade) as DarwinArt.KEY chars
RARITY = [
    {"L": "A", "M": "g", "N": "G"},   # common: sprout, leaf, grass
    {"L": "t", "M": "u", "N": "c"},   # rare: cyan, sky, navy
    {"L": "P", "M": "v", "N": "D"},   # epic: rose, grape, plum
    {"L": "y", "M": "Y", "N": "o"},   # legendary: lemon, amber, orange
]

# ---------------------------------------------------------------- fruit, one per rarity
APPLE = [  # common: a round apple, stem and leaf
    ".....d.jg..",
    ".....djgg..",
    "..LMMdMMM..",
    ".LLMMMMMMN.",
    ".LMMMMMMMN.",
    ".MMMMMMMMN.",
    ".MMMMMMMNN.",
    "..MMMMMNN..",
    "...NNNNN...",
]
PLUM = [  # rare: a tall drop-shaped fruit with scale tips
    "......d....",
    ".....dd....",
    "....LMMM...",
    "...LLMMML..",
    "..LLMMMMMN.",
    "..LMMMLMMN.",
    ".LMMMMMMMN.",
    ".MMLMMMMNN.",
    ".MMMMMMMNN.",
    "..MMMMLNN..",
    "...NNNNN...",
]
MANGOSTEEN = [  # epic: a round purple fruit under a crown of leaves
    "....jdj....",
    "..gjgGgjg..",
    ".LMjMGMjMN.",
    ".LLMMMMMMN.",
    ".LMMMMMMMN.",
    ".MMMMMMMNN.",
    ".MMMMMMMNN.",
    "..MMMMMNN..",
    "...NNNNN...",
]
GRAPES = [  # legendary: a bunch of golden grapes
    "......dgj..",
    ".....dGgj..",
    "...LMNLMN..",
    "..LMMNMMNN.",
    "..MMNLMNLN.",
    ".LMNMMNMMN.",
    ".MMNNLMNNN.",
    "..NLMNMMN..",
    "...MMNNNN..",
    "....NLMN...",
    ".....NN....",
]

# ---------------------------------------------------------------- meat and fish
STEAK = [  # common and rare: a round cut in its hide, a bone knob out the side
    "...NMMMN.....",
    "..MLrprrM....",
    ".MLpprrrRM...",
    ".MrprrrrRM.ww",
    ".MrrrrrRRMsww",
    "..MRRRRRMs.w.",
    "...NMMMN.....",
]
HAM = [  # epic and legendary: a big joint on a long bone
    "...NMMMMN.......",
    "..MLLpprrM......",
    ".MLpprrrrRM.....",
    ".MLprrrrrRM.....",
    ".MrrrrrrRRM.....",
    ".MrrrrrRRRMs....",
    "..MRRRRRRMsw....",
    "...NMMMMNsws.ww.",
    ".........swwsww.",
    "............ww..",
]
FISH = [  # common and rare: a small fish, head left
    "....NNN......",
    "..MMMMMMM...N",
    ".MwkMMMMMMMNN",
    "MMkkMMMMMMMN.",
    "MLLLLLMMMMMNN",
    ".LLLLLLLLM..N",
    "...LN........",
]
BIG_FISH = [  # epic and legendary: a big fish with a tall back fin
    ".......NN.......",
    "......NNN.......",
    "..MMMMMMMMMM...N",
    ".MwkMMMMMMMMM.NN",
    "MMkkMMMMMMMMMMN.",
    "MLLLLLLLMMMMMMNN",
    ".LLLLLLLLLLLM..N",
    "...LLLLLLL.N....",
    ".....N..........",
]

# (shape, flesh char under the skin, how it's finished)
FOODS = {
    "fruit": [(APPLE, "n", "core"), (PLUM, "w", "core"), (MANGOSTEEN, "w", "core"), (GRAPES, "q", "stem")],
    "meat": [(STEAK, "p", "bone"), (STEAK, "p", "bone"), (HAM, "p", "bone"), (HAM, "p", "bone")],
    "fish": [(FISH, "p", "bones"), (FISH, "p", "bones"), (BIG_FISH, "p", "bones"), (BIG_FISH, "p", "bones")],
}

# what's left of the meat when it's eaten: a bone with a scrap on it
BONE = [
    ".w......w.",
    "wwwwwwwwsw",
    "wssrRssssw",
    ".s......s.",
]
BIG_BONE = [
    ".ww.......ww.",
    "wwwwwwwwwwwsw",
    "wwsssrRrsssssw",
    ".ss.......ss.",
]

# where the bites come from: fruit from the right, meat from the meaty left (away from
# the bone), fish from its back
BITE_FROM = {"fruit": "right", "meat": "left", "fish": "top"}

PAD = 1  # room for the outline


def grid(rows):
    w = max(len(r) for r in rows) + PAD * 2
    h = len(rows) + PAD * 2
    g = [["."] * w for _ in range(h)]
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            g[y + PAD][x + PAD] = ch
    return g


def filled(g, x, y):
    return 0 <= y < len(g) and 0 <= x < len(g[0]) and g[y][x] != "."


N4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def outline(g):
    out = [r[:] for r in g]
    for y in range(len(g)):
        for x in range(len(g[0])):
            if g[y][x] == "." and any(filled(g, x + dx, y + dy) for dx, dy in N4):
                out[y][x] = "k"
    return out


def carve(g, circles, flesh):
    # cut circles out; the fill along the cut becomes flesh
    cut = set()
    for (cx, cy, r) in circles:
        for y in range(len(g)):
            for x in range(len(g[0])):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r and g[y][x] != ".":
                    cut.add((x, y))
    out = [r[:] for r in g]
    for (x, y) in cut:
        out[y][x] = "."
    for y in range(len(g)):
        for x in range(len(g[0])):
            if out[y][x] != "." and any((x + dx, y + dy) in cut for dx, dy in N4 + [(1, 1), (-1, -1), (1, -1), (-1, 1)]):
                if out[y][x] not in "dwsjgGk":
                    out[y][x] = flesh
    return out


def bbox(g):
    xs = [x for y in range(len(g)) for x in range(len(g[0])) if g[y][x] != "."]
    ys = [y for y in range(len(g)) for x in range(len(g[0])) if g[y][x] != "."]
    return min(xs), min(ys), max(xs), max(ys)


def finish(g, how, flesh):
    # the last bite's leftovers: an apple core, a bare stem, a bone, a fish skeleton
    x0, y0, x1, y1 = bbox(g)
    cx = (x0 + x1) // 2
    out = [["."] * len(g[0]) for _ in g]
    if how == "core":
        top = next(y for y in range(len(g)) if any(g[y][x] not in ".dgGj" for x in range(len(g[0]))))
        for y in range(len(g)):
            for x in range(len(g[0])):
                ch = g[y][x]
                if ch in "dgGj":
                    out[y][x] = ch  # the stem and leaves stay
                elif ch != "." and (y <= top or y == y1):
                    if abs(x - cx) <= 2:
                        out[y][x] = ch  # the skin at the top and the bottom
                elif ch != "." and abs(x - cx) <= 1:
                    out[y][x] = flesh if abs(x - cx) == 0 or y % 3 else "N"
    elif how == "stem":
        # a bare stalk with a few grapes left
        for y in range(len(g)):
            for x in range(len(g[0])):
                if g[y][x] in "dgGj":
                    out[y][x] = g[y][x]
        sx = next(x for y in range(len(g)) for x in range(len(g[0])) if g[y][x] == "d")
        for i, y in enumerate(range(y0 + 2, y1 - 1)):
            out[y][sx - 1 - i // 3] = "d"
        for (x, y) in [(sx - 3, y0 + 4), (sx - 2, y0 + 5), (sx - 4, y0 + 7)]:
            out[y][x] = "M"
            out[y][x + 1] = "N"
    elif how == "bone":
        bone = BIG_BONE if (x1 - x0) > 13 else BONE
        bw = max(len(r) for r in bone)
        ox, oy = (x0 + x1 + 1 - bw) // 2, (y0 + y1 + 1 - len(bone)) // 2
        for y, row in enumerate(bone):
            for x, ch in enumerate(row):
                if ch != "." and 0 <= ox + x < len(g[0]):
                    out[oy + y][ox + x] = ch
    elif how == "bones":
        spine = (y0 + y1) // 2
        for y in range(len(g)):
            for x in range(len(g[0])):
                ch = g[y][x]
                if ch == ".":
                    continue
                if x <= x0 + 2 or x >= x1 - 1:
                    out[y][x] = ch if x >= x1 - 2 else ("s" if ch in "LM" else ch)  # the head, bare
                elif y == spine:
                    out[y][x] = "w"
                elif (x - x0) % 2 == 0 and 0 < abs(y - spine) <= (2 if x1 - x0 > 13 else 1):
                    out[y][x] = "s"
    return out


def stages(shape, flesh, how, side):
    g = grid(shape)
    x0, y0, x1, y1 = bbox(g)
    w, h = x1 - x0 + 1, y1 - y0 + 1
    r1 = max(2.4, min(w, h) * 0.3)
    if side == "left":
        b1 = [(x0 + 0.5, y0 + h * 0.3, r1)]
        b2 = b1 + [(x0 + 0.8, y0 + h * 0.75, r1 * 1.1)]
    elif side == "top":
        b1 = [(x0 + w * 0.55, y0 + 0.5, r1 * 1.1)]
        b2 = b1 + [(x0 + w * 0.3, y0 + 1.0, r1 * 1.15)]
    else:
        b1 = [(x1 + 0.5, y0 + h * 0.3, r1)]
        b2 = b1 + [(x1 + 0.2, y0 + h * 0.72, r1 * 1.1)]
    return [outline(g), outline(carve(g, b1, flesh)), outline(carve(g, b2, flesh)), outline(finish(g, how, flesh))]


def recolor(g, rar):
    m = RARITY[rar]
    return ["".join(m.get(ch, ch) for ch in row) for row in g]


def build():
    out = {}
    for type_, per in FOODS.items():
        for rar, (shape, flesh, how) in enumerate(per):
            out["%s_%d" % (type_, rar)] = [recolor(s, rar) for s in stages(shape, flesh, how, BITE_FROM[type_])]
    return out


def gd(foods):
    lines = ["class_name DarwinFood", "extends RefCounted",
             "## Hand-drawn food (Darwin style), generated by tools/art/darwin_food.py: \"<type>_<rarity>\"",
             "## -> four stages as it's eaten (whole, bitten, half gone, core or bones), as",
             "## DarwinArt.KEY rows. Props draws them as food_<type>_<rarity>_<stage>.", "", "const ALL := {"]
    for k, sts in foods.items():
        lines.append('\t"%s": [%s],' % (k, ", ".join("[" + ", ".join('"%s"' % r for r in s) + "]" for s in sts)))
    lines.append("}")
    return "\n".join(lines) + "\n"


def board(foods, path):
    # review board: every food, every stage, at 6x on grass (needs Pillow)
    from PIL import Image
    here = os.path.dirname(os.path.abspath(__file__))
    game = os.path.join(here, "..", "..", "game", "scripts", "art")
    pal = dict(re.findall(r'"(\w+)": "([0-9a-f]{6})"', open(os.path.join(game, "pal.gd")).read()))
    body = open(os.path.join(game, "darwin", "body.gd")).read()
    key_src = body[body.index("const KEY"):body.index("}", body.index("const KEY"))]
    key = dict(re.findall(r'"(\w)": "(\w+)"', key_src))
    cell, s = 20, 6
    rows = list(foods.items())
    img = Image.new("RGB", (cell * 4 * s + s * 4, cell * len(rows) * s), (143, 208, 122))
    for ri, (k, sts) in enumerate(rows):
        for si, st in enumerate(sts):
            ox, oy = si * (cell * s + s), ri * cell * s
            for y, row in enumerate(st):
                for x, ch in enumerate(row):
                    if ch == ".":
                        continue
                    hexc = pal.get(key.get(ch, "ink"), "181425")
                    c = tuple(int(hexc[i:i + 2], 16) for i in (0, 2, 4))
                    for yy in range(s):
                        for xx in range(s):
                            img.putpixel((ox + (x + 2) * s + xx, oy + (y + 2) * s + yy), c)
    img.save(path)
    print("board:", path)


if __name__ == "__main__":
    foods = build()
    here = os.path.dirname(os.path.abspath(__file__))
    dst = os.path.join(here, "..", "..", "game", "scripts", "art", "darwin", "food.gd")
    open(dst, "w").write(gd(foods))
    print(len(foods), "foods x 4 stages")
    if "--board" in sys.argv:
        board(foods, sys.argv[sys.argv.index("--board") + 1])
