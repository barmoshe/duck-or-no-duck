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
	check(Foods.heart_chance(3, 0.1) == 0.0 and Foods.heart_chance(0, 0.1) > Foods.heart_chance(0, 0.9), "legendary never turns into a heart; low HP finds more hearts")
	var sprites := 0
	for kind in ["apple", "pear", "snowberry", "meat", "fish"]:
		for r in 4:
			if Props.image("food_%s_%d" % [kind, r]).get_used_rect().size.x > 4:
				sprites += 1
	check(sprites == 20 and Props.image("food_heart").get_width() > 0, "all 20 food sprites + the heart draw")
	main._start()
	var w: World = main.world
	w.auto_step = false
	check(w.sources.size() > 60, "fruit sources: %d trees, bushes and cacti" % w.sources.size())
	check(w.pools.size() >= 12, "fish pools: %d" % w.pools.size())
	var fruit := 0
	for f in w.foods:
		if String(f["type"]) == "fruit" or String(f["type"]) == "heart":
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
	w._eat(w.spawn_food(w.player.position, "heart", 1.0, 0))
	check(w.player.hp > 5.0, "a heart drop heals")
	# carcasses: big kills are chewed bite by bite
	main.run.stats["vegan"] = 0.0
	var an: Actor = w.spawn_animal("capybara", w.player.position + Vector2(8, 0), false)
	w._make_carcass(an, 20.0, false, false, "animal")
	var cc: Dictionary = w.foods[w.foods.size() - 1]
	var bites0 := int(cc["bites"])
	w.player.vel = Vector2.ZERO
	cc["p"] = w.player.position
	for i in 3:
		w._carcass_step(cc, 0.3)
	check(cc["type"] == "carcass" and int(cc["bites"]) == bites0 - 1, "standing at a carcass chews a bite off (%d -> %d)" % [bites0, int(cc["bites"])])
	check(String(w.foods[w.foods.size() - 1]["type"]) in ["meat", "heart"], "each bite pops a piece of meat")
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
	var dir := best.normalized() + danger * 2.5
	if dir.length() < 0.1:
		dir = Vector2.from_angle(w.run.time)
	return dir.limit_length(1.0)


func _sim(seconds: float, start_at: float, label: String) -> void:
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
	if main.state != END:
		main._end(false)
	main._title()
