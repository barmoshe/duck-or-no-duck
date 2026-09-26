# Hand-drawn animals and bosses in the Darwin style (flat fills, 1 px ink outline, dot
# eyes), side view facing right.  python3 tools/art/darwin_animals.py
# regenerates game/scripts/art/darwin/animals.gd.
#
# Each species: rows (the body, legs excluded), legs (walk frames stamped at legs_at, the
# ground is their bottom row), alt (optional second body for the walk: a tail flick, a
# wing beat), eyes (blinks), mouth (opens on the bite), squash (the row the idle squash
# removes), recolor (body chars -> Pal color names; B body, b shade, F belly/light, f
# light shade), zoom (the final boss is shown at 2x: a giant). Any other char is a
# DarwinArt.KEY color.
import os

A = {}


def sp(id_, rows, eyes, mouth, legs=None, legs_at=(0, 0), alt=None, recolor=None, squash=None, zoom=1):
    A[id_] = {"rows": rows, "eyes": eyes, "mouth": mouth, "legs": legs or [], "legs_at": legs_at,
              "alt": alt or [], "recolor": recolor or {}, "squash": squash if squash is not None else len(rows) // 2,
              "zoom": zoom}


# stubby feet for small quadrupeds (ink pads that shuffle)
def feet(n_left, n_right, w=2):
    a = "." * n_left + "k" * w + "." * (n_right - n_left - w) + "k" * w
    b = "." * (n_left + 1) + "k" * w + "." * (n_right - n_left - w - 2) + "k" * w
    return [[a], [b]]


def legs2(x1, x2, h, ch="B"):
    # two body-colored legs of height h with ink outline, stepping
    rest, step = [], []
    for i in range(h):
        rest.append(" " * 0 + "." * x1 + "k" + ch + "k" + "." * (x2 - x1 - 3) + "k" + ch + "k")
        off = 1 if i >= h // 2 else 0
        step.append("." * (x1 + off) + "k" + ch + "k" + "." * (x2 - x1 - 3 - 2 * off) + "k" + ch + "k")
    rest.append("." * x1 + "kkk" + "." * (x2 - x1 - 3) + "kkk")
    step.append("." * (x1 + 1) + "kkk" + "." * (x2 - x1 - 5) + "kkk")
    return [rest, step]


def bug_legs(x, n):
    a = "".join(".k." for _ in range(n))
    b = "".join("k.k" for _ in range(n))
    return [["." * x + a, "." * x + b], ["." * x + b, "." * x + a]]


# ============================================================== grass
sp("beetle", [
    "............k.k",
    ".....kkkk....k.",
    "...kkgyGGk..kk.",
    "..kgGGGGjGkkjjk",
    ".kgGGGGjGGkjjwjk",
    ".kGGGGjGGGkjjjjk",
    ".kjGGjGGGjkjjjk.",
    "..kkkkkkkkkkkk..",
], [], (14, 5), bug_legs(2, 4), (1, 8))

sp("snail", [
    "...........kw.kw",
    "....kkkk....k..k",
    "..kkCCCCkk..k..k",
    ".kCChkkhCCk.kFFk",
    ".kChkCCkhCk.kFFFk",
    ".kCkCkkCkCkkFFFFk",
    ".kCkChhhkCkFFFFk.",
    ".kCCkkkkCkFFFFFk.",
    "kFkkCCCCkFFFFFk..",
    "kFFFkkkkFFFFFk...",
    ".kkkkkkkkkkkk....",
], [], (15, 6), alt=[
    "...........kw.kw",
    "....kkkk....k..k",
    "..kkCCCCkk..k..k",
    ".kCChkkhCCk.kFFk",
    ".kChkCCkhCk.kFFFk",
    ".kCkCkkCkCkkFFFFk",
    ".kCkChhhkCkFFFFFk",
    ".kCCkkkkCkFFFFFFk",
    "kFkkCCCCkFFFFFFk.",
    "kFFFkkkkFFFFFFk..",
    ".kkkkkkkkkkkkk...",
], recolor={"F": "sand", "f": "tan"})

sp("pilfermouse", [
    "..........kk....",
    ".........kPpk...",
    "....kkkkkkPPk...",
    "...kFBBBBkkBkk..",
    "..kBBBBBBBBBekk.",
    ".kBBBBBBBBBBBBPk",
    "kkBBBBBBBBBBBkk.",
    "k.kbbFFFFFbbk...",
    ".k.kkkkkkkkk....",
], [(12, 4)], (14, 6), feet(3, 9), (0, 9), recolor={"B": "slate", "b": "steel", "F": "mist"})

sp("frog", [
    "........kkkk...",
    ".......kwweek..",
    "...kkkkkweeeGk.",
    "..kGGgGGkkkGGGk",
    ".kGgGGGGGGGGGGk",
    "kGGGGGgGGGkkkkk",
    "kGgGGGGGGyyyyk.",
    "kjGGGGGGyyyyk..",
    ".kjjkkjjkkkk...",
    "..kk..kk.......",
], [], (13, 5), [[".kjGk....kGk", ".kkkkk...kkk"], ["kjGGk....kGk", "kkkkk.....kkk"]], (0, 9), squash=4)

sp("fox", [
    "..............k..k.",
    ".............kOkkOk",
    "....kk......kOOOOOk",
    "..kkwwk....kOOOwOek",
    ".kwwwwk...kOOOOOOOkkk",
    "kwwwwOOkkkkOOOOOOnnnk",
    "kwwwOOOOOOOOOOOOOnnkk",
    ".kkOOOOOOOOOOOOOkkk..",
    "...kOOOOOOOOOOOOk....",
    "...knnOOOOOOOnnk.....",
    "....kkkkkkkkkkk......",
], [(16, 3)], (19, 6), legs2(4, 13, 3, "O"), (0, 11), squash=6)

sp("spineapple", [
    ".....k.k.k.....",
    "....kgkgkgk....",
    ".....kGkGk.....",
    "...kkkkkkkkk...",
    "..kYyYyYyYyYk..",
    ".kyYYkYYYkYYyk.",
    ".kYYkyYYkyYYYk.",
    "kYyYYYYyYYYyYYk",
    "kYYYkYYYYkYYYYk",
    "kYYkyYYYkyYYYYk",
    ".kYYYYyYYYYYYk.",
    "..kkkkkkkkkkk..",
], [], (13, 8), feet(3, 10), (0, 12), recolor={}, squash=7)

sp("capybara", [
    "................kk.",
    "...kkkkkkkkkkkkkaak",
    "..kaaaaaaaaaaaaaaaak",
    ".kaaaaaaaaaaaaaaaeaak",
    "kaaaaaaaaaaaaaaaaaaaak",
    "kaaaaaaaaaaaaaaaaaaaak",
    "kHaaaaaaaaaaaaaaaaakkk",
    ".kHHaaaaaaaaaaaaaaHk..",
    "..kkkkkkkkkkkkkkkkk...",
], [(17, 3)], (21, 5), legs2(3, 15, 2, "H"), (0, 9))

# ============================================================== lake
sp("tadpole", [
    ".....kkkk.",
    "k...kmmmmk",
    "kk.kmmmmwek",
    "kxkkmmmmmmk",
    "kk.kmmmmmk.",
    "k...kkkkk..",
], [(9, 2)], (10, 3), alt=[
    ".....kkkk.",
    "....kmmmmk",
    "kkkkmmmmwek",
    ".kxxmmmmmmk",
    "kkkkmmmmmk.",
    ".....kkkk..",
])

sp("minnow", [
    "........kk.....",
    "......kkuukk...",
    "k...kkuuuuuukk.",
    "kk.kuuuuuuuwek.",
    "kukuuuuuuuuuuuk",
    "kk.kwwwwwwwwwk.",
    "k...kkkkkkkkk..",
], [(12, 3)], (14, 4), alt=[
    "........kk.....",
    "......kkuukk...",
    "....kkuuuuuukk.",
    "kkkkuuuuuuuwek.",
    ".kuuuuuuuuuuuuk",
    "kkkkwwwwwwwwwk.",
    "....kkkkkkkkk..",
])

sp("newt", [
    ".......kkkkkk....",
    "......koooooookk.",
    "..kkkkoOooOoooeok",
    ".kookooooooooooook",
    "kk..kyyyyyyyyyykk.",
    "k....kkkkkkkkkk...",
], [(14, 2)], (17, 3), feet(6, 13), (0, 6), alt=[
    ".......kkkkkk....",
    "......koooooookk.",
    "k.kkkkoOooOoooeok",
    "kkookooooooooooook",
    "....kyyyyyyyyyykk.",
    ".....kkkkkkkkkk...",
])

sp("dragonfly", [
    "......kkk.kkk....",
    ".....kwwwkwwwk...",
    "....kwwtwkwtwwk..",
    ".....kkkkkkkkkkk.",
    "kkkkkkkkkkkkkttek",
    "kTTTTTTTTTTTkttkk",
    "kkkkkkkkkkkkkkk..",
], [(15, 4)], (16, 5), alt=[
    ".................",
    ".................",
    "...kkkkkkkkkkk...",
    "..kwwtwwkwwtwwk..",
    "kkkkkkkkkkkkkttek",
    "kTTTTTTTTTTTkttkk",
    "kkkkkkkkkkkkkkk..",
], squash=4)

sp("pike", [
    "..........kkk..........",
    "........kkEEEkk........",
    "k.....kkEEEEEEEkkkk....",
    "kk..kkEEEEEEEEEEEEEkkk.",
    "kEkkEEEjEEjEEEjEEEwekk.",
    "kEEEEjEEEjEEEjEEEEEEEEk",
    "kEkkAAAAAAAAAAAAAAkwkwk",
    "kk..kkAAAAAAAAAAAAAkkk.",
    "k.....kkkkkkkkkkkkk....",
], [(19, 4)], (22, 6), alt=[
    "..........kkk..........",
    "........kkEEEkk........",
    "......kkEEEEEEEkkkk....",
    "kkkkkkEEEEEEEEEEEEEkkk.",
    ".kEEEEEjEEjEEEjEEEwekk.",
    "..kEEjEEEjEEEjEEEEEEEEk",
    ".kEkAAAAAAAAAAAAAAkwkwk",
    "kkkkkkAAAAAAAAAAAAAkkk.",
    "......kkkkkkkkkkkkk....",
])

sp("heron", [
    "..........kkk....",
    ".........kssskk..",
    "..........kswekkk",
    "...........kssYYYk",
    "...........kssk.kk",
    "...........kssk...",
    "....kkkkkkkkssk...",
    "..kkSSsssssssk....",
    "kkSSSSSsssssssk...",
    ".kkSSSSSssssssk...",
    "...kkkkkkkkkkk....",
], [(12, 2)], (15, 3), [[".....ko..ko", ".....ko..ko", ".....ko..ko", ".....ko..ko", "....kkk.kkk"],
                         [".....ko..ko", ".....ko.ko.", "......koko.", "......koko.", ".....kkkkk."]], (0, 11), squash=8)

# ============================================================== sand
sp("crab", [
    "..kkk........kkk..",
    ".krrrk......krrrk.",
    ".krkrk.k..k.krkrk.",
    "..kkrk.k..k.krkk..",
    "....kk.e..e.kk....",
    "...kkkkkkkkkkkk...",
    "..krrprrrrrrrrrk..",
    ".krrrrrrrrrrrrrrk.",
    ".kRrrrrrrrrrrrrRk.",
    "..kRRRRRRRRRRRRk..",
    "...kkkkkkkkkkkk...",
], [(7, 4), (10, 4)], (9, 8), [["..k.k.k....k.k.k", ".k.k.k......k.k.k"], [".k.k.k....k.k.k.", "..k.k.k....k.k.k"]], (0, 11), squash=7)

sp("scarab", [
    ".............kk",
    "............kdk",
    "....kkkkk..kdk.",
    "..kkhnhhhk.kdk.",
    ".khnhhhhHhkkdHk",
    "kHhhhhHhhhkHHwHk",
    "kHhhhHhhhHkHHHHk",
    ".kHHHhhhHHkHHHk.",
    "..kkkkkkkkkkkk..",
], [], (15, 6), bug_legs(2, 4), (1, 9))

sp("gull", [
    ".............kkk..",
    "............kwwwk.",
    "............kwwekk",
    "............kwwwYYk",
    "....kkkkkkkkwwwkkk",
    "..kkssssswwwwwwk..",
    "kksSSsssswwwwwwk..",
    "kmmkSSSsswwwwwk...",
    ".kkkkkkkkkkkkk....",
], [(14, 2)], (17, 3), [[".....kok..kok", ".....koo..koo"], ["......kok.kok.", "......koo.koo."]], (0, 9), alt=[
    ".............kkk..",
    "......kk....kwwwk.",
    ".....ksk....kwwekk",
    "....kssk....kwwwYYk",
    "...kssskkkkkwwwkkk",
    "..kkssswwwwwwwwk..",
    "kksSSsssswwwwwwk..",
    "kmmkSSSsswwwwwk...",
    ".kkkkkkkkkkkkk....",
], squash=6)

sp("tortoise", [
    ".....kkkkkk.......",
    "...kkEjEEjEkk.....",
    "..kEjjEEEEjjEk.kk.",
    ".kEEjEEjjEEjEEkgggk",
    ".kjEEjjEEjjEEjkggek",
    "kjjjjjjjjjjjjjjkggk",
    "kCCCCCCCCCCCCCCkkk.",
    ".kkkkkkkkkkkkkkk...",
], [(17, 4)], (18, 5), [["..kgk.....kgk", "..kkk.....kkk"], ["...kgk...kgk.", "...kkk...kkk."]], (0, 8), squash=4)

sp("scorpion", [
    ".kkk..............",
    "kDDvk.............",
    "kvkDk.............",
    ".kkDk.............",
    "...kDk........kk.kk",
    "....kDkkkkkk.kCkkCk",
    ".....kCCCCCCkkCCCCk",
    "....kCaCCaCCaCCeCk.",
    "....kCCCCCCCCCCCCk.",
    ".....kkkkkkkkkkkk..",
], [(15, 7)], (17, 6), bug_legs(5, 4), (0, 10), alt=[
    "..................",
    ".kkk..............",
    "kDDvk.............",
    "kvkDkk............",
    ".kkkDk........kk.kk",
    "....kDkkkkkk.kCkkCk",
    ".....kCCCCCCkkCCCCk",
    "....kCaCCaCCaCCeCk.",
    "....kCCCCCCCCCCCCk.",
    ".....kkkkkkkkkkkk..",
], squash=7)

# ============================================================== snow
sp("hare", [
    "..........kk.kk.",
    ".........kwPkwPk",
    ".........kwPkwPk",
    ".........kwPkwPk",
    "..........kwwwwk",
    "....kkkkkkwwwewk",
    "...kwwwwwwwwwwwPk",
    "kkkwwwwwwwwwwwkk.",
    "kwwkwwwwwwwwwwk..",
    ".kkksswwwwwwssk..",
    "....kkkkkkkkkk...",
], [(13, 5)], (16, 6), legs2(4, 11, 2, "s"), (0, 11), squash=7)

sp("stoat", [
    "..................kk..",
    ".................kwwk.",
    "................kwwwwk",
    "....kkkkkkkkkkkkwwwewkk",
    "..kkwwwwwwwwwwwwwwwwwwmk",
    ".kwwwwwwwwwwwwwwwwwwwkk.",
    "kmkwwwwwwwwwwwwwwwwwk...",
    "kmkkaaaaaaaaaaaaaaakk...",
    ".kk.kkkkkkkkkkkkkkk.....",
], [(19, 3)], (23, 4), feet(5, 16), (0, 9), alt=[
    "..................kk..",
    ".................kwwk.",
    "................kwwwwk",
    ".....kkkkkkkkkkkwwwewkk",
    "...kkwwwwwwwwwwwwwwwwwmk",
    "..kwwwwwwwwwwwwwwwwwwkk.",
    "kkkwwwwwwwwwwwwwwwwwk...",
    "kmmkaaaaaaaaaaaaaaakk...",
    ".kk.kkkkkkkkkkkkkkk.....",
], squash=5)

sp("ice_toad", [
    "........kkkk...",
    ".......kwweek..",
    "...kkkkkweeeuk.",
    "..kuuwuukkkuuuk",
    ".kuwuuuuuuuuuuk",
    "kuuuuuwuuukkkkk",
    "kuwuuuuuuwwwwk.",
    "klluuuuuwwwwk..",
    ".kllkkllkkkk...",
    "..kk..kk.......",
], [], (13, 5), [[".kluk....kuk", ".kkkkk...kkk"], ["kluuk....kuk", "kkkkk.....kkk"]], (0, 9), squash=4)

sp("seal", [
    "...............kkkk..",
    ".............kksssskk",
    "....kkkkkkkkkssssesmk",
    "..kksssSssssSssssskkk",
    ".ksssSssssSssssssssk.",
    "kksssssssssssssssssk.",
    "kSkkwwwwwwwwwwwwkksk.",
    "kk.kkkkkkkkkkkkk.kk..",
], [(17, 2)], (20, 3), alt=[
    "...............kkkk..",
    ".............kksssskk",
    "....kkkkkkkkkssssesmk",
    "..kksssSssssSssssskkk",
    ".ksssSssssSssssssssk.",
    "kksssssssssssssssssk.",
    ".kSkwwwwwwwwwwwwwksk.",
    "..kkkkkkkkkkkkkkkkk..",
])

sp("yeti_crab", [
    "..kkk........kkk..",
    ".kwwwk......kwwwk.",
    ".kwkwk.k..k.kwkwk.",
    "..kkwk.k..k.kwkk..",
    "....kk.e..e.kk....",
    "...kkkkkkkkkkkk...",
    "..kwwswwswwswwwk..",
    ".kwswwwswwwswwswk.",
    ".kswwswwwswwwswsk.",
    "..kssssssssssssk..",
    "...kkkkkkkkkkkk...",
], [(7, 4), (10, 4)], (9, 8), [["..k.k.k....k.k.k", ".k.k.k......k.k.k"], [".k.k.k....k.k.k.", "..k.k.k....k.k.k"]], (0, 11), squash=7)

sp("duckling", [
    "......kkk..",
    ".....kyyyk.",
    ".....kyyekk",
    ".....kyyyook",
    "..kkkkyyykk.",
    ".kyyyyyyyk..",
    "kyYyyyyyyk..",
    "kYYYyyyyk...",
    ".kkkkkkk....",
], [(8, 2)], (10, 3), [["...kok.", "...koo."], ["..kok..", "..koo.."]], (0, 9), squash=4)

# ============================================================== bosses (drawn big)
sp("duckodile", [
    "..........................kkkk....",
    ".......k.k.k.k.k.........kGGGGkk..",
    "......kGkGkGkGkGk.......kGGGGyekk.",
    "...kkkGGGGGGGGGGGkkkkkkkGGGGGGGGkkkkk",
    ".kkGGGGjGGGGjGGGGGGGGGGGGGGGGGGGYYYYYk",
    "kGGGGGjjjGGjjjGGGGjGGGGGGGGGGGGOOOOOOk",
    "kGjGGGGGGGGGGGGGGjjjGGGGGGGGGGGkkkkkk.",
    "kGGGGGGnnnnnnnnnnnnnnnnnnGGGGGk.......",
    ".kkGGnnnnnnnnnnnnnnnnnnnnnnGGk........",
    "...kkkkkkkkkkkkkkkkkkkkkkkkkk.........",
], [(30, 2)], (36, 5), [["....kGGk........kGGk", "....kjjkk.......kjjkk", "....kkkkk.......kkkkk"],
                         [".....kGGk......kGGk.", ".....kjjkk.....kjjkk", ".....kkkkk.....kkkkk"]], (0, 10), alt=[
    "..........................kkkk....",
    ".......k.k.k.k.k.........kGGGGkk..",
    "......kGkGkGkGkGk.......kGGGGyekk.",
    ".kkkkkGGGGGGGGGGGkkkkkkkGGGGGGGGkkkkk",
    "kGGGGGGjGGGGjGGGGGGGGGGGGGGGGGGGYYYYYk",
    ".kGGGGjjjGGjjjGGGGjGGGGGGGGGGGGOOOOOOk",
    "..kjGGGGGGGGGGGGGjjjGGGGGGGGGGGkkkkkk.",
    "..kGGGGnnnnnnnnnnnnnnnnnnGGGGGk.......",
    "...kkGnnnnnnnnnnnnnnnnnnnnnnGGk.......",
    ".....kkkkkkkkkkkkkkkkkkkkkkkk.........",
], squash=5)

sp("quackaconda", [
    "...........................kkkk.....",
    "..........................kGGGGk....",
    ".........................kGGGGGGkk..",
    "........................kGGGGGGyekk.",
    "........................kTTTTTTTTYYYk",
    "........kkkkkkkk.......kTTTTTTTTOOOOk",
    "......kkTTyTTyTTkk.....kTTTTTkkkkkk.",
    "....kkTTyTTyTTyTTTk....kTTTTk.......",
    "..kkTTyTTkkkkkkTyTTk..kTyTTk........",
    ".kTTyTTkk......kTTTTkkTTyTk.........",
    "kTTTTkk.........kTTTTTTyTk..........",
    "kkkkk............kkkkkkkk...........",
], [(30, 3)], (36, 5), alt=[
    "...........................kkkk.....",
    "..........................kGGGGk....",
    ".........................kGGGGGGkk..",
    "........................kGGGGGGyekk.",
    "........................kTTTTTTTTYYYk",
    "...........kkkkkkkk....kTTTTTTTTOOOOk",
    ".........kkTTyTTyTTkk..kTTTTTkkkkkk.",
    ".......kkTTyTTyTTyTTTk.kTTTTk.......",
    "..kkkkkTTyTTkkkkkkTTTTkTyTTk........",
    ".kTTTTTTkk.......kTTTTTTyTk.........",
    "kTTTTkk...........kTTTTyTk..........",
    "kkkkk..............kkkkkk...........",
], squash=8)

sp("mother_goose", [
    ".........................kkkk....",
    "........................kwwwwk...",
    ".......................kwwwwekk..",
    ".......................kwwwwwooOk",
    ".......................kwwwwkkkk.",
    "........................kwwwk....",
    "........................kwwwk....",
    "........................kwwwk....",
    "...........kkkkkkkkkkkkkkwwwk....",
    "........kkksssssssssswwwwwwwk....",
    "......kksSSSssssssssswwwwwwwk....",
    "....kkSSSSSSSsssssssswwwwwwwk....",
    "..kkSSSSSSSSSsssssswwwwwwwwk.....",
    "kkmmmkSSSSSSSssssswwwwwwwwk......",
    ".kkkkkkSSSSSsssswwwwwwwwkk.......",
    ".......kkkkkkkkkkkkkkkkk.........",
], [(27, 2)], (31, 3), [["........kok....kok", "........kok....kok", "......kooo...kooo", "......kkkk...kkkk"],
                         [".........kok..kok.", ".........kok..kok.", "........kooo.kooo.", "........kkkk.kkkk."]], (0, 16), alt=[
    ".........................kkkk....",
    "........................kwwwwk...",
    ".......................kwwwwekk..",
    ".......................kwwwwwooOk",
    "....kk.................kwwwwkkkk.",
    "...ksSk.................kwwwk....",
    "..ksSSk.................kwwwk....",
    ".ksSSsk.................kwwwk....",
    "ksSSsskkkkkkkkkkkkkkkkkkkwwwk....",
    "kSSssskssssssssssswwwwwwwwwk....",
    ".kSsskssssssssssswwwwwwwwwwk....",
    "..kkkkSSSSSsssssswwwwwwwwwwk....",
    "..kkSSSSSSSSSsssswwwwwwwwwk.....",
    "kkmmmkSSSSSSSssswwwwwwwwwk......",
    ".kkkkkkSSSSSsssswwwwwwwwkk.......",
    ".......kkkkkkkkkkkkkkkkk.........",
], squash=11)

sp("shelldrake", [
    "......k...k...k...k.............",
    ".....ksk.ksk.ksk.ksk..........kk",
    "....kkkkkkkkkkkkkkkkkk.......kHk",
    "...kEjEEjEEjEEjEEjEEEEk....kkHk.",
    "..kEjjEEEjEEEjEEEjEEjjEk..kGGGGk",
    ".kEEjEEjjjEEjjjEEjjjEEjEkkGGGyek",
    ".kjEEEjEEEjjEEEjEEEjEEEjkGGGGGGYYk",
    "kjjjjjjjjjjjjjjjjjjjjjjjjkGGGGOOOk",
    "kCCCCCCCCCCCCCCCCCCCCCCCCCkGGkkkk.",
    ".kkkkkkkkkkkkkkkkkkkkkkkkkkkkk....",
], [(30, 5)], (33, 6), [["...kjjk.........kjjk", "...kjjk.........kjjk", "...kkkk.........kkkk"],
                         ["....kjjk.......kjjk.", "....kjjk.......kjjk.", "....kkkk.......kkkk."]], (0, 10), squash=6)

sp("duckaroo", [
    "...................kk.kk.....",
    "..................kOkkOk.....",
    "..................kOkkOk.....",
    ".................kOOOOOOk....",
    ".................kOOOOOeOkk..",
    ".................kOOOOOOOYYYk",
    ".................kOOOOOOOOOOk",
    "..............kkkkOOOOOkkkkk.",
    "............kkOOOOOOOOOOk....",
    "..........kkOOOOOOOOOOOOk....",
    "........kkOOOOOOOOOOOOOOkkk..",
    "......kkOOOOOOOOOOOOOOOOrrrk.",
    "....kkOOOOOOOOnnnnnOOOOkkrk..",
    "..kkOOOOOOOOOnnnnnnnOOOk.k...",
    "kkOOkkOOOOOOnnnnnnnnnOOk.....",
    "kkk..kOOOOOOOnnnnnnnnOk......",
    ".....kkkkkkkkkkkkkkkkk.......",
], [(22, 4)], (27, 6), [["......kOOOk.....kOk", ".....kOOOOk.....kOk", "....kOOOOkkk..kkOOk", "....kkkkkkkk..kkkkk"],
                         [".......kOOk.....kOk.", "......kOOOk....kOk.", "......kOOOkkk.kOOk.", "......kkkkkkk.kkkk."]], (0, 17), squash=10)

sp("great_mallard", [
    "............................kkkk......",
    "...........................kGGGGk.....",
    "..........................kGGGGGGk....",
    "..........................kGGGGyekkk..",
    "..........................kGGGGGGYYYk.",
    "..........................kGGGGGGOOOk.",
    "...........................kwwwwkkkk..",
    ".........kkkkkkkkkkkkkkkkkkkHHHHk.....",
    "......kkkqqqqqqqqqqqqqqqqqqHHHHHk.....",
    "....kkqqHHqqqqqqqqqqqqqqqqHHHHHHk.....",
    "..kkqqHHHHHqqqqqqqqqqqqqqqHHHHHHk.....",
    ".kkkHHHtHHHHHqqqqqqqqqqqqHHHHHHk......",
    "kmkkHHtuHHHHHHqqqqqqqqqqHHHHHHHk......",
    ".kkkkHHtHHHHHHHqqqqqqqqHHHHHHHk.......",
    "....kkHHHHHHHHHHHHHHHHHHHHHHHk........",
    "......kkkkkkkkkkkkkkkkkkkkkk..........",
], [(31, 3)], (36, 5), [["..........kok......kok", "..........kok......kok", "........kooo......kooo", "........kkkk......kkkk"],
                         ["...........kok....kok.", "...........kok....kok.", "..........kooo..kooo..", "..........kkkk..kkkk.."]], (0, 16), squash=10, zoom=2)

# ------------------------------------------------------------------ out
def gd_rows(rows):
    return "[" + ", ".join('"%s"' % r for r in rows) + "]"


out = ['class_name DarwinAnimals', 'extends RefCounted',
       '## Hand-drawn animals and bosses (Darwin style, side view facing right), generated by',
       '## tools/art/darwin_animals.py. See DarwinArt.species_frames.', '', 'const ALL := {']
for k, v in A.items():
    legs = "[" + ", ".join(gd_rows(f) for f in v["legs"]) + "]"
    eyes = "[" + ", ".join("Vector2i(%d, %d)" % e for e in v["eyes"]) + "]"
    rec = "{" + ", ".join('"%s": "%s"' % kv for kv in v["recolor"].items()) + "}"
    out.append('\t"%s": {"rows": %s, "alt": %s, "legs": %s, "legs_at": Vector2i(%d, %d), "eyes": %s, "mouth": Vector2i(%d, %d), "squash": %d, "zoom": %d, "recolor": %s},' % (
        k, gd_rows(v["rows"]), gd_rows(v["alt"]), legs, v["legs_at"][0], v["legs_at"][1], eyes, v["mouth"][0], v["mouth"][1], v["squash"], v["zoom"], rec))
out.append('}')
here = os.path.dirname(os.path.abspath(__file__))
dst = os.path.join(here, '..', '..', 'game', 'scripts', 'art', 'darwin', 'animals.gd')
open(dst, 'w').write("\n".join(out) + "\n")
print(len(A), "species")
