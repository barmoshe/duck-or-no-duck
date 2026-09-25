class_name Brain
extends RefCounted
## Animal and ally decisions. think() picks a state and target a few times a second;
## follow() turns that into a steering vector every frame. The ecosystem: prey graze
## and flee, predators hunt anything smaller (you included), hybrids fight back,
## scavengers steal food, mimics sleep until you get close, allies guard you.


static func sight(w: World, a: Actor) -> float:
	var s := 80.0 + a.r * 5.0
	if w.run.is_night():
		s *= 1.4 if Species.get_def(a.species).get("night", false) else 0.75
	return s


static func think(w: World, a: Actor) -> void:
	if a.is_ally:
		_think_ally(w, a)
		return
	var p := w.player
	var s := sight(w, a)
	if a.asleep:
		if World.valid(p) and a.position.distance_to(p.position) < 22.0 + p.r:
			a.asleep = false
			a.state = "chase"
			a.target = p
			a.angry_t = 8.0
			w.fx.text(a.position + Vector2(0, -a.r * 2.5), "!", Pal.c("red", 3), true)
			Sfx.play("hiss")
		return
	var stealth := 1.0 - float(w.run.stats["stealth"]) / 100.0
	var threat: Actor = null
	var td := INF
	var prey: Actor = null
	var pd := INF
	for o in w.near(a.position, s):
		var oc: Actor = o
		if oc == a or oc.under:
			continue
		var d := a.position.distance_to(oc.position)
		var seen := d if not oc.is_player else d / maxf(0.3, stealth)
		if seen > s:
			continue
		var dangerous := oc.is_player or oc.is_ally or oc.is_boss or oc.role == "predator" or (oc.role == "hybrid" and oc.angry_t > 0.0)
		if dangerous and oc.r > a.r * 0.85 and d < td:
			threat = oc
			td = d
		if oc.r < a.r * 1.15 and oc.species != a.species and not oc.is_boss and not oc.asleep:
			var dd := d * (0.7 if (oc.is_player or oc.is_ally) else 1.0)
			if dd < pd:
				prey = oc
				pd = dd
	# a creature that was just hit and can fight, fights
	if a.angry_t > 0.0 and World.valid(a.target) and a.role != "prey" and a.role != "scavenger":
		a.state = "chase"
		return
	if a.angry_t > 0.0 and World.valid(a.hurt_by) and a.role in ["hybrid", "predator", "mimic"]:
		a.state = "chase"
		a.target = a.hurt_by
		return
	a.target = null
	match a.role:
		"prey":
			if threat and (threat.r > a.r * 0.9 or a.hp < a.max_hp):
				a.state = "flee"
				a.target = threat
			else:
				a.state = "graze"
		"scavenger":
			if threat and threat.r > a.r * 1.3 and td < s * 0.5:
				a.state = "flee"
				a.target = threat
			else:
				a.state = "scavenge"
		"hybrid":
			if threat and threat.r > a.r * 1.5 and td < s * 0.6:
				a.state = "flee"
				a.target = threat
			else:
				a.state = "graze"
		"predator", "mimic":
			if threat and threat.r > a.r * 1.6 and td < s * 0.5:
				a.state = "flee"
				a.target = threat
			elif prey:
				a.state = "chase"
				a.target = prey
				if w.run.pressure >= 1 and prey.is_player:
					# pressure 1: predators call their friends
					for o in w.near(a.position, 90.0):
						var oc2: Actor = o
						if oc2.role == "predator" and oc2 != a and not World.valid(oc2.target):
							oc2.target = prey
							oc2.state = "chase"
			else:
				a.state = "wander"
	a.goal = {}
	if a.state == "graze":
		var bd := 110.0
		for pl in w.plants:
			if pl["alive"]:
				var d := (pl["p"] as Vector2).distance_to(a.position)
				if d < bd:
					bd = d
					a.goal = pl
	elif a.state == "scavenge":
		var bdf := 150.0
		for f in w.foods:
			if int(f["mut"]) == 0:
				var d2 := (f["p"] as Vector2).distance_to(a.position)
				if d2 < bdf:
					bdf = d2
					a.goal = f
	if (a.state == "wander" or a.state == "graze") and w.rng.randf() < 0.3:
		a.wander = a.wander.rotated(w.rng.randf_range(-1.3, 1.3))


static func _think_ally(w: World, a: Actor) -> void:
	var p := w.player
	var best: Actor = null
	var bd := INF
	for o in w.near(p.position, 120.0):
		var oc: Actor = o
		if World.hostile(a, oc) and not oc.asleep and not oc.under:
			var d := a.position.distance_to(oc.position)
			if d < bd:
				bd = d
				best = oc
	if best:
		a.state = "chase"
		a.target = best
	else:
		a.state = "heel"
		a.target = p


static func follow(w: World, a: Actor) -> void:
	var dir := Vector2.ZERO
	var t = a.target
	match a.state:
		"flee":
			if World.valid(t):
				dir = (a.position - t.position).normalized()
		"chase":
			if World.valid(t):
				var to: Vector2 = t.position - a.position
				dir = to.normalized()
				if to.length() < a.r + t.r:
					dir *= 0.2
			else:
				a.state = "wander"
		"heel":
			if World.valid(t):
				var to2: Vector2 = t.position - a.position
				if to2.length() > 34.0:
					dir = to2.normalized()
		"graze":
			var best: Dictionary = a.goal
			if not best.is_empty() and best.get("alive", false):
				var to3: Vector2 = (best["p"] as Vector2) - a.position
				dir = to3.normalized() * 0.5
				if to3.length() < a.r + 4.0:
					a.eat_t += 0.2
					if a.eat_t > 0.6:
						a.eat_t = 0.0
						w.eat_plant(best)
			else:
				dir = a.wander * 0.4
		"scavenge":
			var bestf: Dictionary = a.goal
			if not bestf.is_empty() and float(bestf.get("life", 0.0)) > 0.0:
				var to4: Vector2 = (bestf["p"] as Vector2) - a.position
				dir = to4.normalized()
				if to4.length() < a.r + 4.0:
					bestf["life"] = 0.0  # stolen!
					if a.position.distance_to(w.player.position) < 160.0:
						w.fx.text(a.position + Vector2(0, -a.r * 2.0), "STOLEN", Pal.c("red", 3))
			else:
				dir = a.wander * 0.45
		_:
			dir = a.wander * 0.45
	# drift back toward home biome, keep off the walls
	if a.state in ["wander", "graze", "scavenge"] and a.position.distance_to(a.home) > 260.0:
		dir += (a.home - a.position).normalized() * 0.5
	if a.water_only and w.map.water_at(a.position + dir * 12.0) == 0:
		dir = -dir * 0.5
	a.desired = dir.limit_length(1.0)
