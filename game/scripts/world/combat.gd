class_name Combat
extends RefCounted
## Fighting: the player's equipped attacks fire when you press their button (hold to
## keep attacking) and aim themselves at the best target in range (the mobile answer to
## Crab's twin-stick aim), projectiles, animal bites with a short readable wind-up,
## ultimates, movement abilities, and the one damage function.

var w: World
var cds := {}  # attack id -> seconds left
var held := {}  # attack id -> its button is down: attack whenever it's ready
var buffer := {}  # attack id -> seconds a press waits for the cooldown to end
var shown := {}  # attack id -> seconds its range marker stays up after a press
var zones: Array = []  # mud pools {p, r, t, slow}
## a press with nothing in reach swings at the air and is ready again this soon
const WHIFF_CD := 0.3
## a press during the cooldown still goes off if the cooldown ends within this
const BUFFER := 0.25
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
	zones.clear()
	shown.clear()
	held.clear()
	buffer.clear()
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
	_markers(dt)
	if p.can_process() and p.stun <= 0.0 and not p.under and dive_t <= 0.0:
		if not w.tips.has("attack") and not w.run.attacks.is_empty() and in_range(slot(0)):
			w._tip("attack", "Tap your attack (or Q / R) to strike. It aims itself; hold to keep going")
		for id in w.run.attacks:
			cds[id] = maxf(0.0, float(cds.get(id, 0.0)) - dt)
			buffer[id] = maxf(0.0, float(buffer.get(id, 0.0)) - dt)
			if float(cds[id]) <= 0.0 and (held.get(id, false) or float(buffer[id]) > 0.0):
				buffer[id] = 0.0
				if fire(id):
					cds[id] = cd_of(id)
					if w.rng.randf() * 100.0 < stat("echo"):
						queued.append({"t": 0.18, "fn": func() -> void: fire(id)})
				else:
					cds[id] = WHIFF_CD
	_animal_attacks(dt)
	_zones(dt)
	_shots(dt)
	_specials(dt)


# ------------------------------------------------------------------ pressing attacks
## The attack in slot i (0 or 1), or "".
func slot(i: int) -> String:
	return String(w.run.attacks[i]) if i < w.run.attacks.size() else ""


## A tap on an attack's button: it goes off now, or as soon as its cooldown ends.
func tap(id: String) -> void:
	if id != "":
		buffer[id] = BUFFER
		shown[id] = 0.4


## Holding an attack's button: it goes off every time it's ready.
func hold(id: String, on: bool) -> void:
	if id != "":
		held[id] = on


## Seconds between two uses of an attack.
func cd_of(id: String) -> float:
	return float(Attacks.ATTACK[id]["cd"]) * Attacks.rank_cd(w.run.rank(id)) * float(w.run.stats["cd_mult"])


## While an attack's button is down (and a moment after a press), its reach is drawn
## around you in its shape and color, and the one it would hit gets a marker.
func _markers(dt: float) -> void:
	w.fx.ranges.clear()
	var p := w.player
	for id in w.run.attacks:
		shown[id] = maxf(0.0, float(shown.get(id, 0.0)) - dt)
		if not held.get(id, false) and float(shown[id]) <= 0.0:
			continue
		var spec: Dictionary = Attacks.ATTACK[id]
		var rng := reach(id)
		var t := best_target(p.position, rng)
		w.fx.ranges.append({"shape": String(spec["shape"]), "p": p.position + Vector2(0, -p.r * 0.5), "dir": aim_dir(p.position, t),
			"r": rng, "arc": deg_to_rad(float(spec.get("arc", 30.0))), "width": float(spec.get("width", 10.0)),
			"c": _col(spec), "target": (t.position + Vector2(0, -t.r)) if t != null else Vector2.INF, "tr": t.r if t != null else 0.0,
			"blast": float(spec.get("radius", 0.0)) * area()})


## How far an attack reaches from your middle: its range, grown by Area, plus your body.
func reach(id: String) -> float:
	return float(Attacks.ATTACK[id]["range"]) * area() + w.player.r * 0.8


## Whether pressing this attack now would hit something (the bot uses this).
func in_range(id: String) -> bool:
	return best_target(w.player.position, reach(id)) != null


## Where an attack goes: at its target, else at the nearest enemy close by, else the
## way you're walking (or facing).
func aim_dir(from: Vector2, t: Actor) -> Vector2:
	if t != null:
		return (t.position - from).normalized()
	var n := best_target(from, 160.0)
	if n != null:
		return (n.position - from).normalized()
	var p := w.player
	return p.desired.normalized() if p.desired.length() > 0.1 else Vector2(p.face, 0)


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
## Attacks that need something in reach; with nothing there they swing at the air.
const NEEDS_TARGET := ["bite", "arc", "line", "lunge"]


func fire(id: String) -> bool:
	var spec: Dictionary = Attacks.ATTACK[id]
	var p := w.player
	var rng := reach(id)
	var shape := String(spec["shape"])
	var t := best_target(p.position, rng)
	var dir := aim_dir(p.position, t)
	p.face = signf(dir.x) if absf(dir.x) > 0.1 else p.face
	if t == null and shape in NEEDS_TARGET:
		# nothing in reach: a swing at the air, so the button always answers
		p.bite_t = 0.15
		w.fx.slash(p.position + dir * (p.r + 6.0) + Vector2(0, -p.r * 0.8), dir, 7.0, Color(1, 1, 1, 0.7), 0.14)
		Sfx.play(String(spec.get("sfx", "chomp")), randf_range(1.15, 1.3), -12.0)
		return false
	var windup := float(spec.get("windup", 0.0))
	p.bite_t = windup + 0.15
	var dmg := power(String(spec["scale"])) * float(spec["coef"]) * Attacks.rank_dmg(w.run.rank(id))
	var tid := t.get_instance_id() if t != null else 0
	# the tell: a lean toward the target while the attack winds up
	if windup > 0.05:
		w.fx.anim("tell", p.position + Vector2(0, -p.r), dir, windup, _col(spec), p.r)
	if shape in ["line", "arc"] and id != "peck_flurry":
		p.start_dash(dir * 60.0, 0.05)
	if windup > 0.0:
		queued.append({"t": windup, "fn": func() -> void: _land(id, dir, tid, dmg)})
	else:
		_land(id, dir, tid, dmg)
	return true


func _col(spec: Dictionary) -> Color:
	return Pal.e(String(spec.get("col", "white")))


## The foes an attack of this shape catches, from your middle toward dir.
func caught(shape: String, dir: Vector2, rng: float, spec: Dictionary) -> Array:
	var p := w.player
	var out: Array = []
	var half := deg_to_rad(float(spec.get("arc", 180.0)))
	var width := float(spec.get("width", 10.0))
	for o in w.near(p.position, rng + 20.0):
		var a: Actor = o
		if not World.hostile(p, a) or a.asleep or a.dead or a.under:
			continue
		var to := a.position - p.position
		var d := to.length() - a.r
		if d > rng:
			continue
		match shape:
			"arc", "cone":
				# outside the wedge misses, unless it's right on top of you
				if to.length() > (a.r + p.r) * 0.5 and absf(dir.angle_to(to)) > half:
					continue
			"line":
				var along := to.dot(dir)
				var side := absf(to.cross(dir))
				if along < -a.r or side > width * 0.5 + a.r:
					continue
		out.append(a)
	return out


## The moment an attack lands, after its windup: what it hits and how it looks.
func _land(id: String, dir: Vector2, tid: int, dmg: float) -> void:
	var spec: Dictionary = Attacks.ATTACK[id]
	var p := w.player
	if not World.valid(p):
		return
	var rng := reach(id)
	var shape := String(spec["shape"])
	var col := _col(spec)
	var t = instance_from_id(tid) if tid != 0 else null
	if t != null and not World.valid(t):
		t = null
	# a bite whose target got away swings at the air
	if shape in ["bite", "lunge"] and (t == null or (shape == "bite" and (t as Actor).position.distance_to(p.position) - (t as Actor).r > rng + 8.0)):
		w.fx.slash(p.position + dir * (p.r + 6.0) + Vector2(0, -p.r * 0.8), dir, 7.0, Color(1, 1, 1, 0.7), 0.14)
		return
	if t != null:
		dir = ((t as Actor).position - p.position).normalized()
	Sfx.play(String(spec.get("sfx", "chomp")), randf_range(0.9, 1.15), -3.0)
	var opts := {}
	for k in ["knock", "stun", "slow", "bleed", "poison", "poison_t", "crit_bonus"]:
		if spec.has(k):
			opts[k] = spec[k]
	match id:
		"gulp":
			var tg: Actor = t
			p.start_dash(dir * 170.0, 0.07)
			hit(tg, dmg, p, opts)
			w.fx.anim("chomp", tg.position + Vector2(0, -tg.r * 0.8), dir, 0.2, col, tg.r)
			if tg.hp <= 0.0:
				p.hp = minf(p.max_hp, p.hp + 1.0 + w.run.level * 0.3)
				w.fx.burst(p.position + Vector2(0, -p.r), Pal.e("leaf"), 4, 30.0)
		"charm_song":
			var tc: Actor = t
			w.fx.anim("notes", p.position + Vector2(0, -p.r * 1.5), dir, 0.5, col, p.position.distance_to(tc.position))
			if not tc.is_boss and tc.hp < tc.max_hp * 0.45 and w.ally_count() < int(w.run.stats["ally_max"]):
				w.make_ally(tc)
				w.fx.text(tc.position + Vector2(0, -tc.r * 2.5), "CHARMED", Pal.c("pink", 3))
				w.fx.anim("hearts", tc.position + Vector2(0, -tc.r * 1.5), dir, 0.8, col, tc.r)
			else:
				hit(tc, dmg, p, {})
		"constrict":
			var th: Actor = t
			var hold := float(spec["hold"])
			th.stun = maxf(th.stun, hold * (0.3 if th.is_boss else 1.0))
			w.fx.anim("coil", th.position + Vector2(0, -th.r * 0.6), dir, hold, col, th.r)
			var hid := th.get_instance_id()
			for k in int(spec["hits"]):
				queued.append({"t": k * hold / float(spec["hits"]), "fn": func() -> void:
					var tg = instance_from_id(hid)
					if World.valid(tg):
						hit(tg, dmg, p, {"bleed": float(spec["bleed"])})})
		"charge":
			var tl: Actor = t
			var dist := minf(rng + 10.0, p.position.distance_to(tl.position) + tl.r + 8.0)
			var dur := dist / 300.0
			p.start_dash(dir * 300.0, dur)
			p.invuln = maxf(p.invuln, dur + 0.1)
			w.fx.anim("speed", p.position, dir, dur + 0.15, col, p.r)
			var struck := {}
			var steps := maxi(2, int(dur / 0.04))
			for k in steps + 1:
				queued.append({"t": k * dur / steps, "fn": func() -> void:
					for o in w.near(p.position, p.r + 30.0):
						var a: Actor = o
						if World.hostile(p, a) and not a.asleep and not struck.has(a.get_instance_id()) and a.position.distance_to(p.position) < a.r + p.r + float(spec["width"]) * 0.5:
							struck[a.get_instance_id()] = true
							hit(a, dmg, p, {"knock": float(spec["knock"])})
							w.fx.anim("bonk", a.position + Vector2(0, -a.r), dir, 0.3, col, a.r)
							w.shake = maxf(w.shake, 2.5)})
		"spit", "stinger", "feather_darts":
			var n := int(spec.get("count", 1)) + (1 if id == "feather_darts" and w.run.rank(id) >= 3 else 0)
			for k in n:
				var off := (k - (n - 1) * 0.5) * 0.2
				_shoot(p.position + Vector2(0, -p.r), dir.rotated(off) * float(spec["speed"]), dmg, false, spec, rng)
		"egg_toss":
			var to: Vector2 = (t as Actor).position if t != null else p.position + dir * rng * 0.8
			var s := _shoot(p.position + Vector2(0, -p.r), Vector2.ZERO, dmg, false, spec, rng)
			s["lob"] = true
			s["from"] = p.position
			s["to"] = to
			s["dur"] = float(spec["flight"])
			s["radius"] = float(spec["radius"]) * area()
			w.fx.mark(to, float(s["radius"]), float(spec["flight"]), col)
		_:
			var hits := int(spec.get("hits", 1))
			var foes := caught(shape, dir, rng, spec)
			if shape == "line" and id != "headbutt" and not foes.is_empty():
				# pecks and lashes find the first thing in the line
				foes.sort_custom(func(a1: Actor, a2: Actor) -> bool: return a1.position.distance_to(p.position) < a2.position.distance_to(p.position))
				foes = [foes[0]]
			_anim_for(id, dir, rng, col, foes, spec)
			for k in hits:
				var ids: Array = []
				for f in foes:
					ids.append((f as Actor).get_instance_id())
				queued.append({"t": k * (0.09 if id == "peck_flurry" else 0.12), "fn": func() -> void:
					for fid in ids:
						var tg = instance_from_id(fid)
						if not World.valid(tg):
							continue
						var o2 := opts.duplicate()
						var dd := dmg
						if id == "jaws" and (tg as Actor).stun > 0.0:
							dd *= 2.0
							w.fx.text((tg as Actor).position + Vector2(0, -(tg as Actor).r * 2.6), "CRUNCH", Pal.e("white"))
						if id == "tentacle_lash" and not (tg as Actor).is_boss:
							(tg as Actor).vel += (p.position - (tg as Actor).position).normalized() * float(spec["pull"])
						hit(tg, dd, p, o2)
						if id == "peck_flurry":
							w.fx.anim("peck", (tg as Actor).position + Vector2(randf_range(-3, 3), -(tg as Actor).r + randf_range(-3, 3)), dir, 0.12, col, 3.0)
						if id == "kick":
							_bowl(tg, dmg * float(spec["bowl"]), dir)})
			if id == "mud_splash":
				zones.append({"p": p.position, "r": rng, "t": float(spec["pool"]), "slow": float(spec["slow"])})


## Each attack's own look at the moment it lands.
func _anim_for(id: String, dir: Vector2, rng: float, col: Color, foes: Array, spec: Dictionary) -> void:
	var p := w.player
	var mid := p.position + Vector2(0, -p.r * 0.7)
	var first: Actor = foes[0] if not foes.is_empty() else null
	var at := (first.position + Vector2(0, -first.r * 0.8)) if first != null else mid + dir * rng * 0.7
	match id:
		"headbutt":
			w.fx.anim("bonk", at, dir, 0.35, col, 6.0)
			for f in foes:
				w.fx.anim("dizzy", (f as Actor).position + Vector2(0, -(f as Actor).r * 2.2), dir, float(spec["stun"]) + 0.2, col, (f as Actor).r)
		"jaws":
			w.fx.anim("fangs", at, dir, 0.22, col, 9.0)
		"tail_whip":
			w.fx.anim("sweep", mid, dir, 0.25, col, rng)
			p.face = -p.face
		"peck_flurry":
			w.fx.anim("beak", mid, dir, 0.3, col, rng)
		"mud_splash":
			w.fx.anim("mud", p.position, dir, float(spec["pool"]), col, rng)
			w.fx.burst(p.position, Pal.c("brown", 2), 16, rng * 2.5, 2.0, 0.35)
		"pincer_snap":
			w.fx.anim("snip", at, dir, 0.3, col, 8.0)
		"quack":
			w.fx.anim("waves", mid, dir, 0.35, col, rng)
			w.fx.text(mid + dir * 14.0 + Vector2(0, -p.r * 1.4), "QUACK", Pal.c("gold", 4))
		"tentacle_lash":
			w.fx.anim("lash", mid, dir, 0.3, col, (first.position.distance_to(p.position) if first != null else rng))
		"kick":
			w.fx.anim("kick", p.position + Vector2(0, -2), dir, 0.2, col, rng)
			if first != null:
				w.fx.anim("bonk", at, dir, 0.3, col, 5.0)
		_:
			w.fx.slash(at, dir, 8.0)


## Kick: the target flies, and what it flies into gets hit too.
func _bowl(t: Actor, dmg: float, dir: Vector2) -> void:
	var tid := t.get_instance_id()
	var struck := {tid: true}
	for k in 4:
		queued.append({"t": 0.06 + k * 0.07, "fn": func() -> void:
			var tg = instance_from_id(tid)
			if not World.valid(tg):
				return
			for o in w.near((tg as Actor).position, 30.0):
				var a: Actor = o
				if struck.has(a.get_instance_id()) or not World.hostile(w.player, a) or a.asleep:
					continue
				if a.position.distance_to((tg as Actor).position) < a.r + (tg as Actor).r + 2.0:
					struck[a.get_instance_id()] = true
					hit(a, dmg, w.player, {"knock": 120.0})
					w.fx.anim("bonk", a.position + Vector2(0, -a.r), dir, 0.3, Pal.e("sand"), 5.0)})


## Mud pools: whatever stands in one is slowed.
func _zones(dt: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var z: Dictionary = zones[i]
		z["t"] = float(z["t"]) - dt
		if float(z["t"]) <= 0.0:
			zones.remove_at(i)
			continue
		for o in w.near(z["p"], float(z["r"]) + 10.0):
			var a: Actor = o
			if World.hostile(w.player, a) and a.position.distance_to(z["p"]) < float(z["r"]):
				a.slow = maxf(a.slow if a.slow_t > 0.0 else 0.0, float(z["slow"]))
				a.slow_t = maxf(a.slow_t, 0.3)


func _shoot(from: Vector2, v: Vector2, dmg: float, hostile: bool, spec: Dictionary, rng: float = 0.0) -> Dictionary:
	var n := Sprite2D.new()
	var ramp := String(spec.get("ramp", "green"))
	var texname: String = {"green": "glob_green", "purple": "glob_purple", "duck": "glob_duck", "red": "threat_glob"}.get(ramp, "glob_green")
	if spec.get("shape", "") == "lob":
		texname = "egg"
	n.texture = Props.tex(texname)
	n.rotation = snappedf(v.angle(), PI / 4.0) if v.length() > 0.0 else 0.0
	n.position = from
	w.shots.add_child(n)
	# a shot flies as far as its attack reaches, then drops
	var life := 1.2 if rng <= 0.0 or v.length() <= 0.0 else rng / v.length()
	var s := {"n": n, "p": from, "v": v, "dmg": dmg, "life": life, "hostile": hostile, "poison": float(spec.get("poison", 0.0)),
		"poison_t": float(spec.get("poison_t", 3.0)), "splash": float(spec.get("splash", 0.0)), "pierce": int(spec.get("pierce", 0)),
		"struck": {}, "col": String(spec.get("col", "white")),
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
				w.fx.anim("yolk", pos, Vector2.RIGHT, 0.5, Pal.e("lemon"), rad)
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
					if body.distance_to(s["p"]) < a2.r + 3.0 and not (s["struck"] as Dictionary).has(a2.get_instance_id()):
						(s["struck"] as Dictionary)[a2.get_instance_id()] = true
						hit(a2, float(s["dmg"]), null if s["hostile"] else w.player, {"poison": float(s["poison"]), "poison_t": float(s["poison_t"])})
						if not s["hostile"]:
							var sc := Pal.e(String(s["col"]))
							w.fx.anim("splat" if float(s["poison"]) <= 0.0 else "bubbles", body, (s["v"] as Vector2).normalized(), 0.4 if float(s["poison"]) <= 0.0 else float(s["poison_t"]), sc, a2.r)
						# Spit: the glob splashes what's next to the target
						if float(s["splash"]) > 0.0:
							for o3 in w.near(a2.position, float(s["splash"]) + 12.0):
								var a3: Actor = o3
								if a3 != a2 and World.hostile(w.player, a3) and a3.position.distance_to(a2.position) < float(s["splash"]) + a3.r:
									hit(a3, float(s["dmg"]) * 0.5, w.player, {})
						if int(s["pierce"]) > 0:
							s["pierce"] = int(s["pierce"]) - 1
							continue
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
		if w.rng.randf() * 100.0 < stat("crit") + float(opts.get("crit_bonus", 0.0)):
			dmg *= 1.8
			crit = true
			w.hitstop = maxf(w.hitstop, 0.04)
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
		t.poison_t = maxf(t.poison_t, float(opts.get("poison_t", 3.0)))
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
