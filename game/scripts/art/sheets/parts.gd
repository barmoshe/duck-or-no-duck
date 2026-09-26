class_name PartSheets
extends RefCounted
## Hand-drawn parts per slot (see Rig for the character key). Each part: "frames" (lists
## of rows; limbs have 4 walk frames, wings 2 flap frames, tails 2 wag frames, eyes a
## blink frame), "pivot" (the pixel that sits on the body's socket), optional "ramp"
## ("body" = the body's ramp, else a named ramp) and "accent".

const ALL := {
	# ------------------------------------------------------------------ eyes (pivot = front eye)
	"eye:cute": {"pivot": Vector2i(4, 1), "frames": [
		["kw..kw", "kk..kk", "kk..kk"],
		["......", "kk..kk", "......"]]},
	"eye:dots": {"pivot": Vector2i(0, 0), "frames": [["kw", "kk"], ["..", "kk"]]},
	"eye:beady": {"pivot": Vector2i(0, 0), "frames": [["wk", "kk"], ["..", "kk"]]},
	"eye:big": {"pivot": Vector2i(2, 2), "frames": [
		[".ooo.", "owwwo", "owkko", "owkko", ".ooo."],
		[".ooo.", "o333o", "okkko", "o333o", ".ooo."]]},
	"eye:angry": {"pivot": Vector2i(1, 1), "frames": [["oo..", ".kkw", ".kkk"], ["oo..", "....", ".kkk"]]},
	"eye:compound": {"pivot": Vector2i(1, 1), "frames": [[".uu.", "uTtu", "uuTu", ".uu."]]},
	"eye:stalks": {"pivot": Vector2i(1, 4), "frames": [
		["ww.ww", "wk.wk", ".o..o", ".o..o", ".o.o."],
		["oo.oo", "kk.kk", ".o..o", ".o..o", ".o.o."]]},
	"eye:glow": {"pivot": Vector2i(0, 0), "frames": [["yY", "YY"], ["yY", "YY"]]},
	"eye:many": {"pivot": Vector2i(4, 1), "frames": [
		["kw..kw", "kk..kk", "..kw..", "..kk.."],
		["......", "kk..kk", "......", "..kk.."]]},
	# ------------------------------------------------------------------ mouths (pivot = attach point)
	"mouth:none": {"pivot": Vector2i(0, 0), "frames": [["k.", ".k"]]},
	"mouth:sucker": {"pivot": Vector2i(0, 1), "frames": [[".oo", "o1k", ".oo"], [".oo", "okk", ".oo"]]},
	"mouth:fangs": {"pivot": Vector2i(0, 0), "frames": [["kkkk", "w.w.", "...."], ["kkkk", "wRwR", "kkkk"]]},
	"mouth:mandibles": {"pivot": Vector2i(0, 1), "accent": "",
		"frames": [["xx..", "..xa", "xx.."], ["xxx.", "...x", "xxx."]]},
	"mouth:snout": {"pivot": Vector2i(0, 1), "frames": [[".oo.", "o33k", ".oo."], [".oo.", "o3k.", ".ok."]]},
	"mouth:beak": {"pivot": Vector2i(0, 1), "frames": [
		["YYo...", "yYYYYo", "eeo..."],
		["YYYo..", "y...Yo", "eeeeo."]]},
	"mouth:bill": {"pivot": Vector2i(0, 1), "frames": [
		["YyynYo.", "YYYYYYo", "eeeeeo."],
		["YyynYYo", "......o", "eeeeeeo"]]},
	"mouth:pincers": {"pivot": Vector2i(0, 1), "frames": [["xa.", ".x.", "xa."], ["xa.", "...", "xa."]]},
	# ------------------------------------------------------------------ crowns (pivot = base)
	"crown:none": {"pivot": Vector2i(0, 0), "frames": [["."]]},
	"crown:ears": {"pivot": Vector2i(1, 3), "frames": [[".o.", "o3o", "opo", "o3o"]]},
	"crown:antennae": {"pivot": Vector2i(2, 3), "frames": [["d...d", "x...x", ".x.x.", "..x.."], [".d.d.", ".x.x.", ".x.x.", "..x.."]]},
	"crown:horns": {"pivot": Vector2i(2, 3), "frames": [["s...s", "ss.ss", ".s.s.", ".sss."]]},
	"crown:crest": {"pivot": Vector2i(0, 3), "frames": [["..c.", ".cbc", "cb..", "b..."]]},
	"crown:crest_duck": {"pivot": Vector2i(1, 3), "frames": [["..GG", ".GgG", "GgG.", "GG.."]]},
	"crown:frill": {"pivot": Vector2i(3, 2), "frames": [["a.a.a.a", "bcbcbcb", ".bbbbb."]]},
	# ------------------------------------------------------------------ wings / fins (pivot = shoulder)
	"back:wings_duck": {"pivot": Vector2i(6, 2), "ramp": "duck", "frames": [
		["....ooo.", "..oo334o", ".o33334o", "o3uTu33o", ".oo3333o", "...oooo."],
		[".oo.....", "o33o....", "o333o...", ".o3uTo..", "..o333o.", "...oooo."]]},
	"back:wings_bird": {"pivot": Vector2i(6, 2), "frames": [
		["....ooo.", "..oo334o", ".o33334o", "o3333o3o", ".oo222o.", "...ooo.."],
		[".oo.....", "o33o....", "o333o...", ".o333o..", "..o222o.", "...ooo.."]]},
	"back:wings_bug": {"pivot": Vector2i(5, 3), "frames": [
		["..ss...", ".sttss.", "sttttts", ".sssss."],
		[".s.....", "stts...", "sttts..", ".sss..."]]},
	"back:fin": {"pivot": Vector2i(2, 3), "frames": [["...x", "..xa", ".xab", "xabb"]]},
	# ------------------------------------------------------------------ armor (pivot = top of back)
	"armor:shell": {"pivot": Vector2i(4, 5), "ramp": "coral", "frames": [[
		"..oooo..", ".o3443o.", "o34o334o", "o3o43o3o", "o33oo33o", ".o2332o.", "..oooo.."]]},
	"armor:spines": {"pivot": Vector2i(4, 3), "frames": [[".s...s..", ".ss.ss.s", "sssssssss", "........."]]},
	"armor:plating": {"pivot": Vector2i(4, 2), "ramp": "grey", "frames": [[".oo.oo..", "o44o44o.", "o33o33o."]]},
	# ------------------------------------------------------------------ tails (pivot = root, tail goes left)
	"tail:none": {"pivot": Vector2i(0, 0), "frames": [["."]]},
	"tail:nub": {"pivot": Vector2i(2, 1), "frames": [[".o.", "o33", ".o."]]},
	"tail:long": {"pivot": Vector2i(6, 1), "frames": [
		["oo....o", "3o..oo3", ".oooo.."],
		[".......", "ooo..o3", "..oooo."]]},
	"tail:whip": {"pivot": Vector2i(7, 1), "frames": [
		["o.......", ".o...oo3", "..ooo..."],
		["........", "oo..ooo3", "..oo...."]]},
	"tail:fin": {"pivot": Vector2i(4, 2), "frames": [
		["xx...", "abx..", "abbbx", "abx..", "xx..."],
		[".xx..", ".abx.", "abbbx", ".abx.", ".xx.."]]},
	"tail:stinger": {"pivot": Vector2i(4, 4), "frames": [
		["kk...", "kv3..", ".v33.", "..33.", "...3o"],
		[".kk..", ".kv3.", "..v33", "..33.", "...3o"]]},
	"tail:fluffy": {"pivot": Vector2i(4, 2), "frames": [["..444", ".4444o", "44444o", ".443o."], [".444.", "44444o", "44444o", ".443o."]]},
	"tail:curl": {"pivot": Vector2i(4, 3), "frames": [["kk...", "k.k..", "..kkk", "..kkkk"], [".kk..", "k..k.", "..kkk", "..kkkk"]]},
	"tail:feathers": {"pivot": Vector2i(3, 1), "frames": [["NNNo", "NNNN", "NNo."], [".NNo", "NNNN", ".NNo"]]},
	"tail:fan": {"pivot": Vector2i(3, 2), "frames": [["o...", "33o.", "3333", "33o.", "o..."]]},
	# ------------------------------------------------------------------ limbs (pivot = hip; 4 walk frames)
	"limb:none": {"pivot": Vector2i(0, 0), "frames": [["."]]},
	"limb:cilia": {"pivot": Vector2i(1, 0), "frames": [["o.o", "o.o"], [".o.o", "o.o."], ["o.o", "o.o"], ["o.o.", ".o.o"]]},
	"limb:stubby": {"pivot": Vector2i(0, 0), "frames": [["12", "12", "oo"], [".12", "12.", "oo."], ["12", "12", "oo"], ["12.", ".12", ".oo"]]},
	"limb:long": {"pivot": Vector2i(0, 0), "frames": [
		["2.", "2.", "2.", "2.", "oo"], [".2", ".2", "2.", "2.", "oo."], ["2.", "2.", "2.", "2.", "oo"], ["2.", "2.", ".2", ".2", ".oo"]]},
	"limb:bug": {"pivot": Vector2i(1, 0), "frames": [
		["x.x.", ".x.x", "x.x.", "x..x"], [".x.x", "x.x.", "x.x.", ".x.x"], ["x.x.", ".x.x", "x.x.", "x..x"], ["x.x.", "x.x.", ".x.x", "x..x"]]},
	"limb:frog": {"pivot": Vector2i(3, 0), "frames": [
		[".o22", "o222", "o22.", ".o22", "..oo"], [".o22", "o222", ".o22", "..o2", "..oo"],
		[".o22", "o222", "o22.", ".o22", "..oo"], ["..o2", ".o22", "o22.", "o2..", "oo.."]]},
	"limb:crab": {"pivot": Vector2i(2, 0), "frames": [
		["x.x.x", ".x.x.", "x.x.x", "x.x.x"], [".x.x.", "x.x.x", ".x.x.", "x.x.x"],
		["x.x.x", ".x.x.", "x.x.x", "x.x.x"], ["x.x.x", "x.x.x", ".x.x.", ".x.x."]]},
	"limb:webbed": {"pivot": Vector2i(1, 0), "frames": [
		[".e.", ".e.", "eee"], ["..e", ".e.", "eee"], [".e.", ".e.", "eee"], ["e..", ".e.", ".eee"]]},
	"limb:stilts": {"pivot": Vector2i(1, 0), "frames": [
		[".Y", ".Y", ".Y", ".Y", ".Y", "YYY"], [".Y", ".Y", "Y.", "Y.", "Y.", "YYY"],
		[".Y", ".Y", ".Y", ".Y", ".Y", "YYY"], [".Y", ".Y", "..Y", "..Y", "..Y", ".YYY"]]},
	# ------------------------------------------------------------------ arms (pivot = shoulder)
	"arm:none": {"pivot": Vector2i(0, 0), "frames": [["."]]},
	"arm:claws": {"pivot": Vector2i(0, 2), "frames": [
		["...ooo", "..o334", "oo3333", "..o334", "...ooo"],
		["...oo.", "..o33o", "oo33..", "..o33o", "...oo."]]},
	"arm:tentacles": {"pivot": Vector2i(0, 0), "frames": [["c.", "cc", ".c", "c.", "cc"], [".c", "cc", "c.", ".c", "cc"]]},
	# ------------------------------------------------------------------ branch body plans (bigger, readable parts)
	"back:wings_big": {"pivot": Vector2i(12, 9), "frames": [
		["..........o....", ".........o4o...", "......o.o44o...", ".....o4o443o...", "..o.o44o433o...", ".o4o443o333o.oo", "o44o433o3333o4o", "o43o333o33333o.", ".o3o332o2222o..", "..o2o22o222o...", "...oooooooo...."],
		["...............", "...............", "...............", "......ooooooo..", "...ooo4444444o.", ".oo44o4333333oo", "o4443o33333333o", ".o433o3332222o.", "..o33o3o2o2o2o.", "...oo.o.o.o.o..", "..............."]]},
	"arm:tentacles_big": {"pivot": Vector2i(4, 0), "frames": [
		["vpPPvvpPPvvpPPv", "vpPwvvpPwvvpPwv", ".vpPPvpPPvpPPv.", ".vpwvpwvv.vpwv.", "vpPvvpPv...vpPv", "vpwvvpwv...vpwv", "vPv..vvPv...vPv", "vPv....vPv..vPv", "vPv....vPv.vPv.", ".v......v...v..", "..............."],
		["vpPPvvpPPvvpPPv", "vpPwvvpPwvvpPwv", "vpPPvpPPv..vpPP", "pwvvvpwv...vpwv", "pPv..vpPv..vpPv", "pwv...vpwvvpwv.", "vvPv...vPvvPv..", ".vPv...vPvvPv..", "..vPv.vPv.vPv..", "...v...v...v...", "..............."]]},
	"arm:claws_big": {"pivot": Vector2i(1, 5), "frames": [
		["....oooo...", "...o4443o..", "..o433oo...", ".o4333o....", "o43333o.oo.", "o33332o3o..", ".o2222223o.", "..oooooooo."],
		["...........", "...ooooo...", "..o44443o..", ".o433333oo.", "o433333333o", "o333322222o", ".o2222ooo..", "..oooo....."]]},
	"back:shell_big": {"pivot": Vector2i(6, 6), "ramp": "coral", "frames": [
		["......ooo......", "...ooo444ooo...", "..o444444333o..", ".o44444233333o.", ".o44233233233o.", "o4333232323333o", "o1323333333231o", ".o33323232333o.", ".o13333333331o.", "..o111333111o..", "...ooo111ooo..."]]},
	"tail:serpent": {"pivot": Vector2i(12, 3), "frames": [
		[".......oooo...", "o.....o3333oo.", "4ooooo3222233o", "o333332oooo223", ".ooo22o....oo2", "....oo.......o"],
		["....ooooo.....", "...o33333o....", "ooo3222223oooo", "433oooooo23333", "ooo......o2222", "..........oooo"]]},
	"back:wings_bee": {"pivot": Vector2i(8, 5), "frames": [
		[".ssTwss....", "swTwwTwsss.", "wTwwTwwTwws", "swwTwwTwwTw", ".sswwswwTws", "...ss.ssss.", "..........."],
		["...........", "..sss......", "sswwTsssss.", "TwwTwwTwwTs", "wwTwwTwwTww", "sswwTswTwws", "..sss.ssss."]]},
	"limb:legs_tall": {"pivot": Vector2i(0, 0), "frames": [
		["23", "23", "2.", ".2", ".2", ".2", ".oo"],
		["23", "23", ".2", ".2", "2.", "2.", "oo."],
		["23", "23", "2.", ".2", ".2", ".2", ".oo"],
		["23", "23", "2.", "2.", ".2", ".2", "..oo"]]},
	"crown:horns_ram": {"pivot": Vector2i(5, 4), "frames": [
		[".nnn...nnn.", "nNNNn.nNNNn", "nNnNn.nNnNn", ".nnNn.nNnn.", "...nn.nn..."]]},
	"crown:mane": {"pivot": Vector2i(4, 4), "frames": [
		["..a...a...", ".ab..ab.a.", "abbaabbab.", "bbbbbbbbb.", "cbcbcbcbc."],
		[".a...a....", "ab..ab.a..", "abbaabbab.", "bbbbbbbbb.", "cbcbcbcbc."]]},
	# ------------------------------------------------------------------ hides (pivot = center, masked to body)
	"hide:none": {"pivot": Vector2i(0, 0), "frames": [["."]]},
	"hide:spots": {"pivot": Vector2i(6, 3), "frames": [["..1.....1...", "........11..", ".11..1......", "11.......1..", ".....11.....", "..1.......1."]]},
	"hide:stripes": {"pivot": Vector2i(6, 3), "frames": [["1..1..1..1..", "1..1..1..1..", ".1..1..1..1.", ".1..1..1..1.", "1..1..1..1..", "1..1..1..1.."]]},
	"hide:scales": {"pivot": Vector2i(6, 3), "frames": [["o.o.o.o.o.o.", ".o.o.o.o.o.o", "o.o.o.o.o.o.", ".o.o.o.o.o.o", "o.o.o.o.o.o."]]},
	"hide:down": {"pivot": Vector2i(6, 3), "frames": [["w...w....w..", "..w....w....", "w....w...w..", "...w....w..w", ".w....w....."]]},
	"hide:toxic": {"pivot": Vector2i(6, 3), "frames": [[".g.....g....", "gg.....gg...", "....g.....g.", "...gg....gg.", ".g.....g...."]]},
	"hide:feathers": {"pivot": Vector2i(6, 3), "frames": [["N...N...N...", ".N.N.N.N.N.N", "..N...N...N.", "N...N...N...", ".N.N.N.N.N.N"]]},
	"hide:pattern_none": {"pivot": Vector2i(0, 0), "frames": [["."]]},
}


static func get_part(slot: String, id: String) -> Dictionary:
	return ALL.get(slot + ":" + id, {})
