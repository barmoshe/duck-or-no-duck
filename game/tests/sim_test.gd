extends Node
## Headless tests: logic checks, then a bot plays through the real main.gd and World:
## eating, evolving (cards, rerolls), points of interest, bosses (kill or give up),
## night, and the final boss with the Breadfall.
##   tools/test.sh      (godot --headless --path game -- --test)

const RUN := 1
const CHOICE := 2
const END := 4
const WAIT := 5

var main: Node
var failed := 0


func check(ok: bool, msg: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + msg)
	if not ok:
		failed += 1


func run(m: Node) -> void:
	main = m
	Game.save_enabled = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--balance="):
			await _balance(int(a.substr(10)))
			return
	print("== logic")
	_logic()
	print("== food")
	_food()
	print("== simulated runs")
	await _sim(480.0, 0.0, "early game")
	await _sim(170.0, Run.FINAL_TIME - 5.0, "final boss")
	print("TESTS: %s" % ("PASS" if failed == 0 else "%d FAILED" % failed))
	get_tree().quit(1 if failed else 0)


func _logic() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var r := Run.new("pioneer", 0, rng)
	check(r.attacks == ["gulp"] and r.move == "scoot", "Puddle hatches with Gulp and Scoot")
	check(r.boss_order.size() == 4 and r.boss_order[3] == "great_mallard", "3 bosses then the Great Mallard: %s" % [r.boss_order])
	check(float(r.stats["max_hp"]) == 50.0 and float(r.stats["speed"]) == 6.0, "Darwin's base line (+1 Speed from Pioneer)")
	var bad := 0
	for id in Evolutions.ALL:
		var d: Dictionary = Evolutions.ALL[id]
		if not d["aff"] in Evolutions.AFFINITIES or not d["type"] in Evolutions.TYPE_NAMES:
			bad += 1
		if d["type"] == "attack" and not Attacks.ATTACK.has(id):
			bad += 1
		if d["type"] == "ultimate" and not Attacks.ULT.has(id):
			bad += 1
		if d["type"] == "move" and not Attacks.MOVE.has(id):
			bad += 1
	check(bad == 0, "every evolution is well formed (%d)" % Evolutions.ALL.size())
	var hand := Offers.roll(r, rng, "level")
	check(hand.size() == 3, "a level up offers 3 cards")
	for id in hand:
		check(not Evolutions.get_def(id).get("starter", false) or r.has(id), "no unowned starters offered")
	var fruit := Offers.roll(r, rng, "boss")
	check(fruit.size() == 3 and Evolutions.get_def(fruit[0])["type"] == "branch", "Boss Fruit offers Branching Evolutions")
	# Darwin-style art: evolutions that add a part show on Puddle, stacks stay readable
	var base_run := Run.new("pioneer", 0, rng)
	var base_key := Anatomy.key_of(base_run.look)
	var same: Array = []
	for id in Evolutions.ALL:
		var ev := Evolutions.get_def(id)
		if ev.get("starter", false) or (ev.get("look", {}) as Dictionary).is_empty():
			continue
		if Anatomy.key_of(base_run.preview(id)) == base_key:
			same.append(id)
	check(same.is_empty(), "every evolution with a look shows on Puddle (unchanged: %s)" % [same])
	var big := Run.new("pioneer", 0, rng)
	for i in 3:
		for id in ["more_eyes", "mutant_luck", "long_legs", "horns", "swan_neck", "heron_stilts", "colossal", "big_brain", "branch_tentacles", "tentacle_lash"]:
			big.take(id)
	check(int(big.look["eye_n"]) <= 6, "eyes stack up to 6 (%d)" % int(big.look["eye_n"]))
	var fr_big := Anatomy.frames(big.look)
	check((fr_big["idle"] as Array).size() == 4 and (fr_big["walk"] as Array).size() == 4 and (fr_big["bite"] as Array).size() == 1, "Puddle has idle, walk and bite frames")
	var t_r := Time.get_ticks_usec()
	Anatomy.clear_cache()
	var no_art: Array = []
	for sid in Species.ALL:
		var sf := Anatomy.frames(Species.look_of(sid))
		var sz: Vector2i = sf["size"]
		var ft: Vector2 = sf["foot"]
		var ok_fr := (sf["idle"] as Array).size() == 4 and (sf["walk"] as Array).size() == 4 and (sf["bite"] as Array).size() == 1
		ok_fr = ok_fr and (sf["idle"][0] as Texture2D).get_image().get_used_rect().size.x > 4
		if not ok_fr or ft.x < 0 or ft.y > sz.y or not DarwinAnimals.ALL.has(sid):
			no_art.append(sid)
	check(no_art.is_empty(), "every species and boss has a hand-drawn sprite with all frames (bad: %s)" % [no_art])
	var ms := (Time.get_ticks_usec() - t_r) / 1000.0
	check(ms < 400.0, "drawing every species takes %.0f ms" % ms)
	# the evolution tree: unlocks, bans, levels, branches
	var tr := Run.new("pioneer", 0, rng)
	check(not Offers.eligible(tr, "glide", "level"), "Glide starts locked")
	tr.take("duck_wings")
	check(Offers.eligible(tr, "glide", "level") and Offers.eligible(tr, "feather_darts", "level"), "Duck Wings unlocks Glide and Feather Darts")
	tr.take("herbivore")
	check(not Offers.eligible(tr, "vegan", "level"), "Vegan needs Herbivore level 2")
	tr.take("herbivore")
	check(Offers.eligible(tr, "vegan", "level"), "Herbivore level 2 unlocks Vegan")
	tr.take("branch_wings")
	check(not Offers.eligible(tr, "branch_shell", "boss") and tr.branches == ["branch_wings"], "Wings bans Shell")
	check(Offers.eligible(tr, "duck_dive", "level"), "Wings opens Duck Dive")
	check(Evolutions.offered_rarity("thick_hide", 1) == 0 and Evolutions.offered_rarity("thick_hide", 3) == 1 and Evolutions.offered_rarity("thick_hide", 5) == 2, "rarity rises with level (common, rare at 3, epic at 5)")
	var ln := Evolutions.lines("jaws", 2)
	check(ln.size() >= 2 and String(ln[0][1]) != "" and String(ln[0][2]) != "", "cards show current -> next numbers (%s)" % [ln[0]])
	var br := Offers.roll(tr, rng, "boss")
	var all_br := br.size() == 3
	for id in br:
		all_br = all_br and Evolutions.get_def(id)["type"] == "branch"
	check(all_br, "a Boss Fruit hand is 3 branching evolutions: %s" % [br])
	var bad_tree := 0
	for id in Evolutions.ALL:
		for x in Evolutions.unlocks_of(id):
			if Evolutions.get_def(x).is_empty():
				bad_tree += 1
		for x in Evolutions.get_def(id).get("excludes", []):
			if Evolutions.get_def(x).is_empty():
				bad_tree += 1
	check(bad_tree == 0, "every unlock and ban names a real evolution")
	var orphan := 0
	for id in Evolutions.ALL:
		if Evolutions.get_def(id).get("locked", false):
			var opened := false
			for other in Evolutions.ALL:
				if id in Evolutions.unlocks_of(other):
					opened = true
			if not opened:
				orphan += 1
	check(orphan == 0, "every locked evolution can be unlocked (%d orphans)" % orphan)
	# attacks: a third replaces the weakest
	r.take("spit")
	var repl := r.take("tail_whip")
	check(r.attacks.size() == 2 and repl != "", "a third attack replaces one (%s)" % repl)
	# duck parts
	for id in ["duck_bill", "webbed_feet", "down_feathers", "duck_wings", "tail_curl"]:
		r.take(id)
	check(r.duck_parts() == 5 and float(r.stats["duck_taken"]) == 20.0, "5 duck parts: +20% damage taken")
	check(Offers.eligible(r, "convergent", "level"), "Convergent Evolution unlocks at 5 duck parts")
	r.take("convergent")
	check(r.look["body"] == "duck" and r.ultimate == "mega_quack", "Convergent Evolution: a mallard with Mega Quack")
	# every look renders
	var imgs := 0
	for id in Species.ALL:
		if Anatomy.render(Species.look_of(id), "idle", 0).get_width() > 0:
			imgs += 1
	check(imgs == Species.ALL.size(), "every species renders (%d)" % imgs)
	for id in Pois.ALL:
		check((Pois.get_def(id)["options"] as Array).size() == 3, "POI %s has 3 options" % id)
	var mg := MapGen.new()
	mg.generate(99)
	check(mg.pois.size() >= 12 and mg.burrows.size() >= 12, "map: %d POIs, %d burrows, %d obstacles" % [mg.pois.size(), mg.burrows.size(), mg.obstacles.size()])
	check(mg.biome_at(mg.start) == 0 and mg.water_at(mg.start) == 0, "you hatch on dry grass")
	r.time = 0.0
	check(not r.is_night(), "runs start in daylight")
	r.time = Run.DAY_LEN * 0.7
	check(r.is_night(), "night comes")


func _food() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var n := [0, 0, 0, 0]
	for i in 20000:
		n[Foods.roll(rng, "animal")] += 1
	check(n[0] > 14000 and n[0] < 16000 and n[3] > 100 and n[3] < 320, "animal food rolls ~75/19/5/1: %s" % [n])
	var lucky := [0, 0, 0, 0]
	for i in 20000:
		lucky[Foods.roll(rng, "animal", 10.0)] += 1
	check(lucky[3] > n[3] * 1.5, "luck makes rare food likelier (%d vs %d legendary)" % [lucky[3], n[3]])
	check(Foods.heal_chance(3, 0.1) == 0.0 and Foods.heal_chance(0, 0.1) > Foods.heal_chance(0, 0.9), "legendary never heals; low HP finds more healing food")
	var sprites := 0
	var shrinks := 0
	for kind in Foods.TYPES:
		for r in 4:
			var whole := Props.image(Foods.sprite_name(kind, r, 0))
			if whole.get_used_rect().size.x > 6:
				sprites += 1
			var px := [0, 0, 0, 0]
			for st in 4:
				var im := Props.image(Foods.sprite_name(kind, r, st))
				check(im.get_size() == whole.get_size(), "%s_%d stage %d keeps its canvas" % [kind, r, st])
				for y in im.get_height():
					for x in im.get_width():
						if im.get_pixel(x, y).a > 0.0:
							px[st] += 1
			if px[0] > px[1] and px[1] > px[2] and px[2] > px[3]:
				shrinks += 1
	check(sprites == 12, "all 12 foods draw (fruit, meat, fish x 4 rarities)")
	check(shrinks == 12, "every food shrinks bite by bite (%d of 12)" % shrinks)
	main._start()
	var w: World = main.world
	w.auto_step = false
	check(w.sources.size() > 60, "fruit sources: %d trees, bushes and cacti" % w.sources.size())
	check(w.pools.size() >= 12, "fish pools: %d" % w.pools.size())
	var fruit := 0
	for f in w.foods:
		if String(f["type"]) == "fruit":
			fruit += 1
	check(fruit > 40, "the world starts with windfall fruit (%d)" % fruit)
	var src: Dictionary = w.sources[0]
	var before := w.foods.size()
	src["stock"] = 2
	src["cd"] = 0.0
	w.shake_source(src)
	check(w.foods.size() == before + 1 and int(src["stock"]) == 1, "bumping a tree shakes a fruit loose")
	w.shake_source(src)
	check(w.foods.size() == before + 1, "a shaken tree needs a moment before it shakes again")
	var pl: Dictionary = w.pools[0]
	before = w.foods.size()
	w._fish_jump(pl)
	check(w.foods.size() == before + 2, "fish jump out of a fish pool")
	# eating: rarity multiplies XP, vegans can't eat meat
	var lvl0: int = main.run.level
	var common: float = w.food_value(w.spawn_food(w.player.position, "meat", 1.0, 0))
	var legend: float = w.food_value(w.spawn_food(w.player.position, "meat", 1.0, 3))
	check(absf(legend - common * 10.0) < 0.01, "legendary food is worth 10x common (%.1f vs %.1f)" % [legend, common])
	main.run.take("carnivore")
	check(w.food_value(w.spawn_food(w.player.position, "meat", 1.0, 0)) > common, "Carnivore makes meat worth more")
	main.run.stats["meat_xp"] = 0.0
	main.run.stats["vegan"] = 1.0
	check(not w.can_eat(w.spawn_food(w.player.position, "meat", 1.0, 0)) and w.can_eat(w.spawn_food(w.player.position, "fruit", 1.0, 0)), "vegans eat fruit, not meat")
	check(not Offers.eligible(main.run, "vegan", "level"), "a Carnivore is never offered Vegan")
	w.player.hp = 1.0
	var hf: Dictionary = w.spawn_food(w.player.position, "fruit", 1.0, 0, false, 0.0, true)
	w._bite(hf)
	check(w.player.hp > 2.0 and int(hf["bites"]) == Foods.BITES - 1, "a bite of sparkling food heals")
	check(not w.spawn_food(w.player.position, "fruit", 1.0, 3, false, 0.0, true)["heal"], "legendary food never heals")
	# Hump: a sparkling bite at full health grows Max HP for good
	main.run.stats["hump"] = 1.0
	w.player.hp = w.player.max_hp
	var mhp: float = w.player.max_hp
	w._bite(w.spawn_food(w.player.position, "fruit", 1.0, 0, false, 0.0, true))
	check(w.player.max_hp > mhp and float(main.run._bonus.get("max_hp", 0.0)) >= 1.0, "Hump: a sparkling bite at full health raises Max HP")
	main.run._bonus.erase("max_hp")
	main.run.recompute()
	w.sync_player()
	# Food Sense: more food sparkles
	var plain := 0
	var sensed := 0
	for i in 400:
		plain += 1 if w._roll_food(w.player.position + Vector2(300, 0), "fruit", 1.0, "plant")["heal"] else 0
	main.run.stats["forage"] = 150.0
	for i in 400:
		sensed += 1 if w._roll_food(w.player.position + Vector2(300, 0), "fruit", 1.0, "plant")["heal"] else 0
	main.run.stats["forage"] = 0.0
	check(sensed > plain * 1.6, "Food Sense makes more food sparkle (%d vs %d)" % [sensed, plain])
	# eating: walk over food and eat it one piece at a time, four bites a piece
	main.run.stats["vegan"] = 0.0
	for f in w.foods:
		(f["n"] as Node).queue_free()
	w.foods.clear()
	w.pouch.clear()
	w.bite_cd = 0.0
	w.player.vel = Vector2(60, 0)
	var xp_e: float = main.run.xp
	var lvl_e: int = main.run.level
	var fd: Dictionary = w.spawn_food(w.player.position + Vector2(6, 0), "meat", 5.0, 0)
	var fd2: Dictionary = w.spawn_food(w.player.position + Vector2(-5, 2), "fruit", 5.0, 0)
	for f in [fd, fd2]:
		f["v"] = Vector2.ZERO
	w._feed(0.01)
	var bitten := (1 if int(fd["bites"]) == Foods.BITES - 1 else 0) + (1 if int(fd2["bites"]) == Foods.BITES - 1 else 0)
	var whole := (1 if int(fd["bites"]) == Foods.BITES else 0) + (1 if int(fd2["bites"]) == Foods.BITES else 0)
	check(bitten == 1 and whole == 1, "the first bite is instant, on the move, and takes one piece only")
	var first: Dictionary = fd2 if int(fd2["bites"]) < Foods.BITES else fd
	var second: Dictionary = fd if is_same(first, fd2) else fd2
	check(is_same(first, fd2), "you start on the nearest piece")
	check(main.run.xp > xp_e or main.run.level > lvl_e, "each bite gives Progress")
	w._feed(0.01)
	check(int(first["bites"]) == Foods.BITES - 1, "the next bite waits for the bite time")
	var bt := Foods.bite_time(float(main.run.stats["feed"]))
	for i in (Foods.BITES - 1) * 2:
		w._feed(bt / 2.0 + 0.001)
	check(not w.foods.has(first) and int(second["bites"]) == Foods.BITES, "you finish one piece before starting the next")
	for i in Foods.BITES * 2 + 2:
		w._feed(bt / 2.0 + 0.001)
	check(not w.foods.has(second), "four bites finish a piece")
	check(Foods.bite_time(100.0) >= 0.5, "a bite takes at least half a second at base Feeding Speed")
	check(Foods.bite_time(125.0) < Foods.bite_time(100.0), "Feeding Speed (Saliva) bites faster")
	var shares := 0.0
	for left in range(Foods.BITES, 0, -1):
		shares += Foods.bite_share(left)
	check(is_equal_approx(shares, 1.0) and Foods.bite_share(1) == 2.0 * Foods.bite_share(4), "the bites add up to the piece; the last pays double")
	var far: Dictionary = w.spawn_food(w.player.position + Vector2(200, 0), "fruit", 5.0, 0)
	far["v"] = Vector2.ZERO
	w.bite_cd = 0.0
	w._feed(0.01)
	check(int(far["bites"]) == Foods.BITES, "food out of reach isn't eaten")
	w.take_food(far)
	check(int(far["bites"]) == Foods.BITES - 1 and float(far["life"]) > 0.0, "an animal takes one bite at a time")
	for i in 3:
		w.take_food(far)
	check(float(far["life"]) <= 0.0, "animals can finish a piece")
	# Cheek Pouch: food a little further out goes into your cheeks and is bitten on the move
	main.run.stats["pouch"] = 2.0
	var pr := (w.reach() + w.pouch_reach()) * 0.5
	for i in 3:
		var fp: Dictionary = w.spawn_food(w.player.position + Vector2(pr, i), "fruit", 5.0, 0)
		fp["v"] = Vector2.ZERO
	w.bite_cd = 1.0
	w._feed(0.01)
	check(w.pouch.size() == 2, "Cheek Pouch stores food nearby up to its capacity (%d)" % w.pouch.size())
	w.bite_cd = 0.0
	w._feed(0.01)
	check(int(w.pouch[0]["bites"]) == Foods.BITES - 1 and int(w.pouch[1]["bites"]) == Foods.BITES, "food in your cheeks is eaten one piece at a time when nothing is in reach")
	main.run.stats["pouch"] = 0.0
	w.pouch.clear()
	# mushrooms: eaten on purpose, each look keeps one effect all run, named by Senses
	for sm in w.shrooms:
		(sm["n"] as Node).queue_free()
	w.shrooms.clear()
	check(w.shroom_fx.size() == Pois.SHROOM_LOOKS.size(), "every mushroom look is dealt an effect for the run")
	var dealt := {}
	for e in w.shroom_fx:
		dealt[e] = true
	check(dealt.size() == w.shroom_fx.size(), "no two looks share an effect")
	var sm0: Dictionary = w._place_shroom(w.player.position + Vector2(3, 0))
	check(not w.shroom_in_reach().is_empty(), "a mushroom at your feet is in reach")
	for i in 120:
		w._pickups(0.016)
	check(w.shrooms.size() == 1, "standing on a mushroom doesn't eat it")
	check(String(w.interact_target().get("kind", "")) == "shroom" and String(w.interact_target()["label"]) == "EAT", "E offers to eat the mushroom at your feet")
	var xs: float = main.run.xp
	var ls: int = main.run.level
	var eff := w.shroom_effect(sm0)
	check(w.interact(), "E eats it")
	check(w.shrooms.is_empty(), "the mushroom is gone once eaten")
	check(main.run.xp > xs or main.run.level > ls, "every mushroom gives some Progress")
	check(w.shroom_known.has(int(sm0["look"])), "once eaten, you know what that look does")
	check(not w.eat_shroom(), "nothing to eat when no mushroom is in reach")
	# points of interest open with E too, not by walking into them
	check(not w.pois.is_empty(), "the map has ? spots")
	var poi0: Dictionary = w.pois[0]
	var back: Vector2 = w.player.position
	var opened := []
	var on_poi := func(kind: String) -> void: opened.append(kind)
	w.poi_choice.connect(on_poi)
	w.player.position = poi0["p"]
	w._poi_check()
	check(opened.is_empty() and not poi0["used"], "walking into a ? spot doesn't open it")
	check(String(w.interact_target().get("kind", "")) == "poi", "E offers the ? spot you're standing at")
	check(w.interact() and opened.size() == 1 and poi0["used"], "E opens it, once")
	check(w.interact_target().is_empty() or String(w.interact_target()["kind"]) != "poi" or not is_same(w.interact_target()["ref"], poi0), "a used spot isn't offered again")
	w.poi_choice.disconnect(on_poi)
	# close the choice screen main opened, without taking an option
	main.poi_screen.hide_screen()
	main.get_tree().paused = false
	main._set_state(main.S.RUN)
	w.player.position = back
	check(String(eff[1]) in ["good", "side", "bad"], "the effect has a kind (%s)" % eff[0])
	w.player.hp = w.player.max_hp
	w.player.poison_t = 0.0
	w.apply_fx({"poison": 0.05})
	for i in 60:
		w.player.tick(1.0 / 15.0)
	check(w.player.hp < w.player.max_hp * 0.9 and w.player.hp > w.player.max_hp * 0.7, "Poisonous takes about a fifth of your health over 4 s (%d/%d)" % [roundi(w.player.hp), roundi(w.player.max_hp)])
	w.player.hp = w.player.max_hp * 0.5
	w.apply_fx({"hot": 0.4, "secs": 4.0})
	for i in 50:
		w._regen(0.1)
	check(w.player.hp > w.player.max_hp * 0.85, "Medicinal heals over a few seconds")
	w.player.hp = w.player.max_hp
	w.apply_fx({"deaf": 15.0, "trip": 10.0})
	w.step(0.016)
	check(Sfx.muffle < 0.0 and w.trip > 0.0, "Deafening muffles the sound; Hallucinogen swirls the colors")
	w.deaf = 0.0
	w.trip = 0.0
	w.step(0.016)
	check(Sfx.muffle == 0.0, "the sound comes back")
	check(Pois.identify_chance(0.0) == 0.0 and Pois.identify_chance(1.0) > 0.2 and Pois.identify_chance(1.0) < 0.3 and Pois.identify_chance(2.5) >= 1.0, "Senses: blind at 0, a quarter at 1, always right at 2.5")
	w.shroom_known.clear()
	main.run.stats["identify"] = 3.0
	var seen: Dictionary = w._place_shroom(w.player.position + Vector2(40, 0))
	w._shrooms_near()
	check(w.shroom_known.has(int(seen["look"])), "high Senses names a mushroom on sight")
	main.run.stats["identify"] = 0.0
	for sm in w.shrooms:
		(sm["n"] as Node).queue_free()
	w.shrooms.clear()
	# attacks: you press them, they aim themselves. A level-up from the mushrooms above
	# may have opened its screen and paused the game: close it first.
	w.pending_ups = 0
	main.levelup.hide_screen()
	main.poi_screen.hide_screen()
	main.get_tree().paused = false
	main._set_state(main.S.RUN)
	var a0 := w.combat.slot(0)
	check(a0 != "", "you start with an attack in slot 1 (%s)" % a0)
	var foe: Actor = w.spawn_animal("stoat", w.player.position + Vector2(w.player.r + 6.0, 0))
	foe.asleep = false
	foe.stun = 30.0
	foe.max_hp = 9999.0
	foe.hp = 9999.0
	w._rebuild_grid()  # the world does this every step; targeting reads it
	w.combat.cds[a0] = 0.0
	for i in 40:
		w.combat.step(0.016)
	check(foe.hp >= 9999.0, "attacks don't go off on their own")
	w.combat.tap(a0)
	w.combat.step(0.016)
	var hp_a: float = foe.hp
	check(hp_a < 9999.0, "a tap strikes the enemy in reach, aimed for you")
	check(float(w.combat.cds[a0]) > Combat.WHIFF_CD, "then the attack cools down")
	w.combat.cds[a0] = 0.1
	w.combat.tap(a0)
	w.combat.step(0.05)
	check(foe.hp == hp_a, "a press during the cooldown waits")
	w.combat.step(0.06)
	check(foe.hp < hp_a, "and goes off when the cooldown ends")
	var hits := 0
	var last: float = foe.hp
	w.combat.hold(a0, true)
	for i in int(w.combat.cd_of(a0) * 3.5 / 0.05):
		w.combat.step(0.05)
		if foe.hp < last:
			hits += 1
			last = foe.hp
	w.combat.hold(a0, false)
	check(hits >= 3, "holding the button keeps attacking (%d hits)" % hits)
	foe.position += Vector2(400, 0)
	w._rebuild_grid()
	w.combat.cds[a0] = 0.0
	last = foe.hp
	w.combat.tap(a0)
	w.combat.step(0.016)
	check(foe.hp == last and is_equal_approx(float(w.combat.cds[a0]), Combat.WHIFF_CD), "with nothing in reach it swings at the air and is ready again soon")
	# every attack: its own shape, reach and cooldown, and each one lands
	var saved_attacks: Array = main.run.attacks.duplicate()
	var home: Vector2 = w.player.position
	for aid in Attacks.ATTACK:
		var spec: Dictionary = Attacks.ATTACK[aid]
		check(spec.has("shape") and spec.has("range") and spec.has("cd") and Attacks.TRAIT.has(aid), "%s has a shape, range, cooldown and trait" % aid)
		main.run.attacks = [aid]
		w.player.position = home
		w.player.invuln = 0.0
		# fire along a line with no wall in the way (shots stop at walls)
		var gap := minf(w.combat.reach(aid) * 0.6, 60.0)
		var way := Vector2.RIGHT
		for k in 16:
			var cand := Vector2.from_angle(k * TAU / 16.0)
			var open := true
			for j in 13:
				if w.map.is_wall(home + cand * gap * j / 12.0):
					open = false
					break
			if open:
				way = cand
				break
		foe.position = home + way * gap
		foe.vel = Vector2.ZERO
		foe.stun = 30.0
		foe.hp = 9999.0
		foe.is_ally = false
		w._rebuild_grid()
		w.combat.cds[aid] = 0.0
		w.combat.tap(aid)
		for i in 40:
			w.player.tick(0.05)
			w.combat.step(0.05)
		var landed: bool = foe.hp < 9999.0 or (aid == "charm_song" and foe.is_ally)
		check(landed, "%s lands on a target %d px away (reach %d)" % [aid, roundi(foe.position.distance_to(home)), roundi(w.combat.reach(aid))])
	main.run.attacks = saved_attacks
	w.player.position = home
	foe.is_ally = false
	# Jaws: double damage to stunned; its swipe misses what's behind you
	main.run.attacks = ["jaws"]
	var jspec: Dictionary = Attacks.ATTACK["jaws"]
	foe.position = home + Vector2(-w.player.r - 6.0, 0)
	w._rebuild_grid()
	check(not w.combat.caught("arc", Vector2.RIGHT, w.combat.reach("jaws"), jspec).has(foe), "a swipe doesn't hit what's behind you")
	foe.position = home + Vector2(w.player.r + 6.0, 0)
	w._rebuild_grid()
	check(w.combat.caught("arc", Vector2.RIGHT, w.combat.reach("jaws"), jspec).has(foe), "a swipe hits what's in front")
	# shots fly as far as their attack reaches
	var sh: Dictionary = w.combat._shoot(home, Vector2(170, 0), 1.0, false, Attacks.ATTACK["spit"], w.combat.reach("spit"))
	check(is_equal_approx(float(sh["life"]) * 170.0, w.combat.reach("spit")), "a shot stops at its range")
	# Mud Splash leaves a pool that slows
	w.combat.zones.append({"p": foe.position, "r": 20.0, "t": 1.0, "slow": 0.5})
	foe.slow_t = 0.0
	w.combat._zones(0.05)
	check(foe.slow_t > 0.0 and foe.slow >= 0.5, "a mud pool slows what stands in it")
	w.combat.zones.clear()
	main.run.attacks = saved_attacks
	foe.hp = 0.0
	w._reap()
	# kills drop pieces of food, big ones more, and no carcass
	for f in w.foods:
		(f["n"] as Node).queue_free()
	w.foods.clear()
	w.drop_food(w.player.position + Vector2(80, 0), 20.0, true, false, false)
	var pieces := 0
	for f in w.foods:
		if String(f["type"]) == "meat" and int(f["bites"]) == Foods.BITES:
			pieces += 1
	check(pieces >= 3, "a big kill drops several whole pieces of meat (%d)" % pieces)
	# Ruminant: progress while calm, reset when hit
	main.run.stats["ruminant"] = 1.0
	var xr: float = main.run.xp
	w._ruminate(10.5)
	check(main.run.xp > xr or main.run.level > lvl0, "Ruminant gives Progress every 10 calm seconds")
	w.on_player_hit()
	xr = main.run.xp
	w._ruminate(10.5)
	check(main.run.xp == xr, "getting hit pauses Ruminant")
	w.auto_step = true
	main._end(false)
	main._title()


## Scores a card like a sensible player: attacks and raw power first.
func _score(r: Run, id: String) -> float:
	var d := Evolutions.get_def(id)
	var sc := 1.0 + int(d["rarity"]) * 0.8
	match String(d["type"]):
		"attack":
			sc += 3.0 if r.has(id) else (2.0 if r.attacks.size() < 2 else 0.5)
		"ultimate":
			sc += 2.5 if r.ultimate == "" or r.ultimate == id else 0.2
		"branch":
			sc += 3.0
	var st: Dictionary = d.get("stats", {})
	for k in ["physical", "ability", "max_hp", "armor", "regen", "all"]:
		if st.has(k):
			sc += 1.5
	return sc


func _best_card(r: Run, hand: Array) -> int:
	var bi := 0
	var bs := -1.0
	for i in hand.size():
		var sc := _score(r, String(hand[i]))
		if sc > bs:
			bs = sc
			bi = i
	return bi


func _bot(w: World) -> Vector2:
	var p := w.player
	# press E at ? spots, and on mushrooms it doesn't know to be bad
	var t := w.interact_target()
	if not t.is_empty():
		if String(t["kind"]) == "poi":
			w.interact()
		elif not w.shroom_known.has(int(t["ref"]["look"])) or String(w.shroom_effect(t["ref"])[1]) != "bad":
			w.interact()
	# hurt: run for the nearest burrow and hide
	if p.hp < p.max_hp * 0.4:
		var nb := Vector2.ZERO
		var nd := INF
		for b in w.burrows:
			var d := (b["p"] as Vector2).distance_to(p.position)
			if d < nd:
				nd = d
				nb = b["p"]
		if nd < 400.0:
			return Vector2.ZERO if nd < 5.0 else (nb - p.position).normalized()
	var best := Vector2.ZERO
	var bd := INF
	var danger := Vector2.ZERO
	for o in w.near(p.position, 160.0):
		var c: Actor = o
		if c == p or c.is_ally:
			continue
		var to := c.position - p.position
		if c.alpha or (c.is_boss and p.hp < p.max_hp * 0.6) or (c.r > p.r * 1.3 and (c.role == "predator" or c.state == "chase")):
			danger -= to.normalized() * (160.0 - to.length()) / 160.0
		elif to.length() < bd and not c.asleep:
			bd = to.length()
			best = to
	for f in w.foods:
		if not w.can_eat(f):
			continue
		var to2: Vector2 = (f["p"] as Vector2) - p.position
		if to2.length() < bd:
			bd = to2.length()
			best = to2
	if bd > 200.0:
		var poi := w.nearest_poi()
		if not poi.is_empty():
			best = (poi["p"] as Vector2) - p.position
	# stand still to eat when food is in reach and nothing dangerous is close
	if danger.length() < 0.2:
		# food in reach is being eaten as you move; don't wander off before it's gone
		if not w.in_reach().is_empty():
			return Vector2.ZERO
	var dir := best.normalized() + danger * 2.5
	if dir.length() < 0.1:
		dir = Vector2.from_angle(w.run.time)
	return dir.limit_length(1.0)


func _sim(seconds: float, start_at: float, label: String) -> Dictionary:
	main._start()
	var w: World = main.world
	w.auto_step = false
	if start_at > 0.0:
		main.run.time = start_at
		w.next_boss = 3
		for i in 30:
			main.run.take(String(Offers.roll(main.run, Game.rng, "level", 1)[0]))
		main.run.level = 25
		main.run.recompute()
		w.sync_player(true)
	var dt := 1.0 / 60.0
	var t := 0.0
	var picks := 0
	var pois := 0
	var worst := 0
	var total := 0
	var steps := 0
	var bosses := 0
	var nights := 0
	var was_boss := false
	while t < seconds:
		match main.state:
			RUN:
				get_tree().paused = false
				w.input_dir = _bot(w)
				if w.combat.ult_cd <= 0.0:
					w.combat.use_ult()
				# the bot holds an attack down while something is in its reach
				for aid in main.run.attacks:
					w.combat.hold(aid, w.combat.in_range(aid))
				var t0 := Time.get_ticks_usec()
				w.step(dt)
				w._camera(dt)
				var us := Time.get_ticks_usec() - t0
				worst = maxi(worst, us)
				total += us
				steps += 1
				if w.bosses.active() and not was_boss:
					bosses += 1
				was_boss = w.bosses.active()
				if main.run.is_night() and steps % 600 == 0:
					nights += 1
			CHOICE:
				if main.poi_screen.visible:
					pois += 1
					main.poi_screen.press("opt:%d" % (Game.rng.randi() % 3))
				elif main.levelup.visible:
					if main.run.mutagen >= main.run.reroll_cost and Game.rng.randf() < 0.2:
						main.levelup.press("reroll")
					main.levelup.press("pick:%d" % _best_card(main.run, main.levelup.hand))
					picks += 1
				else:
					main._next_choice()
			WAIT:
				main._after_wait()
			END:
				break
			_:
				break
		t += dt
		if steps % 300 == 0:
			await get_tree().process_frame
	var r: Run = main.run
	print("  %s: %.0fs, level %d, picks %d, POIs %d, bosses met %d (killed %d, survived %d), kills %d, allies %d, animals %d, won %s, state %d" % [
		label, t, r.level, picks, pois, bosses, r.bosses_killed, r.bosses_survived, r.kills, w.ally_count(), w.actors.size(), r.won, main.state])
	print("  killed by: %s, hp %d/%d, stats phy %d abi %d arm %d" % [w.get_meta("killed_by", "-"), w.player.hp, w.player.max_hp, r.stats["physical"], r.stats["ability"], r.stats["armor"]])
	print("  step cost: avg %.2f ms, worst %.2f ms, look: %s" % [total / 1000.0 / maxf(1, steps), worst / 1000.0, Anatomy.key_of(r.look)])
	if start_at == 0.0:
		check(picks > 0, "%s: evolved" % label)
	check(steps > 0 and total / 1000.0 / steps < 6.0, "%s: average step under 6 ms" % label)
	if start_at == 0.0:
		check(bosses >= 1, "early game: a boss arrived on the timer")
	else:
		check(bosses >= 1, "final: the Great Mallard hatched")
	w.auto_step = true
	var result := {"t": t, "level": r.level, "picks": picks, "bosses": bosses, "killed": r.bosses_killed,
		"survived": r.bosses_survived, "won": r.won, "allies": w.ally_count(), "killer": String(w.get_meta("killed_by", "-"))}
	if main.state != END:
		main._end(false)
	main._title()
	return result


## Balance report: n full bot runs (14 minutes) and n final-boss runs.
func _balance(n: int) -> void:
	print("== balance (%d runs)" % n)
	var lv_at_end: Array = []
	var first_boss := 0
	var reached_final := 0
	for i in n:
		Game.rng.seed = 1000 + i
		var res: Dictionary = await _sim(Run.FINAL_TIME, 0.0, "full %d" % i)
		lv_at_end.append(res["level"])
		if int(res["killed"]) + int(res["survived"]) >= 1:
			first_boss += 1
		if float(res["t"]) >= Run.FINAL_TIME - 1.0:
			reached_final += 1
	var wins := 0
	var surv: Array = []
	for i in n:
		Game.rng.seed = 2000 + i
		var res2: Dictionary = await _sim(170.0, Run.FINAL_TIME - 5.0, "final %d" % i)
		surv.append(int(res2["t"]))
		if res2["won"]:
			wins += 1
	print("BALANCE levels at end %s | got past boss 1: %d/%d | reached the final: %d/%d | final wins %d/%d, survived %s s" % [lv_at_end, first_boss, n, reached_final, n, wins, n, surv])
	get_tree().quit(0)
