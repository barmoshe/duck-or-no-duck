class_name World
extends Node2D
## The run's open world: map, ground, props, every Actor, food, mushrooms, burrows,
## points of interest, day and night, and the step loop. Brains (Brain), fighting
## (Combat), bosses (Bosses) and weather (Weather) live in their own files. World never
## opens menus: it emits signals and main.gd answers them.

signal level_up(count: int)
signal boss_fruit(boss_id: String)
signal poi_choice(kind: String)
signal player_died
signal run_won
signal banner(title: String, sub: String)
signal toast(text: String)

const GRID := 64.0
const NIGHT_TINT := Color(0.42, 0.48, 0.82)
const DUSK_TINT := Color(1.0, 0.78, 0.62)

var run: Run
var map: MapGen
var rng := RandomNumberGenerator.new()
var ground: ColorRect
var decor_layer: Node2D
var food_layer: Node2D
var ents: Node2D
var shots: Node2D
var fx: Fx
var cam: Camera2D
var tint: CanvasModulate
var night: NightLayer
var player: Actor
var actors: Array[Actor] = []
var grid := {}
var obst_grid := {}
var tall_props: Array = []  # trees and pines, faded when the player walks behind them
var foods: Array = []  # {n, p, v, z, vz, xp, type, rar, mut, life, bob, scav}
var sources: Array = []  # fruit trees, bushes, cacti: {n, p, o, stock, max, t, shed, shake, fruit}
var pools: Array = []  # fish pools: {n, p, stock, t, anim}
var carcass_tex := {}  # look key -> the body lying on its back
var tips := {}  # one-time food tips already shown
var meal: Dictionary = {}  # the piece you're chewing (a food, a carcass, or one from your cheeks)
var meal_src := ""  # ground | pouch
var meal_t := 0.0
var meal_need := 1.0
var pouch: Array = []  # Cheek Pouch: food stored in your cheeks, eaten even on the move
var crumb_t := 0.0
var rum_t := 0.0  # Ruminant: seconds of calm chewing
var rum_cd := 0.0
var shrooms: Array = []  # {n, p, fx, good}
var burrows: Array = []  # {n, p}
var pois: Array = []  # {n, mark, p, kind, used}
var combat: Combat
var bosses: Bosses
var weather: Weather
var running := false
var input_dir := Vector2.ZERO
var shake := 0.0
var hitstop := 0.0
var view := Rect2()
var spawn_t := 0.0
var next_boss := 0
var auto_step := true
var last_biome := ""
var player_look_key := ""
var pending_ups := 0
var dizzy := 0.0
var hide_t := 0.0
var was_night := false
var shroom_t := 0.0
var sway_mat: ShaderMaterial


func _ready() -> void:
	ground = ColorRect.new()
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.z_index = -20
	add_child(ground)
	decor_layer = Node2D.new()
	decor_layer.z_index = -10
	add_child(decor_layer)
	food_layer = Node2D.new()
	food_layer.z_index = -5
	add_child(food_layer)
	ents = Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	shots = Node2D.new()
	shots.z_index = 40
	add_child(shots)
	fx = Fx.new()
	add_child(fx)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	tint = CanvasModulate.new()
	add_child(tint)
	night = NightLayer.new()
	night.world = self
	add_child(night)
	combat = Combat.new(self)
	bosses = Bosses.new(self)
	weather = Weather.new()
	weather.world = self
	add_child(weather)
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;
uniform float strength = 1.0;
void vertex() {
	vec2 wp = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float top = 1.0 - UV.y;
	VERTEX.x += floor(sin(TIME * 1.6 + wp.x * 0.05 + wp.y * 0.03) * 1.6 * top * top * strength + 0.5);
}"
	sway_mat = ShaderMaterial.new()
	sway_mat.shader = sh


# ------------------------------------------------------------------ build
func build(seed_value: int, r: Run) -> void:
	run = r
	rng.seed = seed_value
	clear()
	map = MapGen.new()
	map.generate(seed_value)
	_build_ground()
	_build_props()
	_build_food_sources()
	_build_pools()
	_build_pois()
	_build_burrows()
	player = Actor.new()
	player.is_player = true
	player.species = "player"
	player.position = map.start
	ents.add_child(player)
	actors.append(player)
	sync_player(true)
	cam.position = player.position
	for i in 20:
		_spawn_one(90.0, 420.0)
	for i in 16:
		_spawn_shroom()
	next_boss = 0
	last_biome = ""
	was_night = false
	running = true


func clear() -> void:
	running = false
	for a in actors:
		if is_instance_valid(a):
			a.queue_free()
	actors.clear()
	for n in [decor_layer, food_layer, shots, ents]:
		for c in n.get_children():
			c.queue_free()
	foods.clear()
	sources.clear()
	pools.clear()
	tips.clear()
	rum_t = 0.0
	rum_cd = 0.0
	shrooms.clear()
	burrows.clear()
	pois.clear()
	obst_grid.clear()
	tall_props.clear()
	grid.clear()
	player = null
	player_look_key = ""
	pending_ups = 0
	dizzy = 0.0
	if combat:
		combat.reset()
	if bosses:
		bosses.reset()
	if weather:
		weather.reset()
	tint.color = Color.WHITE


func _build_ground() -> void:
	var sh := Shader.new()
	sh.code = load("res://scripts/world/ground.gdshader").code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("map_tex", ImageTexture.create_from_image(map.map_image()))
	mat.set_shader_parameter("cells", float(MapGen.N))
	mat.set_shader_parameter("cell", MapGen.CELL)
	var tones: Array[Color] = [
		Color("438f48"), Color("4f9d4b"), Color("5cab4f"), Pal.e("lemon"),  # grass
		Color("438f48"), Color("4f9d4b"), Color("5cab4f"), Pal.e("lemon"),  # lake islands (grass)
		Color("dfae72"), Color("e6bb80"), Color("ecc990"), Pal.e("cocoa"),  # sand
		Color("c8d2e0"), Color("d6dee9"), Color("e4eaf2"), Pal.e("slate"),  # snow
		Color("0f1f22"), Pal.e("deep"), Pal.e("pine"), Pal.e("grass"),  # forest wall
	]
	mat.set_shader_parameter("tones", tones)
	var wc: Array[Color] = [Color("1a5f9e"), Pal.e("sky"), Color("7fe6f5"), Pal.e("white"), Color("b8dcef"), Pal.e("white"), Pal.e("sand"), Pal.e("tan")]
	mat.set_shader_parameter("water_c", wc)
	ground.material = mat
	ground.position = Vector2.ZERO
	ground.size = Vector2(MapGen.SIZE, MapGen.SIZE)


func _sprite(tex: Texture2D, p: Vector2, parent: Node, sway: bool = false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var sz := tex.get_size()
	s.offset = Vector2(-floorf(sz.x * 0.5), -sz.y + 2)
	s.position = p.floor()
	if sway:
		s.material = sway_mat
	parent.add_child(s)
	return s


func _build_props() -> void:
	for o in map.obstacles:
		var kind := String(o["kind"])
		# a soft shadow under trees and rocks
		var sh := Sprite2D.new()
		sh.texture = Props.tex("shadow")
		sh.scale = Vector2(float(o["r"]) / 5.0, float(o["r"]) / 7.0)
		sh.position = (o["p"] as Vector2).floor() + Vector2(1, 0)
		sh.z_index = -9
		add_child(sh)
		var tex_name := kind
		if kind == "tree":
			var roll := rng.randf()
			tex_name = "tree" if roll < 0.5 else ("tree_autumn" if roll < 0.75 else "tree_blossom")
		elif kind == "bush" and rng.randf() < 0.4:
			tex_name = "bush_berry"
		o["n"] = _sprite(Props.tex(tex_name), o["p"], ents, kind in ["tree", "pine", "bush", "cactus"])
		if kind in ["tree", "pine"]:
			tall_props.append(o)
		var k := _gkey(o["p"])
		if not obst_grid.has(k):
			obst_grid[k] = []
		(obst_grid[k] as Array).append(o)
	for d in map.decor:
		var kind2 := String(d["kind"])
		if kind2 == "lily" and rng.randf() < 0.2:
			kind2 = "lily_flower"
		if kind2 == "pebbles" and map.biome_at(d["p"]) in [0, 1]:
			kind2 = "stones"
		var tall := kind2 in ["reeds", "cattail", "tall_grass"]
		_sprite(Props.tex(kind2), d["p"], ents if tall else decor_layer, tall or kind2 in ["grass", "flowers"])


## Fruit comes from trees, bushes and cacti (and snowy pines): each holds a small stock
## that regrows, sheds a piece now and then, and drops fruit when something bumps it.
func _build_food_sources() -> void:
	for o in map.obstacles:
		var kind := String(o["kind"])
		if not kind in ["tree", "bush", "cactus", "pine"]:
			continue
		var mx := {"tree": 3, "bush": 2, "cactus": 2, "pine": 2}[kind] as int
		var src := {"n": o.get("n"), "p": o["p"], "o": o, "stock": mx, "max": mx, "t": rng.randf_range(10.0, 22.0),
			"shed": rng.randf_range(4.0, 30.0), "shake": 0.0, "cd": 0.0,
			"fruit": Foods.FRUIT_OF_BIOME[clampi(map.biome_at(o["p"]), 0, 3)], "tall": kind in ["tree", "pine"]}
		o["src"] = src
		sources.append(src)
		# the world starts with windfall under most of them
		if rng.randf() < 0.75:
			_drop_fruit(src, false)


## A fish pool: dark ripples in the water where fish jump out when you swim close.
func _build_pools() -> void:
	var tries := 0
	while pools.size() < 34 and tries < 3000:
		tries += 1
		var p := Vector2(rng.randf_range(80, MapGen.SIZE - 80), rng.randf_range(80, MapGen.SIZE - 80))
		if map.water_at(p) == 0 or map.is_wall(p) or map.biome_at(p) == 3:
			continue
		var ok := true
		for q in pools:
			if (q["p"] as Vector2).distance_to(p) < 110.0:
				ok = false
				break
		if not ok:
			continue
		var n := Sprite2D.new()
		n.texture = Props.tex("fish_pool")
		n.position = p.floor()
		decor_layer.add_child(n)
		pools.append({"n": n, "p": p, "stock": 2, "t": 0.0, "anim": rng.randf() * 3.0})


func _build_pois() -> void:
	for d in map.pois:
		var s := _sprite(Props.tex("poi_" + String(d["kind"])), d["p"], ents)
		var m := Sprite2D.new()
		m.texture = Props.tex("poi_mark")
		m.position = Vector2(0, -s.texture.get_size().y - 8)
		s.add_child(m)
		pois.append({"n": s, "mark": m, "p": d["p"], "kind": d["kind"], "used": false})


func _build_burrows() -> void:
	for p in map.burrows:
		var s := Sprite2D.new()
		s.texture = Props.tex("burrow")
		s.position = (p as Vector2).floor()
		decor_layer.add_child(s)
		burrows.append({"n": s, "p": p})


func _spawn_shroom() -> void:
	for k in 10:
		var p := map.random_point(rng, player.position if rng.randf() < 0.5 else Vector2(MapGen.SIZE, MapGen.SIZE) * 0.5, 60.0, 1100.0, false)
		if p.x < 0 or not map.biome_at(p) in [0, 3]:
			continue
		var idx := rng.randi() % Pois.SHROOMS.size()
		var good: bool = Pois.SHROOMS[idx][1]
		var s := Sprite2D.new()
		s.texture = Props.tex(["shroom_red", "shroom_brown", "shroom_blue", "shroom_gold"][rng.randi() % 4])
		s.position = p.floor()
		food_layer.add_child(s)
		shrooms.append({"n": s, "p": p, "i": idx, "good": good})
		return


# ------------------------------------------------------------------ player
func sync_player(full: bool = false) -> void:
	var st := run.stats
	var ratio := player.hp / maxf(1.0, player.max_hp)
	player.max_hp = float(st["max_hp"])
	player.hp = player.max_hp if full else player.max_hp * ratio
	player.speed = run.move_speed()
	player.armor = float(st["armor"])
	player.r = run.radius()
	player.swim = float(st["swim"]) >= 1.0
	var key := Anatomy.key_of(run.look)
	if key != player_look_key:
		var was_slime := player_look_key.begins_with("slime|") or player_look_key.begins_with("mochi|")
		if player_look_key.begins_with("slime|") and key.begins_with("mochi|"):
			toast.emit("The goo is firming up...")
		player_look_key = key
		player.set_look(run.look)
		if was_slime and not run.is_slime():
			banner.emit("METAMORPHOSIS!", "The goo firms up: you are a %s creature now" % String(Evolutions.AFF_NAMES[run.dominant_affinity()]))
			fx.burst(player.position + Vector2(0, -player.r), Pal.c("slime", 3), 40, 90.0, 2.0, 0.9)
			fx.ring(player.position + Vector2(0, -player.r), 4.0, 60.0, 0.6, Pal.c("slime", 4))
			Sfx.play("stage")


# ------------------------------------------------------------------ loop
func _process(delta: float) -> void:
	if not auto_step:
		return
	var dt := minf(delta, 0.05)
	if hitstop > 0.0:
		hitstop -= delta
		dt *= 0.05
	if running and player:
		step(dt)
	_camera(delta)
	fx.step(delta)


func step(dt: float) -> void:
	run.time += dt
	run.tick_buffs(dt)
	_schedule()
	_daylight()
	dizzy = maxf(0.0, dizzy - dt)
	player.desired = input_dir if dizzy <= 0.0 else -input_dir
	_hide_in_burrow(dt)
	_rebuild_grid()
	for a in actors:
		if a.dead:
			continue
		if a.is_boss:
			bosses.brain(a, dt)
		elif not a.is_player:
			a.think_t -= dt
			if a.think_t <= 0.0:
				a.think_t = 0.2 + rng.randf() * 0.12
				Brain.think(self, a)
			Brain.follow(self, a)
		_terrain(a)
		a.tick(dt)
	_collide()
	combat.step(dt)
	bosses.step(dt)
	_pickups(dt)
	_regen(dt)
	_reap()
	spawn_t -= dt
	if spawn_t <= 0.0:
		spawn_t = 0.35
		_spawner()
	shroom_t -= dt
	if shroom_t <= 0.0:
		shroom_t = 8.0
		if shrooms.size() < 16:
			_spawn_shroom()
	_poi_check()
	weather.step(dt)
	_biome_toast()
	if pending_ups > 0 and running:
		var n := pending_ups
		pending_ups = 0
		level_up.emit(n)


func _schedule() -> void:
	if next_boss < Run.BOSS_TIMES.size() and run.time >= float(Run.BOSS_TIMES[next_boss]):
		bosses.hatch(String(run.boss_order[next_boss]))
		next_boss += 1
	if run.time >= Run.FINAL_TIME and not bosses.final_started:
		bosses.start_final()


func _daylight() -> void:
	var dark := run.darkness()
	var ph := run.day_phase()
	var c := Color.WHITE.lerp(NIGHT_TINT, dark * 0.85)
	if ph > 0.5 and ph < 0.66:
		c = c.lerp(DUSK_TINT, sin((ph - 0.5) / 0.16 * PI) * 0.45)
	elif ph > 0.9:
		c = c.lerp(Color(1.0, 0.85, 0.75), sin((ph - 0.9) / 0.1 * PI) * 0.35)
	tint.color = c
	var n := run.is_night()
	if n != was_night:
		was_night = n
		if n:
			banner.emit("NIGHTFALL", "Hunters grow bold. Stay close to the light.")
			Sfx.play("night")
		else:
			toast.emit("Dawn breaks")
	if n and rng.randf() < 0.3:
		var fp := player.position + Vector2(rng.randf_range(-200, 200), rng.randf_range(-120, 120))
		fx.bits.append({"p": fp, "v": Vector2(rng.randf_range(-6, 6), rng.randf_range(-8, -2)), "life": 2.0, "max": 2.0,
			"c": Pal.c("gold", 4), "s": 1.0, "g": 0.0})


func _hide_in_burrow(dt: float) -> void:
	var near_b := false
	for b in burrows:
		if (b["p"] as Vector2).distance_to(player.position) < 9.0:
			near_b = true
			break
	if near_b and input_dir.length() < 0.1 and player.dash_t <= 0.0:
		hide_t += dt
		if hide_t > 0.25 and not player.under:
			player.under = true
			fx.burst(player.position, Pal.c("brown", 3), 6, 30.0, 1.0, 0.3)
			for a in actors:
				if a.target == player:
					a.target = null
					a.angry_t = 0.0
					a.state = "wander"
	else:
		hide_t = 0.0
		if player.under and combat.dive_t <= 0.0 and player.dash_t <= 0.0 and not player.has_meta("burrowing"):
			player.under = false


func hidden() -> bool:
	return player.under and hide_t > 0.25


func _terrain(a: Actor) -> void:
	var w := map.water_at(a.position)
	var b := map.biome_at(a.position)
	if bosses.arena_on and float(get_meta("flood_t", 0.0)) > run.time and a.position.distance_to(bosses.arena_c) < bosses.arena_r:
		w = 1
		b = 0
	a.ice = w != 0 and b == 3
	if a.fly or a.is_airborne():
		a.terrain = 1.0
	elif w != 0 and b != 3:
		if a.swim:
			a.terrain = 1.25 if a.is_player else 1.0
		elif a.wade:
			a.terrain = 0.9
		elif a.is_player and float(run.stats["swim"]) > 0.0:
			a.terrain = 0.5 + 0.5 * minf(1.0, float(run.stats["swim"]))
		else:
			a.terrain = 0.5
	elif a.water_only:
		a.terrain = 0.4
	elif b == 3:
		a.terrain = 0.8 if not a.swim or a.is_player else 0.85
	elif b == 2:
		a.terrain = 0.9
	else:
		a.terrain = 1.0
	if weather.kind == "blizzard" and b == 3 and not a.fly:
		a.terrain *= 0.7
	# Wings: most of the terrain penalty goes away
	if a.is_player and a.terrain < 1.0:
		a.terrain = 1.0 - (1.0 - a.terrain) * (1.0 - float(run.stats["terrain_res"]) / 100.0)
	if weather.kind == "current" and w != 0:
		a.vel += weather.push * 0.016


func _rebuild_grid() -> void:
	grid.clear()
	for a in actors:
		if a.dead:
			continue
		var k := _gkey(a.position)
		if not grid.has(k):
			grid[k] = []
		(grid[k] as Array).append(a)


func _gkey(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / GRID), floori(p.y / GRID))


func near(p: Vector2, radius: float) -> Array:
	var out: Array = []
	var k0 := _gkey(p - Vector2(radius, radius))
	var k1 := _gkey(p + Vector2(radius, radius))
	var r2 := radius * radius
	for x in range(k0.x, k1.x + 1):
		for y in range(k0.y, k1.y + 1):
			for a in grid.get(Vector2i(x, y), []):
				if is_instance_valid(a) and not a.dead and (a as Actor).position.distance_squared_to(p) <= r2:
					out.append(a)
	return out


func obstacles_near(p: Vector2, radius: float) -> Array:
	var out: Array = []
	var k0 := _gkey(p - Vector2(radius, radius))
	var k1 := _gkey(p + Vector2(radius, radius))
	for x in range(k0.x, k1.x + 1):
		for y in range(k0.y, k1.y + 1):
			for o in obst_grid.get(Vector2i(x, y), []):
				out.append(o)
	return out


static func valid(a) -> bool:
	return a != null and is_instance_valid(a) and not a.dead


## True when a and b are on opposite sides (player + allies vs animals).
static func hostile(a: Actor, b: Actor) -> bool:
	return (a.is_player or a.is_ally) != (b.is_player or b.is_ally)


func _collide() -> void:
	for a in actors:
		if a.dead:
			continue
		for b in near(a.position, a.r + 30.0):
			var bb: Actor = b
			if bb == a or bb.get_instance_id() < a.get_instance_id() or bb.under or a.under:
				continue
			var d := a.position - bb.position
			var dist := d.length()
			var md := (a.r + bb.r) * 0.7
			if dist < md and dist > 0.01:
				var push := d / dist * (md - dist)
				var ma := a.r * a.r * (4.0 if a.is_boss else 1.0)
				var mb := bb.r * bb.r * (4.0 if bb.is_boss else 1.0)
				a.position += push * mb / (ma + mb)
				bb.position -= push * ma / (ma + mb)
		if not a.is_airborne() and not a.under and not a.fly:
			for o in obstacles_near(a.position, 24.0):
				var op: Vector2 = o["p"]
				var dd := a.position - op
				var need := float(o["r"]) + a.r * 0.6
				if dd.length() < need:
					if dd.length() < 0.01:
						dd = Vector2.RIGHT
					a.position = op + dd.normalized() * need
					if a.dash_t > 0.0:
						a.set_meta("bonk", true)
					# bumping a fruit tree, bush or cactus shakes fruit loose
					if o.has("src") and (a.is_player or a.r >= 9.0):
						shake_source(o["src"], a.dash_t > 0.0)
		if map.is_wall(a.position):
			var c := Vector2(MapGen.SIZE, MapGen.SIZE) * 0.5
			a.position += (c - a.position).normalized() * 3.0
			a.vel *= 0.3
			if a.dash_t > 0.0:
				a.set_meta("bonk", true)
		# the boss arena holds everyone who's fighting in it
		if bosses.arena_on and (a.is_player or a.is_boss):
			var off := a.position - bosses.arena_c
			var lim := bosses.arena_r - a.r * 0.5
			if off.length() > lim:
				a.position = bosses.arena_c + off.normalized() * lim
				if a.dash_t > 0.0:
					a.set_meta("bonk", true)
		if a.water_only and map.water_at(a.position) == 0 and not a.is_player:
			a.position -= a.vel * 0.05
			a.wander = -a.wander


# ------------------------------------------------------------------ food
## Animals drop meat (fish-like animals drop fish); each piece rolls a rarity.
func drop_food(p: Vector2, xp: float, big: bool, fish: bool, scav: bool, source: String = "animal") -> void:
	var pieces := clampi(int(xp / 4.0) + 1, 1, 6)
	if big:
		pieces = mini(pieces + 1, 7)
	for i in pieces:
		_roll_food(p, "fish" if fish else "meat", xp / pieces, source, scav)


func _luck() -> float:
	return float(run.stats["luck"]) + run.duck_parts() * 1.5


## Roll a rarity (and maybe a heart) for one piece of food and put it in the world.
func _roll_food(p: Vector2, type: String, xp: float, source: String, scav: bool = false, variant: String = "", z: float = 0.0) -> Dictionary:
	var rar := Foods.roll(rng, source, _luck())
	if rng.randf() < Foods.heart_chance(rar, player.hp / maxf(1.0, player.max_hp) if valid(player) else 1.0):
		return spawn_food(p, "heart", 1.0, 0, false, "", z)
	return spawn_food(p, type, xp, rar, scav, variant, z)


func spawn_food(p: Vector2, type: String, xp: float, rar: int, scav: bool = false, variant: String = "", z: float = 0.0) -> Dictionary:
	var s := Sprite2D.new()
	s.texture = Props.tex(Foods.sprite_name(type, variant if variant != "" else "apple", rar))
	s.position = p.floor()
	food_layer.add_child(s)
	var life: float = Foods.LIFE[rar] * (1.0 + float(run.stats["omni"]) * 0.25)
	var f := {"n": s, "p": p, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30.0, 80.0), "z": z, "vz": 0.0,
		"xp": xp, "type": type, "rar": rar, "mut": 0, "life": life, "bob": rng.randf() * 6.0, "scav": scav}
	foods.append(f)
	return f


func drop_mutagen(p: Vector2, n: int) -> void:
	for i in n:
		var s := Sprite2D.new()
		s.texture = Props.tex("mutagen")
		s.position = p.floor()
		food_layer.add_child(s)
		foods.append({"n": s, "p": p, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30.0, 80.0), "z": 0.0, "vz": 0.0,
			"xp": 0.0, "type": "mutagen", "rar": 0, "mut": 1, "life": 40.0, "bob": rng.randf() * 6.0, "scav": false})


## Vegans can't eat meat or fish: it stays on the ground for the animals.
func can_eat(f: Dictionary) -> bool:
	if float(run.stats["vegan"]) > 0.0 and String(f["type"]) in ["meat", "fish", "carcass"]:
		return false
	return true


## A big kill leaves its body: stay close to chew it, bite by bite, before a scavenger does.
func _make_carcass(a: Actor, xp: float, fish: bool, scav: bool, source: String) -> void:
	var key := Anatomy.key_of(a.look)
	if not carcass_tex.has(key):
		var img: Image = (a.frames["idle"][0] as Texture2D).get_image()
		img = img.get_region(img.get_used_rect())
		img.flip_y()
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					var g := c.get_luminance()
					img.set_pixel(x, y, Color(c.lerp(Color(g, g * 0.92, g * 0.9), 0.35).darkened(0.12), c.a))
		carcass_tex[key] = ImageTexture.create_from_image(img)
	var tex: Texture2D = carcass_tex[key]
	var s := Sprite2D.new()
	s.texture = tex
	s.position = (a.position - Vector2(0, floorf(tex.get_size().y * 0.5) - 2)).floor()
	food_layer.add_child(s)
	var bites := clampi(int(xp / 4.0) + 2, 2, 8)
	foods.append({"n": s, "p": a.position, "v": Vector2.ZERO, "z": 0.0, "vz": 0.0, "xp": xp * 1.2 / bites,
		"type": "carcass", "meat": "fish" if fish else "meat", "rar": 0, "mut": 0, "life": 40.0, "bob": 0.0,
		"scav": scav, "bites": bites, "max_bites": bites, "chew": 0.0, "src": source, "r": a.r})
	if not scav:
		_tip("carcass", "Big kills leave a carcass: stand next to it to eat it bite by bite")


func _tip(id: String, text: String) -> void:
	if tips.has(id):
		return
	tips[id] = true
	toast.emit(text)


func on_player_hit() -> void:
	rum_cd = 15.0
	rum_t = 0.0


## Ruminant: every 10 calm seconds, Progress equal to 4x your Prey affinity.
func _ruminate(dt: float) -> void:
	if float(run.stats["ruminant"]) <= 0.0:
		return
	if rum_cd > 0.0:
		rum_cd -= dt
		return
	rum_t += dt
	if rum_t >= 10.0:
		rum_t = 0.0
		var prey := int(run.affinity_points().get("prey", 0))
		var gain := 4.0 * maxi(1, prey) * float(run.stats["ruminant"])
		_gain_xp(gain)
		fx.text(player.position + Vector2(0, -player.r * 2.2), "RUMINATE +%d" % roundi(gain), Pal.e("leaf"))


## Fruit falls from a source: out of the crown with a little bounce, onto the ground.
func _drop_fruit(src: Dictionary, falling: bool = true) -> void:
	var tall: bool = src["tall"]
	var ang := rng.randf_range(0.15, PI - 0.15)  # in front of (below) the trunk
	var p: Vector2 = (src["p"] as Vector2) + Vector2(cos(ang) * rng.randf_range(8.0, 22.0), sin(ang) * rng.randf_range(4.0, 14.0))
	if map.water_at(p) != 0 or map.is_wall(p):
		p = (src["p"] as Vector2) + Vector2(rng.randf_range(-6, 6), 8)
	var xp := Foods.FRUIT_XP * (1.0 + run.minute() * 0.04)
	var f := _roll_food(p, "fruit", xp, "plant", false, String(src["fruit"]), (22.0 if tall else 10.0) if falling else 0.0)
	f["v"] = Vector2.ZERO
	f["life"] = float(f["life"]) + 15.0


## Something bumped a fruit source: it shakes and lets go of some of its fruit.
func shake_source(src: Dictionary, hard: bool = false) -> void:
	if float(src["cd"]) > 0.0:
		return
	src["cd"] = 0.9
	src["shake"] = 0.35
	var n := mini(int(src["stock"]), (2 if hard else 1) + (1 if float(run.stats["pollen"]) > 0.0 else 0) + (1 if run.has_gene("forager") else 0))
	for i in n:
		_drop_fruit(src)
	src["stock"] = int(src["stock"]) - n
	var leaf := Pal.e("leaf") if String(src["fruit"]) != "pear" else Pal.e("grass")
	fx.burst((src["p"] as Vector2) + Vector2(0, -24 if src["tall"] else -8), leaf, 5 + n * 2, 40.0, 1.0, 0.6, 60.0)
	if n > 0:
		Sfx.play("pop", randf_range(1.2, 1.4), -8.0)


func _food_sources(dt: float) -> void:
	var grow := (3.0 if weather.kind == "rain" else 1.0) * (1.0 + float(run.stats["pollen"]) * 0.6)
	var pp := player.position
	for src in sources:
		src["cd"] = maxf(0.0, float(src["cd"]) - dt)
		if not tips.has("fruit") and int(src["stock"]) > 0 and (src["p"] as Vector2).distance_squared_to(pp) < 40.0 * 40.0:
			_tip("fruit", "Bump trees and bushes to shake fruit loose")
		if int(src["stock"]) < int(src["max"]):
			src["t"] = float(src["t"]) - dt * grow
			if float(src["t"]) <= 0.0:
				src["stock"] = int(src["stock"]) + 1
				src["t"] = rng.randf_range(18.0, 26.0)
		# windfall: only near the player, so the ground doesn't fill up far away
		if int(src["stock"]) > 0 and (src["p"] as Vector2).distance_squared_to(pp) < 420.0 * 420.0:
			src["shed"] = float(src["shed"]) - dt * grow
			if float(src["shed"]) <= 0.0:
				src["shed"] = rng.randf_range(20.0, 36.0)
				src["stock"] = int(src["stock"]) - 1
				_drop_fruit(src)
		if float(src["shake"]) > 0.0:
			src["shake"] = maxf(0.0, float(src["shake"]) - dt)
			var n = src["n"]
			if n is Sprite2D:
				var k := float(src["shake"])
				(n as Sprite2D).position = (src["p"] as Vector2).floor() + Vector2(roundf(sin(k * 60.0) * k * 5.0), 0)
	for pl in pools:
		pl["anim"] = float(pl["anim"]) + dt
		var n2: Sprite2D = pl["n"]
		var has := int(pl["stock"]) > 0
		n2.texture = Props.tex("fish_pool" if int(float(pl["anim"]) * 2.0) % 2 == 0 else "fish_pool_2")
		n2.modulate.a = 1.0 if has else 0.35
		if not has:
			pl["t"] = float(pl["t"]) - dt
			if float(pl["t"]) <= 0.0:
				pl["stock"] = 2
			continue
		if not tips.has("fish") and (pl["p"] as Vector2).distance_squared_to(pp) < 90.0 * 90.0:
			_tip("fish", "Swim over dark ripples: fish jump out")
		if (pl["p"] as Vector2).distance_squared_to(pp) < 18.0 * 18.0 and not player.air:
			_fish_jump(pl)


## A fish jumps out of the pool and lands on the bank side of you.
func _fish_jump(pl: Dictionary) -> void:
	pl["stock"] = int(pl["stock"]) - 1
	if int(pl["stock"]) <= 0:
		pl["t"] = 15.0 if run.has_gene("angler") else 30.0
	var p: Vector2 = pl["p"]
	var xp := Foods.FISH_POOL_XP * (1.0 + run.minute() * 0.05)
	for i in 3 if run.has_gene("angler") else 2:
		var f := _roll_food(p, "fish", xp, "pool", false, "", 4.0)
		f["v"] = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40.0, 70.0)
		f["vz"] = 70.0
	fx.burst(p, Pal.e("cyan"), 12, 60.0, 1.0, 0.5, 120.0)
	fx.ring(p, 3.0, 16.0, 0.4, Pal.e("white"))
	Sfx.play("splash", 1.2, -4.0)


func _pickups(dt: float) -> void:
	fx.chew_on = false
	player.eating = false
	_ruminate(dt)
	_food_sources(dt)
	var pp := player.position
	for i in range(foods.size() - 1, -1, -1):
		var f: Dictionary = foods[i]
		var is_meal := is_same(f, meal)
		if not is_meal:
			f["life"] = float(f["life"]) - dt  # the piece in your mouth doesn't spoil
		var n: Sprite2D = f["n"]
		if float(f["life"]) <= 0.0:
			n.queue_free()
			foods.remove_at(i)
			continue
		if String(f["type"]) == "carcass":
			if float(f["life"]) <= 0.0:
				n.queue_free()
				foods.remove_at(i)
			elif float(f["life"]) < 4.0:
				n.visible = int(float(f["life"]) * 8.0) % 2 == 0
			continue
		# falling out of a tree or jumping out of a pool
		var z := float(f["z"])
		if z > 0.0 or float(f["vz"]) > 0.0:
			f["vz"] = float(f["vz"]) - 260.0 * dt
			z = maxf(0.0, z + float(f["vz"]) * dt)
			if z <= 0.0 and float(f["vz"]) < -40.0:
				f["vz"] = -float(f["vz"]) * 0.3  # a little bounce
				z = 0.01
			elif z <= 0.0:
				f["vz"] = 0.0
			f["z"] = z
		var to: Vector2 = pp - (f["p"] as Vector2)
		var d := to.length()
		# hearts and mutagen are picked up on touch (and drift to you from close by);
		# food has to be eaten: only the piece you're chewing slides into your mouth
		var grab := int(f["mut"]) > 0 or String(f["type"]) == "heart"
		if grab and d < 22.0 and not player.under and z <= 0.0:
			f["v"] = (f["v"] as Vector2).lerp(to.normalized() * 160.0, minf(1.0, dt * 8.0))
		elif is_meal and d > player.r * 0.6 and z <= 0.0:
			f["v"] = to.normalized() * 70.0
		else:
			f["v"] = (f["v"] as Vector2) * maxf(0.0, 1.0 - dt * (1.5 if z > 0.0 else 5.0))
		f["p"] = (f["p"] as Vector2) + (f["v"] as Vector2) * dt
		f["bob"] = float(f["bob"]) + dt
		var bob := 0.0 if z > 0.0 else roundf(absf(sin(float(f["bob"]) * 3.0)) * (2.0 if int(f["rar"]) > 0 else 1.0))
		n.position = ((f["p"] as Vector2) + Vector2(0, -bob - roundf(z))).floor()
		if float(f["life"]) < 4.0:
			n.visible = int(float(f["life"]) * 8.0) % 2 == 0
		if int(f["rar"]) == 3 and rng.randf() < dt * 3.0:
			fx.burst(n.position + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 3)), Pal.e("lemon"), 1, 8.0, 1.0, 0.4)
		if grab and d < player.r + 5.0 and not player.under and z <= 0.0:
			_eat(f)
			n.queue_free()
			foods.remove_at(i)
	_feed(dt)
	for i in range(shrooms.size() - 1, -1, -1):
		var sm: Dictionary = shrooms[i]
		var sn: Sprite2D = sm["n"]
		var ident := float(run.stats["identify"]) > 0.0
		if ident:
			sn.modulate = Color(0.7, 1.3, 0.7) if sm["good"] else Color(1.3, 0.6, 0.6)
		if (sm["p"] as Vector2).distance_to(pp) < player.r + 5.0 and not player.under:
			if ident and not sm["good"]:
				continue  # More Eyes: you know better
			var e: Array = Pois.SHROOMS[int(sm["i"])]
			fx.text(pp + Vector2(0, -player.r * 2.5), String(e[0]).to_upper(), Pal.c("green", 4) if e[1] else Pal.c("red", 3))
			apply_fx(e[2])
			_gain_xp(3.0 * (1.0 + run.minute() * 0.05) * (1.0 + float(run.stats["shroom_xp"]) / 100.0))
			Sfx.play("slurp", 0.8)
			sn.queue_free()
			shrooms.remove_at(i)


# ------------------------------------------------------------------ eating
## How far from your body you can eat (Feeding Distance).
func reach() -> float:
	return player.r + float(run.stats["magnet"])


func _edible(f: Dictionary) -> bool:
	return float(f["z"]) <= 0.0 and float(f["life"]) > 0.0 and int(f["mut"]) == 0 and String(f["type"]) != "heart" and can_eat(f)


## Eating, as Crab does it: stand still next to food and chew it, one piece at a time;
## it takes time (Feeding Speed), from within reach (Feeding Distance). Cheek Pouch
## stores food in reach while you're busy or moving, and eats it even on the move.
func _feed(dt: float) -> void:
	if not valid(player) or player.under:
		return
	var pp := player.position
	var still := player.vel.length() < 30.0
	var r := reach()
	# the piece on the ground got stolen, spoiled, or you walked off
	if meal_src == "ground":
		var far := (meal["p"] as Vector2).distance_to(pp) > r + float(meal.get("r", 0.0)) + 6.0
		if float(meal["life"]) <= 0.0 or far:
			_clear_meal()
	var cap := int(run.stats["pouch"])
	if cap > 0 and pouch.size() < cap and (not meal.is_empty() or not still):
		for i in range(foods.size() - 1, -1, -1):
			if pouch.size() >= cap:
				break
			var f: Dictionary = foods[i]
			if is_same(f, meal) or String(f["type"]) == "carcass" or not _edible(f) or (f["p"] as Vector2).distance_to(pp) >= r:
				continue
			var n: Sprite2D = f["n"]
			var kept := f.duplicate()
			kept["icon"] = n.texture
			pouch.append(kept)
			f["life"] = 0.0  # gone from the ground: animals stop going for it
			n.queue_free()
			foods.remove_at(i)
			fx.burst(pp + Vector2(0, -12), Pal.e("peach"), 3, 30.0, 1.0, 0.3)
			Sfx.play("pop", 1.5, -10.0)
			_tip("pouch", "Food in your cheeks is eaten on the move")
	# the next meal: your cheeks first, then the nearest food in reach if you stand still
	if meal.is_empty():
		if not pouch.is_empty():
			_start_meal(pouch.pop_front(), "pouch")
		elif still:
			var best: Dictionary = {}
			var bd := INF
			for f in foods:
				if not _edible(f):
					continue
				var d := (f["p"] as Vector2).distance_to(pp) - float(f.get("r", 0.0))
				if d < r and d < bd:
					bd = d
					best = f
			if not best.is_empty():
				_start_meal(best, "ground")
	if meal.is_empty():
		return
	var chewing := meal_src == "pouch" or still
	if chewing:
		meal_t += dt
		player.eating = true
		crumb_t -= dt
		if crumb_t <= 0.0:
			crumb_t = 0.22
			var col := Pal.e(String(Foods.TYPE_COL.get(String(meal.get("meat", meal["type"])), "white")))
			fx.burst(pp + Vector2(player.face * 6.0, -10.0), col, 2, 30.0, 1.0, 0.3, 120.0)
	fx.chew_on = true
	fx.chew_p = pp + Vector2(0, -34)
	fx.chew_frac = meal_t / meal_need
	fx.chew_icon = meal.get("icon", null)
	if meal_t >= meal_need:
		_finish_meal()


func _start_meal(f: Dictionary, src: String) -> void:
	meal = f
	meal_src = src
	meal_t = 0.0
	var carcass := String(f["type"]) == "carcass"
	meal_need = Foods.eat_time("carcass" if carcass else String(f["type"]), 0 if carcass else int(f["rar"]), float(run.stats["feed"]))
	if not f.has("icon"):
		f["icon"] = Props.tex(Foods.sprite_name(String(f["meat"]), "", 0)) if carcass else (f["n"] as Sprite2D).texture
	_tip("eat", "Stand still next to food to eat it")


func _finish_meal() -> void:
	var f := meal
	var src := meal_src
	_clear_meal()
	if String(f["type"]) == "carcass":
		# one bite: its rarity is rolled now, and it goes straight to your Progress
		f["bites"] = int(f["bites"]) - 1
		var rar := Foods.roll(rng, String(f["src"]), _luck())
		_eat({"type": String(f["meat"]), "rar": rar, "xp": float(f["xp"]), "scav": bool(f["scav"]), "mut": 0})
		fx.burst((f["p"] as Vector2) + Vector2(0, -4), Pal.e("red"), 4, 40.0, 1.0, 0.35, 100.0)
		if int(f["bites"]) <= 0:
			f["life"] = 0.0
		return
	_eat(f)
	if src == "ground":
		var i := foods.find(f)
		if i >= 0:
			(f["n"] as Sprite2D).queue_free()
			foods.remove_at(i)


func _clear_meal() -> void:
	meal = {}
	meal_src = ""
	meal_t = 0.0


## An animal ate or stole this piece of food.
func take_food(f: Dictionary) -> void:
	f["life"] = 0.0


## Progress a piece of food is worth to you: rarity x diet bonuses.
func food_value(f: Dictionary) -> float:
	var type := String(f["type"])
	var bonus := float(run.stats["food"]) + float(run.stats["omni"]) * 12.0
	match type:
		"fish":
			bonus += float(run.stats["fish_xp"])
		"meat":
			bonus += float(run.stats["meat_xp"])
		"fruit":
			bonus += float(run.stats["fruit_xp"]) + float(run.stats["vegan"]) * 150.0
	if f.get("scav", false):
		bonus += float(run.stats["scav_xp"])
	return float(f["xp"]) * float(Foods.XP_MULT[int(f["rar"])]) * Foods.VALUE * (1.0 + bonus / 100.0)


func _eat(f: Dictionary) -> void:
	var head := player.position + Vector2(0, -player.r * 2.0)
	if int(f["mut"]) > 0:
		run.mutagen += int(f["mut"])
		fx.text(head, "+1 MUTAGEN", Pal.c("green", 4))
		Sfx.play("mutagen")
		return
	var type := String(f["type"])
	var rar := int(f["rar"])
	if type == "heart":
		var amt := player.max_hp * Foods.HEART_HEAL
		player.hp = minf(player.max_hp, player.hp + amt)
		fx.text(head, "+%d HP" % ceili(amt), Pal.e("salmon"))
		fx.burst(player.position + Vector2(0, -player.r), Pal.e("salmon"), 6, 30.0)
		Sfx.play("heal", 1.2, -4.0)
		_gain_xp(float(f["xp"]))
		return
	var gain := food_value(f)
	_gain_xp(gain)
	run.food_eaten[type] = int(run.food_eaten.get(type, 0)) + 1
	# eating heals a little (a rare piece more); fruit heals more with Herbivore and Vegan
	var heal := player.max_hp * Foods.EAT_HEAL * (1.0 + rar)
	if type == "fruit":
		heal += float(run.stats["fruit_heal"]) + float(run.stats["vegan"]) * 4.0
	player.hp = minf(player.max_hp, player.hp + heal)
	var col := Pal.e(String(Foods.TYPE_COL.get(type, "white")))
	if rar >= 2:
		fx.text(head + Vector2(0, -9), String(Foods.RARITY[rar]).to_upper() + "!", Pal.e("rose") if rar == 2 else Pal.e("amber"), rar == 3)
		fx.burst(player.position + Vector2(0, -player.r), Pal.e("amber") if rar == 3 else Pal.e("rose"), 6 + rar * 3, 50.0, 1.0, 0.5)
	fx.text(head + Vector2(randf_range(-4, 4), 0), "+%d" % maxi(1, roundi(gain)), col)
	Sfx.play("chomp" if type == "meat" else "slurp", randf_range(0.95, 1.1) + rar * 0.08, -5.0)


func _gain_xp(v: float) -> void:
	var ups := run.add_xp(v)
	if ups > 0:
		pending_ups += ups
		run.recompute()
		sync_player()
		fx.ring(player.position + Vector2(0, -player.r), 4.0, 40.0, 0.5, Pal.c("gold", 4))
		Sfx.play("levelup")


func _regen(dt: float) -> void:
	var reg := float(run.stats["regen"])
	if player.since_hurt > 3.0 and reg > 0.0:
		player.hp = minf(player.max_hp, player.hp + reg * dt)
	if weather.kind == "heatwave" and map.biome_at(player.position) == 2 and map.water_at(player.position) == 0 and not player.under:
		player.hp -= 1.0 * dt
	var ally_reg := float(run.stats["ally_regen"])
	for a in actors:
		if a.is_ally and ally_reg > 0.0 and not a.dead:
			a.hp = minf(a.max_hp, a.hp + ally_reg * dt)


## Applies an effect dictionary (points of interest, mushrooms).
func apply_fx(e: Dictionary) -> void:
	var p := player
	if e.has("hp_cost"):
		p.hp = maxf(1.0, p.hp - p.max_hp * float(e["hp_cost"]))
		p.hit_flash(Pal.c("red", 3))
	if e.has("heal"):
		p.hp = minf(p.max_hp, p.hp + p.max_hp * float(e["heal"]))
		fx.ring(p.position + Vector2(0, -p.r), 4.0, 30.0, 0.5, Pal.c("pink", 3))
	if e.has("bonus"):
		for k in e["bonus"]:
			run.bonus(k, float(e["bonus"][k]))
		sync_player()
	if e.has("buff"):
		for k in e["buff"]:
			run.buff(k, float(e["buff"][k]), float(e.get("secs", 20.0)))
		sync_player()
	if e.has("xp"):
		_gain_xp(float(e["xp"]) * run.xp_need() * 0.35)
	if e.has("mutagen"):
		run.mutagen += int(e["mutagen"])
	if e.has("dizzy"):
		dizzy = float(e["dizzy"])
	if e.has("affinity"):
		run.bonus("aff_" + String(e["affinity"]), 3.0)
	if e.has("ally"):
		var id := String(e["ally"])
		if id == "random":
			var b := map.biome_name_at(p.position)
			var table: Array = Species.SPAWNS.get(b, Species.SPAWNS["grass"])
			id = String(table[rng.randi() % table.size()][0])
			if Species.get_def(id).get("water_only", false):
				id = "stoat"
		var a := spawn_animal(id, p.position + Vector2(18, 0), id != "duckling")
		make_ally(a)
	if e.has("fruit"):
		for i in int(e["fruit"]):
			var fp := p.position + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10, 40)
			_roll_food(fp, "fruit", Foods.FRUIT_XP * (1.0 + run.minute() * 0.04), "plant", false, Foods.FRUIT_OF_BIOME[clampi(map.biome_at(fp), 0, 3)], 14.0)
	if e.has("mushrooms"):
		for i in int(e["mushrooms"]):
			var sp := p.position + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(24, 90)
			if map.water_at(sp) == 0 and not map.is_wall(sp):
				var idx := rng.randi() % Pois.SHROOMS.size()
				var s := Sprite2D.new()
				s.texture = Props.tex(["shroom_red", "shroom_brown", "shroom_blue", "shroom_gold"][rng.randi() % 4])
				s.position = sp.floor()
				food_layer.add_child(s)
				shrooms.append({"n": s, "p": sp, "i": idx, "good": Pois.SHROOMS[idx][1]})
	if e.has("shroom"):
		for i in int(e["shroom"]):
			var sh: Array = Pois.SHROOMS[rng.randi() % Pois.SHROOMS.size()]
			fx.text(p.position + Vector2(0, -p.r * 2.5 - i * 10), String(sh[0]).to_upper(), Pal.c("green", 4) if sh[1] else Pal.c("red", 3))
			apply_fx(sh[2])
	if e.has("time"):
		run.time += Run.DAY_LEN * 0.5
		next_boss = next_boss  # the schedule catches up in _schedule
	if e.has("parent"):
		var parent := spawn_animal("fox" if map.biome_at(p.position) == 0 else "scorpion", p.position + Vector2(90, -30), true)
		parent.target = p
		parent.state = "chase"
		parent.angry_t = 30.0
		banner.emit("THE PARENT IS BACK", "and it saw you")
	if e.has("gamble"):
		if rng.randf() < 0.5:
			_gain_xp(run.xp_need() * 1.2)
			fx.text(p.position + Vector2(0, -30), "YOU WIN!", Pal.c("gold", 4), true)
		else:
			p.hp = maxf(1.0, p.hp - p.max_hp * 0.4)
			fx.text(p.position + Vector2(0, -30), "YOU LOSE", Pal.c("red", 3), true)
	if e.has("random_evo"):
		var hand := Offers.roll(run, rng, "poi", 1)
		if not hand.is_empty():
			run.take(hand[0])
			Game.codex_evos[hand[0]] = true
			sync_player()
			banner.emit(String(Evolutions.get_def(hand[0])["name"]).to_upper(), "The Chaos Tree changed you")


# ------------------------------------------------------------------ death
func _reap() -> void:
	for i in range(actors.size() - 1, -1, -1):
		var a := actors[i]
		if a.dead or a.hp > 0.0:
			continue
		if a.is_player:
			if float(run.stats["revive"]) > 0.0 and not run.revive_used:
				run.revive_used = true
				a.hp = a.max_hp * 0.4
				a.invuln = 2.0
				banner.emit("NOT TODAY", "Playing Dead saved you")
				continue
			a.dead = true
			running = false
			if is_instance_valid(a.hurt_by):
				set_meta("killed_by", a.hurt_by.species + (" (alpha)" if a.hurt_by.alpha else ""))
			fx.burst(a.position, Pal.c("blue", 3), 30, 90.0, 2.0, 1.0)
			Sfx.play("die")
			a.visible = false
			player_died.emit()
			return
		a.dead = true
		var killer = a.hurt_by
		var by_us: bool = valid(killer) and (killer.is_player or killer.is_ally)
		fx.burst(a.position + Vector2(0, -a.r), Pal.c(String(a.look.get("ramp", "grey")), 3), 10 + int(a.r), 70.0, 1.0, 0.5)
		if not a.is_ally and not a.is_boss:
			var d := Species.get_def(a.species)
			var fxp := a.xp_value * (1.0 + run.minute() * 0.04)
			var fsrc := "alpha" if a.alpha else "animal"
			# big kills leave a carcass to chew; small ones pop straight into food
			if a.r >= 8.5 or a.alpha:
				_make_carcass(a, fxp, bool(d.get("fish", false)), not by_us, fsrc)
			else:
				drop_food(a.position, fxp, false, bool(d.get("fish", false)), not by_us, fsrc)
			var mchance := 0.03 * (1.0 + float(run.stats["luck"]) * 0.2)
			if a.alpha:
				drop_mutagen(a.position, 1 + (1 if rng.randf() < 0.4 else 0))
			elif rng.randf() < mchance:
				drop_mutagen(a.position, 1)
		if by_us and not a.is_ally:
			run.kills += 1
			run.eaten[a.species] = int(run.eaten.get(a.species, 0)) + 1
			var hk := float(run.stats["heal_kill"])
			if hk > 0.0:
				player.hp = minf(player.max_hp, player.hp + hk)
			Sfx.play("pop", randf_range(0.8, 1.2), -3.0)
		if a.is_boss:
			bosses.on_boss_dead(a)
		actors.remove_at(i)
		a.queue_free()


# ------------------------------------------------------------------ spawning
## Animals get tougher as the clock runs: HP grows faster than damage.
func strength() -> float:
	var s := 1.0 + run.minute() * 0.09 + run.minute() * run.minute() * 0.002
	if run.has_gene("challenger"):
		s *= 1.3
	return s


func dmg_strength() -> float:
	return 1.0 + run.minute() * 0.06


func _spawner() -> void:
	var vr := view.size.length() * 0.5
	var far := vr + 520.0
	var count := 0
	for i in range(actors.size() - 1, -1, -1):
		var a := actors[i]
		if a.is_player or a.is_boss or a.is_ally or a.dead:
			continue
		if a.position.distance_to(player.position) > far:
			actors.remove_at(i)
			a.queue_free()
		else:
			count += 1
	var target := 22 + int(run.minute() * 1.2) + (6 if run.is_night() else 0)
	if count < target:
		_spawn_one(vr + 20.0, vr + 220.0)


func _spawn_one(dmin: float, dmax: float) -> void:
	var p := map.random_point(rng, player.position, dmin, dmax, true)
	if p.x < 0:
		return
	var biome := map.biome_name_at(p)
	var id := Species.pick(biome, run.minute(), run.is_night(), rng)
	var d := Species.get_def(id)
	# the first minute is a gentle nursery: no predators, so Puddle can eat and grow
	if run.time < 60.0 and String(d.get("role", "")) == "predator":
		return
	var wet := map.water_at(p) != 0
	if bool(d.get("water_only", false)) != wet and bool(d.get("water_only", false)):
		return
	if wet and not (bool(d.get("swim", false)) or bool(d.get("fly", false)) or bool(d.get("wade", false))):
		return
	var alpha_chance := (0.02 + run.minute() * 0.006) * (2.0 if run.pressure >= 3 else 1.0)
	spawn_animal(id, p, rng.randf() < alpha_chance)


func spawn_animal(id: String, p: Vector2, is_alpha: bool = false) -> Actor:
	var a := Actor.new()
	if Species.get_def(id).get("boss", false):
		a.setup_animal(id, 1.0 + run.minute() * 0.08, 1.0 + run.minute() * 0.025, false)
	else:
		a.setup_animal(id, strength(), dmg_strength(), is_alpha)
	a.position = p
	a.home = p
	a.biome = map.biome_name_at(p)
	ents.add_child(a)
	actors.append(a)
	if not Game.codex_species.has(id):
		Game.codex_species[id] = 0
	return a


const ALLY_HARD_CAP := 14


func make_ally(a: Actor, life: float = -1.0) -> void:
	# never more than a small herd: past the cap the newcomer just runs off
	if ally_count() >= ALLY_HARD_CAP:
		a.state = "flee"
		return
	a.is_ally = true
	a.role = "ally"
	a.asleep = false
	a.target = null
	a.life_t = life
	a.hp = a.max_hp
	a.set_look(a.look)
	fx.burst(a.position + Vector2(0, -a.r), Pal.c("pink", 3), 12, 40.0, 1.0, 0.6)


func ally_count() -> int:
	var n := 0
	for a in actors:
		if a.is_ally and not a.dead:
			n += 1
	return n


# ------------------------------------------------------------------ points of interest
func _poi_check() -> void:
	for poi in pois:
		if poi["used"]:
			continue
		var mk: Sprite2D = poi["mark"]
		mk.position.y = -float((poi["n"] as Sprite2D).texture.get_size().y) - 8.0 - roundf(sin(run.time * 3.0) * 1.5)
		if (poi["p"] as Vector2).distance_to(player.position) < 14.0 + player.r:
			poi["used"] = true
			mk.visible = false
			(poi["n"] as Sprite2D).modulate = Color(0.65, 0.65, 0.7)
			Sfx.play("poi")
			poi_choice.emit(String(poi["kind"]))


func nearest_poi() -> Dictionary:
	var best := {}
	var bd := INF
	for poi in pois:
		if poi["used"]:
			continue
		var d := (poi["p"] as Vector2).distance_to(player.position)
		if d < bd:
			bd = d
			best = poi
	return best


func _biome_toast() -> void:
	var b := map.biome_name_at(player.position)
	if b != last_biome and b != "wall":
		if last_biome != "":
			toast.emit(Species.BIOME_NAMES[b])
		last_biome = b


# ------------------------------------------------------------------ camera
func _camera(delta: float) -> void:
	if player == null:
		return
	var target := player.position + Vector2(0, -6) + player.vel * 0.12
	cam.position = cam.position.lerp(target, 1.0 - pow(0.002, delta))
	var vs := get_viewport_rect().size
	var half := vs * 0.5
	cam.position.x = clampf(cam.position.x, half.x, MapGen.SIZE - half.x)
	cam.position.y = clampf(cam.position.y, half.y, MapGen.SIZE - half.y)
	shake = maxf(0.0, shake - delta * 25.0)
	var sh := shake if Game.shake else 0.0
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * minf(sh, 6.0)
	view = Rect2(cam.position - half, vs)
	for a in actors:
		a.visible = (not a.dead and view.grow(40.0).has_point(a.position)) or (a.is_boss and not a.dead)
	# see-through crowns: a tree fades while the player stands behind it
	for o in tall_props:
		var n: Sprite2D = o["n"]
		var d: Vector2 = player.position - (o["p"] as Vector2)
		var behind := absf(d.x) < 22.0 and d.y < -4.0 and d.y > -46.0
		n.modulate.a = move_toward(n.modulate.a, 0.5 if behind else 1.0, delta * 4.0)
