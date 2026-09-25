class_name Props
extends RefCounted
## Pixel sprites for everything that isn't a creature: obstacles, decor, food, pickups,
## points of interest and projectiles. Built once with Px and cached by name.

static var _cache := {}


static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = ImageTexture.create_from_image(image(name))
	return _cache[name]


static func image(name: String) -> Image:
	var p: Px
	match name:
		"tree":
			p = Px.make(28, 34)
			p.rect(12, 22, 4, 10, Pal.c("brown", 1))
			p.circle(14, 14, 11, Pal.c("green", 1))
			p.circle(9, 17, 7, Pal.c("green", 2))
			p.circle(19, 11, 7, Pal.c("green", 2))
			p.circle(13, 9, 6, Pal.c("green", 3))
			for q in [Vector2(8, 12), Vector2(18, 18), Vector2(14, 6)]:
				p.put(int(q.x), int(q.y), Pal.c("green", 4))
		"bush":
			p = Px.make(20, 16)
			p.circle(10, 9, 7, Pal.c("green", 2))
			p.circle(6, 10, 5, Pal.c("green", 1))
			p.circle(13, 7, 4, Pal.c("green", 3))
			p.put(7, 7, Pal.c("red", 2))
			p.put(13, 11, Pal.c("red", 2))
		"stump":
			p = Px.make(16, 14)
			p.rect(3, 4, 10, 8, Pal.c("brown", 1))
			p.ellipse(8, 4, 5, 2, Pal.c("brown", 3))
			p.put(8, 4, Pal.c("brown", 1))
		"rock":
			p = Px.make(22, 18)
			p.ellipse(11, 11, 9, 6, Pal.c("grey", 2))
			p.ellipse(9, 9, 6, 4, Pal.c("grey", 3))
			p.put(13, 12, Pal.c("grey", 1))
		"driftwood":
			p = Px.make(26, 12)
			p.line(3, 8, 22, 4, Pal.c("sandy", 1), 3.0)
			p.line(15, 6, 19, 1, Pal.c("sandy", 1), 1.0)
		"pine":
			p = Px.make(22, 34)
			p.rect(10, 26, 3, 6, Pal.c("brown", 1))
			for k in 3:
				var y0 := 4 + k * 7
				var hw := 4 + k * 3
				p.poly(PackedVector2Array([Vector2(11, y0 - 2), Vector2(11 + hw, y0 + 8), Vector2(11 - hw, y0 + 8)]), Pal.c("teal", 2))
				p.line(11 - hw + 1, y0 + 7, 11 + hw - 1, y0 + 7, Pal.c("snow", 4), 1.0)
			p.put(11, 2, Pal.c("snow", 4))
		"ice_rock":
			p = Px.make(20, 20)
			p.poly(PackedVector2Array([Vector2(4, 17), Vector2(7, 4), Vector2(12, 1), Vector2(16, 8), Vector2(17, 17)]), Pal.c("blue", 3))
			p.line(9, 5, 11, 14, Pal.c("blue", 4), 1.0)
		"reeds":
			p = Px.make(14, 20)
			for k in 4:
				var x := 3 + k * 3
				p.line(x, 19, x + (k - 2) * 0.6, 4 + (k % 2) * 3, Pal.c("green", 2 + k % 2), 1.0)
			p.rect(5, 4, 2, 4, Pal.c("brown", 1))
			p.rect(10, 6, 2, 4, Pal.c("brown", 1))
		"cattail":
			p = Px.make(8, 18)
			p.line(4, 17, 4, 5, Pal.c("green", 2), 1.0)
			p.rect(3, 3, 3, 5, Pal.c("brown", 1))
		"lily":
			p = Px.make(14, 10)
			p.ellipse(7, 5, 6, 4, Pal.c("green", 3))
			p.line(7, 5, 12, 3, Pal.c("green", 1), 1.0)
		"lily_flower":
			p = Px.make(14, 10)
			p.ellipse(7, 5, 6, 4, Pal.c("green", 3))
			p.circle(6, 4, 2, Pal.c("pink", 3))
			p.put(6, 4, Pal.c("gold", 3))
		"ripple":
			p = Px.make(12, 6)
			p.line(1, 3, 5, 2, Pal.c("blue", 3), 1.0)
			p.line(7, 4, 10, 3, Pal.c("blue", 3), 1.0)
			return p.img
		"flowers":
			p = Px.make(10, 8)
			for q in [Vector2(2, 3), Vector2(6, 2), Vector2(4, 6), Vector2(8, 5)]:
				p.put(int(q.x), int(q.y), Pal.c(["gold", "pink", "snow"][int(q.x) % 3], 3))
			return p.img
		"grass", "grass_dry":
			p = Px.make(8, 6)
			var gc := Pal.c("green", 3) if name == "grass" else Pal.c("sandy", 1)
			p.line(2, 5, 1, 1, gc, 1.0)
			p.line(4, 5, 4, 0, gc, 1.0)
			p.line(6, 5, 7, 2, gc, 1.0)
			return p.img
		"mushroom":
			p = Px.make(8, 8)
			p.rect(3, 4, 2, 3, Pal.c("snow", 4))
			p.ellipse(4, 3, 3, 2, Pal.c("red", 2))
			p.put(3, 2, Pal.e("white"))
		"shell":
			p = Px.make(8, 6)
			p.ellipse(4, 3, 3, 2, Pal.c("pink", 3))
			p.line(2, 3, 6, 3, Pal.c("pink", 2), 1.0)
		"pebbles":
			p = Px.make(10, 6)
			p.circle(3, 3, 2, Pal.c("grey", 3))
			p.circle(7, 4, 1.5, Pal.c("grey", 2))
		"snow_tuft":
			p = Px.make(10, 6)
			p.ellipse(5, 4, 4, 2, Pal.c("snow", 4))
			p.put(3, 3, Pal.c("snow", 3))
			return p.img
		"icicle":
			p = Px.make(8, 8)
			p.poly(PackedVector2Array([Vector2(1, 7), Vector2(4, 0), Vector2(7, 7)]), Pal.c("blue", 4))
		"ice_crack":
			p = Px.make(14, 10)
			p.line(1, 2, 6, 5, Pal.c("snow", 2), 1.0)
			p.line(6, 5, 12, 4, Pal.c("snow", 2), 1.0)
			p.line(6, 5, 7, 9, Pal.c("snow", 2), 1.0)
			return p.img
		# ---------------------------------------------------------- food & pickups
		"meat":
			p = Px.make(9, 8)
			p.ellipse(4, 4, 3, 2.6, Pal.c("red", 2))
			p.put(3, 3, Pal.c("red", 3))
			p.line(6, 5, 8, 7, Pal.c("snow", 4), 1.0)
		"meat_big":
			p = Px.make(12, 10)
			p.ellipse(5, 5, 4.5, 3.6, Pal.c("red", 2))
			p.put(4, 3, Pal.c("red", 3))
			p.line(8, 6, 11, 9, Pal.c("snow", 4), 2.0)
		"meat_gold":
			p = Px.make(10, 9)
			p.ellipse(5, 4, 3.5, 3, Pal.c("gold", 2))
			p.put(4, 3, Pal.c("gold", 4))
			p.line(7, 6, 9, 8, Pal.c("snow", 4), 1.0)
		"berry":
			p = Px.make(8, 8)
			p.circle(3, 4, 2, Pal.c("purple", 3))
			p.circle(5, 5, 2, Pal.c("purple", 2))
			p.put(4, 1, Pal.c("green", 3))
		"seed":
			p = Px.make(7, 7)
			p.ellipse(3, 3, 2, 2.6, Pal.c("sandy", 3))
			p.put(3, 2, Pal.c("sandy", 4))
		"sparkle_food":
			p = Px.make(9, 9)
			p.circle(4, 4, 3, Pal.c("pink", 3))
			p.put(4, 1, Pal.e("white"))
			p.put(1, 4, Pal.e("white"))
			p.put(3, 3, Pal.e("white"))
		"mutagen":
			p = Px.make(9, 12)
			for y in 11:
				var ox := sin(y * 0.8) * 2.5
				p.put(int(4 + ox), y, Pal.c("green", 4))
				p.put(int(4 - ox), y, Pal.c("teal", 4))
				if y % 3 == 1:
					p.line(4 - ox, y, 4 + ox, y, Pal.c("snow", 4), 1.0)
		"bread":
			p = Px.make(14, 10)
			p.ellipse(7, 5, 6, 4, Pal.c("sandy", 2))
			p.ellipse(7, 4, 5, 2.5, Pal.c("orange", 3))
			for x in [4, 7, 10]:
				p.put(x, 3, Pal.c("sandy", 4))
		"bread_big":
			p = Px.make(32, 22)
			p.ellipse(16, 12, 14, 9, Pal.c("sandy", 2))
			p.ellipse(16, 9, 12, 6, Pal.c("orange", 3))
			for x in [7, 12, 17, 22, 26]:
				p.line(x, 6, x + 2, 10, Pal.c("sandy", 4), 1.0)
		# ---------------------------------------------------------- points of interest
		"poi_bread":
			p = Px.make(20, 20)
			p.rect(3, 6, 14, 12, Pal.c("sandy", 3))
			p.rect(3, 6, 14, 3, Pal.c("sandy", 2))
			p.ellipse(10, 6, 5, 3, Pal.c("orange", 3))
			p.put(7, 12, Pal.c("red", 2))
			p.put(12, 12, Pal.c("red", 2))
		"poi_mutagen":
			p = Px.make(22, 14)
			p.ellipse(11, 8, 10, 5, Pal.c("teal", 2))
			p.ellipse(11, 7, 7, 3, Pal.c("green", 4))
			p.put(8, 6, Pal.e("white"))
			p.put(14, 7, Pal.e("white"))
		"poi_egg":
			p = Px.make(16, 20)
			p.ellipse(8, 14, 7, 4, Pal.c("brown", 2))
			p.ellipse(8, 9, 5, 7, Pal.c("gold", 3))
			p.put(6, 6, Pal.e("white"))
			p.put(9, 11, Pal.c("gold", 2))
		"poi_nest":
			p = Px.make(22, 14)
			p.ellipse(11, 9, 10, 4, Pal.c("brown", 2))
			p.ellipse(11, 7, 7, 2, Pal.c("brown", 0))
			p.circle(8, 6, 2, Pal.c("snow", 4))
			p.circle(13, 6, 2, Pal.c("snow", 4))
		"poi_challenge":
			p = Px.make(22, 22)
			p.ellipse(11, 14, 10, 6, Pal.c("red", 1))
			p.ellipse(11, 14, 8, 4.5, Pal.c("grey", 2))
			p.rect(10, 2, 2, 11, Pal.c("brown", 1))
			p.poly(PackedVector2Array([Vector2(12, 2), Vector2(19, 4), Vector2(12, 7)]), Pal.c("red", 2))
		"poi_shrine":
			p = Px.make(20, 24)
			p.rect(4, 17, 12, 6, Pal.c("grey", 2))
			p.ellipse(10, 13, 6, 4, Pal.c("gold", 2))
			p.circle(13, 8, 3.5, Pal.c("gold", 3))
			p.poly(PackedVector2Array([Vector2(15, 8), Vector2(19, 9), Vector2(15, 10)]), Pal.c("orange", 3))
			p.put(13, 7, Pal.INK)
		"poi_used":
			p = Px.make(12, 6)
			p.ellipse(6, 3, 5, 2, Pal.c("brown", 1))
		"poi_mark":
			p = Px.make(9, 12)
			p.rect(2, 1, 5, 2, Pal.c("gold", 4))
			p.rect(6, 2, 2, 3, Pal.c("gold", 4))
			p.rect(4, 5, 3, 2, Pal.c("gold", 4))
			p.rect(4, 9, 2, 2, Pal.c("gold", 4))
		"cactus":
			p = Px.make(16, 24)
			p.rect(6, 4, 5, 19, Pal.c("green", 2))
			p.rect(2, 9, 3, 7, Pal.c("green", 2))
			p.rect(2, 15, 5, 2, Pal.c("green", 2))
			p.rect(12, 7, 3, 6, Pal.c("green", 2))
			p.rect(10, 12, 4, 2, Pal.c("green", 2))
			p.put(8, 3, Pal.c("pink", 3))
			for q in [Vector2(7, 8), Vector2(9, 12), Vector2(7, 16), Vector2(9, 19)]:
				p.put(int(q.x), int(q.y), Pal.c("green", 4))
		"tall_grass":
			p = Px.make(12, 12)
			for k in 5:
				var x2 := 2 + k * 2
				p.line(x2, 11, x2 + (k - 2) * 0.8, 2 + (k % 2) * 2, Pal.c("green", 2 + k % 2), 1.0)
			return p.img
		"bones":
			p = Px.make(12, 8)
			p.line(2, 5, 9, 3, Pal.c("snow", 4), 1.0)
			p.circle(2, 5, 1.5, Pal.c("snow", 4))
			p.circle(9, 3, 1.5, Pal.c("snow", 4))
		"burrow":
			p = Px.make(22, 12)
			p.ellipse(11, 7, 10, 4.5, Pal.c("brown", 2))
			p.ellipse(11, 7, 7, 3, Pal.INK)
			p.ellipse(11, 8, 5, 2, Color("0d0a14"))
			for q in [Vector2(3, 4), Vector2(18, 5), Vector2(6, 10)]:
				p.put(int(q.x), int(q.y), Pal.c("brown", 3))
			p.shade(0.1, 0.1)
			return p.img
		"shroom_red", "shroom_brown", "shroom_blue", "shroom_gold":
			p = Px.make(10, 10)
			var cap: String = {"shroom_red": "red", "shroom_brown": "brown", "shroom_blue": "blue", "shroom_gold": "gold"}[name]
			p.rect(4, 5, 3, 4, Pal.c("snow", 4))
			p.ellipse(5, 4, 4.2, 2.8, Pal.c(cap, 2))
			p.put(3, 3, Pal.e("white"))
			p.put(6, 2, Pal.e("white"))
		"fruit":
			p = Px.make(8, 9)
			p.circle(4, 5, 3, Pal.c("red", 2))
			p.put(3, 4, Pal.c("red", 4))
			p.line(4, 2, 5, 0, Pal.c("brown", 1), 1.0)
			p.put(5, 1, Pal.c("green", 3))
		"fish":
			p = Px.make(11, 7)
			p.ellipse(4, 3, 3.5, 2.2, Pal.c("blue", 3))
			p.poly(PackedVector2Array([Vector2(7, 3), Vector2(10, 1), Vector2(10, 5)]), Pal.c("blue", 2))
			p.put(2, 2, Pal.INK)
		# ---------------------------------------------------------- the 12 points of interest
		"poi_healing_pond":
			p = Px.make(28, 16)
			p.ellipse(14, 9, 13, 6, Pal.c("grey", 2))
			p.ellipse(14, 9, 11, 4.5, Pal.c("pink", 2))
			p.ellipse(12, 8, 5, 1.5, Pal.c("pink", 4))
			p.put(20, 9, Pal.e("white"))
		"poi_mud_pond":
			p = Px.make(28, 16)
			p.ellipse(14, 9, 13, 6, Pal.c("brown", 1))
			p.ellipse(14, 9, 10, 4, Pal.c("brown", 2))
			p.circle(10, 8, 1.5, Pal.c("brown", 3))
			p.circle(17, 10, 1, Pal.c("brown", 3))
		"poi_sun_dial":
			p = Px.make(22, 22)
			p.ellipse(11, 17, 10, 4, Pal.c("sandy", 2))
			p.ellipse(11, 16, 8, 3, Pal.c("sandy", 3))
			p.poly(PackedVector2Array([Vector2(11, 16), Vector2(11, 3), Vector2(17, 16)]), Pal.c("gold", 2))
			p.circle(11, 3, 2, Pal.c("gold", 4))
		"poi_oasis":
			p = Px.make(30, 28)
			p.ellipse(15, 22, 13, 5, Pal.c("blue", 2))
			p.ellipse(15, 22, 10, 3, Pal.c("blue", 3))
			p.line(20, 20, 21, 6, Pal.c("brown", 2), 2.0)
			for a in 5:
				var d := Vector2.from_angle(PI + a * PI / 4.0) * 8.0
				p.line(21, 6, 21 + d.x, 6 + d.y * 0.6 + 2, Pal.c("green", 3), 1.0)
		"poi_frozen_specimen":
			p = Px.make(22, 24)
			p.poly(PackedVector2Array([Vector2(3, 22), Vector2(4, 6), Vector2(11, 2), Vector2(19, 5), Vector2(19, 22)]), Color(Pal.c("blue", 4), 0.95))
			p.ellipse(11, 14, 5, 4, Pal.c("orange", 2))
			p.put(13, 12, Pal.INK)
			p.line(6, 8, 9, 20, Pal.e("white"), 1.0)
		"poi_unattended_nest":
			p = Px.make(24, 14)
			p.ellipse(12, 9, 11, 4.5, Pal.c("brown", 2))
			p.ellipse(12, 7, 8, 2.5, Pal.c("brown", 0))
			p.ellipse(9, 6, 2.5, 3, Pal.c("snow", 4))
			p.ellipse(14, 6, 2.5, 3, Pal.c("blue", 4))
			p.ellipse(12, 5, 2.5, 3, Pal.c("snow", 4))
		"poi_giant_mushroom":
			p = Px.make(26, 30)
			p.rect(10, 14, 6, 14, Pal.c("snow", 3))
			p.ellipse(13, 12, 12, 8, Pal.c("purple", 3))
			for q in [Vector2(8, 9), Vector2(15, 7), Vector2(19, 12), Vector2(11, 14)]:
				p.circle(q.x, q.y, 1.5, Pal.e("white"))
		"poi_carved_tree":
			p = Px.make(24, 32)
			p.rect(9, 10, 7, 20, Pal.c("brown", 2))
			p.circle(12, 8, 8, Pal.c("green", 2))
			p.line(11, 16, 14, 16, Pal.c("gold", 3), 1.0)
			p.line(12, 17, 12, 22, Pal.c("gold", 3), 1.0)
			p.put(11, 20, Pal.c("gold", 3))
			p.put(13, 20, Pal.c("gold", 3))
		"poi_growing_tree":
			p = Px.make(30, 34)
			p.rect(13, 20, 4, 12, Pal.c("brown", 1))
			p.circle(15, 12, 12, Pal.c("green", 2))
			p.circle(10, 15, 6, Pal.c("green", 3))
			for q in [Vector2(9, 10), Vector2(19, 8), Vector2(15, 16), Vector2(21, 15)]:
				p.circle(q.x, q.y, 1.6, Pal.c("red", 2))
		"poi_lotus_plant":
			p = Px.make(22, 14)
			p.ellipse(11, 9, 10, 4, Pal.c("green", 3))
			p.poly(PackedVector2Array([Vector2(7, 8), Vector2(9, 2), Vector2(11, 7), Vector2(13, 2), Vector2(15, 8)]), Pal.c("pink", 3))
			p.put(11, 6, Pal.c("gold", 4))
		"poi_algae_reef":
			p = Px.make(24, 16)
			p.ellipse(12, 11, 11, 4, Pal.c("teal", 2))
			for k in 5:
				var x3 := 4 + k * 4
				p.line(x3, 12, x3 + 1, 4 + (k % 2) * 2, Pal.c("green", 3 + k % 2), 1.0)
			p.circle(9, 10, 1.5, Pal.c("coral", 3))
		"poi_chaos_tree":
			p = Px.make(26, 32)
			p.line(13, 30, 13, 10, Pal.c("purple", 1), 3.0)
			p.line(13, 16, 6, 8, Pal.c("purple", 1), 2.0)
			p.line(13, 14, 20, 6, Pal.c("purple", 1), 2.0)
			p.circle(6, 7, 4, Pal.c("purple", 3))
			p.circle(20, 5, 4, Pal.c("pink", 3))
			p.circle(13, 8, 5, Pal.c("purple", 2))
			p.put(13, 7, Pal.c("gold", 4))
		# ---------------------------------------------------------- projectiles & fx
		"shadow":
			p = Px.make(16, 6)
			p.ellipse(8, 3, 7.5, 2.5, Color(0, 0, 0, 0.3))
			return p.img
		"glob_green":
			p = Px.make(6, 6)
			p.circle(3, 3, 2.5, Pal.c("green", 3))
			p.put(2, 2, Pal.c("green", 4))
		"glob_purple":
			p = Px.make(7, 5)
			p.line(0, 2, 6, 2, Pal.c("purple", 3), 2.0)
			p.put(6, 2, Pal.e("white"))
		"glob_duck":
			p = Px.make(8, 5)
			p.line(0, 2, 7, 2, Pal.c("duck", 3), 1.0)
			p.line(1, 1, 4, 1, Pal.c("duck", 4), 1.0)
			p.line(1, 3, 4, 3, Pal.c("duck", 2), 1.0)
		"egg":
			p = Px.make(7, 8)
			p.ellipse(3, 4, 2.6, 3.4, Pal.c("snow", 4))
			p.put(2, 2, Pal.e("white"))
		"threat_glob":
			p = Px.make(7, 7)
			p.circle(3, 3, 3, Pal.c("red", 2))
			p.circle(3, 3, 1.5, Pal.e("white"))
		"star":
			p = Px.make(7, 7)
			p.line(3, 0, 3, 6, Pal.c("gold", 3), 1.0)
			p.line(0, 3, 6, 3, Pal.c("gold", 3), 1.0)
			p.put(3, 3, Pal.e("white"))
			return p.img
		_:
			p = Px.make(6, 6)
			p.rect(0, 0, 6, 6, Color(1, 0, 1))
	p.shade(0.14, 0.18)
	p.outline(Pal.INK, 0.3)
	return p.img
