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
	print("== simulated runs")
	await _sim(480.0, 0.0, "early game")
	await _sim(170.0, Run.FINAL_TIME - 5.0, "final boss")
	print("TESTS: %s" % ("PASS" if failed == 0 else "%d FAILED" % failed))
	get_tree().quit(1 if failed else 0)


func _logic() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var r := Run.new("pioneer", 0, rng)
	check(r.attacks == ["headbutt"] and r.move == "scoot", "Puddle hatches with Headbutt and Scoot")
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
	check(fruit.size() == 3 and Evolutions.get_def(fruit[0])["type"] == "fruit", "boss food offers Boss Fruits")
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


## Scores a card like a sensible player: attacks and raw power first.
func _score(r: Run, id: String) -> float:
	var d := Evolutions.get_def(id)
	var sc := 1.0 + int(d["rarity"]) * 0.8
	match String(d["type"]):
		"attack":
			sc += 3.0 if r.has(id) else (2.0 if r.attacks.size() < 2 else 0.5)
		"ultimate":
			sc += 2.5 if r.ultimate == "" or r.ultimate == id else 0.2
		"fruit":
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
					main.levelup.press("card:%d" % _best_card(main.run, main.levelup.hand))
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
