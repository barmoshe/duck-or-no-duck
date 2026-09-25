#!/usr/bin/env python3
"""Pixel-art authoring helper for the hand-drawn body rigs.

Each sprite row is a list of (start_col, pixels) segments, so the art is placed
column-exact while it is drawn by hand. The script checks every row, prints an ASCII
preview, and rewrites the "rows" of those bodies in game/scripts/art/sheets/bodies.gd.
Character key: see game/scripts/art/rig.gd.
    python3 tools/art/author.py            (update bodies.gd)
    python3 tools/art/author.py --show     (print the sprites)
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
BODIES = ROOT / "game/scripts/art/sheets/bodies.gd"


def build(rows, width):
    out = []
    for segs in rows:
        line = ["."] * width
        for col, px in segs:
            for i, ch in enumerate(px):
                assert col + i < width, f"row overflows width {width}: {segs}"
                line[col + i] = ch
        out.append("".join(line))
    return out


def R(*segs):
    return list(segs)


SPRITES = {}

# ---------------------------------------------------------------- slime: Puddle hatches
# light from the top left: O light rim, o dark rim, 4 foam, 3 cyan, 2 sea, 1 navy, w specular
SPRITES["slime"] = (22, [
    R((8, "OOO^OO")),
    R((6, "OO334433OO")),
    R((5, "O34ww3=3332O")),
    R((4, "O334w333333*2O")),
    R((3, "O#3433333333322o")),
    R((2, "O2333333333332221o")),
    R((1, "~22333333!333332<11o")),
    R((1, "O122333333333332221o")),
    R((1, "o124332222222222111o")),
    R((1, "o112222333332221111o")),
    R((1, "o1:122334443322/111o")),
    R((2, "oo11122233322211oo")),
    R((4, "oooooooooooooo")),
    R((6, "1"), (15, "1")),
])

# ---------------------------------------------------------------- mochi: the goo firms up
SPRITES["mochi"] = (24, [
    R((9, "OO^OOO")),
    R((7, "OO334433OO")),
    R((5, "O344ww33=3332o")),
    R((4, "O34w43333333322o")),
    R((3, "O#34333333333*322o")),
    R((2, "O233333333333333221o")),
    R((2, "O223333333333322<21o")),
    R((1, "~1222333!333332222211o")),
    R((1, "o12222333333332222211o")),
    R((1, "o11243322222222222111o")),
    R((1, "o11122223333322221111o")),
    R((2, "o1:12234443222/1111o")),
    R((3, "oo11122222221111oo")),
    R((5, "oooooooooooooo")),
])

# ---------------------------------------------------------------- beast: predator / prey form
SPRITES["beast"] = (30, [
    R((21, "oo^o")),
    R((20, "o3443o")),
    R((10, "oooooooooo"), (20, "o34w3*3o")),
    R((7, "ooo3#44=444o"), (19, "o33333333<o")),
    R((5, "oo3333444444433333322222o")),
    R((4, "o33333333333333333332222o")),
    R((3, "~2223333!33333333322222oo")),
    R((3, "o11222223333333222221oo")),
    R((4, "o111122222222222211o")),
    R((5, "oo:111ooooooo111/oo")),
    R((7, "oo"), (17, "oo")),
])

# ---------------------------------------------------------------- chunk: imposing / social form
SPRITES["chunk"] = (26, [
    R((10, "ooo^ooo")),
    R((7, "ooo3344443ooo")),
    R((5, "oo334ww=44444333oo")),
    R((4, "o3334w44444444*433o")),
    R((3, "o#33344444444444433o")),
    R((2, "o2233333333333333333<o")),
    R((2, "o22233333333333333332o")),
    R((1, "~1222233333!33333332222o")),
    R((1, "o112222333333333333222o")),
    R((1, "o1112222334444443332221o")),
    R((1, "o1111222233444443322211o")),
    R((2, "o111112222333332222111o")),
    R((2, "o:11111122222222221/1o")),
    R((3, "ooo1111111111111111oo")),
    R((6, "ooooooooooooooo")),
])

# ---------------------------------------------------------------- bug: trickster form
SPRITES["bug"] = (28, [
    R((22, "^")),
    R((5, "ooooo"), (13, "oooooo"), (20, "ooooooo")),
    R((3, "oo3#444o"), (12, "o44=4444o"), (19, "o33344*o")),
    R((2, "o333444443o"), (12, "o334444443o"), (19, "o3333333<")),
    R((1, "~22333333332o"), (12, "o2333!33333o"), (19, "o2333333o")),
    R((1, "o1222333332o"), (12, "o22233333322o"), (20, "o22222o")),
    R((2, "o11222222o"), (13, "o122222221o"), (21, "ooooo")),
    R((3, "oo1111oo"), (14, "oo11111oo")),
    R((5, ":"), (17, "/")),
])

# ---------------------------------------------------------------- duck: the mallard
SPRITES["duck"] = (27, [
    R((16, "ooo^o")),
    R((14, "ooGGGGGo")),
    R((13, "oGgGGGGGGo")),
    R((13, "oGGGGGG*GGo")),
    R((13, "oGGGGGGGGG<")),
    R((14, "oGGGGGGGo")),
    R((14, "owwwwwwwo")),
    R((8, "ooooooo44444o")),
    R((5, "ooo3#344=444444o")),
    R((3, "oo3333334444444443o")),
    R((2, "o22333333333333333333o")),
    R((1, "~122233333!333333333o")),
    R((1, "o1122222333sssssssss3o")),
    R((2, "o11122222sssssssssso")),
    R((3, "oo111122sssssssss2o")),
    R((5, "oo:11111111/11oo")),
    R((7, "oooooooooooo")),
])


def main():
    text = BODIES.read_text()
    for name, (width, rows) in SPRITES.items():
        lines = build(rows, width)
        if "--show" in sys.argv:
            print(f"--- {name}")
            print("\n".join(lines))
        body = ",\n".join(f'\t\t\t"{ln}"' for ln in lines)
        pat = re.compile(r'(\t"%s": \{.*?"rows": \[\n)(.*?)(\n\t\t\]\},)' % re.escape(name), re.S)
        m = pat.search(text)
        assert m, f"body {name} not found in bodies.gd"
        text = text[:m.start(2)] + body + "," + text[m.end(2):]
    BODIES.write_text(text)
    print("bodies.gd updated:", ", ".join(SPRITES))


if __name__ == "__main__":
    main()
