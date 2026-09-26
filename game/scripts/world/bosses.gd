class_name Bosses
extends RefCounted
## Crab-style boss rounds. At each mark on the timer bar a boss arrives and an arena
## ring closes around you (its edge and trees are terrain: chargers get stunned on
## them). Kill it, or survive: after 75 s it gives up and leaves, but its Boss Fruit
## (a major mutation) drops either way. Burrows hide you. The final boss, the Great
## Mallard, brings BREADFALL after 40 s: survive 2 minutes of it and the bread wins.

const GIVE_UP := 75.0
const ARENA_R := 150.0
const FINAL_BREAD_AFTER := 40.0
const BREADFALL := 120.0

var w: World
var boss: Actor = null
var boss_id := ""
var timer := 0.0
var final_started := false
var final_active := false
var bread_on := false
var bread_left := 0.0
var bread_t := 0.0
var falls: Array = []  # {p, t, dur, r, n}
var rings: Array = []  # boss shockwaves {p, t, dur, rmax, dmg, hit}
var arena_on := false
var arena_c := Vector2.ZERO
var arena_r := ARENA_R
var arena_node: Node2D
var fight_t := 0.0


func _init(world: World) -> void:
	w = world


func reset() -> void:
	boss = null
	boss_id = ""
	timer = 0.0
	final_started = false
	final_active = false
	bread_on = false
	falls.clear()
	rings.clear()
	_arena(false)


func active() -> bool:
	return World.valid(boss)


func _arena(on: bool) -> void:
	arena_on = on
	if arena_node and is_instance_valid(arena_node):
		arena_node.queue_free()
		arena_node = null
	if on:
		arena_c = w.player.position
		arena_node = ArenaRing.new()
		arena_node.position = arena_c
		(arena_node as ArenaRing).radius = arena_r
		w.add_child(arena_node)


func hatch(id: String) -> void:
	if active():
		return
	var p := w.player.position
	# clear the player out of a burrow: the arena shows up where you are
	w.player.under = false
	arena_r = ARENA_R * (1.25 if id == "great_mallard" else 1.0)
	_arena(true)
	var spot := p + Vector2.from_angle(w.rng.randf() * TAU) * arena_r * 0.6
	if w.map.is_wall(spot):
		spot = p + (Vector2(MapGen.SIZE, MapGen.SIZE) * 0.5 - p).normalized() * arena_r * 0.6
	boss = w.spawn_animal(id, spot, false)
	boss.target = w.player
	boss.state = "chase"
	boss_id = id
	timer = GIVE_UP * (0.8 if w.run.pressure >= 4 else 1.0)
	fight_t = 0.0
	# clear small fry out of the arena
	for a in w.actors:
		if not a.is_player and not a.is_boss and not a.is_ally and a.position.distance_to(arena_c) < arena_r:
			a.position = arena_c + (a.position - arena_c).normalized() * (arena_r + 30.0)
	var d := Species.get_def(id)
	w.banner.emit(String(d["name"]).to_upper(), "Survive or defeat it!" if id != "great_mallard" else "The final boss")
	Sfx.play("boss")
	w.shake = 5.0


func start_final() -> void:
	final_started = true
	final_active = true
	hatch("great_mallard")
	timer = 0.0


func on_boss_dead(a: Actor) -> void:
	w.drop_mutagen(a.position, 5)
	w.drop_food(a.position, 40.0, true, false, false)
	w.run.bosses_killed += 1
	w.fx.burst(a.position, Pal.c("gold", 4), 40, 120.0, 2.0, 1.0)
	w.shake = 8.0
	_arena(false)
	if a.species == "great_mallard":
		_win("You beat the Great Mallard")
		return
	boss = null
	w.boss_fruit.emit(a.species)


func _give_up() -> void:
	var b := boss
	w.fx.text(b.position + Vector2(0, -b.r * 2.5), "...forget it", Ui.DIM, false, 1.5)
	w.fx.burst(b.position, Pal.c("brown", 3), 20, 60.0, 2.0, 0.6)
	w.banner.emit("%s GAVE UP" % String(Species.get_def(b.species)["name"]).to_upper(), "It left its Boss Fruit behind")
	w.run.bosses_survived += 1
	b.dead = true
	b.visible = false
	w.actors.erase(b)
	b.queue_free()
	boss = null
	_arena(false)
	w.boss_fruit.emit(boss_id)


func _win(why: String) -> void:
	final_active = false
	bread_on = false
	w.run.won = true
	w.running = false
	for f in falls:
		(f["n"] as Node).queue_free()
	falls.clear()
	_arena(false)
	Sfx.play("win")
	w.banner.emit("DUCK!", why)
	w.run_won.emit()


func step(dt: float) -> void:
	if World.valid(boss):
		fight_t += dt
		if final_active:
			if not bread_on and fight_t > FINAL_BREAD_AFTER:
				bread_on = true
				bread_left = BREADFALL * (1.3 if w.run.pressure >= 5 else 1.0)
				w.banner.emit("BREADFALL", "Survive %d seconds" % int(bread_left))
				Sfx.play("boss")
		else:
			timer -= dt
			if timer <= 0.0:
				_give_up()
				return
	if bread_on:
		bread_left -= dt
		bread_t -= dt
		if bread_t <= 0.0:
			bread_t = 0.5
			_drop_bread()
		if bread_left <= 0.0:
			if World.valid(boss):
				w.fx.text(boss.position + Vector2(0, -60), "*POP*", Pal.c("gold", 4), true, 1.5)
				w.fx.burst(boss.position, Pal.c("sandy", 4), 60, 160.0, 3.0, 1.2)
				boss.dead = true
				boss.visible = false
			_win("The Mallard ate too much bread and popped")
			return
	for i in range(falls.size() - 1, -1, -1):
		var f: Dictionary = falls[i]
		f["t"] = float(f["t"]) + dt
		var u := float(f["t"]) / float(f["dur"])
		var n: Sprite2D = f["n"]
		n.position = ((f["p"] as Vector2) + Vector2(0, -(1.0 - u) * 160.0)).floor()
		if u >= 1.0:
			var r := float(f["r"])
			for o in w.near(f["p"], r + 10.0):
				var a: Actor = o
				if a.position.distance_to(f["p"]) < r + a.r * 0.5:
					if a.is_boss:
						a.hp -= a.max_hp * 0.01
						a.hit_flash()
					else:
						w.combat.hit(a, 10.0 + w.run.level * 0.4, null, {"knock": 120.0})
			w.fx.burst(f["p"], Pal.c("sandy", 3), 12, 70.0, 2.0, 0.5, 80.0)
			w.fx.ring(f["p"], 2.0, r, 0.25, Pal.c("sandy", 4))
			Sfx.play("thud", randf_range(0.8, 1.1), -6.0)
			n.queue_free()
			falls.remove_at(i)
	for i in range(rings.size() - 1, -1, -1):
		var g: Dictionary = rings[i]
		g["t"] = float(g["t"]) + dt
		var u2 := float(g["t"]) / float(g["dur"])
		if u2 >= 1.0:
			rings.remove_at(i)
			continue
		var rr := float(g["rmax"]) * u2
		var p := w.player
		if not g["hit"] and not p.untouchable() and absf(p.position.distance_to(g["p"]) - rr) < 8.0 + p.r:
			g["hit"] = true
			w.combat.hit(p, float(g["dmg"]), boss, {"knock": 200.0, "stun": 0.3})


func _drop_bread() -> void:
	var c := arena_c if arena_on else w.player.position
	var p := c + Vector2.from_angle(w.rng.randf() * TAU) * w.rng.randf_range(0.0, arena_r * 0.9)
	if w.rng.randf() < 0.35:
		p = w.player.position + w.player.vel * 0.6
	var n := Sprite2D.new()
	n.texture = Props.tex("bread_big")
	n.z_index = 45
	w.shots.add_child(n)
	falls.append({"p": p, "t": 0.0, "dur": 1.2, "r": 18.0, "n": n})
	w.fx.mark(p, 18.0, 1.2, Pal.c("red", 3))


# ------------------------------------------------------------------ patterns
func brain(b: Actor, dt: float) -> void:
	var p := w.player
	if not World.valid(p):
		b.desired = Vector2.ZERO
		return
	var to := p.position - b.position
	# a hidden player: the boss circles, confused
	if p.under:
		b.desired = Vector2.from_angle(w.run.time) * 0.4
		b.state = "wander"
		return
	b.target = p
	b.state = "chase"
	var hurt := b.hp < b.max_hp * 0.5
	if hurt and not b.has_meta("phase2"):
		_enrage(b)
	if b.has_meta("bonk"):
		b.remove_meta("bonk")
		if b.phase in ["charge", "roll", "hop"]:
			b.stun = 1.8
			b.phase = ""
			b.dash_t = 0.0
			w.fx.text(b.position + Vector2(0, -b.r * 2.5), "BONK", Pal.c("gold", 4), true)
			w.shake = 5.0
			Sfx.play("thud", 0.6)
	if b.phase == "":
		b.boss_t += dt
		b.desired = to.normalized() * (0.75 if hurt else 0.6)
		b.under = false
		var gap := (2.4 if hurt else 3.2) * (0.8 if w.run.pressure >= 3 else 1.0)
		if b.boss_t > gap and b.stun <= 0.0:
			b.boss_t = 0.0
			b.boss_cycle += 1
			_pick_phase(b)
		return
	b.phase_t -= dt
	b.desired = Vector2.ZERO
	match b.phase:
		"windup_charge":
			b.face = signf(to.x) if absf(to.x) > 1.0 else b.face
			if b.phase_t <= 0.0:
				b.phase = "charge"
				b.phase_t = 0.8
				b.start_dash(to.normalized() * 240.0, 0.8)
				Sfx.play("dash", 0.6)
		"charge":
			if b.phase_t <= 0.0:
				b.phase = ""
			elif b.position.distance_to(p.position) < b.r + p.r and float(b.get_meta("hit_t", 0.0)) <= w.run.time:
				b.set_meta("hit_t", w.run.time + 0.6)
				w.combat.hit(p, b.dmg * 1.2, b, {"knock": 220.0})
		"windup_ring":
			if b.phase_t <= 0.0:
				var rmax := 150.0 if b.species == "great_mallard" else 110.0
				rings.append({"p": b.position, "t": 0.0, "dur": 0.8, "rmax": rmax, "dmg": b.dmg * 1.1, "hit": false})
				w.fx.ring(b.position, b.r, rmax, 0.8, Pal.c("gold", 4))
				w.fx.text(b.position + Vector2(0, -b.r * 2.5), "QUAAACK" if b.species == "great_mallard" else "HONK", Pal.c("gold", 4), true)
				Sfx.play("quack_big" if b.species == "great_mallard" else "honk")
				w.shake = 6.0
				b.bite_t = 0.4
				b.phase = ""
		"windup_cone":
			b.face = signf(to.x) if absf(to.x) > 1.0 else b.face
			if b.phase_t <= 0.0:
				var dir := to.normalized()
				if to.length() < 130.0:
					w.combat.hit(p, b.dmg * 1.2, b, {"stun": 0.6, "knock": 160.0})
				w.fx.cone(b.position + Vector2(0, -b.r), dir, 130.0, 1.2, 0.35, Pal.c("red", 3))
				Sfx.play("honk")
				b.phase = ""
		"summon":
			if b.phase_t <= 0.0:
				var n := 5 if b.species == "great_mallard" else 3
				for k in n:
					var d := w.spawn_animal("duckling", b.position + Vector2.from_angle(TAU * k / n) * (b.r + 12.0))
					d.target = p
					d.state = "chase"
					d.angry_t = 30.0
				Sfx.play("quack", 1.4)
				b.phase = ""
		"flood":
			# Quackaconda floods the arena: shallow water everywhere slows you
			if b.phase_t <= 0.0:
				b.phase = ""
				w.set_meta("flood_t", w.run.time + 8.0)
				if arena_node:
					(arena_node as ArenaRing).flood_t = 8.0
				w.fx.ring(arena_c, 10.0, arena_r, 0.8, Pal.c("blue", 4))
				w.banner.emit("FLOOD", "The arena turns to shallow water")
				Sfx.play("splash", 0.6)
		"spit":
			if b.phase_t <= 0.0:
				for k in 5:
					var ang := to.angle() + (k - 2) * 0.22
					w.combat.enemy_shot(b.position + Vector2(0, -b.r), Vector2.from_angle(ang) * 120.0, b.dmg * 0.6)
				Sfx.play("spit", 0.7)
				b.phase = ""
		"roll":
			if b.phase_t <= 0.0:
				b.phase = ""
				b.armor = float(Species.get_def(b.species).get("armor", 0.0))
			elif b.dash_t <= 0.0:
				b.start_dash(to.normalized().rotated(w.rng.randf_range(-0.4, 0.4)) * 200.0, 0.9)
			if b.position.distance_to(p.position) < b.r + p.r and not p.untouchable():
				if float(b.get_meta("roll_hit", 0.0)) <= w.run.time:
					b.set_meta("roll_hit", w.run.time + 0.6)
					w.combat.hit(p, b.dmg, b, {"knock": 220.0})
		"hop":
			# Duckaroo: big hops that land with a stomp ring
			if b.dash_t <= 0.0 and b.phase_t > 0.0:
				var tgt := p.position
				w.fx.mark(tgt, 34.0, 0.5, Pal.c("red", 3))
				b.start_dash((tgt - b.position) / 0.5, 0.5)
				b.start_air(0.5)
				b.set_meta("land_at", w.run.time + 0.5)
				b.phase_t = minf(b.phase_t, 1.6)
			if b.has_meta("land_at") and w.run.time >= float(b.get_meta("land_at")):
				b.remove_meta("land_at")
				if b.position.distance_to(p.position) < 34.0 + p.r:
					w.combat.hit(p, b.dmg * 1.3, b, {"knock": 200.0, "stun": 0.4})
				w.fx.ring(b.position, 4.0, 34.0, 0.3, Pal.c("brown", 3))
				w.shake = 4.0
				Sfx.play("thud", 0.7)
			if b.phase_t <= 0.0:
				b.phase = ""


## Phase 2 at half HP: a banner, a tint, a longer and nastier pattern.
func _enrage(b: Actor) -> void:
	b.set_meta("phase2", true)
	b.boss_cycle = 0
	b.modulate = Color(1.2, 0.82, 0.82)
	w.banner.emit("%s IS ENRAGED" % String(Species.get_def(b.species)["name"]).to_upper(), "Phase 2: new moves")
	w.fx.ring(b.position, b.r, 90.0, 0.6, Pal.c("red", 3))
	w.shake = 6.0
	Sfx.play("boss", 1.2)


const PHASE2 := {
	"duckodile": ["windup_charge", "spit", "windup_charge", "summon"],
	"quackaconda": ["spit", "flood", "windup_charge", "spit", "windup_ring"],
	"mother_goose": ["windup_cone", "summon", "windup_charge", "windup_ring"],
	"shelldrake": ["roll", "windup_ring", "spit"],
	"duckaroo": ["hop", "hop", "hop", "windup_cone", "windup_ring"],
	"great_mallard": ["windup_ring", "windup_charge", "summon", "spit", "windup_cone"],
}


func _pick_phase(b: Actor) -> void:
	var c := b.boss_cycle
	if b.has_meta("phase2") and PHASE2.has(b.species):
		var seq: Array = PHASE2[b.species]
		b.phase = String(seq[c % seq.size()])
		b.phase_t = {"hop": 2.4, "roll": 3.2, "windup_ring": 0.8}.get(b.phase, 0.6)
		if b.phase == "roll":
			b.armor = float(Species.get_def(b.species).get("armor", 0.0)) * 3.0
			b.start_dash((w.player.position - b.position).normalized() * 200.0, 0.9)
		_telegraph(b)
		return
	match b.species:
		"duckodile":
			b.phase = ["windup_charge", "windup_charge", "summon"][c % 3]
			b.phase_t = 0.6
		"quackaconda":
			b.phase = ["spit", "flood", "spit", "windup_charge"][c % 4]
			b.phase_t = 0.7
		"mother_goose":
			b.phase = ["windup_cone", "windup_charge", "summon"][c % 3]
			b.phase_t = 0.55
		"shelldrake":
			if c % 2 == 1:
				b.phase = "roll"
				b.phase_t = 3.2
				b.armor = float(Species.get_def(b.species).get("armor", 0.0)) * 3.0
				b.start_dash((w.player.position - b.position).normalized() * 200.0, 0.9)
			else:
				b.phase = "windup_ring"
				b.phase_t = 0.8
				w.fx.mark(b.position, 110.0, 0.8, Pal.c("red", 3))
		"duckaroo":
			b.phase = ["hop", "hop", "windup_cone"][c % 3]
			b.phase_t = 2.4 if b.phase == "hop" else 0.55
		"great_mallard":
			b.phase = ["windup_ring", "windup_charge", "summon", "spit"][c % 4]
			b.phase_t = 0.7
			if b.phase == "windup_ring":
				w.fx.mark(b.position, 40.0, 0.7, Pal.c("gold", 3))
	_telegraph(b)


## Every attack shows where it lands before it does.
func _telegraph(b: Actor) -> void:
	if w.run.pressure >= 3 and b.phase.begins_with("windup"):
		b.phase_t *= 0.85
	var to := (w.player.position - b.position).normalized()
	var col := Color(Pal.c("red", 3), 0.55)
	match b.phase:
		"windup_charge":
			w.fx.cone(b.position + Vector2(0, -b.r * 0.5), to, 200.0, 0.12, b.phase_t, col)
		"windup_cone":
			w.fx.cone(b.position + Vector2(0, -b.r), to, 130.0, 1.2, b.phase_t, col)
		"spit":
			w.fx.cone(b.position + Vector2(0, -b.r), to, 120.0, 0.9, b.phase_t, col)
		"windup_ring":
			w.fx.mark(b.position, 150.0 if b.species == "great_mallard" else 110.0, b.phase_t, Pal.c("red", 3))
	if b.phase.begins_with("windup"):
		b.hit_flash(Pal.c("red", 3))
