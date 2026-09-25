class_name Combat
extends RefCounted
## Fighting: the player's equipped attacks fire on their own at the best target in range
## (the mobile answer to Crab's twin-stick aim), projectiles, animal bites with a short
## readable wind-up, ultimates, movement abilities, and the one damage function.

var w: World
var cds := {}  # attack id -> seconds left
var ult_cd := 0.0
var move_cd := 0.0
var shots: Array = []  # {n, p, v, dmg, life, hostile, poison, radius, lob, t, dur, from, to, pierce}
var queued: Array = []  # delayed hits {t, fn}
var storm_t := 0.0
var storm_tick := 0.0
var hibernate_t := 0.0
var dive_t := 0.0


func _init(world: World) -> void:
	w = world


func reset() -> void:
	cds.clear()
	ult_cd = 0.0
	move_cd = 0.0
	for s in shots:
		if is_instance_valid(s["n"]):
			(s["n"] as Node).queue_free()
	shots.clear()
	queued.clear()
	storm_t = 0.0
	hibernate_t = 0.0
	dive_t = 0.0


func stat(k: String) -> float:
	return float(w.run.stats.get(k, 0.0))


# ------------------------------------------------------------------ loop
func step(dt: float) -> void:
	var p := w.player
	ult_cd = maxf(0.0, ult_cd - dt)
	move_cd = maxf(0.0, move_cd - dt)
	for i in range(queued.size() - 1, -1, -1):
		queued[i]["t"] = float(queued[i]["t"]) - dt
		if float(queued[i]["t"]) <= 0.0:
			var fn: Callable = queued[i]["fn"]
			queued.remove_at(i)
			fn.call()
	if p.can_process() and p.stun <= 0.0 and not p.under and dive_t <= 0.0:
		for id in w.run.attacks:
			cds[id] = maxf(0.0, float(cds.get(id, 0.0)) - dt)
			if float(cds[id]) <= 0.0:
				if fire(id):
					var rk := w.run.rank(id)
					cds[id] = float(Attacks.ATTACK[id]["cd"]) * Attacks.rank_cd(rk) * float(w.run.stats["cd_mult"])
					if w.rng.randf() * 100.0 < stat("echo"):
						queued.append({"t": 0.18, "fn": func() -> void: fire(id)})
	_animal_attacks(dt)
	_shots(dt)
	_specials(dt)


# ------------------------------------------------------------------ targeting
func best_target(from: Vector2, rng: float) -> Actor:
	var best: Actor = null
	var bd := INF
	for o in w.near(from, rng + 30.0):
		var a: Actor = o
		if a.is_player or a.is_ally or a.asleep or a.under or a.dead:
			continue
		var d := from.distance_to(a.position) - a.r
		if d > rng:
			continue
		# whoever just hurt you is the priority
		if a == w.player.hurt_by and w.player.since_hurt < 2.0:
			d -= 40.0
		if d < bd:
			bd = d
			best = a
	return best


func area() -> float:
	return stat("area") / 100.0


func power(scale: String) -> float:
	var base := stat("physical") if scale == "physical" else stat("ability")
	return base * stat("dmg") / 100.0


# ------------------------------------------------------------------ player attacks
func fire(id: String) -> bool:
	var spec: Dictionary = Attacks.ATTACK[id]
	var p := w.player
	var rng := float(spec["range"]) * area() + p.r * 0.8
	var t := best_target(p.position, rng)
	if t == null:
		return false
	var rk := w.run.rank(id)
	var dmg := power(String(spec["scale"])) * float(spec["coef"]) * Attacks.rank_dmg(rk)
	var dir := (t.position - p.position).normalized()
	p.face = signf(dir.x) if absf(dir.x) > 0.1 else p.face
	p.bite_t = 0.18
	Sfx.play(String(spec.get("sfx", "chomp")), randf_range(0.9, 1.15), -3.0)
	match String(spec["kind"]):
		"melee":
			hit(t, dmg, p, {"bleed": float(spec.get("bleed", 0.0)), "slow": float(spec.get("slow", 0.0)), "knock": float(spec.get("knock", 0.0))})
			w.fx.slash(t.position + Vector2(0, -t.r * 0.8), dir, t.r + 7.0)
		"multi":
			# capture the target by id: it may be freed before a later hit lands
			var tid := t.get_instance_id()
			for k in int(spec["hits"]):
				queued.append({"t": k * 0.09, "fn": func() -> void:
					var tg = instance_from_id(tid)
					if World.valid(tg):
						hit(tg, dmg, p, {"slow": float(spec.get("slow", 0.0))})
						w.fx.slash(tg.position + Vector2(randf_range(-3, 3), -tg.r * 0.8 + randf_range(-3, 3)), dir.rotated(randf_range(-0.6, 0.6)), tg.r + 4.0, Color.WHITE, 0.14)
						w.fx.burst(tg.position + Vector2(0, -tg.r), Pal.c("snow", 4), 2, 30.0)})
		"spin":
			var rad := float(spec["range"]) * area() + p.r
			for o in w.near(p.position, rad + 8.0):
				var a: Actor = o
				if World.hostile(p, a) and not a.asleep:
					hit(a, dmg, p, {"knock": float(spec["knock"])})
			w.fx.ring(p.position + Vector2(0, -p.r * 0.5), 4.0, rad, 0.25, Pal.c("snow", 4))
		"proj":
			_shoot(p.position + Vector2(0, -p.r), dir * float(spec["speed"]), dmg, false, spec)
		"spread":
			for k in int(spec["count"]) + (1 if rk >= 3 else 0):
				var off := (k - (int(spec["count"]) - 1) * 0.5) * 0.22
				_shoot(p.position + Vector2(0, -p.r), dir.rotated(off) * float(spec["speed"]), dmg, false, spec)
		"lunge":
			p.start_dash(dir * 260.0, minf(0.22, p.position.distance_to(t.position) / 260.0))
			var lid := t.get_instance_id()
			queued.append({"t": 0.12, "fn": func() -> void:
				var tg = instance_from_id(lid)
				if World.valid(tg) and tg.position.distance_to(p.position) < tg.r + p.r + 14.0:
					hit(tg, dmg, p, {"knock": 160.0})
					w.shake = maxf(w.shake, 2.0)})
		"lob":
			var s := _shoot(p.position + Vector2(0, -p.r), Vector2.ZERO, dmg, false, spec)
			s["lob"] = true
			s["from"] = p.position
			s["to"] = t.position
			s["dur"] = 0.5
			s["radius"] = float(spec["radius"]) * area()
		"nova":
			var rad2 := float(spec["range"]) * area() + p.r
			for o in w.near(p.position, rad2):
				var a2: Actor = o
				if World.hostile(p, a2) and not a2.asleep:
					hit(a2, dmg, p, {"slow": float(spec["slow"])})
			w.fx.burst(p.position, Pal.c("brown", 2), 16, rad2 * 2.5, 2.0, 0.35)
		"cone":
			var ln := float(spec["range"]) * area() + p.r
			for o in w.near(p.position, ln):
				var a3: Actor = o
				if World.hostile(p, a3) and absf(dir.angle_to(a3.position - p.position)) < 0.55 and not a3.asleep:
					hit(a3, dmg, p, {"stun": float(spec["stun"])})
			w.fx.cone(p.position + Vector2(0, -p.r * 0.6), dir, ln, 1.1, 0.3, Pal.c("gold", 4))
			w.fx.text(p.position + dir * 14.0 + Vector2(0, -p.r * 2.0), "QUACK", Pal.c("gold", 4))
		"charm":
			if not t.is_boss and t.hp < t.max_hp * 0.45 and w.ally_count() < int(w.run.stats["ally_max"]):
				w.make_ally(t)
				w.fx.text(t.position + Vector2(0, -t.r * 2.5), "CHARMED", Pal.c("pink", 3))
			else:
				hit(t, dmg, p, {})
				w.fx.burst(t.position + Vector2(0, -t.r), Pal.c("pink", 3), 4, 30.0)
	return true


func _shoot(from: Vector2, v: Vector2, dmg: float, hostile: bool, spec: Dictionary) -> Dictionary:
	var n := Sprite2D.new()
	var ramp := String(spec.get("ramp", "green"))
	var texname: String = {"green": "glob_green", "purple": "glob_purple", "duck": "glob_duck", "red": "threat_glob"}.get(ramp, "glob_green")
	if spec.get("kind", "") == "lob":
		texname = "egg"
	n.texture = Props.tex(texname)
	n.rotation = snappedf(v.angle(), PI / 4.0) if v.length() > 0.0 else 0.0
	n.position = from
	w.shots.add_child(n)
	var s := {"n": n, "p": from, "v": v, "dmg": dmg, "life": 1.2, "hostile": hostile, "poison": float(spec.get("poison", 0.0)),
		"radius": 0.0, "lob": false, "t": 0.0, "dur": 0.0, "from": from, "to": from}
	shots.append(s)
	return s


func _shots(dt: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var n: Sprite2D = s["n"]
		var done := false
		if s["lob"]:
			s["t"] = float(s["t"]) + dt
			var u := clampf(float(s["t"]) / float(s["dur"]), 0.0, 1.0)
			var pos := (s["from"] as Vector2).lerp(s["to"], u)
			n.position = (pos + Vector2(0, -sin(u * PI) * 24.0)).floor()
			if u >= 1.0:
				var rad := float(s["radius"])
				for o in w.near(pos, rad):
					var a: Actor = o
					if (s["hostile"] and (a.is_player or a.is_ally)) or (not s["hostile"] and World.hostile(w.player, a)):
						hit(a, float(s["dmg"]), w.player if not s["hostile"] else null, {})
				w.fx.ring(pos, 2.0, rad, 0.3, Pal.c("snow", 4))
				w.fx.burst(pos, Pal.c("gold", 3), 10, 60.0, 1.0, 0.4)
				done = true
		else:
			s["life"] = float(s["life"]) - dt
			s["p"] = (s["p"] as Vector2) + (s["v"] as Vector2) * dt
			n.position = (s["p"] as Vector2).floor()
			if float(s["life"]) <= 0.0 or w.map.is_wall(s["p"]):
				done = true
			else:
				for o in w.near(s["p"], 14.0):
					var a2: Actor = o
					var foe := (a2.is_player or a2.is_ally) if s["hostile"] else World.hostile(w.player, a2)
					if not foe or a2.asleep:
						continue
					var body := a2.position + Vector2(0, -a2.r * 0.8)
					if body.distance_to(s["p"]) < a2.r + 3.0:
						hit(a2, float(s["dmg"]), null if s["hostile"] else w.player, {"poison": float(s["poison"])})
						done = true
						break
		if done:
			n.queue_free()
			shots.remove_at(i)


# ------------------------------------------------------------------ animals fight
func _animal_attacks(dt: float) -> void:
	for a in w.actors:
		if a.is_player or a.dead or a.stun > 0.0 or a.asleep or a.under:
			continue
		if a.windup > 0.0:
			a.windup -= dt
			if a.windup <= 0.0:
				var t = a.target
				if World.valid(t) and a.position.distance_to(t.position) <= a.r + t.r + 9.0:
					var dmg := a.dmg * (1.0 + float(w.run.stats["ally_dmg"]) / 100.0 + float(w.run.stats["social"]) * 0.03 if a.is_ally else 1.0)
					hit(t, dmg, a, {})
					w.fx.slash(t.position + Vector2(0, -t.r * 0.8), (t.position - a.position).normalized(), t.r + 5.0, Pal.c("red", 4) if t.is_player else Color.WHITE, 0.16)
					a.bite_t = 0.2
					if a.is_ally:
						Sfx.play("chomp", 1.4, -8.0)
				a.attack_cd = 1.0 + randf() * 0.4
			continue
		if a.state != "chase" or a.attack_cd > 0.0 or not World.valid(a.target):
			continue
		var t2 = a.target
		if not World.hostile(a, t2) and not (a.role == "predator" and not t2.is_player and not t2.is_ally):
			continue
		if a.position.distance_to(t2.position) <= a.r + t2.r + 4.0:
			a.windup = 0.32 if not a.is_ally else 0.1
			if t2.is_player:
				a.hit_flash(Pal.c("red", 3))
	# ram: horns hurt what you touch
	var ram := stat("ram")
	if ram > 0.0:
		var p := w.player
		for o in w.near(p.position, p.r * 2.0 + 10.0):
			var a2: Actor = o
			if World.hostile(p, a2) and not a2.asleep and a2.position.distance_to(p.position) < a2.r + p.r:
				if float(a2.get_meta("ram_t", 0.0)) <= w.run.time:
					a2.set_meta("ram_t", w.run.time + 0.6)
					hit(a2, stat("physical") * ram / 100.0, p, {"knock": 90.0})


# ------------------------------------------------------------------ damage
func hit(t: Actor, amount: float, src: Actor, opts: Dictionary) -> void:
	if t.dead or t.untouchable():
		return
	var dmg := amount
	var crit := false
	var p := w.player
	if src == p:
		if w.rng.randf() * 100.0 < stat("crit"):
			dmg *= 1.8
			crit = true
		if t.hp < t.max_hp * 0.5:
			dmg *= 1.0 + stat("execute") / 100.0
		if p.hp < p.max_hp * 0.5:
			dmg *= 1.0 + stat("temper") / 100.0
		if stat("poison") > 0.0:
			t.poison = maxf(t.poison, stat("poison"))
			t.poison_t = 3.0
	if t.is_player:
		if w.rng.randf() * 100.0 < stat("evasion"):
			w.fx.text(t.position + Vector2(0, -t.r * 2.0), "DODGE", Pal.c("snow", 4))
			return
		dmg *= 1.0 + float(w.run.stats["duck_taken"]) / 100.0
		var herd := stat("herd") * mini(w.ally_count(), 5)
		var arm := t.armor + herd + (10.0 if hibernate_t > 0.0 else 0.0)
		dmg *= 20.0 / (20.0 + arm)
		if w.bosses.final_active:
			dmg *= 1.0
		# thorns
		w.on_player_hit()
		if World.valid(src) and stat("thorns") > 0.0:
			src.hp -= dmg * stat("thorns") / 100.0
			src.hit_flash()
			src.hurt_by = p
	else:
		dmg *= 20.0 / (20.0 + t.armor)
	t.hp -= dmg
	t.since_hurt = 0.0
	if src == p and stat("lifesteal") > 0.0:
		p.hp = minf(p.max_hp, p.hp + dmg * stat("lifesteal") / 100.0)
	t.hit_flash(Color.WHITE if not t.is_player else Pal.c("red", 3))
	if src:
		t.hurt_by = src
		if not t.is_player:
			t.angry_t = 5.0
			if t.role in ["hybrid", "predator", "mimic"] or t.is_ally:
				t.target = src
	if opts.has("knock") and not t.is_boss:
		var kd := (t.position - (src.position if src else t.position)).normalized()
		t.vel += kd * float(opts["knock"]) * clampf(10.0 / t.r, 0.3, 1.5)
	if float(opts.get("stun", 0.0)) > 0.0:
		t.stun = maxf(t.stun, float(opts["stun"]) * (0.3 if t.is_boss else 1.0))
	if float(opts.get("slow", 0.0)) > 0.0:
		t.slow = float(opts["slow"])
		t.slow_t = 2.0
	if float(opts.get("poison", 0.0)) > 0.0:
		t.poison = maxf(t.poison, float(opts["poison"]) * (1.0 + stat("ability") * 0.03))
		t.poison_t = 3.0
	if float(opts.get("bleed", 0.0)) > 0.0:
		t.bleed_t = 3.0
	var head := t.position + Vector2(0, -t.r * 2.0 - 2.0)
	if t.is_player:
		w.fx.text(head, str(ceili(dmg)), Pal.c("red", 3))
		w.shake = maxf(w.shake, 3.0)
		w.hitstop = 0.04
		Sfx.play("hurt", randf_range(0.9, 1.1))
	elif src == p or (src and src.is_ally):
		w.fx.text(head + Vector2(randf_range(-3, 3), 0), str(ceili(dmg)) + ("!" if crit else ""), Pal.c("gold", 4) if crit else Color.WHITE, crit)
		if crit:
			w.hitstop = 0.03


# ------------------------------------------------------------------ buttons
func use_move() -> bool:
	var p := w.player
	var id := w.run.move
	if id == "" or move_cd > 0.0 or p.stun > 0.0 or not w.running:
		return false
	var spec: Dictionary = Attacks.MOVE[id]
	var dir := w.input_dir.normalized() if w.input_dir.length() > 0.2 else Vector2(p.face, 0)
	var dist := float(spec["dist"])
	if id == "paddle" and w.map.water_at(p.position) != 0:
		dist *= 1.5
	var tm := float(spec["time"])
	p.start_dash(dir * dist / tm, tm)
	if spec.get("air", false):
		p.start_air(tm)
	if spec.get("under", false):
		p.under = true
		queued.append({"t": tm, "fn": func() -> void:
			p.under = false
			w.fx.burst(p.position, Pal.c("brown", 2), 12, 50.0, 1.0, 0.4)})
	if spec.get("invuln", false):
		p.invuln = tm + 0.05
	move_cd = float(spec["cd"]) * float(w.run.stats["cd_mult"])
	w.fx.burst(p.position, Pal.c("snow", 4), 6, 40.0, 1.0, 0.3)
	Sfx.play("dash", randf_range(0.9, 1.1))
	return true


func move_max() -> float:
	var id := w.run.move
	return float(Attacks.MOVE[id]["cd"]) * float(w.run.stats["cd_mult"]) if id != "" else 1.0


func ult_max() -> float:
	var id := w.run.ultimate
	return float(Attacks.ULT[id]["cd"]) * float(w.run.stats["cd_mult"]) if id != "" else 1.0


func use_ult() -> bool:
	var p := w.player
	var id := w.run.ultimate
	if id == "" or ult_cd > 0.0 or p.stun > 0.0 or not w.running:
		return false
	var spec: Dictionary = Attacks.ULT[id]
	var rk := w.run.rank(id)
	ult_cd = float(spec["cd"]) * float(w.run.stats["cd_mult"])
	match id:
		"mega_quack":
			var rad := float(spec["radius"]) * area()
			var dmg := power("ability") * float(spec["coef"]) * Attacks.rank_dmg(rk)
			for o in w.near(p.position, rad):
				var a: Actor = o
				if World.hostile(p, a):
					hit(a, dmg, p, {"stun": float(spec["stun"]), "knock": 120.0})
			w.fx.ring(p.position, 4.0, rad, 0.5, Pal.c("gold", 4))
			w.fx.ring(p.position, 2.0, rad * 0.7, 0.4, Pal.e("white"))
			w.fx.text(p.position + Vector2(0, -p.r * 2.5), "MEGA QUACK", Pal.c("gold", 4), true, 1.1)
			w.shake = 6.0
			Sfx.play("quack_big")
		"body_slam":
			p.start_air(0.45)
			p.invuln = 0.5
			queued.append({"t": 0.45, "fn": func() -> void:
				var rad2 := float(spec["radius"]) * area() * (0.6 + p.r / 12.0)
				var dmg2 := power("physical") * float(spec["coef"]) * Attacks.rank_dmg(rk) * (0.7 + p.r / 18.0)
				for o in w.near(p.position, rad2):
					var a2: Actor = o
					if World.hostile(p, a2):
						hit(a2, dmg2, p, {"knock": 200.0, "stun": 0.6})
				w.fx.ring(p.position, 4.0, rad2, 0.4, Pal.c("brown", 3))
				w.fx.burst(p.position, Pal.c("brown", 2), 20, 90.0, 2.0, 0.5)
				w.shake = 7.0
				Sfx.play("thud", 0.7)})
		"duck_dive":
			p.under = true
			dive_t = float(spec["dur"])
			p.invuln = dive_t + 0.1
			w.fx.burst(p.position, Pal.c("blue", 4), 14, 60.0, 1.0, 0.4)
			Sfx.play("splash")
			queued.append({"t": dive_t, "fn": func() -> void:
				p.under = false
				var rad3 := float(spec["radius"]) * area()
				var dmg3 := power("physical") * float(spec["coef"]) * Attacks.rank_dmg(rk)
				for o in w.near(p.position, rad3):
					var a3: Actor = o
					if World.hostile(p, a3):
						hit(a3, dmg3, p, {"knock": 180.0})
				w.fx.ring(p.position, 4.0, rad3, 0.35, Pal.c("blue", 4))
				w.fx.burst(p.position, Pal.c("blue", 4), 24, 100.0, 1.0, 0.6, 120.0)
				Sfx.play("splash", 0.8)})
		"hibernate":
			hibernate_t = float(spec["dur"])
			p.hp = minf(p.max_hp, p.hp + p.max_hp * float(spec["heal"]) * (1.0 + 0.2 * (rk - 1)))
			w.fx.text(p.position + Vector2(0, -p.r * 2.5), "ZZZ", Pal.c("blue", 4), true)
			Sfx.play("heal")
		"duckling_parade":
			for k in int(spec["count"]) + rk - 1:
				var d := w.spawn_animal("duckling", p.position + Vector2.from_angle(TAU * k / 4.0) * 16.0)
				w.make_ally(d, float(spec["dur"]))
			Sfx.play("quack", 1.5)
		"molt_storm":
			storm_t = float(spec["dur"])
			storm_tick = 0.0
			Sfx.play("flap")
	return true


func _specials(dt: float) -> void:
	var p := w.player
	hibernate_t = maxf(0.0, hibernate_t - dt)
	dive_t = maxf(0.0, dive_t - dt)
	if storm_t > 0.0:
		storm_t -= dt
		storm_tick -= dt
		var spec: Dictionary = Attacks.ULT["molt_storm"]
		var rad := float(spec["radius"]) * area()
		for k in 3:
			var a := w.run.time * 6.0 + TAU * k / 3.0
			w.fx.burst(p.position + Vector2.from_angle(a) * rad * 0.7 + Vector2(0, -p.r), Pal.c("duck", 4), 1, 10.0, 1.0, 0.3)
		if storm_tick <= 0.0:
			storm_tick = 0.25
			var dmg := power("ability") * float(spec["coef"]) * Attacks.rank_dmg(w.run.rank("molt_storm"))
			for o in w.near(p.position, rad):
				var a2: Actor = o
				if World.hostile(p, a2):
					hit(a2, dmg, p, {})


## A hostile shot fired by a boss or animal.
func enemy_shot(from: Vector2, v: Vector2, dmg: float) -> void:
	_shoot(from, v, dmg, true, {"ramp": "red"})
