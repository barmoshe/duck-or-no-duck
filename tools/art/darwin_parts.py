# Hand-drawn parts for Puddle (Darwin style). Each: frames (list of row lists), anchor
# (part pixel that sits on the body anchor), at (body anchor), layer (back|front).
def pair(left, gap):
    # mirror a left-side sprite to make a symmetric pair with a gap between
    w = max(len(r) for r in left)
    rows = []
    for r in left:
        r = r.ljust(w, '.')
        rows.append(r + '.' * gap + r[::-1])
    return rows

P = {}
def part(id_, frames, anchor, at, layer):
    if isinstance(frames[0], str):
        frames = [frames]
    P[id_] = {"frames": frames, "anchor": anchor, "at": at, "layer": layer}

# ---------------- crowns (top of the head)
goat = ["kk..", "khk.", "kHdk", "kHdk", ".kHdk", ".kHdk", "..kdk", "..kk."]
g = pair(goat, 3)
part("horns", g, (6, 6), "top", "back")
ram = ["..kkk..", ".kHhHk.", "kHdkdHk", "kHk.kHk", "kdk.kk.", ".kHk...", "..kk..."]
part("horns_ram", pair(ram, 1), (7, 6), "top", "back")
ant = [".kkk.", "kmsmk", "kmmmk", ".kkk.", "..k..", "..k..", "...k."]
part("antennae", pair(ant, 1), (5, 6), "top", "back")
ears = [".kk.", "kFfk", "kFfk", "kFfk", "kFfk", ".kFk", ".kFk"]
part("ears", pair(ears, 2), (5, 6), "top", "back")
antl = [".k.k.k....", "kdkdkdk...", "kddddddk..", ".kHddddk..", "..kkkHddk.", "......kddk", ".......kk."]
part("antlers", pair(antl, 2), (11, 5), "top", "back")
crest = ["..k.k...", ".kykyk..", "kyYkYk..", ".kYYk...", "..kk...."]
part("crest", crest, (3, 4), "top", "back")
part("crest_duck", ["..kk..", ".kGgk.", "kGgGk.", ".kGk.."], (3, 3), "top", "back")
frill = ["k.k.k.k.k", "kokokokok", "kOoOoOoOk", ".kOOOOOk.", "..kkkkk.."]
part("frill", frill, (4, 4), "top", "back")
mane = ["..k..k..k..", ".kYkkYkkYk.", "kYOYkYOYkYk", "kOOOOOOOOOk", ".kkkkkkkkk."]
part("mane", mane, (5, 4), "top", "back")
gog = ["kkkkk.kkkkk", "knnnnknnnnk", "kneenknneek", "knnnnknnnnk", "kkkkkkkkkkk", "...k...k..."]
part("stalks", gog, (5, 5), "top", "front")

# ---------------- back (left flank)
shell = ["..kkkk..", ".kgygGk.", "kgGGjGGk", "kyGjjjGk", "kgGjGjGk", "kGjGGGjk", "kyGjjjGk", "kgGGjGGk", ".kgyGGk.", "..kkkk.."]
part("shell", shell, (6, 5), "back", "front")
part("shell_big", ["..kkkkk..", ".kgyyGGk.", "kgGGjGGGk", "kyGjjjjGk", "kgGjGGjGk", "kGjGyGjGk", "kGjGGGjGk", "kyGjjjjGk", "kgGGjGGGk", ".kgyGGGk.", "..kkkkk.."], (7, 5), "back", "front")
wing_up = ["......kk.", "....kkwwk", "..kkwwwsk", ".kwwwwssk", "kwwwssSk.", "kwsSkSk..", ".kSkkk...", "..k......"]
wing_dn = [".........", ".........", "....kkkk.", "..kkwwwwk", ".kwwwwssk", "kwwwssSk.", "kwsSkSk..", ".kkkkk..."]
part("wings_bird", [wing_up, wing_dn], (7, 6), "back", "back")
dwing_up = ["......kk.", "....kkqqk", "..kkqqqHk", ".kqqqqHHk", "kqqqHHuk.", "kqHuktk..", ".kHkkk...", "..k......"]
dwing_dn = [".........", ".........", "....kkkk.", "..kkqqqqk", ".kqqqqHHk", "kqqqHHuk.", "kqHuktk..", ".kkkkk..."]
part("wings_duck", [dwing_up, dwing_dn], (7, 6), "back", "back")
big_up = ["........kk..", "......kkwwk.", "....kkwwwwk.", "..kkwwwwssk.", ".kwwwwwssSk.", "kwwwwssSSk..", "kwwsSSkSk...", "kwsSkkSk....", ".kSk.kk.....", "..k........."]
big_dn = ["............", "............", "............", "......kkkkk.", "...kkkwwwwsk", "..kwwwwwssSk", ".kwwwwssSSk.", "kwwwssSSkk..", "kwsSkSSk....", ".kkk.kk....."]
part("wings_big", [big_up, big_dn], (10, 8), "back", "back")
bug_up = ["..kkk....", ".kwtwk...", "kwwtwwk..", "kwtwtwk..", ".kwwwk...", "..kkk...."]
bug_dn = [".........", ".kkkk....", "kwtwtwk..", "kwwtwwwk.", ".kkkkkk..", "........."]
part("wings_bug", [bug_up, bug_dn], (6, 4), "back", "back")
part("wings_bee", [bug_up, bug_dn], (6, 4), "back", "back")
spines = ["..k...k...k", ".ksk.ksk.ks", "kssk.kssk.k", "kSSk.kSSk..", ".kk...kk..."]
part("spines", spines, (8, 4), "top", "back")
plating = ["..kkkkkk..", ".klslslsk.", "klSlSlSlk.", ".kkkkkkk.."]
part("plating", plating, (1, 1), "back", "front")
fin = ["....k..", "...kBk.", "..kBBk.", ".kBbBk.", "kBBbBk.", "kkkkkk."]
part("fin", fin, (4, 5), "back", "back")

# ---------------- tails (lower left, behind)
tail_long = [["kk......", "kBk.....", ".kBkk...", "..kBBkkk", "...kkBBB"], ["........", "kkk.....", "kBBkk...", ".kkBBkkk", "...kkBBB"]]
part("long", tail_long, (7, 4), "tail", "back")
part("serpent", [["kk.........", "kBk..kkk...", ".kBkkBBBkk.", "..kBBkkkBBk", "...kk...kBB"], ["...........", "kkk..kk....", "kBBkkBBkk..", ".kkBBkkBBkk", "....kk..kBB"]], (10, 4), "tail", "back")
part("whip", [["k.......", "kk......", ".kk.....", "..kkkk..", "....kkBB"]], (7, 4), "tail", "back")
part("stinger", [["..kkk...", ".kvvRk..", ".kvkkBk.", "..k.kBk.", "....kBk.", "...kBBk.", "..kBBk.."]], (5, 6), "tail", "back")
part("fluffy", [[".kkkk...", "kwwwwk..", "kwwswwkk", "kwsswwBB", ".kkkkkk."]], (7, 3), "tail", "back")
part("curl", [["..kk....", ".kBBk...", ".kBk.kk.", "..kkkBBk", ".....kBB"]], (7, 4), "tail", "back")
part("feathers", [["kk.kk...", "kwkkwk..", ".kwwwkkk", "..kkkBBB"]], (7, 3), "tail", "back")
part("fin_tail", [["kkk.....", "kttk....", ".kttkkkk", "kttkkBBB", "kkk....."]], (7, 3), "tail", "back")
part("nub", [["kk.", "kBk", ".kB"]], (2, 2), "tail", "back")
part("fan", [["k.k.k...", "kykykk..", ".kyyykkk", "..kkkBBB"]], (7, 3), "tail", "back")

# ---------------- legs (under the body)
part("stubby", [["kBk....kBk.", "kBBk...kBBk", "kkkk...kkkk"], ["kBk....kBk.", "kBBk...kkkk", "kkkk......."], ["kBk....kBk.", "kBBk...kBBk", "kkkk...kkkk"], ["kBk....kBk.", "kkkk...kBBk", ".......kkkk"]], (4, 0), "feet", "back")
part("long", None, None, None, None) if False else None
legs_long = [["kBk....kBk", "kBk....kBk", "kBk....kBk", "kBBk...kBBk", "kkkk...kkkk"],
	["kBk....kBk", "kBk....kBk", ".kBk..kBk.", ".kBBk.kBBk", ".kkkk.kkkk"],
	["kBk....kBk", "kBk....kBk", "kBk....kBk", "kBBk...kBBk", "kkkk...kkkk"],
	["kBk....kBk", "kBk....kBk", "kBk..kBk..", "kBBk.kBBk.", "kkkk.kkkk."]]
P["legs_long"] = {"frames": legs_long, "anchor": (4, 0), "at": "feet", "layer": "back"}
part("webbed", [["kok....kok.", "kOok..kOook", "kkkkk.kkkkk"], ["kok....kok.", "kOok...kkk.", "kkkkk......"], ["kok....kok.", "kOok..kOook", "kkkkk.kkkkk"], ["kok....kok.", "kkk...kOook", "......kkkkk"]], (4, 0), "feet", "back")
part("bug", [[".k.k.k.k.k.", "k.k.k.k.k.k", "k.k.k.k.k.k"], ["k.k.k.k.k.k", ".k.k.k.k.k.", "k.k.k.k.k.k"]], (5, 0), "feet", "back")
part("crab", [[".k.k.k.k.k.k", "k.k.k.k.k.k.", "kk.kk.kk.kk."], ["k.k.k.k.k.k.", ".k.k.k.k.k.k", ".kk.kk.kk.kk"]], (6, 0), "feet", "back")
part("frog", [["kBBk....kBBk", "kBBBk..kBBBk", "kkkkk..kkkkk"], ["kBBk....kBBk", ".kBBk..kBBk.", "..kkkk.kkkk."]], (5, 0), "feet", "back")
part("stilts", [["ko....ko", "ko....ko", "ko....ko", "ko....ko", "ko....ko", "koo...koo", "kkk...kkk"], ["ko....ko", "ko....ko", ".ko..ko.", ".ko..ko.", ".ko..ko.", ".koo.koo", ".kkk.kkk"]], (3, 0), "feet", "back")
part("cilia", [["k.k.k.k.k.k.k", ".k.k.k.k.k.k."], [".k.k.k.k.k.k.", "k.k.k.k.k.k.k"]], (6, 0), "feet", "back")
part("legs_tall", legs_long, (4, 0), "feet", "back")

# ---------------- arms
claw = [["..kkk..", ".kpprk.", "kprrkkk", "krrk.kk", "krrkkrk", ".krrrRk", "..kkkk."], ["..kkk..", ".kpprk.", "kprrkkk", "krrrrrk", ".krrrRk", "..kkkk.", "......."]]
part("claws", claw, (0, 4), "arm", "front")
part("claws_big", [["...kkkk..", "..kpprrk.", ".kprrkkk.", "kprrk..kk", "krrk..krk", "krrkkkrrk", ".krrrrRk.", "..kkkkk.."], ["...kkkk..", "..kpprrk.", ".kprrrrkk", "kprrrrrrk", "krrrrrRk.", ".krrrRk..", "..kkkk...", "........."]], (0, 5), "arm", "front")
tent = [["kPpk.kPpk.kPpk", "kPpk.kPpk.kPpk", ".kPk..kPk.kPk.", ".kPpk.kPpkkPk.", "..kk...kk..kk."], ["kPpk.kPpk.kPpk", "kPpk.kPpk.kPpk", "kPk.kPk..kPk..", "kPpkkPpk.kPpk.", ".kk..kk...kk.."]]
part("tentacles", tent, (7, 0), "feet", "back")
part("tentacles_big", tent, (7, 0), "feet", "back")

# ---------------- mouths (the right of the face)
part("bill", [["kkkk..", "kYYYkk", "kOOOOk", ".kkkk."], ["kkkk..", "kYYYkk", "kkkkkk", "kOOOOk", ".kkkk."]], (0, 1), "face", "front")
part("beak", [["kkk...", "kYYkk.", "kOOOYk", ".kkkk."], ["kkkk..", "kYYYk.", "kkkkkk", "kOOOk.", ".kkk.."]], (0, 1), "face", "front")
part("snout", [["kkk.", "FFFk", "FFek", "kkk."]], (0, 1), "face", "front")
part("mandibles", [["kk..", ".kdk", "..k.", ".kdk", "kk.."], ["kkk.", "..kdk", "....", "..kdk", "kkk."]], (0, 2), "face", "front")
part("pincers", [["kk..", ".krk", "..k.", ".krk", "kk.."]], (0, 2), "face", "front")
part("sucker", [["kk.", "kPk", "kk."]], (0, 1), "face", "front")

# ---------------- cheeks (Cheek Pouch): a puffed cheek with a blush, low on the face
part("cheeks", [["..kkk..", ".kFFFFk", "kFFFPPk", "kFFFFFk", ".kfFFfk", "..kkkk."]], (3, 0), "face", "front")

import json
open('/tmp/claude-0/-home-user-bar-builds/f444614b-f2b3-55c1-a1f3-5f7f9598ded7/scratchpad/dparts.json','w').write(json.dumps(P))
out = ['class_name DarwinParts', 'extends RefCounted', '## Hand-drawn parts for Puddle (Darwin style), generated from tools/art/darwin_parts.py.',
 '## frames: rows per frame; anchor: the part pixel placed on the body anchor "at";', '## layer: back (behind the body) or front.', '', 'const ALL := {']
for k, v in P.items():
    fr = ", ".join("[" + ", ".join('"%s"' % r for r in f) + "]" for f in v["frames"])
    out.append('\t"%s": {"anchor": Vector2i(%d, %d), "at": "%s", "layer": "%s", "frames": [%s]},' % (k, v["anchor"][0], v["anchor"][1], v["at"], v["layer"], fr))
out.append('}')
open('/home/user/bar_builds/lab/duck-or-no-duck/game/scripts/art/darwin/parts.gd', 'w').write("\n".join(out) + "\n")
print(len(P))
